# 银行卡功能优化计划（11项）

## Context

用户要求对钱包应用的银行卡模块进行 11 项功能优化，涵盖卡片显示、表单校验、归档功能、标签系统、筛选增强等方面。当前卡片模型（`Wallet`）已有 `number`、`expiry`、`cvv`、`network`、`issuer`、`cardtype` 等字段，但缺少归档标记、卡类别（credit/debit）和自定义标签。数据库当前为 v8，需要迁移到 v9 添加新列。

## 涉及的关键文件

| 文件                                        | 改动内容                                     |
| ----------------------------------------- | ---------------------------------------- |
| `lib/models/wallet.dart`                  | 新增 `isArchived`、`cardCategory`、`tags` 字段 |
| `lib/models/db_helper.dart`               | DB v8→v9 迁移；归档/取消归档方法；查询排除已归档卡片          |
| `lib/models/provider_helper.dart`         | WalletProvider 新增归档/取消归档方法               |
| `lib/services/card_utils.dart`            | 新增本地化卡组织名称方法                             |
| `lib/widgets/glass_credit_card.dart`      | 显示前4位卡号、标签、卡类别标签                         |
| `lib/widgets/credit_card_entry_form.dart` | 卡类别选择、标签输入、校验时机、有效期月份校验                  |
| `lib/pages/walletdetails.dart`            | CVV 点击复制（去掉按钮）、编辑表单同步改动、下拉框尺寸修复          |
| `lib/screens/homescreen.dart`             | 按发卡行分组、紧凑筛选栏、归档视图切换                      |
| `lib/l10n/app_zh.arb` / `app_en.arb`      | 新增本地化键                                   |

***

## 实现步骤

### 第 1 步：数据库迁移 v8 → v9

**文件**: `lib/models/db_helper.dart`

在 `onUpgrade` 中添加 `if (oldVersion < 9)` 分支，`onCreate` 中也同步更新建表语句：

```sql
ALTER TABLE wallets ADD COLUMN isArchived INTEGER DEFAULT 0;
ALTER TABLE wallets ADD COLUMN cardCategory TEXT;
ALTER TABLE wallets ADD COLUMN tags TEXT;
```

版本号 `version: 8` → `version: 9`。

在 `getWalletsSummary()` 的 `columns` 列表中添加 `'isArchived'`, `'cardCategory'`, `'tags'`。

新增方法：

* `archiveWallet(int id)` — 将 `isArchived` 设为 1

* `unarchiveWallet(int id)` — 将 `isArchived` 设为 0

* `getArchivedWalletsSummary()` — 查询 `WHERE isArchived = 1`

* 修改 `getWalletsSummary()` — 添加 `where: 'isArchived = 0 OR isArchived IS NULL'`

### 第 2 步：Wallet 模型更新

**文件**: `lib/models/wallet.dart`

新增三个字段：

```dart
final bool isArchived;
final String? cardCategory; // 'credit' | 'debit' | null
final List<String>? tags;
```

更新以下方法，加入新字段的序列化/反序列化（`tags` 用 `jsonEncode`/`jsonDecode` + `encryptText` 加密）：

* 构造函数（`isArchived` 默认 `false`）

* `toMap()` / `toEncryptedMap()`

* `fromMap()` / `fromEncryptedMap()` / `fromEncryptedMapSummary()`

### 第 3 步：WalletProvider 更新

**文件**: `lib/models/provider_helper.dart`

新增方法：

* `archiveWallet(int id)` — 调用 `DatabaseHelper.archiveWallet`，从 `wallets` 列表移除，`notifyListeners()`

* `unarchiveWallet(int id)` — 调用 `DatabaseHelper.unarchiveWallet`

* `fetchArchivedWallets()` — 加载归档卡片列表

* `deleteWalletPermanently(int id)` — 调用原有 `deleteWallet`（硬删除）

### 第 4 步：卡组织名称本地化（功能 4）

**文件**: `lib/services/card_utils.dart`

新增方法，使用 `AppLocalizations` 返回本地化名称：

```dart
static String? networkDisplayNameLocalized(String? network, AppLocalizations l) {
  if (network == null) return null;
  switch (network) {
    case 'visa': return l.networkVisa;
    case 'mastercard': return l.networkMastercard;
    case 'amex': return l.networkAmex;
    case 'discover': return l.networkDiscover;
    case 'rupay': return l.networkRupay;
    case 'unionpay': return l.networkUnionpay;
    case 'jcb': return l.networkJcb;
    default: return network.toUpperCase();
  }
}
```

保留原 `networkDisplayNames` 作为无 context 时的回退。

**本地化文件**: `app_zh.arb` 修改 `"networkMastercard": "万事达"`，`app_en.arb` 保持 `"Mastercard"`。

更新所有使用 `CardUtils.networkDisplayName()` 的位置改用 `networkDisplayNameLocalized(network, l)`：

* `glass_credit_card.dart` 的 `_IssuerBadge` 和 `_NetworkLogo`

