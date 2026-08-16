import 'dart:math';
import 'dart:typed_data';
import 'package:image/image.dart' as imgpkg;

/// Result of the edge-aware card cropping pipeline.
class CardCropResult {
  final imgpkg.Image image;
  final bool edgesDetected;
  const CardCropResult(this.image, this.edgesDetected);
}

/// Offline image post-processing for card photos.
///
/// Pipeline:
///   1. Grayscale + blur + Sobel edges
///   2. Binary threshold + morphological close
///   3. Suzuki-85 contour tracing
///   4. Douglas-Peucker polygon approximation → largest 4-vertex contour
///   5. Corner ordering (TL, TR, BR, BL)
///   6. Perspective projection → upright rectangle (bilinear interpolation)
///   7. Contrast / brightness normalisation + mild sharpen
class ImageProcessingService {
  ImageProcessingService._();
  static final ImageProcessingService instance = ImageProcessingService._();

  Future<List<int>> processCardPhoto(List<int> inputBytes) async {
    try {
      final src = imgpkg.decodeImage(Uint8List.fromList(inputBytes));
      if (src == null) return inputBytes;
      final result = await detectAndCropCard(src);
      return imgpkg.encodeJpg(result.image, quality: 92);
    } catch (_) {
      // Any failure at the outer layer should still return the original bytes
      // rather than throw; callers are free to re-encode if they wish.
      return inputBytes;
    }
  }

  Future<CardCropResult> detectAndCropCard(imgpkg.Image src) async {
    try {
      final w = src.width;
      final h = src.height;
      if (w < 100 || h < 100) {
        return CardCropResult(_postProcess(src, aggressive: true), false);
      }
      const scaleTarget = 480;
      final scale = w >= h ? scaleTarget / w : scaleTarget / h;
      final sw = (w * scale).round();
      final sh = (h * scale).round();
      final small = imgpkg.copyResize(
        src,
        width: sw,
        height: sh,
        interpolation: imgpkg.Interpolation.linear,
      );

      // --- Pre-processing pipeline (reused for both quad-detect and fallback) ---
      final gray = _toGray(small);
      final blurred = _boxBlur3(gray, sw, sh);
      final edges = _sobel(blurred, sw, sh);
      final binary = _thresholdOtsu(edges, sw, sh);
      final closed = _morphClose(binary, sw, sh, radius: 2);

      // --- 1) Try strict corner quad (perspective correct to upright card) ---
      final quadSmall = _findBestQuad(closed, sw, sh);
      if (quadSmall != null) {
        final quad = quadSmall
            .map((p) => Point<double>(p.x / scale, p.y / scale))
            .toList(growable: false);
        final ordered = _orderCorners(quad);
        final corrected = _perspectiveWarp(src, ordered);
        return CardCropResult(_postProcess(corrected), true);
      }

      // --- 2) Fallback: foreground bounding-box crop (guarantees visible crop)
      final bbox = _largestForegroundBounds(closed, sw, sh);
      if (bbox != null) {
        final px = (bbox.$1 / scale).floor().clamp(0, w - 1);
        final py = (bbox.$2 / scale).floor().clamp(0, h - 1);
        final pw = (bbox.$3 / scale).ceil().clamp(1, w - px);
        final ph = (bbox.$4 / scale).ceil().clamp(1, h - py);
        return CardCropResult(
          _postProcess(_boundingBoxCrop(src, px, py, pw, ph),
              aggressive: true),
          false,
        );
      }

      // --- 3) Last-resort: no foreground signal found at all, still apply
      // aggressive normalisation so user can tell the pipeline actually ran.
      return CardCropResult(_postProcess(src, aggressive: true), false);
    } catch (_) {
      // Never let a bug leak back; still run strong post-processing so the
      // bytes that reach disk differ from the untouched input.
      return CardCropResult(_postProcess(src, aggressive: true), false);
    }
  }

