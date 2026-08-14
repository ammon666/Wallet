import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:wallet/models/db_helper.dart';
import 'package:wallet/models/provider_helper.dart';
import 'package:wallet/services/image_service.dart';
import 'package:wallet/services/auto_backup_service.dart';
import 'package:wallet/widgets/identity_card_widget.dart';
import 'package:wallet/widgets/color_picker.dart';
import 'package:wallet/l10n/app_localizations.dart';

class IdentityCardEntryForm extends StatefulWidget {
  final IdentityCard? existingCard;
  const IdentityCardEntryForm({super.key, this.existingCard});

  @override
  State<IdentityCardEntryForm> createState() => IdentityCardEntryFormState();
}

class IdentityCardEntryFormState extends State<IdentityCardEntryForm> {
  final _nameController = TextEditingController();
  final _valueController = TextEditingController();
  final _cardTypeController = TextEditingController();
  String? _frontImagePath;
  String? _backImagePath;
  String _selectedColor = 'obsidian';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingCard != null) {
      _nameController.text = widget.existingCard!.name;
      _valueController.text = widget.existingCard!.value;
      _cardTypeController.text = widget.existingCard!.cardType;
      _frontImagePath = widget.existingCard!.frontImagePath;
      _backImagePath = widget.existingCard!.backImagePath;
      _selectedColor = widget.existingCard!.color ?? 'obsidian';
    }
    _nameController.addListener(() => setState(() {}));
    _valueController.addListener(() => setState(() {}));
    _cardTypeController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _valueController.dispose();
    _cardTypeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isFront) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final encryptedPath = await saveImageToAppDirectory(
        File(pickedFile.path),
      );
      setState(() {
        if (isFront) {
          _frontImagePath = encryptedPath;
        } else {
          _backImagePath = encryptedPath;
        }
      });
    }
  }

  Future<void> _saveData() async {
    final name = _nameController.text.trim();
    final value = _valueController.text.trim();
    final cardType = _cardTypeController.text.trim();

    if (name.isEmpty || value.isEmpty) {
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.validationNameValueRequired)),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final l = AppLocalizations.of(context)!;
      final card = IdentityCard(
        id: widget.existingCard?.id,
        name: name,
        value: value,
        cardType: cardType.isEmpty ? l.identityCardDefaultType : cardType,
        frontImagePath: _frontImagePath,
        backImagePath: _backImagePath,
        color: _selectedColor,
        orderIndex: widget.existingCard?.orderIndex ?? 0,
      );

      if (widget.existingCard != null) {
        await IdentityDatabaseHelper.instance.updateIdentity(card);
      } else {
        await IdentityDatabaseHelper.instance.insertIdentity(card);
        AutoBackupService.triggerBackup();
      }

      if (mounted) {
        context.read<IdentityProvider>().fetchIdentities();
        Navigator.pop(context, true);
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void save() => _saveData();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l = AppLocalizations.of(context)!;

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Preview
        IdentityCardWidget(
          card: IdentityCard(
            name: _nameController.text.isEmpty ? l.idNamePlaceholder : _nameController.text,
            value: _valueController.text.isEmpty
                ? l.idValuePlaceholder
                : _valueController.text,
            cardType: _cardTypeController.text.isEmpty
                ? l.idCardTypePlaceholder
                : _cardTypeController.text,
            frontImagePath: _frontImagePath,
            backImagePath: _backImagePath,
            color: _selectedColor,
          ),
          onTap: () {},
        ),
        const SizedBox(height: 32),

        ColorPicker(
          selectedColor: _selectedColor,
          onColorSelected: (color) => setState(() => _selectedColor = color),
        ),
        const SizedBox(height: 32),

        TextField(
          controller: _cardTypeController,
          decoration: InputDecoration(
            labelText: l.idCardLabelHint,
            hintText: l.idCardLabelExample,
            prefixIcon: const Icon(Icons.label_outline_rounded),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),

        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: l.fullNameLabel,
            hintText: l.fullNameExample,
            prefixIcon: const Icon(Icons.person_outline_rounded),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _valueController,
          decoration: InputDecoration(
            labelText: l.idValueLabel,
            hintText: l.idValueExample,
            prefixIcon: const Icon(Icons.badge_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 32),

        Text(
          l.attachmentsOptional,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white54 : Colors.black54,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: _buildImagePickerTile(
                l.frontSide,
                _frontImagePath,
                () => _pickImage(true),
                isDark,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildImagePickerTile(
                l.backSide,
                _backImagePath,
                () => _pickImage(false),
                isDark,
              ),
            ),
          ],
        ),

        const SizedBox(height: 48),

        if (widget.existingCard == null)
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
              onPressed: _isSaving ? null : _saveData,
              child: _isSaving
                  ? CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.onPrimary,
                    )
                  : Text(
                      l.saveIdentityCardButton,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
            ),
          ),
      ],
    );
  }

  Widget _buildImagePickerTile(
    String label,
    String? path,
    VoidCallback onTap,
    bool isDark,
  ) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: path != null
                    ? Colors.green.withValues(alpha: 0.5)
                    : (isDark ? Colors.white12 : Colors.black12),
              ),
            ),
            child: path != null
                ? const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.green,
                    size: 32,
                  )
                : Icon(
                    Icons.add_a_photo_outlined,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.white54 : Colors.black54,
          ),
        ),
      ],
    );
  }
}
