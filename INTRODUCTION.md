# Wallet 项目介绍文档

> 隐私优先、零知识的本地卡片管理应用。所有敏感数据经军用级加密后仅存储于设备本地，应用**完全不申请联网权限**，从物理层面杜绝数据外泄。

---

## 一、项目概述

**Wallet** 是一款基于 **Flutter** 构建的开源（GPL 协议）卡片管理 App，可让你在本地安全存储信用卡、借记卡、会员卡、条码卡、身份卡以及 Apple Wallet 通行证（`.pkpass`）。

- **包名**：`com.sidhant.wallet`
- **当前版本**：`1.0.41+44`（见 [pubspec.yaml](file:///d:/98.Vibe_coding/Wallet/pubspec.yaml)）
- **目标平台**：Android（同时具备 iOS / Linux / Web 的基础运行能力）
- **分发渠道**：Google Play、IzzyOnDroid、F-Droid、GitHub Releases

应用的核心设计哲学是 **"绝对零网络访问 + 端到端本地加密"**：敏感字段、自定义数据与卡片图片均使用 **AES-256-GCM** 加密，密钥派生使用 **Argon2id（RFC 9106）**，主密钥保存在系统级安全存储（Android Keystore / iOS Keychain）中。

---

## 二、核心特性

| 特性 | 说明 |
| --- | --- |
| 🚫 零网络访问 | AndroidManifest 仅声明 `CAMERA` 权限，**未申请 `INTERNET`**；并禁用系统自动备份（`allowBackup=false`、`fullBackupContent=false`）。 |
| 🛡️ 军用级加密 | AES-256-GCM 认证加密；备份/分享使用 Argon2id 派生密钥（128MB 内存 / 3 轮 / 并行度 4）。 |
| 🔐 生物识别保护 | 启动时通过 `local_auth` 进行指纹/面部解锁；销毁性操作前需重新认证。 |
| 🎨 Liquid Glass UI | 玻璃拟态设计、交错动画、动态过渡，支持真·OLED 暗色模式。 |
| 📲 Apple Wallet 支持 | 直接导入并解析 `.pkpass` 文件至本地保险库。 |
| 🔄 安全 E2EE 分享 | 通过加密二维码分享卡片，数据仅由接收端 App 实例解密。 |
| 💾 加密备份 | 整库导出为 `.wbk` 文件，含卡片、通行证、身份卡与设置。 |
| 📸 加密图片保险库 | 卡片正反面照片在磁盘上加密、仅在内存中解密（带 LRU 缓存）。 |

---

## 三、技术栈

| 层级 | 技术 |
| --- | --- |
| 框架 | Flutter `^3.44.7` / Dart SDK `^3.10.4` |
| 状态管理 | `provider`（`ChangeNotifier` + `MultiProvider`） |
| 本地数据库 | `sqflite` / `sqflite_common_ffi`（三库分离） |
| 加密 | `cryptography_plus`（Argon2id）、`encrypt`（AES）、`crypto`（SHA/HMAC） |
| 安全存储 | `flutter_secure_storage`（Keystore/Keychain） |
| 生物识别 | `local_auth` |
| 条码 | `barcode_scan2`、`barcode_widget`、`zxing_lib` |
| 文件/图片 | `file_picker`、`image_picker`、`image`、`archive` |
| 共享接入 | `receive_sharing_intent`（接收系统图片分享） |
| 其他 | `path` / `path_provider`、`shared_preferences`、`url_launcher` |

---

## 四、项目结构

```
Wallet/
├── lib/
│   ├── main.dart                      # 应用入口、启动闪屏、生物认证
│   ├── models/                        # 数据模型 + 状态 Provider + DB Helper
│   │   ├── db_helper.dart             # 三个 SQLite 库的建表/迁移/CRUD
│   │   ├── provider_helper.dart       # WalletProvider / PassProvider / IdentityProvider
│   │   ├── wallet.dart                # 信用卡/借记卡模型
│   │   ├── pass.dart / pass_types.dart# pkpass 通行证模型与类型枚举
│   │   ├── identity_card.dart         # 身份卡模型
│   │   ├── theme_provider.dart        # 主题（明/暗/字体）
│   │   ├── startup_settings_provider.dart  # 启动设置（是否需认证等）
│   │   ├── auto_backup_provider.dart  # 自动备份开关状态
│   │   ├── card_color_data.dart       # 卡片配色数据
│   ├── services/                      # 业务逻辑服务层
│   │   ├── encryption_service.dart    # ★ 加密核心：AES-256-GCM + Argon2id
│   │   ├── app_initialization_service.dart  # 启动初始化
│   │   ├── backup_service.dart        # 手动备份/恢复（.wbk）
│   │   ├── auto_backup_service.dart   # 自动备份触发
│   │   ├── pkpass_service.dart        # .pkpass 解析与导入
│   │   ├── barcode_decoder_service.dart / barcode_utils.dart  # 条码解码/工具
│   │   ├── card_utils.dart            # 卡号校验、品牌识别等
│   │   ├── clipboard_service.dart     # 安全剪贴板（自动清除）
│   │   ├── image_service.dart         # 图片处理
│   │   ├── saf_service.dart           # Android SAF 文件访问
│   │   ├── loyalty_migration_service.dart  # 旧版会员卡数据迁移
│   ├── screens/                       # 全屏页面
│   │   ├── homescreen.dart            # 主页（卡片列表/搜索/分类）
│   │   ├── barcode_card_details_screen.dart
│   │   ├── identity_card_details_screen.dart
│   │   ├── share_secure_screen.dart   # 加密 QR 分享
│   ├── pages/                         # 业务页面
│   │   ├── add_card_screen.dart       # 添加卡片
│   │   ├── settings_page.dart         # 设置
│   │   └── walletdetails.dart         # 卡片详情
│   └── widgets/                       # 可复用 UI 组件
│       ├── glass_credit_card.dart     # 玻璃质感信用卡
│       ├── credit_card_entry_form.dart / barcode_card_entry_form.dart / identity_card_entry_form.dart
│       ├── display_barcode_screen.dart / barcode_card.dart
│       ├── encrypted_image_display.dart / full_screen_image_viewer.dart / image_picker_widget.dart
│       ├── color_picker.dart / form_section.dart / identity_card_widget.dart
├── android/                           # Android 原生配置（AndroidManifest 等）
├── assets/                            # 卡组织图标、字体（SpaceGrotesk）
└── pubspec.yaml
```

---

## 五、架构设计

应用采用 **分层 + Provider 状态管理** 的简洁架构：

```
┌─────────────────────────────────────────────┐
│  UI 层 (screens / pages / widgets)          │  ← StatelessWidget / StatefulWidget
├─────────────────────────────────────────────┤
│  状态层 (models/*_provider.dart)            │  ← ChangeNotifier，通过 Provider 注入
│     WalletProvider / PassProvider /         │
│     IdentityProvider / ThemeProvider ...    │
├─────────────────────────────────────────────┤
│  服务层 (services/*.dart)                   │  ← 单例服务，无状态业务逻辑
│     EncryptionService / BackupService ...   │
├─────────────────────────────────────────────┤
│  数据层 (models/db_helper.dart)             │  ← sqflite，三库分离
│     DatabaseHelper / PassDatabaseHelper /   │
│     IdentityDatabaseHelper                  │
└─────────────────────────────────────────────┘
```

- **入口装配**：[main.dart](file:///d:/98.Vibe_coding/Wallet/lib/main.dart) 中通过 `MultiProvider` 注册 6 个 Provider（3 个业务数据 + 3 个设置类）。
- **数据流向**：UI 通过 `Provider.of<T>(context)` 读取状态；调用 Provider 方法 → Provider 调用对应 `DatabaseHelper` → `DatabaseHelper` 在读写时透明地调用 `EncryptionService` 对字段加解密。
- **自动备份联动**：任意删除操作都会触发 `AutoBackupService.triggerBackup()`（见 [provider_helper.dart](file:///d:/98.Vibe_coding/Wallet/lib/models/provider_helper.dart)）。
- **生命周期守护**：`_MyAppState` 注册 `AppLifecycleListener`，应用进入 `paused` 时清空图片解密缓存，避免明文图片长驻内存。

---

## 六、安全机制（核心）

### 6.1 零网络保证
[AndroidManifest.xml](file:///d:/98.Vibe_coding/Wallet/android/app/src/main/AndroidManifest.xml) 仅声明 `CAMERA` 与 `android.hardware.camera`，**无 `INTERNET` 权限**，同时关闭 Android 自动备份：

```xml
<uses-permission android:name="android.permission.CAMERA" />
<application android:allowBackup="false" android:fullBackupContent="false" ...>
```

### 6.2 加密体系（[encryption_service.dart](file:///d:/98.Vibe_coding/Wallet/lib/services/encryption_service.dart)）

**主密钥**
- 首次启动用 `Random.secure()` 生成 32 字节（256-bit）随机密钥；
- 经 `flutter_secure_storage` 存入 Android Keystore / iOS Keychain；
- 单例 `EncryptionService.instance`，启动时由 `AppInitializationService.initializeApp()` 完成初始化。

**字段级加密（AES-256-GCM）**
- 每条敏感字段独立加密，使用随机 12 字节 IV（96-bit nonce）；
- 存储格式：`base64(iv):base64(ciphertext + 16字节GCM认证tag)`；
- 提供自动兼容：按 IV 长度识别 GCM（12B）/ 旧版 CBC（16B），平滑读取历史数据；
- 支持文本、JSON Map、图片字节三种加密入口。

**备份加密（Argon2id）**
- 密钥派生：`DartArgon2id(parallelism: 4, memory: 128MB, iterations: 3, hashLength: 32)`（符合 RFC 9106）；
- 备份文件格式：`argon2:<base64(salt)>:<base64(iv)>:<base64(ciphertext)>`；
- 保留对旧版 **PBKDF2-HMAC-SHA256（600,000 轮）** 与更早 SHA-256 多轮方案的**只读兼容**，确保历史备份可恢复。

**加密 QR 分享**
- 同样基于 Argon2id 派生密钥 + AES-256-GCM；
- 密文按 1500 字节分块为多张二维码，格式 `v3:<idx>:<total>:<salt>:<iv>:<chunk>`；
- 接收端支持 v3（Argon2id）/ v2（PBKDF2）/ v1（设备内密钥）三种版本。

**图片加密**
- 图片落盘前在独立 **Isolate** 中完成 AES-256-GCM 加密（`compute()`），避免阻塞 UI；
- 解密结果进入 **LRU 内存缓存**（上限 20 张），命中即免重复解密；
- 应用切到后台时 `clearImageCache()` 立即清空明文缓存。

**性能优化**
- 备份加解密、图片加解密均通过 `compute()` 在 Isolate 中执行；
- 缓存的 `Encrypter` 实例避免每次调用重复构造。

### 6.3 认证
- 启动闪屏 `SplashScreen` 在 `showAuthenticationScreen` 开启时调用 `LocalAuthentication().authenticate()`，要求指纹/面容解锁后方可进入主页（Linux/Web 跳过）。

---

## 七、数据模型与存储

应用使用 **三个独立的 SQLite 数据库**，均位于应用文档目录，所有敏感文本字段在写入前加密、读取时解密。

### 7.1 `wallets.db`（v7）— 信用卡 / 借记卡 / 会员卡
表 `wallets`：`id, name, number, expiry, network, issuer, customFields, spends, rewards, annualFeeWaiver, maxlimit, cardtype, billdate, category, color, frontImagePath, backImagePath, orderIndex`（带 `orderIndex` 索引）。

> 提供轻量查询 `getWalletsSummary()`：仅解密列表展示与搜索所需字段，详情页再通过 `getWalletById()` 解密全部字段，减少冷启动开销。

### 7.2 `passes.db`（v2）— Apple Wallet 通行证 / 条码卡
表 `passes`：`id, type, organizationName, description, logoText, backgroundColor, foregroundColor, labelColor, barcodeValue, barcodeFormat, barcodeAltText, transitType, relevantDate, frontImagePath, backImagePath, stripImagePath, thumbnailImagePath, fields, orderIndex`。

### 7.3 `identities.db`（v3）— 身份卡
表 `identities`：`id, name, value, cardType, frontImagePath, backImagePath, color, orderIndex`。

### 7.4 数据迁移
- 每个库都有 `onUpgrade` 增量迁移逻辑；
- `migrateToEncrypted()` 以 50 条/批的方式将历史明文数据加密回写，批次间 `yield` 让出事件循环保持 UI 响应；
- 加密迁移进度通过 `flutter_secure_storage` 中的 `wallet_encryption_migrated` / `..._migrated_v2` 标志位记录。

### 7.5 三个状态 Provider（[provider_helper.dart](file:///d:/98.Vibe_coding/Wallet/lib/models/provider_helper.dart)）
- `WalletProvider` / `PassProvider` / `IdentityProvider`：各负责对应库的列表加载、删除、重排序与搜索；
- 删除操作统一触发 `AutoBackupService.triggerBackup()`；
- `PassProvider.searchPasses` 支持深入动态 `fields`（含 label/value）做全文搜索。

---

## 八、应用启动流程

[main.dart](file:///d:/98.Vibe_coding/Wallet/lib/main.dart) `main()`：

1. `WidgetsFlutterBinding.ensureInitialized()`；
2. **并行初始化**（`Future.wait`）：
   - `ThemeProvider.init()`
   - `StartupSettingsProvider.loadStartupSettings()`
   - `AutoBackupProvider.init()`
   - `AppInitializationService.initializeApp()`（含 `EncryptionService.init()`）
3. `AutoBackupService.initialize(autoBackupProvider)`；
4. `runApp(MultiProvider(...))` 注册 6 个 Provider；
5. `MaterialApp` 首页为 `SplashScreen`：
   - 预缓存卡组织图标（visa/mastercard/amex/discover/rupay）；
   - 读取启动设置，若开启认证则进行生物识别；
   - 通过后无动画跳转至 `HomeScreen`。

---

## 九、核心模块速览

| 模块 | 职责 |
| --- | --- |
| [encryption_service.dart](file:///d:/98.Vibe_coding/Wallet/lib/services/encryption_service.dart) | 字段/JSON/图片 AES-256-GCM 加解密；备份与 QR 分享的 Argon2id 派生；图片 LRU 缓存；迁移标志管理 |
| [db_helper.dart](file:///d:/98.Vibe_coding/Wallet/lib/models/db_helper.dart) | 三库建表、版本迁移、加密 CRUD、批量重排序、加密迁移 |
| [provider_helper.dart](file:///d:/98.Vibe_coding/Wallet/lib/models/provider_helper.dart) | 三个业务 Provider，连接 UI 与数据层，触发自动备份 |
| [backup_service.dart](file:///d:/98.Vibe_coding/Wallet/lib/services/backup_service.dart) | 导出/导入 `.wbk` 加密备份（含卡片、通行证、身份卡、设置） |
| [auto_backup_service.dart](file:///d:/98.Vibe_coding/Wallet/lib/services/auto_backup_service.dart) | 数据变更后自动触发备份 |
| [pkpass_service.dart](file:///d:/98.Vibe_coding/Wallet/lib/services/pkpass_service.dart) | 解析 `.pkpass` 压缩包并导入为本地 Pass |
| [barcode_decoder_service.dart](file:///d:/98.Vibe_coding/Wallet/lib/services/barcode_decoder_service.dart) | 扫码识别条码/二维码 |
| [card_utils.dart](file:///d:/98.Vibe_coding/Wallet/lib/services/card_utils.dart) | 卡号校验（Luhn）、卡组织识别、格式化 |
| [clipboard_service.dart](file:///d:/98.Vibe_coding/Wallet/lib/services/clipboard_service.dart) | 复制卡号等敏感信息到剪贴板并定时清除 |
| [saf_service.dart](file:///d:/98.Vibe_coding/Wallet/lib/services/saf_service.dart) | 通过 Android Storage Access Framework 选择文件 |
| [share_secure_screen.dart](file:///d:/98.Vibe_coding/Wallet/lib/screens/share_secure_screen.dart) | 生成/扫描加密二维码完成端到端分享 |
| [homescreen.dart](file:///d:/98.Vibe_coding/Wallet/lib/screens/homescreen.dart) | 主界面：分类列表、搜索、拖拽排序、入口导航 |

---

## 十、构建与运行

> 环境要求：Flutter `^3.44.7` / Dart `^3.10.4`。

```bash
# 安装依赖
flutter pub get

# 调试运行
flutter run

# 构建 Release APK
flutter build apk --release

# 构建 App Bundle（上架 Play Store）
flutter build appbundle --release
```

> 说明：桌面（Linux）/Web 端运行时，生物认证会自动跳过；FFI 版 sqflite 用于桌面测试支持。

---

## 十一、安全设计小结

1. **物理隔离**：无 `INTERNET` 权限 + 关闭系统备份，数据无法外发。
2. **纵深加密**：主密钥在 Keystore → 字段级 AES-256-GCM → 备份/分享 Argon2id。
3. **最小驻留**：图片解密仅在内存、LRU 限 20 张、切后台即清空。
4. **认证守门**：启动生物识别，销毁性操作前再次确认。
5. **向后兼容**：保留对 CBC、PBKDF2、旧版 QR 协议的**只读**兼容，升级无感。
6. **性能兼顾**：加解密与密钥派生全部 Isolate 化，列表查询走轻量解密路径。

---

*本文档基于源码（截至 v1.0.41+44）整理，关键安全实现均经 [encryption_service.dart](file:///d:/98.Vibe_coding/Wallet/lib/services/encryption_service.dart) 与 [AndroidManifest.xml](file:///d:/98.Vibe_coding/Wallet/android/app/src/main/AndroidManifest.xml) 核对。*
