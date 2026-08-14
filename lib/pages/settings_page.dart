// ignore_for_file: deprecated_member_use

import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:wallet/models/theme_provider.dart';
import 'package:wallet/models/startup_settings_provider.dart';
import 'package:wallet/services/backup_service.dart';
import 'package:wallet/models/provider_helper.dart';
import 'package:wallet/models/db_helper.dart';
import 'package:wallet/models/auto_backup_provider.dart';
import 'package:wallet/services/saf_service.dart';
import 'package:wallet/l10n/app_localizations.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String? _pendingBackupUri;

  @override
  void initState() {
    super.initState();
  }

  Future<bool> _authenticateForDestructiveAction() async {
    if (Platform.isLinux) return true;
    final auth = LocalAuthentication();
    final isDeviceSupported = await auth.isDeviceSupported();
    if (!isDeviceSupported) return true;
    final l = AppLocalizations.of(context)!;
    return await auth.authenticate(
      localizedReason: l.authenticateAction,
      options: const AuthenticationOptions(stickyAuth: true),
    );
  }

  String _getThemeDisplayName(ThemePreference preference, AppLocalizations l) {
    switch (preference) {
      case ThemePreference.light:
        return l.themeLight;
      case ThemePreference.dark:
        return l.themeDark;
      case ThemePreference.system:
        return l.themeSystem;
    }
  }

  String _getDefaultScreenName(int index, AppLocalizations l) {
    switch (index) {
      case 0:
        return l.navPayments;
      case 1:
        return l.navPasses;
      case 2:
        return l.navIdentity;
      default:
        return l.navPayments;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final startupProvider = Provider.of<StartupSettingsProvider>(context);
    final autoBackupProvider = Provider.of<AutoBackupProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.settingsTitle),
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF0F0F0),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: isDark ? Colors.white : Colors.black,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSponsorshipBanner(context, isDark),
          const SizedBox(height: 16),
          _LiquidGlassSection(
            title: l.sectionStartupLayout,
            icon: Icons.rocket_launch_outlined,
            children: [
              _LiquidGlassTile(
                icon: Icons.shield_outlined,
                title: l.authScreenTitle,
                subtitle: l.authScreenSubtitle,
                trailing: Switch(
                  value: startupProvider.showAuthenticationScreen,
                  onChanged: (_) {
                    startupProvider.toggleAuthenticationScreen();
                  },
                ),
              ),
              Divider(
                color: isDark
                    ? const Color(0xFF2A2A2A)
                    : const Color(0xFFE8E8E8),
                height: 1,
              ),
              _LiquidGlassTile(
                icon: Icons.payments_outlined,
                title: l.currencyTitle,
                subtitle:
                    '${startupProvider.selectedCurrencyCode} (${startupProvider.selectedCurrencySymbol})',
                onTap: () => _showCurrencyDialog(context, startupProvider),
              ),
              Divider(
                color: isDark
                    ? const Color(0xFF2A2A2A)
                    : const Color(0xFFE8E8E8),
                height: 1,
              ),
              if (!startupProvider.paymentsOnlyMode) ...[
                _LiquidGlassTile(
                  icon: Icons.home_filled,
                  title: l.defaultScreenTitle,
                  subtitle: _getDefaultScreenName(
                    startupProvider.defaultScreenIndex,
                    l,
                  ),
                  onTap: () =>
                      _showDefaultScreenDialog(context, startupProvider),
                ),
                Divider(
                  color: isDark
                      ? const Color(0xFF2A2A2A)
                      : const Color(0xFFE8E8E8),
                  height: 1,
                ),
              ],
              _LiquidGlassTile(
                icon: Icons.credit_card_rounded,
                title: l.paymentsOnlyTitle,
                subtitle: l.paymentsOnlySubtitle,
                trailing: Switch(
                  value: startupProvider.paymentsOnlyMode,
                  onChanged: (_) {
                    startupProvider.togglePaymentsOnlyMode();
                  },
                ),
              ),
            ],
          ),

          _LiquidGlassSection(
            title: l.sectionAppearance,
            icon: Icons.palette_outlined,
            children: [
              _LiquidGlassTile(
                icon: Icons.brightness_6_outlined,
                title: l.appThemeTitle,
                subtitle: _getThemeDisplayName(themeProvider.themePreference, l),
                onTap: () => _showThemeDialog(context, themeProvider),
              ),
              Divider(
                color: isDark
                    ? const Color(0xFF2A2A2A)
                    : const Color(0xFFE8E8E8),
                height: 1,
              ),
              _LiquidGlassTile(
                icon: Icons.font_download_outlined,
                title: l.useSystemFontTitle,
                subtitle: l.useSystemFontSubtitle,
                trailing: Switch(
                  value: themeProvider.useSystemFont,
                  onChanged: (_) => themeProvider.toggleFont(),
                ),
              ),
            ],
          ),

          _LiquidGlassSection(
            title: l.sectionDataManagement,
            icon: Icons.storage_outlined,
            children: [
              _LiquidGlassTile(
                icon: Icons.sync_rounded,
                title: l.autoBackupTitle,
                subtitle: _getAutoBackupSubtitle(autoBackupProvider, l),
                trailing: Switch(
                  value: autoBackupProvider.isEnabled,
                  onChanged: (value) async {
                    if (value) {
                      await _showEnableAutoBackupDialog(autoBackupProvider);
                    } else {
                      await autoBackupProvider.setEnabled(false);
                    }
                  },
                ),
              ),
              if (autoBackupProvider.isEnabled) ...[
                Divider(
                  color: isDark
                      ? const Color(0xFF2A2A2A)
                      : const Color(0xFFE8E8E8),
                  height: 1,
                ),
                _LiquidGlassTile(
                  icon: Icons.folder_outlined,
                  title: l.backupLocationTitle,
                  subtitle: _getShortPath(autoBackupProvider.backupPath, l),
                  onTap: () => _pickAutoBackupPath(autoBackupProvider),
                ),
                Divider(
                  color: isDark
                      ? const Color(0xFF2A2A2A)
                      : const Color(0xFFE8E8E8),
                  height: 1,
                ),
                _LiquidGlassTile(
                  icon: Icons.lock_outline_rounded,
                  title: l.changeBackupPasswordTitle,
                  subtitle: l.changeBackupPasswordSubtitle,
                  onTap: () =>
                      _showChangeAutoBackupPasswordDialog(autoBackupProvider),
                ),
              ],
              Divider(
                color: isDark
                    ? const Color(0xFF2A2A2A)
                    : const Color(0xFFE8E8E8),
                height: 1,
              ),
              _LiquidGlassTile(
                icon: Icons.backup_outlined,
                title: l.createBackupTitle,
                subtitle: l.createBackupSubtitle,
                onTap: () => _showBackupDialog(themeProvider),
              ),
              Divider(
                color: isDark
                    ? const Color(0xFF2A2A2A)
                    : const Color(0xFFE8E8E8),
                height: 1,
              ),
              _LiquidGlassTile(
                icon: Icons.restore_outlined,
                title: l.restoreBackupTitle,
                subtitle: l.restoreBackupSubtitle,
                onTap: () => _showRestoreDialog(themeProvider),
              ),
              Divider(
                color: isDark
                    ? const Color(0xFF2A2A2A)
                    : const Color(0xFFE8E8E8),
                height: 1,
              ),
              _LiquidGlassTile(
                icon: Icons.delete_forever_outlined,
                title: l.deleteAllDataTitle,
                subtitle: l.deleteAllDataSubtitle,
                onTap: () => _showDeleteAllDataDialog(themeProvider),
              ),
              Divider(
                color: isDark
                    ? const Color(0xFF2A2A2A)
                    : const Color(0xFFE8E8E8),
                height: 1,
              ),
              _LiquidGlassTile(
                icon: Icons.info_outline_rounded,
                title: l.trademarkNoticeTitle,
                subtitle: l.trademarkNoticeSubtitle,
                onTap: () => _showTrademarkNotice(isDark),
              ),
            ],
          ),

          _LiquidGlassSection(
            title: l.sectionAbout,
            icon: Icons.info_outline_rounded,
            children: [
              _LiquidGlassTile(
                icon: Icons.bug_report_outlined,
                title: l.reportErrorTitle,
                subtitle: l.reportErrorSubtitle,
                onTap: () async {
                  HapticFeedback.mediumImpact();
                  const url = 'https://github.com/sidhant947/Wallet/issues';
                  if (await canLaunchUrl(Uri.parse(url))) {
                    await launchUrl(
                      Uri.parse(url),
                      mode: LaunchMode.externalApplication,
                    );
                  }
                },
              ),
            ],
          ),
          SizedBox(height: 30),
        ],
      ),
    );
  }

  void _showTrademarkNotice(bool isDark) {
    final l = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.white,
        title: Text(
          l.trademarkDialogTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Text(l.trademarkDialogBody),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.closeButton),
          ),
        ],
      ),
    );
  }

  void _showCurrencyDialog(
    BuildContext context,
    StartupSettingsProvider provider,
  ) {
    final isDark = Provider.of<ThemeProvider>(
      context,
      listen: false,
    ).isDarkMode;
    final l = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.white,
        title: Text(
          l.chooseCurrency,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: StartupSettingsProvider.majorCurrencies.length,
            itemBuilder: (context, index) {
              final currency = StartupSettingsProvider.majorCurrencies[index];
              return RadioListTile<String>(
                title: Text('${currency['name']} (${currency['symbol']})'),
                value: currency['code']!,
                groupValue: provider.selectedCurrencyCode,
                onChanged: (val) {
                  if (val != null) {
                    provider.setCurrency(val, currency['symbol']!);
                    Navigator.pop(context);
                  }
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showDefaultScreenDialog(
    BuildContext context,
    StartupSettingsProvider provider,
  ) {
    final isDark = Provider.of<ThemeProvider>(
      context,
      listen: false,
    ).isDarkMode;
    final l = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.white,
        title: Text(
          l.chooseDefaultScreen,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRadioOption(l.navPayments, 0, provider.defaultScreenIndex, (v) {
              provider.setDefaultScreen(v);
              Navigator.pop(context);
            }, isDark),
            _buildRadioOption(l.navPasses, 1, provider.defaultScreenIndex, (v) {
              provider.setDefaultScreen(v);
              Navigator.pop(context);
            }, isDark),
            _buildRadioOption(l.navIdentity, 2, provider.defaultScreenIndex, (v) {
              provider.setDefaultScreen(v);
              Navigator.pop(context);
            }, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioOption(
    String label,
    int value,
    int groupValue,
    Function(int) onChanged,
    bool isDark,
  ) {
    return RadioListTile<int>(
      title: Text(label),
      value: value,
      groupValue: groupValue,
      onChanged: (val) {
        if (val != null) onChanged(val);
      },
    );
  }

  void _showThemeDialog(BuildContext context, ThemeProvider themeProvider) {
    final isDark = themeProvider.isDarkMode;
    final l = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.white,
        title: Text(
          l.chooseTheme,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ThemePreference.values
              .map(
                (p) => RadioListTile<ThemePreference>(
                  title: Text(_getThemeDisplayName(p, l)),
                  value: p,
                  groupValue: themeProvider.themePreference,
                  onChanged: (v) {
                    if (v != null) {
                      themeProvider.setThemePreference(v);
                      Navigator.pop(context);
                    }
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  String _getAutoBackupSubtitle(AutoBackupProvider provider, AppLocalizations l) {
    if (!provider.isEnabled) return l.autoBackupSubtitleOff;
    final path = provider.displayPath;
    if (path.isEmpty) return l.autoBackupSubtitleNoPath;
    return l.autoBackupSubtitleActive(_getShortPath(path, l));
  }

  String _getShortPath(String path, AppLocalizations l) {
    if (path.isEmpty) return l.pathNotSet;
    final parts = path.split('/');
    if (parts.length <= 3) return path;
    return '.../${parts.sublist(parts.length - 2).join('/')}';
  }

  Future<void> _showEnableAutoBackupDialog(
    AutoBackupProvider provider,
  ) async {
    final isDark = Provider.of<ThemeProvider>(
      context,
      listen: false,
    ).isDarkMode;
    final l = AppLocalizations.of(context)!;
    final pathController = TextEditingController();
    final passwordController = TextEditingController();
    bool obscure = true;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.white,
          title: Text(
            l.enableAutoBackupTitle,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.enableAutoBackupBody,
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black87,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l.backupLocationTitle,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final result = await SafService.pickDirectory();
                    if (result != null) {
                      final segments = Uri.parse(result).pathSegments;
                      final displayPath = segments.isNotEmpty ? segments.last : result;
                      setDialogState(() {
                        pathController.text = displayPath;
                      });
                      _pendingBackupUri = result;
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF2A2A2A)
                            : const Color(0xFFE0E0E0),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.folder_outlined,
                          color: isDark ? Colors.white54 : Colors.black54,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            pathController.text.isEmpty
                                ? l.selectDirectoryHint
                                : pathController.text,
                            style: TextStyle(
                              color: pathController.text.isEmpty
                                  ? (isDark ? Colors.white38 : Colors.black38)
                                  : (isDark ? Colors.white : Colors.black),
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l.backupPasswordLabel,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: passwordController,
                  obscureText: obscure,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  decoration: InputDecoration(
                    hintText: l.enterPasswordHint,
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscure ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () => setDialogState(() {
                        obscure = !obscure;
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l.cancelButton),
            ),
            FilledButton(
              onPressed: () async {
                if (pathController.text.isEmpty) return;
                if (passwordController.text.length < 8) return;
                if (_pendingBackupUri == null) return;

                await provider.setBackupUri(_pendingBackupUri!);
                await provider.setBackupPath(pathController.text);
                await provider.setBackupPassword(passwordController.text);
                await provider.setEnabled(true);

                _pendingBackupUri = null;
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              child: Text(l.enableButton),
            ),
          ],
        ),
      ),
    );
  }

  void _pickAutoBackupPath(AutoBackupProvider provider) async {
    final result = await SafService.pickDirectory();
    if (result != null) {
      await provider.setBackupUri(result);
      final segments = Uri.parse(result).pathSegments;
      final displayPath = segments.isNotEmpty ? segments.last : result;
      await provider.setBackupPath(displayPath);
    }
  }

  void _showChangeAutoBackupPasswordDialog(
    AutoBackupProvider provider,
  ) {
    final isDark = Provider.of<ThemeProvider>(
      context,
      listen: false,
    ).isDarkMode;
    final l = AppLocalizations.of(context)!;
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.white,
        title: Text(
          l.changeBackupPasswordTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
          ),
          decoration: InputDecoration(
            hintText: l.enterNewPasswordHint,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l.cancelButton),
          ),
          FilledButton(
            onPressed: () async {
              if (passwordController.text.length < 8) return;
              await provider.setBackupPassword(passwordController.text);
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: Text(l.saveButtonText),
          ),
        ],
      ),
    );
  }

  void _showBackupDialog(ThemeProvider themeProvider) async {
    final authenticated = await _authenticateForDestructiveAction();
    if (!authenticated || !mounted) return;
    final isDark = themeProvider.isDarkMode;
    final l = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (dialogContext) => _LiquidGlassPasswordDialog(
        title: l.createBackupTitle,
        content: l.createBackupDialogBody,
        buttonText: l.createBackupButton,
        isDark: isDark,
        onConfirm: (password) async {
          try {
            await BackupService.createBackup(password, saveDialogTitle: l.saveBackupDialogTitle);
            if (!mounted) return;
            if (dialogContext.mounted) {
              Navigator.pop(dialogContext);
            }
          } catch (_) {
            if (!mounted) return;
            if (dialogContext.mounted) {
              Navigator.pop(dialogContext);
            }
          }
        },
      ),
    );
  }

  void _showRestoreDialog(ThemeProvider themeProvider) async {
    final authenticated = await _authenticateForDestructiveAction();
    if (!authenticated || !mounted) return;
    final isDark = themeProvider.isDarkMode;
    final l = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (dialogContext) => _LiquidGlassPasswordDialog(
        title: l.restoreBackupTitle,
        content: l.restoreBackupDialogBody,
        buttonText: l.restoreButton,
        isDestructive: true,
        isDark: isDark,
        validatePassword: false,
        onConfirm: (password) async {
          try {
            final walletProvider = context.read<WalletProvider>();
            final passProvider = context.read<PassProvider>();
            final identityProvider = context.read<IdentityProvider>();
            final tProvider = context.read<ThemeProvider>();
            final sProvider = context.read<StartupSettingsProvider>();

            await BackupService.restoreBackup(password, context: dialogContext);

            if (dialogContext.mounted) {
              Navigator.pop(dialogContext);
            }

            if (!mounted) return;

            // Reload all providers to reflect restored data and settings
            walletProvider.fetchWallets();
            passProvider.fetchPasses();
            identityProvider.fetchIdentities();
            await tProvider.init();
            await sProvider.loadStartupSettings();

            if (!mounted) return;
          } catch (_) {
            if (dialogContext.mounted) {
              Navigator.pop(dialogContext);
            }
            if (!mounted) return;
          }
        },
      ),
    );
  }

  void _showDeleteAllDataDialog(ThemeProvider themeProvider) async {
    final authenticated = await _authenticateForDestructiveAction();
    if (!authenticated || !mounted) return;
    final isDark = themeProvider.isDarkMode;
    final l = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.white,
        title: Text(l.deleteAllDataTitle),
        content: Text(l.deleteAllDataBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancelButton),
          ),
          FilledButton(
            onPressed: () async {
              await _performDeleteAllData();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l.deleteEverythingButton),
          ),
        ],
      ),
    );
  }

  Future<void> _performDeleteAllData() async {
    final walletProvider = context.read<WalletProvider>();
    final passProvider = context.read<PassProvider>();
    final identityProvider = context.read<IdentityProvider>();

    try {
      // Bulk delete wallets
      final wallets = await DatabaseHelper.instance.getWallets();
      if (wallets.isNotEmpty) {
        final db = await DatabaseHelper.instance.database;
        final batch = db.batch();
        for (var w in wallets) {
          if (w.id != null) {
            batch.delete('wallets', where: 'id = ?', whereArgs: [w.id]);
          }
        }
        await batch.commit(noResult: true);
        // Delete image files
        for (var w in wallets) {
          await DatabaseHelper.deleteImageFile(w.frontImagePath);
          await DatabaseHelper.deleteImageFile(w.backImagePath);
        }
      }

      // Bulk delete passes
      final passes = await PassDatabaseHelper.instance.getAllPasses();
      if (passes.isNotEmpty) {
        final db = await PassDatabaseHelper.instance.database;
        final batch = db.batch();
        for (var p in passes) {
          if (p.id != null) {
            batch.delete('passes', where: 'id = ?', whereArgs: [p.id]);
          }
        }
        await batch.commit(noResult: true);
        for (var p in passes) {
          await DatabaseHelper.deleteImageFile(p.frontImagePath);
          await DatabaseHelper.deleteImageFile(p.backImagePath);
          await DatabaseHelper.deleteImageFile(p.stripImagePath);
          await DatabaseHelper.deleteImageFile(p.thumbnailImagePath);
        }
      }

      // Bulk delete identities
      final identities = await IdentityDatabaseHelper.instance.getAllIdentities();
      if (identities.isNotEmpty) {
        final db = await IdentityDatabaseHelper.instance.database;
        final batch = db.batch();
        for (var i in identities) {
          if (i.id != null) {
            batch.delete('identities', where: 'id = ?', whereArgs: [i.id]);
          }
        }
        await batch.commit(noResult: true);
        for (var i in identities) {
          await DatabaseHelper.deleteImageFile(i.frontImagePath);
          await DatabaseHelper.deleteImageFile(i.backImagePath);
        }
      }

      final directory = await getApplicationDocumentsDirectory();
      final dir = Directory(directory.path);
      if (await dir.exists()) {
        final deleteFutures = <Future>[];
        for (var f in dir.listSync()) {
          if (f is File) {
            final basename = f.path.split(Platform.pathSeparator).last;
            final isTimestampImage = RegExp(r'^\d{16,}\.(png|jpg)$').hasMatch(basename);
            if (basename.endsWith('.enc') || isTimestampImage) {
              deleteFutures.add(f.delete());
            }
          }
        }
        if (deleteFutures.isNotEmpty) {
          await Future.wait(deleteFutures);
        }
      }

      if (!mounted) return;

      walletProvider.fetchWallets();
      passProvider.fetchPasses();
      identityProvider.fetchIdentities();
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.allDataDeleted)));
    } catch (_) {
      if (!mounted) return;
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.deleteFailedRetry)));
    }
  }

  Widget _buildSponsorshipBanner(BuildContext context, bool isDark) {
    final l = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () async {
        HapticFeedback.mediumImpact();
        const url = 'https://ko-fi.com/sidhant947';
        if (await canLaunchUrl(Uri.parse(url))) {
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE8E8E8),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.coffee_outlined,
              size: 20,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l.buyMeACoffee,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: isDark ? Colors.white30 : Colors.black38,
            ),
          ],
        ),
      ),
    );
  }
}

