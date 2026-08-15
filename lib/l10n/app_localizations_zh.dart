// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

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
  String get emptyPayments => '还没有银行卡。\n点击“+”添加一张。';

  @override
  String get emptyPasses => '还没有票卡。\n点击“+”添加一张。';

  @override
  String get emptyIdentities => '还没有证件。\n点击“+”添加一张。';

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
  String deleteConfirmBody(Object name) {
    return '确定要删除“$name”吗？此操作无法撤销。';
  }

  @override
  String get passDeleted => '票卡已删除！';

  @override
  String get identityDeleted => '证件已删除！';

  @override
  String importSharedTitle(String type) {
    return '导入共享的$type';
  }

  @override
  String importSharedBody(String name) {
    return '是否要导入“$name”？';
  }

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
  String scannedChunk(int current, int total) {
    return '已扫描第 $current / $total 个分片';
  }

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
  String importPassBody(String name) {
    return '是否要导入“$name”？';
  }

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
  String autoBackupSubtitleActive(String path) {
    return '已启用 - $path';
  }

  @override
  String get backupLocationTitle => '备份位置';

  @override
  String get changeBackupPasswordTitle => '修改备份密码';

  @override
  String get changeBackupPasswordSubtitle => '更新自动备份的加密密码';

  @override
  String get enableAutoBackupTitle => '启用自动备份';

  @override
  String get enableAutoBackupBody => '每当您添加或删除卡片、票卡或证件时，都会自动创建备份。';

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
  String get dangerZonePinAuthSubtitle => '请输入设备 PIN 码以删除所有数据，不可使用指纹。';

  @override
  String get pinAuthUnavailable => '本设备不支持 PIN 验证。请先在系统设置中设置屏幕锁定（PIN/密码）后再操作。';

  @override
  String get trademarkNoticeTitle => '商标声明';

  @override
  String get trademarkNoticeSubtitle => '卡组织徽标均为其各自所有者的商标。';

  @override
  String get trademarkDialogTitle => '商标合理使用声明';

  @override
  String get trademarkDialogBody =>
      '本应用中展示的 Visa、Mastercard、银联、JCB、RuPay、American Express 和 Discover 徽标均为其各自所有者的注册商标。\n\n这些徽标仅用于标识卡组织，属于指示性合理使用。\n\n本应用与上述任何公司均无关联，也未获得其认可或赞助。';

  @override
  String get reportErrorTitle => '报告问题';

  @override
  String get reportErrorSubtitle => '发现问题？请在 GitHub 上告知我们。';

  @override
  String get buyMeACoffee => '请我喝杯咖啡';

  @override
  String get passwordLabel => '密码';

  @override
  String passwordTooShort(int min) {
    return '密码长度至少为 $min 位';
  }

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
  String feeWaiverRemaining(String symbol, String amount) {
    return '再消费 $symbol$amount 即可免除';
  }

  @override
  String billEveryDate(String date) {
    return '每月 $date 日';
  }

  @override
  String get naValue => '无';

  @override
  String maxLimitField(String symbol) {
    return '最高额度（$symbol）';
  }

  @override
  String currentSpendsField(String symbol) {
    return '当前消费（$symbol）';
  }

  @override
  String get cashbackRateField => '返现比例（%）';

  @override
  String get billDateField => '账单日（例如：15）';

  @override
  String annualFeeWaiverField(String symbol) {
    return '消费满以下金额免除年费（$symbol）';
  }

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
  String sharePassOrCard(String type) {
    return '分享$type';
  }

  @override
  String scanAllQrCodes(int count) {
    return '请扫描全部 $count 个二维码';
  }

  @override
  String get scanToImportLabel => '扫码导入';

  @override
  String get tapToSetPassword => '点击设置密码';

  @override
  String get toGenerateQr => '以生成二维码';

  @override
  String get passwordEncryptedTransfer => '密码加密传输';

  @override
  String shareMultiChunkBody(int count) {
    return '您的数据已拆分为 $count 个二维码。接收方需扫描全部二维码并输入密码才能解密。';
  }

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
  String scannedFormat(String format, String text) {
    return '已扫描 $format：$text';
  }

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
  String archiveConfirmBody(String name) {
    return '确定要归档「$name」吗？可随时在归档视图中恢复。';
  }

  @override
  String deletePermanentlyConfirmBody(String name) {
    return '确定要永久删除「$name」吗？此操作无法撤销。';
  }

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