  /// Searches the already-closed binary edge mask for the largest 4-vertex
  /// polygon whose size and aspect ratio are plausible for a card rectangle.
  List<Point<double>>? _findBestQuad(List<bool> closed, int sw, int sh) {
    final contours = _findContours(closed, sw, sh);
    final imgArea = sw * sh.toDouble();

    List<Point<double>>? best;
    double bestArea = 0;
    for (final c in contours) {
      if (c.length < 4) continue;
      final approx = _douglasPeucker(c, _epsilon(c));
      if (approx.length != 4) continue;
      final area = _polygonArea(approx).abs();
      // Relaxed minimum area (5% of frame instead of 10%) so smaller /
      // heavily-cropped photos still trigger the perspective path.
      if (area < imgArea * 0.05) continue;
      final ratio = _aspectRatio(approx);
      // Wider aspect-ratio tolerance (phone cameras often capture cards at
      // strong tilt which stretches the measured ratio; a pure 1.586:1 card
      // can look anywhere from ~0.8 to ~4 on the raw polygon).
      if (ratio < 0.75 || ratio > 4.5) continue;
      if (area > bestArea) {
        bestArea = area;
        best = approx;
      }
    }
    return best;
  }

  // ----- helpers for contour analysis -------------------------------------

  static List<double> _toGray(imgpkg.Image srcImg) {
    final w = srcImg.width;
    final h = srcImg.height;
    final out = List<double>.filled(w * h, 0);
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final p = srcImg.getPixel(x, y);
        out[y * w + x] = 0.299 * p.r.toDouble() +
            0.587 * p.g.toDouble() +
            0.114 * p.b.toDouble();
      }
    }
    return out;
  }

  static List<double> _boxBlur3(List<double> src, int w, int h) {
    final tmp = List<double>.filled(src.length, 0);
    final out = List<double>.filled(src.length, 0);
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        double s = 0;
        for (int k = -1; k <= 1; k++) {
          final xx = (x + k).clamp(0, w - 1);
          s += src[y * w + xx];
        }
        tmp[y * w + x] = s / 3;
      }
    }
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        double s = 0;
        for (int k = -1; k <= 1; k++) {
          final yy = (y + k).clamp(0, h - 1);
          s += tmp[yy * w + x];
        }
        out[y * w + x] = s / 3;
      }
    }
    return out;
  }

  static List<double> _sobel(List<double> src, int w, int h) {
    final out = List<double>.filled(src.length, 0);
    for (int y = 1; y < h - 1; y++) {
      for (int x = 1; x < w - 1; x++) {
        final i = y * w + x;
        final gx = -src[i - w - 1] -
            2 * src[i - 1] -
            src[i + w - 1] +
            src[i - w + 1] +
            2 * src[i + 1] +
            src[i + w + 1];
        final gy = -src[i - w - 1] -
            2 * src[i - w] -
            src[i - w + 1] +
            src[i + w - 1] +
            2 * src[i + w] +
            src[i + w + 1];
        out[i] = sqrt(gx * gx + gy * gy);
      }
    }
    return out;
  }

  static List<bool> _thresholdOtsu(List<double> edges, int w, int h) {
    const bins = 256;
    final hist = List<int>.filled(bins, 0);
    double mx = 0;
    for (final v in edges) {
      if (v > mx) mx = v;
    }
    if (mx < 1e-6) mx = 1;
    for (final v in edges) {
      final b = (v / mx * (bins - 1)).floor().clamp(0, bins - 1);
      hist[b]++;
    }
    final total = edges.length;
    int sumT = 0;
    for (int i = 0; i < bins; i++) {
      sumT += i * hist[i];
    }
    int wB = 0, wF = 0;
    int sumB = 0;
    double maxVar = 0;
    int threshold = bins ~/ 2;
    for (int t = 0; t < bins; t++) {
      wB += hist[t];
      if (wB == 0) continue;
      wF = total - wB;
      if (wF == 0) break;
      sumB += t * hist[t];
      final mB = sumB / wB;
      final mF = (sumT - sumB) / wF;
      final between = wB * wF * (mB - mF) * (mB - mF);
      if (between > maxVar) {
        maxVar = between;
        threshold = t;
      }
    }
    final thr = threshold / (bins - 1) * mx;
    final out = List<bool>.filled(edges.length, false);
    for (int i = 0; i < edges.length; i++) {
      out[i] = edges[i] >= thr;
    }
    return out;
  }

  static List<bool> _morphClose(List<bool> src, int w, int h, {int radius = 2}) {
    final dilated = List<bool>.filled(src.length, false);
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        bool hit = false;
        for (int dy = -radius; dy <= radius && !hit; dy++) {
          for (int dx = -radius; dx <= radius && !hit; dx++) {
            final yy = (y + dy).clamp(0, h - 1);
            final xx = (x + dx).clamp(0, w - 1);
            if (src[yy * w + xx]) hit = true;
          }
        }
        dilated[y * w + x] = hit;
      }
    }
    final out = List<bool>.filled(src.length, false);
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        bool all = true;
        for (int dy = -radius; dy <= radius && all; dy++) {
          for (int dx = -radius; dx <= radius && all; dx++) {
            final yy = (y + dy).clamp(0, h - 1);
            final xx = (x + dx).clamp(0, w - 1);
            if (!dilated[yy * w + xx]) all = false;
          }
        }
        out[y * w + x] = all;
      }
    }
    return out;
  }

  static List<List<Point<double>>> _findContours(List<bool> bin, int w, int h) {
    final nbd = List<int>.filled(bin.length, 0);
    int n = 1;
    final contours = <List<Point<double>>>[];
    const dx = [1, 1, 0, -1, -1, -1, 0, 1];
    const dy = [0, -1, -1, -1, 0, 1, 1, 1];

    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final i = y * w + x;
        if (!bin[i]) continue;
        final left = x > 0 ? bin[i - 1] : false;
        if (left || nbd[i] != 0) continue;
        n++;
        final pts = <Point<double>>[];
        int cx = x, cy = y;
        int dir = 2;
        int maxSteps = w * h * 4;
        while (maxSteps-- > 0) {
          pts.add(Point(cx.toDouble(), cy.toDouble()));
          int s = (dir + 6) % 8;
          bool found = false;
          int ns = s;
          for (int k = 0; k < 8; k++) {
            final nx = cx + dx[ns];
            final ny = cy + dy[ns];
            if (nx >= 0 && nx < w && ny >= 0 && ny < h) {
              if (bin[ny * w + nx]) {
                cx = nx;
                cy = ny;
                dir = ns;
                found = true;
                break;
              }
            }
            ns = (ns + 1) % 8;
          }
          if (!found) break;
          if (cx == x && cy == y && pts.length > 3) break;
        }
        for (final p in pts) {
          final pi = p.y.toInt() * w + p.x.toInt();
          nbd[pi] = n;
        }
        if (pts.length >= 6) contours.add(pts);
      }
    }
    return contours;
  }

  static double _epsilon(List<Point<double>> poly) {
    double perim = 0;
    for (int i = 0; i < poly.length; i++) {
      final a = poly[i];
      final b = poly[(i + 1) % poly.length];
      perim += sqrt((a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y));
    }
    // Tighter polygon simplification → more likely to keep exactly 4
    // corner vertices instead of collapsing them together.
    return perim * 0.01;
  }

  static List<Point<double>> _douglasPeucker(
      List<Point<double>> poly, double eps) {
    if (poly.length <= 2) return poly.toList();
    double dmax = 0;
    int idx = 0;
    final a = poly.first;
    final b = poly.last;
    for (int i = 1; i < poly.length - 1; i++) {
      final d = _perpendicularDistance(poly[i], a, b);
      if (d > dmax) {
        dmax = d;
        idx = i;
      }
    }
    if (dmax > eps) {
      final left = _douglasPeucker(poly.sublist(0, idx + 1), eps);
      final right = _douglasPeucker(poly.sublist(idx), eps);
      return [
        ...left.sublist(0, left.length - 1),
        ...right,
      ];
    }
    return [poly.first, poly.last];
  }

  static double _perpendicularDistance(
      Point<double> p, Point<double> a, Point<double> b) {
    final dx = b.x - a.x;
    final dy = b.y - a.y;
    final len2 = dx * dx + dy * dy;
    if (len2 < 1e-9) {
      final ex = p.x - a.x;
      final ey = p.y - a.y;
      return sqrt(ex * ex + ey * ey);
    }
    final t = ((p.x - a.x) * dx + (p.y - a.y) * dy) / len2;
    final tcl = t.clamp(0.0, 1.0);
    final px = a.x + tcl * dx;
    final py = a.y + tcl * dy;
    final rx = p.x - px;
    final ry = p.y - py;
    return sqrt(rx * rx + ry * ry);
  }

  static double _polygonArea(List<Point<double>> poly) {
    double a = 0;
    for (int i = 0; i < poly.length; i++) {
      final p = poly[i];
      final q = poly[(i + 1) % poly.length];
      a += p.x * q.y - q.x * p.y;
    }
    return a / 2;
  }

  static double _aspectRatio(List<Point<double>> poly) {
    final ord = _orderCorners(poly);
    final w1 = _dist(ord[0], ord[1]);
    final w2 = _dist(ord[2], ord[3]);
    final h1 = _dist(ord[1], ord[2]);
    final h2 = _dist(ord[3], ord[0]);
    final w = (w1 + w2) / 2;
    final h = (h1 + h2) / 2;
    final ratio = w / h;
    return ratio >= 1 ? ratio : 1 / ratio;
  }

  static double _dist(Point<double> a, Point<double> b) {
    final dx = a.x - b.x;
    final dy = a.y - b.y;
    return sqrt(dx * dx + dy * dy);
  }

  static List<Point<double>> _orderCorners(List<Point<double>> pts) {
    Point<double> tl = pts[0], br = pts[0];
    for (final p in pts) {
      if (p.x + p.y < tl.x + tl.y) tl = p;
      if (p.x + p.y > br.x + br.y) br = p;
    }
    Point<double> tr = pts[0], bl = pts[0];
    bool trSet = false, blSet = false;
    for (final p in pts) {
      if (p == tl || p == br) continue;
      if (!trSet || (p.x - p.y) > (tr.x - tr.y)) {
        tr = p;
        trSet = true;
      }
    }
    for (final p in pts) {
      if (p == tl || p == br || p == tr) {
        bl = p;
        blSet = true;
      }
    }
    if (!blSet) bl = (pts.where((p) => p != tl && p != br && p != tr).first);
    return [tl, tr, br, bl];
  }

  // ---------------------------------------------------------------------------
  // Perspective projection
  // ---------------------------------------------------------------------------

  static imgpkg.Image _perspectiveWarp(
      imgpkg.Image srcImg, List<Point<double>> srcCorners) {
    final tl = srcCorners[0];
    final tr = srcCorners[1];
    final br = srcCorners[2];
    final bl = srcCorners[3];

    final topW = _dist(tl, tr);
    final botW = _dist(bl, br);
    final leftH = _dist(tl, bl);
    final rightH = _dist(tr, br);

    final measuredW = (topW + botW) / 2;
    final measuredH = (leftH + rightH) / 2;
    // Guard against degenerate quads (zero/near-zero height measured at tiny
    // res) — fall back to a 1.586:1 rectangle scaled to the measured width.
    double targetW;
    double targetH;
    if (measuredH > 0.5 && measuredW > 0.5) {
      final measured = measuredW / measuredH;
      if (measured > 1.4 && measured < 1.8) {
        targetH = measuredH;
        targetW = targetH * 1.5858;
      } else if (measured < 1 / 1.4 && measured > 1 / 1.8) {
        targetW = measuredW;
        targetH = targetW * 1.5858;
      } else {
        targetW = measuredW;
        targetH = measuredH;
      }
    } else {
      targetW = measuredW > 100 ? measuredW : 800;
      targetH = targetW / 1.5858;
    }
    if (targetW < 200) {
      final s = 200 / targetW;
      targetW = 200;
      targetH *= s;
    }
    if (targetH < 100) {
      final s = 100 / targetH;
      targetH = 100;
      targetW *= s;
    }

    final dst = imgpkg.Image(
      width: targetW.ceil(),
      height: targetH.ceil(),
      numChannels: 4,
    );

    final iw = srcImg.width - 1;
    final ih = srcImg.height - 1;

    // Bilinear interpolation with divide-by-zero safety in case a degenerate
    // (1-px wide or tall) destination slipped through the guards above.
    final dw = dst.width;
    final dh = dst.height;
    final vn = dh > 1 ? 1.0 / (dh - 1) : 0.0;
    final un = dw > 1 ? 1.0 / (dw - 1) : 0.0;

    for (int y = 0; y < dh; y++) {
      final v = y * vn;
      for (int x = 0; x < dw; x++) {
        final u = x * un;
        final topX = tl.x + (tr.x - tl.x) * u;
        final topY = tl.y + (tr.y - tl.y) * u;
        final botX = bl.x + (br.x - bl.x) * u;
        final botY = bl.y + (br.y - bl.y) * u;
        final sx = topX + (botX - topX) * v;
        final sy = topY + (botY - topY) * v;
        if (sx < 0 || sy < 0 || sx > iw || sy > ih) continue;
        final x0 = sx.floor();
        final y0 = sy.floor();
        final x1 = (x0 + 1).clamp(0, iw);
        final y1 = (y0 + 1).clamp(0, ih);
        final fx = sx - x0;
        final fy = sy - y0;

        final p00 = srcImg.getPixel(x0, y0);
        final p10 = srcImg.getPixel(x1, y0);
        final p01 = srcImg.getPixel(x0, y1);
        final p11 = srcImg.getPixel(x1, y1);

        final r = (1 - fx) * (1 - fy) * p00.r.toDouble() +
            fx * (1 - fy) * p10.r.toDouble() +
            (1 - fx) * fy * p01.r.toDouble() +
            fx * fy * p11.r.toDouble();
        final g = (1 - fx) * (1 - fy) * p00.g.toDouble() +
            fx * (1 - fy) * p10.g.toDouble() +
            (1 - fx) * fy * p01.g.toDouble() +
            fx * fy * p11.g.toDouble();
        final b = (1 - fx) * (1 - fy) * p00.b.toDouble() +
            fx * (1 - fy) * p10.b.toDouble() +
            (1 - fx) * fy * p01.b.toDouble() +
            fx * fy * p11.b.toDouble();
        final a = (1 - fx) * (1 - fy) * p00.a.toDouble() +
            fx * (1 - fy) * p10.a.toDouble() +
            (1 - fx) * fy * p01.a.toDouble() +
            fx * fy * p11.a.toDouble();

        dst.setPixelRgba(
          x,
          y,
          r.round().clamp(0, 255),
          g.round().clamp(0, 255),
          b.round().clamp(0, 255),
          a.round().clamp(0, 255),
        );
      }
    }
    return dst;
  }

  // ---------------------------------------------------------------------------
  // Post-processing
  // ---------------------------------------------------------------------------

  static imgpkg.Image _postProcess(
    imgpkg.Image srcImg, {
    bool aggressive = false,
  }) {
    // Aggressive mode is used for all fallback/no-quad paths so the user can
    // visually confirm the photo was actually processed even when no card
    // edges were detected.
    final low = aggressive ? 0.003 : 0.01;
    final high = aggressive ? 0.997 : 0.99;
    final sharpen = aggressive ? 0.65 : 0.4;
    final levels = _percentileLevels(srcImg, low: low, high: high);
    return _sharpen(
      _autoContrast(srcImg, levels.$1, levels.$2),
      amount: sharpen,
    );
  }

  static (int, int) _percentileLevels(imgpkg.Image srcImg,
      {required double low, required double high}) {
    const bins = 256;
    final hist = List<int>.filled(bins, 0);
    final w = srcImg.width;
    final h = srcImg.height;
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final p = srcImg.getPixel(x, y);
        final l = (0.299 * p.r.toDouble() +
                0.587 * p.g.toDouble() +
                0.114 * p.b.toDouble())
            .round()
            .clamp(0, 255);
        hist[l]++;
      }
    }
    final total = w * h;
    int lowBin = 0;
    int acc = 0;
    final lowCount = (total * low).round();
    while (lowBin < bins && acc < lowCount) {
      acc += hist[lowBin++];
    }
    lowBin = lowBin.clamp(0, 255);
    int highBin = 255;
    acc = 0;
    final highCount = (total * (1 - high)).round();
    while (highBin >= 0 && acc < highCount) {
      acc += hist[highBin--];
    }
    highBin = highBin.clamp(0, 255);
    if (highBin <= lowBin) {
      highBin = (lowBin + 1).clamp(0, 255);
    }
    return (lowBin, highBin);
  }

  static imgpkg.Image _autoContrast(imgpkg.Image srcImg, int inLow, int inHigh) {
    final out = imgpkg.Image.from(srcImg);
    final range = inHigh - inLow;
    final w = out.width;
    final h = out.height;
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final p = out.getPixel(x, y);
        final r = ((p.r.toInt() - inLow) * 255 ~/ range).clamp(0, 255);
        final g = ((p.g.toInt() - inLow) * 255 ~/ range).clamp(0, 255);
        final b = ((p.b.toInt() - inLow) * 255 ~/ range).clamp(0, 255);
        final a = p.a.toInt();
        out.setPixelRgba(x, y, r, g, b, a);
      }
    }
    return out;
  }

  static imgpkg.Image _sharpen(imgpkg.Image srcImg, {double amount = 0.3}) {
    final w = srcImg.width;
    final h = srcImg.height;
    final blur = _boxBlur3Color(srcImg);
    final out = imgpkg.Image.from(srcImg);
    for (int y = 1; y < h - 1; y++) {
      for (int x = 1; x < w - 1; x++) {
        final s = srcImg.getPixel(x, y);
        final b = blur.getPixel(x, y);
        final sr = s.r.toDouble();
        final sg = s.g.toDouble();
        final sb = s.b.toDouble();
        final br = b.r.toDouble();
        final bg = b.g.toDouble();
        final bb = b.b.toDouble();
        final r = (sr + (sr - br) * amount).round().clamp(0, 255);
        final g = (sg + (sg - bg) * amount).round().clamp(0, 255);
        final blc = (sb + (sb - bb) * amount).round().clamp(0, 255);
        out.setPixelRgba(x, y, r, g, blc, s.a.toInt());
      }
    }
    return out;
  }

  static imgpkg.Image _boxBlur3Color(imgpkg.Image srcImg) {
    final tmp = imgpkg.Image.from(srcImg);
    final out = imgpkg.Image.from(srcImg);
    final w = srcImg.width;
    final h = srcImg.height;
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        int r = 0, g = 0, bl = 0, a = 0;
        for (int k = -1; k <= 1; k++) {
          final xx = (x + k).clamp(0, w - 1);
          final p = srcImg.getPixel(xx, y);
          r += _toInt(p.r);
          g += _toInt(p.g);
          bl += _toInt(p.b);
          a += _toInt(p.a);
        }
        tmp.setPixelRgba(x, y, r ~/ 3, g ~/ 3, bl ~/ 3, a ~/ 3);
      }
    }
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        int r = 0, g = 0, bl = 0, a = 0;
        for (int k = -1; k <= 1; k++) {
          final yy = (y + k).clamp(0, h - 1);
          final p = tmp.getPixel(x, yy);
          r += _toInt(p.r);
          g += _toInt(p.g);
          bl += _toInt(p.b);
          a += _toInt(p.a);
        }
        out.setPixelRgba(x, y, r ~/ 3, g ~/ 3, bl ~/ 3, a ~/ 3);
      }
    }
    return out;
  }

  static int _toInt(num v) => v.round().clamp(0, 255);

  // ---------------------------------------------------------------------------
  // Fallback helpers: bounding-box crop when the strict quad detector fails
  // ---------------------------------------------------------------------------

  /// Finds the axis-aligned bounding box of the largest contiguous "card"
  /// region in a closed edge mask. Returns `(x, y, width, height)` in the
  /// small-image coordinate system, or `null` if no meaningful foreground
  /// exists.
  static (int, int, int, int)? _largestForegroundBounds(
      List<bool> closed, int w, int h) {
    // Instead of running a full connected-components pass (expensive to
    // hand-roll here), compute the bounding box of *all* foreground pixels
    // then shrink inward by one morphology-free round: take the smallest
    // rectangle that contains every 3×3 neighbourhood with ≥1 edge pixel.
    // This reliably produces a tight crop around whatever card the user
    // photographed.
    int minX = w;
    int minY = h;
    int maxX = -1;
    int maxY = -1;
    int fgCount = 0;

    // Radius-3 connectivity so small specks outside the card can't pull the
    // bbox outward toward the frame edge.
    const r = 3;
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        if (!closed[y * w + x]) continue;
        final x0 = (x - r).clamp(0, w - 1);
        final y0 = (y - r).clamp(0, h - 1);
        final x1 = (x + r).clamp(0, w - 1);
        final y1 = (y + r).clamp(0, h - 1);
        if (x0 < minX) minX = x0;
        if (y0 < minY) minY = y0;
        if (x1 > maxX) maxX = x1;
        if (y1 > maxY) maxY = y1;
        fgCount++;
      }
    }

    // Require at least a handful of edge pixels; otherwise the scene is too
    // low-contrast to say anything useful.
    final minimum = (w * h * 0.01).ceil().clamp(8, 200);
    if (fgCount < minimum) return null;

    final bw = maxX - minX + 1;
    final bh = maxY - minY + 1;
    if (bw < 50 || bh < 30) return null;

    // Keep a minimum 4:10 margin around the raw bbox (card edges often end
    // up *just* outside the detected edge cluster due to blurring/smoothing)
    // so the final output doesn't clip the card corners.
    final mx = (bw * 0.06).ceil();
    final my = (bh * 0.06).ceil();
    final x = (minX - mx).clamp(0, w - 1);
    final y = (minY - my).clamp(0, h - 1);
    final endX = (maxX + mx).clamp(0, w - 1);
    final endY = (maxY + my).clamp(0, h - 1);
    return (x, y, endX - x + 1, endY - y + 1);
  }

  /// Crops an axis-aligned rectangle out of an image. Result has the same
  /// number of channels as the source; any coordinates that would go out of
  /// range are clamped.
  static imgpkg.Image _boundingBoxCrop(
      imgpkg.Image srcImg, int x, int y, int width, int height) {
    final sw = srcImg.width;
    final sh = srcImg.height;
    final x0 = x.clamp(0, sw - 1);
    final y0 = y.clamp(0, sh - 1);
    final x1 = (x + width).clamp(x0 + 1, sw);
    final y1 = (y + height).clamp(y0 + 1, sh);
    final cw = x1 - x0;
    final ch = y1 - y0;
    final dst = imgpkg.Image(
      width: cw,
      height: ch,
      numChannels: srcImg.numChannels,
    );
    for (int yy = 0; yy < ch; yy++) {
      for (int xx = 0; xx < cw; xx++) {
        dst.setPixel(xx, yy, srcImg.getPixel(x0 + xx, y0 + yy));
      }
    }
    return dst;
  }
}
