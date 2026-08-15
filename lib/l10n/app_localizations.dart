import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

/// A class which supports localization in this app.
///
/// To include this class in MaterialApp, add:
///
/// ```dart
/// MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
/// )
/// ```
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along
  /// with [GlobalMaterialLocalizations.delegate],
  /// [GlobalWidgetsLocalizations.delegate], and
  /// [GlobalCupertinoLocalizations.delegate].
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  String get appTitle;

  /// No description provided for @splashTagline.
  String get splashTagline;

  /// No description provided for @splashAuthReason.
  String get splashAuthReason;

  /// No description provided for @navPayments.
  String get navPayments;

  /// No description provided for @navPasses.
  String get navPasses;

  /// No description provided for @navIdentity.
  String get navIdentity;

  /// No description provided for @scanToImport.
  String get scanToImport;

  /// No description provided for @emptyPayments.
  String get emptyPayments;

  /// No description provided for @emptyPasses.
  String get emptyPasses;

  /// No description provided for @emptyIdentities.
  String get emptyIdentities;

  /// No description provided for @searchCards.
  String get searchCards;

  /// No description provided for @searchPasses.
  String get searchPasses;

  /// No description provided for @searchIdentities.
  String get searchIdentities;

  /// No description provided for @noCardsFound.
  String get noCardsFound;

  /// No description provided for @noPassesFound.
  String get noPassesFound;

  /// No description provided for @noIdentitiesFound.
  String get noIdentitiesFound;

  /// No description provided for @filterAll.
  String get filterAll;

  /// No description provided for @filterLoyalty.
  String get filterLoyalty;

  /// No description provided for @filterGiftCards.
  String get filterGiftCards;

  /// No description provided for @filterOffers.
  String get filterOffers;

  /// No description provided for @filterBoarding.
  String get filterBoarding;

  /// No description provided for @filterEvents.
  String get filterEvents;

  /// No description provided for @filterTransit.
  String get filterTransit;

  /// No description provided for @filterHealth.
  String get filterHealth;

  /// No description provided for @filterCampus.
  String get filterCampus;

  /// No description provided for @filterCorporate.
  String get filterCorporate;

  /// No description provided for @filterHotel.
  String get filterHotel;

  /// No description provided for @filterOther.
  String get filterOther;

  /// No description provided for @actionEdit.
  String get actionEdit;

  /// No description provided for @actionCopy.
  String get actionCopy;

  /// No description provided for @actionDelete.
  String get actionDelete;

  /// No description provided for @cardNumberCopied.
  String get cardNumberCopied;

  /// No description provided for @passDataCopied.
  String get passDataCopied;

  /// No description provided for @idValueCopied.
  String get idValueCopied;

  /// No description provided for @cardNumberCopiedBang.
  String get cardNumberCopiedBang;

  /// No description provided for @cvvCopied.
  String get cvvCopied;

  /// No description provided for @idNumberCopied.
  String get idNumberCopied;

  /// No description provided for @copiedToClipboard.
  String get copiedToClipboard;

  /// No description provided for @qrDataCopied.
  String get qrDataCopied;

  /// No description provided for @deleteWalletTitle.
  String get deleteWalletTitle;

  /// No description provided for @cardDeleted.
  String get cardDeleted;

  /// No description provided for @deletePassTitle.
  String get deletePassTitle;

  /// No description provided for @deleteIdentityTitle.
  String get deleteIdentityTitle;

  /// No description provided for @deleteConfirmBody.
  String deleteConfirmBody(Object name);

  /// No description provided for @passDeleted.
  String get passDeleted;

  /// No description provided for @identityDeleted.
  String get identityDeleted;

  /// No description provided for @importSharedTitle.
  String importSharedTitle(Object type);

  /// No description provided for @importSharedBody.
  String importSharedBody(Object name);

  /// No description provided for @invalidShareCode.
  String get invalidShareCode;

  /// No description provided for @invalidShareFormat.
  String get invalidShareFormat;

  /// No description provided for @invalidPassData.
  String get invalidPassData;

  /// No description provided for @invalidCardData.
  String get invalidCardData;

  /// No description provided for @invalidIdentityData.
  String get invalidIdentityData;

  /// No description provided for @importFailedCorrupted.
  String get importFailedCorrupted;

  /// No description provided for @invalidChunkFormat.
  String get invalidChunkFormat;

  /// No description provided for @invalidChunkIndex.
  String get invalidChunkIndex;

  /// No description provided for @chunkMismatch.
  String get chunkMismatch;

  /// No description provided for @failedParseChunk.
  String get failedParseChunk;

  /// No description provided for @decryptFailed.
  String get decryptFailed;

  /// No description provided for @importFailedWrongPassword.
  String get importFailedWrongPassword;

  /// No description provided for @scannedChunk.
  String scannedChunk(Object current, Object total);

  /// No description provided for @enterTransferPasswordTitle.
  String get enterTransferPasswordTitle;

  /// No description provided for @enterTransferPasswordBody.
  String get enterTransferPasswordBody;

  /// No description provided for @passImportedSuccess.
  String get passImportedSuccess;

  /// No description provided for @paymentCardImportedSuccess.
  String get paymentCardImportedSuccess;

  /// No description provided for @identityCardImportedSuccess.
  String get identityCardImportedSuccess;

  /// No description provided for @typeLabelPass.
  String get typeLabelPass;

  /// No description provided for @typeLabelPaymentCard.
  String get typeLabelPaymentCard;

  /// No description provided for @typeLabelIdentityCard.
  String get typeLabelIdentityCard;

  /// No description provided for @typeLabelCard.
  String get typeLabelCard;

  /// No description provided for @saveButton.
  String get saveButton;

  /// No description provided for @cancelButton.
  String get cancelButton;

  /// No description provided for @importButton.
  String get importButton;

  /// No description provided for @deleteButton.
  String get deleteButton;

  /// No description provided for @closeButton.
  String get closeButton;

  /// No description provided for @enableButton.
  String get enableButton;

  /// No description provided for @saveButtonText.
  String get saveButtonText;

  /// No description provided for @importPassTitle.
  String get importPassTitle;

  /// No description provided for @importPassBody.
  String importPassBody(Object name);

  /// No description provided for @passImportedSuccessShort.
  String get passImportedSuccessShort;

  /// No description provided for @pkpassParseFailed.
  String get pkpassParseFailed;

  /// No description provided for @passImportFailed.
  String get passImportFailed;

  /// No description provided for @importPkpass.
  String get importPkpass;

  /// No description provided for @settingsTitle.
  String get settingsTitle;

  /// No description provided for @sectionStartupLayout.
  String get sectionStartupLayout;

  /// No description provided for @sectionAppearance.
  String get sectionAppearance;

  /// No description provided for @sectionDataManagement.
  String get sectionDataManagement;

  /// No description provided for @sectionAbout.
  String get sectionAbout;

  /// No description provided for @authScreenTitle.
  String get authScreenTitle;

  /// No description provided for @authScreenSubtitle.
  String get authScreenSubtitle;

  /// No description provided for @authenticateAction.
  String get authenticateAction;

  /// No description provided for @currencyTitle.
  String get currencyTitle;

  /// No description provided for @chooseCurrency.
  String get chooseCurrency;

  /// No description provided for @defaultScreenTitle.
  String get defaultScreenTitle;

  /// No description provided for @defaultScreenSubtitle.
  String get defaultScreenSubtitle;

  /// No description provided for @chooseDefaultScreen.
  String get chooseDefaultScreen;

  /// No description provided for @paymentsOnlyTitle.
  String get paymentsOnlyTitle;

  /// No description provided for @paymentsOnlySubtitle.
  String get paymentsOnlySubtitle;

  /// No description provided for @appThemeTitle.
  String get appThemeTitle;

  /// No description provided for @appThemeSubtitle.
  String get appThemeSubtitle;

  /// No description provided for @chooseTheme.
  String get chooseTheme;

  /// No description provided for @themeLight.
  String get themeLight;

  /// No description provided for @themeDark.
  String get themeDark;

  /// No description provided for @themeSystem.
  String get themeSystem;

  /// No description provided for @useSystemFontTitle.
  String get useSystemFontTitle;

  /// No description provided for @useSystemFontSubtitle.
  String get useSystemFontSubtitle;

  /// No description provided for @autoBackupTitle.
  String get autoBackupTitle;

  /// No description provided for @autoBackupSubtitleOff.
  String get autoBackupSubtitleOff;

  /// No description provided for @autoBackupSubtitleNoPath.
  String get autoBackupSubtitleNoPath;

  /// No description provided for @autoBackupSubtitleActive.
  String autoBackupSubtitleActive(Object path);

  /// No description provided for @backupLocationTitle.
  String get backupLocationTitle;

  /// No description provided for @changeBackupPasswordTitle.
  String get changeBackupPasswordTitle;

  /// No description provided for @changeBackupPasswordSubtitle.
  String get changeBackupPasswordSubtitle;

  /// No description provided for @enableAutoBackupTitle.
  String get enableAutoBackupTitle;

  /// No description provided for @enableAutoBackupBody.
  String get enableAutoBackupBody;

  /// No description provided for @selectDirectoryHint.
  String get selectDirectoryHint;

  /// No description provided for @backupPasswordLabel.
  String get backupPasswordLabel;

  /// No description provided for @enterPasswordHint.
  String get enterPasswordHint;

  /// No description provided for @enterNewPasswordHint.
  String get enterNewPasswordHint;

  /// No description provided for @createBackupTitle.
  String get createBackupTitle;

  /// No description provided for @createBackupSubtitle.
  String get createBackupSubtitle;

  /// No description provided for @createBackupDialogBody.
  String get createBackupDialogBody;

  /// No description provided for @createBackupButton.
  String get createBackupButton;

  /// No description provided for @restoreBackupTitle.
  String get restoreBackupTitle;

  /// No description provided for @restoreBackupSubtitle.
  String get restoreBackupSubtitle;

  /// No description provided for @restoreBackupDialogBody.
  String get restoreBackupDialogBody;

  /// No description provided for @restoreButton.
  String get restoreButton;

  /// No description provided for @deleteAllDataTitle.
  String get deleteAllDataTitle;

  /// No description provided for @deleteAllDataSubtitle.
  String get deleteAllDataSubtitle;

  /// No description provided for @deleteAllDataBody.
  String get deleteAllDataBody;

  /// No description provided for @deleteEverythingButton.
  String get deleteEverythingButton;

  /// No description provided for @allDataDeleted.
  String get allDataDeleted;

  /// No description provided for @deleteFailedRetry.
  String get deleteFailedRetry;

  /// No description provided for @sectionDangerZone.
  String get sectionDangerZone;

  /// No description provided for @dangerZoneSubtitle.
  String get dangerZoneSubtitle;

  /// No description provided for @dangerZonePinAuthTitle.
  String get dangerZonePinAuthTitle;

  /// No description provided for @dangerZonePinAuthSubtitle.
  String get dangerZonePinAuthSubtitle;

  /// No description provided for @pinAuthUnavailable.
  String get pinAuthUnavailable;

  /// No description provided for @trademarkNoticeTitle.
  String get trademarkNoticeTitle;

  /// No description provided for @trademarkNoticeSubtitle.
  String get trademarkNoticeSubtitle;

  /// No description provided for @trademarkDialogTitle.
  String get trademarkDialogTitle;

  /// No description provided for @trademarkDialogBody.
  String get trademarkDialogBody;

  /// No description provided for @reportErrorTitle.
  String get reportErrorTitle;

  /// No description provided for @reportErrorSubtitle.
  String get reportErrorSubtitle;

  /// No description provided for @buyMeACoffee.
  String get buyMeACoffee;

  /// No description provided for @passwordLabel.
  String get passwordLabel;

  /// No description provided for @passwordTooShort.
  String passwordTooShort(Object min);

  /// No description provided for @setTransferPasswordTitle.
  String get setTransferPasswordTitle;

  /// No description provided for @setTransferPasswordBody.
  String get setTransferPasswordBody;

  /// No description provided for @generateQrButton.
  String get generateQrButton;

  /// No description provided for @pathNotSet.
  String get pathNotSet;

  /// No description provided for @cardNameLabel.
  String get cardNameLabel;

  /// No description provided for @cardNumberLabel.
  String get cardNumberLabel;

  /// No description provided for @expiryLabel.
  String get expiryLabel;

  /// No description provided for @cvvLabel.
  String get cvvLabel;

  /// No description provided for @cardIssuerLabel.
  String get cardIssuerLabel;

  /// No description provided for @cardIssuerLabelEdit.
  String get cardIssuerLabelEdit;

  /// No description provided for @cardNetworkLabel.
  String get cardNetworkLabel;

  /// No description provided for @validationEnterName.
  String get validationEnterName;

  /// No description provided for @validationEnterCardNumber.
  String get validationEnterCardNumber;

  /// No description provided for @validationCardNumberLength.
  String get validationCardNumberLength;

  /// No description provided for @validationCardNumberLengthEdit.
  String get validationCardNumberLengthEdit;

  /// No description provided for @validationExpiryLength.
  String get validationExpiryLength;

  /// No description provided for @validationExpiryMonth.
  String get validationExpiryMonth;

  /// No description provided for @validationCvvLength.
  String get validationCvvLength;

  /// No description provided for @validationEnterIssuer.
  String get validationEnterIssuer;

  /// No description provided for @validationOrgRequired.
  String get validationOrgRequired;

  /// No description provided for @validationNameValueRequired.
  String get validationNameValueRequired;

  /// No description provided for @additionalInfo.
  String get additionalInfo;

  /// No description provided for @frontImage.
  String get frontImage;

  /// No description provided for @backImage.
  String get backImage;

  /// No description provided for @customFieldsTitle.
  String get customFieldsTitle;

  /// No description provided for @noCustomFields.
  String get noCustomFields;

  /// No description provided for @fieldNameLabel.
  String get fieldNameLabel;

  /// No description provided for @fieldValueLabel.
  String get fieldValueLabel;

  /// No description provided for @saveCardButton.
  String get saveCardButton;

  /// No description provided for @addCustomField.
  String get addCustomField;

  /// No description provided for @selectImage.
  String get selectImage;

  /// No description provided for @cardColorLabel.
  String get cardColorLabel;

  /// No description provided for @customColorTitle.
  String get customColorTitle;

  /// No description provided for @hexColorCodeLabel.
  String get hexColorCodeLabel;

  /// No description provided for @applyButton.
  String get applyButton;

  /// No description provided for @walletDetailSecurity.
  String get walletDetailSecurity;

  /// No description provided for @walletDetailCardImages.
  String get walletDetailCardImages;

  /// No description provided for @walletDetailFinancials.
  String get walletDetailFinancials;

  /// No description provided for @walletDetailBillingTerms.
  String get walletDetailBillingTerms;

  /// No description provided for @walletDetailCustomFields.
  String get walletDetailCustomFields;

  /// No description provided for @walletDetailPrimaryDetails.
  String get walletDetailPrimaryDetails;

  /// No description provided for @financialMaxLimit.
  String get financialMaxLimit;

  /// No description provided for @financialAnnualSpends.
  String get financialAnnualSpends;

  /// No description provided for @financialEstimatedCashback.
  String get financialEstimatedCashback;

  /// No description provided for @financialBillDate.
  String get financialBillDate;

  /// No description provided for @financialAnnualFeeWaiver.
  String get financialAnnualFeeWaiver;

  /// No description provided for @financialCardType.
  String get financialCardType;

  /// No description provided for @feeWaiverNotApplicable.
  String get feeWaiverNotApplicable;

  /// No description provided for @feeWaiverWaived.
  String get feeWaiverWaived;

  /// No description provided for @feeWaiverRemaining.
  String feeWaiverRemaining(Object symbol, Object amount);

  /// No description provided for @billEveryDate.
  String billEveryDate(Object date);

  /// No description provided for @naValue.
  String get naValue;

  /// No description provided for @maxLimitField.
  String maxLimitField(Object symbol);

  /// No description provided for @currentSpendsField.
  String currentSpendsField(Object symbol);

  /// No description provided for @cashbackRateField.
  String get cashbackRateField;

  /// No description provided for @billDateField.
  String get billDateField;

  /// No description provided for @annualFeeWaiverField.
  String annualFeeWaiverField(Object symbol);

  /// No description provided for @cardTypeField.
  String get cardTypeField;

  /// No description provided for @cardNamePlaceholder.
  String get cardNamePlaceholder;

  /// No description provided for @sharePassTitle.
  String get sharePassTitle;

  /// No description provided for @sharePassTooltip.
  String get sharePassTooltip;

  /// No description provided for @shareCardTitle.
  String get shareCardTitle;

  /// No description provided for @sharePassOrCard.
  String sharePassOrCard(Object type);

  /// No description provided for @scanAllQrCodes.
  String scanAllQrCodes(Object count);

  /// No description provided for @scanToImportLabel.
  String get scanToImportLabel;

  /// No description provided for @tapToSetPassword.
  String get tapToSetPassword;

  /// No description provided for @toGenerateQr.
  String get toGenerateQr;

  /// No description provided for @passwordEncryptedTransfer.
  String get passwordEncryptedTransfer;

  /// No description provided for @shareMultiChunkBody.
  String shareMultiChunkBody(Object count);

  /// No description provided for @shareSingleBody.
  String get shareSingleBody;

  /// No description provided for @exportPkpass.
  String get exportPkpass;

  /// No description provided for @exportPassDialog.
  String get exportPassDialog;

  /// No description provided for @copyChunkData.
  String get copyChunkData;

  /// No description provided for @showToCashier.
  String get showToCashier;

  /// No description provided for @cannotDisplayFormat.
  String get cannotDisplayFormat;

  /// No description provided for @invalidBarcodeData.
  String get invalidBarcodeData;

  /// No description provided for @invalidBarcode.
  String get invalidBarcode;

  /// No description provided for @barcodeOrgName.
  String get barcodeOrgName;

  /// No description provided for @barcodeValueLabel.
  String get barcodeValueLabel;

  /// No description provided for @barcodeFormatLabel.
  String get barcodeFormatLabel;

  /// No description provided for @passCategoryLabel.
  String get passCategoryLabel;

  /// No description provided for @transitTypeLabel.
  String get transitTypeLabel;

  /// No description provided for @importFromGallery.
  String get importFromGallery;

  /// No description provided for @scanBarcode.
  String get scanBarcode;

  /// No description provided for @attachmentsOptional.
  String get attachmentsOptional;

  /// No description provided for @frontSide.
  String get frontSide;

  /// No description provided for @backSide.
  String get backSide;

  /// No description provided for @additionalDetails.
  String get additionalDetails;

  /// No description provided for @descriptionLabel.
  String get descriptionLabel;

  /// No description provided for @logoTextLabel.
  String get logoTextLabel;

  /// No description provided for @savePassButton.
  String get savePassButton;

  /// No description provided for @noBarcodeDetected.
  String get noBarcodeDetected;

  /// No description provided for @errorReadingImage.
  String get errorReadingImage;

  /// No description provided for @orgPlaceholder.
  String get orgPlaceholder;

  /// No description provided for @fieldSectionPrimary.
  String get fieldSectionPrimary;

  /// No description provided for @fieldSectionSecondary.
  String get fieldSectionSecondary;

  /// No description provided for @fieldSectionAuxiliary.
  String get fieldSectionAuxiliary;

  /// No description provided for @fieldSectionHeader.
  String get fieldSectionHeader;

  /// No description provided for @fieldSectionBack.
  String get fieldSectionBack;

  /// No description provided for @passImagesTitle.
  String get passImagesTitle;

  /// No description provided for @identityImagesTitle.
  String get identityImagesTitle;

  /// No description provided for @cardDetailsTitle.
  String get cardDetailsTitle;

  /// No description provided for @cardTypeLabel.
  String get cardTypeLabel;

  /// No description provided for @nameLabel.
  String get nameLabel;

  /// No description provided for @idNumberLabel.
  String get idNumberLabel;

  /// No description provided for @identityCardDefaultType.
  String get identityCardDefaultType;

  /// No description provided for @idNamePlaceholder.
  String get idNamePlaceholder;

  /// No description provided for @idValuePlaceholder.
  String get idValuePlaceholder;

  /// No description provided for @idDocumentNumberPlaceholder.
  String get idDocumentNumberPlaceholder;

  /// No description provided for @idCardTypePlaceholder.
  String get idCardTypePlaceholder;

  /// No description provided for @idCardLabelHint.
  String get idCardLabelHint;

  /// No description provided for @idCardLabelExample.
  String get idCardLabelExample;

  /// No description provided for @fullNameLabel.
  String get fullNameLabel;

  /// No description provided for @fullNameExample.
  String get fullNameExample;

  /// No description provided for @idValueLabel.
  String get idValueLabel;

  /// No description provided for @idValueExample.
  String get idValueExample;

  /// No description provided for @saveIdentityCardButton.
  String get saveIdentityCardButton;

  /// No description provided for @frontLabel.
  String get frontLabel;

  /// No description provided for @backLabel.
  String get backLabel;

  /// No description provided for @stripLabel.
  String get stripLabel;

  /// No description provided for @thumbnailLabel.
  String get thumbnailLabel;

  /// No description provided for @sectionFlightDetails.
  String get sectionFlightDetails;

  /// No description provided for @sectionPassengerInfo.
  String get sectionPassengerInfo;

  /// No description provided for @sectionTravelInfo.
  String get sectionTravelInfo;

  /// No description provided for @sectionEventDetails.
  String get sectionEventDetails;

  /// No description provided for @sectionVenueInfo.
  String get sectionVenueInfo;

  /// No description provided for @sectionTicketDetails.
  String get sectionTicketDetails;

  /// No description provided for @sectionMemberInfo.
  String get sectionMemberInfo;

  /// No description provided for @sectionAccountDetails.
  String get sectionAccountDetails;

  /// No description provided for @sectionRewardsInfo.
  String get sectionRewardsInfo;

  /// No description provided for @sectionCardInfo.
  String get sectionCardInfo;

  /// No description provided for @sectionBalancePin.
  String get sectionBalancePin;

  /// No description provided for @sectionGiftDetails.
  String get sectionGiftDetails;

  /// No description provided for @sectionOfferDetails.
  String get sectionOfferDetails;

  /// No description provided for @sectionProviderInfo.
  String get sectionProviderInfo;

  /// No description provided for @sectionTerms.
  String get sectionTerms;

  /// No description provided for @sectionCouponInfo.
  String get sectionCouponInfo;

  /// No description provided for @sectionRouteDetails.
  String get sectionRouteDetails;

  /// No description provided for @sectionTripInfo.
  String get sectionTripInfo;

  /// No description provided for @sectionFareDetails.
  String get sectionFareDetails;

  /// No description provided for @sectionVehicleInfo.
  String get sectionVehicleInfo;

  /// No description provided for @sectionKeyDetails.
  String get sectionKeyDetails;

  /// No description provided for @sectionAccessInfo.
  String get sectionAccessInfo;

  /// No description provided for @sectionStudentInfo.
  String get sectionStudentInfo;

  /// No description provided for @sectionUniversityDetails.
  String get sectionUniversityDetails;

  /// No description provided for @sectionEmployeeInfo.
  String get sectionEmployeeInfo;

  /// No description provided for @sectionCompanyDetails.
  String get sectionCompanyDetails;

  /// No description provided for @sectionGuestInfo.
  String get sectionGuestInfo;

  /// No description provided for @sectionHotelDetails.
  String get sectionHotelDetails;

  /// No description provided for @sectionStayDetails.
  String get sectionStayDetails;

  /// No description provided for @sectionResidentInfo.
  String get sectionResidentInfo;

  /// No description provided for @sectionPropertyDetails.
  String get sectionPropertyDetails;

  /// No description provided for @sectionPolicyDetails.
  String get sectionPolicyDetails;

  /// No description provided for @sectionCoverageInfo.
  String get sectionCoverageInfo;

  /// No description provided for @sectionTestInfo.
  String get sectionTestInfo;

  /// No description provided for @sectionResults.
  String get sectionResults;

  /// No description provided for @sectionLabDetails.
  String get sectionLabDetails;

  /// No description provided for @sectionVaccineInfo.
  String get sectionVaccineInfo;

  /// No description provided for @sectionDoseDetails.
  String get sectionDoseDetails;

  /// No description provided for @sectionManufacturerInfo.
  String get sectionManufacturerInfo;

  /// No description provided for @sectionDocumentInfo.
  String get sectionDocumentInfo;

  /// No description provided for @sectionIssuerDetails.
  String get sectionIssuerDetails;

  /// No description provided for @sectionVerification.
  String get sectionVerification;

  /// No description provided for @sectionOrganization.
  String get sectionOrganization;

  /// No description provided for @sectionDataDetails.
  String get sectionDataDetails;

  /// No description provided for @sectionAdditionalInfo.
  String get sectionAdditionalInfo;

  /// No description provided for @sectionPaymentInfo.
  String get sectionPaymentInfo;

  /// No description provided for @sectionHeaderDetails.
  String get sectionHeaderDetails;

  /// No description provided for @sectionCardDetails.
  String get sectionCardDetails;

  /// No description provided for @sectionInformation.
  String get sectionInformation;

  /// No description provided for @fieldFrom.
  String get fieldFrom;

  /// No description provided for @fieldTo.
  String get fieldTo;

  /// No description provided for @fieldPassenger.
  String get fieldPassenger;

  /// No description provided for @fieldFlight.
  String get fieldFlight;

  /// No description provided for @fieldGate.
  String get fieldGate;

  /// No description provided for @fieldSeat.
  String get fieldSeat;

  /// No description provided for @fieldDeparture.
  String get fieldDeparture;

  /// No description provided for @fieldArrival.
  String get fieldArrival;

  /// No description provided for @fieldMemberName.
  String get fieldMemberName;

  /// No description provided for @fieldBalance.
  String get fieldBalance;

  /// No description provided for @fieldTier.
  String get fieldTier;

  /// No description provided for @fieldAccountNo.
  String get fieldAccountNo;

  /// No description provided for @fieldPoints.
  String get fieldPoints;

  /// No description provided for @fieldCardNumber.
  String get fieldCardNumber;

  /// No description provided for @fieldPin.
  String get fieldPin;

  /// No description provided for @fieldRecipient.
  String get fieldRecipient;

  /// No description provided for @fieldEventNo.
  String get fieldEventNo;

  /// No description provided for @fieldOffer.
  String get fieldOffer;

  /// No description provided for @fieldProvider.
  String get fieldProvider;

  /// No description provided for @fieldExpires.
  String get fieldExpires;

  /// No description provided for @fieldTerms.
  String get fieldTerms;

  /// No description provided for @fieldCode.
  String get fieldCode;

  /// No description provided for @fieldEvent.
  String get fieldEvent;

  /// No description provided for @fieldVenue.
  String get fieldVenue;

  /// No description provided for @fieldDate.
  String get fieldDate;

  /// No description provided for @fieldSection.
  String get fieldSection;

  /// No description provided for @fieldRow.
  String get fieldRow;

  /// No description provided for @fieldTime.
  String get fieldTime;

  /// No description provided for @fieldRoute.
  String get fieldRoute;

  /// No description provided for @fieldFareClass.
  String get fieldFareClass;

  /// No description provided for @fieldFare.
  String get fieldFare;

  /// No description provided for @fieldCoach.
  String get fieldCoach;

  /// No description provided for @fieldPlatform.
  String get fieldPlatform;

  /// No description provided for @fieldVehicle.
  String get fieldVehicle;

  /// No description provided for @fieldKeyStatus.
  String get fieldKeyStatus;

  /// No description provided for @fieldVin.
  String get fieldVin;

  /// No description provided for @fieldDevice.
  String get fieldDevice;

  /// No description provided for @fieldStudentName.
  String get fieldStudentName;

  /// No description provided for @fieldUniversity.
  String get fieldUniversity;

  /// No description provided for @fieldIdNo.
  String get fieldIdNo;

  /// No description provided for @fieldDorm.
  String get fieldDorm;

  /// No description provided for @fieldYear.
  String get fieldYear;

  /// No description provided for @fieldEmployeeName.
  String get fieldEmployeeName;

  /// No description provided for @fieldCompany.
  String get fieldCompany;

  /// No description provided for @fieldDept.
  String get fieldDept;

  /// No description provided for @fieldAccessLevel.
  String get fieldAccessLevel;

  /// No description provided for @fieldGuestName.
  String get fieldGuestName;

  /// No description provided for @fieldHotel.
  String get fieldHotel;

  /// No description provided for @fieldRoomNo.
  String get fieldRoomNo;

  /// No description provided for @fieldCheckIn.
  String get fieldCheckIn;

  /// No description provided for @fieldCheckOut.
  String get fieldCheckOut;

  /// No description provided for @fieldResidentName.
  String get fieldResidentName;

  /// No description provided for @fieldProperty.
  String get fieldProperty;

  /// No description provided for @fieldUnitNo.
  String get fieldUnitNo;

  /// No description provided for @fieldPolicyNo.
  String get fieldPolicyNo;

  /// No description provided for @fieldGroupNo.
  String get fieldGroupNo;

  /// No description provided for @fieldPcn.
  String get fieldPcn;

  /// No description provided for @fieldTestType.
  String get fieldTestType;

  /// No description provided for @fieldResult.
  String get fieldResult;

  /// No description provided for @fieldLab.
  String get fieldLab;

  /// No description provided for @fieldVaccine.
  String get fieldVaccine;

  /// No description provided for @fieldDose.
  String get fieldDose;

  /// No description provided for @fieldManufacturer.
  String get fieldManufacturer;

  /// No description provided for @fieldLotNo.
  String get fieldLotNo;

  /// No description provided for @fieldDocumentType.
  String get fieldDocumentType;

  /// No description provided for @fieldIssuer.
  String get fieldIssuer;

  /// No description provided for @fieldExpiry.
  String get fieldExpiry;

  /// No description provided for @fieldVerified.
  String get fieldVerified;

  /// No description provided for @fieldDataType.
  String get fieldDataType;

  /// No description provided for @fieldNotes.
  String get fieldNotes;

  /// No description provided for @fieldCardType.
  String get fieldCardType;

  /// No description provided for @fieldMerchant.
  String get fieldMerchant;

  /// No description provided for @fieldDetails.
  String get fieldDetails;

  /// No description provided for @passCategoryRetail.
  String get passCategoryRetail;

  /// No description provided for @passCategoryTickets.
  String get passCategoryTickets;

  /// No description provided for @passCategoryAccess.
  String get passCategoryAccess;

  /// No description provided for @passCategoryHealth.
  String get passCategoryHealth;

  /// No description provided for @passCategoryIdentity.
  String get passCategoryIdentity;

  /// No description provided for @passCategoryGeneric.
  String get passCategoryGeneric;

  /// No description provided for @passTypeLoyaltyCard.
  String get passTypeLoyaltyCard;

  /// No description provided for @passTypeGiftCard.
  String get passTypeGiftCard;

  /// No description provided for @passTypeOffer.
  String get passTypeOffer;

  /// No description provided for @passTypeInStorePayment.
  String get passTypeInStorePayment;

  /// No description provided for @passTypeBoardingPass.
  String get passTypeBoardingPass;

  /// No description provided for @passTypeEventTicket.
  String get passTypeEventTicket;

  /// No description provided for @passTypeTransitPass.
  String get passTypeTransitPass;

  /// No description provided for @passTypeDigitalCarKey.
  String get passTypeDigitalCarKey;

  /// No description provided for @passTypeCampusId.
  String get passTypeCampusId;

  /// No description provided for @passTypeCorporateBadge.
  String get passTypeCorporateBadge;

  /// No description provided for @passTypeHotelKey.
  String get passTypeHotelKey;

  /// No description provided for @passTypeMultiFamilyKey.
  String get passTypeMultiFamilyKey;

  /// No description provided for @passTypeHealthInsurance.
  String get passTypeHealthInsurance;

  /// No description provided for @passTypeTestRecord.
  String get passTypeTestRecord;

  /// No description provided for @passTypeVaccineCard.
  String get passTypeVaccineCard;

  /// No description provided for @passTypeDigitalCredential.
  String get passTypeDigitalCredential;

  /// No description provided for @passTypeGeneric.
  String get passTypeGeneric;

  /// No description provided for @passTypeGenericPrivate.
  String get passTypeGenericPrivate;

  /// No description provided for @passTypeCoupon.
  String get passTypeCoupon;

  /// No description provided for @passTypeStoreCard.
  String get passTypeStoreCard;

  /// No description provided for @networkVisa.
  String get networkVisa;

  /// No description provided for @networkMastercard.
  String get networkMastercard;

  /// No description provided for @networkAmex.
  String get networkAmex;

  /// No description provided for @networkDiscover.
  String get networkDiscover;

  /// No description provided for @networkRupay.
  String get networkRupay;

  /// No description provided for @networkUnionpay.
  String get networkUnionpay;

  /// No description provided for @networkJcb.
  String get networkJcb;

  /// No description provided for @organizationRequired.
  String get organizationRequired;

  /// No description provided for @scannedFormat.
  String scannedFormat(Object format, Object text);

  /// No description provided for @barcodeWord.
  String get barcodeWord;

  /// No description provided for @fieldOrganization.
  String get fieldOrganization;

  /// No description provided for @fieldTermsConditions.
  String get fieldTermsConditions;

  /// No description provided for @fieldContact.
  String get fieldContact;

  /// No description provided for @nameOrganizationLabel.
  String get nameOrganizationLabel;

  /// No description provided for @saveBackupDialogTitle.
  String get saveBackupDialogTitle;

  /// No description provided for @noCvvPlaceholder.
  String get noCvvPlaceholder;

  /// No description provided for @cardCategoryLabel.
  String get cardCategoryLabel;

  /// No description provided for @cardCategoryCredit.
  String get cardCategoryCredit;

  /// No description provided for @cardCategoryDebit.
  String get cardCategoryDebit;

  /// No description provided for @cardCategoryNone.
  String get cardCategoryNone;

  /// No description provided for @tagsLabel.
  String get tagsLabel;

  /// No description provided for @tagsAddHint.
  String get tagsAddHint;

  /// No description provided for @tagsEmpty.
  String get tagsEmpty;

  /// No description provided for @filterNetwork.
  String get filterNetwork;

  /// No description provided for @filterIssuer.
  String get filterIssuer;

  /// No description provided for @filterType.
  String get filterType;

  /// No description provided for @filterAllNetworks.
  String get filterAllNetworks;

  /// No description provided for @filterAllIssuers.
  String get filterAllIssuers;

  /// No description provided for @filterAllCardTypes.
  String get filterAllCardTypes;

  /// No description provided for @actionArchive.
  String get actionArchive;

  /// No description provided for @actionUnarchive.
  String get actionUnarchive;

  /// No description provided for @actionDeletePermanently.
  String get actionDeletePermanently;

  /// No description provided for @archivedView.
  String get archivedView;

  /// No description provided for @activeView.
  String get activeView;

  /// No description provided for @cardArchived.
  String get cardArchived;

  /// No description provided for @cardUnarchived.
  String get cardUnarchived;

  /// No description provided for @archiveConfirmBody.
  String archiveConfirmBody(Object name);

  /// No description provided for @deletePermanentlyConfirmBody.
  String deletePermanentlyConfirmBody(Object name);

  /// No description provided for @noArchivedCards.
  String get noArchivedCards;

  /// No description provided for @unknownIssuer.
  String get unknownIssuer;

  /// No description provided for @scannerTitleFront.
  String get scannerTitleFront;

  /// No description provided for @scannerTitleBack.
  String get scannerTitleBack;

  /// No description provided for @scannerTitleNumberOnly.
  String get scannerTitleNumberOnly;

  /// No description provided for @scannerHintFront.
  String get scannerHintFront;

  /// No description provided for @scannerHintBack.
  String get scannerHintBack;

  /// No description provided for @scannerHintNumberOnly.
  String get scannerHintNumberOnly;

  /// No description provided for @scannerShutterHint.
  String get scannerShutterHint;

  /// No description provided for @scannerNextBack.
  String get scannerNextBack;

  /// No description provided for @scannerFinish.
  String get scannerFinish;

  /// No description provided for @scannerRetake.
  String get scannerRetake;

  /// No description provided for @scannerSkipBack.
  String get scannerSkipBack;

  /// No description provided for @scannerCropOk.
  String get scannerCropOk;

  /// No description provided for @scannerCropFallback.
  String get scannerCropFallback;

  /// No description provided for @scannerProcessing.
  String get scannerProcessing;

  /// No description provided for @scannerOcrInProgress.
  String get scannerOcrInProgress;

  /// No description provided for @scannerOcrFailed.
  String get scannerOcrFailed;

  /// No description provided for @scannerCaptureFailed.
  String get scannerCaptureFailed;

  /// No description provided for @scannerCameraInitializing.
  String get scannerCameraInitializing;

  /// No description provided for @scannerCameraPermissionDenied.
  String get scannerCameraPermissionDenied;

  /// No description provided for @scannerNoCameraFound.
  String get scannerNoCameraFound;

  /// No description provided for @scannerUnknownError.
  String get scannerUnknownError;

  /// No description provided for @scannerCameraInitFailed.
  String get scannerCameraInitFailed;

  /// No description provided for @addCardActionScan.
  String get addCardActionScan;

  /// No description provided for @scanCardNumberTooltip.
  String get scanCardNumberTooltip;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return Future<AppLocalizations>.value(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  switch (locale.languageCode) {
    case 'zh':
      return _AppLocalizationsZh();
    case 'en':
    default:
      return _AppLocalizationsEn();
  }
}

