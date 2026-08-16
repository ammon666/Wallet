import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:wallet/l10n/app_localizations.dart';
import 'package:wallet/models/db_helper.dart';
import 'package:wallet/models/theme_provider.dart';
import 'package:wallet/services/auto_backup_service.dart';
import 'package:wallet/services/card_utils.dart';
import 'package:wallet/services/image_processing_service.dart';
import 'package:wallet/services/image_service.dart';
import 'package:wallet/widgets/color_picker.dart';
import 'package:wallet/widgets/form_section.dart';
import 'package:wallet/widgets/glass_credit_card.dart';
import 'package:wallet/widgets/image_picker_widget.dart';

class CreditCardEntryForm extends StatefulWidget {
  final String? initialColor;

  const CreditCardEntryForm({
    super.key,
    this.initialColor,
  });

  @override
  State<CreditCardEntryForm> createState() => _CreditCardEntryFormState();
}

class _CreditCardEntryFormState extends State<CreditCardEntryForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _numberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _issuerController = TextEditingController();
  final _tagController = TextEditingController();
  final _numberFocusNode = FocusNode();
  final _expiryFocusNode = FocusNode();
  String _network = "visa";
  String? _cardCategory; // 'credit' | 'debit' | null
  final List<String> _tags = [];
  late String _selectedColor;
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
    _nameController.addListener(_onFieldChanged);
    _numberController.addListener(_onNumberChanged);
    _expiryController.addListener(_onFieldChanged);
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

  Future<void> _showImageSourceDialog(bool isFront) async {
    final l = AppLocalizations.of(context)!;
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF0A0A0A)
            : Colors.white,
        title: Text(l.selectImageSource),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l.chooseFromGallery),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text(l.takePhoto),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source != null) {
      await _pickImage(source, isFront);
    }
  }

  Future<void> _pickImage(ImageSource source, bool isFront) async {
    final pickedFile = await _picker.pickImage(
      source: source,
      maxWidth: 2400,
      maxHeight: 2400,
      imageQuality: 92,
    );
    if (pickedFile == null) return;
    if (!mounted) return;

    final l = AppLocalizations.of(context)!;
    // Show loading while running offline edge/crop pipeline.
    final dialog = showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 16),
              Flexible(child: Text(l.processing)),
            ],
          ),
        ),
      ),
    );

    try {
      final rawBytes = await File(pickedFile.path).readAsBytes();
      final processedBytes = await ImageProcessingService.instance
          .processCardPhoto(rawBytes);
      final directory = await getApplicationDocumentsDirectory();
      final tempName =
          'proc_${DateTime.now().microsecondsSinceEpoch}${p.extension(pickedFile.path)}';
      final tempPath = p.join(directory.path, tempName);
      final tempFile = await File(tempPath).writeAsBytes(processedBytes);

      setState(() {
        if (isFront) {
          _frontImageFile = tempFile;
        } else {
          _backImageFile = tempFile;
        }
      });
    } catch (_) {
      // Fallback: keep the original photo without processing.
      setState(() {
        if (isFront) {
          _frontImageFile = File(pickedFile.path);
        } else {
          _backImageFile = File(pickedFile.path);
        }
      });
    } finally {
      Navigator.of(context).pop();
    }
  }

  void _addData() async {
    if (_formKey.currentState!.validate()) {
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
    );

    return Form(
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
          FormSection(
            children: [
              ColorPicker(
                selectedColor: _selectedColor,
                onColorSelected: (color) =>
                    setState(() => _selectedColor = color),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: l.cardNameLabel),
                validator: (v) => v!.isEmpty ? l.validationEnterName : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
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
              TextFormField(
                controller: _issuerController,
                decoration: InputDecoration(
                  labelText: l.cardIssuerLabel,
                ),
                validator: (v) => v!.isEmpty ? l.validationEnterIssuer : null,
              ),
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
                items: ['visa', 'mastercard', 'unionpay', 'amex', 'discover', 'jcb', 'rupay'].map((
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
                ImagePickerWidget(
                  title: l.frontImage,
                  imageFile: _frontImageFile,
                  onPickImage: () => _showImageSourceDialog(true),
                  onRemoveImage: () => setState(() => _frontImageFile = null),
                ),
                const SizedBox(height: 16),
                ImagePickerWidget(
                  title: l.backImage,
                  imageFile: _backImageFile,
                  onPickImage: () => _showImageSourceDialog(false),
                  onRemoveImage: () => setState(() => _backImageFile = null),
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