class _LiquidGlassSection extends StatelessWidget {
  final String title;
  final IconData? icon;
  final List<Widget> children;
  const _LiquidGlassSection({
    required this.title,
    this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final color = isDark ? Colors.white38 : Colors.black38;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8, top: 12),
          child: Row(
            children: [
              if (icon != null) Icon(icon, size: 14, color: color),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Material(
            color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE8E8E8),
                  width: 0.5,
                ),
              ),
              child: Column(children: children),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _LiquidGlassTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  const _LiquidGlassTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final textColor = isDark ? Colors.white : Colors.black;
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEEEEEE),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: textColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(
                color: isDark ? Colors.white54 : Colors.black54,
                fontSize: 12,
              ),
            )
          : null,
      trailing:
          trailing ??
          (onTap != null
              ? Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: isDark ? Colors.white30 : Colors.black26,
                )
              : null),
    );
  }
}

class _LiquidGlassPasswordDialog extends StatefulWidget {
  final String title;
  final String content;
  final String buttonText;
  final bool isDestructive;
  final bool isDark;
  final bool validatePassword;
  final Future<void> Function(String) onConfirm;
  const _LiquidGlassPasswordDialog({
    required this.title,
    required this.content,
    required this.buttonText,
    this.isDestructive = false,
    required this.isDark,
    this.validatePassword = true,
    required this.onConfirm,
  });

