import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wallet/services/clipboard_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:wallet/services/brand_icon_service.dart';
import 'package:wallet/services/image_service.dart';
import 'package:wallet/widgets/color_picker.dart';
import 'package:wallet/screens/homescreen.dart';
import 'package:wallet/models/db_helper.dart';
import 'package:wallet/models/provider_helper.dart';
import 'package:wallet/models/theme_provider.dart';
import 'package:wallet/models/startup_settings_provider.dart';
import 'package:wallet/services/card_utils.dart';
import 'package:wallet/services/auto_backup_service.dart';
import 'package:wallet/widgets/full_screen_image_viewer.dart';
import 'package:wallet/widgets/glass_credit_card.dart';
import 'package:wallet/widgets/encrypted_image_display.dart';
import 'package:wallet/screens/share_secure_screen.dart';
import 'package:wallet/l10n/app_localizations.dart';
import 'dart:io';

// WalletDetailScreen with liquid glass design
class WalletDetailScreen extends StatefulWidget {
  final Wallet wallet;
  const WalletDetailScreen({super.key, required this.wallet});
  @override
  State<WalletDetailScreen> createState() => _WalletDetailScreenState();
}

class _WalletDetailScreenState extends State<WalletDetailScreen> {
  late Wallet currentWallet;

  @override
  void initState() {
    super.initState();
    currentWallet = widget.wallet;
  }

  String _formatCashback(String? spends, String? rewards, String symbol) {
    if (spends == null ||
        rewards == null ||
        spends.isEmpty ||
        rewards.isEmpty) {
      return '${symbol}0.00';
    }
    double spendsVal = double.tryParse(spends) ?? 0;
    double rewardsVal = double.tryParse(rewards) ?? 0;
    double result = (spendsVal * rewardsVal) / 100;
    return '$symbol${result.toStringAsFixed(2)}';
  }

  String _getFeeWaiverStatus(Wallet wallet, String symbol, AppLocalizations l) {
    double spends = double.tryParse(wallet.spends ?? '0') ?? 0;
    double waiverRequirement =
        double.tryParse(wallet.annualFeeWaiver ?? '0') ?? 0;
    if (waiverRequirement == 0) return l.feeWaiverNotApplicable;
    if (spends >= waiverRequirement) return l.feeWaiverWaived;
    return l.feeWaiverRemaining(symbol, (waiverRequirement - spends).toStringAsFixed(2));
  }

