import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:local_auth/local_auth.dart';
import 'package:wallet/l10n/app_localizations.dart';
import 'package:wallet/models/theme_provider.dart';
import 'package:wallet/models/startup_settings_provider.dart';
import 'package:wallet/services/app_initialization_service.dart';
import 'package:wallet/services/brand_icon_service.dart';
import 'package:wallet/services/encryption_service.dart';
import 'models/auto_backup_provider.dart';
import 'models/provider_helper.dart';
import 'screens/homescreen.dart';
import 'package:provider/provider.dart';
import 'package:wallet/services/auto_backup_service.dart';
import 'dart:io' show Platform;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final themeProvider = ThemeProvider();
  final startupProvider = StartupSettingsProvider();
  final autoBackupProvider = AutoBackupProvider();

  await Future.wait([
    themeProvider.init(),
    startupProvider.loadStartupSettings(),
    autoBackupProvider.init(),
    AppInitializationService.initializeApp(),
    BrandIconService.instance.ensureInitialized(),
  ]);

  AutoBackupService.initialize(autoBackupProvider);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => WalletProvider()),
        ChangeNotifierProvider(create: (context) => PassProvider()),
        ChangeNotifierProvider(create: (context) => IdentityProvider()),
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: startupProvider),
        ChangeNotifierProvider.value(value: autoBackupProvider),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return Selector<ThemeProvider, ({ThemeMode themeMode, bool useSystemFont})>(
      selector: (_, provider) => (
        themeMode: provider.currentTheme,
        useSystemFont: provider.useSystemFont,
      ),
      builder: (context, data, _) {
        final themeProvider = Provider.of<ThemeProvider>(
          context,
          listen: false,
        );
        return MaterialApp(
          onGenerateTitle: (context) =>
              AppLocalizations.of(context)?.appTitle ?? '钱包',
          debugShowCheckedModeBanner: false,
          theme: themeProvider.lightTheme,
          darkTheme: themeProvider.darkTheme,
          themeMode: data.themeMode,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('zh'),
          home: const SplashScreen(),
        );
      },
    );
  }
}

/// 认证守卫：包装应用主界面，当应用从后台/锁屏返回时要求重新认证
class AuthGuard extends StatefulWidget {
  final Widget child;

  const AuthGuard({super.key, required this.child});

  @override
  State<AuthGuard> createState() => _AuthGuardState();
}

class _AuthGuardState extends State<AuthGuard> with WidgetsBindingObserver {
  bool _isAuthenticating = false;
  bool _isLocked = false;
  bool _isInBackground = false;
  DateTime? _pausedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    final startupProvider = Provider.of<StartupSettingsProvider>(
      context,
      listen: false,
    );

