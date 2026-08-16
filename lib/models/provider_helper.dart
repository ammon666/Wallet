import 'package:flutter/material.dart';
import 'package:wallet/models/db_helper.dart';
import 'package:wallet/services/auto_backup_service.dart';

class WalletProvider with ChangeNotifier {
  List<Wallet> wallets = [];
  List<Wallet> archivedWallets = [];

  Future<void> fetchWallets() async {
    wallets = await DatabaseHelper.instance.getWalletsSummary();
    // 若用户从未调整过顺序（所有 orderIndex 都相同，默认都是0），
    // 则先按发卡行聚合排序（同发卡行的默认挨在一起），然后依次分配 orderIndex，
    // 之后完全按用户的持久化 orderIndex 展示，不再强行分组。
    if (wallets.isNotEmpty) {
      final firstOid = wallets.first.orderIndex;
      final allSame = wallets.every((w) => w.orderIndex == firstOid);
      if (allSame) {
        wallets.sort((a, b) {
          final ia = (a.issuer ?? '').trim().toLowerCase();
          final ib = (b.issuer ?? '').trim().toLowerCase();
          if (ia != ib) return ia.compareTo(ib);
          // 同发卡行内部保持原有 id 顺序
          return (a.id ?? 0).compareTo(b.id ?? 0);
        });
        for (int i = 0; i < wallets.length; i++) {
          wallets[i].orderIndex = i;
        }
        await DatabaseHelper.instance.updateWalletsOrder(wallets);
      }
    }
    notifyListeners();
  }

  Future<void> fetchArchivedWallets() async {
    archivedWallets = await DatabaseHelper.instance.getArchivedWalletsSummary();
    notifyListeners();
  }

  Future<Wallet?> getWalletDetails(int id) async {
    return await DatabaseHelper.instance.getWalletById(id);
  }

  /// Soft-delete: archive a wallet (can be restored later).
  Future<void> archiveWallet(int id) async {
    await DatabaseHelper.instance.archiveWallet(id);
    wallets.removeWhere((w) => w.id == id);
    notifyListeners();
    AutoBackupService.triggerBackup();
  }

  /// Restore an archived wallet back to the active list.
  Future<void> unarchiveWallet(int id) async {
    await DatabaseHelper.instance.unarchiveWallet(id);
    archivedWallets.removeWhere((w) => w.id == id);
    notifyListeners();
    AutoBackupService.triggerBackup();
  }

  /// Hard-delete: permanently remove a wallet from the database.
  Future<void> deleteWallet(int id) async {
    await DatabaseHelper.instance.deleteWallet(id);
    wallets.removeWhere((w) => w.id == id);
    archivedWallets.removeWhere((w) => w.id == id);
    notifyListeners();
    AutoBackupService.triggerBackup();
  }

  Future<void> reorderWallets(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final wallet = wallets.removeAt(oldIndex);
    wallets.insert(newIndex, wallet);

    // Update order indices internally
    for (int i = 0; i < wallets.length; i++) {
      wallets[i].orderIndex = i;
    }

    await DatabaseHelper.instance.updateWalletsOrder(wallets);
    notifyListeners();
  }

  /// Reorders a display list (which may be filtered/sorted differently from
  /// the internal wallets list) and syncs the new orderIndex back to the
  /// full wallets list, then persists to the database.
  Future<void> reorderDisplayWallets(
      List<Wallet> displayList, int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;
    final wallet = displayList.removeAt(oldIndex);
    displayList.insert(newIndex, wallet);

    // Assign new orderIndex to display wallets (0, 1, 2, ...)
    for (int i = 0; i < displayList.length; i++) {
      displayList[i].orderIndex = i;
    }

    // Sync back to the full wallets list — display wallets get their new
    // orderIndex; non-display wallets get orderIndex starting after the
    // display list to avoid conflicts.
    final displayIds = displayList.map((w) => w.id).toSet();
    int nextIndex = displayList.length;
    for (final w in wallets) {
      if (displayIds.contains(w.id)) {
        final displayIdx =
            displayList.indexWhere((d) => d.id == w.id);
        w.orderIndex = displayList[displayIdx].orderIndex;
      } else {
        w.orderIndex = nextIndex++;
      }
    }

    wallets.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    await DatabaseHelper.instance.updateWalletsOrder(wallets);
    notifyListeners();
  }
}

class PassProvider with ChangeNotifier {
  List<Pass> passes = [];

  Future<void> fetchPasses() async {
    passes = await PassDatabaseHelper.instance.getAllPasses();
    notifyListeners();
  }

  Future<void> deletePass(int id) async {
    await PassDatabaseHelper.instance.deletePass(id);
    passes.removeWhere((p) => p.id == id);
    notifyListeners();
    AutoBackupService.triggerBackup();
  }

  Future<void> reorderPasses(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final pass = passes.removeAt(oldIndex);
    passes.insert(newIndex, pass);

    // Update order indices internally
    for (int i = 0; i < passes.length; i++) {
      passes[i].orderIndex = i;
    }

    await PassDatabaseHelper.instance.updatePassesOrder(passes);
    notifyListeners();
  }

  /// Deep search through all pass fields
  List<Pass> searchPasses(String query) {
    if (query.isEmpty) return passes;
    final lowercaseQuery = query.toLowerCase();

    return passes.where((pass) {
      // Basic fields
      if (pass.organizationName.toLowerCase().contains(lowercaseQuery)) return true;
      if (pass.description != null && pass.description!.toLowerCase().contains(lowercaseQuery)) return true;
      if (pass.logoText != null && pass.logoText!.toLowerCase().contains(lowercaseQuery)) return true;
      if (pass.barcodeValue.toLowerCase().contains(lowercaseQuery)) return true;
      if (pass.barcodeAltText != null && pass.barcodeAltText!.toLowerCase().contains(lowercaseQuery)) return true;

      // Search through dynamic fields
      if (pass.fields != null) {
        for (final section in pass.fields!.values) {
          if (section is List) {
            for (final field in section) {
              if (field is Map) {
                final label = field['label']?.toString() ?? '';
                final value = field['value']?.toString() ?? '';
                if ((label.isNotEmpty && label.toLowerCase().contains(lowercaseQuery)) ||
                    (value.isNotEmpty && value.toLowerCase().contains(lowercaseQuery))) {
                  return true;
                }
              }
            }
          }
        }
      }
      return false;
    }).toList();
  }
}

class IdentityProvider with ChangeNotifier {
  List<IdentityCard> identities = [];

  Future<void> fetchIdentities() async {
    identities = await IdentityDatabaseHelper.instance.getAllIdentities();
    notifyListeners();
  }

  Future<void> deleteIdentity(int id) async {
    await IdentityDatabaseHelper.instance.deleteIdentity(id);
    identities.removeWhere((i) => i.id == id);
    notifyListeners();
    AutoBackupService.triggerBackup();
  }

  Future<void> reorderIdentities(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final card = identities.removeAt(oldIndex);
    identities.insert(newIndex, card);

    for (int i = 0; i < identities.length; i++) {
      identities[i].orderIndex = i;
    }

    await IdentityDatabaseHelper.instance.updateIdentitiesOrder(identities);
    notifyListeners();
  }

  List<IdentityCard> searchIdentities(String query) {
    if (query.isEmpty) return identities;
    final lowercaseQuery = query.toLowerCase();

    return identities.where((card) {
      return card.name.toLowerCase().contains(lowercaseQuery) ||
          card.value.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }
}

