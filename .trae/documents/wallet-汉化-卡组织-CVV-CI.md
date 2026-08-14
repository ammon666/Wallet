# Wallet 改造方案：汉化 + 卡组织扩展 + CVV 字段 + CI 自动构建

## Context（背景与目标）

基于现有 Flutter 钱包应用（Provider + sqflite + AES-256-GCM 加密，三库分离）做四项改造，**保持整体架构不变**（分层 + Provider + 加密体系不动）：

1. **汉化**：引入 i18n 框架（flutter_localizations + intl + gen-l10n），支持简体中文并保留英文，按系统语言自动切换。银行卡相关术语使用专业中文译法。
2. **卡组织扩展**：在现有 Visa/Mastercard/Amex/Discover/RuPay 基础上增加**银联 UnionPay** 与 **JCB**，覆盖中国常见卡组织。
3. **CVV 字段**：为支付卡增加 CVV 录入（加密存储，与卡号同级安全）+ 详情页展示（默认掩码、点击揭示、可复制）。
4. **CI 自动构建**：新增 GitHub Actions 工作流，push 到主分支自动构建 **Debug APK** 并上传为产物（无需签名密钥），仅安卓。

预期结果：中文用户看到简体中文界面并能管理银联/JCB 卡片的 CVV；每次推送代码后 Actions 自动产出可下载的 APK。

---

## 关键约束与已确认事实

- 数据库实际文件名为 `walletbox.db`（非 wallets.db），当前版本 **v7**。
- `Wallet` 模型当前**无 CVV 字段**；`cardtype` 是自由文本（非信用卡/借记卡枚举），无"持卡人"字段（实际字段叫 `Card Name` 卡名称）；rewards 实为返现率（Cashback）。
- 应用未使用任何 i18n 框架，所有字符串硬编码英文。
- 现有 `release.yml`/`test.yml` 仅 `workflow_dispatch` 手动触发且依赖 4 个签名密钥。
- `backup_service.dart` 通过 `toMap()`/`fromMap()` 动态序列化 Wallet（非硬编码字段列表）→ **CVV 自动包含，无需改动备份逻辑**。
- `share_secure_screen.dart:110` 通过 `wallet.toMap()` 生成 QR 分享载荷 → **新增 CVV 后必须剥离，否则 CVV 经二维码外泄**。
- 存在**两个**网络下拉框（添加表单 + 编辑表单）+ 主页筛选 SegmentedButton + 设置页商标声明，共 4 处需同步。
- Debug 构建无需 `sed CMakeLists.txt` 变通（该变通仅 release/jni 需要），也无需签名密钥。

---

## Feature 1：i18n（简体中文 + 保留英文）

### 1.1 基础设施搭建

- **pubspec.yaml**：
  - 顶层新增 `generate: true`
  - `dependencies` 新增 `flutter_localizations: { sdk: flutter }` 与 `intl: ^0.20.0`（与 pubspec.lock 中既有 0.20.2 一致，符合 Flutter 3.44.x 约束）
- **新建 `l10n.yaml`**（仓库根）：
  ```
  arb-dir: lib/l10n
  template-arb-file: app_en.arb
  output-localization-file: app_localizations.dart
  output-class: AppLocalizations
  output-dir: lib/l10n
  synthetic-package: false
  nullable-getter: false
  ```
  - 采用 `synthetic-package: false` + `output-dir: lib/l10n`：生成文件落盘到 `lib/l10n/`，导入路径为 `package:wallet/l10n/app_localizations.dart`，CI 友好且不依赖 `.dart_tool/flutter_gen`。**生成的 3 个文件需提交 git**。
- `flutter pub get` 自动触发 gen-l10n，生成 `app_localizations.dart` / `_en.dart` / `_zh.dart`。

### 1.2 MaterialApp 接线（[main.dart](file:///d:/98.Vibe_coding/Wallet/lib/main.dart) `_MyAppState.build` L76-97）

新增：
- `localizationsDelegates: AppLocalizations.localizationsDelegates`（含 GlobalMaterial/Widgets/Cupertino 本地化，zh 日期/对话框所需）
- `supportedLocales: AppLocalizations.supportedLocales`（`[Locale('en'), Locale('zh')]`）
- `localeResolutionCallback`：设备语言以 `en`/`zh` 开头则采用，否则回退 `en`
- `onGenerateTitle: (ctx) => AppLocalizations.of(ctx)!.appName`（安卓任务切换器标题）