    // 如果没有开启认证，只清除图片缓存
    if (!startupProvider.showAuthenticationScreen) {
      if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
        EncryptionService.instance.clearImageCache();
      }
      return;
    }

    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      _pausedAt = DateTime.now();
      _isInBackground = true;
      // 立即锁定，防止在任务切换器中显示应用内容
      if (mounted) {
        setState(() {
          _isLocked = true;
        });
      }
      EncryptionService.instance.clearImageCache();
    } else if (state == AppLifecycleState.resumed) {
      // 如果是从后台返回（锁屏或切换应用），需要重新认证
      if (_isInBackground && _pausedAt != null) {
        final pausedDuration = DateTime.now().difference(_pausedAt!);
        // 超过1秒的后台停留就要求重新认证
        if (pausedDuration.inSeconds >= 1) {
          // 下一帧触发认证
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _performReAuth();
          });
        } else {
          // 短暂后台切换（如下拉通知栏），直接解锁
          if (mounted) {
            setState(() {
              _isLocked = false;
            });
          }
        }
      }
      _isInBackground = false;
      _pausedAt = null;
    } else if (state == AppLifecycleState.inactive) {
      // 应用进入非活动状态（来电、权限弹窗等）
      if (!_isInBackground) {
        _pausedAt = DateTime.now();
      }
    }
  }

  Future<void> _performReAuth() async {
    if (_isAuthenticating) return;
    _isAuthenticating = true;

    try {
      if (Platform.isLinux || kIsWeb) {
        if (mounted) {
          setState(() {
            _isLocked = false;
          });
        }
        return;
      }

      final auth = LocalAuthentication();
      bool isBiometricSupported = await auth.isDeviceSupported();
      bool canCheckBiometrics = await auth.canCheckBiometrics;

      if (!isBiometricSupported || !canCheckBiometrics) {
        if (mounted) {
          setState(() {
            _isLocked = false;
          });
        }
        return;
      }

      bool authenticated = false;
      while (!authenticated && mounted) {
        try {
          authenticated = await auth.authenticate(
            localizedReason: AppLocalizations.of(context)!.splashAuthReason,
            options: const AuthenticationOptions(
              stickyAuth: true,
              useErrorDialogs: true,
            ),
          );
        } catch (_) {
          authenticated = false;
        }

        if (authenticated && mounted) {
          setState(() {
            _isLocked = false;
          });
        } else if (!authenticated && mounted) {
          final shouldExit = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: Text(AppLocalizations.of(context)!.splashAuthRequiredTitle),
              content: Text(AppLocalizations.of(context)!.splashAuthRequiredMessage),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(AppLocalizations.of(context)!.splashAuthRetry),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(AppLocalizations.of(context)!.splashAuthExit),
                ),
              ],
            ),
          );
          if (shouldExit == true) {
            SystemNavigator.pop();
            return;
          }
        }
      }
    } finally {
      _isAuthenticating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final textColor = isDark ? Colors.white : Colors.black;

    return Stack(
      children: [
        widget.child,
        if (_isLocked)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                color: isDark ? Colors.black : Colors.white,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lock_rounded,
                        size: 64,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        AppLocalizations.of(context)!.appTitle.toUpperCase(),
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          letterSpacing: 6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _iconSlideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _iconSlideAnimation = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.1, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preCacheAssets();
      _checkStartupSettings();
    });
  }

  void _preCacheAssets() {
    final networks = ['visa', 'mastercard', 'amex', 'discover', 'rupay'];
    for (final network in networks) {
      precacheImage(AssetImage('assets/network/$network.png'), context);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkStartupSettings() async {
    final startupProvider = Provider.of<StartupSettingsProvider>(
      context,
      listen: false,
    );

    if (startupProvider.showAuthenticationScreen) {
      await _performAuthentication();
    } else {
      _navigateToHomeScreen();
    }
  }

  void _navigateToHomeScreen() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const AuthGuard(child: HomeScreen()),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return child;
          },
          transitionDuration: Duration.zero,
        ),
      );
    }
  }

  Future<void> _performAuthentication() async {
    if (Platform.isLinux || kIsWeb) {
      _navigateToHomeScreen();
      return;
    }

    final auth = LocalAuthentication();
    bool isBiometricSupported = await auth.isDeviceSupported();
    bool canCheckBiometrics = await auth.canCheckBiometrics;

    if (isBiometricSupported && canCheckBiometrics) {
      bool authenticated = false;
      while (!authenticated && mounted) {
        authenticated = await auth.authenticate(
          localizedReason: AppLocalizations.of(context)!.splashAuthReason,
          options: const AuthenticationOptions(
            stickyAuth: true,
            useErrorDialogs: true,
          ),
        );
        if (!authenticated && mounted) {
          // User canceled or failed - show dialog before exiting
          final shouldExit = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: Text(AppLocalizations.of(context)!.splashAuthRequiredTitle),
              content:
                  Text(AppLocalizations.of(context)!.splashAuthRequiredMessage),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(AppLocalizations.of(context)!.splashAuthRetry),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(AppLocalizations.of(context)!.splashAuthExit),
                ),
              ],
            ),
          );
          if (shouldExit == true) {
            SystemNavigator.pop();
            return;
          }
        }
      }
      if (authenticated && mounted) {
        _navigateToHomeScreen();
      }
    } else {
      _navigateToHomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final textColor = isDark ? Colors.white : Colors.black;

    SystemChrome.setSystemUIOverlayStyle(
      isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
    );

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Transform.translate(
                      offset: Offset(0, _iconSlideAnimation.value),
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(32),
                          color: isDark
                              ? const Color(0xFF1A1A1A)
                              : const Color(0xFFF0F0F0),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF2A2A2A)
                                : const Color(0xFFE0E0E0),
                            width: 0.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: textColor.withValues(alpha: 0.08),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            Icons.wallet_rounded,
                            size: 56,
                            color: textColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.translate(
                    offset: Offset(0, _iconSlideAnimation.value * 1.2),
                    child: Column(
                      children: [
                        Text(
                          AppLocalizations.of(context)!.appTitle.toUpperCase(),
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                            letterSpacing: 8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppLocalizations.of(context)!.splashTagline,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white54 : Colors.black45,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.translate(
                    offset: Offset(0, _iconSlideAnimation.value * 1.5),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark
                            ? const Color(0xFF1A1A1A)
                            : const Color(0xFFF5F5F5),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
