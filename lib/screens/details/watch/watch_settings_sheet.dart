import 'package:better_player/better_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:aniways/core/network/extractor_service.dart';
import 'package:aniways/core/widgets/extension_icon.dart';
import 'package:aniways/core/widgets/one_ui_bottom_sheet.dart';
import 'package:aniways/providers/watch_provider.dart';
import 'package:aniways/screens/settings/extensions/extensions_shared.dart';

/// Categories available in the settings sheet / panel.
enum WatchSettingsCategory { audio, provider, quality, speed, subtitles }

/// Unified bottom sheet / side panel for stream quality, servers, providers, subtitles, and speed.
class WatchSettingsSheet extends StatefulWidget {
  const WatchSettingsSheet({
    super.key,
    required this.wp,
    required this.accent,
    this.isSidePanel = false,
    this.initialCategory = WatchSettingsCategory.provider,
    this.providerOnly = false,
  });

  final WatchProvider wp;
  final Color accent;
  final bool isSidePanel;
  final WatchSettingsCategory initialCategory;
  final bool providerOnly;

  static Future<void> show(
    BuildContext context,
    WatchProvider wp,
    Color accent, {
    WatchSettingsCategory initialCategory = WatchSettingsCategory.provider,
    bool providerOnly = false,
  }) {
    final theme = Theme.of(context);
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    if (isLandscape) {
      return showGeneralDialog<void>(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Dismiss Settings',
        barrierColor: Colors.black54,
        transitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (dialogContext, anim, secAnim) {
          final screenW = MediaQuery.sizeOf(dialogContext).width;
          final panelWidth = (screenW * 0.45).clamp(320.0, 420.0);
          return Theme(
            data: theme,
            child: Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: panelWidth,
                height: double.infinity,
                child: WatchSettingsSheet(
                  wp: wp,
                  accent: accent,
                  isSidePanel: true,
                  initialCategory: initialCategory,
                  providerOnly: providerOnly,
                ),
              ),
            ),
          );
        },
        transitionBuilder: (dialogContext, anim, secAnim, child) {
          final curved = CurvedAnimation(
            parent: anim,
            curve: Curves.easeOutCubic,
          );
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          );
        },
      );
    }

    return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Theme(
        data: theme,
        child: WatchSettingsSheet(
          wp: wp,
          accent: accent,
          initialCategory: initialCategory,
          providerOnly: providerOnly,
        ),
      ),
    );
  }

  @override
  State<WatchSettingsSheet> createState() => _WatchSettingsSheetState();
}

class _WatchSettingsSheetState extends State<WatchSettingsSheet> {
  late WatchSettingsCategory _selectedCategory;
  final ScrollController _tabScrollController = ScrollController();
  final Map<WatchSettingsCategory, GlobalKey> _tabKeys = {
    for (final cat in WatchSettingsCategory.values) cat: GlobalKey(),
  };

