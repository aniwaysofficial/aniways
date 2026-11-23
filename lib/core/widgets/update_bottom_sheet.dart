import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import 'package:aniways/core/services/app_info_service.dart';
import 'package:aniways/core/update/update_installer.dart';
import 'package:aniways/core/update/update_models.dart';
import 'package:aniways/core/update/update_service.dart';
import 'package:aniways/core/widgets/one_ui_bottom_sheet.dart';

/// One UI styled bottom sheet that presents app update details,
/// formats GitHub markdown changelogs, and handles in-app download & installation.
class UpdateBottomSheet extends StatefulWidget {
  const UpdateBottomSheet({
    super.key,
    required this.release,
  });

  final AppRelease release;

  /// Convenience helper to show the update sheet in a modal bottom sheet.
  static Future<void> show(BuildContext context, AppRelease release) {
    return showOneUiBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => UpdateBottomSheet(release: release),
    );
  }

  @override
  State<UpdateBottomSheet> createState() => _UpdateBottomSheetState();
}

class _UpdateBottomSheetState extends State<UpdateBottomSheet> {
  bool _isDownloading = false;
  DownloadProgress? _progress;
  File? _downloadedApk;
  String? _errorMessage;
  CancelToken? _cancelToken;

  @override
  void dispose() {
    _cancelToken?.cancel();
    super.dispose();
  }

  void _cancelDownload() {
    _cancelToken?.cancel();
    setState(() {
      _isDownloading = false;
      _progress = null;
      _cancelToken = null;
    });
  }

  Future<void> _startAndroidDownload(ReleaseAsset asset) async {
    setState(() {
      _isDownloading = true;
      _errorMessage = null;
      _progress = const DownloadProgress(receivedBytes: 0, totalBytes: 0);
      _cancelToken = CancelToken();
    });

    try {
      final file = await UpdateService.instance.downloadUpdate(
        asset: asset,
        cancelToken: _cancelToken,
        onProgress: (p) {
          if (mounted) {
            setState(() => _progress = p);
          }
        },
      );

      if (!mounted) return;

      if (file != null) {
        setState(() {
          _isDownloading = false;
          _downloadedApk = file;
        });

        // Trigger installation automatically
        await _triggerInstall(file.path);
      } else {
        setState(() {
          _isDownloading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isDownloading = false;
        _errorMessage = 'Download failed: $e';
      });
    }
  }

  Future<void> _triggerInstall(String filePath) async {
    final canInstall = await UpdateInstaller.canRequestPackageInstalls();
    if (!canInstall && mounted) {
      final shouldOpenSettings = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Permission Required'),
          content: const Text(
            'To install updates directly, allow Aniways to install unknown apps in system settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );

      if (shouldOpenSettings == true) {
        await UpdateInstaller.openInstallPermissionSettings();
      }
      return;
    }

    await UpdateInstaller.installApk(filePath);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final currentVersion = AppInfoService.instance.version;
    final asset = widget.release.matchingAsset;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return PopScope(
      canPop: !_isDownloading,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isDownloading) {
          _cancelDownload();
          Navigator.pop(context);
        }
      },
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 8, 20, bottomPadding + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const OneUiDragHandle(margin: EdgeInsets.only(bottom: 16)),

            // ── Glowing Header Icon ──
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.28),
                    blurRadius: 18,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.rocket_launch_rounded,
                color: cs.onPrimaryContainer,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),

