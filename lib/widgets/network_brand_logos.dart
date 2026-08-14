import 'package:flutter/material.dart';

/// 根据用户提供的官方风格，绘制 4 个高保真品牌 logo：
/// UnionPay（银联）、Mastercard、JCB、VISA。
///
/// 采用纯 CustomPaint + Text 绘制，矢量保真，无需依赖外部 PNG 文件。
class NetworkBrandLogos {
  NetworkBrandLogos._();

  /// 返回一个按品牌匹配的 logo Widget；若品牌不识别则返回 null。
  /// 尺寸由父级约束决定（传进来的 [height] 控制整体高度，默认 30）。
  static Widget? build(String? network, {double height = 30}) {
    switch (network) {
      case 'unionpay':
        return SizedBox(height: height, child: const _UnionPayLogo());
      case 'mastercard':
        return SizedBox(height: height, child: const _MastercardLogo());
      case 'jcb':
        return SizedBox(height: height, child: const _JCBLogo());
      case 'visa':
        return SizedBox(height: height, child: const _VISALogo());
      default:
        return null;
    }
  }
}

/* ==========================================================
 *  1. UnionPay 银联 logo
 *     - 三个竖向圆角色条：红 / 深蓝 / 绿
 *     - 左上到右下略微平行四边形倾斜
 *     - 白色 "UnionPay" 英文 + "银联" 中文叠印
 * ========================================================== */
