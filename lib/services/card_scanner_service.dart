import 'dart:math' as math;
import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// Result of the card cropping pipeline.
///
/// If [cornersFound] is true, [croppedBytes] holds a perspective-corrected
/// rectangle (standard card size ~ 3.375:2.125 = 1.586 aspect) with a small
/// 2.5 mm safety margin on all sides. If false, [croppedBytes] is the
/// original, uncropped image so the user can still use it / re-scan.
class CardCropResult {
  final bool cornersFound;
  final Uint8List croppedBytes;
  final int originalWidth;
  final int originalHeight;

  CardCropResult({
    required this.cornersFound,
    required this.croppedBytes,
    required this.originalWidth,
    required this.originalHeight,
  });
}

/// Offline, static-image card edge detector + perspective cropper.
///
/// Design philosophy: the user manually taps the shutter button and gives us
/// a single, focused photo. We do NOT auto-snap. We then run:
///   1. Decode → resize for speed
///   2. Grayscale → Gaussian blur → Sobel gradients → Threshold → Dilate
///   3. Contour tracing → Largest 4-point quadrilateral approximation
///   4. Validate aspect ratio and minimum area
///   5. Expand the detected corners by ~2.5 mm (min of ~30 px or 5% of long
///      side) to prevent clipping the card's bevel.
///   6. Perspective warp → output a nice, upright JPEG at ~1200×750 px.
///
/// If detection fails at any step, we fall back to returning the original
/// (downscaled) image so the OCR engine can still try its luck against the
/// raw photo. This degrades gracefully instead of dropping the frame.
class CardScannerService {
  static const int _preferredLongSide = 1600;
  static const int _outputLongSide = 1200;
  static const double _targetAspect = 3.375 / 2.125; // ~1.586
  static const double _aspectTolerance = 0.35; // accept 1.03–2.14 aspect
  static const double _minAreaRatio = 0.10;
  static const double _safetyMarginMm = 2.5;

  static final CardScannerService instance = CardScannerService._();
  CardScannerService._();

  // ================================================================
  // Public entry point.
  // ================================================================
  Future<CardCropResult> processCardPhoto(Uint8List jpegBytes) async {
    final img.Image? decoded = img.decodeImage(jpegBytes);
    if (decoded == null) {
      return CardCropResult(
        cornersFound: false,
        croppedBytes: jpegBytes,
        originalWidth: 0,
        originalHeight: 0,
      );
    }

    final int origW = decoded.width;
    final int origH = decoded.height;

    // --- Step 1: Downscale for processing so our Dart loops stay fast. ---
    final img.Image working = _resizeToLongSide(decoded, _preferredLongSide);
    final int w = working.width;
    final int h = working.height;

    // --- Step 2: Find four corners of the card. ---
    final List<img.Point>? quad = _findCardCorners(working, w, h);

    if (quad == null || quad.length != 4) {
      // Graceful fallback: just return a re-encoded, reasonably-sized JPEG.
      final fallback = _resizeToLongSide(decoded, _outputLongSide);
      return CardCropResult(
        cornersFound: false,
        croppedBytes: Uint8List.fromList(img.encodeJpg(fallback, quality: 90)),
        originalWidth: origW,
        originalHeight: origH,
      );
    }

    // --- Step 3: Expand the quad by the 2.5 mm safety margin. ---
    final expandedQuad =
        _expandQuadBy(quad, w, h, _computePaddingPx(w, h));

    // --- Step 4: Perspective warp to an upright standard-card rectangle. ---
    // image 4.x does NOT have copyPerspective — use copyRectify instead.
    // copyRectify maps a quadrilateral in the source image to fill an
    // output image (provided via toImage). It accepts the four source
    // corners as named params topLeft / topRight / bottomLeft / bottomRight.
    final int outW = _outputLongSide;
    final int outH = (outW / _targetAspect).round();

    // expandedQuad is [TL, TR, BR, BL] (output of _orderCorners).
    // Map each detected corner back to the ORIGINAL image coordinate space.
    img.Point mapToOriginal(img.Point p) => img.Point(
          p.x * origW / w,
          p.y * origH / h,
        );

    final img.Image cropped = img.copyRectify(
      decoded, // warp from the ORIGINAL (higher-res) image, not working copy
      topLeft: mapToOriginal(expandedQuad[0]),
      topRight: mapToOriginal(expandedQuad[1]),
      bottomRight: mapToOriginal(expandedQuad[2]),
      bottomLeft: mapToOriginal(expandedQuad[3]),
      interpolation: img.Interpolation.linear,
      toImage: img.Image(width: outW, height: outH),
    );

    return CardCropResult(
      cornersFound: true,
      croppedBytes: Uint8List.fromList(img.encodeJpg(cropped, quality: 92)),
      originalWidth: origW,
      originalHeight: origH,
    );
  }

