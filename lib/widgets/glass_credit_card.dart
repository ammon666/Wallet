// lib/widgets/glass_credit_card.dart - ULTRA PREMIUM DESIGN

import 'package:flutter/material.dart';
import 'package:wallet/l10n/app_localizations.dart';
import 'package:wallet/models/card_color_data.dart';
import 'package:wallet/services/card_utils.dart';
import 'package:wallet/widgets/network_brand_logos.dart';
import '../models/db_helper.dart';

class GlassCreditCard extends StatefulWidget {
  final Wallet wallet;
  final bool isMasked;
  final VoidCallback onCardTap;

  const GlassCreditCard({
    super.key,
    required this.wallet,
    required this.isMasked,
    required this.onCardTap,
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _IssuerBadge(
                            issuer: widget.wallet.issuer,
                            network: widget.wallet.network,
                          ),
                          if (widget.wallet.cardCategory != null) ...[
                            const SizedBox(height: 4),
                            _CardCategoryBadge(
                              category: widget.wallet.cardCategory!,
                            ),
                          ],
                        ],
                      ),
                      SizedBox(
                        height: 36,
                        child: _NetworkLogo(network: widget.wallet.network),
                      ),
                    ],
                  ),
                  const Spacer(),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      widget.isMasked
                          ? "$firstFour  ••••  ••••  $lastFour"
                          : _formatCardNumber(widget.wallet.number).trim(),
                      style: TextStyle(
                        fontFamily: 'Courier',
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
                  if (widget.wallet.tags != null &&
                      widget.wallet.tags!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      runSpacing: 2,
                      children: widget.wallet.tags!
                          .take(4)
                          .map((tag) => _TagChip(label: tag))
                          .toList(),
                    ),
                  ],
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
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          widget.isMasked
                              ? "••/••"
                              : _formatExpiry(widget.wallet.expiry),
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
    // 优先使用矢量品牌 logo（完全匹配官方色彩与样式）
    final brandLogo = NetworkBrandLogos.build(network, height: 36);
    if (brandLogo != null) {
      return brandLogo;
    }
    return Image.asset(
      "assets/network/${network ?? 'visa'}.png",
      fit: BoxFit.contain,
      height: 36,
      // 注意：不再加 `color: Colors.white`，避免把彩色 logo 全部染白。
      // 只有 silhouette 类图片（全黑/单色）才需要染色，但现有彩色品牌图不允许。
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
