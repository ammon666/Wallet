import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:wallet/l10n/app_localizations.dart';
import 'package:wallet/models/db_helper.dart';
import 'package:wallet/models/theme_provider.dart';
import 'package:wallet/services/auto_backup_service.dart';
import 'package:wallet/services/brand_icon_service.dart';
import 'package:wallet/services/card_utils.dart';
import 'package:wallet/services/image_service.dart';
import 'package:wallet/screens/homescreen.dart';
import 'package:wallet/widgets/color_picker.dart';
import 'package:wallet/widgets/form_section.dart';
import 'package:wallet/widgets/full_screen_image_viewer.dart';
import 'package:wallet/widgets/glass_credit_card.dart';
import 'package:wallet/widgets/image_picker_widget.dart';

class CreditCardEntryForm extends StatefulWidget {
  final String? initialColor;
  final String? initialIssuer;

  const CreditCardEntryForm({
    super.key,
    this.initialColor,
    this.initialIssuer,
  });

  @override
  State<CreditCardEntryForm> createState() => _CreditCardEntryFormState();
}

class _CreditCardEntryFormState extends State<CreditCardEntryForm> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _nameController = TextEditingController();
  final _numberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _issuerController = TextEditingController();
  final _tagController = TextEditingController();
  final _numberFocusNode = FocusNode();
  final _expiryFocusNode = FocusNode();
  // GlobalKeys for scrolling to the first error field on validation failure.
  final _nameFieldKey = GlobalKey();
  final _numberFieldKey = GlobalKey();
  final _expiryFieldKey = GlobalKey();
  final _issuerFieldKey = GlobalKey();
  String _network = "visa";
  String? _cardCategory; // 'credit' | 'debit' | null
  final List<String> _tags = [];
  late String _selectedColor;
  /// 当前选中的发卡行下拉项。值为 [BrandIconService.issuerOtherSentinel]
  /// 时，下方显示 TextField 允许用户自由输入「其他」发卡行名称。
  late String _selectedIssuer;
  File? _frontImageFile;
  File? _backImageFile;
  bool _showAdditionalDetails = true;
  bool _isSaving = false;

  final _customFieldNameControllers = <TextEditingController>[];
  final _customFieldValueControllers = <TextEditingController>[];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor ?? 'default';
    // 初始下拉选择：优先与 widget.initialIssuer 对齐（若恰好命中库内
    // 选项），否则默认进入「其他」自由输入模式。
    final brand = BrandIconService.instance;
    final initialIssuer = widget.initialIssuer ?? '';
    if (initialIssuer.isNotEmpty &&
        brand.availableIssuers.contains(initialIssuer)) {
      _selectedIssuer = initialIssuer;
      _issuerController.text = initialIssuer;
    } else {
      _selectedIssuer = BrandIconService.issuerOtherSentinel;
      _issuerController.text = initialIssuer;
    }
    _nameController.addListener(_onFieldChanged);
    _numberController.addListener(_onNumberChanged);
    _expiryController.addListener(_onFieldChanged);
    _issuerController.addListener(_onFieldChanged);
    // Validate on focus loss (not on every keystroke) — Feature 5.
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
  }

  @override
  void dispose() {
    _nameController.removeListener(_onFieldChanged);
    _numberController.removeListener(_onNumberChanged);
    _expiryController.removeListener(_onFieldChanged);
    _scrollController.dispose();
    _nameController.dispose();
    _numberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _issuerController.dispose();
    _tagController.dispose();
    _numberFocusNode.dispose();
    _expiryFocusNode.dispose();
    for (var c in _customFieldNameControllers) {
      c.dispose();
    }
    for (var c in _customFieldValueControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  void _onNumberChanged() {
    final detected = CardUtils.detectCardNetwork(_numberController.text);
    if (detected != null && detected != _network) {
      setState(() => _network = detected);
    } else if (mounted) {
      setState(() {});
    }
  }

  /// Get maximum card number length
  int _getMaxCardLength(String network) {
    return 19;
  }

  /// 直接从相册选择卡片图片（移除了裁切功能与"拍照/相册"来源选择对话框）。
  Future<void> _pickFromGallery(bool isFront) async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2400,
      maxHeight: 2400,
      imageQuality: 92,
    );
    if (pickedFile == null || !mounted) return;

    setState(() {
      final file = File(pickedFile.path);
      if (isFront) {
        _frontImageFile = file;
      } else {
        _backImageFile = file;
      }
    });
  }

  /// Scrolls the ListView to bring the widget identified by [key] into view.
  void _scrollToField(GlobalKey key) {
    final context = key.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      alignment: 0.3, // show the field at 30% from the top
    );
  }

  /// Validates the form and scrolls to the first field that has an error.
  bool _validateAndScroll() {
    final isValid = _formKey.currentState!.validate();
    if (isValid) return true;
    // Find the first field with an error and scroll to it.
    final fieldKeys = [_nameFieldKey, _numberFieldKey, _expiryFieldKey, _issuerFieldKey];
    for (final key in fieldKeys) {
      final ctx = key.currentContext;
      if (ctx == null) continue;
      // Check if this TextFormField has a validation error by looking
      // for the error text in the nearest TextFormFieldState.
      final state = ctx.findAncestorStateOfType<FormFieldState>();
      if (state != null && state.hasError) {
        _scrollToField(key);
        return false;
      }
    }
    // Fallback: scroll to top if no specific error field found.
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    return false;
  }

  void _addData() async {
    if (_validateAndScroll()) {
      setState(() => _isSaving = true);
      try {
        String? frontImagePath;
        if (_frontImageFile != null) {
          frontImagePath = await saveImageToAppDirectory(_frontImageFile!);
        }
        String? backImagePath;
        if (_backImageFile != null) {
          backImagePath = await saveImageToAppDirectory(_backImageFile!);
        }

        Map<String, String> customFields = {};
        for (int i = 0; i < _customFieldNameControllers.length; i++) {
          String fieldName = _customFieldNameControllers[i].text;
          String fieldValue = _customFieldValueControllers[i].text;
          if (fieldName.isNotEmpty && fieldValue.isNotEmpty) {
            customFields[fieldName] = fieldValue;
          }
        }

        Wallet wallet = Wallet(
          name: _nameController.text,
          number: _numberController.text,
          expiry: _expiryController.text,
          cvv: _cvvController.text,
          network: _network,
          issuer: _issuerController.text,
          customFields: customFields.isNotEmpty ? customFields : null,
          color: _selectedColor,
          frontImagePath: frontImagePath,
          backImagePath: backImagePath,
          cardCategory: _cardCategory,
          tags: _tags.isNotEmpty ? _tags : null,
        );
        await DatabaseHelper.instance.insertWallet(wallet);
        AutoBackupService.triggerBackup();

        if (mounted) {
          Navigator.pop(context, true);
        }
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
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

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final l = AppLocalizations.of(context)!;
    final previewWallet = Wallet(
      name: _nameController.text.isEmpty ? l.cardNamePlaceholder : _nameController.text,
      number: _numberController.text.padRight(16, '•'),
      expiry: _expiryController.text.padRight(4, '•'),
      network: _network,
      color: _selectedColor,
      cardCategory: _cardCategory,
      tags: _tags.isNotEmpty ? _tags : null,
    );

    return Form(
      key: _formKey,
      child: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16.0),
        children: [
          GlassCreditCard(
            isMasked: false,
            wallet: previewWallet,
            onCardTap: () {},
          ),
          const SizedBox(height: 24),
          FormSection(
            children: [
              ColorPicker(
                selectedColor: _selectedColor,
                onColorSelected: (color) =>
                    setState(() => _selectedColor = color),
              ),
              const SizedBox(height: 24),
              TextFormField(
                key: _nameFieldKey,
                controller: _nameController,
                decoration: InputDecoration(labelText: l.cardNameLabel),
                validator: (v) => v!.isEmpty ? l.validationEnterName : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: _numberFieldKey,
                controller: _numberController,
                focusNode: _numberFocusNode,
                decoration: InputDecoration(
                  labelText: l.cardNumberLabel,
                  suffixIcon: Consumer<ThemeProvider>(
                    builder: (context, themeProvider, _) {
                      final isDark = themeProvider.isDarkMode;
                      final detectedNetwork = CardUtils.detectCardNetwork(
                        _numberController.text,
                      );
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Network badge (hidden until filled)
                          if (detectedNetwork != null &&
                              _numberController.text.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: Text(
                                detectedNetwork.toUpperCase(),
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.702)
                                      : Colors.black.withValues(alpha: 0.702),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(_getMaxCardLength(_network)),
                ],
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return l.validationEnterCardNumber;
                  }
                  final cleaned = v.replaceAll(RegExp(r'\D'), '');
                  if (cleaned.length < 15 || cleaned.length > 19) {
                    return l.validationCardNumberLength;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: _expiryFieldKey,
                controller: _expiryController,
                focusNode: _expiryFocusNode,
                decoration: InputDecoration(labelText: l.expiryLabel),
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
              TextFormField(
                controller: _cvvController,
                decoration: InputDecoration(
                  labelText: l.cvvLabel,
                ),
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
              DropdownButtonFormField<String>(
                value: _selectedIssuer,
                decoration: InputDecoration(labelText: l.cardIssuerLabel),
                items: [
                  ...BrandIconService.instance.availableIssuers.map(
                    (name) => DropdownMenuItem<String>(
                      value: name,
                      child: Text(name),
                    ),
                  ),
                  const DropdownMenuItem<String>(
                    value: BrandIconService.issuerOtherSentinel,
                    child: Text('其他'),
                  ),
                ],
                onChanged: (newValue) {
                  if (newValue == null) return;
                  setState(() {
                    _selectedIssuer = newValue;
                    if (newValue == BrandIconService.issuerOtherSentinel) {
                      // 切换到「其他」时清空输入框，让用户手动输入。
                      _issuerController.text = '';
                    } else {
                      _issuerController.text = newValue;
                    }
                  });
                },
              ),
              if (_selectedIssuer == BrandIconService.issuerOtherSentinel) ...[
                const SizedBox(height: 16),
                TextFormField(
                  key: _issuerFieldKey,
                  controller: _issuerController,
                  decoration: const InputDecoration(
                    labelText: '自定义发卡行',
                    hintText: '如：地方银行 / 外资银行等',
                  ),
                  validator: (v) =>
                      v!.isEmpty ? l.validationEnterIssuer : null,
                ),
              ],
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                value: _cardCategory,
                decoration: InputDecoration(labelText: l.cardCategoryLabel),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(l.cardCategoryNone),
                  ),
                  DropdownMenuItem<String?>(
                    value: 'credit',
                    child: Text(l.cardCategoryCredit),
                  ),
                  DropdownMenuItem<String?>(
                    value: 'debit',
                    child: Text(l.cardCategoryDebit),
                  ),
                ],
                onChanged: (newValue) =>
                    setState(() => _cardCategory = newValue),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _network,
                decoration: InputDecoration(labelText: l.cardNetworkLabel),
                items: ['unionpay', 'visa', 'mastercard', 'amex', 'discover', 'jcb', 'rupay'].map((
                  String value,
                ) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(CardUtils.networkDisplayNameLocalized(value, l)!),
                  );
                }).toList(),
                onChanged: (newValue) => setState(() => _network = newValue!),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Tags input — Feature 10: custom tags shown on card face
          FormSection(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l.tagsLabel,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
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
                      ),
                      onSubmitted: (value) {
                        final trimmed = value.trim();
                        if (trimmed.isNotEmpty && !_tags.contains(trimmed)) {
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
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: () {
                      final trimmed = _tagController.text.trim();
                      if (trimmed.isNotEmpty && !_tags.contains(trimmed)) {
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
          if (!_showAdditionalDetails)
            Center(
              child: TextButton.icon(
                onPressed: () => setState(() => _showAdditionalDetails = true),
                icon: const Icon(Icons.add_rounded),
                label: Text(l.additionalInfo),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ),
          if (_showAdditionalDetails) ...[
            FormSection(
              children: [
                // 正面 / 反面：左右并排显示（选图前按钮 / 选图后图片容器大小一致）。
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ImagePickerWidget(
                        title: l.frontImage,
                        imageFile: _frontImageFile,
                        // 直接打开相册，不再弹出"拍照/相册"来源选择。
                        onPickImage: () => _pickFromGallery(true),
                        onRemoveImage: () =>
                            setState(() => _frontImageFile = null),
                        onPreviewImage: _frontImageFile != null
                            ? () => Navigator.push(
                                  context,
                                  SmoothPageRoute(
                                    page: FullScreenImageViewer(
                                      imagePath: _frontImageFile!.path,
                                    ),
                                  ),
                                )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ImagePickerWidget(
                        title: l.backImage,
                        imageFile: _backImageFile,
                        onPickImage: () => _pickFromGallery(false),
                        onRemoveImage: () =>
                            setState(() => _backImageFile = null),
                        onPreviewImage: _backImageFile != null
                            ? () => Navigator.push(
                                  context,
                                  SmoothPageRoute(
                                    page: FullScreenImageViewer(
                                      imagePath: _backImageFile!.path,
                                    ),
                                  ),
                                )
                            : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            FormSection(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l.customFieldsTitle,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.add_circle,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      onPressed: _addCustomField,
                    ),
                  ],
                ),
                if (_customFieldNameControllers.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: Center(
                      child: Text(
                        l.noCustomFields,
                        style: themeProvider.getTextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
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
                            child: TextFormField(
                              controller: _customFieldNameControllers[index],
                              decoration: InputDecoration(
                                labelText: l.fieldNameLabel,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _customFieldValueControllers[index],
                              decoration: InputDecoration(
                                labelText: l.fieldValueLabel,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () => _removeCustomField(index),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              onPressed: _isSaving ? null : _addData,
              child: _isSaving
                  ? CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.onPrimary,
                    )
                  : Text(
                      l.saveCardButton,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