  // ================================================================
  // Internal helpers.
  // ================================================================

  static img.Image _resizeToLongSide(img.Image src, int longSide) {
    final int w = src.width;
    final int h = src.height;
    final int maxSide = math.max(w, h);
    if (maxSide <= longSide) return src;
    final double ratio = longSide / maxSide;
    return img.copyResize(
      src,
      width: (w * ratio).round(),
      height: (h * ratio).round(),
      interpolation: img.Interpolation.average,
    );
  }

  /// Padding to apply around the detected quad, in pixels (computed on the
  /// working copy size, not the original).
  static int _computePaddingPx(int w, int h) {
    // 320 dpi fallback → 2.5 mm ≈ 31.5 px. Also use 5% of the short side as a
    // lower bound so very small cards on a dense background also get padding.
    final int shortSide = math.min(w, h);
    final int byDpi = ((320 / 25.4) * _safetyMarginMm).round();
    final int byPct = (shortSide * 0.05).round();
    return math.max(byDpi, byPct);
  }

  /// Given the 4 corners of the detected card (working-image space) and an
  /// absolute pixel padding, push each corner outward from the image centre
  /// without crossing the image boundaries.
  static List<img.Point> _expandQuadBy(
      List<img.Point> quad, int w, int h, int padPx) {
    // Compute centroid of the 4 corners. Point.x/y are `num`, so accumulate
    // as double (p.x.toDouble()) to keep math typed as double.
    double cx = 0, cy = 0;
    for (final p in quad) {
      cx += p.x;
      cy += p.y;
    }
    cx /= 4;
    cy /= 4;

    return quad.map((p) {
      // Unit vector from centroid → corner. Convert p.x / p.y to double
      // first to avoid "num cannot be assigned to double" compile errors.
      final double px = p.x.toDouble();
      final double py = p.y.toDouble();
      final double dx = px - cx;
      final double dy = py - cy;
      final double len = math.sqrt(dx * dx + dy * dy) + 1e-9;
      final double nx = dx / len;
      final double ny = dy / len;
      return img.Point(
        (px + nx * padPx).round().clamp(0, w - 1),
        (py + ny * padPx).round().clamp(0, h - 1),
      );
    }).toList();
  }

