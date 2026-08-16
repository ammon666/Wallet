// lib/widgets/glass_credit_card.dart - ULTRA PREMIUM DESIGN

import 'package:flutter/material.dart';
import 'package:wallet/l10n/app_localizations.dart';
import 'package:wallet/models/card_color_data.dart';
import 'package:wallet/services/brand_icon_service.dart';
import 'package:wallet/services/card_utils.dart';
import 'package:wallet/widgets/network_brand_logos.dart';
import '../models/db_helper.dart';

class GlassCreditCard extends StatefulWidget {
  final Wallet wallet;
  final bool isMasked;
  final VoidCallback onCardTap;

  /// Show the CVV on the bottom row, to the left of the expiry. Intended
  /// only for the detail page where the user has explicitly unlocked the
  /// card; the home list tiles leave this as `false`.
  final bool showCvv;

  /// Whether the CVV digits are visible (or masked with bullets).
  final bool cvvRevealed;

  /// Optional tap handler for the reveal-eye icon next to the CVV. The
  /// widget does not manage reveal state internally; it mirrors the value
  /// of [cvvRevealed] and calls this back when the user taps the icon.
  final VoidCallback? onCvvRevealToggle;

  const GlassCreditCard({
    super.key,
    required this.wallet,
    required this.isMasked,
    required this.onCardTap,
    this.showCvv = false,
    this.cvvRevealed = false,
    this.onCvvRevealToggle,
  });

  @override
  State<GlassCreditCard> createState() => _GlassCreditCardState();
}

class _GlassCreditCardState extends State<GlassCreditCard> {
  static final RegExp _fourDigitPattern = RegExp(r".{4}");

  String _formatCardNumber(String input) {
    return input.replaceAllMapped(
      _fourDigitPattern,
      (match) => "${match.group(0)} ",
    );
  }

  String _formatExpiry(String input) {
    if (input.length != 4) return "MM/YY";
    return "${input.substring(0, 2)}/${input.substring(2, 4)}";
  }

  bool get _cvvHasValue {
    final cvv = widget.wallet.cvv;
    return cvv != null && cvv.isNotEmpty;
  }

  /// Renders the CVV label shown next to the expiry on the card detail view.
  ///
  /// Mirrors the existing "reveal" semantics: dots by default, digits when
  /// the parent has flipped [widget.cvvRevealed] to `true`.
  String _renderCvvText() {
    final l = AppLocalizations.of(context);
    final cvv = widget.wallet.cvv;
    if (!_cvvHasValue) return l?.naValue ?? 'N/A';
    return widget.cvvRevealed ? cvv! : '•' * cvv!.length;
  }

  @override
  Widget build(BuildContext context) {
    final number = widget.wallet.number;
    final firstFour = number.length >= 8 ? number.substring(0, 4) : '';
    final lastFour = number.length >= 4
        ? number.substring(number.length - 4)
        : number;

    final String colorKey = widget.wallet.color ?? '#0F0F0F';
    final CardColorData colorData = CardColorData.fromHexOrKey(colorKey);

    return Material(
      color: Colors.transparent,
      child: RepaintBoundary(
        child: GestureDetector(
          onTap: widget.onCardTap,
          child: _buildFront(colorData, firstFour, lastFour),
        ),
      ),
    );
  }