  @override
  State<_LiquidGlassPasswordDialog> createState() =>
      _LiquidGlassPasswordDialogState();
}

class _LiquidGlassPasswordDialogState
    extends State<_LiquidGlassPasswordDialog> {
  late final TextEditingController _passwordController;
  bool _isLoading = false;
  bool _obscure = true;
  String? _passwordError;

  static const int _minPasswordLength = 8;

  @override
  void initState() {
    super.initState();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _validateAndConfirm() {
    final password = _passwordController.text;
    final l = AppLocalizations.of(context)!;
    if (widget.validatePassword && password.length < _minPasswordLength) {
      setState(() {
        _passwordError = l.passwordTooShort(_minPasswordLength);
      });
      return;
    }
    setState(() {
      _passwordError = null;
      _isLoading = true;
    });
    widget.onConfirm(password).then((_) {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AlertDialog(
      backgroundColor: widget.isDark ? const Color(0xFF0A0A0A) : Colors.white,
      title: Text(
        widget.title,
        style: TextStyle(
          color: widget.isDark ? Colors.white : Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.content,
            style: TextStyle(
              color: widget.isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: _obscure,
            style: TextStyle(
              color: widget.isDark ? Colors.white : Colors.black,
            ),
            onChanged: (_) {
              if (_passwordError != null) {
                setState(() => _passwordError = null);
              }
            },
            decoration: InputDecoration(
              labelText: l.passwordLabel,
              errorText: _passwordError,
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.cancelButton),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _validateAndConfirm,
          style: FilledButton.styleFrom(
            backgroundColor: widget.isDestructive
                ? Colors.red
                : (widget.isDark ? Colors.white : Colors.black),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.buttonText),
        ),
      ],
    );
  }
}