### 1.3 .arb 文件

- 新建 `lib/l10n/app_en.arb`（模板，含全部 key + `@key` description）
- 新建 `lib/l10n/app_zh.arb`（中文翻译）
- 命名规范：按页面/模块分组前缀（如 `splashTagline`、`homeNavPayments`、`walletCardNumber`、`walletCvv`）。

### 1.4 专业术语对照（按代码实际字段校正）

| 代码实际英文 | 中文 | 位置 |
| --- | --- | --- |
| Card Name | 卡名称 | 添加/编辑表单 |
| Card Number | 卡号 | 表单/详情 |
| Expiry (MMYY) | 有效期（MMYY） | 表单/详情 |
| CVV（新增） | CVV（安全码） | 表单/详情 |
| Card Issuer (e.g., HDFC) | 发卡行（例如：HDFC） | 表单/详情 |
| Card Network | 卡组织 | 表单/详情 |
| Card Type (e.g., LTF, Paid) | 卡类型（例如：LTF、付费） | 编辑表单 |
| Max Limit | 信用额度 | 详情/编辑 |
| Annual Spends / Current Spends | 年度消费 / 当前消费 | 详情/编辑 |
| Cashback Rate (%) / Estimated Cashback | 返现率（%）/ 预计返现 | 详情/编辑 |
| Annual Fee Waiver on Spends of $ | 年费减免（消费满 $） | 详情/编辑 |
| Bill Generation Date / Bill Date | 账单日 | 详情/编辑 |
| Custom Fields / Field Name / Value | 自定义字段 / 字段名 / 值 | 表单/详情 |
| Front Image / Back Image / Card Images | 正面照片 / 背面照片 / 卡片照片 | 表单/详情 |
| Secure • Simple • Smart | 安全 · 简洁 · 智能 | 闪屏 |
| Authenticate to access your wallet | 验证身份以访问钱包 | 生物认证（main.dart L205, settings_page.dart L39，均有 context） |

注：原词汇表中"持卡人/还款日/年费/信用卡借记卡"在代码中无对应 UI，不建 key。

### 1.5 无 BuildContext 的字符串处理

- **生物认证 `localizedReason`**（main.dart L205、settings_page.dart L39）：在 State 类中，context 可用 → 直接 `AppLocalizations.of(context)!.biometricReason`。
- **服务层异常**（encryption_service.dart、backup_service.dart）：无 context。策略：**服务层保留英文/错误码，UI 捕获处本地化**。
  - `EncryptionService` 异常多被内部捕获、不展示用户 → 保留英文。
  - `BackupService.restoreBackup` 异常会展示用户 → 在 backup_service.dart 引入轻量类型化异常 `BackupException { String code; }`（code: `wrongPassword`/`corrupted`/`tooSmall`/`wrongFileType`/`invalidFormat`），UI 捕获处按 code 映射到 .arb key。仅 backup_service 做此重构。

### 1.6 字符串提取范围（按文件，约 20+ 文件）

逐文件替换 `AppLocalizations.of(context)!.key`：
- `lib/main.dart`（闪屏 + 认证）
- `lib/screens/homescreen.dart`（导航标签、筛选、搜索、空状态、滑动操作、Snackbar、导入对话框 — 最大量）
- `lib/pages/walletdetails.dart`（详情 + 编辑两套表单）
- `lib/pages/settings_page.dart`（大量设置项、对话框、主题名、币种）
- `lib/pages/add_card_screen.dart`（pkpass 导入流程）
- `lib/screens/share_secure_screen.dart`、`barcode_card_details_screen.dart`、`identity_card_details_screen.dart`
- `lib/widgets/`：credit_card_entry_form / barcode_card_entry_form / identity_card_entry_form / glass_credit_card('CARD' fallback L184) / color_picker / display_barcode_screen / full_screen_image_viewer / image_picker_widget / barcode_card / identity_card_widget

**落地顺序**：① 搭基础设施 + main.dart 几个 key 验证管线通 + zh 能加载；② settings_page + walletdetails（最高价值）；③ homescreen + add_card_screen；④ 全部 widgets；⑤ 服务层异常本地化（类型化异常）。