/// ENGLISH LOCALIZATIONS
class _AppLocalizationsEn extends AppLocalizations {
  _AppLocalizationsEn() : super('en');

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
      "No credit or debit cards yet.\\nTap the '+' to add one.";
  @override
  String get emptyPasses => "No passes added yet.\\nTap the '+' to add one.";
  @override
  String get emptyIdentities =>
      "No identity cards yet.\\nTap the '+' to add one.";
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
  String deleteConfirmBody(Object name) =>
      'Are you sure you want to delete \"$name\"? This action cannot be undone.';
  @override
  String get passDeleted => 'Pass Deleted!';
  @override
  String get identityDeleted => 'Identity Card Deleted!';
  @override
  String importSharedTitle(Object type) => 'Import Shared $type';
  @override
  String importSharedBody(Object name) => 'Do you want to import \"$name\"?';
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
  String get decryptFailed => 'Decryption failed. Wrong password or corrupted data.';
  @override
  String get importFailedWrongPassword =>
      'Failed to import. Wrong password or corrupted data.';
  @override
  String scannedChunk(Object current, Object total) =>
      'Scanned chunk $current of $total';
  @override
  String get enterTransferPasswordTitle => 'Enter Transfer Password';
  @override
  String get enterTransferPasswordBody =>
      'Enter the password that was used to encrypt this transfer.';
  @override
  String get passImportedSuccess => 'Pass imported successfully!';
  @override
  String get paymentCardImportedSuccess => 'Payment card imported successfully!';
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
  String importPassBody(Object name) => 'Do you want to import \"$name\"?';
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
  String autoBackupSubtitleActive(Object path) => 'Active - $path';
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
  String get deleteAllDataSubtitle => 'Permanently erase all data from this device';
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
      'The Visa, Mastercard, UnionPay, JCB, RuPay, American Express, and Discover logos displayed in this application are registered trademarks of their respective owners.\\n\\nThese logos are used solely for identifying the card network. This usage constitutes nominative fair use.\\n\\nThis application is not affiliated with, endorsed by, or sponsored by any of these companies.';
  @override
  String get reportErrorTitle => 'Report Error';
  @override
  String get reportErrorSubtitle => 'Found a bug? Let us know on GitHub.';
  @override
  String get buyMeACoffee => 'Buy Me a Coffee';
  @override
  String get passwordLabel => 'Password';
  @override
  String passwordTooShort(Object min) =>
      'Password must be at least $min characters';
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
  String feeWaiverRemaining(Object symbol, Object amount) =>
      '$symbol$amount more to waive';
  @override
  String billEveryDate(Object date) => 'Every $date';
  @override
  String get naValue => 'N/A';
  @override
  String maxLimitField(Object symbol) => 'Max Limit ($symbol)';
  @override
  String currentSpendsField(Object symbol) => 'Current Spends ($symbol)';
  @override
  String get cashbackRateField => 'Cashback Rate (%)';
  @override
  String get billDateField => 'Bill Date (e.g., 15)';
  @override
  String annualFeeWaiverField(Object symbol) =>
      'Annual Fee Waiver on Spends of ($symbol)';
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
  String sharePassOrCard(Object type) => 'Share $type';
  @override
  String scanAllQrCodes(Object count) => 'SCAN ALL $count QR CODES';
  @override
  String get scanToImportLabel => 'SCAN TO IMPORT';
  @override
  String get tapToSetPassword => 'Tap to Set Password';
  @override
  String get toGenerateQr => 'to generate QR code';
  @override
  String get passwordEncryptedTransfer => 'Password-Encrypted Transfer';
  @override
  String shareMultiChunkBody(Object count) =>
      'Your data is split across $count QR codes. The receiver must scan all of them and enter the password to decrypt.';
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
  String scannedFormat(Object format, Object text) =>
      'Scanned $format: $text';
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
  String archiveConfirmBody(Object name) =>
      'Archive \"$name\"? You can restore it from the archive view.';
  @override
  String deletePermanentlyConfirmBody(Object name) =>
      'Permanently delete \"$name\"? This cannot be undone.';
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

/// CHINESE LOCALIZATIONS
class _AppLocalizationsZh extends AppLocalizations {
  _AppLocalizationsZh() : super('zh');

