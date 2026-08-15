import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:wallet/services/clipboard_service.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:wallet/models/startup_settings_provider.dart';
import 'package:wallet/pages/add_card_screen.dart';
import 'package:wallet/pages/settings_page.dart';
import 'package:wallet/widgets/barcode_card.dart';
import 'package:wallet/widgets/glass_credit_card.dart';
import 'package:wallet/screens/barcode_card_details_screen.dart';
import 'package:wallet/services/encryption_service.dart';
import '../models/db_helper.dart';
import '../models/provider_helper.dart';
import '../models/theme_provider.dart';
import '../pages/walletdetails.dart';
import 'package:wallet/widgets/identity_card_widget.dart';
import 'package:wallet/screens/identity_card_details_screen.dart';
import 'package:wallet/services/auto_backup_service.dart';
import 'package:wallet/services/card_utils.dart';
import 'package:wallet/l10n/app_localizations.dart';

/// Smooth route builder — used across the app for premium transitions
class SmoothPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  SmoothPageRoute({required this.page})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return child;
        },
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String _selectedFilter = 'all';
  String _selectedPassFilter = 'all';
  String _selectedIssuer = 'all';
  String _selectedCardType = 'all';
  bool _showArchived = false;

  late final TextEditingController _searchController;
  String _searchQuery = "";
  Timer? _debounce;

  // Chunked transfer import state
  final List<String> _transferChunks = [];
  int _expectedTotalChunks = 0;

  StreamSubscription? _intentDataStreamSubscription;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WalletProvider>().fetchWallets();
      context.read<PassProvider>().fetchPasses();
      context.read<IdentityProvider>().fetchIdentities();

      // Initialize selected index from startup settings
      final startupProvider = context.read<StartupSettingsProvider>();
      if (startupProvider.paymentsOnlyMode) {
        setState(() => _selectedIndex = 0);
      } else {
        setState(() => _selectedIndex = startupProvider.defaultScreenIndex);
      }

      _initSharingIntent();
    });

    _searchController.addListener(() {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 300), () {
        if (mounted && _searchQuery != _searchController.text) {
          setState(() {
            _searchQuery = _searchController.text;
          });
        }
      });
    });
  }

  void _initSharingIntent() {
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) return;

    // For sharing images while app is in memory
    _intentDataStreamSubscription = ReceiveSharingIntent.instance.getMediaStream().listen((value) {
      _handleSharedMedia(value);
    }, onError: (_) {});

    // For sharing images when app was closed/opened via intent
    ReceiveSharingIntent.instance.getInitialMedia().then((value) {
      _handleSharedMedia(value);
      ReceiveSharingIntent.instance.reset();
    });
  }

  void _handleSharedMedia(List<SharedMediaFile> value) {
    if (value.isNotEmpty && mounted) {
      final imagePath = value.first.path;
      if (imagePath.isNotEmpty) {
        Navigator.push(
          context,
          SmoothPageRoute(
            page: AddCardScreen(
              initialTabIndex: 1,
              initialSharedImagePath: imagePath,
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _intentDataStreamSubscription?.cancel();
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _scanAndImport() async {
    final l = AppLocalizations.of(context)!;
    try {
      final scanResult = await BarcodeScanner.scan();
      if (scanResult.type != ResultType.Barcode) return;

      final rawData = scanResult.rawContent;

      // V2/V3: Chunked password-based transfer (V2=PBKDF2, V3=Argon2id)
      if (rawData.startsWith('v2:') || rawData.startsWith('v3:')) {
        _handleChunkScan(rawData);
        return;
      }

      // Legacy v1 single-QR transfer
      final decryptedJson = await EncryptionService.instance.decryptFromTransfer(rawData);

      if (decryptedJson == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l.invalidShareCode)),
          );
        }
        return;
      }

      final payload = jsonDecode(decryptedJson) as Map<String, dynamic>;
      final type = payload['type'] as String?;
      final data = payload['data'] as Map<String, dynamic>?;

      if (type == null || data == null || !_isValidImportType(type)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l.invalidShareFormat)),
          );
        }
        return;
      }

      if (type == 'pass') {
        if (!_isValidPassData(data)) {
          _showImportError(l.invalidPassData);
          return;
        }
        final newPass = Pass.fromMap(data);
        if (mounted) {
          final confirm = await _showImportConfirmation(newPass.organizationName, l.typeLabelPass);
          if (confirm == true) {
            await PassDatabaseHelper.instance.insertPass(newPass);
            AutoBackupService.triggerBackup();
            if (mounted) {
              context.read<PassProvider>().fetchPasses();
              _showSuccessSnackBar(l.passImportedSuccess);
            }
          }
        }
      } else if (type == 'wallet') {
        if (!_isValidWalletData(data)) {
          _showImportError(l.invalidCardData);
          return;
        }
        final newWallet = Wallet.fromMap(data);
        if (mounted) {
          final confirm = await _showImportConfirmation(newWallet.name, l.typeLabelPaymentCard);
          if (confirm == true) {
            await DatabaseHelper.instance.insertWallet(newWallet);
            AutoBackupService.triggerBackup();
            if (mounted) {
              context.read<WalletProvider>().fetchWallets();
              _showSuccessSnackBar(l.paymentCardImportedSuccess);
            }
          }
        }
      } else if (type == 'identity') {
        if (!_isValidIdentityData(data)) {
          _showImportError(l.invalidIdentityData);
          return;
        }
        final newIdentity = IdentityCard.fromMap(data);
        if (mounted) {
          final confirm = await _showImportConfirmation(newIdentity.name, l.typeLabelIdentityCard);
          if (confirm == true) {
            await IdentityDatabaseHelper.instance.insertIdentity(newIdentity);
            AutoBackupService.triggerBackup();
            if (mounted) {
              context.read<IdentityProvider>().fetchIdentities();
              _showSuccessSnackBar(l.identityCardImportedSuccess);
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.importFailedCorrupted)),
        );
      }
    }
  }

  void _handleChunkScan(String rawData) {
    final l = AppLocalizations.of(context)!;
    try {
      final parts = rawData.split(':');
      if (parts.length != 6) {
        _showImportError(l.invalidChunkFormat);
        return;
      }

      final chunkIndex = int.parse(parts[1]);
      final totalChunks = int.parse(parts[2]);

      if (chunkIndex < 0 || chunkIndex >= totalChunks) {
        _showImportError(l.invalidChunkIndex);
        return;
      }

      if (_transferChunks.isEmpty) {
        _expectedTotalChunks = totalChunks;
      } else if (_expectedTotalChunks != totalChunks) {
        _showImportError(l.chunkMismatch);
        _transferChunks.clear();
        _expectedTotalChunks = 0;
        return;
      }

      if (!_transferChunks.asMap().containsKey(chunkIndex)) {
        _transferChunks.add(rawData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.scannedChunk(_transferChunks.length, totalChunks)),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 1),
          ),
        );
      }

      if (_transferChunks.length == totalChunks) {
        _promptTransferPassword();
      }
    } catch (_) {
      _showImportError(l.failedParseChunk);
    }
  }

  void _promptTransferPassword() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final controller = TextEditingController();
        bool obscure = true;
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            backgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.white,
            title: Text(l.enterTransferPasswordTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l.enterTransferPasswordBody,
                  style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  obscureText: obscure,
                  decoration: InputDecoration(
                    labelText: l.passwordLabel,
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setDialogState(() => obscure = !obscure),
                    ),
                  ),
                  onSubmitted: (_) => _decryptAndImportChunks(ctx, controller.text),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _transferChunks.clear();
                  _expectedTotalChunks = 0;
                  Navigator.pop(ctx);
                },
                child: Text(l.cancelButton),
              ),
              FilledButton(
                onPressed: () => _decryptAndImportChunks(ctx, controller.text),
                child: Text(l.importButton),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _decryptAndImportChunks(BuildContext ctx, String password) async {
    if (password.isEmpty) return;
    Navigator.pop(ctx);

    final l = AppLocalizations.of(context)!;
    try {
      final joinedData = _transferChunks.join('\n');
      _transferChunks.clear();
      _expectedTotalChunks = 0;

      final decryptedJson = await EncryptionService.instance.decryptFromTransfer(joinedData, password: password);

      if (decryptedJson == null) {
        _showImportError(l.decryptFailed);
        return;
      }

      final payload = jsonDecode(decryptedJson) as Map<String, dynamic>;
      final type = payload['type'] as String?;
      final data = payload['data'] as Map<String, dynamic>?;

      if (type == null || data == null || !_isValidImportType(type)) {
        _showImportError(l.invalidShareFormat);
        return;
      }

      if (type == 'pass') {
        if (!_isValidPassData(data)) {
          _showImportError(l.invalidPassData);
          return;
        }
        final newPass = Pass.fromMap(data);
        if (mounted) {
          final confirm = await _showImportConfirmation(newPass.organizationName, l.typeLabelPass);
          if (confirm == true) {
            await PassDatabaseHelper.instance.insertPass(newPass);
            AutoBackupService.triggerBackup();
            if (mounted) {
              context.read<PassProvider>().fetchPasses();
              _showSuccessSnackBar(l.passImportedSuccess);
            }
          }
        }
      } else if (type == 'wallet') {
        if (!_isValidWalletData(data)) {
          _showImportError(l.invalidCardData);
          return;
        }
        final newWallet = Wallet.fromMap(data);
        if (mounted) {
          final confirm = await _showImportConfirmation(newWallet.name, l.typeLabelPaymentCard);
          if (confirm == true) {
            await DatabaseHelper.instance.insertWallet(newWallet);
            AutoBackupService.triggerBackup();
            if (mounted) {
              context.read<WalletProvider>().fetchWallets();
              _showSuccessSnackBar(l.paymentCardImportedSuccess);
            }
          }
        }
      } else if (type == 'identity') {
        if (!_isValidIdentityData(data)) {
          _showImportError(l.invalidIdentityData);
          return;
        }
        final newIdentity = IdentityCard.fromMap(data);
        if (mounted) {
          final confirm = await _showImportConfirmation(newIdentity.name, l.typeLabelIdentityCard);
          if (confirm == true) {
            await IdentityDatabaseHelper.instance.insertIdentity(newIdentity);
            AutoBackupService.triggerBackup();
            if (mounted) {
              context.read<IdentityProvider>().fetchIdentities();
              _showSuccessSnackBar(l.identityCardImportedSuccess);
            }
          }
        }
      }
    } catch (_) {
      _showImportError(l.importFailedWrongPassword);
    }
  }

  bool _isValidImportType(String type) {
    return type == 'pass' || type == 'wallet' || type == 'identity';
  }

  bool _isValidWalletData(Map<String, dynamic> data) {
    return data.containsKey('name') &&
        data.containsKey('number') &&
        data.containsKey('expiry') &&
        data['name'] is String &&
        data['number'] is String &&
        data['expiry'] is String &&
        (data['name'] as String).isNotEmpty &&
        (data['number'] as String).isNotEmpty;
  }

  bool _isValidPassData(Map<String, dynamic> data) {
    return data.containsKey('type') &&
        data.containsKey('organizationName') &&
        data.containsKey('barcodeValue') &&
        data['type'] is String &&
        data['organizationName'] is String &&
        data['barcodeValue'] is String &&
        (data['organizationName'] as String).isNotEmpty;
  }

  bool _isValidIdentityData(Map<String, dynamic> data) {
    return data.containsKey('name') &&
        data.containsKey('value') &&
        data['name'] is String &&
        data['value'] is String &&
        (data['name'] as String).isNotEmpty &&
        (data['value'] as String).isNotEmpty;
  }

  void _showImportError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<bool?> _showImportConfirmation(String name, String typeLabel) {
    final l = AppLocalizations.of(context)!;
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF0A0A0A) : Colors.white,
        title: Text(l.importSharedTitle(typeLabel)),
        content: Text(l.importSharedBody(name)),
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
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<bool> _authenticateForDestructiveAction() async {
    if (Platform.isLinux) return true;
    final auth = LocalAuthentication();
    final supported = await auth.isDeviceSupported();
    if (!supported) return true;
    final l = AppLocalizations.of(context)!;
    return auth.authenticate(
      localizedReason: l.authenticateAction,
      options: const AuthenticationOptions(stickyAuth: true),
    );
  }

  void _showWalletDeleteConfirmationDialog({
    required int id,
    required String name,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;
    final l = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      barrierColor: isDark ? Colors.black54 : Colors.black26,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.white,
          title: Text(
            l.actionDeletePermanently,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            l.deletePermanentlyConfirmBody(name),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                l.cancelButton,
                style: TextStyle(
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () async {
                HapticFeedback.mediumImpact();
                Navigator.of(ctx).pop();
                final ok = await _authenticateForDestructiveAction();
                if (!ok || !mounted) return;
                await context.read<WalletProvider>().deleteWallet(id);
                if (!mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(l.cardDeleted)));
              },
              child: Text(l.deleteButton),
            ),
          ],
        );
      },
    );
  }

  /// Archive confirmation — no fingerprint needed (non-destructive).
  void _showArchiveConfirmationDialog({
    required int id,
    required String name,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;
    final l = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      barrierColor: isDark ? Colors.black54 : Colors.black26,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.white,
          title: Text(
            l.actionArchive,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            l.archiveConfirmBody(name),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                l.cancelButton,
                style: TextStyle(
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ),
            FilledButton(
              onPressed: () async {
                HapticFeedback.mediumImpact();
                Navigator.of(ctx).pop();
                await context.read<WalletProvider>().archiveWallet(id);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l.cardArchived)),
                );
              },
              child: Text(l.actionArchive),
            ),
          ],
        );
      },
    );
  }

  void _showPassDeleteConfirmationDialog({
    required int id,
    required String name,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;
    final l = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      barrierColor: isDark ? Colors.black54 : Colors.black26,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.white,
          title: Text(
            l.deletePassTitle,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            l.deleteConfirmBody(name),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                l.cancelButton,
                style: TextStyle(
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () async {
                HapticFeedback.mediumImpact();
                Navigator.of(ctx).pop();
                final ok = await _authenticateForDestructiveAction();
                if (!ok || !mounted) return;
                await context.read<PassProvider>().deletePass(id);
                if (!mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(l.passDeleted)));
              },
              child: Text(l.deleteButton),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final startupProvider = Provider.of<StartupSettingsProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final l = AppLocalizations.of(context)!;

    // Force index to 0 (Payments) if hidden mode is on
    final isHiddenMode = startupProvider.paymentsOnlyMode;
    final effectiveIndex = isHiddenMode ? 0 : _selectedIndex;

    return Scaffold(
      appBar: AppBar(
        actions: [
          if (effectiveIndex == 0)
            Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.078) : Colors.black.withValues(alpha: 0.051),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: Icon(
                  _showArchived ? Icons.inventory_2 : Icons.inventory_2_outlined,
                  color: isDark ? Colors.white : Colors.black,
                ),
                tooltip: _showArchived ? l.activeView : l.archivedView,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  final nextArchived = !_showArchived;
                  setState(() {
                    _showArchived = nextArchived;
                    _selectedFilter = 'all';
                    _selectedIssuer = 'all';
                    _selectedCardType = 'all';
                  });
                  if (nextArchived) {
                    context.read<WalletProvider>().fetchArchivedWallets();
                  } else {
                    context.read<WalletProvider>().fetchWallets();
                  }
                },
              ),
            ),
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.078) : Colors.black.withValues(alpha: 0.051),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(Icons.qr_code_scanner_rounded, color: isDark ? Colors.white : Colors.black),
              tooltip: l.scanToImport,
              onPressed: () {
                HapticFeedback.mediumImpact();
                _scanAndImport();
              },
            ),
          ),
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.078)
                  : Colors.black.withValues(alpha: 0.051),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(
                Icons.settings_outlined,
                color: isDark ? Colors.white : Colors.black,
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  SmoothPageRoute(page: const SettingsPage()),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.2),
              blurRadius: 30,
              offset: const Offset(0, 12),
              spreadRadius: -2,
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () async {
            HapticFeedback.mediumImpact();
            final walletProvider = context.read<WalletProvider>();
            final passProvider = context.read<PassProvider>();
            final identityProvider = context.read<IdentityProvider>();
            final result = await Navigator.push(
              context,
              SmoothPageRoute(
                page: AddCardScreen(initialTabIndex: effectiveIndex),
              ),
            );
            if (result == true && mounted) {
              await walletProvider.fetchWallets();
              await passProvider.fetchPasses();
              await identityProvider.fetchIdentities();
            }
          },
          child: const Icon(Icons.add_rounded),
        ),
      ),
      body: IndexedStack(
        key: ValueKey(effectiveIndex),
        index: effectiveIndex,
        children: [
          _buildPaymentsTab(context),
          _buildPassesTab(context),
          _buildIdentitiesTab(context),
        ],
      ),
      bottomNavigationBar: isHiddenMode
          ? null
          : Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.black : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.078)
                        : Colors.black.withValues(alpha: 0.051),
                  ),
                ),
              ),
              child: NavigationBar(
                selectedIndex: effectiveIndex,
                onDestinationSelected: _onItemTapped,
                animationDuration: Duration.zero,
                elevation: 0,
                destinations: <Widget>[
                  NavigationDestination(
                    icon: const Icon(Icons.credit_card_outlined),
                    selectedIcon: const Icon(Icons.credit_card),
                    label: l.navPayments,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.confirmation_number_outlined),
                    selectedIcon: const Icon(Icons.confirmation_number),
                    label: l.navPasses,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.badge_outlined),
                    selectedIcon: const Icon(Icons.badge),
                    label: l.navIdentity,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String message) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.credit_card_outlined,
            size: 80,
            color: isDark ? Colors.white24 : Colors.black26,
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Returns the issuer name for display, falling back to localized "Unknown".
  String _getIssuerName(Wallet wallet, AppLocalizations l) {
    if (wallet.issuer != null && wallet.issuer!.isNotEmpty) {
      return wallet.issuer!;
    }
    return l.unknownIssuer;
  }

  /// Compact dropdown used in the filter row.
  Widget _buildCompactDropdown({
    required String label,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isDark
            ? Colors.white.withValues(alpha: 0.059)
            : Colors.black.withValues(alpha: 0.031),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.102)
              : Colors.black.withValues(alpha: 0.059),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.any((e) => e.value == value) ? value : null,
          isExpanded: true,
          hint: Text(label, style: const TextStyle(fontSize: 13)),
          items: items,
          onChanged: onChanged,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 13,
          ),
          dropdownColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildPaymentsTab(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;
    final l = AppLocalizations.of(context)!;

    return Consumer<WalletProvider>(
      builder: (context, provider, child) {
        final wallets = _showArchived ? provider.archivedWallets : provider.wallets;

        // Always compute filters so the dropdown UI can be rendered even when
        // the wallet list is empty (prevents the "filter bar disappearing,
        // cannot switch back from archived view" bug).
        // 1. Search filter
        final List<Wallet> searchedWallets = _searchQuery.isEmpty
            ? wallets
            : wallets.where((wallet) {
                final query = _searchQuery.toLowerCase();
                final nameMatch = wallet.name.toLowerCase().contains(query);
                final maskedNumber = wallet.number.length >= 4
                    ? '••••${wallet.number.substring(wallet.number.length - 4)}'
                    : wallet.number;
                final numberMatch = maskedNumber.contains(query) ||
                    wallet.number.contains(query);
                final networkMatch = wallet.network?.toLowerCase().contains(query) ?? false;
                final issuerMatch = wallet.issuer?.toLowerCase().contains(query) ?? false;
                final typeMatch = wallet.cardtype?.toLowerCase().contains(query) ?? false;
                return nameMatch || numberMatch || networkMatch || issuerMatch || typeMatch;
              }).toList();

        // 2. Network filter
        final List<Wallet> networkFiltered = searchedWallets.where((wallet) {
          if (_selectedFilter == 'all') return true;
          return wallet.network?.toLowerCase() == _selectedFilter;
        }).toList();

        // 3. Issuer filter
        final List<Wallet> issuerFiltered = networkFiltered.where((wallet) {
          if (_selectedIssuer == 'all') return true;
          return _getIssuerName(wallet, l) == _selectedIssuer;
        }).toList();

        // 4. Category filter (credit / debit / none / all)
        final List<Wallet> filteredWallets = issuerFiltered.where((wallet) {
          if (_selectedCardType == 'all') return true;
          if (_selectedCardType == 'none') return wallet.cardCategory == null;
          return wallet.cardCategory == _selectedCardType;
        }).toList();

        // 5. Unique issuers for dropdown (derived from searched, pre-issuer-filter)
        final uniqueIssuers = <String>{};
        for (final w in searchedWallets) {
          uniqueIssuers.add(_getIssuerName(w, l));
        }
        final sortedIssuers = uniqueIssuers.toList()..sort();

        // 6. Group by issuer (sorted alphabetically; within group by orderIndex)
        final Map<String, List<Wallet>> byIssuer = {};
        for (final w in filteredWallets) {
          final issuer = _getIssuerName(w, l);
          byIssuer.putIfAbsent(issuer, () => []).add(w);
        }
        final groupedIssuers = byIssuer.keys.toList()..sort();

        // 7. Build mixed list [Header, Card, Card, Header, Card, ...]
        final List<_PaymentListItem> items = [];
        for (final issuer in groupedIssuers) {
          items.add(_PaymentListItem.header(issuer, byIssuer[issuer]!.length));
          for (final w in byIssuer[issuer]!) {
            items.add(_PaymentListItem.card(w));
          }
        }

        return CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            // Search field
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.059)
                        : Colors.black.withValues(alpha: 0.031),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.102)
                          : Colors.black.withValues(alpha: 0.059),
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      hintText: l.searchCards,
                      hintStyle: TextStyle(
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear_rounded,
                                color: isDark ? Colors.white54 : Colors.black45,
                              ),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            // Three filter dropdowns (vertical always, no horizontal scroll chips)
            // Row 1: Network (卡组织) full-width — UnionPay first, Mastercard 中文
            // Row 2: Issuer + Type side by side
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    // Row 1 — Network dropdown (full width; 银联 first; 万事达中文)
                    _buildCompactDropdown(
                      label: l.filterNetwork,
                      value: _selectedFilter,
                      items: [
                        // Default value shows field name to be self-describing
                        DropdownMenuItem(value: 'all', child: Text(l.filterAllNetworks)),
                        // 银联 — always first as required
                        DropdownMenuItem(
                          value: 'unionpay',
                          child: Text(CardUtils.networkDisplayNameLocalized('unionpay', l) ?? '银联'),
                        ),
                        DropdownMenuItem(
                          value: 'visa',
                          child: Text(CardUtils.networkDisplayNameLocalized('visa', l) ?? 'VISA'),
                        ),
                        DropdownMenuItem(
                          value: 'mastercard',
                          child: Text(CardUtils.networkDisplayNameLocalized('mastercard', l) ?? '万事达'),
                        ),
                        DropdownMenuItem(
                          value: 'amex',
                          child: Text(CardUtils.networkDisplayNameLocalized('amex', l) ?? 'AMEX'),
                        ),
                        DropdownMenuItem(
                          value: 'discover',
                          child: Text(CardUtils.networkDisplayNameLocalized('discover', l) ?? 'Discover'),
                        ),
                        DropdownMenuItem(
                          value: 'rupay',
                          child: Text(CardUtils.networkDisplayNameLocalized('rupay', l) ?? 'RUPAY'),
                        ),
                        DropdownMenuItem(
                          value: 'jcb',
                          child: Text(CardUtils.networkDisplayNameLocalized('jcb', l) ?? 'JCB'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedFilter = v);
                      },
                      isDark: isDark,
                    ),
                    const SizedBox(height: 8),
                    // Row 2 — Issuer (left) + Card type (right) side by side
                    Row(
                      children: [
                        Expanded(
                          child: _buildCompactDropdown(
                            label: l.filterIssuer,
                            value: _selectedIssuer,
                            items: [
                              DropdownMenuItem(value: 'all', child: Text(l.filterAllIssuers)),
                              ...sortedIssuers.map((issuer) =>
                                  DropdownMenuItem(value: issuer, child: Text(issuer))),
                            ],
                            onChanged: (v) {
                              if (v != null) setState(() => _selectedIssuer = v);
                            },
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildCompactDropdown(
                            label: l.filterType,
                            value: _selectedCardType,
                            items: [
                              DropdownMenuItem(value: 'all', child: Text(l.filterAllCardTypes)),
                              DropdownMenuItem(value: 'credit', child: Text(l.cardCategoryCredit)),
                              DropdownMenuItem(value: 'debit', child: Text(l.cardCategoryDebit)),
                              DropdownMenuItem(value: 'none', child: Text(l.cardCategoryNone)),
                            ],
                            onChanged: (v) {
                              if (v != null) setState(() => _selectedCardType = v);
                            },
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            // If wallets list is totally empty (no cards at all) — show the big
            // empty placeholder WITH its icon, so the user is never stuck without
            // a way to navigate (filters are still visible above).
            if (wallets.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEmptyState(
                  context,
                  _showArchived ? l.noArchivedCards : l.emptyPayments,
                ),
              )
            // Cards exist, but after applying search+filters nothing matches.
            else if (items.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(48.0),
                  child: Center(
                    child: Text(
                      _showArchived ? l.noArchivedCards : l.noCardsFound,
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                  ),
                ),
              )
            // Everything good — show the grouped, reorderable cards list.
            else
              SliverReorderableList(
                itemCount: items.length,
                onReorder: (oldIndex, newIndex) {
                  // Headers cannot be dragged; archived view is read-only for reorder.
                  if (items[oldIndex].isHeader) return;
                  if (_showArchived) return;

                  // Find the group boundaries for the dragged card.
                  int groupStart = oldIndex;
                  while (groupStart > 0 && !items[groupStart].isHeader) {
                    groupStart--;
                  }
                  int groupEnd = oldIndex + 1;
                  while (groupEnd < items.length && !items[groupEnd].isHeader) {
                    groupEnd++;
                  }

                  // Only allow reordering within the same issuer group.
                  if (newIndex <= groupStart || newIndex > groupEnd) return;

                  // Convert mixed-list indices to filtered-list (wallet-only) indices.
                  int oldFilteredIndex = 0;
                  for (int i = 0; i < oldIndex; i++) {
                    if (!items[i].isHeader) oldFilteredIndex++;
                  }
                  int newFilteredIndex = 0;
                  for (int i = 0; i < newIndex; i++) {
                    if (!items[i].isHeader) newFilteredIndex++;
                  }

                  HapticFeedback.lightImpact();
                  context.read<WalletProvider>().reorderDisplayWallets(
                        filteredWallets,
                        oldFilteredIndex,
                        newFilteredIndex,
                      );
                },
                itemBuilder: (context, index) {
                  final item = items[index];

                  // Group header — not draggable, not reorderable.
                  if (item.isHeader) {
                    return Container(
                      key: ValueKey('header_${item.headerText}'),
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.account_balance_outlined,
                            size: 14,
                            color: (isDark ? Colors.white : Colors.black)
                                .withValues(alpha: 0.4),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            item.headerText!,
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: (isDark ? Colors.white : Colors.black)
                                      .withValues(alpha: 0.5),
                                  letterSpacing: 0.5,
                                ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${item.headerCount}',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: (isDark ? Colors.white : Colors.black)
                                      .withValues(alpha: 0.3),
                                ),
                          ),
                        ],
                      ),
                    );
                  }

                  final wallet = item.wallet!;
                  return ReorderableDelayedDragStartListener(
                    key: ValueKey(wallet.id),
                    index: index,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                      child: Slidable(
                        key: ValueKey('slidable_${wallet.id}'),
                        startActionPane: _showArchived
                            ? null
                            : ActionPane(
                                motion: const BehindMotion(),
                                extentRatio: 0.25,
                                children: [
                                  SlidableAction(
                                    onPressed: (ctx) async {
                                      HapticFeedback.lightImpact();
                                      final provider = ctx.read<WalletProvider>();
                                      final fullWallet =
                                          await provider.getWalletDetails(wallet.id!);
                                      if (fullWallet != null && ctx.mounted) {
                                        Navigator.push(
                                          ctx,
                                          SmoothPageRoute(
                                            page: WalletEditScreen(wallet: fullWallet),
                                          ),
                                        );
                                      }
                                    },
                                    backgroundColor: Colors.transparent,
                                    foregroundColor: Colors.blue,
                                    icon: Icons.edit_outlined,
                                    label: l.actionEdit,
                                  ),
                                ],
                              ),
                        endActionPane: ActionPane(
                          motion: const BehindMotion(),
                          extentRatio: _showArchived ? 0.5 : 0.45,
                          children: _showArchived
                              ? [
                                  SlidableAction(
                                    onPressed: (ctx) async {
                                      HapticFeedback.mediumImpact();
                                      await context
                                          .read<WalletProvider>()
                                          .unarchiveWallet(wallet.id!);
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(l.cardUnarchived)),
                                      );
                                    },
                                    backgroundColor: Colors.transparent,
                                    foregroundColor: Colors.green,
                                    icon: Icons.unarchive_outlined,
                                    label: l.actionUnarchive,
                                  ),
                                  SlidableAction(
                                    onPressed: (ctx) {
                                      HapticFeedback.mediumImpact();
                                      _showWalletDeleteConfirmationDialog(
                                        id: wallet.id!,
                                        name: wallet.name,
                                      );
                                    },
                                    backgroundColor: Colors.transparent,
                                    foregroundColor: Colors.red,
                                    icon: Icons.delete_forever_rounded,
                                    label: l.actionDeletePermanently,
                                  ),
                                ]
                              : [
                                  SlidableAction(
                                    onPressed: (ctx) {
                                      HapticFeedback.mediumImpact();
                                      ClipboardService.instance.copy(wallet.number);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(l.cardNumberCopied),
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          duration: const Duration(seconds: 1),
                                        ),
                                      );
                                    },
                                    backgroundColor: Colors.transparent,
                                    foregroundColor: Colors.blue,
                                    icon: Icons.copy_rounded,
                                    label: l.actionCopy,
                                  ),
                                  SlidableAction(
                                    onPressed: (ctx) {
                                      HapticFeedback.mediumImpact();
                                      _showArchiveConfirmationDialog(
                                        id: wallet.id!,
                                        name: wallet.name,
                                      );
                                    },
                                    backgroundColor: Colors.transparent,
                                    foregroundColor: Colors.orange,
                                    icon: Icons.archive_outlined,
                                    label: l.actionArchive,
                                  ),
                                ],
                        ),
                        child: GlassCreditCard(
                          wallet: wallet,
                          isMasked: true,
                          onCardTap: () async {
                            final navCtx = context;
                            final provider = navCtx.read<WalletProvider>();
                            final fullWallet =
                                await provider.getWalletDetails(wallet.id!);
                            if (fullWallet != null && navCtx.mounted) {
                              Navigator.push(
                                navCtx,
                                SmoothPageRoute(
                                  page: WalletDetailScreen(wallet: fullWallet),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            // Bottom padding
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        );
      },
    );
  }

  Widget _buildPassesTab(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;
    final l = AppLocalizations.of(context)!;

    return Consumer<PassProvider>(
      builder: (context, provider, child) {
        final passes = provider.passes;
        if (passes.isEmpty) {
          return _buildEmptyState(
            context,
            l.emptyPasses,
          );
        }

        final searchedPasses = provider.searchPasses(_searchQuery);
        final filteredPasses = searchedPasses.where((pass) {
          if (_selectedPassFilter == 'all') return true;
          // Handle legacy types mapping to modern equivalents
          if (_selectedPassFilter == 'loyaltyCard' && pass.type == 'storeCard') return true;
          if (_selectedPassFilter == 'offer' && pass.type == 'coupon') return true;
          return pass.type == _selectedPassFilter;
        }).toList();

        return CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            // Search field
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: isDark ? Colors.white.withValues(alpha: 0.059) : Colors.black.withValues(alpha: 0.031),
                    border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.102) : Colors.black.withValues(alpha: 0.059)),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      hintText: l.searchPasses,
                      hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear_rounded, color: isDark ? Colors.white54 : Colors.black45),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ),
            // Filter chips
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SegmentedButton<String>(
                    segments: [
                      ButtonSegment<String>(value: 'all', label: Text(l.filterAll)),
                      ButtonSegment<String>(value: 'loyaltyCard', label: Text(l.filterLoyalty)),
                      ButtonSegment<String>(value: 'giftCard', label: Text(l.filterGiftCards)),
                      ButtonSegment<String>(value: 'offer', label: Text(l.filterOffers)),
                      ButtonSegment<String>(value: 'boardingPass', label: Text(l.filterBoarding)),
                      ButtonSegment<String>(value: 'eventTicket', label: Text(l.filterEvents)),
                      ButtonSegment<String>(value: 'transitPass', label: Text(l.filterTransit)),
                      ButtonSegment<String>(value: 'healthInsuranceCard', label: Text(l.filterHealth)),
                      ButtonSegment<String>(value: 'campusId', label: Text(l.filterCampus)),
                      ButtonSegment<String>(value: 'corporateBadge', label: Text(l.filterCorporate)),
                      ButtonSegment<String>(value: 'hotelKey', label: Text(l.filterHotel)),
                      ButtonSegment<String>(value: 'generic', label: Text(l.filterOther)),
                    ],
                    showSelectedIcon: false,
                    selected: <String>{_selectedPassFilter},
                    onSelectionChanged: (Set<String> newSelection) {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedPassFilter = newSelection.first);
                    },
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            // Passes list
            if (filteredPasses.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(48.0),
                  child: Center(
                        child: Text(
                          l.noPassesFound,
                          style: TextStyle(color: isDark ? Colors.white54 : Colors.black45),
                        ),
                      ),
                    ),
                  )
            else
              SliverReorderableList(
              itemCount: filteredPasses.length,
              // ignore: deprecated_member_use
              onReorder: (oldIndex, newIndex) {
                HapticFeedback.lightImpact();
                context.read<PassProvider>().reorderPasses(oldIndex, newIndex);
              },
              itemBuilder: (context, index) {
                final pass = filteredPasses[index];
                return ReorderableDelayedDragStartListener(
                  key: ValueKey(pass.id),
                  index: index,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Slidable(
                      key: ValueKey(pass.id),
                      startActionPane: ActionPane(
                        motion: const BehindMotion(),
                        extentRatio: 0.25,
                        children: [
                          SlidableAction(
                            onPressed: (ctx) async {
                              HapticFeedback.lightImpact();
                              final result = await Navigator.push(
                                ctx,
                                SmoothPageRoute(
                                  page: PassEditScreen(pass: pass),
                                ),
                              );
                              if (result == true && ctx.mounted) {
                                ctx.read<PassProvider>().fetchPasses();
                              }
                            },
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.blue,
                            icon: Icons.edit_outlined,
                            label: l.actionEdit,
                          ),
                        ],
                      ),
                      endActionPane: ActionPane(
                        motion: const BehindMotion(),
                        extentRatio: 0.45,
                        children: [
                          SlidableAction(
                            onPressed: (ctx) {
                              HapticFeedback.mediumImpact();
                              ClipboardService.instance.copy(pass.barcodeValue);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(l.passDataCopied),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            },
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.blue,
                            icon: Icons.copy_rounded,
                            label: l.actionCopy,
                          ),
                          SlidableAction(
                            onPressed: (context) => _showPassDeleteConfirmationDialog(
                              id: pass.id!,
                              name: pass.organizationName,
                            ),
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.red,
                            icon: Icons.delete_outline_rounded,
                            label: l.actionDelete,
                          ),
                        ],
                      ),
                      child: BarcodeCard(
                        pass: pass,
                        onCardTap: () async {
                          HapticFeedback.selectionClick();
                          final passProvider = Provider.of<PassProvider>(context, listen: false);
                          final result = await Navigator.push(
                            context,
                            SmoothPageRoute(page: BarcodeCardDetailScreen(pass: pass)),
                          );
                          if (result == true && mounted) {
                            await passProvider.fetchPasses();
                          }
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        );
      },
    );
  }
  void _showIdentityDeleteConfirmationDialog({
    required int id,
    required String name,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;
    final l = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      barrierColor: isDark ? Colors.black54 : Colors.black26,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.white,
          title: Text(
            l.deleteIdentityTitle,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            l.deleteConfirmBody(name),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                l.cancelButton,
                style: TextStyle(
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () async {
                HapticFeedback.mediumImpact();
                Navigator.of(ctx).pop();
                final ok = await _authenticateForDestructiveAction();
                if (!ok || !mounted) return;
                await context.read<IdentityProvider>().deleteIdentity(id);
                if (!mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(l.identityDeleted)));
              },
              child: Text(l.deleteButton),
            ),
          ],
        );
      },
    );
  }

  Widget _buildIdentitiesTab(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;
    final l = AppLocalizations.of(context)!;

    return Consumer<IdentityProvider>(
      builder: (context, provider, child) {
        final identities = provider.identities;
        if (identities.isEmpty) {
          return _buildEmptyState(
            context,
            l.emptyIdentities,
          );
        }

        final filteredIdentities = provider.searchIdentities(_searchQuery);

        return CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            // Search field
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: isDark ? Colors.white.withValues(alpha: 0.059) : Colors.black.withValues(alpha: 0.031),
                    border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.102) : Colors.black.withValues(alpha: 0.059)),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      hintText: l.searchIdentities,
                      hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear_rounded, color: isDark ? Colors.white54 : Colors.black45),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            if (filteredIdentities.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(48.0),
                  child: Center(
                    child: Text(
                      l.noIdentitiesFound,
                      style: TextStyle(color: isDark ? Colors.white54 : Colors.black45),
                    ),
                  ),
                ),
              )
            else
              SliverReorderableList(
              itemCount: filteredIdentities.length,
              // ignore: deprecated_member_use
              onReorder: (oldIndex, newIndex) {
                HapticFeedback.lightImpact();
                context.read<IdentityProvider>().reorderIdentities(oldIndex, newIndex);
              },
              itemBuilder: (context, index) {
                final card = filteredIdentities[index];
                return ReorderableDelayedDragStartListener(
                  key: ValueKey(card.id),
                  index: index,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Slidable(
                      key: ValueKey(card.id),
                      startActionPane: ActionPane(
                        motion: const BehindMotion(),
                        extentRatio: 0.25,
                        children: [
                          SlidableAction(
                            onPressed: (ctx) async {
                              HapticFeedback.lightImpact();
                              final result = await Navigator.push(
                                ctx,
                                SmoothPageRoute(
                                  page: IdentityEditScreen(card: card),
                                ),
                              );
                              if (result == true && ctx.mounted) {
                                ctx.read<IdentityProvider>().fetchIdentities();
                              }
                            },
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.blue,
                            icon: Icons.edit_outlined,
                            label: l.actionEdit,
                          ),
                        ],
                      ),
                      endActionPane: ActionPane(
                        motion: const BehindMotion(),
                        extentRatio: 0.45,
                        children: [
                          SlidableAction(
                            onPressed: (ctx) {
                              HapticFeedback.mediumImpact();
                              ClipboardService.instance.copy(card.value);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(l.idValueCopied),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            },
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.blue,
                            icon: Icons.copy_rounded,
                            label: l.actionCopy,
                          ),
                          SlidableAction(
                            onPressed: (context) => _showIdentityDeleteConfirmationDialog(
                              id: card.id!,
                              name: card.name,
                            ),
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.red,
                            icon: Icons.delete_outline_rounded,
                            label: l.actionDelete,
                          ),
                        ],
                      ),
                      child: IdentityCardWidget(
                        card: card,
                        onTap: () async {
                           HapticFeedback.selectionClick();
                           final identityProvider = Provider.of<IdentityProvider>(context, listen: false);
                           final result = await Navigator.push(
                             context,
                             SmoothPageRoute(page: IdentityCardDetailScreen(card: card)),
                           );
                           if (result == true && mounted) {
                             await identityProvider.fetchIdentities();
                           }
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        );
      },
    );
  }
}

/// Mixed-list item for the grouped payments tab: either a group header or a wallet card.
class _PaymentListItem {
  final bool isHeader;
  final String? headerText;
  final Wallet? wallet;
  final int headerCount;

  const _PaymentListItem._({
    required this.isHeader,
    this.headerText,
    this.wallet,
    this.headerCount = 0,
  });

  factory _PaymentListItem.header(String text, int count) {
    return _PaymentListItem._(
      isHeader: true,
      headerText: text,
      headerCount: count,
    );
  }

  factory _PaymentListItem.card(Wallet wallet) {
    return _PaymentListItem._(isHeader: false, wallet: wallet);
  }
}