---

## Feature 2：新增银联 UnionPay + JCB

### 2.1 BIN 识别（[card_utils.dart](file:///d:/98.Vibe_coding/Wallet/lib/services/card_utils.dart) `detectCardNetwork`）

- **JCB**：在 amex 块（L14）之后、rupay 块（L17）之前插入 4 位前缀检查：`3528–3589 → 'jcb'`（与 amex 34/37 无冲突）。
- **银联**：在 discover 块（L45）之后、mastercard 块（L47）之前插入：`startsWith('62') → 'unionpay'`（62 不在 discover 64-69/65/6011 范围，无冲突）。

### 2.2 四处网络列表同步

1. [credit_card_entry_form.dart:268](file:///d:/98.Vibe_coding/Wallet/lib/widgets/credit_card_entry_form.dart#L268) 添加表单下拉 → 追加 `'unionpay','jcb'`
2. [walletdetails.dart:865](file:///d:/98.Vibe_coding/Wallet/lib/pages/walletdetails.dart#L865) `WalletEditScreen._buildDropdown` 编辑表单下拉 → 追加（**易遗漏**）
3. [homescreen.dart:834-851](file:///d:/98.Vibe_coding/Wallet/lib/screens/homescreen.dart#L834) SegmentedButton 筛选 → 新增 `ButtonSegment(value:'unionpay')` 与 `value:'jcb'`，否则无法按新卡组织筛选
4. [settings_page.dart:328](file:///d:/98.Vibe_coding/Wallet/lib/pages/settings_page.dart#L328) 商标声明文本 → .arb 中英文均加入银联/JCB

### 2.3 缺失 Logo 的文字徽标回退（[glass_credit_card.dart](file:///d:/98.Vibe_coding/Wallet/lib/widgets/glass_credit_card.dart) `_NetworkLogo` L170-195）

assets/network/ 仅有 5 张 PNG，无 unionpay/jcb（不生成商标 Logo）。方案：
- 在 card_utils.dart 新增静态映射：
  ```
  static const networkDisplayNames = {
    'visa':'VISA','mastercard':'MASTERCARD','amex':'AMEX',
    'discover':'DISCOVER','rupay':'RUPAY','unionpay':'银联','jcb':'JCB',
  };
  static String? networkDisplayName(String? n) =>
      n==null ? null : networkDisplayNames[n] ?? n.toUpperCase();
  ```
- `_NetworkLogo.errorBuilder` 回退文本改用 `CardUtils.networkDisplayName(network) ?? 'CARD'`（银联显示"银联"，JCB 显示"JCB"）。errorBuilder 在缺图时同步触发，立即显示文字徽标。

### 2.4 precache 列表（[main.dart:152](file:///d:/98.Vibe_coding/Wallet/lib/main.dart#L152)）

**不**追加 unionpay/jcb（precacheImage 缺图会报错且无意义），保持现有 5 个有 PNG 的网络。

### 2.5 与 i18n 协调

Feature 2 先以 `toUpperCase()`/文字徽标落地，i18n 阶段再把四处列表的标签替换为 `AppLocalizations` key（品牌名"银联""JCB"跨语言不变，可继续用静态映射）。

---

## Feature 3：CVV 字段（录入 + 详情展示，加密存储）

### 3.1 模型（[wallet.dart](file:///d:/98.Vibe_coding/Wallet/lib/models/wallet.dart)）

- 新增字段 `final String? cvv;`（邻近 number/expiry）
- 构造函数加 `this.cvv,`
- `toMap()` 加 `'cvv': cvv,`
- `toEncryptedMap()` 加 `'cvv': enc.encryptText(cvv),`（**AES-256-GCM 加密**）
- `fromMap()` 加 `cvv: map['cvv'],`（缺 key 返回 null，向后兼容旧备份/QR）
- `fromEncryptedMap()` 加 `cvv: enc.decryptText(map['cvv']),`
- `fromEncryptedMapSummary()` **不加** cvv（列表不解密敏感字段）

### 3.2 数据库迁移（[db_helper.dart](file:///d:/98.Vibe_coding/Wallet/lib/models/db_helper.dart)）

- `version: 7` → `version: 8`
- `onCreate` CREATE TABLE 加 `cvv TEXT,`
- `onUpgrade` 新增：`if (oldVersion < 8) { await db.execute('ALTER TABLE wallets ADD COLUMN cvv TEXT;'); }`
- `getWalletsSummary` 的 columns 列表**不加** cvv（详情查 `getWalletById` 取全列自动含 cvv）

### 3.3 添加表单（[credit_card_entry_form.dart](file:///d:/98.Vibe_coding/Wallet/lib/widgets/credit_card_entry_form.dart)）

- 新增 `_cvvController` + `bool _cvvVisible = false;`
- dispose 释放
- 在 Expiry 字段（L255）之后插入 CVV `TextFormField`：`keyboardType: number`、`obscureText: !_cvvVisible`、`inputFormatters: [digitsOnly, LengthLimitingTextInputFormatter(4)]`、suffixIcon 为可见性切换 IconButton、validator 允许空或 3-4 位
- `_addData()` 构造 Wallet（L124-134）加 `cvv: _cvvController.text,`

### 3.4 编辑表单（[walletdetails.dart](file:///d:/98.Vibe_coding/Wallet/lib/pages/walletdetails.dart) `WalletEditScreen` L317-790）— **易遗漏**

- 新增 `_cvvController` + `_cvvVisible`
- `initState` 预填 `_cvvController = TextEditingController(text: wallet.cvv);`
- dispose 释放
- 扩展 `_buildTextField`（L792-833）签名增加 `bool obscureText = false` 参数（已支持 suffixIcon）
- 在 "Primary Details" 区块插入 CVV 字段
- `_saveUpdatedDetails` 构造 Wallet（L492-510）加 `cvv: _cvvController.text,`

### 3.5 详情展示（`walletdetails.dart` `WalletDetailScreen`）

- 新增 `bool _cvvRevealed = false;`
- 新建 `_LiquidGlassDetailSection(title:"安全", icon: Icons.lock_outline)`，内含 CVV 自定义 tile：默认显示 `•••`/`••••`，点击切换揭示，提供复制按钮（复用 `ClipboardService.instance.copy` + Snackbar "CVV 已复制"）
- 安全增强：App 切后台（main.dart L60-66 既有 lifecycle listener）时清空图片缓存的同时，可考虑重置 CVV 揭示态（最小实现：详情页dispose 时重置）

### 3.6 安全：QR 分享剥离 CVV（[share_secure_screen.dart:110-121](file:///d:/98.Vibe_coding/Wallet/lib/screens/share_secure_screen.dart#L110)）— **必须与 3.1 同提交**

`_onPasswordSet` 中 `dataMap = _wallet!.toMap();` 后已剥离 image/id，**必须新增 `dataMap.remove('cvv');`**，否则 CVV 经二维码外泄。3.1 与 3.6 视为原子改动。

### 3.7 无需改动（已验证）

- `backup_service.dart`：用 toMap/fromMap 动态序列化，CVV 自动含；`fromMap` 缺 key 返回 null → 旧备份可恢复。
- `loyalty_migration_service.dart`：迁移 loyalty.db→passes，不涉及 wallets。
- `homescreen.dart` 导入校验 `_isValidWalletData`：仅要 name/number/expiry，CVV 缺失可导入。

---

## Feature 4：CI 自动构建 Debug APK

### 4.1 新建 `.github/workflows/build-apk.yml`

- 触发：`push: branches: [main, master]` + `workflow_dispatch:` + `paths-ignore: ['**/*.md']`（文档变更不构建）
- `permissions: contents: read`
- `runs-on: ubuntu-latest`
- 步骤：
  1. `actions/checkout@v4`
  2. `actions/setup-java@v4`（zulu, 17）
  3. `subosito/flutter-action@v2`（`flutter-version-file: pubspec.yaml`, `channel: stable`, `cache: true`）
  4. `flutter --version`
  5. `flutter pub get`（若 Feature 1 已合入，自动跑 gen-l10n）
  6. `flutter build apk --debug`（debug 自动签名，无需密钥；产物 `build/app/outputs/flutter-apk/app-debug.apk`）
  7. `actions/upload-artifact@v4`：name `app-debug-apk`，path 上述产物，`retention-days: 14`

### 4.2 决策

- **不**加 `sed CMakeLists.txt`（仅 release/jni 需要）
- **不**加签名步骤（debug 用自动调试密钥）
- **不**加 split-per-abi 与 AAB（仅一个 universal Debug APK）
- 现有 `release.yml`/`test.yml` **保持不动**（保留手动签名发布通道）
- 与 Feature 1 协调：采用 `synthetic-package: false` 时，生成的 `lib/l10n/app_localizations*.dart` 须先提交 git，CI 才能编译

---

## 跨功能协调与落地顺序

**依赖关系**：Feature 2/3 独立于 Feature 1；Feature 4 独立于全部（但若 1 先合且 `synthetic-package:false`，需先提交生成文件）。Feature 3 的 3.1+3.2+3.6 必须原子提交（否则 QR 分享泄露 CVV）。

**建议提交顺序**：
1. Feature 2（卡组织）— 最小、隔离、无 schema 变更
2. Feature 3（CVV）— schema 升级；3.1+3.2+3.6 原子，再 3.3/3.4/3.5
3. Feature 4（CI）— 独立
4. Feature 1（i18n）— 最大；按 1.6 顺序逐屏落地

---

## 验证方案

1. **i18n**：`flutter pub get` 生成 AppLocalizations 无误；`flutter run`，将设备/模拟器语言设为简体中文 → 全站中文；切英文 → 英文；专业术语对照表逐项核对。
2. **卡组织**：添加卡片时输入 `62` 开头卡号 → 自动识别"银联"；`3528` 开头 → "JCB"；下拉与主页筛选出现新选项；卡片正面文字徽标显示"银联"/"JCB"。
3. **CVV**：添加卡片填 CVV（3-4 位、可显隐）→ 保存 → 详情页 CVV 默认掩码、点击揭示、复制生效；用已有 v7 数据的设备升级 → `onUpgrade` v8 加列成功、旧卡 CVV 为空；生成 QR 分享 → 验证载荷不含 cvv（安全）；备份导出/恢复含 CVV。
4. **CI**：push 到 main → GitHub Actions 标签页出现构建任务 → 成功后在 Artifacts 下载 `app-debug-apk` → 安装运行验证。

### 关键改动文件清单

- [pubspec.yaml](file:///d:/98.Vibe_coding/Wallet/pubspec.yaml) + 新建 `l10n.yaml` + 新建 `lib/l10n/app_en.arb`、`app_zh.arb` 及生成文件
- [main.dart](file:///d:/98.Vibe_coding/Wallet/lib/main.dart)（MaterialApp 接线 + 闪屏/认证字符串 + precache）
- [card_utils.dart](file:///d:/98.Vibe_coding/Wallet/lib/services/card_utils.dart)（BIN + 显示名映射）
- [wallet.dart](file:///d:/98.Vibe_coding/Wallet/lib/models/wallet.dart)（CVV 字段）
- [db_helper.dart](file:///d:/98.Vibe_coding/Wallet/lib/models/db_helper.dart)（v8 迁移）
- [credit_card_entry_form.dart](file:///d:/98.Vibe_coding/Wallet/lib/widgets/credit_card_entry_form.dart)（CVV 录入 + 下拉）
- [walletdetails.dart](file:///d:/98.Vibe_coding/Wallet/lib/pages/walletdetails.dart)（编辑表单 CVV + 详情展示 + 下拉）
- [share_secure_screen.dart](file:///d:/98.Vibe_coding/Wallet/lib/screens/share_secure_screen.dart)（剥离 CVV）
- [glass_credit_card.dart](file:///d:/98.Vibe_coding/Wallet/lib/widgets/glass_credit_card.dart)（文字徽标）
- [homescreen.dart](file:///d:/98.Vibe_coding/Wallet/lib/screens/homescreen.dart)（筛选 SegmentedButton + 字符串）
- [settings_page.dart](file:///d:/98.Vibe_coding/Wallet/lib/pages/settings_page.dart)（商标声明 + 字符串 + 备份异常本地化）
- [backup_service.dart](file:///d:/98.Vibe_coding/Wallet/lib/services/backup_service.dart)（类型化异常）
- 新建 `.github/workflows/build-apk.yml`
- 其余 widgets/screens 字符串逐文件替换（见 1.6）