            // ── Headline & Version Transition Pill ──
            Text(
              'Update Available!',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.35),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'v$currentVersion',
                    style: TextStyle(
                      fontSize: 13,
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: cs.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'v${widget.release.version}',
                    style: TextStyle(
                      fontSize: 13,
                      color: cs.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),

            // ── Metadata Text ──
            Text(
              'Released ${widget.release.relativeDate}${asset != null && asset.formattedSize.isNotEmpty ? ' · ${asset.formattedSize}' : ''}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant.withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(height: 16),

            // ── Markdown Release Notes Box ──
            Flexible(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 220),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.25),
                    width: 0.8,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.auto_awesome_rounded,
                              size: 16,
                              color: cs.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "What's New",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: cs.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        MarkdownBody(
                          data: widget.release.changelog.trim().isNotEmpty
                              ? widget.release.changelog
                              : '• General stability and performance improvements.',
                          selectable: false,
                          styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                            p: theme.textTheme.bodyMedium?.copyWith(
                              color: cs.onSurface,
                              height: 1.45,
                              fontSize: 13,
                            ),
                            h1: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: cs.primary,
                            ),
                            h2: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: cs.primary,
                            ),
                            h3: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                            ),
                            listBullet: TextStyle(
                              color: cs.primary,
                              fontWeight: FontWeight.bold,
                            ),
                            code: TextStyle(
                              backgroundColor: cs.surfaceContainerHighest,
                              color: cs.onSurface,
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                            codeblockDecoration: BoxDecoration(
                              color: cs.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onTapLink: (text, href, title) {
                            if (href != null) {
                              UpdateInstaller.openReleaseUrl(href);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: cs.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 16,
                      color: cs.onErrorContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 18),

            // ── Primary Interactive Action Area ──
            _buildActionArea(context, cs, asset),

            // ── Secondary GitHub Link ──
            const SizedBox(height: 4),
            TextButton(
              onPressed: () {
                UpdateInstaller.openReleaseUrl(widget.release.htmlUrl);
              },
              child: Text(
                'View on GitHub',
                style: TextStyle(
                  fontSize: 13,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionArea(
    BuildContext context,
    ColorScheme cs,
    ReleaseAsset? asset,
  ) {
    // 1. Android downloading state with live animated progress
    if (_isDownloading) {
      final p = _progress;
      final progressVal = p?.progress;
      final percent = p?.percentage ?? 0;
      final receivedMb = p?.formattedReceived ?? '0';
      final totalMb = p?.formattedTotal ?? '?';

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: cs.outlineVariant.withValues(alpha: 0.35),
            width: 0.8,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Downloading update... ($percent%)',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: _cancelDownload,
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Cancel download',
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progressVal,
                minHeight: 6,
                backgroundColor: cs.outlineVariant.withValues(alpha: 0.25),
              ),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '$receivedMb MB / $totalMb MB',
                style: TextStyle(
                  fontSize: 11,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // 2. Android: APK already downloaded and ready to install
    if (_downloadedApk != null) {
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: FilledButton.icon(
          onPressed: () {
            HapticFeedback.lightImpact();
            _triggerInstall(_downloadedApk!.path);
          },
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          icon: const Icon(Icons.install_mobile_rounded),
          label: const Text(
            'Install Now',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ),
      );
    }

    // 3. Android: APK available for download
    if (Platform.isAndroid && asset != null) {
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: FilledButton.icon(
          onPressed: () {
            HapticFeedback.lightImpact();
            _startAndroidDownload(asset);
          },
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          icon: const Icon(Icons.download_rounded),
          label: Text(
            _errorMessage != null ? 'Retry Download' : 'Download & Install',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ),
      );
    }

    // 4. Non-Android platforms (Windows, macOS, Linux, iOS) or fallback
    String label = 'View Release on GitHub';
    IconData icon = Icons.open_in_browser_rounded;
    String targetUrl = widget.release.htmlUrl;

    if (Platform.isWindows) {
      label = asset != null ? 'Download for Windows' : 'View Windows Release';
      icon = Icons.desktop_windows_rounded;
      targetUrl = asset?.downloadUrl ?? widget.release.htmlUrl;
    } else if (Platform.isLinux) {
      label = asset != null ? 'Download for Linux' : 'View Linux Release';
      icon = Icons.terminal_rounded;
      targetUrl = asset?.downloadUrl ?? widget.release.htmlUrl;
    } else if (Platform.isMacOS) {
      label = asset != null ? 'Download for macOS' : 'View macOS Release';
      icon = Icons.laptop_mac_rounded;
      targetUrl = asset?.downloadUrl ?? widget.release.htmlUrl;
    }

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: FilledButton.icon(
        onPressed: () {
          HapticFeedback.lightImpact();
          UpdateInstaller.openReleaseUrl(targetUrl);
        },
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: Icon(icon),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
    );
  }
}

