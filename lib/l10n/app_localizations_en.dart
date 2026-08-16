// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Wallet';

  @override
  String get splashTagline => 'Secure • Simple • Smart';

  @override
  String get splashAuthReason => 'Authenticate to access your wallet';

  @override
  String get navPayments => 'Payments';

  @override
  String get navPasses => 'Passes';

  @override
  String get navIdentity => 'Identity';

  @override
  String get scanToImport => 'Scan to Import';

  @override
  String get emptyPayments =>
      'No credit or debit cards yet.\nTap the \'+\' to add one.';

  @override
  String get emptyPasses => 'No passes added yet.\nTap the \'+\' to add one.';

  @override
  String get emptyIdentities =>
      'No identity cards yet.\nTap the \'+\' to add one.';

  @override
  String get searchCards => 'Search cards...';

  @override
  String get searchPasses => 'Search passes...';

  @override
  String get searchIdentities => 'Search identities...';

  @override
  String get noCardsFound => 'No cards found.';

  @override
  String get noPassesFound => 'No passes found.';

  @override
  String get noIdentitiesFound => 'No identity cards found.';

  @override
  String get filterAll => 'ALL';

  @override
  String get filterLoyalty => 'LOYALTY';

  @override
  String get filterGiftCards => 'GIFT CARDS';

  @override
  String get filterOffers => 'OFFERS';

  @override
  String get filterBoarding => 'BOARDING';

  @override
  String get filterEvents => 'EVENTS';

  @override
  String get filterTransit => 'TRANSIT';

  @override
  String get filterHealth => 'HEALTH';

  @override
  String get filterCampus => 'CAMPUS';

  @override
  String get filterCorporate => 'CORPORATE';

  @override
  String get filterHotel => 'HOTEL';

  @override
  String get filterOther => 'OTHER';

  @override
  String get actionEdit => 'Edit';

  @override
  String get actionCopy => 'Copy';

  @override
  String get actionDelete => 'Delete';

  @override
  String get cardNumberCopied => 'Card number copied!';

  @override
  String get passDataCopied => 'Pass data copied!';

  @override
  String get idValueCopied => 'ID value copied!';

  @override
  String get cardNumberCopiedBang => 'Card Number Copied!';

  @override
  String get cvvCopied => 'CVV Copied!';

  @override
  String get idNumberCopied => 'ID Number Copied!';

  @override
  String get copiedToClipboard => 'Copied to clipboard';

  @override
  String get qrDataCopied => 'QR data copied to clipboard';

  @override
  String get deleteWalletTitle => 'Delete Card?';

  @override
  String get cardDeleted => 'Card deleted!';

  @override
  String get deletePassTitle => 'Delete Pass?';

  @override
  String get deleteIdentityTitle => 'Delete Identity Card?';

  @override
  String deleteConfirmBody(Object name) {
    return 'Are you sure you want to delete \"$name\"? This action cannot be undone.';
  }

  @override
  String get passDeleted => 'Pass Deleted!';

  @override
  String get identityDeleted => 'Identity Card Deleted!';

  @override
  String importSharedTitle(String type) {
    return 'Import Shared $type';
  }

  @override
  String importSharedBody(String name) {
    return 'Do you want to import \"$name\"?';
  }

  @override
  String get invalidShareCode => 'Invalid or corrupted sharing code.';

  @override
  String get invalidShareFormat => 'Invalid sharing code format.';

  @override
  String get invalidPassData => 'Invalid pass data.';

  @override
  String get invalidCardData => 'Invalid card data.';

  @override
  String get invalidIdentityData => 'Invalid identity data.';

  @override
  String get importFailedCorrupted =>
      'Failed to import. The sharing code may be corrupted.';

  @override
  String get invalidChunkFormat => 'Invalid chunk format.';

  @override
  String get invalidChunkIndex => 'Invalid chunk index.';

  @override
  String get chunkMismatch => 'Chunk mismatch. Please restart scanning.';

  @override
  String get failedParseChunk => 'Failed to parse chunk.';

  @override
  String get decryptFailed =>
      'Decryption failed. Wrong password or corrupted data.';

  @override
  String get importFailedWrongPassword =>
      'Failed to import. Wrong password or corrupted data.';

  @override
  String scannedChunk(int current, int total) {
    return 'Scanned chunk $current of $total';
  }

  @override
  String get enterTransferPasswordTitle => 'Enter Transfer Password';

  @override
  String get enterTransferPasswordBody =>
      'Enter the password that was used to encrypt this transfer.';

  @override
  String get passImportedSuccess => 'Pass imported successfully!';

  @override
  String get paymentCardImportedSuccess =>
      'Payment card imported successfully!';

  @override
  String get identityCardImportedSuccess =>
      'Identity card imported successfully!';

  @override
  String get typeLabelPass => 'Pass';

  @override
  String get typeLabelPaymentCard => 'Payment Card';

  @override
  String get typeLabelIdentityCard => 'Identity Card';

  @override
  String get typeLabelCard => 'Card';

  @override
  String get saveButton => 'SAVE';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get importButton => 'Import';

  @override
  String get deleteButton => 'Delete';

  @override
  String get closeButton => 'Close';

  @override
  String get enableButton => 'Enable';

  @override
  String get saveButtonText => 'Save';

  @override
  String get importPassTitle => 'Import Pass';

  @override
  String importPassBody(String name) {
    return 'Do you want to import \"$name\"?';
  }

  @override
  String get passImportedSuccessShort => 'Pass imported successfully!';

  @override
  String get pkpassParseFailed => 'Failed to parse .pkpass file.';

  @override
  String get passImportFailed => 'Failed to import pass. Please try again.';

  @override
  String get importPkpass => 'Import pkpass';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get sectionStartupLayout => 'Startup & Layout';

  @override
  String get sectionAppearance => 'Appearance';

  @override
  String get sectionDataManagement => 'Data Management';

  @override
  String get sectionAbout => 'About';

  @override
  String get authScreenTitle => 'Authentication Screen';

  @override
  String get authScreenSubtitle => 'Require biometrics when app starts';

  @override
  String get authenticateAction => 'Authenticate to perform this action';

  @override
  String get currencyTitle => 'Currency';

  @override
  String get chooseCurrency => 'Choose Currency';

  @override
  String get defaultScreenTitle => 'Default Screen';

  @override
  String get defaultScreenSubtitle => 'Default Screen';

  @override
  String get chooseDefaultScreen => 'Default Screen';

  @override
  String get paymentsOnlyTitle => 'Payments Only Mode';

  @override
  String get paymentsOnlySubtitle => 'Hide Passes and Identity screen';

  @override
  String get appThemeTitle => 'App Theme';

  @override
  String get appThemeSubtitle => 'App Theme';

  @override
  String get chooseTheme => 'Choose Theme';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystem => 'Follow System';

  @override
  String get useSystemFontTitle => 'Use System Font';

  @override
  String get useSystemFontSubtitle => 'Use the default system font';

  @override
  String get autoBackupTitle => 'Auto Backup';

  @override
  String get autoBackupSubtitleOff => 'Automatically backup on changes';

  @override
  String get autoBackupSubtitleNoPath => 'Configure backup location';

  @override
  String autoBackupSubtitleActive(String path) {
    return 'Active - $path';
  }

  @override
  String get backupLocationTitle => 'Backup Location';

  @override
  String get changeBackupPasswordTitle => 'Change Backup Password';

  @override
  String get changeBackupPasswordSubtitle =>
      'Update the auto backup encryption password';

  @override
  String get enableAutoBackupTitle => 'Enable Auto Backup';

  @override
  String get enableAutoBackupBody =>
      'A backup will be created automatically whenever you add or remove cards, passes, or identity cards.';

  @override
  String get selectDirectoryHint => 'Select directory...';

  @override
  String get backupPasswordLabel => 'Backup Password';

  @override
  String get enterPasswordHint => 'Enter password';

  @override
  String get enterNewPasswordHint => 'Enter new password (min 8 characters)';

  @override
  String get createBackupTitle => 'Create Backup';

  @override
  String get createBackupSubtitle => 'Save an encrypted copy of your data';

  @override
  String get createBackupDialogBody =>
      'Enter a strong password to encrypt your backup file.';

  @override
  String get createBackupButton => 'Create Backup';

  @override
  String get restoreBackupTitle => 'Restore from Backup';

  @override
  String get restoreBackupSubtitle => 'Replace current data from a backup file';

  @override
  String get restoreBackupDialogBody =>
      'Enter the password for the backup file. This will replace all current data.';

  @override
  String get restoreButton => 'Restore';

  @override
  String get deleteAllDataTitle => 'Delete All Data?';

  @override
  String get deleteAllDataSubtitle =>
      'Permanently erase all data from this device';

  @override
  String get deleteAllDataBody =>
      'This will permanently delete all wallets, passes, and images.';

  @override
  String get deleteEverythingButton => 'Delete Everything';

  @override
  String get allDataDeleted => 'All data deleted.';

  @override
  String get deleteFailedRetry => 'Delete failed. Please try again.';

  @override
  String get sectionDangerZone => 'Danger Zone';

  @override
  String get dangerZoneSubtitle => 'Irreversible destructive operations';

  @override
  String get dangerZonePinAuthTitle => 'Verify PIN';

  @override
  String get dangerZonePinAuthSubtitle =>
      'Enter your device PIN to delete all data. Fingerprint is not accepted.';

  @override
  String get pinAuthUnavailable =>
      'PIN verification is unavailable on this device. Set a screen lock (PIN/password) to proceed.';

  @override
  String get trademarkNoticeTitle => 'Trademark Notice';

  @override
  String get trademarkNoticeSubtitle =>
      'Card network logos are trademarks of their respective owners.';

  @override
  String get trademarkDialogTitle => 'Trademark Fair Use Notice';

  @override
  String get trademarkDialogBody =>
      'The Visa, Mastercard, UnionPay, JCB, RuPay, American Express, and Discover logos displayed in this application are registered trademarks of their respective owners.\n\nThese logos are used solely for identifying the card network. This usage constitutes nominative fair use.\n\nThis application is not affiliated with, endorsed by, or sponsored by any of these companies.';

  @override
  String get reportErrorTitle => 'Report Error';

  @override
  String get reportErrorSubtitle => 'Found a bug? Let us know on GitHub.';

  @override
  String get buyMeACoffee => 'Buy Me a Coffee';

  @override
  String get passwordLabel => 'Password';

  @override
  String passwordTooShort(int min) {
    return 'Password must be at least $min characters';
  }

  @override
  String get setTransferPasswordTitle => 'Set Transfer Password';

  @override
  String get setTransferPasswordBody =>
      'Enter a password to encrypt the transfer. The receiver will need this to import.';

  @override
  String get generateQrButton => 'Generate QR';

  @override
  String get pathNotSet => 'Not set';

  @override
  String get cardNameLabel => 'Card Name';

  @override
  String get cardNumberLabel => 'Card Number';

  @override
  String get expiryLabel => 'Expiry (MMYY)';

  @override
  String get cvvLabel => 'CVV';

  @override
  String get cardIssuerLabel => 'Card Issuer (e.g., HDFC)';

  @override
  String get cardIssuerLabelEdit => 'Card Issuer (e.g. HDFC)';

  @override
  String get cardNetworkLabel => 'Card Network';

  @override
  String get validationEnterName => 'Please enter a name';

  @override
  String get validationEnterCardNumber => 'Please enter a card number';

  @override
  String get validationCardNumberLength => 'Card number must be 15-19 digits';

  @override
  String get validationCardNumberLengthEdit =>
      'Card number must be 13-19 digits';

  @override
  String get validationExpiryLength => 'Must be 4 digits';

  @override
  String get validationExpiryMonth => 'Month must be 01-12';

  @override
  String get validationCvvLength => 'CVV must be 3-4 digits';

  @override
  String get validationEnterIssuer => 'Please enter an issuer';

  @override
  String get validationOrgRequired => 'Organization is required.';

  @override
  String get validationNameValueRequired => 'Name and Value are required.';

  @override
  String get additionalInfo => 'Additional Info';

  @override
  String get frontImage => 'Front Image';

  @override
  String get backImage => 'Back Image';

  @override
  String get customFieldsTitle => 'CUSTOM FIELDS';

  @override
  String get noCustomFields => 'No custom fields added.';

  @override
  String get fieldNameLabel => 'Field Name';

  @override
  String get fieldValueLabel => 'Value';

  @override
  String get saveCardButton => 'SAVE CARD';

  @override
  String get addCustomField => 'Add Custom Field';

  @override
  String get selectImage => 'Select Image';

  @override
  String get cardColorLabel => 'CARD COLOR';

  @override
  String get customColorTitle => 'Custom Color';

  @override
  String get hexColorCodeLabel => 'Hex Color Code';

  @override
  String get applyButton => 'Apply';

  @override
  String get walletDetailSecurity => 'Security';

  @override
  String get walletDetailCardImages => 'Card Images';

  @override
  String get walletDetailFinancials => 'Financials';

  @override
  String get walletDetailBillingTerms => 'Billing & Terms';

  @override
  String get walletDetailCustomFields => 'Custom Fields';

  @override
  String get walletDetailPrimaryDetails => 'Primary Details';

  @override
  String get financialMaxLimit => 'Max Limit';

  @override
  String get financialAnnualSpends => 'Annual Spends';

  @override
  String get financialEstimatedCashback => 'Estimated Cashback';

  @override
  String get financialBillDate => 'Bill Generation Date';

  @override
  String get financialAnnualFeeWaiver => 'Annual Fee Waiver';

  @override
  String get financialCardType => 'Card Type';

  @override
  String get feeWaiverNotApplicable => 'Not Applicable';

  @override
  String get feeWaiverWaived => 'Waived Off';

  @override
  String feeWaiverRemaining(String symbol, String amount) {
    return '$symbol$amount more to waive';
  }

  @override
  String billEveryDate(String date) {
    return 'Every $date';
  }

  @override
  String get naValue => 'N/A';

  @override
  String maxLimitField(String symbol) {
    return 'Max Limit ($symbol)';
  }

  @override
  String currentSpendsField(String symbol) {
    return 'Current Spends ($symbol)';
  }

  @override
  String get cashbackRateField => 'Cashback Rate (%)';

  @override
  String get billDateField => 'Bill Date (e.g., 15)';

  @override
  String annualFeeWaiverField(String symbol) {
    return 'Annual Fee Waiver on Spends of ($symbol)';
  }

  @override
  String get cardTypeField => 'Card Type (e.g., LTF, Paid)';

  @override
  String get cardNamePlaceholder => 'CARD NAME';

  @override
  String get sharePassTitle => 'Share Pass';

  @override
  String get sharePassTooltip => 'Share Pass (Encrypted Data)';

  @override
  String get shareCardTitle => 'Share Card';

  @override
  String sharePassOrCard(String type) {
    return 'Share $type';
  }

  @override
  String scanAllQrCodes(int count) {
    return 'SCAN ALL $count QR CODES';
  }

  @override
  String get scanToImportLabel => 'SCAN TO IMPORT';

  @override
  String get tapToSetPassword => 'Tap to Set Password';

  @override
  String get toGenerateQr => 'to generate QR code';

  @override
  String get passwordEncryptedTransfer => 'Password-Encrypted Transfer';

  @override
  String shareMultiChunkBody(int count) {
    return 'Your data is split across $count QR codes. The receiver must scan all of them and enter the password to decrypt.';
  }

  @override
  String get shareSingleBody =>
      'This QR code contains your data encrypted with a password. The receiver must enter the same password to decrypt and import it.';

  @override
  String get exportPkpass => 'Export as .pkpass';

  @override
  String get exportPassDialog => 'Export Pass';

  @override
  String get copyChunkData => 'Copy chunk data';

  @override
  String get showToCashier => 'Show this to cashier';

  @override
  String get cannotDisplayFormat => 'Cannot display in this format';

  @override
  String get invalidBarcodeData => 'Invalid Barcode Data';

  @override
  String get invalidBarcode => 'Invalid Barcode';

  @override
  String get barcodeOrgName => 'Name (Organization)';

  @override
  String get barcodeValueLabel => 'Barcode Value';

  @override
  String get barcodeFormatLabel => 'Barcode Format';

  @override
  String get passCategoryLabel => 'Pass Category';

  @override
  String get transitTypeLabel => 'Transit Type';

  @override
  String get importFromGallery => 'Import from Gallery';

  @override
  String get scanBarcode => 'Scan Barcode';

  @override
  String get attachmentsOptional => 'ATTACHMENTS (OPTIONAL)';

  @override
  String get frontSide => 'Front Side';

  @override
  String get backSide => 'Back Side';

  @override
  String get additionalDetails => 'Additional Details';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get logoTextLabel => 'Logo Text';

  @override
  String get savePassButton => 'SAVE PASS';

  @override
  String get noBarcodeDetected =>
      'No barcode or QR code detected in the selected image.';

  @override
  String get errorReadingImage => 'Error reading image file.';

  @override
  String get orgPlaceholder => 'ORGANIZATION';

  @override
  String get fieldSectionPrimary => 'Primary Fields (Main Info)';

  @override
  String get fieldSectionSecondary => 'Secondary Fields (Details)';

  @override
  String get fieldSectionAuxiliary => 'Auxiliary Fields (More)';

  @override
  String get fieldSectionHeader => 'Header Fields (Top Right)';

  @override
  String get fieldSectionBack => 'Back Details (Fine Print)';

  @override
  String get passImagesTitle => 'Pass Images';

  @override
  String get identityImagesTitle => 'Identity Images';

  @override
  String get cardDetailsTitle => 'Card Details';

  @override
  String get cardTypeLabel => 'Card Type';

  @override
  String get nameLabel => 'Name';

  @override
  String get idNumberLabel => 'ID Number';

  @override
  String get identityCardDefaultType => 'Identity Card';

  @override
  String get idNamePlaceholder => 'NAME';

  @override
  String get idValuePlaceholder => 'ID NUMBER';

  @override
  String get idDocumentNumberPlaceholder => 'DOCUMENT NUMBER';

  @override
  String get idCardTypePlaceholder => 'IDENTITY CARD';

  @override
  String get idCardLabelHint => 'Card Label (e.g. Passport, License)';

  @override
  String get idCardLabelExample => 'e.g. Passport';

  @override
  String get fullNameLabel => 'Full Name';

  @override
  String get fullNameExample => 'e.g. John Doe';

  @override
  String get idValueLabel => 'ID Value / Number';

  @override
  String get idValueExample => 'e.g. 123-456-789';

  @override
  String get saveIdentityCardButton => 'SAVE IDENTITY CARD';

  @override
  String get frontLabel => 'Front';

  @override
  String get backLabel => 'Back';

  @override
  String get stripLabel => 'Strip';

  @override
  String get thumbnailLabel => 'Thumbnail';

  @override
  String get sectionFlightDetails => 'Flight Details';

  @override
  String get sectionPassengerInfo => 'Passenger Info';

  @override
  String get sectionTravelInfo => 'Travel Info';

  @override
  String get sectionEventDetails => 'Event Details';

  @override
  String get sectionVenueInfo => 'Venue Info';

  @override
  String get sectionTicketDetails => 'Ticket Details';

  @override
  String get sectionMemberInfo => 'Member Info';

  @override
  String get sectionAccountDetails => 'Account Details';

  @override
  String get sectionRewardsInfo => 'Rewards Info';

  @override
  String get sectionCardInfo => 'Card Info';

  @override
  String get sectionBalancePin => 'Balance & PIN';

  @override
  String get sectionGiftDetails => 'Gift Details';

  @override
  String get sectionOfferDetails => 'Offer Details';

  @override
  String get sectionProviderInfo => 'Provider Info';

  @override
  String get sectionTerms => 'Terms';

  @override
  String get sectionCouponInfo => 'Coupon Info';

  @override
  String get sectionRouteDetails => 'Route Details';

  @override
  String get sectionTripInfo => 'Trip Info';

  @override
  String get sectionFareDetails => 'Fare Details';

  @override
  String get sectionVehicleInfo => 'Vehicle Info';

  @override
  String get sectionKeyDetails => 'Key Details';

  @override
  String get sectionAccessInfo => 'Access Info';

  @override
  String get sectionStudentInfo => 'Student Info';

  @override
  String get sectionUniversityDetails => 'University Details';

  @override
  String get sectionEmployeeInfo => 'Employee Info';

  @override
  String get sectionCompanyDetails => 'Company Details';

  @override
  String get sectionGuestInfo => 'Guest Info';

  @override
  String get sectionHotelDetails => 'Hotel Details';

  @override
  String get sectionStayDetails => 'Stay Details';

  @override
  String get sectionResidentInfo => 'Resident Info';

  @override
  String get sectionPropertyDetails => 'Property Details';

  @override
  String get sectionPolicyDetails => 'Policy Details';

  @override
  String get sectionCoverageInfo => 'Coverage Info';

  @override
  String get sectionTestInfo => 'Test Info';

  @override
  String get sectionResults => 'Results';

  @override
  String get sectionLabDetails => 'Lab Details';

  @override
  String get sectionVaccineInfo => 'Vaccine Info';

  @override
  String get sectionDoseDetails => 'Dose Details';

  @override
  String get sectionManufacturerInfo => 'Manufacturer Info';

  @override
  String get sectionDocumentInfo => 'Document Info';

  @override
  String get sectionIssuerDetails => 'Issuer Details';

  @override
  String get sectionVerification => 'Verification';

  @override
  String get sectionOrganization => 'Organization';

  @override
  String get sectionDataDetails => 'Data Details';

  @override
  String get sectionAdditionalInfo => 'Additional Info';

  @override
  String get sectionPaymentInfo => 'Payment Info';

  @override
  String get sectionHeaderDetails => 'Header Details';

  @override
  String get sectionCardDetails => 'Card Details';

  @override
  String get sectionInformation => 'Information';

  @override
  String get fieldFrom => 'From';

  @override
  String get fieldTo => 'To';

  @override
  String get fieldPassenger => 'Passenger';

  @override
  String get fieldFlight => 'Flight';

  @override
  String get fieldGate => 'Gate';

  @override
  String get fieldSeat => 'Seat';

  @override
  String get fieldDeparture => 'Departure';

  @override
  String get fieldArrival => 'Arrival';

  @override
  String get fieldMemberName => 'Member Name';

  @override
  String get fieldBalance => 'Balance';

  @override
  String get fieldTier => 'Tier';

  @override
  String get fieldAccountNo => 'Account #';

  @override
  String get fieldPoints => 'Points';

  @override
  String get fieldCardNumber => 'Card Number';

  @override
  String get fieldPin => 'PIN';

  @override
  String get fieldRecipient => 'Recipient';

  @override
  String get fieldEventNo => 'Event #';

  @override
  String get fieldOffer => 'Offer';

  @override
  String get fieldProvider => 'Provider';

  @override
  String get fieldExpires => 'Expires';

  @override
  String get fieldTerms => 'Terms';

  @override
  String get fieldCode => 'Code';

  @override
  String get fieldEvent => 'Event';

  @override
  String get fieldVenue => 'Venue';

  @override
  String get fieldDate => 'Date';

  @override
  String get fieldSection => 'Section';

  @override
  String get fieldRow => 'Row';

  @override
  String get fieldTime => 'Time';

  @override
  String get fieldRoute => 'Route';

  @override
  String get fieldFareClass => 'Fare Class';

  @override
  String get fieldFare => 'Fare';

  @override
  String get fieldCoach => 'Coach';

  @override
  String get fieldPlatform => 'Platform';

  @override
  String get fieldVehicle => 'Vehicle';

  @override
  String get fieldKeyStatus => 'Key Status';

  @override
  String get fieldVin => 'VIN';

  @override
  String get fieldDevice => 'Device';

  @override
  String get fieldStudentName => 'Student Name';

  @override
  String get fieldUniversity => 'University';

  @override
  String get fieldIdNo => 'ID #';

  @override
  String get fieldDorm => 'Dorm';

  @override
  String get fieldYear => 'Year';

  @override
  String get fieldEmployeeName => 'Employee Name';

  @override
  String get fieldCompany => 'Company';

  @override
  String get fieldDept => 'Dept';

  @override
  String get fieldAccessLevel => 'Access Level';

  @override
  String get fieldGuestName => 'Guest Name';

  @override
  String get fieldHotel => 'Hotel';

  @override
  String get fieldRoomNo => 'Room #';

  @override
  String get fieldCheckIn => 'Check-in';

  @override
  String get fieldCheckOut => 'Check-out';

  @override
  String get fieldResidentName => 'Resident Name';

  @override
  String get fieldProperty => 'Property';

  @override
  String get fieldUnitNo => 'Unit #';

  @override
  String get fieldPolicyNo => 'Policy #';

  @override
  String get fieldGroupNo => 'Group #';

  @override
  String get fieldPcn => 'PCN';

  @override
  String get fieldTestType => 'Test Type';

  @override
  String get fieldResult => 'Result';

  @override
  String get fieldLab => 'Lab';

  @override
  String get fieldVaccine => 'Vaccine';

  @override
  String get fieldDose => 'Dose';

  @override
  String get fieldManufacturer => 'Manufacturer';

  @override
  String get fieldLotNo => 'Lot #';

  @override
  String get fieldDocumentType => 'Document Type';

  @override
  String get fieldIssuer => 'Issuer';

  @override
  String get fieldExpiry => 'Expiry';

  @override
  String get fieldVerified => 'Verified';

  @override
  String get fieldDataType => 'Data Type';

  @override
  String get fieldNotes => 'Notes';

  @override
  String get fieldCardType => 'Card Type';

  @override
  String get fieldMerchant => 'Merchant';

  @override
  String get fieldDetails => 'Details';

  @override
  String get passCategoryRetail => 'Retail';

  @override
  String get passCategoryTickets => 'Tickets & Transit';

  @override
  String get passCategoryAccess => 'Access';

  @override
  String get passCategoryHealth => 'Health';

  @override
  String get passCategoryIdentity => 'Identity';

  @override
  String get passCategoryGeneric => 'Generic';

  @override
  String get passTypeLoyaltyCard => 'Loyalty Card';

  @override
  String get passTypeGiftCard => 'Gift Card';

  @override
  String get passTypeOffer => 'Offer';

  @override
  String get passTypeInStorePayment => 'In-Store Payment';

  @override
  String get passTypeBoardingPass => 'Boarding Pass';

  @override
  String get passTypeEventTicket => 'Event Ticket';

  @override
  String get passTypeTransitPass => 'Transit Pass';

  @override
  String get passTypeDigitalCarKey => 'Digital Car Key';

  @override
  String get passTypeCampusId => 'Campus ID';

  @override
  String get passTypeCorporateBadge => 'Corporate Badge';

  @override
  String get passTypeHotelKey => 'Hotel Key';

  @override
  String get passTypeMultiFamilyKey => 'Multi-Family Key';

  @override
  String get passTypeHealthInsurance => 'Health Insurance';

  @override
  String get passTypeTestRecord => 'Test Record';

  @override
  String get passTypeVaccineCard => 'Vaccine Card';

  @override
  String get passTypeDigitalCredential => 'Digital Credential';

  @override
  String get passTypeGeneric => 'Generic';

  @override
  String get passTypeGenericPrivate => 'Private Pass';

  @override
  String get passTypeCoupon => 'Coupon';

  @override
  String get passTypeStoreCard => 'Store Card';

  @override
  String get networkVisa => 'VISA';

  @override
  String get networkMastercard => 'Mastercard';

  @override
  String get networkAmex => 'AMEX';

  @override
  String get networkDiscover => 'DISCOVER';

  @override
  String get networkRupay => 'RUPAY';

  @override
  String get networkUnionpay => '银联';

  @override
  String get networkJcb => 'JCB';

  @override
  String get organizationRequired => 'Organization is required.';

  @override
  String scannedFormat(String format, String text) {
    return 'Scanned $format: $text';
  }

  @override
  String get barcodeWord => 'Barcode';

  @override
  String get fieldOrganization => 'Organization';

  @override
  String get fieldTermsConditions => 'Terms & Conditions';

  @override
  String get fieldContact => 'Contact';

  @override
  String get nameOrganizationLabel => 'Name (Organization)';

  @override
  String get saveBackupDialogTitle => 'Save Backup File';

  @override
  String get noCvvPlaceholder => 'No CVV';

  @override
  String get cardCategoryLabel => 'Card Category';

  @override
  String get cardCategoryCredit => 'Credit';

  @override
  String get cardCategoryDebit => 'Debit';

  @override
  String get cardCategoryNone => 'None';

  @override
  String get tagsLabel => 'Tags';

  @override
  String get tagsAddHint => 'Type tag and press enter';

  @override
  String get tagsEmpty => 'No tags';

  @override
  String get filterNetwork => 'Network';

  @override
  String get filterIssuer => 'Issuer';

  @override
  String get filterType => 'Type';

  @override
  String get filterAllNetworks => 'All Networks';

  @override
  String get filterAllIssuers => 'All Issuers';

  @override
  String get filterAllCardTypes => 'All Card Types';

  @override
  String get actionArchive => 'Archive';

  @override
  String get actionUnarchive => 'Unarchive';

  @override
  String get actionDeletePermanently => 'Delete Permanently';

  @override
  String get archivedView => 'Archived';

  @override
  String get activeView => 'Active';

  @override
  String get cardArchived => 'Card archived';

  @override
  String get cardUnarchived => 'Card unarchived';

  @override
  String archiveConfirmBody(String name) {
    return 'Archive \"$name\"? You can restore it from the archive view.';
  }

  @override
  String deletePermanentlyConfirmBody(String name) {
    return 'Permanently delete \"$name\"? This cannot be undone.';
  }

  @override
  String get noArchivedCards => 'No archived cards';

  @override
  String get unknownIssuer => 'Unknown Issuer';

  @override
  String get scannerTitleFront => 'Scan Front of Card';

  @override
  String get scannerTitleBack => 'Scan Back of Card';

  @override
  String get scannerTitleNumberOnly => 'Scan Card Number';

  @override
  String get scannerHintFront =>
      'Align card inside the green frame and tap the shutter when focused';

  @override
  String get scannerHintBack =>
      'Align the back of the card (signature strip + CVV) inside the frame';

  @override
  String get scannerHintNumberOnly =>
      'Frame the card number in the rectangle, then tap to scan';

  @override
  String get scannerShutterHint =>
      'Manual shutter — tap only when the image is sharp';

  @override
  String get scannerNextBack => 'Scan Back Side';

  @override
  String get scannerFinish => 'Done';

  @override
  String get scannerRetake => 'Retake';

  @override
  String get scannerSkipBack => 'Skip Back';

  @override
  String get scannerCropOk => '✓ Card edges detected and auto-cropped';

  @override
  String get scannerCropFallback =>
      'Could not detect edges; keeping original photo';

  @override
  String get scannerProcessing => 'Processing…';

  @override
  String get scannerOcrInProgress => 'Recognising text…';

  @override
  String get scannerOcrFailed => 'OCR failed';

  @override
  String get scannerCaptureFailed => 'Capture failed';

  @override
  String get scannerCameraInitializing => 'Starting camera…';

  @override
  String get scannerDetecting => 'Detecting…';

  @override
  String get scannerCameraPermissionDenied =>
      'Camera permission denied — enable it in Settings';

  @override
  String get scannerNoCameraFound => 'No camera available on this device';

  @override
  String get scannerUnknownError => 'Unknown error';

  @override
  String get scannerCameraInitFailed => 'Failed to start camera';

  @override
  String get addCardActionScan => 'Scan to add card';

  @override
  String get scanCardNumberTooltip => 'Scan card number';
}
