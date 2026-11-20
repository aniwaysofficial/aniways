import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:aniways/core/constants.dart';
import 'package:aniways/core/network/anilist_service.dart';
import 'package:aniways/core/network/extractor_service.dart';
import 'package:aniways/core/responsive.dart';
import 'package:aniways/core/services/image_cache_service.dart';
import 'package:aniways/core/widgets/anime_states.dart';
import 'package:aniways/models/anime_details.dart';
import 'package:aniways/models/anime_media.dart';
import 'package:aniways/navigation/main_navigation.dart' show pushFullScreen;
import 'package:aniways/providers/watch_provider.dart';
import 'package:aniways/screens/home/home_section.dart' show SectionHeader;
import 'package:aniways/screens/settings/extensions/extensions_screen.dart';

import 'anime_player_screen.dart';
import 'episode_grid.dart';
import 'watch_settings_sheet.dart';

// ═════════════════════════════════════════════════════════════════════════
// WatchView
// ═════════════════════════════════════════════════════════════════════════

class WatchView extends StatefulWidget {
  const WatchView({
    super.key,
    required this.anime,
    required this.accent,
    required this.bottom,
    this.embedded = false,
    this.details,
  });

  final AnimeMedia anime;
  final Color accent;
  final double bottom;
  final bool embedded;
  final AnimeDetails? details;

  @override
  State<WatchView> createState() => _WatchViewState();
}

class _WatchViewState extends State<WatchView> {
  AnimeDetails? _resolvedDetails;

