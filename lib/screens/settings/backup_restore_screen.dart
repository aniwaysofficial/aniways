import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:aniways/core/database/repositories/watch_repository.dart';
import 'package:aniways/core/helpers.dart';
import 'package:aniways/core/services/backup_restore_service.dart';
import 'package:aniways/core/services/image_cache_service.dart';
import 'package:aniways/core/services/saf_storage_service.dart';
import 'package:aniways/core/storage/shared_preferences_service.dart';
import 'package:aniways/core/theme/category_colors.dart';
import 'package:aniways/core/widgets/aniways_snackbar.dart';
import 'package:aniways/core/widgets/one_ui_bottom_sheet.dart';
import 'package:aniways/core/widgets/one_ui_scroll_view.dart';
import 'package:aniways/providers/theme_provider.dart';
import 'package:aniways/screens/settings/settings_components.dart';
import 'package:aniways/screens/settings/widgets/restore_summary_sheet.dart';

/// Settings screen for exporting/restoring `.hnm` backups, automated backups,
/// and storage/cache management.
class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  final SharedPreferencesService _prefs = SharedPreferencesService();
  final ImageCacheService _cacheService = ImageCacheService.instance;
  final BackupRestoreService _backupService = BackupRestoreService.instance;

  int _cacheSizeBytes = 0;
  bool _isLoadingCacheSize = true;

  String _backupDirPath = '';
  List<BackupItem> _existingBackups = [];

  @override
  void initState() {
    super.initState();
    _loadCacheSize();
    _loadBackupDirectoryAndList();
  }

  Future<void> _loadCacheSize() async {
    setState(() => _isLoadingCacheSize = true);
    final size = await _cacheService.getCacheSizeBytes();
    if (mounted) {
      setState(() {
        _cacheSizeBytes = size;
        _isLoadingCacheSize = false;
      });
    }
  }

  Future<void> _loadBackupDirectoryAndList() async {
    final displayName = _backupService.getBackupLocationDisplayName();
    final backups = await _backupService.getExistingBackups();
    if (mounted) {
      setState(() {
        _backupDirPath = displayName;
        _existingBackups = backups;
      });
    }
  }

  String _displayShortPath([String? path]) {
    return _backupService.getBackupLocationDisplayName();
  }

  Future<bool> _chooseBackupDirectory() async {
    try {
      if (Platform.isAndroid) {
        final res = await SafStorageService.instance.pickDirectory();
        if (res != null) {
          final treeUri = res['treeUri']!;
          final displayPath = res['displayPath']!;
          await _prefs.setBackupTreeUri(treeUri);
          await _prefs.setBackupDirectoryPath(displayPath);
          await _loadBackupDirectoryAndList();
          if (mounted) {
            AniwaysSnackBar.show(
              context,
              message: 'Backup location: $displayPath',
              icon: Icons.folder_open_rounded,
            );
          }
          return true;
        }
        return false;
      } else {
        final selectedPath = await FilePicker.getDirectoryPath(
          dialogTitle: 'Select Backup Folder',
        );
        if (selectedPath != null && selectedPath.trim().isNotEmpty) {
          await _prefs.setBackupDirectoryPath(selectedPath);
          await _loadBackupDirectoryAndList();
          if (mounted) {
            AniwaysSnackBar.show(
              context,
              message: 'Backup location: ${_displayShortPath(selectedPath)}',
              icon: Icons.folder_open_rounded,
            );
          }
          return true;
        }
      }
    } catch (e) {
      if (mounted) {
        AniwaysSnackBar.error(context, message: 'Failed to select folder: $e');
      }
    }
    return false;
  }

  Future<bool> _ensureBackupFolderConfigured(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    final custom = _prefs.backupDirectoryPath;
    if (custom != null && custom.isNotEmpty) {
      return true;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Use Default'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogCtx, true),
            icon: const Icon(Icons.folder_open_rounded, size: 18),
            label: const Text('Choose Folder'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _chooseBackupDirectory();
      return true;
    } else if (confirmed == false) {
      return true;
    }
    return false;
  }

  void _showLocationPickerSheet(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cat = CategoryColors.of(context);
    final isCustom =
        _prefs.backupDirectoryPath != null &&
        _prefs.backupDirectoryPath!.isNotEmpty;

    showOneUiBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useRootNavigator: false,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              4,
              20,
              MediaQuery.viewPaddingOf(sheetContext).bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: cat.backup.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.folder_outlined,
                        color: cat.backup,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Backup Location',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Folder where backups are automatically and manually saved',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.folder_open_rounded,
                        size: 20,
                        color: isCustom ? cs.primary : cs.outline,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isCustom ? _backupDirPath : 'Not configured yet\nSelect a folder on your device (e.g. Documents/Aniways)',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: isCustom
                                ? cs.onSurface
                                : cs.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () async {
                    Navigator.pop(sheetContext);
                    await _chooseBackupDirectory();
                  },
                  icon: const Icon(Icons.folder_shared_outlined, size: 20),
                  label: Text(isCustom ? 'Change Folder' : 'Select Folder'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                if (isCustom) ...[
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.pop(sheetContext);
                      await _prefs.setBackupDirectoryPath(null);
                      await _loadBackupDirectoryAndList();
                      if (context.mounted) {
                        AniwaysSnackBar.show(
                          context,
                          message: 'Reset to default backup folder',
                          icon: Icons.restart_alt_rounded,
                        );
                      }
                    },
                    icon: const Icon(Icons.restart_alt_rounded, size: 20),
                    label: const Text('Reset to Default Folder'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // 1. Create Backup Dialog / Sheet
  // ═══════════════════════════════════════════════════════════════════════

  void _showCreateBackupSheet(BuildContext context) {
    var incLibrary = true;
    var incProgress = true;
    var incSettings = true;
    var isExporting = false;

    showOneUiBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useRootNavigator: false,
      builder: (sheetContext) {
        final cs = Theme.of(sheetContext).colorScheme;
        final cat = CategoryColors.of(sheetContext);

        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  4,
                  20,
                  MediaQuery.viewPaddingOf(sheetContext).bottom + 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: cat.backup.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.file_upload_outlined,
                            color: cat.backup,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Create Backup',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'Saves directly to ${_displayShortPath(_backupDirPath)}',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Include in backup',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _ModalCheckbox(
                      value: incLibrary,
                      onChanged: (v) =>
                          setModalState(() => incLibrary = v ?? false),
                      title: 'Library & Collections',
                      subtitle:
                          'Favorites, Watching, Plan to Watch, custom lists',
                      color: cat.backup,
                      isFirst: true,
                      isLast: false,
                    ),
                    const SizedBox(height: 2),
                    _ModalCheckbox(
                      value: incProgress,
                      onChanged: (v) =>
                          setModalState(() => incProgress = v ?? false),
                      title: 'Watch Progress & History',
                      subtitle:
                          'Episode timestamps, watched marks, and history',
                      color: cat.playback,
                      isFirst: false,
                      isLast: false,
                    ),
                    const SizedBox(height: 2),
                    _ModalCheckbox(
                      value: incSettings,
                      onChanged: (v) =>
                          setModalState(() => incSettings = v ?? false),
                      title: 'Settings & Preferences',
                      subtitle:
                          'Appearance theme, player gestures, audio defaults',
                      color: cat.appearance,
                      isFirst: false,
                      isLast: true,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed:
                          isExporting ||
                              (!incLibrary && !incProgress && !incSettings)
                          ? null
                          : () async {
                              setModalState(() => isExporting = true);
                              // Dismiss the sheet so it never blocks the UI or hides dialogs/snackbars
                              if (sheetContext.mounted) {
                                Navigator.pop(sheetContext);
                              }

                              try {
                                final backupItem = await _backupService
                                    .createBackup(
                                      includeLibrary: incLibrary,
                                      includeProgress: incProgress,
                                      includeSettings: incSettings,
                                    );
                                await _loadBackupDirectoryAndList();
                                if (context.mounted) {
                                  final fileName = backupItem.name;
                                  AniwaysSnackBar.success(
                                    context,
                                    message: 'Backup saved: $fileName',
                                    actionLabel: 'Share',
                                    onAction: () => _backupService
                                        .shareBackupItem(backupItem),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  AniwaysSnackBar.error(
                                    context,
                                    message: 'Failed to create backup: $e',
                                  );
                                }
                              }
                            },
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: isExporting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                strokeCap: StrokeCap.round,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_alt_rounded, size: 20),
                      label: Text(
                        isExporting
                            ? 'Creating Backup...'
                            : 'Create Backup (.anw)',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // 2. Restore Backup Dialog / Sheet
  // ═══════════════════════════════════════════════════════════════════════

  void _onTapRestore(BuildContext context) {
    if (_existingBackups.isEmpty) {
      _pickAndRestoreBackup();
    } else {
      _showRestorePickerSheet(context);
    }
  }

  Future<void> _pickAndRestoreBackup() async {
    try {
      final file = await FilePicker.pickFile(type: FileType.any);

      if (file == null) return;
      final fileName = file.name.toLowerCase();
      final filePath = file.path;

      if (!fileName.endsWith('.anw') &&
          !fileName.endsWith('.hnm') &&
          !fileName.endsWith('.json') &&
          (filePath == null ||
              (!filePath.toLowerCase().endsWith('.anw') &&
                  !filePath.toLowerCase().endsWith('.hnm') &&
                  !filePath.toLowerCase().endsWith('.json')))) {
        if (!mounted) return;
        AniwaysSnackBar.error(
          context,
          message: 'Please select a valid Aniways backup file (.anw)',
        );
        return;
      }

      if (!mounted) return;
      if (filePath == null) {
        throw const FormatException('Could not resolve selected file path.');
      }
      final summary = await _backupService.readBackupFromFile(filePath);

      if (!mounted) return;
      _showRestoreSummarySheet(context, summary);
    } catch (e) {
      if (!mounted) return;
      AniwaysSnackBar.error(context, message: 'Could not read backup file: $e');
    }
  }

  void _showRestorePickerSheet(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cat = CategoryColors.of(context);

    showOneUiBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useRootNavigator: false,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  4,
                  20,
                  MediaQuery.viewPaddingOf(sheetContext).bottom + 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: cat.accounts.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.file_download_outlined,
                            color: cat.accounts,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Restore Backup',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'Select a backup from your storage',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: () async {
                        Navigator.pop(sheetContext);
                        await _pickAndRestoreBackup();
                      },
                      icon: const Icon(Icons.file_open_outlined, size: 20),
                      label: const Text('Browse Other Files...'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Backups in ${_displayShortPath(_backupDirPath)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (var i = 0; i < _existingBackups.length; i++) ...[
                      if (i > 0) const SizedBox(height: 2),
                      _BackupFileTile(
                        item: _existingBackups[i],
                        isFirst: i == 0,
                        isLast: i == _existingBackups.length - 1,
                        onTap: () async {
                          Navigator.pop(sheetContext);
                          try {
                            final summary = await _backupService
                                .readBackupFromItem(_existingBackups[i]);
                            if (context.mounted) {
                              _showRestoreSummarySheet(context, summary);
                            }
                          } catch (e) {
                            if (context.mounted) {
                              AniwaysSnackBar.error(
                                context,
                                message: 'Could not read backup file: $e',
                              );
                            }
                          }
                        },
                        onDelete: () async {
                          final item = _existingBackups[i];
                          final confirmed = await showDialog<bool>(
                            context: sheetContext,
                            builder: (ctx) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              title: const Text('Delete Backup?'),
                              content: Text(
                                'Delete ${item.name}? This action cannot be undone.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .error,
                                  ),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                          if (confirmed == true) {
                            await _backupService.deleteBackupItem(item);
                            await _loadBackupDirectoryAndList();
                            setModalState(() {});
                          }
                        },
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showRestoreSummarySheet(BuildContext context, BackupSummary summary) {
    showRestoreSummarySheet(
      context: context,
      summary: summary,
      hideMergeOption: false,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // 3. Maintenance Actions (Clear Cache, Clear History, Reset Settings)
  // ═══════════════════════════════════════════════════════════════════════

  Future<void> _confirmClearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Clear Image Cache?'),
        content: Text(
          'This will remove all downloaded poster covers, banners, and thumbnails (${ImageCacheService.formatBytes(_cacheSizeBytes)}). They will automatically reload as you browse.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _cacheService.clearCache();
      await _loadCacheSize();
      if (mounted) {
        AniwaysSnackBar.show(
          context,
          message: 'Image cache cleared successfully!',
          icon: Icons.cleaning_services_rounded,
        );
      }
    }
  }

  Future<void> _confirmClearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Clear Watch History?'),
        content: const Text(
          'This will clear episode playback progress and remove all items from Continue Watching. Your library collections will remain safe.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Clear History'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await WatchRepository.instance.clearAllWatchHistory();
      if (mounted) {
        AniwaysSnackBar.show(
          context,
          message: 'Watch history cleared!',
          icon: Icons.history_rounded,
        );
      }
    }
  }

  Future<void> _confirmResetSettings() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Reset Settings to Default?'),
        content: const Text(
          'This will revert all appearance, player controls, gestures, and playback preferences back to their factory defaults. Your anime library and history will remain safe.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Reset Settings'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _prefs.resetSettingsToDefault();
      if (mounted) {
        context.read<ThemeProvider>().reload();
        setState(() {});
        AniwaysSnackBar.show(
          context,
          message: 'Settings have been reset to default!',
          icon: Icons.restore_rounded,
        );
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Main Build
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final cat = CategoryColors.of(context);

    final maxCacheMb = _prefs.maxImageCacheMb;
    final autoFreq = _prefs.autoBackupFrequency;
    final maxAutoBackups = _prefs.maxAutoBackups;

    final autoFreqLabel = switch (autoFreq) {
      'daily' => 'Daily',
      'weekly' => 'Weekly',
      _ => 'Off',
    };

    final cacheSizeText = _isLoadingCacheSize
        ? 'Calculating...'
        : '${ImageCacheService.formatBytes(_cacheSizeBytes)} cached';

    final restoreSubtitle = _existingBackups.isNotEmpty
        ? '${_existingBackups.length} local ${_existingBackups.length == 1 ? 'backup' : 'backups'} found'
        : 'Import from a backup file';

    return Scaffold(
      body: OneUiScrollView(
        title: 'Backup & Restore',
        showBackButton: !widget.embedded,
        bottomPadding: MediaQuery.viewPaddingOf(context).bottom + 24,
        children: [
          // ── 1. Backup & Restore ───────────────────────────────────────────
          const SettingsSectionHeader('Backup & Restore'),
          Padding(
            padding: kSettingsHorizontalPadding,
            child: Column(
              children: [
                SettingsActionTile(
                  icon: Icons.file_upload_outlined,
                  color: cat.backup,
                  title: 'Create Backup',
                  subtitle: 'Export library, progress, and settings to a file',
                  isFirst: true,
                  isLast: false,
                  onTap: () async {
                    final hasFolder = await _ensureBackupFolderConfigured(
                      context,
                      title: 'Select Backup Folder',
                      message: 'Please choose a folder on your device (e.g. Documents/Aniways) where your backups will be saved. Backups in this folder remain safe even if Aniways is reinstalled.',
                    );
                    if (hasFolder && context.mounted) {
                      _showCreateBackupSheet(context);
                    }
                  },
                ),
                const SizedBox(height: 2),
                SettingsActionTile(
                  icon: Icons.file_download_outlined,
                  color: cat.accounts,
                  title: 'Restore Backup',
                  subtitle: restoreSubtitle,
                  isFirst: false,
                  isLast: true,
                  onTap: () => _onTapRestore(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── 2. Automated Backups ──────────────────────────────────────────
          const SettingsSectionHeader('Automated Backups'),
          Padding(
            padding: kSettingsHorizontalPadding,
            child: Column(
              children: [
                SettingsActionTile(
                  icon: Icons.folder_outlined,
                  color: cat.backup,
                  title: 'Backup Location',
                  subtitle: _displayShortPath(_backupDirPath),
                  isFirst: true,
                  isLast: false,
                  onTap: () => _showLocationPickerSheet(context),
                ),
                const SizedBox(height: 2),
                SettingsSelectorTile<String>(
                  icon: Icons.sync_rounded,
                  color: cat.backup,
                  title: 'Auto-Backup Frequency',
                  subtitle: autoFreq == 'off' ? 'Off' : 'Every $autoFreqLabel',
                  currentValue: autoFreq,
                  options: const [
                    SettingsOption(
                      'off',
                      'Off',
                      'Disable automatic backups (manual only)',
                    ),
                    SettingsOption(
                      'daily',
                      'Daily',
                      'Create a backup once every day',
                    ),
                    SettingsOption(
                      'weekly',
                      'Weekly',
                      'Create a backup once a week',
                    ),
                  ],
                  isFirst: false,
                  isLast: false,
                  onSelected: (val) async {
                    if (val != 'off') {
                      final hasFolder = await _ensureBackupFolderConfigured(
                        context,
                        title: 'Select Backup Folder',
                        message: 'To enable automatic backups, please choose a folder on your device (e.g. Documents/Aniways) where automatic backups will be saved.',
                      );
                      if (!hasFolder) return;
                    }
                    await _prefs.setAutoBackupFrequency(val);
                    setState(() {});
                  },
                ),
                const SizedBox(height: 2),
                SettingsSelectorTile<int>(
                  icon: Icons.folder_copy_outlined,
                  color: cat.accounts,
                  title: 'Saved Backups Limit',
                  subtitle: '$maxAutoBackups backups',
                  currentValue: maxAutoBackups,
                  options: const [
                    SettingsOption(
                      3,
                      '3 backups',
                      'Keep the 3 most recent automatic backups',
                    ),
                    SettingsOption(
                      5,
                      '5 backups',
                      'Keep the 5 most recent automatic backups',
                    ),
                    SettingsOption(
                      10,
                      '10 backups',
                      'Keep the 10 most recent automatic backups',
                    ),
                  ],
                  isFirst: false,
                  isLast: true,
                  onSelected: (val) async {
                    await _prefs.setMaxAutoBackups(val);
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── 3. Storage & Cache ────────────────────────────────────────────
          const SettingsSectionHeader('Storage & Cache'),
          Padding(
            padding: kSettingsHorizontalPadding,
            child: Column(
              children: [
                SettingsSelectorTile<int>(
                  icon: Icons.storage_rounded,
                  color: cat.downloads,
                  title: 'Max Image Cache Size',
                  subtitle: maxCacheMb >= 1000 ? '1 GB' : '$maxCacheMb MB',
                  currentValue: maxCacheMb,
                  options: const [
                    SettingsOption(
                      100,
                      '100 MB',
                      'Compact cache for limited storage',
                    ),
                    SettingsOption(
                      250,
                      '250 MB (Recommended)',
                      'Balanced size for smooth browsing',
                    ),
                    SettingsOption(
                      500,
                      '500 MB',
                      'Large cache for extensive browsing',
                    ),
                    SettingsOption(
                      1000,
                      '1 GB',
                      'Maximum cache size for heavy libraries',
                    ),
                  ],
                  isFirst: true,
                  isLast: false,
                  onSelected: (val) async {
                    await _prefs.setMaxImageCacheMb(val);
                    await _cacheService.enforceCacheLimit();
                    await _loadCacheSize();
                    setState(() {});
                  },
                ),
                const SizedBox(height: 2),
                SettingsActionTile(
                  icon: Icons.cleaning_services_rounded,
                  color: cat.appearance,
                  title: 'Clear Image Cache',
                  subtitle: cacheSizeText,
                  isFirst: false,
                  isLast: false,
                  onTap: _confirmClearCache,
                ),
                const SizedBox(height: 2),
                SettingsActionTile(
                  icon: Icons.history_toggle_off_rounded,
                  color: Colors.amber.shade700,
                  title: 'Clear Watch History',
                  subtitle: 'Reset playback progress and continue watching',
                  isFirst: false,
                  isLast: false,
                  onTap: _confirmClearHistory,
                ),
                const SizedBox(height: 2),
                SettingsActionTile(
                  icon: Icons.restart_alt_rounded,
                  color: Theme.of(context).colorScheme.error,
                  title: 'Reset Settings to Default',
                  subtitle: 'Revert theme and player preferences',
                  isFirst: false,
                  isLast: true,
                  onTap: _confirmResetSettings,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// Helper UI Widgets
// ═════════════════════════════════════════════════════════════════════════

class _ModalCheckbox extends StatelessWidget {
  const _ModalCheckbox({
    required this.value,
    required this.onChanged,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.isFirst,
    required this.isLast,
  });

  final bool value;
  final ValueChanged<bool?>? onChanged;
  final String title;
  final String subtitle;
  final Color color;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: cs.surfaceContainerHigh,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: settingsTileBorderRadius(
          isFirst: isFirst,
          isLast: isLast,
        ),
      ),
      child: CheckboxListTile(
        value: value,
        onChanged: onChanged,
        activeColor: color,
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: cs.onSurface,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
        ),
        controlAffinity: ListTileControlAffinity.trailing,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      ),
    );
  }
}

class _BackupFileTile extends StatelessWidget {
  const _BackupFileTile({
    required this.item,
    required this.isFirst,
    required this.isLast,
    required this.onTap,
    required this.onDelete,
  });

  final BackupItem item;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cat = CategoryColors.of(context);
    final fileName = item.name;
    final isAuto = fileName.contains('auto');

    final modTime = item.lastModified;
    final sizeBytes = item.sizeBytes;

    final dateStr = modTime != null ? formatShortDateTime(modTime) : '';
    final sizeStr = ImageCacheService.formatBytes(sizeBytes);

    return Material(
      color: cs.surfaceContainerHigh,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: settingsTileBorderRadius(
          isFirst: isFirst,
          isLast: isLast,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: SettingsTileIcon(
          icon: isAuto ? Icons.sync_rounded : Icons.save_rounded,
          color: isAuto ? cat.backup : cat.accounts,
        ),
        title: Text(
          fileName,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13.5,
            color: cs.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '$dateStr · $sizeStr',
          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                Icons.delete_outline_rounded,
                size: 20,
                color: cs.onSurfaceVariant,
              ),
              tooltip: 'Delete',
              onPressed: onDelete,
            ),
            Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