  Widget _buildFront(CardColorData colorData, String firstFour, String lastFour) {
    return AspectRatio(
      aspectRatio: 1.586,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomRight,
                    colors: [
                      colorData.accent,
                      colorData.secondary,
                      colorData.primary,
                    ],
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 20.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Top-left: 发卡行图标（与右上角卡组织使用同样 36dp 外层容器，
                      // 高度标尺对齐，视觉上完全对称。）
                      SizedBox(
                        height: 36,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: _IssuerBadge(
                            issuer: widget.wallet.issuer,
                            network: widget.wallet.network,
                          ),
                        ),
                      ),
                      // Top-right: 卡组织 logo
                      SizedBox(
                        height: 36,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: _NetworkLogo(network: widget.wallet.network),
                        ),
                      ),
                    ],
                  ),
                  // 卡类型徽章 + 自定义 Tags：合并成一行显示，放在卡号上方；
                  // 卡类型永远放在首位，使用 SingleChildScrollView 以防
                  // 标签过多溢出（超宽时左右滑）。
                  if ((widget.wallet.cardCategory != null) ||
                      (widget.wallet.tags != null &&
                          widget.wallet.tags!.isNotEmpty)) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 28,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            if (widget.wallet.cardCategory != null)
                              _CardCategoryBadge(
                                category: widget.wallet.cardCategory!,
                              ),
                            if (widget.wallet.tags != null &&
                                widget.wallet.tags!.isNotEmpty) ...[
                              if (widget.wallet.cardCategory != null)
                                const SizedBox(width: 6),
                              ...widget.wallet.tags!
                                  .take(6)
                                  .map(
                                    (tag) => Padding(
                                      padding: const EdgeInsets.only(right: 4.0),
                                      child: _TagChip(label: tag),
                                    ),
                                  )
                                  .toList(),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      widget.isMasked
                          ? "$firstFour  ••••  ••••  $lastFour"
                          : _formatCardNumber(widget.wallet.number).trim(),
                      maxLines: 1,
                      style: TextStyle(
                        // 不再使用 'Courier' 等宽字体，与卡片上其它文字
                        // （姓名/有效期/发卡行 fallback text 等）使用同
                        // 一套默认字体。外层 FittedBox + maxLines:1 保
                        // 证卡号不会被拆成两行。
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withValues(alpha: 0.941),
                        letterSpacing: 2.0,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.392),
                            offset: const Offset(1, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          widget.wallet.name.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      // --- CVV（左） + 有效期（右），中间留较大间距 ---
                      if (widget.showCvv) ...[
                        const SizedBox(width: 12),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _renderCvvText(),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.5,
                              ),
                            ),
                            if (_cvvHasValue && widget.onCvvRevealToggle != null)
                              Padding(
                                padding: const EdgeInsets.only(left: 4.0),
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: widget.onCvvRevealToggle,
                                  child: Icon(
                                    widget.cvvRevealed
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    size: 16,
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        // 明确要求的：CVV 与有效期之间要空一些距离间隔。
                        const SizedBox(width: 32),
                      ],
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          _formatExpiry(widget.wallet.expiry),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Issuer (发卡行) badge shown in the top-left corner of the card.
/// Priority:
///   1. Custom issuer text entered by the user (e.g. "招商银行" / "ICBC").
///   2. Fallback to the card network display name
///      (Visa / Mastercard / 银联 / JCB / ...).
class _IssuerBadge extends StatelessWidget {
  final String? issuer;
  final String? network;

  const _IssuerBadge({this.issuer, this.network});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    // 优先使用 txt 文件中打包的发卡行 SVG 图标；找不到再使用文字 fallback。
    final icon = BrandIconService.instance.buildIssuerIcon(
      context,
      (issuer != null && issuer!.trim().isNotEmpty) ? issuer : null,
      // 与卡组织 buildNetworkIcon 的默认 height 完全一致，保证大小标尺对齐。
      height: 30,
    );
    if (icon != null) {
      // 与卡组织（_NetworkLogo）保持一致：不加任何外框/背景，直接展示。
      return icon;
    }
    final raw = (issuer != null && issuer!.trim().isNotEmpty)
        ? issuer!.trim()
        : (CardUtils.networkDisplayNameLocalized(network, l) ?? 'CARD');
    final display = raw.length > 8 ? '${raw.substring(0, 8)}…' : raw;
    return Container(
      constraints: const BoxConstraints(maxWidth: 150),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: Text(
        display,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _NetworkLogo extends StatelessWidget {
  final String? network;

  const _NetworkLogo({required this.network});

  @override
  Widget build(BuildContext context) {
    const double targetHeight = 32;
    // 优先使用 txt 文件中打包的卡组织 SVG 图标（统一高度保证大小一致）。
    final svgIcon = BrandIconService.instance.buildNetworkIcon(
      context,
      network,
      height: targetHeight,
    );
    if (svgIcon != null) {
      return svgIcon;
    }
    // Fallback 1: 现有的 CustomPaint 矢量 logo。
    final brandLogo = NetworkBrandLogos.build(network, height: targetHeight);
    if (brandLogo != null) {
      return SizedBox(height: targetHeight, child: brandLogo);
    }
    // Fallback 2: assets 目录下的 PNG。
    return Image.asset(
      "assets/network/${network ?? 'visa'}.png",
      fit: BoxFit.contain,
      height: targetHeight,
      errorBuilder: (context, error, stackTrace) {
        final l = AppLocalizations.of(context)!;
        return Text(
          CardUtils.networkDisplayNameLocalized(network, l) ?? 'CARD',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            fontStyle: FontStyle.italic,
          ),
        );
      },
    );
  }
}

/// Small badge showing card category (信用卡 / 借记卡) on the card face.
class _CardCategoryBadge extends StatelessWidget {
  final String category;

  const _CardCategoryBadge({required this.category});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final label = category == 'credit'
        ? l.cardCategoryCredit
        : category == 'debit'
            ? l.cardCategoryDebit
            : category;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Small semi-transparent chip for displaying a custom tag on the card face.
class _TagChip extends StatelessWidget {
  final String label;

  const _TagChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