class _UnionPayLogo extends StatelessWidget {
  const _UnionPayLogo();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.8,
      child: LayoutBuilder(
        builder: (context, c) {
          final h = c.maxHeight;
          final stripeW = c.maxWidth / 3.0;
          final skew = stripeW * 0.18;
          final r = Radius.circular(h * 0.22);
          return Stack(
            clipBehavior: Clip.none,
            children: [
              // 红色条
              Positioned.fill(
                left: 0,
                right: c.maxWidth - stripeW + skew,
                child: _SkewRect(
                  color: const Color(0xFFE4002B),
                  radius: BorderRadius.only(
                    topLeft: r,
                    bottomLeft: r,
                  ),
                  skew: skew,
                  direction: _SkewDirection.shearLeft,
                ),
              ),
              // 深蓝色条
              Positioned.fill(
                left: stripeW - skew,
                right: c.maxWidth - 2 * stripeW,
                child: _SkewRect(
                  color: const Color(0xFF00338D),
                  radius: BorderRadius.zero,
                  skew: skew,
                  direction: _SkewDirection.shearLeft,
                ),
              ),
              // 绿色条
              Positioned.fill(
                left: 2 * stripeW - skew,
                right: 0,
                child: _SkewRect(
                  color: const Color(0xFF007F3F),
                  radius: BorderRadius.only(
                    topRight: r,
                    bottomRight: r,
                  ),
                  skew: skew,
                  direction: _SkewDirection.shearLeft,
                ),
              ),
              // 文字：UnionPay 上 + 银联 下
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: c.maxWidth * 0.04,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: Text(
                            'UnionPay',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.w900,
                              fontSize: h * 0.5,
                              fontStyle: FontStyle.italic,
                              letterSpacing: h * 0.02,
                              height: 1.0,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: h * 0.04),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: Text(
                            '银联',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: h * 0.48,
                              height: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/* ==========================================================
 *  2. Mastercard logo
 *     - 两个交错的圆：左红、右橙黄
 *     - 重叠区：橙红混合
 * ========================================================== */
class _MastercardLogo extends StatelessWidget {
  const _MastercardLogo();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.38,
      child: LayoutBuilder(
        builder: (context, c) {
          final r = c.maxHeight * 0.38;
          final offset = r * 0.92;
          return Stack(
            alignment: Alignment.center,
            children: [
              // 左：红
              Positioned(
                right: offset,
                child: Container(
                  width: r * 2,
                  height: r * 2,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEB001B),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              // 右：橙黄
              Positioned(
                left: offset,
                child: Container(
                  width: r * 2,
                  height: r * 2,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF5F00),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              // 重叠区：用 BlendMode 让两个圆重叠时显示真实的橙红色
              Positioned(
                right: offset,
                child: Container(
                  width: r * 2,
                  height: r * 2,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF5F00),
                    shape: BoxShape.circle,
                    backgroundBlendMode: BlendMode.modulate,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/* ==========================================================
 *  3. JCB logo
 *     - 三个竖向圆角色条：蓝 / 红 / 绿
 *     - 白色 "JCB" 三字叠在色条上方（斜体粗体）
 *     - 每个色条略微平行四边形倾斜
 * ========================================================== */
class _JCBLogo extends StatelessWidget {
  const _JCBLogo();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.6,
      child: LayoutBuilder(
        builder: (context, c) {
          final h = c.maxHeight;
          final stripeW = c.maxWidth / 3.0;
          final skew = stripeW * 0.22;
          final r = Radius.circular(h * 0.20);
          return Stack(
            clipBehavior: Clip.none,
            children: [
              // 蓝
              Positioned.fill(
                left: 0,
                right: c.maxWidth - stripeW + skew,
                child: _SkewRect(
                  color: const Color(0xFF003087),
                  radius: BorderRadius.only(
                    topLeft: r,
                    bottomLeft: r,
                  ),
                  skew: skew,
                  direction: _SkewDirection.shearLeft,
                ),
              ),
              // 红
              Positioned.fill(
                left: stripeW - skew,
                right: c.maxWidth - 2 * stripeW,
                child: _SkewRect(
                  color: const Color(0xFFCE0018),
                  radius: BorderRadius.zero,
                  skew: skew,
                  direction: _SkewDirection.shearLeft,
                ),
              ),
              // 绿
              Positioned.fill(
                left: 2 * stripeW - skew,
                right: 0,
                child: _SkewRect(
                  color: const Color(0xFF00734C),
                  radius: BorderRadius.only(
                    topRight: r,
                    bottomRight: r,
                  ),
                  skew: skew,
                  direction: _SkewDirection.shearLeft,
                ),
              ),
              // 文字 JCB
              Positioned.fill(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: c.maxWidth * 0.03,
                    ),
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: Text(
                        'JCB',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: h * 0.7,
                          fontFamily: 'Roboto',
                          letterSpacing: h * 0.03,
                          fontStyle: FontStyle.italic,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/* ==========================================================
 *  4. VISA logo
 *     - 纯蓝色粗体 VISA 字样（白底或透明背景）
 * ========================================================== */
class _VISALogo extends StatelessWidget {
  const _VISALogo();

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.contain,
      alignment: Alignment.centerRight,
      child: Text(
        'VISA',
        style: TextStyle(
          color: const Color(0xFF1A1F71),
          fontWeight: FontWeight.w900,
          fontFamily: 'Roboto',
          fontStyle: FontStyle.italic,
          letterSpacing: 0,
          height: 1.0,
          shadows: const [
            // 深色卡背景上提供极轻微抗走样边
            Shadow(
              color: Color(0x44000000),
              offset: Offset(0, 0.5),
              blurRadius: 0.2,
            ),
          ],
          fontSize: 100,
        ),
      ),
    );
  }
}

/* ==========================================================
 *  Shared: skew (parallel-strip) rectangle helper
 * ========================================================== */
enum _SkewDirection { shearLeft, shearRight }

class _SkewRect extends StatelessWidget {
  final Color color;
  final BorderRadiusGeometry radius;
  final double skew;
  final _SkewDirection direction;

  const _SkewRect({
    required this.color,
    required this.radius,
    required this.skew,
    required this.direction,
  });

  @override
  Widget build(BuildContext context) {
    final matrix = Matrix4.skewX(
      direction == _SkewDirection.shearLeft ? -0.12 : 0.12,
    );
    return Transform(
      alignment: Alignment.center,
      transform: matrix,
      child: Container(
        decoration: BoxDecoration(color: color, borderRadius: radius),
      ),
    );
  }
}
