import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:aniways/core/services/backup_restore_service.dart';
import 'package:aniways/core/services/saf_storage_service.dart';
import 'package:aniways/core/storage/shared_preferences_service.dart';
import 'package:aniways/core/theme/category_colors.dart';
import 'package:aniways/core/widgets/aniways_snackbar.dart';
import 'package:aniways/screens/onboarding/widgets/onboarding_card_scaffold.dart';

/// Step 3: Backup folder and automatic backup frequency.
class BackupSetupCard extends StatefulWidget {
  const BackupSetupCard({super.key});

  @override
  State<BackupSetupCard> createState() => _BackupSetupCardState();
}

class _BackupSetupCardState extends State<BackupSetupCard> {
  final SharedPreferencesService _prefs = SharedPreferencesService();
  final BackupRestoreService _backupService = BackupRestoreService.instance;

  late String _frequency;
  String? _displayFolder;

  static const _frequencies = [
    (
      'daily',
      'Daily',
      'Once every 24 hours. Recommended.',
      Icons.today_rounded,
    ),
    ('weekly', 'Weekly', 'Once every 7 days', Icons.date_range_rounded),
    ('off', 'Off', 'Only when you back up manually', Icons.block_rounded),
  ];

  @override
  void initState() {
    super.initState();
    // Default to daily on first run, as recommended.
    if (_prefs.autoBackupFrequency == 'off') {
      _prefs.setAutoBackupFrequency('daily');
      _frequency = 'daily';
    } else {
      _frequency = _prefs.autoBackupFrequency;
    }
    _displayFolder = _backupService.getBackupLocationDisplayName();
  }

  void _refreshFolder() {
    setState(() {
      _displayFolder = _backupService.getBackupLocationDisplayName();
    });
  }

  Future<void> _pickFolder() async {
    HapticFeedback.lightImpact();
    try {
      if (Platform.isAndroid) {
        final res = await SafStorageService.instance.pickDirectory();
        if (res != null) {
          final treeUri = res['treeUri']!;
          final displayPath = res['displayPath']!;
          await _prefs.setBackupTreeUri(treeUri);
          await _prefs.setBackupDirectoryPath(displayPath);
          _refreshFolder();
          if (mounted) {
            AniwaysSnackBar.show(
              context,
              message: 'Backup folder selected: $displayPath',
              icon: Icons.folder_open_rounded,
            );
          }
        }
      } else {
        final selectedPath = await FilePicker.getDirectoryPath(
          dialogTitle: 'Select Backup Folder',
        );
        if (selectedPath != null && selectedPath.trim().isNotEmpty) {
          await _prefs.setBackupDirectoryPath(selectedPath);
          _refreshFolder();
          if (mounted) {
            AniwaysSnackBar.show(
              context,
              message: 'Backup folder selected',
              icon: Icons.folder_open_rounded,
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        AniwaysSnackBar.error(context, message: 'Failed to choose folder: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cat = CategoryColors.of(context);

    return OnboardingPage(
      title: 'Keep your library safe',
      subtitle: 'Choose where Aniways saves backups of your library and watch history.',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OnboardingSection(
            title: 'Backup folder',
            child: OnboardingGroup(
              tiles: [
                OnboardingTile(
                  icon: Icons.folder_rounded,
                  color: cat.backup,
                  title: _displayFolder ?? 'Aniways/backups',
                  subtitle: 'Tap to choose a different folder',
                  onTap: _pickFolder,
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          OnboardingSection(
            title: 'Automatic backups',
            child: OnboardingGroup(
              tiles: [
                for (final (value, title, subtitle, icon) in _frequencies)
                  OnboardingTile(
                    icon: icon,
                    color: cat.backup,
                    title: title,
                    subtitle: subtitle,
                    selected: _frequency == value,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _frequency = value);
                      _prefs.setAutoBackupFrequency(value);
                    },
                  ),
              ],
            ),
          ),
          const OnboardingNote(
            icon: Icons.lock_outline_rounded,
            text: 'Backups stay on your device. Your library and watch history are never shared unless you choose to.',
          ),
        ],
      ),
    );
  }
}