  @override
  String get appTitle => '钱包';
  @override
  String get splashTagline => '安全 • 简洁 • 智能';
  @override
  String get splashAuthReason => '请验证身份以打开钱包';
  @override
  String get navPayments => '支付';
  @override
  String get navPasses => '票卡';
  @override
  String get navIdentity => '证件';
  @override
  String get scanToImport => '扫码导入';
  @override
  String get emptyPayments => '还没有银行卡。\\n点击"+"添加一张。';
  @override
  String get emptyPasses => '还没有票卡。\\n点击"+"添加一张。';
  @override
  String get emptyIdentities => '还没有证件。\\n点击"+"添加一张。';
  @override
  String get searchCards => '搜索卡片...';
  @override
  String get searchPasses => '搜索票卡...';
  @override
  String get searchIdentities => '搜索证件...';
  @override
  String get noCardsFound => '未找到卡片。';
  @override
  String get noPassesFound => '未找到票卡。';
  @override
  String get noIdentitiesFound => '未找到证件。';
  @override
  String get filterAll => '全部';
  @override
  String get filterLoyalty => '会员卡';
  @override
  String get filterGiftCards => '礼品卡';
  @override
  String get filterOffers => '优惠';
  @override
  String get filterBoarding => '登机牌';
  @override
  String get filterEvents => '活动';
  @override
  String get filterTransit => '交通';
  @override
  String get filterHealth => '医疗';
  @override
  String get filterCampus => '校园';
  @override
  String get filterCorporate => '企业';
  @override
  String get filterHotel => '酒店';
  @override
  String get filterOther => '其他';
  @override
  String get actionEdit => '编辑';
  @override
  String get actionCopy => '复制';
  @override
  String get actionDelete => '删除';
  @override
  String get cardNumberCopied => '卡号已复制！';
  @override
  String get passDataCopied => '票卡数据已复制！';
  @override
  String get idValueCopied => '证件号码已复制！';
  @override
  String get cardNumberCopiedBang => '卡号已复制！';
  @override
  String get cvvCopied => 'CVV 已复制！';
  @override
  String get idNumberCopied => '证件号码已复制！';
  @override
  String get copiedToClipboard => '已复制到剪贴板';
  @override
  String get qrDataCopied => '二维码数据已复制到剪贴板';
  @override
  String get deleteWalletTitle => '删除银行卡？';
  @override
  String get cardDeleted => '银行卡已删除！';
  @override
  String get deletePassTitle => '删除票卡？';
  @override
  String get deleteIdentityTitle => '删除证件？';
  @override
  String deleteConfirmBody(Object name) => '确定要删除"$name"吗？此操作无法撤销。';
  @override
  String get passDeleted => '票卡已删除！';
  @override
  String get identityDeleted => '证件已删除！';
  @override
  String importSharedTitle(Object type) => '导入共享的$type';
  @override
  String importSharedBody(Object name) => '是否要导入"$name"？';
  @override
  String get invalidShareCode => '共享码无效或已损坏。';
  @override
  String get invalidShareFormat => '共享码格式无效。';
  @override
  String get invalidPassData => '票卡数据无效。';
  @override
  String get invalidCardData => '卡片数据无效。';
  @override
  String get invalidIdentityData => '证件数据无效。';
  @override
  String get importFailedCorrupted => '导入失败。共享码可能已损坏。';
  @override
  String get invalidChunkFormat => '分片格式无效。';
  @override
  String get invalidChunkIndex => '分片索引无效。';
  @override
  String get chunkMismatch => '分片不匹配，请重新扫描。';
  @override
  String get failedParseChunk => '解析分片失败。';
  @override
  String get decryptFailed => '解密失败。密码错误或数据已损坏。';
  @override
  String get importFailedWrongPassword => '导入失败。密码错误或数据已损坏。';
  @override
  String scannedChunk(Object current, Object total) =>
      '已扫描第 $current / $total 个分片';
  @override
  String get enterTransferPasswordTitle => '输入传输密码';
  @override
  String get enterTransferPasswordBody => '请输入用于加密此次传输的密码。';
  @override
  String get passImportedSuccess => '票卡导入成功！';
  @override
  String get paymentCardImportedSuccess => '银行卡导入成功！';
  @override
  String get identityCardImportedSuccess => '证件导入成功！';
  @override
  String get typeLabelPass => '票卡';
  @override
  String get typeLabelPaymentCard => '银行卡';
  @override
  String get typeLabelIdentityCard => '证件';
  @override
  String get typeLabelCard => '卡片';
  @override
  String get saveButton => '保存';
  @override
  String get cancelButton => '取消';
  @override
  String get importButton => '导入';
  @override
  String get deleteButton => '删除';
  @override
  String get closeButton => '关闭';
  @override
  String get enableButton => '启用';
  @override
  String get saveButtonText => '保存';
  @override
  String get importPassTitle => '导入票卡';
  @override
  String importPassBody(Object name) => '是否要导入"$name"？';
  @override
  String get passImportedSuccessShort => '票卡导入成功！';
  @override
  String get pkpassParseFailed => '解析 .pkpass 文件失败。';
  @override
  String get passImportFailed => '导入票卡失败，请重试。';
  @override
  String get importPkpass => '导入 pkpass';
  @override
  String get settingsTitle => '设置';
  @override
  String get sectionStartupLayout => '启动与布局';
  @override
  String get sectionAppearance => '外观';
  @override
  String get sectionDataManagement => '数据管理';
  @override
  String get sectionAbout => '关于';
  @override
  String get authScreenTitle => '身份验证界面';
  @override
  String get authScreenSubtitle => '应用启动时需要生物识别';
  @override
  String get authenticateAction => '请验证身份以执行此操作';
  @override
  String get currencyTitle => '货币';
  @override
  String get chooseCurrency => '选择货币';
  @override
  String get defaultScreenTitle => '默认界面';
  @override
  String get defaultScreenSubtitle => '默认界面';
  @override
  String get chooseDefaultScreen => '默认界面';
  @override
  String get paymentsOnlyTitle => '仅支付模式';
  @override
  String get paymentsOnlySubtitle => '隐藏票卡和证件界面';
  @override
  String get appThemeTitle => '应用主题';
  @override
  String get appThemeSubtitle => '应用主题';
  @override
  String get chooseTheme => '选择主题';
  @override
  String get themeLight => '浅色';
  @override
  String get themeDark => '深色';
  @override
  String get themeSystem => '跟随系统';
  @override
  String get useSystemFontTitle => '使用系统字体';
  @override
  String get useSystemFontSubtitle => '使用默认系统字体';
  @override
  String get autoBackupTitle => '自动备份';
  @override
  String get autoBackupSubtitleOff => '数据变更时自动备份';
  @override
  String get autoBackupSubtitleNoPath => '请配置备份位置';
  @override
  String autoBackupSubtitleActive(Object path) => '已启用 - $path';
  @override
  String get backupLocationTitle => '备份位置';
  @override
  String get changeBackupPasswordTitle => '修改备份密码';
  @override
  String get changeBackupPasswordSubtitle => '更新自动备份的加密密码';
  @override
  String get enableAutoBackupTitle => '启用自动备份';
  @override
  String get enableAutoBackupBody =>
      '每当您添加或删除卡片、票卡或证件时，都会自动创建备份。';
  @override
  String get selectDirectoryHint => '选择目录...';
  @override
  String get backupPasswordLabel => '备份密码';
  @override
  String get enterPasswordHint => '输入密码';
  @override
  String get enterNewPasswordHint => '输入新密码（至少 8 位）';
  @override
  String get createBackupTitle => '创建备份';
  @override
  String get createBackupSubtitle => '保存数据的加密副本';
  @override
  String get createBackupDialogBody => '请输入一个强密码以加密备份文件。';
  @override
  String get createBackupButton => '创建备份';
  @override
  String get restoreBackupTitle => '从备份恢复';
  @override
  String get restoreBackupSubtitle => '用备份文件替换当前数据';
  @override
  String get restoreBackupDialogBody => '请输入备份文件的密码。此操作将替换所有当前数据。';
  @override
  String get restoreButton => '恢复';
  @override
  String get deleteAllDataTitle => '删除所有数据？';
  @override
  String get deleteAllDataSubtitle => '永久擦除本设备上的所有数据';
  @override
  String get deleteAllDataBody => '此操作将永久删除所有银行卡、票卡和图片。';
  @override
  String get deleteEverythingButton => '全部删除';
  @override
  String get allDataDeleted => '所有数据已删除。';
  @override
  String get deleteFailedRetry => '删除失败，请重试。';
  @override
  String get sectionDangerZone => '危险操作';
  @override
  String get dangerZoneSubtitle => '不可逆的危险操作';
  @override
  String get dangerZonePinAuthTitle => '验证 PIN';
  @override
  String get dangerZonePinAuthSubtitle =>
      '请输入设备 PIN 码以删除所有数据，不可使用指纹。';
  @override
  String get pinAuthUnavailable =>
      '本设备不支持 PIN 验证。请先在系统设置中设置屏幕锁定（PIN/密码）后再操作。';
  @override
  String get trademarkNoticeTitle => '商标声明';
  @override
  String get trademarkNoticeSubtitle => '卡组织徽标均为其各自所有者的商标。';
  @override
  String get trademarkDialogTitle => '商标合理使用声明';
  @override
  String get trademarkDialogBody =>
      '本应用中展示的 Visa、Mastercard、银联、JCB、RuPay、American Express 和 Discover 徽标均为其各自所有者的注册商标。\\n\\n这些徽标仅用于标识卡组织，属于指示性合理使用。\\n\\n本应用与上述任何公司均无关联，也未获得其认可或赞助。';
  @override
  String get reportErrorTitle => '报告问题';
  @override
  String get reportErrorSubtitle => '发现问题？请在 GitHub 上告知我们。';
  @override
  String get buyMeACoffee => '请我喝杯咖啡';
  @override
  String get passwordLabel => '密码';
  @override
  String passwordTooShort(Object min) => '密码长度至少为 $min 位';
  @override
  String get setTransferPasswordTitle => '设置传输密码';
  @override
  String get setTransferPasswordBody => '请输入一个密码以加密传输内容。接收方需要此密码才能导入。';
  @override
  String get generateQrButton => '生成二维码';
  @override
  String get pathNotSet => '未设置';
  @override
  String get cardNameLabel => '卡片名称';
  @override
  String get cardNumberLabel => '卡号';
  @override
  String get expiryLabel => '有效期（月月年年）';
  @override
  String get cvvLabel => 'CVV 安全码';
  @override
  String get cardIssuerLabel => '发卡行（例如：工商银行）';
  @override
  String get cardIssuerLabelEdit => '发卡行（例如：工商银行）';
  @override
  String get cardNetworkLabel => '卡组织';
  @override
  String get validationEnterName => '请输入名称';
  @override
  String get validationEnterCardNumber => '请输入卡号';
  @override
  String get validationCardNumberLength => '卡号必须为 15-19 位';
  @override
  String get validationCardNumberLengthEdit => '卡号必须为 13-19 位';
  @override
  String get validationExpiryLength => '必须为 4 位';
  @override
  String get validationExpiryMonth => '月份必须在 01-12 之间';
  @override
  String get validationCvvLength => 'CVV 必须为 3-4 位';
  @override
  String get validationEnterIssuer => '请输入发卡行';
  @override
  String get validationOrgRequired => '机构名称为必填项。';
  @override
  String get validationNameValueRequired => '名称和号码为必填项。';
  @override
  String get additionalInfo => '更多信息';
  @override
  String get frontImage => '正面图片';
  @override
  String get backImage => '背面图片';
  @override
  String get customFieldsTitle => '自定义字段';
  @override
  String get noCustomFields => '暂无自定义字段。';
  @override
  String get fieldNameLabel => '字段名称';
  @override
  String get fieldValueLabel => '字段值';
  @override
  String get saveCardButton => '保存卡片';
  @override
  String get addCustomField => '添加自定义字段';
  @override
  String get selectImage => '选择图片';
  @override
  String get cardColorLabel => '卡片颜色';
  @override
  String get customColorTitle => '自定义颜色';
  @override
  String get hexColorCodeLabel => '十六进制颜色代码';
  @override
  String get applyButton => '应用';
  @override
  String get walletDetailSecurity => '安全信息';
  @override
  String get walletDetailCardImages => '卡片图片';
  @override
  String get walletDetailFinancials => '账务信息';
  @override
  String get walletDetailBillingTerms => '账单与条款';
  @override
  String get walletDetailCustomFields => '自定义字段';
  @override
  String get walletDetailPrimaryDetails => '基本信息';
  @override
  String get financialMaxLimit => '最高额度';
  @override
  String get financialAnnualSpends => '年度消费';
  @override
  String get financialEstimatedCashback => '预估返现';
  @override
  String get financialBillDate => '账单日';
  @override
  String get financialAnnualFeeWaiver => '年费免除条件';
  @override
  String get financialCardType => '卡片类型';
  @override
  String get feeWaiverNotApplicable => '不适用';
  @override
  String get feeWaiverWaived => '已免除';
  @override
  String feeWaiverRemaining(Object symbol, Object amount) =>
      '再消费 $symbol$amount 即可免除';
  @override
  String billEveryDate(Object date) => '每月 $date 日';
  @override
  String get naValue => '无';
  @override
  String maxLimitField(Object symbol) => '最高额度（$symbol）';
  @override
  String currentSpendsField(Object symbol) => '当前消费（$symbol）';
  @override
  String get cashbackRateField => '返现比例（%）';
  @override
  String get billDateField => '账单日（例如：15）';
  @override
  String annualFeeWaiverField(Object symbol) => '消费满以下金额免除年费（$symbol）';
  @override
  String get cardTypeField => '卡片类型（例如：免年费、付费）';
  @override
  String get cardNamePlaceholder => '卡片名称';
  @override
  String get sharePassTitle => '分享票卡';
  @override
  String get sharePassTooltip => '分享票卡（加密数据）';
  @override
  String get shareCardTitle => '分享卡片';
  @override
  String sharePassOrCard(Object type) => '分享$type';
  @override
  String scanAllQrCodes(Object count) => '请扫描全部 $count 个二维码';
  @override
  String get scanToImportLabel => '扫码导入';
  @override
  String get tapToSetPassword => '点击设置密码';
  @override
  String get toGenerateQr => '以生成二维码';
  @override
  String get passwordEncryptedTransfer => '密码加密传输';
  @override
  String shareMultiChunkBody(Object count) =>
      '您的数据已拆分为 $count 个二维码。接收方需扫描全部二维码并输入密码才能解密。';
  @override
  String get shareSingleBody => '此二维码包含已用密码加密的数据。接收方需输入相同密码才能解密并导入。';
  @override
  String get exportPkpass => '导出为 .pkpass';
  @override
  String get exportPassDialog => '导出票卡';
  @override
  String get copyChunkData => '复制分片数据';
  @override
  String get showToCashier => '请向收银员出示';
  @override
  String get cannotDisplayFormat => '无法以此格式显示';
  @override
  String get invalidBarcodeData => '条码数据无效';
  @override
  String get invalidBarcode => '条码无效';
  @override
  String get barcodeOrgName => '名称（机构）';
  @override
  String get barcodeValueLabel => '条码内容';
  @override
  String get barcodeFormatLabel => '条码格式';
  @override
  String get passCategoryLabel => '票卡类别';
  @override
  String get transitTypeLabel => '交通类型';
  @override
  String get importFromGallery => '从相册导入';
  @override
  String get scanBarcode => '扫描条码';
  @override
  String get attachmentsOptional => '附件（可选）';
  @override
  String get frontSide => '正面';
  @override
  String get backSide => '背面';
  @override
  String get additionalDetails => '更多详情';
  @override
  String get descriptionLabel => '描述';
  @override
  String get logoTextLabel => '徽标文字';
  @override
  String get savePassButton => '保存票卡';
  @override
  String get noBarcodeDetected => '所选图片中未检测到条码或二维码。';
  @override
  String get errorReadingImage => '读取图片文件出错。';
  @override
  String get orgPlaceholder => '机构名称';
  @override
  String get fieldSectionPrimary => '主要字段（核心信息）';
  @override
  String get fieldSectionSecondary => '次要字段（详情）';
  @override
  String get fieldSectionAuxiliary => '辅助字段（更多）';
  @override
  String get fieldSectionHeader => '页眉字段（右上角）';
  @override
  String get fieldSectionBack => '背面详情（附则）';
  @override
  String get passImagesTitle => '票卡图片';
  @override
  String get identityImagesTitle => '证件图片';
  @override
  String get cardDetailsTitle => '卡片详情';
  @override
  String get cardTypeLabel => '证件类型';
  @override
  String get nameLabel => '姓名';
  @override
  String get idNumberLabel => '证件号码';
  @override
  String get identityCardDefaultType => '证件';
  @override
  String get idNamePlaceholder => '姓名';
  @override
  String get idValuePlaceholder => '证件号码';
  @override
  String get idDocumentNumberPlaceholder => '证件号码';
  @override
  String get idCardTypePlaceholder => '证件';
  @override
  String get idCardLabelHint => '证件标签（例如：护照、驾驶证）';
  @override
  String get idCardLabelExample => '例如：护照';
  @override
  String get fullNameLabel => '姓名';
  @override
  String get fullNameExample => '例如：张三';
  @override
  String get idValueLabel => '证件号码';
  @override
  String get idValueExample => '例如：123-456-789';
  @override
  String get saveIdentityCardButton => '保存证件';
  @override
  String get frontLabel => '正面';
  @override
  String get backLabel => '背面';
  @override
  String get stripLabel => '条带';
  @override
  String get thumbnailLabel => '缩略图';
  @override
  String get sectionFlightDetails => '航班信息';
  @override
  String get sectionPassengerInfo => '乘客信息';
  @override
  String get sectionTravelInfo => '出行信息';
  @override
  String get sectionEventDetails => '活动信息';
  @override
  String get sectionVenueInfo => '场馆信息';
  @override
  String get sectionTicketDetails => '票务信息';
  @override
  String get sectionMemberInfo => '会员信息';
  @override
  String get sectionAccountDetails => '账户详情';
  @override
  String get sectionRewardsInfo => '积分信息';
  @override
  String get sectionCardInfo => '卡片信息';
  @override
  String get sectionBalancePin => '余额与密码';
  @override
  String get sectionGiftDetails => '礼品详情';
  @override
  String get sectionOfferDetails => '优惠详情';
  @override
  String get sectionProviderInfo => '提供方信息';
  @override
  String get sectionTerms => '条款';
  @override
  String get sectionCouponInfo => '优惠券信息';
  @override
  String get sectionRouteDetails => '路线信息';
  @override
  String get sectionTripInfo => '行程信息';
  @override
  String get sectionFareDetails => '票价信息';
  @override
  String get sectionVehicleInfo => '车辆信息';
  @override
  String get sectionKeyDetails => '钥匙信息';
  @override
  String get sectionAccessInfo => '通行信息';
  @override
  String get sectionStudentInfo => '学生信息';
  @override
  String get sectionUniversityDetails => '学校信息';
  @override
  String get sectionEmployeeInfo => '员工信息';
  @override
  String get sectionCompanyDetails => '公司信息';
  @override
  String get sectionGuestInfo => '住客信息';
  @override
  String get sectionHotelDetails => '酒店信息';
  @override
  String get sectionStayDetails => '入住信息';
  @override
  String get sectionResidentInfo => '住户信息';
  @override
  String get sectionPropertyDetails => '物业信息';
  @override
  String get sectionPolicyDetails => '保单详情';
  @override
  String get sectionCoverageInfo => '保障信息';
  @override
  String get sectionTestInfo => '检测信息';
  @override
  String get sectionResults => '检测结果';
  @override
  String get sectionLabDetails => '实验室信息';
  @override
  String get sectionVaccineInfo => '疫苗信息';
  @override
  String get sectionDoseDetails => '接种详情';
  @override
  String get sectionManufacturerInfo => '生产商信息';
  @override
  String get sectionDocumentInfo => '文档信息';
  @override
  String get sectionIssuerDetails => '签发方信息';
  @override
  String get sectionVerification => '验证信息';
  @override
  String get sectionOrganization => '机构';
  @override
  String get sectionDataDetails => '数据详情';
  @override
  String get sectionAdditionalInfo => '附加信息';
  @override
  String get sectionPaymentInfo => '支付信息';
  @override
  String get sectionHeaderDetails => '页眉详情';
  @override
  String get sectionCardDetails => '卡片详情';
  @override
  String get sectionInformation => '信息';
  @override
  String get fieldFrom => '出发地';
  @override
  String get fieldTo => '目的地';
  @override
  String get fieldPassenger => '乘客';
  @override
  String get fieldFlight => '航班';
  @override
  String get fieldGate => '登机口';
  @override
  String get fieldSeat => '座位';
  @override
  String get fieldDeparture => '起飞时间';
  @override
  String get fieldArrival => '到达时间';
  @override
  String get fieldMemberName => '会员姓名';
  @override
  String get fieldBalance => '余额';
  @override
  String get fieldTier => '等级';
  @override
  String get fieldAccountNo => '账号';
  @override
  String get fieldPoints => '积分';
  @override
  String get fieldCardNumber => '卡号';
  @override
  String get fieldPin => '密码';
  @override
  String get fieldRecipient => '收件人';
  @override
  String get fieldEventNo => '活动编号';
  @override
  String get fieldOffer => '优惠';
  @override
  String get fieldProvider => '提供方';
  @override
  String get fieldExpires => '有效期';
  @override
  String get fieldTerms => '条款';
  @override
  String get fieldCode => '代码';
  @override
  String get fieldEvent => '活动';
  @override
  String get fieldVenue => '场馆';
  @override
  String get fieldDate => '日期';
  @override
  String get fieldSection => '区域';
  @override
  String get fieldRow => '排';
  @override
  String get fieldTime => '时间';
  @override
  String get fieldRoute => '路线';
  @override
  String get fieldFareClass => '舱位';
  @override
  String get fieldFare => '票价';
  @override
  String get fieldCoach => '车厢';
  @override
  String get fieldPlatform => '站台';
  @override
  String get fieldVehicle => '车辆';
  @override
  String get fieldKeyStatus => '钥匙状态';
  @override
  String get fieldVin => '车架号';
  @override
  String get fieldDevice => '设备';
  @override
  String get fieldStudentName => '学生姓名';
  @override
  String get fieldUniversity => '学校';
  @override
  String get fieldIdNo => '编号';
  @override
  String get fieldDorm => '宿舍';
  @override
  String get fieldYear => '年级';
  @override
  String get fieldEmployeeName => '员工姓名';
  @override
  String get fieldCompany => '公司';
  @override
  String get fieldDept => '部门';
  @override
  String get fieldAccessLevel => '通行级别';
  @override
  String get fieldGuestName => '住客姓名';
  @override
  String get fieldHotel => '酒店';
  @override
  String get fieldRoomNo => '房间号';
  @override
  String get fieldCheckIn => '入住';
  @override
  String get fieldCheckOut => '退房';
  @override
  String get fieldResidentName => '住户姓名';
  @override
  String get fieldProperty => '物业';
  @override
  String get fieldUnitNo => '单元号';
  @override
  String get fieldPolicyNo => '保单号';
  @override
  String get fieldGroupNo => '组号';
  @override
  String get fieldPcn => 'PCN';
  @override
  String get fieldTestType => '检测类型';
  @override
  String get fieldResult => '结果';
  @override
  String get fieldLab => '实验室';
  @override
  String get fieldVaccine => '疫苗';
  @override
  String get fieldDose => '剂次';
  @override
  String get fieldManufacturer => '生产商';
  @override
  String get fieldLotNo => '批号';
  @override
  String get fieldDocumentType => '文档类型';
  @override
  String get fieldIssuer => '签发方';
  @override
  String get fieldExpiry => '有效期';
  @override
  String get fieldVerified => '已验证';
  @override
  String get fieldDataType => '数据类型';
  @override
  String get fieldNotes => '备注';
  @override
  String get fieldCardType => '卡片类型';
  @override
  String get fieldMerchant => '商户';
  @override
  String get fieldDetails => '详情';
  @override
  String get passCategoryRetail => '零售';
  @override
  String get passCategoryTickets => '票务与交通';
  @override
  String get passCategoryAccess => '门禁';
  @override
  String get passCategoryHealth => '医疗';
  @override
  String get passCategoryIdentity => '身份';
  @override
  String get passCategoryGeneric => '通用';
  @override
  String get passTypeLoyaltyCard => '会员卡';
  @override
  String get passTypeGiftCard => '礼品卡';
  @override
  String get passTypeOffer => '优惠';
  @override
  String get passTypeInStorePayment => '店内支付';
  @override
  String get passTypeBoardingPass => '登机牌';
  @override
  String get passTypeEventTicket => '活动门票';
  @override
  String get passTypeTransitPass => '交通票';
  @override
  String get passTypeDigitalCarKey => '数字车钥匙';
  @override
  String get passTypeCampusId => '校园卡';
  @override
  String get passTypeCorporateBadge => '企业工牌';
  @override
  String get passTypeHotelKey => '酒店房卡';
  @override
  String get passTypeMultiFamilyKey => '小区门禁卡';
  @override
  String get passTypeHealthInsurance => '医疗保险卡';
  @override
  String get passTypeTestRecord => '检测记录';
  @override
  String get passTypeVaccineCard => '疫苗接种卡';
  @override
  String get passTypeDigitalCredential => '数字凭证';
  @override
  String get passTypeGeneric => '通用';
  @override
  String get passTypeGenericPrivate => '私密票卡';
  @override
  String get passTypeCoupon => '优惠券';
  @override
  String get passTypeStoreCard => '储值卡';
  @override
  String get networkVisa => 'VISA';
  @override
  String get networkMastercard => '万事达';
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
  String get organizationRequired => '请填写发卡机构。';
  @override
  String scannedFormat(Object format, Object text) => '已扫描 $format：$text';
  @override
  String get barcodeWord => '条形码';
  @override
  String get fieldOrganization => '机构';
  @override
  String get fieldTermsConditions => '条款与条件';
  @override
  String get fieldContact => '联系方式';
  @override
  String get nameOrganizationLabel => '名称（发卡机构）';
  @override
  String get saveBackupDialogTitle => '保存备份文件';
  @override
  String get noCvvPlaceholder => '无 CVV';
  @override
  String get cardCategoryLabel => '卡类别';
  @override
  String get cardCategoryCredit => '信用卡';
  @override
  String get cardCategoryDebit => '借记卡';
  @override
  String get cardCategoryNone => '无';
  @override
  String get tagsLabel => '标签';
  @override
  String get tagsAddHint => '输入标签后按回车';
  @override
  String get tagsEmpty => '暂无标签';
  @override
  String get filterNetwork => '卡组织';
  @override
  String get filterIssuer => '发卡行';
  @override
  String get filterType => '类型';
  @override
  String get filterAllNetworks => '全部卡组织';
  @override
  String get filterAllIssuers => '全部发卡行';
  @override
  String get filterAllCardTypes => '全部卡类型';
  @override
  String get actionArchive => '归档';
  @override
  String get actionUnarchive => '取消归档';
  @override
  String get actionDeletePermanently => '永久删除';
  @override
  String get archivedView => '归档';
  @override
  String get activeView => '活跃';
  @override
  String get cardArchived => '卡片已归档';
  @override
  String get cardUnarchived => '卡片已取消归档';
  @override
  String archiveConfirmBody(Object name) => '确定要归档「$name」吗？可随时在归档视图中恢复。';
  @override
  String deletePermanentlyConfirmBody(Object name) =>
      '确定要永久删除「$name」吗？此操作无法撤销。';
  @override
  String get noArchivedCards => '暂无归档卡片';
  @override
  String get unknownIssuer => '未知发卡行';
  @override
  String get scannerTitleFront => '拍摄卡片正面';
  @override
  String get scannerTitleBack => '拍摄卡片背面';
  @override
  String get scannerTitleNumberOnly => '扫描卡号';
  @override
  String get scannerHintFront => '将卡片对齐绿色边框内，然后点击底部快门拍摄';
  @override
  String get scannerHintBack => '将卡片背面（签名条+CVV区）对齐绿色边框内拍摄';
  @override
  String get scannerHintNumberOnly => '将卡号对齐矩形框内，点击快门拍摄识别';
  @override
  String get scannerShutterHint => '手动点击按钮拍照（对焦清晰后再拍）';
  @override
  String get scannerNextBack => '去拍摄背面';
  @override
  String get scannerFinish => '完成';
  @override
  String get scannerRetake => '重新拍摄';
  @override
  String get scannerSkipBack => '跳过背面';
  @override
  String get scannerCropOk => '✓ 已识别卡片边缘并自动裁切';
  @override
  String get scannerCropFallback => '未检测到卡片边缘，已保留原始照片';
  @override
  String get scannerProcessing => '处理中…';
  @override
  String get scannerOcrInProgress => '正在识别文字…';
  @override
  String get scannerOcrFailed => '识别失败';
  @override
  String get scannerCaptureFailed => '拍照失败';
  @override
  String get scannerCameraInitializing => '正在启动相机…';
  @override
  String get scannerCameraPermissionDenied => '相机权限被拒绝，请到系统设置开启';
  @override
  String get scannerNoCameraFound => '设备上没有可用相机';
  @override
  String get scannerUnknownError => '未知错误';
  @override
  String get scannerCameraInitFailed => '相机启动失败';
  @override
  String get addCardActionScan => '扫描添加卡片';
  @override
  String get scanCardNumberTooltip => '扫描识别卡号';
}
