import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// App name shown in MaterialApp title
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get appTitle;

  /// Splash screen tagline
  ///
  /// In en, this message translates to:
  /// **'Secure • Simple • Smart'**
  String get splashTagline;

  /// Biometric authentication prompt on splash
  ///
  /// In en, this message translates to:
  /// **'Authenticate to access your wallet'**
  String get splashAuthReason;

  /// Bottom nav: Payments tab
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get navPayments;

  /// Bottom nav: Passes tab
  ///
  /// In en, this message translates to:
  /// **'Passes'**
  String get navPasses;

  /// Bottom nav: Identity tab
  ///
  /// In en, this message translates to:
  /// **'Identity'**
  String get navIdentity;

  /// Tooltip for scan button on home
  ///
  /// In en, this message translates to:
  /// **'Scan to Import'**
  String get scanToImport;

  /// Empty state for payments tab
  ///
  /// In en, this message translates to:
  /// **'No credit or debit cards yet.\nTap the \'+\' to add one.'**
  String get emptyPayments;

  /// Empty state for passes tab
  ///
  /// In en, this message translates to:
  /// **'No passes added yet.\nTap the \'+\' to add one.'**
  String get emptyPasses;

  /// Empty state for identity tab
  ///
  /// In en, this message translates to:
  /// **'No identity cards yet.\nTap the \'+\' to add one.'**
  String get emptyIdentities;

  /// Search hint for cards
  ///
  /// In en, this message translates to:
  /// **'Search cards...'**
  String get searchCards;

  /// Search hint for passes
  ///
  /// In en, this message translates to:
  /// **'Search passes...'**
  String get searchPasses;

  /// Search hint for identities
  ///
  /// In en, this message translates to:
  /// **'Search identities...'**
  String get searchIdentities;

  /// Shown when filter yields no cards
  ///
  /// In en, this message translates to:
  /// **'No cards found.'**
  String get noCardsFound;

  /// Shown when filter yields no passes
  ///
  /// In en, this message translates to:
  /// **'No passes found.'**
  String get noPassesFound;

  /// Shown when filter yields no identities
  ///
  /// In en, this message translates to:
  /// **'No identity cards found.'**
  String get noIdentitiesFound;

  /// Filter chip: all
  ///
  /// In en, this message translates to:
  /// **'ALL'**
  String get filterAll;

  /// No description provided for @filterLoyalty.
  ///
  /// In en, this message translates to:
  /// **'LOYALTY'**
  String get filterLoyalty;

  /// No description provided for @filterGiftCards.
  ///
  /// In en, this message translates to:
  /// **'GIFT CARDS'**
  String get filterGiftCards;

  /// No description provided for @filterOffers.
  ///
  /// In en, this message translates to:
  /// **'OFFERS'**
  String get filterOffers;

  /// No description provided for @filterBoarding.
  ///
  /// In en, this message translates to:
  /// **'BOARDING'**
  String get filterBoarding;

  /// No description provided for @filterEvents.
  ///
  /// In en, this message translates to:
  /// **'EVENTS'**
  String get filterEvents;

  /// No description provided for @filterTransit.
  ///
  /// In en, this message translates to:
  /// **'TRANSIT'**
  String get filterTransit;

  /// No description provided for @filterHealth.
  ///
  /// In en, this message translates to:
  /// **'HEALTH'**
  String get filterHealth;

  /// No description provided for @filterCampus.
  ///
  /// In en, this message translates to:
  /// **'CAMPUS'**
  String get filterCampus;

  /// No description provided for @filterCorporate.
  ///
  /// In en, this message translates to:
  /// **'CORPORATE'**
  String get filterCorporate;

  /// No description provided for @filterHotel.
  ///
  /// In en, this message translates to:
  /// **'HOTEL'**
  String get filterHotel;

  /// No description provided for @filterOther.
  ///
  /// In en, this message translates to:
  /// **'OTHER'**
  String get filterOther;

  /// Slidable action: edit
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get actionEdit;

  /// Slidable action: copy
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get actionCopy;

  /// Slidable action: delete
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// Snackbar when card number copied
  ///
  /// In en, this message translates to:
  /// **'Card number copied!'**
  String get cardNumberCopied;

  /// Snackbar when pass data copied
  ///
  /// In en, this message translates to:
  /// **'Pass data copied!'**
  String get passDataCopied;

  /// Snackbar when identity value copied
  ///
  /// In en, this message translates to:
  /// **'ID value copied!'**
  String get idValueCopied;

  /// Snackbar on detail screen card tap
  ///
  /// In en, this message translates to:
  /// **'Card Number Copied!'**
  String get cardNumberCopiedBang;

  /// Snackbar when CVV copied
  ///
  /// In en, this message translates to:
  /// **'CVV Copied!'**
  String get cvvCopied;

  /// Snackbar on identity detail tap
  ///
  /// In en, this message translates to:
  /// **'ID Number Copied!'**
  String get idNumberCopied;

  /// Generic clipboard snackbar
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copiedToClipboard;

  /// Snackbar when QR chunk copied
  ///
  /// In en, this message translates to:
  /// **'QR data copied to clipboard'**
  String get qrDataCopied;

  /// Delete payment card dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete Card?'**
  String get deleteWalletTitle;

  /// Snackbar after payment card deleted
  ///
  /// In en, this message translates to:
  /// **'Card deleted!'**
  String get cardDeleted;

  /// Delete pass dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete Pass?'**
  String get deletePassTitle;

  /// Delete identity dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete Identity Card?'**
  String get deleteIdentityTitle;

  /// Delete confirmation body with name placeholder
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"? This action cannot be undone.'**
  String deleteConfirmBody(Object name);

  /// Snackbar after pass deletion
  ///
  /// In en, this message translates to:
  /// **'Pass Deleted!'**
  String get passDeleted;

  /// Snackbar after identity deletion
  ///
  /// In en, this message translates to:
  /// **'Identity Card Deleted!'**
  String get identityDeleted;

  /// Import confirmation dialog title
  ///
  /// In en, this message translates to:
  /// **'Import Shared {type}'**
  String importSharedTitle(String type);

  /// Import confirmation body
  ///
  /// In en, this message translates to:
  /// **'Do you want to import \"{name}\"?'**
  String importSharedBody(String name);

  /// No description provided for @invalidShareCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid or corrupted sharing code.'**
  String get invalidShareCode;

  /// No description provided for @invalidShareFormat.
  ///
  /// In en, this message translates to:
  /// **'Invalid sharing code format.'**
  String get invalidShareFormat;

  /// No description provided for @invalidPassData.
  ///
  /// In en, this message translates to:
  /// **'Invalid pass data.'**
  String get invalidPassData;

  /// No description provided for @invalidCardData.
  ///
  /// In en, this message translates to:
  /// **'Invalid card data.'**
  String get invalidCardData;

  /// No description provided for @invalidIdentityData.
  ///
  /// In en, this message translates to:
  /// **'Invalid identity data.'**
  String get invalidIdentityData;

  /// No description provided for @importFailedCorrupted.
  ///
  /// In en, this message translates to:
  /// **'Failed to import. The sharing code may be corrupted.'**
  String get importFailedCorrupted;

  /// No description provided for @invalidChunkFormat.
  ///
  /// In en, this message translates to:
  /// **'Invalid chunk format.'**
  String get invalidChunkFormat;

  /// No description provided for @invalidChunkIndex.
  ///
  /// In en, this message translates to:
  /// **'Invalid chunk index.'**
  String get invalidChunkIndex;

  /// No description provided for @chunkMismatch.
  ///
  /// In en, this message translates to:
  /// **'Chunk mismatch. Please restart scanning.'**
  String get chunkMismatch;

  /// No description provided for @failedParseChunk.
  ///
  /// In en, this message translates to:
  /// **'Failed to parse chunk.'**
  String get failedParseChunk;

  /// No description provided for @decryptFailed.
  ///
  /// In en, this message translates to:
  /// **'Decryption failed. Wrong password or corrupted data.'**
  String get decryptFailed;

  /// No description provided for @importFailedWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Failed to import. Wrong password or corrupted data.'**
  String get importFailedWrongPassword;

  /// Progress snackbar for chunk scanning
  ///
  /// In en, this message translates to:
  /// **'Scanned chunk {current} of {total}'**
  String scannedChunk(int current, int total);

  /// Dialog title for entering transfer password on import
  ///
  /// In en, this message translates to:
  /// **'Enter Transfer Password'**
  String get enterTransferPasswordTitle;

  /// No description provided for @enterTransferPasswordBody.
  ///
  /// In en, this message translates to:
  /// **'Enter the password that was used to encrypt this transfer.'**
  String get enterTransferPasswordBody;

  /// No description provided for @passImportedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Pass imported successfully!'**
  String get passImportedSuccess;

  /// No description provided for @paymentCardImportedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Payment card imported successfully!'**
  String get paymentCardImportedSuccess;

  /// No description provided for @identityCardImportedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Identity card imported successfully!'**
  String get identityCardImportedSuccess;

  /// No description provided for @typeLabelPass.
  ///
  /// In en, this message translates to:
  /// **'Pass'**
  String get typeLabelPass;

  /// No description provided for @typeLabelPaymentCard.
  ///
  /// In en, this message translates to:
  /// **'Payment Card'**
  String get typeLabelPaymentCard;

  /// No description provided for @typeLabelIdentityCard.
  ///
  /// In en, this message translates to:
  /// **'Identity Card'**
  String get typeLabelIdentityCard;

  /// Generic 'Card' label used in share screen app bar title
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get typeLabelCard;

  /// Uppercase SAVE button on edit screens
  ///
  /// In en, this message translates to:
  /// **'SAVE'**
  String get saveButton;

  /// No description provided for @cancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// No description provided for @importButton.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get importButton;

  /// No description provided for @deleteButton.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteButton;

  /// No description provided for @closeButton.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeButton;

  /// No description provided for @enableButton.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get enableButton;

  /// No description provided for @saveButtonText.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveButtonText;

  /// Dialog title when importing pkpass
  ///
  /// In en, this message translates to:
  /// **'Import Pass'**
  String get importPassTitle;

  /// pkpass import confirmation body
  ///
  /// In en, this message translates to:
  /// **'Do you want to import \"{name}\"?'**
  String importPassBody(String name);

  /// No description provided for @passImportedSuccessShort.
  ///
  /// In en, this message translates to:
  /// **'Pass imported successfully!'**
  String get passImportedSuccessShort;

  /// No description provided for @pkpassParseFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to parse .pkpass file.'**
  String get pkpassParseFailed;

  /// No description provided for @passImportFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to import pass. Please try again.'**
  String get passImportFailed;

  /// Button label for importing pkpass
  ///
  /// In en, this message translates to:
  /// **'Import pkpass'**
  String get importPkpass;

  /// Settings page app bar title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @sectionStartupLayout.
  ///
  /// In en, this message translates to:
  /// **'Startup & Layout'**
  String get sectionStartupLayout;

  /// No description provided for @sectionAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get sectionAppearance;

  /// No description provided for @sectionDataManagement.
  ///
  /// In en, this message translates to:
  /// **'Data Management'**
  String get sectionDataManagement;

  /// No description provided for @sectionAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get sectionAbout;

  /// No description provided for @authScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Authentication Screen'**
  String get authScreenTitle;

  /// No description provided for @authScreenSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Require biometrics when app starts'**
  String get authScreenSubtitle;

  /// Biometric prompt for destructive actions
  ///
  /// In en, this message translates to:
  /// **'Authenticate to perform this action'**
  String get authenticateAction;

  /// Settings tile: currency
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currencyTitle;

  /// Currency dialog title
  ///
  /// In en, this message translates to:
  /// **'Choose Currency'**
  String get chooseCurrency;

  /// No description provided for @defaultScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Default Screen'**
  String get defaultScreenTitle;

  /// No description provided for @defaultScreenSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Default Screen'**
  String get defaultScreenSubtitle;

  /// Default screen dialog title
  ///
  /// In en, this message translates to:
  /// **'Default Screen'**
  String get chooseDefaultScreen;

  /// No description provided for @paymentsOnlyTitle.
  ///
  /// In en, this message translates to:
  /// **'Payments Only Mode'**
  String get paymentsOnlyTitle;

  /// No description provided for @paymentsOnlySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Hide Passes and Identity screen'**
  String get paymentsOnlySubtitle;

  /// No description provided for @appThemeTitle.
  ///
  /// In en, this message translates to:
  /// **'App Theme'**
  String get appThemeTitle;

  /// No description provided for @appThemeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'App Theme'**
  String get appThemeSubtitle;

  /// No description provided for @chooseTheme.
  ///
  /// In en, this message translates to:
  /// **'Choose Theme'**
  String get chooseTheme;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow System'**
  String get themeSystem;

  /// No description provided for @useSystemFontTitle.
  ///
  /// In en, this message translates to:
  /// **'Use System Font'**
  String get useSystemFontTitle;

  /// No description provided for @useSystemFontSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use the default system font'**
  String get useSystemFontSubtitle;

  /// No description provided for @autoBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'Auto Backup'**
  String get autoBackupTitle;

  /// No description provided for @autoBackupSubtitleOff.
  ///
  /// In en, this message translates to:
  /// **'Automatically backup on changes'**
  String get autoBackupSubtitleOff;

  /// No description provided for @autoBackupSubtitleNoPath.
  ///
  /// In en, this message translates to:
  /// **'Configure backup location'**
  String get autoBackupSubtitleNoPath;

  /// Auto backup active subtitle
  ///
  /// In en, this message translates to:
  /// **'Active - {path}'**
  String autoBackupSubtitleActive(String path);

  /// No description provided for @backupLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Backup Location'**
  String get backupLocationTitle;

  /// No description provided for @changeBackupPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Change Backup Password'**
  String get changeBackupPasswordTitle;

  /// No description provided for @changeBackupPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update the auto backup encryption password'**
  String get changeBackupPasswordSubtitle;

  /// No description provided for @enableAutoBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable Auto Backup'**
  String get enableAutoBackupTitle;

  /// No description provided for @enableAutoBackupBody.
  ///
  /// In en, this message translates to:
  /// **'A backup will be created automatically whenever you add or remove cards, passes, or identity cards.'**
  String get enableAutoBackupBody;

  /// No description provided for @selectDirectoryHint.
  ///
  /// In en, this message translates to:
  /// **'Select directory...'**
  String get selectDirectoryHint;

  /// No description provided for @backupPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Backup Password'**
  String get backupPasswordLabel;

  /// No description provided for @enterPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter password'**
  String get enterPasswordHint;

  /// No description provided for @enterNewPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter new password (min 8 characters)'**
  String get enterNewPasswordHint;

  /// No description provided for @createBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Backup'**
  String get createBackupTitle;

  /// No description provided for @createBackupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Save an encrypted copy of your data'**
  String get createBackupSubtitle;

  /// No description provided for @createBackupDialogBody.
  ///
  /// In en, this message translates to:
  /// **'Enter a strong password to encrypt your backup file.'**
  String get createBackupDialogBody;

  /// No description provided for @createBackupButton.
  ///
  /// In en, this message translates to:
  /// **'Create Backup'**
  String get createBackupButton;

  /// No description provided for @restoreBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore from Backup'**
  String get restoreBackupTitle;

  /// No description provided for @restoreBackupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Replace current data from a backup file'**
  String get restoreBackupSubtitle;

  /// No description provided for @restoreBackupDialogBody.
  ///
  /// In en, this message translates to:
  /// **'Enter the password for the backup file. This will replace all current data.'**
  String get restoreBackupDialogBody;

  /// No description provided for @restoreButton.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restoreButton;

  /// No description provided for @deleteAllDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete All Data?'**
  String get deleteAllDataTitle;

  /// No description provided for @deleteAllDataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Permanently erase all data from this device'**
  String get deleteAllDataSubtitle;

  /// No description provided for @deleteAllDataBody.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete all wallets, passes, and images.'**
  String get deleteAllDataBody;

  /// No description provided for @deleteEverythingButton.
  ///
  /// In en, this message translates to:
  /// **'Delete Everything'**
  String get deleteEverythingButton;

  /// No description provided for @allDataDeleted.
  ///
  /// In en, this message translates to:
  /// **'All data deleted.'**
  String get allDataDeleted;

  /// No description provided for @deleteFailedRetry.
  ///
  /// In en, this message translates to:
  /// **'Delete failed. Please try again.'**
  String get deleteFailedRetry;

  /// Title of the collapsible danger-zone settings section
  ///
  /// In en, this message translates to:
  /// **'Danger Zone'**
  String get sectionDangerZone;

  /// Subtitle for the danger-zone section header
  ///
  /// In en, this message translates to:
  /// **'Irreversible destructive operations'**
  String get dangerZoneSubtitle;

  /// Title shown on the system PIN prompt for delete-all-data
  ///
  /// In en, this message translates to:
  /// **'Verify PIN'**
  String get dangerZonePinAuthTitle;

  /// Subtitle on the system PIN prompt
  ///
  /// In en, this message translates to:
  /// **'Enter your device PIN to delete all data. Fingerprint is not accepted.'**
  String get dangerZonePinAuthSubtitle;

  /// Shown when device credential auth is not supported
  ///
  /// In en, this message translates to:
  /// **'PIN verification is unavailable on this device. Set a screen lock (PIN/password) to proceed.'**
  String get pinAuthUnavailable;

  /// No description provided for @trademarkNoticeTitle.
  ///
  /// In en, this message translates to:
  /// **'Trademark Notice'**
  String get trademarkNoticeTitle;

  /// No description provided for @trademarkNoticeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Card network logos are trademarks of their respective owners.'**
  String get trademarkNoticeSubtitle;

  /// No description provided for @trademarkDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Trademark Fair Use Notice'**
  String get trademarkDialogTitle;

  /// Trademark fair use notice body text
  ///
  /// In en, this message translates to:
  /// **'The Visa, Mastercard, UnionPay, JCB, RuPay, American Express, and Discover logos displayed in this application are registered trademarks of their respective owners.\n\nThese logos are used solely for identifying the card network. This usage constitutes nominative fair use.\n\nThis application is not affiliated with, endorsed by, or sponsored by any of these companies.'**
  String get trademarkDialogBody;

  /// No description provided for @reportErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Report Error'**
  String get reportErrorTitle;

  /// No description provided for @reportErrorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Found a bug? Let us know on GitHub.'**
  String get reportErrorSubtitle;

  /// Sponsorship banner text
  ///
  /// In en, this message translates to:
  /// **'Buy Me a Coffee'**
  String get buyMeACoffee;

  /// Generic password field label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// Password validation error
  ///
  /// In en, this message translates to:
  /// **'Password must be at least {min} characters'**
  String passwordTooShort(int min);

  /// No description provided for @setTransferPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Set Transfer Password'**
  String get setTransferPasswordTitle;

  /// No description provided for @setTransferPasswordBody.
  ///
  /// In en, this message translates to:
  /// **'Enter a password to encrypt the transfer. The receiver will need this to import.'**
  String get setTransferPasswordBody;

  /// No description provided for @generateQrButton.
  ///
  /// In en, this message translates to:
  /// **'Generate QR'**
  String get generateQrButton;

  /// Shown when backup path is empty
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get pathNotSet;

  /// Form field: cardholder/card name
  ///
  /// In en, this message translates to:
  /// **'Card Name'**
  String get cardNameLabel;

  /// Form field: card number
  ///
  /// In en, this message translates to:
  /// **'Card Number'**
  String get cardNumberLabel;

  /// Form field: expiry in MMYY format
  ///
  /// In en, this message translates to:
  /// **'Expiry (MMYY)'**
  String get expiryLabel;

  /// Form field: CVV security code
  ///
  /// In en, this message translates to:
  /// **'CVV'**
  String get cvvLabel;

  /// Form field: card issuer / 发卡行
  ///
  /// In en, this message translates to:
  /// **'Card Issuer (e.g., HDFC)'**
  String get cardIssuerLabel;

  /// No description provided for @cardIssuerLabelEdit.
  ///
  /// In en, this message translates to:
  /// **'Card Issuer (e.g. HDFC)'**
  String get cardIssuerLabelEdit;

  /// Form field: card network dropdown
  ///
  /// In en, this message translates to:
  /// **'Card Network'**
  String get cardNetworkLabel;

  /// No description provided for @validationEnterName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a name'**
  String get validationEnterName;

  /// No description provided for @validationEnterCardNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a card number'**
  String get validationEnterCardNumber;

  /// No description provided for @validationCardNumberLength.
  ///
  /// In en, this message translates to:
  /// **'Card number must be 15-19 digits'**
  String get validationCardNumberLength;

  /// No description provided for @validationCardNumberLengthEdit.
  ///
  /// In en, this message translates to:
  /// **'Card number must be 13-19 digits'**
  String get validationCardNumberLengthEdit;

  /// No description provided for @validationExpiryLength.
  ///
  /// In en, this message translates to:
  /// **'Must be 4 digits'**
  String get validationExpiryLength;

  /// No description provided for @validationExpiryMonth.
  ///
  /// In en, this message translates to:
  /// **'Month must be 01-12'**
  String get validationExpiryMonth;

  /// No description provided for @validationCvvLength.
  ///
  /// In en, this message translates to:
  /// **'CVV must be 3-4 digits'**
  String get validationCvvLength;

  /// No description provided for @validationEnterIssuer.
  ///
  /// In en, this message translates to:
  /// **'Please enter an issuer'**
  String get validationEnterIssuer;

  /// No description provided for @validationOrgRequired.
  ///
  /// In en, this message translates to:
  /// **'Organization is required.'**
  String get validationOrgRequired;

  /// No description provided for @validationNameValueRequired.
  ///
  /// In en, this message translates to:
  /// **'Name and Value are required.'**
  String get validationNameValueRequired;

  /// Expandable section button in card form
  ///
  /// In en, this message translates to:
  /// **'Additional Info'**
  String get additionalInfo;

  /// No description provided for @frontImage.
  ///
  /// In en, this message translates to:
  /// **'Front Image'**
  String get frontImage;

  /// No description provided for @backImage.
  ///
  /// In en, this message translates to:
  /// **'Back Image'**
  String get backImage;

  /// No description provided for @customFieldsTitle.
  ///
  /// In en, this message translates to:
  /// **'CUSTOM FIELDS'**
  String get customFieldsTitle;

  /// No description provided for @noCustomFields.
  ///
  /// In en, this message translates to:
  /// **'No custom fields added.'**
  String get noCustomFields;

  /// No description provided for @fieldNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Field Name'**
  String get fieldNameLabel;

  /// No description provided for @fieldValueLabel.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get fieldValueLabel;

  /// No description provided for @saveCardButton.
  ///
  /// In en, this message translates to:
  /// **'SAVE CARD'**
  String get saveCardButton;

  /// No description provided for @addCustomField.
  ///
  /// In en, this message translates to:
  /// **'Add Custom Field'**
  String get addCustomField;

  /// No description provided for @selectImage.
  ///
  /// In en, this message translates to:
  /// **'Select Image'**
  String get selectImage;

  /// No description provided for @cardColorLabel.
  ///
  /// In en, this message translates to:
  /// **'CARD COLOR'**
  String get cardColorLabel;

  /// No description provided for @customColorTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom Color'**
  String get customColorTitle;

  /// No description provided for @hexColorCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Hex Color Code'**
  String get hexColorCodeLabel;

  /// No description provided for @applyButton.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get applyButton;

  /// No description provided for @walletDetailSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get walletDetailSecurity;

  /// No description provided for @walletDetailCardImages.
  ///
  /// In en, this message translates to:
  /// **'Card Images'**
  String get walletDetailCardImages;

  /// No description provided for @walletDetailFinancials.
  ///
  /// In en, this message translates to:
  /// **'Financials'**
  String get walletDetailFinancials;

  /// No description provided for @walletDetailBillingTerms.
  ///
  /// In en, this message translates to:
  /// **'Billing & Terms'**
  String get walletDetailBillingTerms;

  /// No description provided for @walletDetailCustomFields.
  ///
  /// In en, this message translates to:
  /// **'Custom Fields'**
  String get walletDetailCustomFields;

  /// No description provided for @walletDetailPrimaryDetails.
  ///
  /// In en, this message translates to:
  /// **'Primary Details'**
  String get walletDetailPrimaryDetails;

  /// Card max credit limit / 最高额度
  ///
  /// In en, this message translates to:
  /// **'Max Limit'**
  String get financialMaxLimit;

  /// Annual spend amount / 年度消费
  ///
  /// In en, this message translates to:
  /// **'Annual Spends'**
  String get financialAnnualSpends;

  /// Estimated cashback / 预估返现
  ///
  /// In en, this message translates to:
  /// **'Estimated Cashback'**
  String get financialEstimatedCashback;

  /// Billing statement date / 账单日
  ///
  /// In en, this message translates to:
  /// **'Bill Generation Date'**
  String get financialBillDate;

  /// Annual fee waiver threshold / 年费免除条件
  ///
  /// In en, this message translates to:
  /// **'Annual Fee Waiver'**
  String get financialAnnualFeeWaiver;

  /// Card type e.g. LTF / 卡片类型
  ///
  /// In en, this message translates to:
  /// **'Card Type'**
  String get financialCardType;

  /// No description provided for @feeWaiverNotApplicable.
  ///
  /// In en, this message translates to:
  /// **'Not Applicable'**
  String get feeWaiverNotApplicable;

  /// No description provided for @feeWaiverWaived.
  ///
  /// In en, this message translates to:
  /// **'Waived Off'**
  String get feeWaiverWaived;

  /// Remaining spend to waive annual fee
  ///
  /// In en, this message translates to:
  /// **'{symbol}{amount} more to waive'**
  String feeWaiverRemaining(String symbol, String amount);

  /// Bill generation date prefix
  ///
  /// In en, this message translates to:
  /// **'Every {date}'**
  String billEveryDate(String date);

  /// Not available value
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get naValue;

  /// Edit field: max limit with currency
  ///
  /// In en, this message translates to:
  /// **'Max Limit ({symbol})'**
  String maxLimitField(String symbol);

  /// Edit field: current spends with currency
  ///
  /// In en, this message translates to:
  /// **'Current Spends ({symbol})'**
  String currentSpendsField(String symbol);

  /// No description provided for @cashbackRateField.
  ///
  /// In en, this message translates to:
  /// **'Cashback Rate (%)'**
  String get cashbackRateField;

  /// No description provided for @billDateField.
  ///
  /// In en, this message translates to:
  /// **'Bill Date (e.g., 15)'**
  String get billDateField;

  /// Edit field: annual fee waiver threshold
  ///
  /// In en, this message translates to:
  /// **'Annual Fee Waiver on Spends of ({symbol})'**
  String annualFeeWaiverField(String symbol);

  /// No description provided for @cardTypeField.
  ///
  /// In en, this message translates to:
  /// **'Card Type (e.g., LTF, Paid)'**
  String get cardTypeField;

  /// Placeholder shown on card preview when name empty
  ///
  /// In en, this message translates to:
  /// **'CARD NAME'**
  String get cardNamePlaceholder;

  /// No description provided for @sharePassTitle.
  ///
  /// In en, this message translates to:
  /// **'Share Pass'**
  String get sharePassTitle;

  /// Tooltip for share pass button on barcode card detail screen
  ///
  /// In en, this message translates to:
  /// **'Share Pass (Encrypted Data)'**
  String get sharePassTooltip;

  /// No description provided for @shareCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Share Card'**
  String get shareCardTitle;

  /// Share screen app bar title
  ///
  /// In en, this message translates to:
  /// **'Share {type}'**
  String sharePassOrCard(String type);

  /// Multi-chunk QR instruction
  ///
  /// In en, this message translates to:
  /// **'SCAN ALL {count} QR CODES'**
  String scanAllQrCodes(int count);

  /// No description provided for @scanToImportLabel.
  ///
  /// In en, this message translates to:
  /// **'SCAN TO IMPORT'**
  String get scanToImportLabel;

  /// No description provided for @tapToSetPassword.
  ///
  /// In en, this message translates to:
  /// **'Tap to Set Password'**
  String get tapToSetPassword;

  /// No description provided for @toGenerateQr.
  ///
  /// In en, this message translates to:
  /// **'to generate QR code'**
  String get toGenerateQr;

  /// No description provided for @passwordEncryptedTransfer.
  ///
  /// In en, this message translates to:
  /// **'Password-Encrypted Transfer'**
  String get passwordEncryptedTransfer;

  /// Multi-chunk share explanation
  ///
  /// In en, this message translates to:
  /// **'Your data is split across {count} QR codes. The receiver must scan all of them and enter the password to decrypt.'**
  String shareMultiChunkBody(int count);

  /// No description provided for @shareSingleBody.
  ///
  /// In en, this message translates to:
  /// **'This QR code contains your data encrypted with a password. The receiver must enter the same password to decrypt and import it.'**
  String get shareSingleBody;

  /// No description provided for @exportPkpass.
  ///
  /// In en, this message translates to:
  /// **'Export as .pkpass'**
  String get exportPkpass;

  /// No description provided for @exportPassDialog.
  ///
  /// In en, this message translates to:
  /// **'Export Pass'**
  String get exportPassDialog;

  /// No description provided for @copyChunkData.
  ///
  /// In en, this message translates to:
  /// **'Copy chunk data'**
  String get copyChunkData;

  /// Subtitle on display barcode screen
  ///
  /// In en, this message translates to:
  /// **'Show this to cashier'**
  String get showToCashier;

  /// No description provided for @cannotDisplayFormat.
  ///
  /// In en, this message translates to:
  /// **'Cannot display in this format'**
  String get cannotDisplayFormat;

  /// No description provided for @invalidBarcodeData.
  ///
  /// In en, this message translates to:
  /// **'Invalid Barcode Data'**
  String get invalidBarcodeData;

  /// No description provided for @invalidBarcode.
  ///
  /// In en, this message translates to:
  /// **'Invalid Barcode'**
  String get invalidBarcode;

  /// No description provided for @barcodeOrgName.
  ///
  /// In en, this message translates to:
  /// **'Name (Organization)'**
  String get barcodeOrgName;

  /// No description provided for @barcodeValueLabel.
  ///
  /// In en, this message translates to:
  /// **'Barcode Value'**
  String get barcodeValueLabel;

  /// No description provided for @barcodeFormatLabel.
  ///
  /// In en, this message translates to:
  /// **'Barcode Format'**
  String get barcodeFormatLabel;

  /// No description provided for @passCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Pass Category'**
  String get passCategoryLabel;

  /// No description provided for @transitTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Transit Type'**
  String get transitTypeLabel;

  /// No description provided for @importFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Import from Gallery'**
  String get importFromGallery;

  /// No description provided for @scanBarcode.
  ///
  /// In en, this message translates to:
  /// **'Scan Barcode'**
  String get scanBarcode;

  /// No description provided for @attachmentsOptional.
  ///
  /// In en, this message translates to:
  /// **'ATTACHMENTS (OPTIONAL)'**
  String get attachmentsOptional;

  /// No description provided for @frontSide.
  ///
  /// In en, this message translates to:
  /// **'Front Side'**
  String get frontSide;

  /// No description provided for @backSide.
  ///
  /// In en, this message translates to:
  /// **'Back Side'**
  String get backSide;

  /// No description provided for @additionalDetails.
  ///
  /// In en, this message translates to:
  /// **'Additional Details'**
  String get additionalDetails;

  /// No description provided for @descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionLabel;

  /// No description provided for @logoTextLabel.
  ///
  /// In en, this message translates to:
  /// **'Logo Text'**
  String get logoTextLabel;

  /// No description provided for @savePassButton.
  ///
  /// In en, this message translates to:
  /// **'SAVE PASS'**
  String get savePassButton;

  /// No description provided for @noBarcodeDetected.
  ///
  /// In en, this message translates to:
  /// **'No barcode or QR code detected in the selected image.'**
  String get noBarcodeDetected;

  /// No description provided for @errorReadingImage.
  ///
  /// In en, this message translates to:
  /// **'Error reading image file.'**
  String get errorReadingImage;

  /// No description provided for @orgPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'ORGANIZATION'**
  String get orgPlaceholder;

  /// No description provided for @fieldSectionPrimary.
  ///
  /// In en, this message translates to:
  /// **'Primary Fields (Main Info)'**
  String get fieldSectionPrimary;

  /// No description provided for @fieldSectionSecondary.
  ///
  /// In en, this message translates to:
  /// **'Secondary Fields (Details)'**
  String get fieldSectionSecondary;

  /// No description provided for @fieldSectionAuxiliary.
  ///
  /// In en, this message translates to:
  /// **'Auxiliary Fields (More)'**
  String get fieldSectionAuxiliary;

  /// No description provided for @fieldSectionHeader.
  ///
  /// In en, this message translates to:
  /// **'Header Fields (Top Right)'**
  String get fieldSectionHeader;

  /// No description provided for @fieldSectionBack.
  ///
  /// In en, this message translates to:
  /// **'Back Details (Fine Print)'**
  String get fieldSectionBack;

  /// No description provided for @passImagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Pass Images'**
  String get passImagesTitle;

  /// No description provided for @identityImagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Identity Images'**
  String get identityImagesTitle;

  /// No description provided for @cardDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Card Details'**
  String get cardDetailsTitle;

  /// No description provided for @cardTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Card Type'**
  String get cardTypeLabel;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// No description provided for @idNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'ID Number'**
  String get idNumberLabel;

  /// Default card type for identity cards
  ///
  /// In en, this message translates to:
  /// **'Identity Card'**
  String get identityCardDefaultType;

  /// No description provided for @idNamePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'NAME'**
  String get idNamePlaceholder;

  /// No description provided for @idValuePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'ID NUMBER'**
  String get idValuePlaceholder;

  /// Uppercase label for document number on identity card display
  ///
  /// In en, this message translates to:
  /// **'DOCUMENT NUMBER'**
  String get idDocumentNumberPlaceholder;

  /// No description provided for @idCardTypePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'IDENTITY CARD'**
  String get idCardTypePlaceholder;

  /// No description provided for @idCardLabelHint.
  ///
  /// In en, this message translates to:
  /// **'Card Label (e.g. Passport, License)'**
  String get idCardLabelHint;

  /// No description provided for @idCardLabelExample.
  ///
  /// In en, this message translates to:
  /// **'e.g. Passport'**
  String get idCardLabelExample;

  /// No description provided for @fullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullNameLabel;

  /// No description provided for @fullNameExample.
  ///
  /// In en, this message translates to:
  /// **'e.g. John Doe'**
  String get fullNameExample;

  /// No description provided for @idValueLabel.
  ///
  /// In en, this message translates to:
  /// **'ID Value / Number'**
  String get idValueLabel;

  /// No description provided for @idValueExample.
  ///
  /// In en, this message translates to:
  /// **'e.g. 123-456-789'**
  String get idValueExample;

  /// No description provided for @saveIdentityCardButton.
  ///
  /// In en, this message translates to:
  /// **'SAVE IDENTITY CARD'**
  String get saveIdentityCardButton;

  /// No description provided for @frontLabel.
  ///
  /// In en, this message translates to:
  /// **'Front'**
  String get frontLabel;

  /// No description provided for @backLabel.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backLabel;

  /// No description provided for @stripLabel.
  ///
  /// In en, this message translates to:
  /// **'Strip'**
  String get stripLabel;

  /// No description provided for @thumbnailLabel.
  ///
  /// In en, this message translates to:
  /// **'Thumbnail'**
  String get thumbnailLabel;

  /// No description provided for @sectionFlightDetails.
  ///
  /// In en, this message translates to:
  /// **'Flight Details'**
  String get sectionFlightDetails;

  /// No description provided for @sectionPassengerInfo.
  ///
  /// In en, this message translates to:
  /// **'Passenger Info'**
  String get sectionPassengerInfo;

  /// No description provided for @sectionTravelInfo.
  ///
  /// In en, this message translates to:
  /// **'Travel Info'**
  String get sectionTravelInfo;

  /// No description provided for @sectionEventDetails.
  ///
  /// In en, this message translates to:
  /// **'Event Details'**
  String get sectionEventDetails;

  /// No description provided for @sectionVenueInfo.
  ///
  /// In en, this message translates to:
  /// **'Venue Info'**
  String get sectionVenueInfo;

  /// No description provided for @sectionTicketDetails.
  ///
  /// In en, this message translates to:
  /// **'Ticket Details'**
  String get sectionTicketDetails;

  /// No description provided for @sectionMemberInfo.
  ///
  /// In en, this message translates to:
  /// **'Member Info'**
  String get sectionMemberInfo;

  /// No description provided for @sectionAccountDetails.
  ///
  /// In en, this message translates to:
  /// **'Account Details'**
  String get sectionAccountDetails;

  /// No description provided for @sectionRewardsInfo.
  ///
  /// In en, this message translates to:
  /// **'Rewards Info'**
  String get sectionRewardsInfo;

  /// No description provided for @sectionCardInfo.
  ///
  /// In en, this message translates to:
  /// **'Card Info'**
  String get sectionCardInfo;

  /// No description provided for @sectionBalancePin.
  ///
  /// In en, this message translates to:
  /// **'Balance & PIN'**
  String get sectionBalancePin;

  /// No description provided for @sectionGiftDetails.
  ///
  /// In en, this message translates to:
  /// **'Gift Details'**
  String get sectionGiftDetails;

  /// No description provided for @sectionOfferDetails.
  ///
  /// In en, this message translates to:
  /// **'Offer Details'**
  String get sectionOfferDetails;

  /// No description provided for @sectionProviderInfo.
  ///
  /// In en, this message translates to:
  /// **'Provider Info'**
  String get sectionProviderInfo;

  /// No description provided for @sectionTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get sectionTerms;

  /// No description provided for @sectionCouponInfo.
  ///
  /// In en, this message translates to:
  /// **'Coupon Info'**
  String get sectionCouponInfo;

  /// No description provided for @sectionRouteDetails.
  ///
  /// In en, this message translates to:
  /// **'Route Details'**
  String get sectionRouteDetails;

  /// No description provided for @sectionTripInfo.
  ///
  /// In en, this message translates to:
  /// **'Trip Info'**
  String get sectionTripInfo;

  /// No description provided for @sectionFareDetails.
  ///
  /// In en, this message translates to:
  /// **'Fare Details'**
  String get sectionFareDetails;

  /// No description provided for @sectionVehicleInfo.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Info'**
  String get sectionVehicleInfo;

  /// No description provided for @sectionKeyDetails.
  ///
  /// In en, this message translates to:
  /// **'Key Details'**
  String get sectionKeyDetails;

  /// No description provided for @sectionAccessInfo.
  ///
  /// In en, this message translates to:
  /// **'Access Info'**
  String get sectionAccessInfo;

  /// No description provided for @sectionStudentInfo.
  ///
  /// In en, this message translates to:
  /// **'Student Info'**
  String get sectionStudentInfo;

  /// No description provided for @sectionUniversityDetails.
  ///
  /// In en, this message translates to:
  /// **'University Details'**
  String get sectionUniversityDetails;

  /// No description provided for @sectionEmployeeInfo.
  ///
  /// In en, this message translates to:
  /// **'Employee Info'**
  String get sectionEmployeeInfo;

  /// No description provided for @sectionCompanyDetails.
  ///
  /// In en, this message translates to:
  /// **'Company Details'**
  String get sectionCompanyDetails;

  /// No description provided for @sectionGuestInfo.
  ///
  /// In en, this message translates to:
  /// **'Guest Info'**
  String get sectionGuestInfo;

  /// No description provided for @sectionHotelDetails.
  ///
  /// In en, this message translates to:
  /// **'Hotel Details'**
  String get sectionHotelDetails;

  /// No description provided for @sectionStayDetails.
  ///
  /// In en, this message translates to:
  /// **'Stay Details'**
  String get sectionStayDetails;

  /// No description provided for @sectionResidentInfo.
  ///
  /// In en, this message translates to:
  /// **'Resident Info'**
  String get sectionResidentInfo;

  /// No description provided for @sectionPropertyDetails.
  ///
  /// In en, this message translates to:
  /// **'Property Details'**
  String get sectionPropertyDetails;

  /// No description provided for @sectionPolicyDetails.
  ///
  /// In en, this message translates to:
  /// **'Policy Details'**
  String get sectionPolicyDetails;

  /// No description provided for @sectionCoverageInfo.
  ///
  /// In en, this message translates to:
  /// **'Coverage Info'**
  String get sectionCoverageInfo;

  /// No description provided for @sectionTestInfo.
  ///
  /// In en, this message translates to:
  /// **'Test Info'**
  String get sectionTestInfo;

  /// No description provided for @sectionResults.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get sectionResults;

  /// No description provided for @sectionLabDetails.
  ///
  /// In en, this message translates to:
  /// **'Lab Details'**
  String get sectionLabDetails;

  /// No description provided for @sectionVaccineInfo.
  ///
  /// In en, this message translates to:
  /// **'Vaccine Info'**
  String get sectionVaccineInfo;

  /// No description provided for @sectionDoseDetails.
  ///
  /// In en, this message translates to:
  /// **'Dose Details'**
  String get sectionDoseDetails;

  /// No description provided for @sectionManufacturerInfo.
  ///
  /// In en, this message translates to:
  /// **'Manufacturer Info'**
  String get sectionManufacturerInfo;

  /// No description provided for @sectionDocumentInfo.
  ///
  /// In en, this message translates to:
  /// **'Document Info'**
  String get sectionDocumentInfo;

  /// No description provided for @sectionIssuerDetails.
  ///
  /// In en, this message translates to:
  /// **'Issuer Details'**
  String get sectionIssuerDetails;

  /// No description provided for @sectionVerification.
  ///
  /// In en, this message translates to:
  /// **'Verification'**
  String get sectionVerification;

  /// No description provided for @sectionOrganization.
  ///
  /// In en, this message translates to:
  /// **'Organization'**
  String get sectionOrganization;

  /// No description provided for @sectionDataDetails.
  ///
  /// In en, this message translates to:
  /// **'Data Details'**
  String get sectionDataDetails;

  /// No description provided for @sectionAdditionalInfo.
  ///
  /// In en, this message translates to:
  /// **'Additional Info'**
  String get sectionAdditionalInfo;

  /// No description provided for @sectionPaymentInfo.
  ///
  /// In en, this message translates to:
  /// **'Payment Info'**
  String get sectionPaymentInfo;

  /// No description provided for @sectionHeaderDetails.
  ///
  /// In en, this message translates to:
  /// **'Header Details'**
  String get sectionHeaderDetails;

  /// No description provided for @sectionCardDetails.
  ///
  /// In en, this message translates to:
  /// **'Card Details'**
  String get sectionCardDetails;

  /// No description provided for @sectionInformation.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get sectionInformation;

  /// No description provided for @fieldFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get fieldFrom;

  /// No description provided for @fieldTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get fieldTo;

  /// No description provided for @fieldPassenger.
  ///
  /// In en, this message translates to:
  /// **'Passenger'**
  String get fieldPassenger;

  /// No description provided for @fieldFlight.
  ///
  /// In en, this message translates to:
  /// **'Flight'**
  String get fieldFlight;

  /// No description provided for @fieldGate.
  ///
  /// In en, this message translates to:
  /// **'Gate'**
  String get fieldGate;

  /// No description provided for @fieldSeat.
  ///
  /// In en, this message translates to:
  /// **'Seat'**
  String get fieldSeat;

  /// No description provided for @fieldDeparture.
  ///
  /// In en, this message translates to:
  /// **'Departure'**
  String get fieldDeparture;

  /// No description provided for @fieldArrival.
  ///
  /// In en, this message translates to:
  /// **'Arrival'**
  String get fieldArrival;

  /// No description provided for @fieldMemberName.
  ///
  /// In en, this message translates to:
  /// **'Member Name'**
  String get fieldMemberName;

  /// No description provided for @fieldBalance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get fieldBalance;

  /// No description provided for @fieldTier.
  ///
  /// In en, this message translates to:
  /// **'Tier'**
  String get fieldTier;

  /// No description provided for @fieldAccountNo.
  ///
  /// In en, this message translates to:
  /// **'Account #'**
  String get fieldAccountNo;

  /// No description provided for @fieldPoints.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get fieldPoints;

  /// No description provided for @fieldCardNumber.
  ///
  /// In en, this message translates to:
  /// **'Card Number'**
  String get fieldCardNumber;

  /// No description provided for @fieldPin.
  ///
  /// In en, this message translates to:
  /// **'PIN'**
  String get fieldPin;

  /// No description provided for @fieldRecipient.
  ///
  /// In en, this message translates to:
  /// **'Recipient'**
  String get fieldRecipient;

  /// No description provided for @fieldEventNo.
  ///
  /// In en, this message translates to:
  /// **'Event #'**
  String get fieldEventNo;

  /// No description provided for @fieldOffer.
  ///
  /// In en, this message translates to:
  /// **'Offer'**
  String get fieldOffer;

  /// No description provided for @fieldProvider.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get fieldProvider;

  /// No description provided for @fieldExpires.
  ///
  /// In en, this message translates to:
  /// **'Expires'**
  String get fieldExpires;

  /// No description provided for @fieldTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get fieldTerms;

  /// No description provided for @fieldCode.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get fieldCode;

  /// No description provided for @fieldEvent.
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get fieldEvent;

  /// No description provided for @fieldVenue.
  ///
  /// In en, this message translates to:
  /// **'Venue'**
  String get fieldVenue;

  /// No description provided for @fieldDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get fieldDate;

  /// No description provided for @fieldSection.
  ///
  /// In en, this message translates to:
  /// **'Section'**
  String get fieldSection;

  /// No description provided for @fieldRow.
  ///
  /// In en, this message translates to:
  /// **'Row'**
  String get fieldRow;

  /// No description provided for @fieldTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get fieldTime;

  /// No description provided for @fieldRoute.
  ///
  /// In en, this message translates to:
  /// **'Route'**
  String get fieldRoute;

  /// No description provided for @fieldFareClass.
  ///
  /// In en, this message translates to:
  /// **'Fare Class'**
  String get fieldFareClass;

  /// Transit fare label (short form)
  ///
  /// In en, this message translates to:
  /// **'Fare'**
  String get fieldFare;

  /// No description provided for @fieldCoach.
  ///
  /// In en, this message translates to:
  /// **'Coach'**
  String get fieldCoach;

  /// No description provided for @fieldPlatform.
  ///
  /// In en, this message translates to:
  /// **'Platform'**
  String get fieldPlatform;

  /// No description provided for @fieldVehicle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get fieldVehicle;

  /// No description provided for @fieldKeyStatus.
  ///
  /// In en, this message translates to:
  /// **'Key Status'**
  String get fieldKeyStatus;

  /// No description provided for @fieldVin.
  ///
  /// In en, this message translates to:
  /// **'VIN'**
  String get fieldVin;

  /// No description provided for @fieldDevice.
  ///
  /// In en, this message translates to:
  /// **'Device'**
  String get fieldDevice;

  /// No description provided for @fieldStudentName.
  ///
  /// In en, this message translates to:
  /// **'Student Name'**
  String get fieldStudentName;

  /// No description provided for @fieldUniversity.
  ///
  /// In en, this message translates to:
  /// **'University'**
  String get fieldUniversity;

  /// No description provided for @fieldIdNo.
  ///
  /// In en, this message translates to:
  /// **'ID #'**
  String get fieldIdNo;

  /// No description provided for @fieldDorm.
  ///
  /// In en, this message translates to:
  /// **'Dorm'**
  String get fieldDorm;

  /// No description provided for @fieldYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get fieldYear;

  /// No description provided for @fieldEmployeeName.
  ///
  /// In en, this message translates to:
  /// **'Employee Name'**
  String get fieldEmployeeName;

  /// No description provided for @fieldCompany.
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get fieldCompany;

  /// No description provided for @fieldDept.
  ///
  /// In en, this message translates to:
  /// **'Dept'**
  String get fieldDept;

  /// No description provided for @fieldAccessLevel.
  ///
  /// In en, this message translates to:
  /// **'Access Level'**
  String get fieldAccessLevel;

  /// No description provided for @fieldGuestName.
  ///
  /// In en, this message translates to:
  /// **'Guest Name'**
  String get fieldGuestName;

  /// No description provided for @fieldHotel.
  ///
  /// In en, this message translates to:
  /// **'Hotel'**
  String get fieldHotel;

  /// No description provided for @fieldRoomNo.
  ///
  /// In en, this message translates to:
  /// **'Room #'**
  String get fieldRoomNo;

  /// No description provided for @fieldCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Check-in'**
  String get fieldCheckIn;

  /// No description provided for @fieldCheckOut.
  ///
  /// In en, this message translates to:
  /// **'Check-out'**
  String get fieldCheckOut;

  /// No description provided for @fieldResidentName.
  ///
  /// In en, this message translates to:
  /// **'Resident Name'**
  String get fieldResidentName;

  /// No description provided for @fieldProperty.
  ///
  /// In en, this message translates to:
  /// **'Property'**
  String get fieldProperty;

  /// No description provided for @fieldUnitNo.
  ///
  /// In en, this message translates to:
  /// **'Unit #'**
  String get fieldUnitNo;

  /// No description provided for @fieldPolicyNo.
  ///
  /// In en, this message translates to:
  /// **'Policy #'**
  String get fieldPolicyNo;

  /// No description provided for @fieldGroupNo.
  ///
  /// In en, this message translates to:
  /// **'Group #'**
  String get fieldGroupNo;

  /// No description provided for @fieldPcn.
  ///
  /// In en, this message translates to:
  /// **'PCN'**
  String get fieldPcn;

  /// No description provided for @fieldTestType.
  ///
  /// In en, this message translates to:
  /// **'Test Type'**
  String get fieldTestType;

  /// No description provided for @fieldResult.
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get fieldResult;

  /// No description provided for @fieldLab.
  ///
  /// In en, this message translates to:
  /// **'Lab'**
  String get fieldLab;

  /// No description provided for @fieldVaccine.
  ///
  /// In en, this message translates to:
  /// **'Vaccine'**
  String get fieldVaccine;

  /// No description provided for @fieldDose.
  ///
  /// In en, this message translates to:
  /// **'Dose'**
  String get fieldDose;

  /// No description provided for @fieldManufacturer.
  ///
  /// In en, this message translates to:
  /// **'Manufacturer'**
  String get fieldManufacturer;

  /// No description provided for @fieldLotNo.
  ///
  /// In en, this message translates to:
  /// **'Lot #'**
  String get fieldLotNo;

  /// No description provided for @fieldDocumentType.
  ///
  /// In en, this message translates to:
  /// **'Document Type'**
  String get fieldDocumentType;

  /// No description provided for @fieldIssuer.
  ///
  /// In en, this message translates to:
  /// **'Issuer'**
  String get fieldIssuer;

  /// No description provided for @fieldExpiry.
  ///
  /// In en, this message translates to:
  /// **'Expiry'**
  String get fieldExpiry;

  /// No description provided for @fieldVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get fieldVerified;

  /// No description provided for @fieldDataType.
  ///
  /// In en, this message translates to:
  /// **'Data Type'**
  String get fieldDataType;

  /// No description provided for @fieldNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get fieldNotes;

  /// No description provided for @fieldCardType.
  ///
  /// In en, this message translates to:
  /// **'Card Type'**
  String get fieldCardType;

  /// No description provided for @fieldMerchant.
  ///
  /// In en, this message translates to:
  /// **'Merchant'**
  String get fieldMerchant;

  /// No description provided for @fieldDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get fieldDetails;

  /// No description provided for @passCategoryRetail.
  ///
  /// In en, this message translates to:
  /// **'Retail'**
  String get passCategoryRetail;

  /// No description provided for @passCategoryTickets.
  ///
  /// In en, this message translates to:
  /// **'Tickets & Transit'**
  String get passCategoryTickets;

  /// No description provided for @passCategoryAccess.
  ///
  /// In en, this message translates to:
  /// **'Access'**
  String get passCategoryAccess;

  /// No description provided for @passCategoryHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get passCategoryHealth;

  /// No description provided for @passCategoryIdentity.
  ///
  /// In en, this message translates to:
  /// **'Identity'**
  String get passCategoryIdentity;

  /// No description provided for @passCategoryGeneric.
  ///
  /// In en, this message translates to:
  /// **'Generic'**
  String get passCategoryGeneric;

  /// No description provided for @passTypeLoyaltyCard.
  ///
  /// In en, this message translates to:
  /// **'Loyalty Card'**
  String get passTypeLoyaltyCard;

  /// No description provided for @passTypeGiftCard.
  ///
  /// In en, this message translates to:
  /// **'Gift Card'**
  String get passTypeGiftCard;

  /// No description provided for @passTypeOffer.
  ///
  /// In en, this message translates to:
  /// **'Offer'**
  String get passTypeOffer;

  /// No description provided for @passTypeInStorePayment.
  ///
  /// In en, this message translates to:
  /// **'In-Store Payment'**
  String get passTypeInStorePayment;

  /// No description provided for @passTypeBoardingPass.
  ///
  /// In en, this message translates to:
  /// **'Boarding Pass'**
  String get passTypeBoardingPass;

  /// No description provided for @passTypeEventTicket.
  ///
  /// In en, this message translates to:
  /// **'Event Ticket'**
  String get passTypeEventTicket;

  /// No description provided for @passTypeTransitPass.
  ///
  /// In en, this message translates to:
  /// **'Transit Pass'**
  String get passTypeTransitPass;

  /// No description provided for @passTypeDigitalCarKey.
  ///
  /// In en, this message translates to:
  /// **'Digital Car Key'**
  String get passTypeDigitalCarKey;

  /// No description provided for @passTypeCampusId.
  ///
  /// In en, this message translates to:
  /// **'Campus ID'**
  String get passTypeCampusId;

  /// No description provided for @passTypeCorporateBadge.
  ///
  /// In en, this message translates to:
  /// **'Corporate Badge'**
  String get passTypeCorporateBadge;

  /// No description provided for @passTypeHotelKey.
  ///
  /// In en, this message translates to:
  /// **'Hotel Key'**
  String get passTypeHotelKey;

  /// No description provided for @passTypeMultiFamilyKey.
  ///
  /// In en, this message translates to:
  /// **'Multi-Family Key'**
  String get passTypeMultiFamilyKey;

  /// No description provided for @passTypeHealthInsurance.
  ///
  /// In en, this message translates to:
  /// **'Health Insurance'**
  String get passTypeHealthInsurance;

  /// No description provided for @passTypeTestRecord.
  ///
  /// In en, this message translates to:
  /// **'Test Record'**
  String get passTypeTestRecord;

  /// No description provided for @passTypeVaccineCard.
  ///
  /// In en, this message translates to:
  /// **'Vaccine Card'**
  String get passTypeVaccineCard;

  /// No description provided for @passTypeDigitalCredential.
  ///
  /// In en, this message translates to:
  /// **'Digital Credential'**
  String get passTypeDigitalCredential;

  /// No description provided for @passTypeGeneric.
  ///
  /// In en, this message translates to:
  /// **'Generic'**
  String get passTypeGeneric;

  /// No description provided for @passTypeGenericPrivate.
  ///
  /// In en, this message translates to:
  /// **'Private Pass'**
  String get passTypeGenericPrivate;

  /// No description provided for @passTypeCoupon.
  ///
  /// In en, this message translates to:
  /// **'Coupon'**
  String get passTypeCoupon;

  /// No description provided for @passTypeStoreCard.
  ///
  /// In en, this message translates to:
  /// **'Store Card'**
  String get passTypeStoreCard;

  /// No description provided for @networkVisa.
  ///
  /// In en, this message translates to:
  /// **'VISA'**
  String get networkVisa;

  /// No description provided for @networkMastercard.
  ///
  /// In en, this message translates to:
  /// **'Mastercard'**
  String get networkMastercard;

  /// No description provided for @networkAmex.
  ///
  /// In en, this message translates to:
  /// **'AMEX'**
  String get networkAmex;

  /// No description provided for @networkDiscover.
  ///
  /// In en, this message translates to:
  /// **'DISCOVER'**
  String get networkDiscover;

  /// No description provided for @networkRupay.
  ///
  /// In en, this message translates to:
  /// **'RUPAY'**
  String get networkRupay;

  /// No description provided for @networkUnionpay.
  ///
  /// In en, this message translates to:
  /// **'银联'**
  String get networkUnionpay;

  /// No description provided for @networkJcb.
  ///
  /// In en, this message translates to:
  /// **'JCB'**
  String get networkJcb;

  /// Snackbar when organization name is empty on save
  ///
  /// In en, this message translates to:
  /// **'Organization is required.'**
  String get organizationRequired;

  /// Snackbar after scanning a barcode from image
  ///
  /// In en, this message translates to:
  /// **'Scanned {format}: {text}'**
  String scannedFormat(String format, String text);

  /// Generic word for barcode, used as fallback format name
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get barcodeWord;

  /// Field label for organization
  ///
  /// In en, this message translates to:
  /// **'Organization'**
  String get fieldOrganization;

  /// Field label for terms and conditions
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get fieldTermsConditions;

  /// Field label for contact
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get fieldContact;

  /// Label for the organization name field in barcode pass entry form
  ///
  /// In en, this message translates to:
  /// **'Name (Organization)'**
  String get nameOrganizationLabel;

  /// Title of the native save-file dialog when creating a backup
  ///
  /// In en, this message translates to:
  /// **'Save Backup File'**
  String get saveBackupDialogTitle;

  /// Placeholder shown in card details when CVV is not stored
  ///
  /// In en, this message translates to:
  /// **'No CVV'**
  String get noCvvPlaceholder;

  /// Label for card category dropdown (credit/debit)
  ///
  /// In en, this message translates to:
  /// **'Card Category'**
  String get cardCategoryLabel;

  /// Credit card category option
  ///
  /// In en, this message translates to:
  /// **'Credit'**
  String get cardCategoryCredit;

  /// Debit card category option
  ///
  /// In en, this message translates to:
  /// **'Debit'**
  String get cardCategoryDebit;

  /// No card category selected
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get cardCategoryNone;

  /// Label for custom tags section
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tagsLabel;

  /// Hint text for tag input field
  ///
  /// In en, this message translates to:
  /// **'Type tag and press enter'**
  String get tagsAddHint;

  /// Shown when no tags are added
  ///
  /// In en, this message translates to:
  /// **'No tags'**
  String get tagsEmpty;

  /// Filter dropdown label for card network
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get filterNetwork;

  /// Filter dropdown label for card issuer/bank
  ///
  /// In en, this message translates to:
  /// **'Issuer'**
  String get filterIssuer;

  /// Filter dropdown label for card type (credit/debit)
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get filterType;

  /// Default network dropdown value: All card networks
  ///
  /// In en, this message translates to:
  /// **'All Networks'**
  String get filterAllNetworks;

  /// Default issuer dropdown value: All card issuers
  ///
  /// In en, this message translates to:
  /// **'All Issuers'**
  String get filterAllIssuers;

  /// Default card-type dropdown value: All card types
  ///
  /// In en, this message translates to:
  /// **'All Card Types'**
  String get filterAllCardTypes;

  /// Archive action button label
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get actionArchive;

  /// Unarchive action button label
  ///
  /// In en, this message translates to:
  /// **'Unarchive'**
  String get actionUnarchive;

  /// Permanently delete action button label
  ///
  /// In en, this message translates to:
  /// **'Delete Permanently'**
  String get actionDeletePermanently;

  /// Label for archived cards view toggle
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get archivedView;

  /// Label for active cards view toggle
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeView;

  /// Snackbar message after archiving a card
  ///
  /// In en, this message translates to:
  /// **'Card archived'**
  String get cardArchived;

  /// Snackbar message after unarchiving a card
  ///
  /// In en, this message translates to:
  /// **'Card unarchived'**
  String get cardUnarchived;

  /// No description provided for @archiveConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Archive \"{name}\"? You can restore it from the archive view.'**
  String archiveConfirmBody(String name);

  /// No description provided for @deletePermanentlyConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete \"{name}\"? This cannot be undone.'**
  String deletePermanentlyConfirmBody(String name);

  /// Empty state message for archived cards view
  ///
  /// In en, this message translates to:
  /// **'No archived cards'**
  String get noArchivedCards;

  /// Fallback issuer name when card has no issuer set
  ///
  /// In en, this message translates to:
  /// **'Unknown Issuer'**
  String get unknownIssuer;

  /// AppBar title for scanning card front
  ///
  /// In en, this message translates to:
  /// **'Scan Front of Card'**
  String get scannerTitleFront;

  /// AppBar title for scanning card back
  ///
  /// In en, this message translates to:
  /// **'Scan Back of Card'**
  String get scannerTitleBack;

  /// AppBar title for number-only scanning
  ///
  /// In en, this message translates to:
  /// **'Scan Card Number'**
  String get scannerTitleNumberOnly;

  /// No description provided for @scannerHintFront.
  ///
  /// In en, this message translates to:
  /// **'Align card inside the green frame and tap the shutter when focused'**
  String get scannerHintFront;

  /// No description provided for @scannerHintBack.
  ///
  /// In en, this message translates to:
  /// **'Align the back of the card (signature strip + CVV) inside the frame'**
  String get scannerHintBack;

  /// No description provided for @scannerHintNumberOnly.
  ///
  /// In en, this message translates to:
  /// **'Frame the card number in the rectangle, then tap to scan'**
  String get scannerHintNumberOnly;

  /// No description provided for @scannerShutterHint.
  ///
  /// In en, this message translates to:
  /// **'Manual shutter — tap only when the image is sharp'**
  String get scannerShutterHint;

  /// No description provided for @scannerNextBack.
  ///
  /// In en, this message translates to:
  /// **'Scan Back Side'**
  String get scannerNextBack;

  /// No description provided for @scannerFinish.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get scannerFinish;

  /// No description provided for @scannerRetake.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get scannerRetake;

  /// No description provided for @scannerSkipBack.
  ///
  /// In en, this message translates to:
  /// **'Skip Back'**
  String get scannerSkipBack;

  /// No description provided for @scannerCropOk.
  ///
  /// In en, this message translates to:
  /// **'✓ Card edges detected and auto-cropped'**
  String get scannerCropOk;

  /// No description provided for @scannerCropFallback.
  ///
  /// In en, this message translates to:
  /// **'Could not detect edges; keeping original photo'**
  String get scannerCropFallback;

  /// No description provided for @scannerProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing…'**
  String get scannerProcessing;

  /// No description provided for @scannerOcrInProgress.
  ///
  /// In en, this message translates to:
  /// **'Recognising text…'**
  String get scannerOcrInProgress;

  /// No description provided for @scannerOcrFailed.
  ///
  /// In en, this message translates to:
  /// **'OCR failed'**
  String get scannerOcrFailed;

  /// No description provided for @scannerCaptureFailed.
  ///
  /// In en, this message translates to:
  /// **'Capture failed'**
  String get scannerCaptureFailed;

  /// No description provided for @scannerCameraInitializing.
  ///
  /// In en, this message translates to:
  /// **'Starting camera…'**
  String get scannerCameraInitializing;

  /// No description provided for @scannerDetecting.
  ///
  /// In en, this message translates to:
  /// **'Detecting…'**
  String get scannerDetecting;

  /// No description provided for @scannerCameraPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Camera permission denied — enable it in Settings'**
  String get scannerCameraPermissionDenied;

  /// No description provided for @scannerNoCameraFound.
  ///
  /// In en, this message translates to:
  /// **'No camera available on this device'**
  String get scannerNoCameraFound;

  /// No description provided for @scannerUnknownError.
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get scannerUnknownError;

  /// No description provided for @scannerCameraInitFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to start camera'**
  String get scannerCameraInitFailed;

  /// Tooltip for scan entry-point button in Add card screen
  ///
  /// In en, this message translates to:
  /// **'Scan to add card'**
  String get addCardActionScan;

  /// No description provided for @scanCardNumberTooltip.
  ///
  /// In en, this message translates to:
  /// **'Scan card number'**
  String get scanCardNumberTooltip;

  /// No description provided for @splashAuthRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Authentication Required'**
  String get splashAuthRequiredTitle;

  /// No description provided for @splashAuthRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'You must authenticate to use the wallet app. Please try again or exit.'**
  String get splashAuthRequiredMessage;

  /// No description provided for @splashAuthRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get splashAuthRetry;

  /// No description provided for @splashAuthExit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get splashAuthExit;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