* `credit_card_entry_form.dart` 的下拉框 items

* `walletdetails.dart` 的 `_buildDropdown` items

* `homescreen.dart` 的筛选 SegmentedButton labels

### 第 5 步：卡片显示优化（功能 1、9、10）

**文件**: `lib/widgets/glass_credit_card.dart`

**功能 1 — 前4位+后4位**：

```dart
final firstFour = widget.wallet.number.length >= 8
    ? widget.wallet.number.substring(0, 4)
    : '';
final lastFour = widget.wallet.number.length >= 4
    ? widget.wallet.number.substring(widget.wallet.number.length - 4)
    : widget.wallet.number;
// 掩码格式: "1234  ••••  ••••  5678"
```

**功能 9 — 卡类别标签**：
在 `_IssuerBadge` 旁边或卡片上添加一个小标签显示 `信用卡` / `借记卡`（当 `cardCategory` 不为 null 时）。

**功能 10 — 自定义标签显示**：
在卡号和持卡人名之间添加一行 `Wrap` of 小 chip，半透明白色背景，显示 `wallet.tags`。

### 第 6 步：表单优化（功能 5、6、7、9、10）

**文件**: `lib/widgets/credit_card_entry_form.dart` 和 `lib/pages/walletdetails.dart`（WalletEditScreen）

**功能 5 — 校验时机**：

* 表单设置 `autovalidateMode: AutovalidateMode.disabled`（默认）

* 为卡号和有效期字段各添加 `FocusNode`，在 `onFocusChange` 时调用 `_formKey.currentState?.validate()`

* 保留保存时的 `validate()` 调用

**功能 6 — 有效期月份校验**：

```dart
validator: (v) {
  if (v == null || v.length != 4) return l.validationExpiryLength;
  final month = int.tryParse(v.substring(0, 2));
  if (month == null || month < 1 || month > 12) {
    return l.validationExpiryMonth; // 新增: "月份必须在 01-12 之间"
  }
  return null;
},
```

**功能 7 — 下拉框尺寸一致性**：
在 `walletdetails.dart` 的 `_buildDropdown` 中，移除 `Container` 的 `padding`，改为在 `InputDecoration` 中使用与 `_buildTextField` 相同的 `contentPadding`，确保两者高度和内边距一致。

**功能 9 — 卡类别选择**：
在基本信息区域添加 `cardCategory` 下拉框（信用卡/借记卡/无），放在发卡行字段之后。

**功能 10 — 标签输入**：
在表单中新增标签输入区域：

* 使用 `Wrap` + `FilterChip` 展示已添加的标签（点击 × 删除）

* 一个 `TextField` + 添加按钮输入新标签

* 标签存储在 `_tags` 列表（`List<String>`），保存时写入 `Wallet.tags`

### 第 7 步：CVV 点击复制（功能 3）

**文件**: `lib/pages/walletdetails.dart`

在 `WalletDetailScreen` 的 CVV 行中：

* 移除复制 `IconButton`（Icons.copy\_rounded）

* 将 CVV 文字包裹在 `GestureDetector` 中，点击时调用 `ClipboardService.instance.copy(cvv)` 并显示 SnackBar

* 保留可见性切换 `IconButton`

### 第 8 步：首页分组 + 紧凑筛选 + 归档视图（功能 2、8、11）

**文件**: `lib/screens/homescreen.dart`

**功能 2 — 按发卡行分组**：

* 将筛选后的 wallets 按 `issuer` 分组排序（issuer 字母序，组内按 orderIndex）

* 构建混合列表：`[Header(BankA), Card, Card, Header(BankB), Card, ...]`

* 使用 `SliverReorderableList`，header 项不包裹 `ReorderableDelayedDragStartListener`（不可拖拽），card 项包裹（可拖拽）

* `onReorder` 中将视觉索引转换为 wallet 索引后执行重排

* 重排后更新 orderIndex 并重新按 issuer 分组

**功能 8 — 归档视图**：

* 在筛选栏添加归档切换按钮（`IconButton` 或 `FilterChip`）

* `_showArchived` 状态：为 true 时加载归档卡片，为 false 时加载正常卡片

* 归档视图中：

  * Slidable 的删除按钮改为"永久删除"（调用 `deleteWalletPermanently`）

  * 新增"取消归档"操作（调用 `unarchiveWallet`）

* 正常视图中：

  * Slidable 的删除按钮改为"归档"（调用 `archiveWallet`），不再直接硬删除

  * 归档操作不需要指纹验证（非破坏性操作）

**功能 11 — 紧凑筛选栏**：
将现有的 `SegmentedButton`（8 个段，占满一整行水平滚动）替换为单行 3 个紧凑下拉框：

```
[卡组织: 全部 ▼] [发卡行: 全部 ▼] [类型: 全部 ▼]
```

* 卡组织下拉：全部 / VISA / 万事达 / 银联 / AMEX / JCB / 发现 / RUPAY

* 发卡行下拉：全部 + 从当前卡片列表中提取的去重发卡行