  Widget _buildImageThumbnail(String imagePath, String label, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                SmoothPageRoute(
                  page: FullScreenImageViewer(imagePath: imagePath),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.102)
                      : Colors.black.withValues(alpha: 0.078),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.302)
                        : Colors.black.withValues(alpha: 0.078),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: EncryptedImageDisplay(
                  imagePath: imagePath,
                  height: 100,
                  width: 150,
                  fit: BoxFit.cover,
                  cacheHeight: 200,
                  cacheWidth: 300,
                  errorWidget: Container(
                    height: 100,
                    width: 150,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.051)
                        : Colors.black.withValues(alpha: 0.031),
                    child: Icon(
                      Icons.error_outline,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final startupProvider = Provider.of<StartupSettingsProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final symbol = startupProvider.selectedCurrencySymbol;
    final l = AppLocalizations.of(context)!;
    bool isPathValid(String? path) => path != null && path.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const SizedBox.shrink(),
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.078)
                : Colors.black.withValues(alpha: 0.051),
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
        actions: [
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
                Icons.share_rounded,
                color: isDark ? Colors.white : Colors.black,
              ),
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.push(
                  context,
                  SmoothPageRoute(page: ShareSecureScreen(wallet: currentWallet)),
                );
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
                Icons.edit_outlined,
                color: isDark ? Colors.white : Colors.black,
              ),
              onPressed: () async {
                final updatedWallet = await Navigator.push<Wallet>(
                  context,
                  SmoothPageRoute(
                    page: WalletEditScreen(wallet: currentWallet),
                  ),
                );

                if (updatedWallet != null && mounted) {
                  setState(() {
                    currentWallet = updatedWallet;
                  });
                }
              },
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          GlassCreditCard(
            isMasked: false,
            wallet: currentWallet,
            showCvv: true,
            onCardTap: () async {
              final copied =
                  await ClipboardService.instance.copy(currentWallet.number);
              if (!copied || !mounted) return;
              final messenger = ScaffoldMessenger.of(context);
              // Always dismiss any existing toast first so rapid taps don't
              // queue up multiple "已复制" SnackBars on top of each other.
              messenger.hideCurrentSnackBar();
              messenger.showSnackBar(
                SnackBar(
                  content: Text(l.cardNumberCopiedBang),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          if (isPathValid(currentWallet.frontImagePath) ||
              isPathValid(currentWallet.backImagePath))
            _LiquidGlassDetailSection(
              title: l.walletDetailCardImages,
              icon: Icons.photo_library_outlined,
              children: [
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (isPathValid(currentWallet.frontImagePath))
                        _buildImageThumbnail(
                          currentWallet.frontImagePath!,
                          l.frontLabel,
                          isDark,
                        ),
                      if (isPathValid(currentWallet.backImagePath))
                        _buildImageThumbnail(
                          currentWallet.backImagePath!,
                          l.backLabel,
                          isDark,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          // 财务信息和账单条款已移除
          if (currentWallet.customFields != null &&
              currentWallet.customFields!.isNotEmpty)
            _LiquidGlassDetailSection(
              title: l.walletDetailCustomFields,
              icon: Icons.tune_outlined,
              children: currentWallet.customFields!.entries.map((entry) {
                return _LiquidGlassDetailTile(
                  icon: Icons.info_outline,
                  title: entry.key,
                  value: entry.value,
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

// --- WalletEditScreen with liquid glass design ---
class WalletEditScreen extends StatefulWidget {
  final Wallet wallet;
  const WalletEditScreen({super.key, required this.wallet});
  @override
  WalletEditScreenState createState() => WalletEditScreenState();
}

class WalletEditScreenState extends State<WalletEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController,
      _numberController,
      _expiryController,
      _cvvController,
      _issuerController,
      _maxlimitController,
      _spendsController,
      _cardtypeController,
      _billdateController,
      _categoryController,
      _annualFeeWaiverController,
      _rewardsController,
      _tagController;
  late String _network;
  late String _selectedColor;
  /// 发卡行下拉当前选择；值为 [BrandIconService.issuerOtherSentinel] 时
  /// 下方显示 TextField 让用户手动输入「其他」发卡行。
  late String _selectedIssuer;
  String? _cardCategory;
  final List<String> _tags = [];
  final _numberFocusNode = FocusNode();
  final _expiryFocusNode = FocusNode();
  final List<TextEditingController> _customFieldNameControllers = [];
  final List<TextEditingController> _customFieldValueControllers = [];

  File? _frontImageFile;
  File? _backImageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final wallet = widget.wallet;
    _nameController = TextEditingController(text: wallet.name);
    _numberController = TextEditingController(text: wallet.number);
    _expiryController = TextEditingController(text: wallet.expiry);
    _cvvController = TextEditingController(text: wallet.cvv);
    _network = wallet.network ?? "visa";
    _issuerController = TextEditingController(text: wallet.issuer);
    _maxlimitController = TextEditingController(text: wallet.maxlimit);
    _spendsController = TextEditingController(text: wallet.spends);
    _cardtypeController = TextEditingController(text: wallet.cardtype);
    _billdateController = TextEditingController(text: wallet.billdate);
    _categoryController = TextEditingController(text: wallet.category);
    _annualFeeWaiverController = TextEditingController(
      text: wallet.annualFeeWaiver,
    );
    _rewardsController = TextEditingController(text: wallet.rewards);
    _tagController = TextEditingController();
    _cardCategory = wallet.cardCategory;
    _tags.addAll(wallet.tags ?? []);
    _selectedColor = wallet.color ?? 'default';

    // Validate on focus loss (Feature 5)
    _numberFocusNode.addListener(() {
      if (!_numberFocusNode.hasFocus) {
        _formKey.currentState?.validate();
      }
    });
    _expiryFocusNode.addListener(() {
      if (!_expiryFocusNode.hasFocus) {
        _formKey.currentState?.validate();
      }
    });

    if (wallet.frontImagePath != null && wallet.frontImagePath!.isNotEmpty) {
      _frontImageFile = File(wallet.frontImagePath!);
    }
    if (wallet.backImagePath != null && wallet.backImagePath!.isNotEmpty) {
      _backImageFile = File(wallet.backImagePath!);
    }

    if (wallet.customFields != null) {
      wallet.customFields!.forEach((key, value) {
        _customFieldNameControllers.add(TextEditingController(text: key));
        _customFieldValueControllers.add(TextEditingController(text: value));
      });
    }

    _nameController.addListener(_updatePreview);
    _numberController.addListener(() {
      // Auto-detect and select card network
      final detected = CardUtils.detectCardNetwork(_numberController.text);
      if (detected != null && detected != _network) {
        setState(() => _network = detected);
      }
      _updatePreview();
    });
    _expiryController.addListener(_updatePreview);
    _issuerController.addListener(_updatePreview);
    // 发卡行下拉默认选择：wallet.issuer 在库里则选中；否则走「其他」。
    final brand = BrandIconService.instance;
    final issuer = wallet.issuer ?? '';
    if (issuer.isNotEmpty && brand.availableIssuers.contains(issuer)) {
      _selectedIssuer = issuer;
    } else {
      _selectedIssuer = BrandIconService.issuerOtherSentinel;
    }
  }

  @override
  void dispose() {
    _nameController.removeListener(_updatePreview);
    _numberController.removeListener(_updatePreview);
    _expiryController.removeListener(_updatePreview);
    _nameController.dispose();
    _numberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _issuerController.dispose();
    _maxlimitController.dispose();
    _spendsController.dispose();
    _cardtypeController.dispose();
    _billdateController.dispose();
    _categoryController.dispose();
    _annualFeeWaiverController.dispose();
    _rewardsController.dispose();
    _tagController.dispose();
    _numberFocusNode.dispose();
    _expiryFocusNode.dispose();
    for (var controller in _customFieldNameControllers) {
      controller.dispose();
    }
    for (var controller in _customFieldValueControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _updatePreview() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _pickImage(ImageSource source, bool isFront) async {
    final pickedFile = await _picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (pickedFile != null) {
      setState(() {
        if (isFront) {
          _frontImageFile = File(pickedFile.path);
        } else {
          _backImageFile = File(pickedFile.path);
        }
      });
    }
  }

  void _addCustomField() {
    setState(() {
      _customFieldNameControllers.add(TextEditingController());
      _customFieldValueControllers.add(TextEditingController());
    });
  }

  void _removeCustomField(int index) {
    setState(() {
      _customFieldNameControllers[index].dispose();
      _customFieldValueControllers[index].dispose();
      _customFieldNameControllers.removeAt(index);
      _customFieldValueControllers.removeAt(index);
    });
  }

  /// Get maximum card number length
  int _getMaxCardLength(String network) {
    return 19;
  }

  void _saveUpdatedDetails() async {
    final provider = context.read<WalletProvider>();
    final navigator = Navigator.of(context);

    if (_formKey.currentState!.validate()) {
      Map<String, String> customFields = {};
      for (int i = 0; i < _customFieldNameControllers.length; i++) {
        String fieldName = _customFieldNameControllers[i].text.trim();
        String fieldValue = _customFieldValueControllers[i].text.trim();
        if (fieldName.isNotEmpty && fieldValue.isNotEmpty) {
          customFields[fieldName] = fieldValue;
        }
      }

      String? frontImagePath = widget.wallet.frontImagePath;
      if (_frontImageFile != null &&
          _frontImageFile!.path != widget.wallet.frontImagePath) {
        frontImagePath = await saveImageToAppDirectory(_frontImageFile!);
      } else if (_frontImageFile == null) {
        frontImagePath = null;
      }

      String? backImagePath = widget.wallet.backImagePath;
      if (_backImageFile != null &&
          _backImageFile!.path != widget.wallet.backImagePath) {
        backImagePath = await saveImageToAppDirectory(_backImageFile!);
      } else if (_backImageFile == null) {
        backImagePath = null;
      }

      final updatedWallet = Wallet(
        id: widget.wallet.id,
        name: _nameController.text,
        number: _numberController.text,
        expiry: _expiryController.text,
        cvv: _cvvController.text,
        network: _network,
        issuer: _issuerController.text,
        maxlimit: _maxlimitController.text,
        spends: _spendsController.text,
        cardtype: _cardtypeController.text,
        billdate: _billdateController.text,
        category: _categoryController.text,
        annualFeeWaiver: _annualFeeWaiverController.text,
        rewards: _rewardsController.text,
        customFields: customFields,
        color: _selectedColor,
        frontImagePath: frontImagePath,
        backImagePath: backImagePath,
        orderIndex: widget.wallet.orderIndex,
        isArchived: widget.wallet.isArchived,
        cardCategory: _cardCategory,
        tags: _tags.isNotEmpty ? _tags : null,
      );
      await DatabaseHelper.instance.updateWallet(updatedWallet);
      AutoBackupService.triggerBackup();

      await provider.fetchWallets();
      await provider.fetchArchivedWallets();
      navigator.pop(updatedWallet);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final startupProvider = Provider.of<StartupSettingsProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final symbol = startupProvider.selectedCurrencySymbol;
    final l = AppLocalizations.of(context)!;

    final previewWallet = Wallet(
      id: widget.wallet.id,
      name: _nameController.text.isEmpty ? l.cardNamePlaceholder : _nameController.text,
      number: _numberController.text,
      expiry: _expiryController.text,
      network: _network,
      color: _selectedColor,
      cardCategory: _cardCategory,
      tags: _tags.isNotEmpty ? _tags : null,
    );

    return Scaffold(
      appBar: AppBar(
        title: const SizedBox.shrink(),
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.05),
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
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            child: FilledButton(
              onPressed: _saveUpdatedDetails,
              style: FilledButton.styleFrom(
                backgroundColor: isDark ? Colors.white : Colors.black,
                foregroundColor: isDark ? Colors.black : Colors.white,
              ),
              child: Text(l.saveButton),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            GlassCreditCard(
              isMasked: false,
              wallet: previewWallet,
              onCardTap: () {},
            ),
            const SizedBox(height: 24),
            _LiquidGlassDetailSection(
              title: l.walletDetailPrimaryDetails,
              icon: Icons.credit_card_outlined,
              children: [
                ColorPicker(
                  selectedColor: _selectedColor,
                  onColorSelected: (color) {
                    setState(() => _selectedColor = color);
                  },
                ),
                const SizedBox(height: 24),
                _buildTextField(
                  _nameController,
                  l.cardNameLabel,
                  isDark,
                  validator: (v) => v!.isEmpty ? l.validationEnterName : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  _numberController,
                  l.cardNumberLabel,
                  isDark,
                  focusNode: _numberFocusNode,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(
                      _getMaxCardLength(_network),
                    ),
                  ],
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return l.validationEnterCardNumber;
                    }
                    final cleaned = v.replaceAll(RegExp(r'\D'), '');
                    if (cleaned.length < 13 || cleaned.length > 19) {
                      return l.validationCardNumberLengthEdit;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  _expiryController,
                  l.expiryLabel,
                  isDark,
                  focusNode: _expiryFocusNode,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  validator: (v) {
                    if (v == null || v.length != 4) {
                      return l.validationExpiryLength;
                    }
                    final month = int.tryParse(v.substring(0, 2));
                    if (month == null || month < 1 || month > 12) {
                      return l.validationExpiryMonth;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  _cvvController,
                  l.cvvLabel,
                  isDark,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  validator: (v) {
                    if (v == null || v.isEmpty) return null;
                    if (v.length < 3 || v.length > 4) {
                      return l.validationCvvLength;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildDropdown(
                  l.cardIssuerLabelEdit,
                  _selectedIssuer,
                  isDark,
                  (newValue) {
                    if (newValue == null) return;
                    setState(() {
                      _selectedIssuer = newValue;
                      if (newValue == BrandIconService.issuerOtherSentinel) {
                        // 编辑模式下切换到「其他」时保留当前 issuer 值（可能是自定义名称），
                        // 让用户在输入框中直接修改。
                      } else {
                        _issuerController.text = newValue;
                      }
                    });
                  },
                  [
                    ...BrandIconService.instance.availableIssuers.map(
                      (name) => DropdownMenuItem<String>(
                        value: name,
                        child: Text(name),
                      ),
                    ),
                    DropdownMenuItem<String>(
                      value: BrandIconService.issuerOtherSentinel,
                      child: const Text('其他'),
                    ),
                  ],
                ),
                if (_selectedIssuer == BrandIconService.issuerOtherSentinel) ...[
                  const SizedBox(height: 16),
                  _buildTextField(
                    _issuerController,
                    '自定义发卡行',
                    isDark,
                    validator: (v) =>
                        v!.isEmpty ? l.validationEnterIssuer : null,
                  ),
                ],
                const SizedBox(height: 16),
                _buildDropdown(
                  l.cardCategoryLabel,
                  _cardCategory,
                  isDark,
                  (newValue) => setState(() => _cardCategory = newValue),
                  [
                    DropdownMenuItem<String>(
                      value: null,
                      child: Text(l.cardCategoryNone),
                    ),
                    DropdownMenuItem<String>(
                      value: 'credit',
                      child: Text(l.cardCategoryCredit),
                    ),
                    DropdownMenuItem<String>(
                      value: 'debit',
                      child: Text(l.cardCategoryDebit),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildDropdown(
                  l.cardNetworkLabel,
                  _network,
                  isDark,
                  (newValue) {
                    if (newValue != null) {
                      setState(() => _network = newValue);
                    }
                  },
                  ['unionpay', 'visa', 'mastercard', 'amex', 'discover', 'jcb', 'rupay']
                      .map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                          CardUtils.networkDisplayNameLocalized(value, l)!),
                    );
                  }).toList(),
                ),
              ],
            ),
            // Tags input — Feature 10
            _LiquidGlassDetailSection(
              title: l.tagsLabel,
              icon: Icons.label_outline,
              children: [
                if (_tags.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _tags.map((tag) {
                      return Chip(
                        label: Text(tag),
                        onDeleted: () {
                          setState(() => _tags.remove(tag));
                        },
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                      );
                    }).toList(),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _tagController,
                        decoration: InputDecoration(
                          hintText: l.tagsAddHint,
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onSubmitted: (value) {
                          final trimmed = value.trim();
                          if (trimmed.isNotEmpty &&
                              !_tags.contains(trimmed)) {
                            setState(() {
                              _tags.add(trimmed);
                              _tagController.clear();
                            });
                          }
                        },
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.add_circle,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      onPressed: () {
                        final trimmed = _tagController.text.trim();
                        if (trimmed.isNotEmpty &&
                            !_tags.contains(trimmed)) {
                          setState(() {
                            _tags.add(trimmed);
                            _tagController.clear();
                          });
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
            _LiquidGlassDetailSection(
              title: l.walletDetailCardImages,
              icon: Icons.photo_library_outlined,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildImagePicker(
                        l.frontImage,
                        _frontImageFile,
                        isDark,
                        () => _pickImage(ImageSource.gallery, true),
                        () => setState(() => _frontImageFile = null),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildImagePicker(
                        l.backImage,
                        _backImageFile,
                        isDark,
                        () => _pickImage(ImageSource.gallery, false),
                        () => setState(() => _backImageFile = null),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // 财务信息和账单条款已移除
            _LiquidGlassDetailSection(
              title: l.walletDetailCustomFields,
              icon: Icons.tune_outlined,
              children: [
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _customFieldNameControllers.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              _customFieldNameControllers[index],
                              l.fieldNameLabel,
                              isDark,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildTextField(
                              _customFieldValueControllers[index],
                              l.fieldValueLabel,
                              isDark,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.remove_circle_outline,
                              color: Colors.red.shade400,
                            ),
                            onPressed: () => _removeCustomField(index),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                Center(
                  child: TextButton.icon(
                    icon: Icon(
                      Icons.add_rounded,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    label: Text(
                      l.addCustomField,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    onPressed: _addCustomField,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    bool isDark, {
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    Widget? suffixIcon,
    bool obscureText = false,
    FocusNode? focusNode,
  }) {
    final textColor = isDark ? Colors.white : Colors.black;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.03),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
        obscureText: obscureText,
        style: TextStyle(color: textColor),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: textColor.withValues(alpha: 0.5)),
          border: InputBorder.none,
          suffixIcon: suffixIcon,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String? value,
    bool isDark,
    ValueChanged<String?> onChanged,
    List<DropdownMenuItem<String>> items,
  ) {
    final textColor = isDark ? Colors.white : Colors.black;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.03),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: textColor.withValues(alpha: 0.5)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        dropdownColor: isDark ? const Color(0xFF0A0A0A) : Colors.white,
        style: TextStyle(color: textColor),
        items: items,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildImagePicker(
    String title,
    File? imageFile,
    bool isDark,
    VoidCallback onPick,
    VoidCallback onRemove,
  ) {
    final textColor = isDark ? Colors.white : Colors.black;
    final l = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 12.0),
          child: Text(
            title,
            style: TextStyle(
              color: textColor.withValues(alpha: 0.5),
              fontSize: 14,
            ),
          ),
        ),
        // 与新增表单保持一致：无论是否添加，固定 150 高度 + 宽度填满。
        SizedBox(
          height: 150,
          width: double.infinity,
          child: imageFile == null
              ? OutlinedButton.icon(
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: Text(l.selectImage),
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.all(16),
                    side: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.2)
                          : Colors.black.withValues(alpha: 0.15),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: onPick,
                )
              : GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.push(
                    context,
                    SmoothPageRoute(
                      page: FullScreenImageViewer(imagePath: imageFile!.path),
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : Colors.black.withValues(alpha: 0.08),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: imageFile.path.endsWith('.enc')
                                ? EncryptedImageDisplay(
                                    imagePath: imageFile.path,
                                    fit: BoxFit.cover,
                                    cacheWidth: 500,
                                    cacheHeight: 300,
                                  )
                                : Image.file(
                                    imageFile,
                                    fit: BoxFit.cover,
                                    cacheWidth: 500,
                                    cacheHeight: 300,
                                  ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 20,
                            ),
                            onPressed: onRemove,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

// --- LIQUID GLASS DETAIL SECTION ---
class _LiquidGlassDetailSection extends StatelessWidget {
  final String title;
  final IconData? icon;
  final List<Widget> children;

  const _LiquidGlassDetailSection({
    required this.title,
    this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final textTheme = Theme.of(context).textTheme;
    final isDark = themeProvider.isDarkMode;
    final textColor = isDark ? Colors.white38 : Colors.black38;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12, top: 8),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: textColor),
                const SizedBox(width: 8),
              ],
              Text(
                title.toUpperCase(),
                style: textTheme.labelSmall?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5),
            border: Border.all(
              color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE8E8E8),
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }
}

// --- LIQUID GLASS DETAIL TILE ---
class _LiquidGlassDetailTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color? valueColor;

  const _LiquidGlassDetailTile({
    required this.icon,
    required this.title,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final textTheme = Theme.of(context).textTheme;
    final isDark = themeProvider.isDarkMode;
    final textColor = isDark ? Colors.white : Colors.black;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 18,
              color: textColor.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: textTheme.bodyMedium?.copyWith(
                color: textColor.withValues(alpha: 0.7),
              ),
            ),
          ),
          Text(
            value,
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: valueColor ?? textColor,
            ),
          ),
        ],
      ),
    );
  }
}
