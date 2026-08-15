import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wallet/l10n/app_localizations.dart';
import 'package:wallet/models/db_helper.dart';
import 'package:wallet/models/provider_helper.dart';
import 'package:wallet/models/startup_settings_provider.dart';
import 'package:wallet/models/theme_provider.dart';
import 'package:wallet/pages/card_scanner_page.dart';
import 'package:wallet/services/auto_backup_service.dart';
import 'package:wallet/services/pkpass_service.dart';
import 'package:wallet/widgets/barcode_card_entry_form.dart';
import 'package:wallet/widgets/color_picker.dart';
import 'package:wallet/widgets/credit_card_entry_form.dart';
import 'package:wallet/widgets/identity_card_entry_form.dart';

class AddCardScreen extends StatefulWidget {
  final int initialTabIndex;
  final String? initialSharedImagePath;

  const AddCardScreen({
    super.key,
    this.initialTabIndex = 0,
    this.initialSharedImagePath,
  });

  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  /// When the user taps the "scan card" entry-point (top-right of Add card
  /// screen) we run a full card scan → then REBUILD the
  /// [CreditCardEntryForm] passing this result so every field is pre-filled
  /// AND the front/back images are attached.
  CardScannerResult? _scannerResult;

  Future<void> _importPkpass() async {
    final l = AppLocalizations.of(context)!;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pkpass'],
      );

      if (result != null && result.files.single.path != null) {
        final pass = await PkpassService.instance.parsePkpass(
          result.files.single.path!,
        );
        if (pass != null) {
          if (mounted) {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(l.importPassTitle),
                content: Text(
                  l.importPassBody(pass.organizationName),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(l.cancelButton),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(l.importButton),
                  ),
                ],
              ),
            );

            if (confirm == true) {
              await PassDatabaseHelper.instance.insertPass(pass);
              AutoBackupService.triggerBackup();
              if (mounted) {
                context.read<PassProvider>().fetchPasses();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l.passImportedSuccessShort)),
                );
                Navigator.pop(context, true);
              }
            }
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l.pkpassParseFailed)),
            );
          }
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.passImportFailed)),
        );
      }
    }
  }

  Future<void> _launchFullCardScan() async {
    final result = await Navigator.push<CardScannerResult>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const CardScannerPage(mode: CardScannerMode.fullCard),
      ),
    );
    if (!mounted || result == null) return;
    // OCR did not find anything at all → still show the form (let the user
    // type it manually) but keep the cropped images as attachments.
    setState(() => _scannerResult = result);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final startupProvider = Provider.of<StartupSettingsProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;
    final textColor = isDark ? Colors.white : Colors.black;
    final l = AppLocalizations.of(context)!;

    final int effectiveIndex = startupProvider.paymentsOnlyMode ? 0 : widget.initialTabIndex;

    // Gather colors already used by existing cards/passes/identities
    // so the default Apple-palette color does not repeat when avoidable.
    final existingColors = <String>{};
    final walletProvider = context.read<WalletProvider>();
    for (final w in walletProvider.wallets) {
      if (w.color != null && w.color!.isNotEmpty) existingColors.add(w.color!);
    }
    final passProvider = context.read<PassProvider>();
    for (final p in passProvider.passes) {
      if (p.backgroundColor != null && p.backgroundColor!.isNotEmpty) {
        existingColors.add(p.backgroundColor!);
      }
    }
    final identityProvider = context.read<IdentityProvider>();
    for (final i in identityProvider.identities) {
      if (i.color != null && i.color!.isNotEmpty) existingColors.add(i.color!);
    }

    Widget form;

    switch (effectiveIndex) {
      case 1:
        form = BarcodeCardEntryForm(
          initialSharedImagePath: widget.initialSharedImagePath,
          initialColor: ColorPicker.pickAppleCardColorDefault(
            excludeColors: existingColors,
          ),
        );
        break;
      case 2:
        form = IdentityCardEntryForm(
          initialColor: ColorPicker.pickAppleCardColorDefault(
            excludeColors: existingColors,
          ),
        );
        break;
      case 0:
      default:
        form = CreditCardEntryForm(
          initialColor: ColorPicker.pickAppleCardColorDefault(
            excludeColors: existingColors,
          ),
          initialScanResult: _scannerResult,
        );
        break;
    }

    return Scaffold(
      appBar: AppBar(
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF0F0F0),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: textColor,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        actions: [
          if (effectiveIndex == 0)
            Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextButton.icon(
                icon: Icon(
                  Icons.document_scanner_outlined,
                  color: textColor,
                  size: 18,
                ),
                label: Text(
                  l.addCardActionScan,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onPressed: _launchFullCardScan,
              ),
            ),
          if (effectiveIndex == 1)
            Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextButton.icon(
                icon: Icon(
                  Icons.file_download_outlined,
                  color: textColor,
                  size: 18,
                ),
                label: Text(
                  l.importPkpass,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onPressed: _importPkpass,
              ),
            ),
        ],
      ),
      body: form,
    );
  }
}