* 类型下拉：全部 / 信用卡 / 借记卡

* 使用 `DropdownButtonFormField` 或紧凑的 `DropdownButton`，包裹在小型 `Container` 中

筛选逻辑：三个条件 AND 组合（卡组织 AND 发卡行 AND 类型）。

### 第 9 步：本地化更新

**文件**: `lib/l10n/app_zh.arb` 和 `lib/l10n/app_en.arb`

新增键（中英文对照）：

```
"validationExpiryMonth": "月份必须在 01-12 之间" / "Month must be 01-12"
"cardCategoryLabel": "卡类别" / "Card Category"
"cardCategoryCredit": "信用卡" / "Credit"
"cardCategoryDebit": "借记卡" / "Debit"
"cardCategoryNone": "无" / "None"
"tagsLabel": "标签" / "Tags"
"tagsAddHint": "输入标签后按回车" / "Type tag and press enter"
"tagsEmpty": "暂无标签" / "No tags"
"filterNetwork": "卡组织" / "Network"
"filterIssuer": "发卡行" / "Issuer"
"filterType": "类型" / "Type"
"actionArchive": "归档" / "Archive"
"actionUnarchive": "取消归档" / "Unarchive"
"actionDeletePermanently": "永久删除" / "Delete Permanently"
"archivedView": "归档" / "Archived"
"activeView": "活跃" / "Active"
"cardArchived": "卡片已归档" / "Card archived"
"cardUnarchived": "卡片已取消归档" / "Card unarchived"
"archiveConfirmBody": "确定要归档"{name}"吗？可随时在归档视图中恢复。" / "Archive "{name"? You can restore it from the archive view."
"deletePermanentlyConfirmBody": "确定要永久删除"{name}"吗？此操作无法撤销。" / "Permanently delete "{name}? This cannot be undone."
```

修改：

* `"networkMastercard"`: `"MASTERCARD"` → `"万事达"` (zh) / `"Mastercard"` (en)

***

## 自查清单

实现完成后逐项检查：

1. **国际化键一致性**：`app_zh.arb` 和 `app_en.arb` 的键完全对应；`flutter gen-l10n` 无报错
2. **DB 迁移安全**：`onUpgrade` 的 `oldVersion < 9` 分支正确；新安装走 `onCreate` 也包含新列；`getWalletsSummary` 查询包含新列
3. **模型完整性**：`toEncryptedMap`/`fromEncryptedMap`/`fromEncryptedMapSummary` 三条路径都处理了 `isArchived`、`cardCategory`、`tags`；`tags` 的 JSON 编解码 + 加密/解密正确
4. **代码引用**：所有使用 `CardUtils.networkDisplayName()` 的位置已改为 `networkDisplayNameLocalized(network, l)`；无残留硬编码 `'MASTERCARD'` 字符串
5. **归档逻辑**：正常视图不显示已归档卡片；归档视图不显示活跃卡片；归档操作不触发硬删除；永久删除操作有二次确认 + 指纹/PIN 验证
6. **分组排序**：按 issuer 分组后 header 不可拖拽；card 可拖拽；`onReorder` 索引转换正确；重排后 orderIndex 更新
7. **筛选逻辑**：三个筛选条件 AND 组合；发卡行列表从当前卡片动态提取；筛选与搜索、分组协同工作
8. **表单校验**：FocusNode 在 `initState` 创建、`dispose` 释放；校验在失焦时触发而非每次按键；保存时仍有 `validate()`；有效期月份 01-12 校验生效
9. **下拉框尺寸**：`_buildDropdown` 与 `_buildTextField` 的高度、padding、圆角一致
10. **CVV 复制**：复制按钮已移除；点击 CVV 文字可复制；保留可见性切换
11. **卡片显示**：掩码时显示前4+后4；卡类别标签和自定义标签在卡片上可见；标签为空时不显示标签区域
12. **Provider 通知**：归档/取消归档后 `notifyListeners()` 被调用；`AutoBackupService.triggerBackup()` 被调用
13. **`const`** **声明**：本地化的 UI 字符串未在 `const` 上下文中使用（遵循项目经验）

***

## 验证方法

1. **本地运行**：`flutter run` 在模拟器/真机上验证
2. **DB 迁移**：在已有数据的应用上升级，验证旧数据不丢失、新字段默认值正确
3. **添加卡片**：填写卡类别、标签，保存后在首页验证显示
4. **编辑卡片**：验证下拉框尺寸一致、校验时机正确
5. **归档流程**：归档卡片 → 切换到归档视图 → 验证显示 → 取消归档 → 验证回到主列表
6. **永久删除**：在归档视图中永久删除 → 验证二次确认 → 验证卡片消失
7. **筛选**：组合使用卡组织+发卡行+类型筛选，验证结果正确
8. **分组**：验证同发卡行卡片在一起，拖拽排序正常
9. **有效期校验**：输入 "2320" 验证报错，输入 "1225" 验证通过
10. **CI 构建**：推送后验证 GitHub Actions 构建通过