  @override
  void initState() {
    super.initState();
    _resolvedDetails = widget.details;
    if (_resolvedDetails == null) {
      _fetchDetailsIfNeeded();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final wp = context.read<WatchProvider>();
        if (wp.currentProviderEpisodes == null &&
            (wp.state == WatchState.loading ||
                wp.state == WatchState.error ||
                (wp.state == WatchState.noExtensions &&
                    wp.hasExtensionsInstalled))) {
          wp.init(widget.anime, accent: widget.accent);
        }
      }
    });
  }

  Future<void> _fetchDetailsIfNeeded() async {
    try {
      final raw = await anilistService.details(widget.anime.id);
      if (mounted) {
        setState(() {
          _resolvedDetails = AnimeDetails.fromJson(raw);
        });
      }
    } catch (_) {}
  }

  @override
  void didUpdateWidget(WatchView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.details != oldWidget.details && widget.details != null) {
      setState(() => _resolvedDetails = widget.details);
    }
    if (widget.accent != oldWidget.accent) {
      context.read<WatchProvider>().accentColor = widget.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final wp = context.watch<WatchProvider>();
    final isWide = context.hasSideNav;
    final top = widget.embedded
        ? MediaQuery.paddingOf(context).top
        : MediaQuery.paddingOf(context).top + 56;
    final inset = widget.embedded ? 16.0 : pageInset(context);
    final effectiveDetails = _resolvedDetails ?? widget.details;

    if (isWide && !widget.embedded) {
      return _WideTwoPaneLayout(
        wp: wp,
        anime: widget.anime,
        details: effectiveDetails,
        accent: widget.accent,
        bottom: widget.bottom,
        top: top,
        inset: inset,
      );
    }

    return _MobilePinnedLayout(
      wp: wp,
      anime: widget.anime,
      details: effectiveDetails,
      accent: widget.accent,
      bottom: widget.embedded ? 16.0 : widget.bottom,
      top: top,
      inset: inset,
      embedded: widget.embedded,
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// Mobile Pinned Layout (Pinned 16:9 Player at Top, Scrollable List Below)
// ═════════════════════════════════════════════════════════════════════════

class _MobilePinnedLayout extends StatelessWidget {
  const _MobilePinnedLayout({
    required this.wp,
    required this.anime,
    required this.accent,
    required this.bottom,
    required this.top,
    required this.inset,
    this.embedded = false,
    this.details,
  });

  final WatchProvider wp;
  final AnimeMedia anime;
  final AnimeDetails? details;
  final Color accent;
  final double bottom;
  final double top;
  final double inset;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final screenH = MediaQuery.sizeOf(context).height;
    final playerMaxH = embedded
        ? null
        : (isLandscape ? (screenH * 0.52).clamp(140.0, 220.0) : null);
    final effectiveTop = embedded
        ? top + 8.0
        : (isLandscape ? 4.0 : top + 16.0);

    // ── When no extensions are installed or active: Show Official Streams & Extensions tile ──
    if (wp.state == WatchState.noExtensions ||
        (!wp.hasExtensionsInstalled &&
            wp.episodes.isEmpty &&
            wp.state != WatchState.upcoming)) {
      return _NoExtensionsWatchView(
        anime: anime,
        details: details,
        accent: accent,
        inset: inset,
        bottom: bottom,
        top: effectiveTop,
        hasInstalled: wp.hasExtensionsInstalled,
        onRetry: wp.retry,
      );
    }

    return Stack(
      children: [
        Column(
          children: [
            SizedBox(height: effectiveTop),

            // ── Pinned 16:9 Player Container ──
            if (playerMaxH != null)
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: playerMaxH),
                child: _VideoPlayerArea(
                  wp: wp,
                  anime: anime,
                  accent: accent,
                  inset: inset,
                ),
              )
            else
              _VideoPlayerArea(
                wp: wp,
                anime: anime,
                accent: accent,
                inset: inset,
              ),

            // ── Fallback / Transient Notice ──
            if (wp.statusNotice != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: cs.onPrimaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        wp.statusNotice!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: cs.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // ── Controls & Filters Bar ──
            if (wp.episodes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 6),
                child: _FilterToolbar(wp: wp, accent: accent),
              ),

            // ── Lazy Scrollable Episode List Section ──
            Expanded(child: _buildEpisodeBody(context, cs)),
          ],
        ),
      ],
    );
  }

  Widget _buildEpisodeBody(BuildContext context, ColorScheme cs) {
    if (wp.state == WatchState.loading) {
      return ListView(
        padding: EdgeInsets.fromLTRB(16, 6, 16, bottom + 24),
        children: const [
          AnimeTileSkeleton(isFirst: true),
          SizedBox(height: 8),
          AnimeTileSkeleton(),
          SizedBox(height: 8),
          AnimeTileSkeleton(),
          SizedBox(height: 8),
          AnimeTileSkeleton(isLast: true),
        ],
      );
    }

    if (wp.state == WatchState.error && wp.episodes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ErrorCard(
            message: wp.errorMessage ?? 'Failed to connect to video providers.',
            onRetry: wp.retry,
          ),
        ),
      );
    }

    return EpisodeViewSection(
      wp: wp,
      anime: anime,
      accent: accent,
      bottom: bottom,
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// Wide Two-Pane Layout (Tablet & Desktop)
// ═════════════════════════════════════════════════════════════════════════

class _WideTwoPaneLayout extends StatelessWidget {
  const _WideTwoPaneLayout({
    required this.wp,
    required this.anime,
    required this.accent,
    required this.bottom,
    required this.top,
    required this.inset,
    this.details,
  });

  final WatchProvider wp;
  final AnimeMedia anime;
  final AnimeDetails? details;
  final Color accent;
  final double bottom;
  final double top;
  final double inset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final effectiveTop = isLandscape ? 8.0 : top + 16.0;
    final effectiveBottom = isLandscape ? 8.0 : bottom;

    // ── When no extensions are installed or active: Show Official Streams & Extensions tile ──
    if (wp.state == WatchState.noExtensions ||
        (!wp.hasExtensionsInstalled &&
            wp.episodes.isEmpty &&
            wp.state != WatchState.upcoming)) {
      return _NoExtensionsWatchView(
        anime: anime,
        details: details,
        accent: accent,
        inset: inset,
        bottom: effectiveBottom,
        top: effectiveTop,
        hasInstalled: wp.hasExtensionsInstalled,
        onRetry: wp.retry,
        isWide: true,
      );
    }

    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            inset,
            effectiveTop,
            inset,
            effectiveBottom,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Left Pane: Video Player + Episode Details (Flex: 1) ──
              Expanded(
                flex: 1,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _VideoPlayerArea(
                        wp: wp,
                        anime: anime,
                        accent: accent,
                        inset: 0,
                      ),
                      const SizedBox(height: 16),
                      if (wp.currentEpisode != null) ...[
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: accent.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Text(
                                'EP ${wp.currentEpisode!.number}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: accent,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                wp.currentEpisode!.title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (wp.currentEpisode!.description != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            wp.currentEpisode!.description!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 24),

              // ── Right Pane: Filters & Episode List (Flex: 1) ──
              Expanded(
                flex: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: cs.outlineVariant.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (wp.episodes.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 12, bottom: 8),
                          child: _FilterToolbar(wp: wp, accent: accent),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: SectionHeader(
                            title: 'Episodes (${wp.episodes.length})',
                            icon: Icons.video_library_rounded,
                            color: accent,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      Expanded(
                        child: wp.state == WatchState.loading
                            ? ListView(
                                padding: const EdgeInsets.all(16),
                                children: const [
                                  AnimeTileSkeleton(isFirst: true),
                                  SizedBox(height: 8),
                                  AnimeTileSkeleton(),
                                  SizedBox(height: 8),
                                  AnimeTileSkeleton(isLast: true),
                                ],
                              )
                            : (wp.state == WatchState.error &&
                                    wp.episodes.isEmpty
                                ? Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                      ),
                                      child: ErrorCard(
                                        message:
                                            wp.errorMessage ??
                                            'Failed to connect to video providers.',
                                        onRetry: wp.retry,
                                      ),
                                    ),
                                  )
                                : EpisodeViewSection(
                                    wp: wp,
                                    anime: anime,
                                    accent: accent,
                                    bottom: 16,
                                    isEmbeddedInTwoPane: true,
                                  )),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// 16:9 Video Area
// ═════════════════════════════════════════════════════════════════════════

class _VideoPlayerArea extends StatelessWidget {
  const _VideoPlayerArea({
    required this.wp,
    required this.anime,
    required this.accent,
    required this.inset,
  });

  final WatchProvider wp;
  final AnimeMedia anime;
  final Color accent;
  final double inset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isPlaying = wp.state == WatchState.playing;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: inset > 16 ? inset : 12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(
                alpha: isDark
                    ? (isPlaying ? 0.32 : 0.22)
                    : (isPlaying ? 0.20 : 0.12),
              ),
              blurRadius: 26,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              color: Colors.black,
              child: _HeroPreviewCard(wp: wp, anime: anime, accent: accent),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroPreviewCard extends StatelessWidget {
  const _HeroPreviewCard({
    required this.wp,
    required this.anime,
    required this.accent,
  });

  final WatchProvider wp;
  final AnimeMedia anime;
  final Color accent;

  Future<void> _handlePlay(BuildContext context) async {
    HapticFeedback.heavyImpact();
    final ep =
        wp.currentEpisode ??
        (wp.episodes.isNotEmpty ? wp.episodes.first : null);
    if (ep == null) return;

    wp.playEpisode(ep, accent: accent);
    await AnimePlayerScreen.open(context, wp, anime: anime, accent: accent);
    if (context.mounted) {
      await wp.refreshWatchState();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ep =
        wp.currentEpisode ??
        (wp.episodes.isNotEmpty ? wp.episodes.first : null);
    final bgImage = ep?.image ?? anime.bannerUrl ?? anime.coverUrl;
    final isPlaying = wp.state == WatchState.playing;
    final isLoadingStream = wp.state == WatchState.loadingStream;
    final isLoadingEpisodes = wp.state == WatchState.loading;
    final isEpisodesError = wp.state == WatchState.error && wp.episodes.isEmpty;
    final isNoExtensions = wp.state == WatchState.noExtensions;
    final watchedPercent = ep != null ? wp.watchedPercentages[ep.number] : null;
    final isPartiallyWatched =
        watchedPercent != null &&
        watchedPercent > 0.01 &&
        watchedPercent < 0.90;
    final shouldResume = isPlaying || isPartiallyWatched;

    final onAccent =
        ThemeData.estimateBrightnessForColor(accent) == Brightness.dark
        ? Colors.white
        : Colors.black87;

    final String buttonLabel;
    if (ep != null) {
      if (shouldResume) {
        buttonLabel = 'Resume Episode ${ep.number}';
      } else {
        buttonLabel = 'Play Episode ${ep.number}';
      }
    } else if (isNoExtensions) {
      buttonLabel = !wp.hasExtensionsInstalled
          ? 'Install Extensions'
          : 'Enable Extensions';
    } else {
      buttonLabel = 'Play Now';
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: (isLoadingEpisodes || ep == null)
            ? (isNoExtensions
                  ? () async {
                      HapticFeedback.lightImpact();
                      await pushFullScreen(
                        context,
                        ExtensionsScreen(
                          initialTabIndex: !wp.hasExtensionsInstalled ? 1 : 0,
                        ),
                      );
                      wp.retry();
                    }
                  : (isEpisodesError
                        ? () => wp.init(anime, accent: accent)
                        : null))
            : () => _handlePlay(context),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (bgImage != null)
              CachedNetworkImage(
                imageUrl: bgImage,
                cacheManager: ImageCacheService.animeImageCache,
                fit: BoxFit.cover,
                placeholder: (_, _) =>
                    Container(color: const Color(0xFF16161A)),
                errorWidget: (_, _, _) =>
                    Container(color: const Color(0xFF16161A)),
              ),

            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.35),
                    Colors.black.withValues(alpha: 0.60),
                    Colors.black.withValues(alpha: 0.88),
                  ],
                ),
              ),
            ),

            Center(
              child: isLoadingEpisodes
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        strokeCap: StrokeCap.round,
                        valueColor: AlwaysStoppedAnimation<Color>(accent),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            constraints: const BoxConstraints(maxWidth: 240),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: accent,
                              borderRadius: BorderRadius.circular(40),
                              boxShadow: [
                                BoxShadow(
                                  color: accent.withValues(alpha: 0.45),
                                  blurRadius: 18,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isLoadingStream) ...[
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      strokeCap: StrokeCap.round,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        onAccent,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      ep != null
                                          ? 'Loading EP ${ep.number}'
                                          : 'Loading...',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: onAccent,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ),
                                ] else if (isNoExtensions) ...[
                                  Icon(
                                    !wp.hasExtensionsInstalled
                                        ? Icons.extension_rounded
                                        : Icons.tune_rounded,
                                    color: onAccent,
                                    size: 19,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      buttonLabel,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: onAccent,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ),
                                ] else if (isEpisodesError) ...[
                                  Icon(
                                    Icons.refresh_rounded,
                                    color: onAccent,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      'Retry loading',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: onAccent,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ),
                                ] else ...[
                                  Icon(
                                    Icons.play_arrow_rounded,
                                    color: onAccent,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      buttonLabel,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: onAccent,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (ep?.title != null) ...[
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text(
                                ep!.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
            ),

            if (watchedPercent != null && watchedPercent > 0)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(20),
                  ),
                  child: LinearProgressIndicator(
                    value: watchedPercent,
                    minHeight: 4,
                    backgroundColor: Colors.white24,
                    valueColor: AlwaysStoppedAnimation<Color>(accent),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// Filter Toolbar (Sub/Dub, Provider, Settings, Search, Sort, Mode)
// ═════════════════════════════════════════════════════════════════════════

class _FilterToolbar extends StatelessWidget {
  const _FilterToolbar({required this.wp, required this.accent});

  final WatchProvider wp;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          // ── Sub / Dub Segmented Pill (only shown when both audios are available) ──
          if (wp.hasSub && wp.hasDub) ...[
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.35),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _AudioOption(
                    label: 'Sub',
                    isSelected: wp.selectedAudio == StreamAudio.sub,
                    accent: accent,
                    onTap: () => wp.setAudio(StreamAudio.sub),
                  ),
                  _AudioOption(
                    label: 'Dub',
                    isSelected: wp.selectedAudio == StreamAudio.dub,
                    isEnabled: wp.hasDub,
                    accent: accent,
                    onTap: () => wp.setAudio(StreamAudio.dub),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
          ],

          // ── Provider Selector Pill ──
          if (wp.selectedProviderId != null)
            _ActionPill(
              icon: Icons.dns_rounded,
              label: wp.activeProviderDisplayName,
              accent: accent,
              onTap: () => WatchSettingsSheet.show(context, wp, accent),
            ),

          const SizedBox(width: 8),

          // ── Sort Order Toggle (1->N vs N->1) ──
          IconButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              wp.toggleSortOrder();
            },
            tooltip: wp.isReversed
                ? 'Showing newest first'
                : 'Showing oldest first',
            style: IconButton.styleFrom(
              backgroundColor: cs.surfaceContainerHighest,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: 0.35),
                  width: 0.8,
                ),
              ),
            ),
            icon: Icon(
              wp.isReversed
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              size: 20,
              color: cs.onSurface,
            ),
          ),

          const SizedBox(width: 8),

          // ── Layout Mode Toggle (List -> Cards -> Compact Numbers) ──
          IconButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              wp.cycleViewMode();
            },
            tooltip: switch (wp.viewMode) {
              EpisodeViewMode.list => 'Layout: List (Tap for Card Grid)',
              EpisodeViewMode.cards =>
                'Layout: Card Grid (Tap for Compact Grid)',
              EpisodeViewMode.compact =>
                'Layout: Compact Numbers (Tap for List View)',
            },
            style: IconButton.styleFrom(
              backgroundColor: cs.surfaceContainerHighest,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: 0.35),
                  width: 0.8,
                ),
              ),
            ),
            icon: Icon(
              switch (wp.viewMode) {
                EpisodeViewMode.list => Icons.view_agenda_rounded,
                EpisodeViewMode.cards => Icons.grid_view_rounded,
                EpisodeViewMode.compact => Icons.apps_rounded,
              },
              size: 20,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _AudioOption extends StatelessWidget {
  const _AudioOption({
    required this.label,
    required this.isSelected,
    required this.accent,
    this.isEnabled = true,
    this.onTap,
  });

  final String label;
  final bool isSelected;
  final Color accent;
  final bool isEnabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? accent : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? cs.onPrimary
                : isEnabled
                ? cs.onSurface
                : cs.onSurface.withValues(alpha: 0.35),
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({
    required this.icon,
    required this.label,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.35),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: accent),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.expand_more_rounded,
                size: 16,
                color: cs.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// No Extensions Watch View: Official Streams & Community Extensions
// ═════════════════════════════════════════════════════════════════════════

class _NoExtensionsWatchView extends StatelessWidget {
  const _NoExtensionsWatchView({
    required this.anime,
    required this.details,
    required this.accent,
    required this.inset,
    required this.bottom,
    required this.top,
    required this.hasInstalled,
    required this.onRetry,
    this.isWide = false,
  });

  final AnimeMedia anime;
  final AnimeDetails? details;
  final Color accent;
  final double inset;
  final double bottom;
  final double top;
  final bool hasInstalled;
  final VoidCallback onRetry;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final links = details?.streamingLinks ?? const [];
    final effectiveHorizontal = isWide ? 0.0 : inset;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        effectiveHorizontal,
        top,
        effectiveHorizontal,
        bottom + 32,
      ),
      children: [
        // ── Section 1: Where to Watch Officially ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.open_in_new_rounded,
                    size: 20,
                    color: accent,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Where to Watch Officially',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Licensed official streaming services for ${anime.title}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ── Official Streaming Providers List ──
        if (links.isNotEmpty)
          ...[
            if (isWide)
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final link in links)
                    SizedBox(
                      width: 320,
                      child: _OfficialStreamingTile(link: link, accent: accent),
                    ),
                ],
              )
            else
              for (final link in links) ...[
                _OfficialStreamingTile(link: link, accent: accent),
                const SizedBox(height: 10),
              ],
          ]
        else if (details == null)
          // Shimmer / skeleton while loading AniList external links
          const Column(
            children: [
              AnimeTileSkeleton(isFirst: true),
              SizedBox(height: 8),
              AnimeTileSkeleton(isLast: true),
            ],
          )
        else
          // Empty state: No official streaming services cataloged on AniList
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.tv_off_rounded,
                    color: cs.onSurfaceVariant,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No Official Streams Cataloged',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'AniList has no licensed streaming partners listed for this anime yet.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 28),

        // ── Section 2: Community Extensions Tile ──
        _CommunityExtensionsCard(
          accent: accent,
          hasInstalled: hasInstalled,
          onRefresh: onRetry,
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// Official Streaming Provider Tile
// ═════════════════════════════════════════════════════════════════════════

class _OfficialStreamingTile extends StatelessWidget {
  const _OfficialStreamingTile({
    required this.link,
    required this.accent,
  });

  final AnimeExternalLink link;
  final Color accent;

  static Color _resolveBrandColor(
    String site,
    String? hexColor,
    Color fallback,
  ) {
    final lower = site.toLowerCase();
    if (lower.contains('crunchyroll')) return const Color(0xFFF47521);
    if (lower.contains('netflix')) return const Color(0xFFE50914);
    if (lower.contains('hidive')) return const Color(0xFF00A3FF);
    if (lower.contains('disney')) return const Color(0xFF113CCF);
    if (lower.contains('hulu')) return const Color(0xFF1CE783);
    if (lower.contains('youtube') ||
        lower.contains('muse') ||
        lower.contains('ani-one')) {
      return const Color(0xFFFF0000);
    }
    if (lower.contains('bilibili')) return const Color(0xFF00A1D6);
    if (lower.contains('prime') || lower.contains('amazon')) {
      return const Color(0xFF00A8E1);
    }
    if (lower.contains('iqiyi')) return const Color(0xFF00C356);

    if (hexColor != null && hexColor.isNotEmpty) {
      final clean = hexColor.replaceAll('#', '').trim();
      if (clean.length == 6) {
        final val = int.tryParse('FF$clean', radix: 16);
        if (val != null) return Color(val);
      }
    }
    return fallback;
  }

  static IconData _resolveBrandIcon(String site) {
    final lower = site.toLowerCase();
    if (lower.contains('youtube') ||
        lower.contains('muse') ||
        lower.contains('ani-one')) {
      return Icons.play_arrow_rounded;
    }
    if (lower.contains('crunchyroll')) {
      return Icons.local_fire_department_rounded;
    }
    if (lower.contains('netflix')) return Icons.movie_rounded;
    if (lower.contains('hidive')) return Icons.live_tv_rounded;
    if (lower.contains('disney')) return Icons.stars_rounded;
    return Icons.tv_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final brandColor = _resolveBrandColor(link.site, link.color, accent);
    final iconData = _resolveBrandIcon(link.site);

    return Material(
      color: cs.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          HapticFeedback.lightImpact();
          try {
            final uri = Uri.parse(link.url);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          } catch (_) {}
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: brandColor.withValues(alpha: isDark ? 0.22 : 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(iconData, color: brandColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      link.site,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      link.language != null && link.language!.isNotEmpty
                          ? 'Official Stream · ${link.language}'
                          : 'Official Streaming Partner',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: brandColor.withValues(alpha: isDark ? 0.20 : 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Watch',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: brandColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.launch_rounded, size: 12, color: brandColor),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// Community Extensions Promotion Card
// ═════════════════════════════════════════════════════════════════════════

class _CommunityExtensionsCard extends StatelessWidget {
  const _CommunityExtensionsCard({
    required this.accent,
    required this.hasInstalled,
    required this.onRefresh,
  });

  final Color accent;
  final bool hasInstalled;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: isDark ? 0.22 : 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.extension_rounded,
                  color: accent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Community Extensions',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Connect external content sources',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            hasInstalled
                ? 'Your installed source extensions are currently disabled. Enable a provider in Extension Settings to connect.'
                : '${AppConstants.appName} is an anime tracker and does not host or distribute media. You can install user-maintained community extensions to connect external source providers.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.85),
              height: 1.45,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () async {
                    HapticFeedback.lightImpact();
                    await pushFullScreen(
                      context,
                      ExtensionsScreen(initialTabIndex: hasInstalled ? 0 : 1),
                    );
                    onRefresh();
                  },
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: Icon(
                    hasInstalled ? Icons.tune_rounded : Icons.explore_rounded,
                    size: 18,
                  ),
                  label: Text(
                    hasInstalled ? 'Manage Extensions' : 'Explore Extensions',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  onRefresh();
                },
                tooltip: 'Refresh extensions',
                icon: const Icon(Icons.refresh_rounded, size: 20),
                style: IconButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