  static const _speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
    if (_selectedCategory == WatchSettingsCategory.provider ||
        widget.providerOnly) {
      widget.wp.probeProvidersForCurrentAnime();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scrollToCategory(_selectedCategory, animate: false);
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) {
          _scrollToCategory(_selectedCategory, animate: false);
        }
      });
    });
  }

  @override
  void didUpdateWidget(covariant WatchSettingsSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialCategory != widget.initialCategory) {
      _selectedCategory = widget.initialCategory;
      _scrollToCategory(_selectedCategory, animate: true);
      if (_selectedCategory == WatchSettingsCategory.provider) {
        widget.wp.probeProvidersForCurrentAnime();
      }
    }
  }

  @override
  void dispose() {
    _tabScrollController.dispose();
    super.dispose();
  }

  void _scrollToCategory(
    WatchSettingsCategory category, {
    bool animate = true,
  }) {
    final key = _tabKeys[category];
    final targetContext = key?.currentContext;
    if (targetContext != null && targetContext.mounted) {
      Scrollable.ensureVisible(
        targetContext,
        duration: animate ? const Duration(milliseconds: 260) : Duration.zero,
        curve: Curves.easeOutCubic,
        alignment: 0.5,
      );
    }
  }

  void _onSelectCategory(WatchSettingsCategory category) {
    if (_selectedCategory == category) return;
    setState(() => _selectedCategory = category);
    _scrollToCategory(category, animate: true);
    if (category == WatchSettingsCategory.provider) {
      widget.wp.probeProvidersForCurrentAnime();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.wp,
      builder: (context, _) {
        final theme = Theme.of(context);
        final cs = theme.colorScheme;
        final wp = widget.wp;
        final bottomPad = MediaQuery.viewPaddingOf(context).bottom;

        return Material(
          color: cs.surface,
          shape: widget.isSidePanel
              ? const RoundedRectangleBorder(
                  borderRadius: BorderRadius.horizontal(
                    left: Radius.circular(24),
                  ),
                )
              : const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
          clipBehavior: Clip.antiAlias,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: widget.isSidePanel
                  ? MediaQuery.sizeOf(context).height
                  : MediaQuery.sizeOf(context).height * 0.75,
            ),
            child: Column(
              mainAxisSize: widget.isSidePanel
                  ? MainAxisSize.max
                  : MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle (only for bottom sheet in portrait)
                if (!widget.isSidePanel)
                  const OneUiDragHandle(
                    margin: EdgeInsets.only(top: 12, bottom: 8),
                  ),

                // Header
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    widget.isSidePanel ? 16 : 4,
                    16,
                    8,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        widget.providerOnly
                            ? Icons.dns_rounded
                            : Icons.tune_rounded,
                        color: widget.accent,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        widget.providerOnly
                            ? 'Select Provider'
                            : 'Stream & Player Settings',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),

                if (!widget.providerOnly) ...[
                  // Horizontal Category Tabs
                  SingleChildScrollView(
                    controller: _tabScrollController,
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _CategoryTab(
                          key: _tabKeys[WatchSettingsCategory.provider],
                          label: 'Providers',
                          icon: Icons.dns_outlined,
                          isSelected:
                              _selectedCategory ==
                              WatchSettingsCategory.provider,
                          accent: widget.accent,
                          onTap: () =>
                              _onSelectCategory(WatchSettingsCategory.provider),
                        ),
                        const SizedBox(width: 8),
                        _CategoryTab(
                          key: _tabKeys[WatchSettingsCategory.audio],
                          label: 'Audio',
                          icon: Icons.record_voice_over_rounded,
                          isSelected:
                              _selectedCategory == WatchSettingsCategory.audio,
                          accent: widget.accent,
                          onTap: () =>
                              _onSelectCategory(WatchSettingsCategory.audio),
                        ),
                        const SizedBox(width: 8),
                        _CategoryTab(
                          key: _tabKeys[WatchSettingsCategory.subtitles],
                          label: 'Subtitles',
                          icon: Icons.subtitles_outlined,
                          isSelected:
                              _selectedCategory ==
                              WatchSettingsCategory.subtitles,
                          accent: widget.accent,
                          onTap: () => _onSelectCategory(
                            WatchSettingsCategory.subtitles,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _CategoryTab(
                          key: _tabKeys[WatchSettingsCategory.quality],
                          label: 'Quality & Server',
                          icon: Icons.hd_outlined,
                          isSelected:
                              _selectedCategory ==
                              WatchSettingsCategory.quality,
                          accent: widget.accent,
                          onTap: () =>
                              _onSelectCategory(WatchSettingsCategory.quality),
                        ),
                        const SizedBox(width: 8),
                        _CategoryTab(
                          key: _tabKeys[WatchSettingsCategory.speed],
                          label: 'Speed',
                          icon: Icons.speed_rounded,
                          isSelected:
                              _selectedCategory == WatchSettingsCategory.speed,
                          accent: widget.accent,
                          onTap: () =>
                              _onSelectCategory(WatchSettingsCategory.speed),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),
                  Divider(
                    height: 1,
                    color: cs.outlineVariant.withValues(alpha: 0.2),
                  ),
                ],

                // Selected Category Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPad + 16),
                    child: widget.providerOnly
                        ? _buildProviderSection(wp, cs)
                        : switch (_selectedCategory) {
                            WatchSettingsCategory.audio => _buildAudioSection(
                              wp,
                              cs,
                            ),
                            WatchSettingsCategory.provider =>
                              _buildProviderSection(wp, cs),
                            WatchSettingsCategory.quality =>
                              _buildQualityAndServerSection(wp, cs),
                            WatchSettingsCategory.speed => _buildSpeedSection(
                              wp,
                              cs,
                            ),
                            WatchSettingsCategory.subtitles =>
                              _buildSubtitlesSection(wp, cs),
                          },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQualityAndServerSection(WatchProvider wp, ColorScheme cs) {
    final tracks = wp.availableQualityTracks;
    final streams = wp.watchResult?.playableStreams ?? const [];

    // Filter unique video tracks by height, descending order
    final Map<int, PlayerAsmsTrack> uniqueTracksByHeight = {};
    for (final t in tracks) {
      final h = t.height ?? 0;
      if (h > 0) {
        if (!uniqueTracksByHeight.containsKey(h) ||
            (t.bitrate ?? 0) > (uniqueTracksByHeight[h]?.bitrate ?? 0)) {
          uniqueTracksByHeight[h] = t;
        }
      }
    }
    final sortedHeights = uniqueTracksByHeight.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    final isAuto =
        wp.currentQualityTrack == null ||
        wp.currentQualityTrack == PlayerAsmsTrack.defaultTrack() ||
        (wp.currentQualityTrack?.height ?? 0) == 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Video Resolution / Quality Section ──
        if (tracks.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'VIDEO RESOLUTION',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          Material(
            color: cs.surfaceContainerHigh,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.2)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                // Auto Track
                ListTile(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.of(context).pop();
                    wp.setQualityTrack(PlayerAsmsTrack.defaultTrack());
                  },
                  leading: Icon(
                    Icons.auto_awesome_rounded,
                    color: isAuto ? widget.accent : cs.onSurfaceVariant,
                    size: 20,
                  ),
                  title: Text(
                    'Auto',
                    style: TextStyle(
                      fontWeight: isAuto ? FontWeight.w800 : FontWeight.w600,
                      color: isAuto ? widget.accent : cs.onSurface,
                    ),
                  ),
                  subtitle: Text(
                    'Automatically adapts to your connection speed',
                    style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                  ),
                  trailing: isAuto
                      ? Icon(
                          Icons.check_circle_rounded,
                          color: widget.accent,
                          size: 20,
                        )
                      : null,
                ),
                for (final h in sortedHeights) ...[
                  Divider(
                    height: 1,
                    color: cs.outlineVariant.withValues(alpha: 0.15),
                  ),
                  _buildTrackTile(
                    uniqueTracksByHeight[h]!,
                    isSelected: !isAuto && wp.currentQualityTrack?.height == h,
                    cs: cs,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // ── Stream Servers / Sources Section ──
        if (streams.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'STREAM SERVERS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          Material(
            color: cs.surfaceContainerHigh,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.2)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (int i = 0; i < streams.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      color: cs.outlineVariant.withValues(alpha: 0.15),
                    ),
                  () {
                    final isSelected =
                        wp.activeSource != null &&
                        wp.activeSource!.server == streams[i].server &&
                        wp.activeSource!.url == streams[i].url;
                    return ListTile(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Navigator.of(context).pop();
                        wp.setSource(streams[i]);
                      },
                      leading: Icon(
                        streams[i].type == StreamType.hls
                            ? Icons.stream_rounded
                            : Icons.movie_outlined,
                        color: isSelected ? widget.accent : cs.onSurfaceVariant,
                        size: 20,
                      ),
                      title: Text(
                        streams[i].server,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: isSelected ? widget.accent : cs.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        streams[i].label,
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(
                              Icons.check_circle_rounded,
                              color: widget.accent,
                              size: 20,
                            )
                          : null,
                    );
                  }(),
                ],
              ],
            ),
          ),
        ],

        if (tracks.isEmpty && streams.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'No stream sources or qualities available.',
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTrackTile(
    PlayerAsmsTrack track, {
    required bool isSelected,
    required ColorScheme cs,
  }) {
    final height = track.height ?? 0;
    final label = '${height}p';
    final bitrate = (track.bitrate ?? 0) > 0
        ? '${(track.bitrate! / 1000000).toStringAsFixed(1)} Mbps'
        : null;

    return ListTile(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.of(context).pop();
        widget.wp.setQualityTrack(track);
      },
      leading: Icon(
        height >= 720 ? Icons.hd_outlined : Icons.sd_outlined,
        color: isSelected ? widget.accent : cs.onSurfaceVariant,
        size: 20,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          color: isSelected ? widget.accent : cs.onSurface,
        ),
      ),
      subtitle: bitrate != null
          ? Text(
              bitrate,
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
            )
          : null,
      trailing: isSelected
          ? Icon(Icons.check_circle_rounded, color: widget.accent, size: 20)
          : null,
    );
  }

  Widget _buildAudioSection(WatchProvider wp, ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'AUDIO TRACK',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
        Material(
          color: cs.surfaceContainerHigh,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.2)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              // Subtitled Option
              ListTile(
                onTap: wp.selectedAudio == StreamAudio.sub
                    ? null
                    : () {
                        HapticFeedback.selectionClick();
                        Navigator.of(context).pop();
                        wp.setAudio(StreamAudio.sub);
                      },
                leading: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: wp.selectedAudio == StreamAudio.sub
                        ? widget.accent.withValues(alpha: 0.18)
                        : cs.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.subtitles_rounded,
                    size: 18,
                    color: wp.selectedAudio == StreamAudio.sub
                        ? widget.accent
                        : cs.onSurfaceVariant,
                  ),
                ),
                title: Text(
                  'Subtitled',
                  style: TextStyle(
                    fontWeight: wp.selectedAudio == StreamAudio.sub
                        ? FontWeight.w800
                        : FontWeight.w600,
                    color: wp.selectedAudio == StreamAudio.sub
                        ? widget.accent
                        : cs.onSurface,
                  ),
                ),
                subtitle: Text(
                  'Original audio with subtitles',
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                ),
                trailing: wp.selectedAudio == StreamAudio.sub
                    ? Icon(
                        Icons.check_circle_rounded,
                        color: widget.accent,
                        size: 20,
                      )
                    : null,
              ),
              Divider(
                height: 1,
                color: cs.outlineVariant.withValues(alpha: 0.15),
              ),
              // Dubbed Option
              ListTile(
                enabled: wp.hasDub,
                onTap: !wp.hasDub || wp.selectedAudio == StreamAudio.dub
                    ? null
                    : () {
                        HapticFeedback.selectionClick();
                        Navigator.of(context).pop();
                        wp.setAudio(StreamAudio.dub);
                      },
                leading: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: wp.selectedAudio == StreamAudio.dub
                        ? widget.accent.withValues(alpha: 0.18)
                        : cs.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.record_voice_over_rounded,
                    size: 18,
                    color: wp.selectedAudio == StreamAudio.dub
                        ? widget.accent
                        : (wp.hasDub
                              ? cs.onSurfaceVariant
                              : cs.outline.withValues(alpha: 0.38)),
                  ),
                ),
                title: Text(
                  'Dubbed',
                  style: TextStyle(
                    fontWeight: wp.selectedAudio == StreamAudio.dub
                        ? FontWeight.w800
                        : FontWeight.w600,
                    color: wp.selectedAudio == StreamAudio.dub
                        ? widget.accent
                        : (wp.hasDub
                              ? cs.onSurface
                              : cs.onSurface.withValues(alpha: 0.38)),
                  ),
                ),
                subtitle: Text(
                  wp.hasDub
                      ? 'Dubbed voiceover track'
                      : 'Not available on ${wp.activeProviderDisplayName}',
                  style: TextStyle(
                    fontSize: 11,
                    color: wp.hasDub
                        ? cs.onSurfaceVariant
                        : cs.onSurface.withValues(alpha: 0.38),
                  ),
                ),
                trailing: wp.selectedAudio == StreamAudio.dub
                    ? Icon(
                        Icons.check_circle_rounded,
                        color: widget.accent,
                        size: 20,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProviderSection(WatchProvider wp, ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Providers List ──
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'PROVIDERS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
        Material(
          color: cs.surfaceContainerHigh,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.2)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (int i = 0; i < wp.availableProviders.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    color: cs.outlineVariant.withValues(alpha: 0.15),
                  ),
                Builder(
                  builder: (context) {
                    final provider = wp.availableProviders[i];
                    final isSelected = wp.selectedProviderId == provider.id;
                    final isOnline = provider.isOnline;
                    final probed = wp.getProbedEpisodes(provider.id);
                    final isProbed = wp.isProviderProbed(provider.id);
                    final isProbing = wp.isProviderProbing(provider.id);
                    final isProbeFailed = wp.isProviderProbeFailed(provider.id);

                    // Determine provider availability for this specific anime
                    final String subtitleText;
                    final Color statusColor;

                    if (!isOnline) {
                      subtitleText = 'Offline';
                      statusColor = const Color(0xFFF44336);
                    } else if (probed != null) {
                      final hasSub = probed.hasSub;
                      final hasDub = probed.hasDub;
                      if (!hasSub && !hasDub) {
                        subtitleText = 'No episodes found · Tap to try';
                        statusColor = cs.onSurfaceVariant.withValues(alpha: 0.5);
                      } else {
                        final parts = <String>[];
                        if (hasSub) parts.add('SUB (${probed.sub.length})');
                        if (hasDub) parts.add('DUB (${probed.dub.length})');
                        if (provider.latencyMs != null) {
                          parts.add('${provider.latencyMs}ms');
                        }
                        subtitleText = parts.join(' · ');
                        statusColor = const Color(0xFF4CAF50);
                      }
                    } else if (isProbing) {
                      subtitleText = 'Checking availability...';
                      statusColor = const Color(0xFFFFB300);
                    } else if (isProbeFailed) {
                      subtitleText = 'Check timed out · Tap to try';
                      statusColor = cs.onSurfaceVariant.withValues(alpha: 0.6);
                    } else if (isProbed) {
                      subtitleText = 'No episodes found · Tap to try';
                      statusColor = cs.onSurfaceVariant.withValues(alpha: 0.5);
                    } else {
                      // Initial preview before probe triggers
                      subtitleText =
                          '${provider.audio.map((a) => a.name.toUpperCase()).join(' · ')}${provider.latencyMs != null ? ' · ${provider.latencyMs}ms' : ''}';
                      statusColor = const Color(0xFF4CAF50);
                    }

                    final isEnabled = isOnline;

                    return ListTile(
                      enabled: isEnabled,
                      onTap: !isEnabled
                          ? null
                          : () {
                              HapticFeedback.selectionClick();
                              Navigator.of(context).pop();
                              wp.selectProvider(provider.id);
                            },
                      leading: ExtensionIcon(
                        name: provider.displayName,
                        iconUrl: provider.iconUrl,
                        size: 32,
                        borderRadius: 8,
                      ),
                      title: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              provider.displayName,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: isSelected
                                    ? widget.accent
                                    : (isEnabled
                                          ? cs.onSurface
                                          : cs.onSurface.withValues(alpha: 0.38)),
                              ),
                            ),
                          ),
                          if (provider.isAdult)
                            const AdultBadge(padding: EdgeInsets.only(left: 6)),
                        ],
                      ),
                      subtitle: Row(
                        children: [
                          if (isProbing) ...[
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(right: 6),
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                strokeCap: StrokeCap.round,
                                color: widget.accent,
                              ),
                            ),
                          ] else ...[
                            Container(
                              width: 6,
                              height: 6,
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                          Flexible(
                            child: Text(
                              subtitleText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: isEnabled
                                    ? cs.onSurfaceVariant
                                    : cs.onSurface.withValues(alpha: 0.38),
                              ),
                            ),
                          ),
                        ],
                      ),
                      trailing: isSelected
                          ? Icon(
                              Icons.check_circle_rounded,
                              color: widget.accent,
                              size: 20,
                            )
                          : null,
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSpeedSection(WatchProvider wp, ColorScheme cs) {
    return Material(
      color: cs.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.2)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (int i = 0; i < _speeds.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                color: cs.outlineVariant.withValues(alpha: 0.15),
              ),
            ListTile(
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.of(context).pop();
                wp.setSpeed(_speeds[i]);
              },
              leading: Icon(
                Icons.speed_rounded,
                color: wp.playbackSpeed == _speeds[i]
                    ? widget.accent
                    : cs.onSurfaceVariant,
                size: 20,
              ),
              title: Text(
                _speeds[i] == 1.0 ? '1.0× (Normal)' : '${_speeds[i]}×',
                style: TextStyle(
                  fontWeight: wp.playbackSpeed == _speeds[i]
                      ? FontWeight.w800
                      : FontWeight.w600,
                  color: wp.playbackSpeed == _speeds[i]
                      ? widget.accent
                      : cs.onSurface,
                ),
              ),
              trailing: wp.playbackSpeed == _speeds[i]
                  ? Icon(
                      Icons.check_circle_rounded,
                      color: widget.accent,
                      size: 20,
                    )
                  : null,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubtitlesSection(WatchProvider wp, ColorScheme cs) {
    final subSources = wp.playerSubtitleSources;
    final currentSub = wp.currentSubtitleSource;
    final isNoneSelected =
        currentSub == null || currentSub.type == PlayerSubtitlesSourceType.none;

    if (subSources.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.subtitles_off_outlined,
                size: 32,
                color: cs.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 8),
              Text(
                'No subtitles available for this stream.',
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }

    return Material(
      color: cs.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.2)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ListTile(
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.of(context).pop();
              wp.setSubtitle(null);
            },
            leading: Icon(
              Icons.subtitles_off_rounded,
              color: isNoneSelected ? widget.accent : cs.onSurfaceVariant,
              size: 20,
            ),
            title: Text(
              'Off / None',
              style: TextStyle(
                fontWeight: isNoneSelected ? FontWeight.w800 : FontWeight.w600,
                color: isNoneSelected ? widget.accent : cs.onSurface,
              ),
            ),
            trailing: isNoneSelected
                ? Icon(
                    Icons.check_circle_rounded,
                    color: widget.accent,
                    size: 20,
                  )
                : null,
          ),
          for (int i = 0; i < subSources.length; i++) ...[
            Divider(
              height: 1,
              color: cs.outlineVariant.withValues(alpha: 0.15),
            ),
            Builder(
              builder: (context) {
                final source = subSources[i];
                final hasMatchingUrl =
                    currentSub?.urls != null &&
                    currentSub!.urls!.isNotEmpty &&
                    source.urls != null &&
                    source.urls!.isNotEmpty &&
                    currentSub.urls!.first == source.urls!.first;
                final isSelected =
                    !isNoneSelected &&
                    (hasMatchingUrl ||
                        ((currentSub.urls == null ||
                                currentSub.urls!.isEmpty) &&
                            currentSub.name == source.name));

                return ListTile(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.of(context).pop();
                    wp.setSubtitle(source);
                  },
                  leading: Icon(
                    Icons.subtitles_rounded,
                    color: isSelected ? widget.accent : cs.onSurfaceVariant,
                    size: 20,
                  ),
                  title: Text(
                    source.name ?? 'Subtitle ${i + 1}',
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: isSelected ? widget.accent : cs.onSurface,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(
                          Icons.check_circle_rounded,
                          color: widget.accent,
                          size: 20,
                        )
                      : null,
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryTab extends StatelessWidget {
  const _CategoryTab({
    super.key,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: isSelected ? accent : cs.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? accent
                  : cs.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : cs.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : cs.onSurface,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