  // ================================================================
  // Corner detection pipeline — pure-Dart, no native libs required.
  // Returns 4 points ordered clockwise from top-left, or null.
  // ================================================================
  static List<img.Point>? _findCardCorners(
      img.Image src, int w, int h) {
    // 2a. Grayscale
    final List<num> gray = List<num>.filled(w * h, 0);
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final p = src.getPixel(x, y);
        gray[y * w + x] = 0.299 * p.r + 0.587 * p.g + 0.114 * p.b;
      }
    }

    // 2b. 3x3 box blur (fast approximation of Gaussian; fine for this pipeline)
    final List<num> blurred = List<num>.filled(w * h, 0);
    _boxBlur3x3(gray, blurred, w, h);

    // 2c. Sobel gradient magnitude → threshold → binary map.
    final List<bool> binary = List<bool>.filled(w * h, false);
    num maxGrad = 0;
    final List<num> grad = List<num>.filled(w * h, 0);
    for (int y = 1; y < h - 1; y++) {
      for (int x = 1; x < w - 1; x++) {
        final int i = y * w + x;
        final num gx = (-blurred[i - w - 1] +
                blurred[i - w + 1] -
                2 * blurred[i - 1] +
                2 * blurred[i + 1] -
                blurred[i + w - 1] +
                blurred[i + w + 1])
            .abs();
        final num gy = (-blurred[i - w - 1] -
                2 * blurred[i - w] -
                blurred[i - w + 1] +
                blurred[i + w - 1] +
                2 * blurred[i + w] +
                blurred[i + w + 1])
            .abs();
        final num m = gx + gy;
        grad[i] = m;
        if (m > maxGrad) maxGrad = m;
      }
    }
    final num thresh = maxGrad * 0.18;
    for (int i = 0; i < grad.length; i++) {
      binary[i] = grad[i] >= thresh;
    }

    // 2d. 3x3 dilate once so broken edges connect again.
    _dilate3x3(binary, w, h);

    // 2e. Contour tracing (border following) on the binary map — collect
    // closed loops as point-lists, then rank by enclosed pixel count.
    final List<List<img.Point>> contours = _findContours(binary, w, h);
    if (contours.isEmpty) return null;
    contours.sort((a, b) => b.length.compareTo(a.length));

    // 2f. For each candidate, approximate as a polygon with Douglas-Peucker
    // down to 4 points and validate.
    final int minArea = (w * h * _minAreaRatio).round();
    for (final c in contours) {
      if (c.length < 16) continue;
      final simplified = _simplifyPolyTo4(c);
      if (simplified == null) continue;
      final area = _polyArea(simplified).abs();
      if (area < minArea) continue;
      final aspect = _polyAspect(simplified);
      if ((aspect - _targetAspect).abs() > _aspectTolerance) continue;
      return _orderCorners(simplified); // TL, TR, BR, BL
    }
    return null;
  }

  // ---- Image-processing primitives --------------------------------

  static void _boxBlur3x3(List<num> src, List<num> dst, int w, int h) {
    for (int y = 1; y < h - 1; y++) {
      for (int x = 1; x < w - 1; x++) {
        final int i = y * w + x;
        dst[i] = (src[i - w - 1] +
                src[i - w] +
                src[i - w + 1] +
                src[i - 1] +
                src[i] +
                src[i + 1] +
                src[i + w - 1] +
                src[i + w] +
                src[i + w + 1]) /
            9;
      }
    }
  }

  static void _dilate3x3(List<bool> src, int w, int h) {
    final copy = List<bool>.from(src);
    for (int y = 1; y < h - 1; y++) {
      for (int x = 1; x < w - 1; x++) {
        final int i = y * w + x;
        if (copy[i]) continue;
        if (copy[i - w - 1] ||
            copy[i - w] ||
            copy[i - w + 1] ||
            copy[i - 1] ||
            copy[i + 1] ||
            copy[i + w - 1] ||
            copy[i + w] ||
            copy[i + w + 1]) {
          src[i] = true;
        }
      }
    }
  }

  /// Basic 4-connected contour tracing (Suzuki–Abe simplified).
  static List<List<img.Point>> _findContours(List<bool> bin, int w, int h) {
    final out = <List<img.Point>>[];
    final visited = List<bool>.filled(bin.length, false);
    for (int y = 1; y < h - 1; y++) {
      for (int x = 1; x < w - 1; x++) {
        final int i = y * w + x;
        if (!bin[i] || visited[i]) continue;
        final contour = <img.Point>[];
        int cx = x, cy = y;
        int dir = 0; // 0..7 clockwise
        int guard = 0;
        while (guard++ < 100000) {
          final int ci = cy * w + cx;
          if (visited[ci]) break;
          visited[ci] = true;
          contour.add(img.Point(cx, cy));
          bool found = false;
          for (int k = 0; k < 8; k++) {
            final int d = (dir + 6 + k) % 8;
            final dx = const [-1, 0, 1, 1, 1, 0, -1, -1][d];
            final dy = const [-1, -1, -1, 0, 1, 1, 1, 0][d];
            final nx = cx + dx, ny = cy + dy;
            if (nx < 1 || nx >= w - 1 || ny < 1 || ny >= h - 1) continue;
            final int ni = ny * w + nx;
            if (bin[ni] && !visited[ni]) {
              cx = nx;
              cy = ny;
              dir = d;
              found = true;
              break;
            }
          }
          if (!found) break;
        }
        if (contour.length >= 12) out.add(contour);
      }
    }
    return out;
  }

  /// Douglas-Peucker until ≤4 points; returns null if approximation isn't
  /// exactly 4 after shrinking the tolerance.
  static List<img.Point>? _simplifyPolyTo4(List<img.Point> c) {
    num tolerance = 8;
    for (int tries = 0; tries < 10; tries++) {
      final s = _douglasPeucker(c, tolerance);
      if (s.length == 4) return s;
      if (s.length < 4) return null;
      tolerance *= 1.4;
    }
    return null;
  }

  static List<img.Point> _douglasPeucker(
      List<img.Point> pts, num epsilon) {
    if (pts.length < 3) return List.from(pts);
    int idx = 0;
    num maxDist = 0;
    for (int i = 1; i < pts.length - 1; i++) {
      final d = _perpendicularDistance(pts[i], pts.first, pts.last);
      if (d > maxDist) {
        maxDist = d;
        idx = i;
      }
    }
    if (maxDist > epsilon) {
      final left = _douglasPeucker(pts.sublist(0, idx + 1), epsilon);
      final right = _douglasPeucker(pts.sublist(idx), epsilon);
      return [...left.sublist(0, left.length - 1), ...right];
    }
    return [pts.first, pts.last];
  }

  static num _perpendicularDistance(
      img.Point p, img.Point a, img.Point b) {
    final num dx = b.x - a.x;
    final num dy = b.y - a.y;
    final num len2 = dx * dx + dy * dy;
    if (len2 == 0) return math.sqrt((p.x - a.x) * (p.x - a.x) + (p.y - a.y) * (p.y - a.y));
    num t = ((p.x - a.x) * dx + (p.y - a.y) * dy) / len2;
    t = t.clamp(0, 1);
    final num projX = a.x + t * dx;
    final num projY = a.y + t * dy;
    return math.sqrt((p.x - projX) * (p.x - projX) + (p.y - projY) * (p.y - projY));
  }

  static num _polyArea(List<img.Point> p) {
    num sum = 0;
    for (int i = 0; i < p.length; i++) {
      final a = p[i];
      final b = p[(i + 1) % p.length];
      sum += (a.x * b.y) - (b.x * a.y);
    }
    return sum / 2;
  }

  static num _polyAspect(List<img.Point> p) {
    if (p.length != 4) return 1;
    num d1 = _dist(p[0], p[1]);
    num d2 = _dist(p[1], p[2]);
    if (d2 > d1) {
      final tmp = d1;
      d1 = d2;
      d2 = tmp;
    }
    return d2 == 0 ? 1 : d1 / d2;
  }

  static num _dist(img.Point a, img.Point b) {
    return math.sqrt((a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y));
  }

  /// Order a set of 4 arbitrary corners: TL, TR, BR, BL (clockwise from top
  /// left). The perspective warp function above depends on this order.
  static List<img.Point> _orderCorners(List<img.Point> p) {
    assert(p.length == 4);
    // Point.x and Point.y are `num` in image 4.x — must call toInt() to
    // satisfy List<int>.generate's return type.
    final sums = List<int>.generate(4, (i) => (p[i].x + p[i].y).toInt());
    final diffs = List<int>.generate(4, (i) => (p[i].x - p[i].y).toInt());
    final tl = p[sums.indexOf(sums.reduce(math.min))];
    final br = p[sums.indexOf(sums.reduce(math.max))];
    final tr = p[diffs.indexOf(diffs.reduce(math.max))];
    final bl = p[diffs.indexOf(diffs.reduce(math.min))];
    return [tl, tr, br, bl];
  }
}
