import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:aniways/core/database/repositories/collection_repository.dart';
import 'package:aniways/core/database/repositories/subscription_repository.dart';
import 'package:aniways/core/database/repositories/watch_repository.dart';
import 'package:aniways/core/network/anilist_service.dart';
import 'package:aniways/core/responsive.dart';
import 'package:aniways/core/scroll/app_scroll.dart';
import 'package:aniways/core/services/blurred_cover_service.dart';
import 'package:aniways/core/theme/cover_palette.dart';
import 'package:aniways/core/theme/genre_colors.dart';
import 'package:aniways/core/widgets/anime_card.dart';
import 'package:aniways/core/widgets/anime_states.dart';
import 'package:aniways/core/widgets/collection_status_sheet.dart';
import 'package:aniways/core/widgets/aniways_snackbar.dart';
import 'package:aniways/models/anime_details.dart';
import 'package:aniways/models/anime_media.dart';
import 'package:aniways/models/collection_status.dart';
import 'package:aniways/navigation/main_navigation.dart'
    show
        FullBleedScreen,
        MainNavigation,
        kNavBarBottomMargin,
        kNavBarHeight,
        kRailWidth,
        Style2PillNavBar;
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart'
    show ItemConfig, NavBarConfig;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:aniways/providers/theme_provider.dart';
import 'package:aniways/providers/watch_provider.dart';
import 'package:aniways/screens/details/watch/watch_view.dart';
import 'package:aniways/screens/details/widgets/details_character_card.dart';
import 'package:aniways/screens/details/widgets/details_genres_and_tags.dart';
import 'package:aniways/screens/details/widgets/details_metadata_table.dart';
import 'package:aniways/screens/details/widgets/details_next_episode_card.dart';
import 'package:aniways/screens/details/widgets/details_stats_row.dart';
import 'package:aniways/screens/details/widgets/details_synopsis.dart';
import 'package:aniways/screens/details/widgets/details_trailer_card.dart';
import 'package:aniways/screens/home/home_section.dart' show SectionHeader;

const double _kPosterWidth = 188;
const double _kFadeDistance = 120;

/// Details screen for one anime, styled to match Aniways's visual design system.
///
/// Opens instantly with cached [AnimeMedia] (cover, title, score, genres),
/// and loads full details (characters, synopsis, studios, relations) from AniList.
class AnimeDetailsScreen extends StatefulWidget implements FullBleedScreen {
  const AnimeDetailsScreen({
    super.key,
    required this.anime,
    this.heroTag,
    this.initialTab = 0,
  });

  final AnimeMedia anime;
  final String? heroTag;
  final int initialTab;

  @override
  State<AnimeDetailsScreen> createState() => _AnimeDetailsScreenState();
}

class _AnimeDetailsScreenState extends State<AnimeDetailsScreen> {
  final ScrollController _scroll = ScrollController();
  final ValueNotifier<double> _barOpacity = ValueNotifier<double>(0);

  ThemeData? _lastPushedRailTheme;
  Route? _ownRoute;

  late int _selectedTab = widget.initialTab;
  late bool _hasOpenedWatchTab = widget.initialTab == 1;
  late final WatchProvider _watchProvider = WatchProvider();

  AnimeDetails? _details;
  Object? _error;
  late final ValueNotifier<AnimeDetails?> _detailsNotifier = ValueNotifier(_details);
  static Map<String, String>? _globalGenreCovers;
  late final ValueNotifier<Map<String, String>?> _genreCoversNotifier =
      ValueNotifier(_globalGenreCovers);

  final ValueNotifier<bool> _savedNotifier = ValueNotifier(false);
  final ValueNotifier<bool> _subscribedNotifier = ValueNotifier(false);
  final ValueNotifier<String?> _watchStatusNotifier = ValueNotifier(null);
  final ValueNotifier<({int episode, String provider, String audio})?>
      _savedWatchStateNotifier = ValueNotifier(null);

  Color? _currentAccent;
  StreamSubscription<bool>? _savedSub;
  StreamSubscription<bool>? _subscribedSub;
  StreamSubscription<String?>? _watchStatusSub;
  StreamSubscription<({int episode, String provider, String audio})?>?
  _watchStateSub;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _initDbSubscriptions();
    _load();
    if (_globalGenreCovers == null) {
      _loadGenreCovers();
    }
    if (_selectedTab == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _initWatchTab();
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.layoutSize.atLeast(WindowSize.expanded) && !_hasOpenedWatchTab) {
      _initWatchTab();
      _watchProvider.handleTabVisibility(true);
    }
  }

  void _initDbSubscriptions() {
    _savedSub = CollectionRepository.instance
        .watchIsFavorite(widget.anime.id)
        .listen((fav) {
          _savedNotifier.value = fav;
        });

    _subscribedSub = SubscriptionRepository.instance
        .watchIsSubscribed(widget.anime.id)
        .listen((sub) {
          _subscribedNotifier.value = sub;
        });

    _watchStatusSub = CollectionRepository.instance
        .watchAnimeStatus(widget.anime.id)
        .listen((status) {
          _watchStatusNotifier.value = status;
        });

    _watchStateSub = WatchRepository.instance
        .watchAnimeWatchState(widget.anime.id)
        .listen((state) {
          _savedWatchStateNotifier.value = state;
        });
  }

  void _initWatchTab({Color? overrideAccent}) {
    _hasOpenedWatchTab = true;
    final themeProvider = Provider.of<ThemeProvider?>(context, listen: false);
    final useCoverColor = themeProvider?.useCoverColorAccent ?? true;
    final primary = Theme.of(context).colorScheme.primary;
    final fallback = (useCoverColor && widget.anime.coverColor != null)
        ? Color(widget.anime.coverColor!)
        : primary;
    final media = _details?.media ?? widget.anime;
    _watchProvider.init(
      media,
      accent: overrideAccent ?? _currentAccent ?? fallback,
    );
  }

  Future<void> _loadGenreCovers() async {
    try {
      final items = await anilistService.genres();
      if (!mounted) return;
      _globalGenreCovers = {
        for (final item in items)
          if (item.coverUrl != null && item.coverUrl!.isNotEmpty)
            item.name: item.coverUrl!,
      };
      if (mounted) {
        _genreCoversNotifier.value = _globalGenreCovers;
      }
      for (final item in items) {
        final url = item.coverUrl;
        if (url != null && url.isNotEmpty) {
          BlurredCoverService.instance.getOrBlur(url);
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    if (_ownRoute != null) {
      MainNavigation.removeRouteRailTheme(_ownRoute!);
      _ownRoute = null;
    }
    _savedSub?.cancel();
    _subscribedSub?.cancel();
    _watchStatusSub?.cancel();
    _watchStateSub?.cancel();
    _detailsNotifier.dispose();
    _genreCoversNotifier.dispose();
    _savedNotifier.dispose();
    _subscribedNotifier.dispose();
    _watchStatusNotifier.dispose();
    _savedWatchStateNotifier.dispose();
    _scroll.dispose();
    _barOpacity.dispose();
    _watchProvider.dispose();
    super.dispose();
  }

  void _onScroll() {
    final raw = (_scroll.offset / _kFadeDistance).clamp(0.0, 1.0);
    final t = (raw * 25).roundToDouble() / 25.0;
    if (t != _barOpacity.value) _barOpacity.value = t;
  }

  Future<void> _load() async {
    try {
      final raw = await anilistService.details(widget.anime.id);
      if (!mounted) return;
      final d = AnimeDetails.fromJson(raw);
      _details = d;
      _detailsNotifier.value = d;
      if (d.media.isUpcoming && _hasOpenedWatchTab) {
        _initWatchTab();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    }
  }

  void _retry() {
    setState(() => _error = null);
    _load();
  }

  Future<void> _toggleSave() async {
    final media = _details?.media ?? widget.anime;
    final isFav = await CollectionRepository.instance.toggleFavorite(media);
    _savedNotifier.value = isFav;
    if (!mounted) return;
    AniwaysSnackBar.show(
      context,
      message: isFav
          ? 'Added "${widget.anime.title}" to favorites'
          : 'Removed "${widget.anime.title}" from favorites',
      icon: isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
    );
  }

  Future<void> _toggleSubscription() async {
    final media = _details?.media ?? widget.anime;
    final nextAiring = _details?.media.nextAiring ?? widget.anime.nextAiring;
    final currentlySubscribed =
        await SubscriptionRepository.instance.isSubscribed(media.id);

    if (!currentlySubscribed &&
        !SubscriptionRepository.instance.canSubscribe(media, nextAiring)) {
      if (!mounted) return;
      AniwaysSnackBar.show(
        context,
        message: '"${widget.anime.title}" has already finished airing',
        icon: Icons.info_outline_rounded,
      );
      return;
    }

    final isSubscribed = await SubscriptionRepository.instance
        .toggleSubscription(media, nextAiring);
    _subscribedNotifier.value = isSubscribed;
    if (!mounted) return;
    AniwaysSnackBar.show(
      context,
      message: isSubscribed
          ? 'Subscribed to episode alerts for "${widget.anime.title}"'
          : 'Unsubscribed from alerts for "${widget.anime.title}"',
      icon: isSubscribed
          ? Icons.notifications_active_rounded
          : Icons.notifications_none_rounded,
    );
  }

  void _openCollectionStatusSheet() {
    final media = _details?.media ?? widget.anime;
    showCollectionStatusSheet(context, media);
  }

  void _onShare() {
    final anime = widget.anime;
    Clipboard.setData(
      ClipboardData(text: 'https://anilist.co/anime/${anime.id}'),
    );
    AniwaysSnackBar.show(
      context,
      message: 'Link for "${anime.title}" copied to clipboard',
      icon: Icons.copy_rounded,
    );
  }

  Future<void> _openTrailer(AnimeTrailer trailer) async {
    final rawUrl = trailer.url;
    if (rawUrl == null) {
      if (!mounted) return;
      AniwaysSnackBar.info(
        context,
        message: 'Trailer is currently unavailable',
        icon: Icons.videocam_off_rounded,
      );
      return;
    }

    try {
      // 1. If YouTube, attempt direct deep-linking to native YouTube app via vnd.youtube scheme
      if (trailer.site.toLowerCase() == 'youtube') {
        final appUri = Uri.parse('vnd.youtube:${trailer.id}');
        if (await canLaunchUrl(appUri)) {
          final launched = await launchUrl(
            appUri,
            mode: LaunchMode.externalApplication,
          );
          if (launched) return;
        }
      }

      // 2. Launch external URL (opens YouTube app if registered, or default browser)
      final webUri = Uri.parse(rawUrl);
      final launched = await launchUrl(
        webUri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        AniwaysSnackBar.error(
          context,
          message: 'Could not open trailer link',
        );
      }
    } catch (e) {
      if (!mounted) return;
      AniwaysSnackBar.error(
        context,
        message: 'Failed to open trailer: $e',
      );
    }
  }

  void _onWatchNow() {
    _initWatchTab();
    if (!context.layoutSize.atLeast(WindowSize.expanded)) {
      if (_selectedTab != 1) {
        setState(() => _selectedTab = 1);
      }
    } else {
      if (_watchProvider.currentEpisode != null) {
        _watchProvider.playEpisode(_watchProvider.currentEpisode!);
      } else if (_watchProvider.episodes.isNotEmpty) {
        _watchProvider.playEpisode(_watchProvider.episodes.first);
      }
    }
  }

  ThemeData? _cachedParentTheme;
  Color? _cachedAccent;
  bool? _cachedIsPureBlack;
  bool? _cachedUseCoverColor;
  ThemeData? _cachedScopedTheme;
  Color? _cachedPageBg;

  (ThemeData, Color) _resolveScopedTheme({
    required ThemeData parentTheme,
    required Color accent,
    required Color onAccent,
    required bool isDark,
    required bool isPureBlack,
    required bool useCoverColor,
  }) {
    if (_cachedParentTheme == parentTheme &&
        _cachedAccent == accent &&
        _cachedIsPureBlack == isPureBlack &&
        _cachedUseCoverColor == useCoverColor &&
        _cachedScopedTheme != null &&
        _cachedPageBg != null) {
      return (_cachedScopedTheme!, _cachedPageBg!);
    }

    final pageBg = isPureBlack
        ? const Color(0xFF000000)
        : (useCoverColor
            ? (isDark
                ? Color.alphaBlend(
                    accent.withValues(alpha: 0.14),
                    const Color(0xFF0A0B0E),
                  )
                : Color.alphaBlend(
                    accent.withValues(alpha: 0.07),
                    const Color(0xFFF7F7FA),
                  ))
            : parentTheme.scaffoldBackgroundColor);

    final seededScheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: parentTheme.brightness,
    );

    final surfaceContainerHighestTinted = isPureBlack
        ? Color.alphaBlend(
            accent.withValues(alpha: 0.10),
            const Color(0xFF202024),
          )
        : Color.alphaBlend(
            accent.withValues(alpha: isDark ? 0.22 : 0.14),
            isDark ? const Color(0xFF1E1E22) : const Color(0xFFE4E4E8),
          );
    final surfaceContainerHighTinted = isPureBlack
        ? Color.alphaBlend(
            accent.withValues(alpha: 0.08),
            const Color(0xFF18181A),
          )
        : Color.alphaBlend(
            accent.withValues(alpha: isDark ? 0.15 : 0.09),
            isDark ? const Color(0xFF18181C) : const Color(0xFFEAEAEF),
          );
    final outlineVariantTinted = Color.alphaBlend(
      accent.withValues(alpha: isDark ? 0.32 : 0.24),
      seededScheme.outlineVariant,
    );

    final scopedColorScheme = seededScheme.copyWith(
      primary: accent,
      onPrimary: onAccent,
      primaryContainer: accent.withValues(alpha: isDark ? 0.25 : 0.15),
      onPrimaryContainer: isDark ? Colors.white : accent,
      surface: pageBg,
      surfaceContainerLowest: isPureBlack
          ? const Color(0xFF000000)
          : (isDark ? const Color(0xFF070709) : const Color(0xFFFFFFFF)),
      surfaceContainerLow: isPureBlack
          ? const Color(0xFF0A0A0A)
          : Color.alphaBlend(
              accent.withValues(alpha: isDark ? 0.08 : 0.04),
              isDark ? const Color(0xFF101115) : const Color(0xFFF2F2F6),
            ),
      surfaceContainer: isPureBlack
          ? const Color(0xFF141416)
          : Color.alphaBlend(
              accent.withValues(alpha: isDark ? 0.12 : 0.06),
              isDark ? const Color(0xFF15161B) : const Color(0xFFEDEDF2),
            ),
      surfaceContainerHigh: surfaceContainerHighTinted,
      surfaceContainerHighest: surfaceContainerHighestTinted,
      outlineVariant: outlineVariantTinted,
    );

    final scopedTheme = useCoverColor
        ? parentTheme.copyWith(
            colorScheme: scopedColorScheme,
            scaffoldBackgroundColor: pageBg,
            primaryColor: accent,
          )
        : parentTheme;

    _cachedParentTheme = parentTheme;
    _cachedAccent = accent;
    _cachedIsPureBlack = isPureBlack;
    _cachedUseCoverColor = useCoverColor;
    _cachedScopedTheme = scopedTheme;
    _cachedPageBg = pageBg;

    return (scopedTheme, pageBg);
  }

  @override
  Widget build(BuildContext context) {
    final parentTheme = Theme.of(context);
    final anime = widget.anime;
    final fallback = anime.coverColor == null
        ? (anime.genres.isNotEmpty
            ? genreColor(anime.genres.first)
            : parentTheme.colorScheme.primary)
        : Color(anime.coverColor!);

    return CoverPaletteBuilder(
      url: anime.coverUrl,
      fallback: fallback,
      builder: (context, accent, palette) {
        _currentAccent = accent;
        final isDark = parentTheme.brightness == Brightness.dark;
        final onAccent =
            ThemeData.estimateBrightnessForColor(accent) == Brightness.dark
            ? Colors.white
            : Colors.black;

        final themeProvider = context.watch<ThemeProvider?>();
        final useCoverColor = themeProvider?.useCoverColorAccent ?? true;
        final isPureBlack =
            isDark &&
            ((themeProvider?.pureBlack ?? false) ||
                parentTheme.colorScheme.surface == const Color(0xFF000000) ||
                parentTheme.scaffoldBackgroundColor == const Color(0xFF000000));

        final (scopedTheme, pageBg) = _resolveScopedTheme(
          parentTheme: parentTheme,
          accent: accent,
          onAccent: onAccent,
          isDark: isDark,
          isPureBlack: isPureBlack,
          useCoverColor: useCoverColor,
        );

        if (context.hasSideNav) {
          final route = ModalRoute.of(context);
          if (route != null) {
            _ownRoute = route;
            final themeToPush = scopedTheme;
            if (_lastPushedRailTheme != themeToPush) {
              _lastPushedRailTheme = themeToPush;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                MainNavigation.setRouteRailTheme(route, themeToPush);
              });
            }
          }
        }

        return Theme(
          data: scopedTheme,
          child: Builder(
            builder: (themedContext) {
              final cs = scopedTheme.colorScheme;
              final isWide = themedContext.hasSideNav;
              final inset = pageInset(themedContext);
              final isDualPane =
                  themedContext.layoutSize.atLeast(WindowSize.expanded);
              final paneInset = isDualPane ? 24.0 : inset;
              final leftPaneInset =
                  isWide ? (kRailWidth + paneInset) : paneInset;
              final bottom = isDualPane
                  ? 24.0
                  : kNavBarHeight +
                      kNavBarBottomMargin +
                      MediaQuery.viewPaddingOf(themedContext).bottom +
                      28.0;

              final romaji = anime.englishTitle != null &&
                      anime.englishTitle!.trim().toLowerCase() !=
                          anime.romajiTitle.trim().toLowerCase()
                  ? anime.romajiTitle
                  : null;

              final backdrop = Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: 500,
                child: IgnorePointer(
                  child: _AmbientBackdrop(
                    coverUrl: anime.coverUrl,
                    coverColor: anime.coverColor,
                    pageBg: pageBg,
                  ),
                ),
              );

              final infoScrollView = CustomScrollView(
                controller: _scroll,
                physics: const AppScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: _Hero(
                      anime: anime,
                      details: _details,
                      accent: accent,
                      palette: palette,
                      inset: paneInset,
                      leftInset: leftPaneInset,
                      heroTag:
                          widget.heroTag ?? 'anime-poster-${anime.id}',
                      heroEnabled: _selectedTab == 0 || isDualPane,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: ValueListenableBuilder<AnimeDetails?>(
                      valueListenable: _detailsNotifier,
                      builder: (context, details, _) {
                        return _InfoBody(
                          anime: anime,
                          details: details,
                          genreCoversNotifier: _genreCoversNotifier,
                          error: _error,
                          accent: accent,
                          inset: paneInset,
                          leftInset: leftPaneInset,
                          bottom: bottom,
                          savedNotifier: _savedNotifier,
                          subscribedNotifier: _subscribedNotifier,
                          watchStatusNotifier: _watchStatusNotifier,
                          savedWatchStateNotifier: _savedWatchStateNotifier,
                          watchProvider: _watchProvider,
                          onRetry: _retry,
                          onWatch: _onWatchNow,
                          onSave: _toggleSave,
                          onSubscribe: _toggleSubscription,
                          onStatusManage: _openCollectionStatusSheet,
                          onShare: _onShare,
                          onTrailer: _openTrailer,
                          showWatchRow: true,
                          showPlayButton: !isDualPane,
                        );
                      },
                    ),
                  ),
                ],
              );

              final watchView = ChangeNotifierProvider<WatchProvider>.value(
                value: _watchProvider,
                child: ValueListenableBuilder<AnimeDetails?>(
                  valueListenable: _detailsNotifier,
                  builder: (context, details, _) {
                    return WatchView(
                      anime: anime,
                      accent: accent,
                      bottom: isDualPane ? 16 : bottom,
                      embedded: isDualPane,
                      details: details,
                    );
                  },
                ),
              );

              if (isDualPane) {
                return PopScope(
                  canPop: true,
                  onPopInvokedWithResult: (didPop, _) {
                    if (didPop) {
                      _watchProvider.cancelPlayback();
                      if (_ownRoute != null) {
                        MainNavigation.removeRouteRailTheme(_ownRoute!);
                        _ownRoute = null;
                      }
                    }
                  },
                  child: Scaffold(
                    backgroundColor: pageBg,
                    body: Stack(
                      children: [
                        backdrop,
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final railOffset = isWide ? kRailWidth : 0.0;
                            final availableWidth =
                                constraints.maxWidth - railOffset;
                            final leftPaneWidth =
                                railOffset + (availableWidth / 2);

                            return Row(
                              children: [
                                SizedBox(
                                  width: leftPaneWidth,
                                  child: Stack(
                                    children: [
                                      infoScrollView,
                                      _TopBar(
                                        opacity: _barOpacity,
                                        title: anime.title,
                                        subtitle: romaji,
                                        inset: paneInset,
                                        leftInset: leftPaneInset,
                                      ),
                                    ],
                                  ),
                                ),
                                VerticalDivider(
                                  width: 1,
                                  thickness: 1,
                                  color: cs.outlineVariant.withValues(alpha: 0.35),
                                ),
                                Expanded(
                                  child: watchView,
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }

              return PopScope(
                canPop: true,
                onPopInvokedWithResult: (didPop, _) {
                  if (didPop) {
                    _watchProvider.cancelPlayback();
                    if (_ownRoute != null) {
                      MainNavigation.removeRouteRailTheme(_ownRoute!);
                      _ownRoute = null;
                    }
                  }
                },
                child: Scaffold(
                  backgroundColor: pageBg,
                  body: Stack(
                    children: [
                      backdrop,
                      IndexedStack(
                        index: _selectedTab,
                        children: [
                          infoScrollView,
                          if (_hasOpenedWatchTab)
                            (isWide
                                ? Padding(
                                    padding: const EdgeInsets.only(
                                      left: kRailWidth,
                                    ),
                                    child: watchView,
                                  )
                                : watchView)
                          else
                            const SizedBox.shrink(),
                        ],
                      ),
                      _TopBar(
                        opacity: _barOpacity,
                        title: anime.title,
                        subtitle: romaji,
                        inset: paneInset,
                        leftInset: leftPaneInset,
                      ),
                      Positioned(
                        left: isWide ? kRailWidth : 0,
                        right: 0,
                        bottom:
                            kNavBarBottomMargin +
                            MediaQuery.viewPaddingOf(themedContext).bottom,
                        child: RepaintBoundary(
                          child: Center(
                            child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 200),
                            child: Style2PillNavBar(
                              navBarConfig: NavBarConfig(
                                selectedIndex: _selectedTab,
                                items: [
                                  ItemConfig(
                                    icon: const Icon(Icons.info_rounded),
                                    inactiveIcon: const Icon(
                                      Icons.info_outline_rounded,
                                    ),
                                    title: 'Info',
                                    iconSize: 22,
                                    activeForegroundColor: cs.onPrimary,
                                    inactiveForegroundColor:
                                        cs.onSurfaceVariant,
                                    activeColorSecondary: cs.primary,
                                    textStyle: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                  ItemConfig(
                                    icon: const Icon(Icons.play_circle_rounded),
                                    inactiveIcon: const Icon(
                                      Icons.play_circle_outline_rounded,
                                    ),
                                    title: 'Watch',
                                    iconSize: 22,
                                    activeForegroundColor: cs.onPrimary,
                                    inactiveForegroundColor:
                                        cs.onSurfaceVariant,
                                    activeColorSecondary: cs.primary,
                                    textStyle: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                                onItemSelected: (index) {
                                  if (_selectedTab != index) {
                                    HapticFeedback.selectionClick();
                                    _watchProvider.handleTabVisibility(
                                      index == 1,
                                    );
                                    if (index == 0) {
                                      _watchProvider.cancelPlayback();
                                    }
                                    if (index == 1) {
                                      _initWatchTab(overrideAccent: accent);
                                    }
                                    setState(() => _selectedTab = index);
                                  }
                                },
                              ),
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(50),
                                boxShadow: [
                                  BoxShadow(
                                    color: accent.withValues(
                                      alpha: isDark ? 0.20 : 0.12,
                                    ),
                                    blurRadius: 18,
                                    spreadRadius: 1,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                                border: Border.all(
                                  color: cs.outlineVariant.withValues(
                                    alpha: isDark ? 0.35 : 0.45,
                                  ),
                                  width: 0.9,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// Top bar
// ═════════════════════════════════════════════════════════════════════════

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.opacity,
    required this.title,
    this.subtitle,
    required this.inset,
    this.leftInset,
  });

  final ValueListenable<double> opacity;
  final String title;
  final String? subtitle;
  final double inset;
  final double? leftInset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final top = MediaQuery.paddingOf(context).top;

    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      child: RepaintBoundary(
        child: Stack(
          children: [
            // ── Backdrop Layer (Transition Blur -> Full Solid at t >= 1.0) ──
            Positioned.fill(
              child: ValueListenableBuilder<double>(
                valueListenable: opacity,
                builder: (context, rawProgress, _) {
                  final t = rawProgress.clamp(0.0, 1.0);
                  if (t <= 0.02) return const SizedBox.shrink();

                  final borderColor = cs.outlineVariant.withValues(
                    alpha: (isDark ? 0.30 : 0.40) * t,
                  );

                  // ── Full Solid Phase (t >= 1.0) ──
                  // Once fully collapsed, render 100% opaque solid surface with ZERO
                  // BackdropFilter or shader passes. 0.00 ms GPU time for the rest of the scroll.
                  if (t >= 1.0) {
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        color: cs.surface,
                        border: Border(
                          bottom: BorderSide(
                            color: borderColor,
                            width: 0.8,
                          ),
                        ),
                      ),
                    );
                  }

                  // ── Transition Phase (0.02 < t < 1.0) ──
                  // While transitioning to solid, keep the frosted blur active.
                  final transitionBg = Color.lerp(
                    Colors.transparent,
                    cs.surface,
                    t,
                  )!;

                  return ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: 8 * t,
                        sigmaY: 8 * t,
                      ),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: transitionBg,
                          border: Border(
                            bottom: BorderSide(
                              color: borderColor,
                              width: 0.8,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // ── Foreground Content Layer (Back Button & Title) ──
            Container(
              padding: EdgeInsets.fromLTRB(
                leftInset ?? inset,
                top + 6,
                inset,
                8,
              ),
              child: Row(
                children: [
                  _NavButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: 'Back',
                    onTap: () => Navigator.of(context).maybePop(),
                    opacity: opacity,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ValueListenableBuilder<double>(
                      valueListenable: opacity,
                      builder: (context, rawProgress, _) {
                        final t = rawProgress.clamp(0.0, 1.0);
                        final hasSubtitle =
                            subtitle != null && subtitle!.trim().isNotEmpty;

                        final titleColor =
                            Color.lerp(Colors.white, cs.onSurface, t)!;
                        final subtitleColor = Color.lerp(
                          Colors.white.withValues(alpha: 0.75),
                          cs.onSurfaceVariant,
                          t,
                        )!;
                        final textShadow = t < 0.8
                            ? [
                                Shadow(
                                  color: Colors.black.withValues(
                                    alpha: (1.0 - t) * 0.50,
                                  ),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ]
                            : null;

                        if (!hasSubtitle) {
                          return Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontSize: 16.0,
                              fontWeight: FontWeight.w700,
                              color: titleColor,
                              shadows: textShadow,
                            ),
                          );
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                height: 1.15,
                                color: titleColor,
                                shadows: textShadow,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                height: 1.15,
                                color: subtitleColor,
                                shadows: textShadow,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    required this.opacity,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final ValueListenable<double> opacity;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Tooltip(
      message: tooltip,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: ValueListenableBuilder<double>(
            valueListenable: opacity,
            builder: (context, progress, _) {
              final t = progress.clamp(0.0, 1.0);
              final bgColor = Color.lerp(
                Colors.black.withValues(alpha: 0.38),
                Colors.transparent,
                t,
              )!;
              final borderColor = Color.lerp(
                Colors.white.withValues(alpha: 0.18),
                Colors.transparent,
                t,
              )!;
              final iconColor = Color.lerp(Colors.white, cs.onSurface, t)!;

              return Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                  border: t < 0.95
                      ? Border.all(color: borderColor, width: 0.8)
                      : null,
                ),
                child: Icon(icon, size: 20, color: iconColor),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// Hero: poster artwork backdrop, centered poster, score tab & actions
// ═════════════════════════════════════════════════════════════════════════
// Ambient backdrop
// ═════════════════════════════════════════════════════════════════════════

/// Ambient blurred anime poster artwork that glows behind the header area
/// of both the Info and Watch tabs, as well as spanning the entire dual-pane
/// width on wide screens.
class _AmbientBackdrop extends StatelessWidget {
  const _AmbientBackdrop({
    required this.coverUrl,
    required this.coverColor,
    required this.pageBg,
  });

  final String? coverUrl;
  final int? coverColor;
  final Color pageBg;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        height: 500,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRect(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(
                  sigmaX: 16,
                  sigmaY: 16,
                  tileMode: TileMode.clamp,
                ),
                child: Transform.scale(
                  scale: 1.35,
                  alignment: Alignment.topCenter,
                  child: AnimeImage(
                    coverUrl,
                    tint: coverColor,
                    alignment: Alignment.topCenter,
                    cacheWidth: 140,
                  ),
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.35, 0.65, 0.92, 1.0],
                  colors: [
                    Colors.black.withValues(alpha: 0.60),
                    Colors.black.withValues(alpha: 0.40),
                    pageBg.withValues(alpha: 0.70),
                    pageBg,
                    pageBg,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.anime,
    required this.details,
    required this.accent,
    required this.palette,
    required this.inset,
    this.leftInset,
    required this.heroTag,
    this.heroEnabled = true,
  });

  final AnimeMedia anime;
  final AnimeDetails? details;
  final Color accent;
  final CoverPalette? palette;
  final double inset;
  final double? leftInset;
  final String heroTag;
  final bool heroEnabled;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final media = details?.media ?? anime;
    final score = media.scoreLabel;

    return RepaintBoundary(
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            leftInset ?? inset,
            top + 68,
            inset,
            16,
          ),
          child: _HeroCompact(
            anime: anime,
            media: media,
            accent: accent,
            palette: palette,
            score: score,
            heroTag: heroTag,
            heroEnabled: heroEnabled,
          ),
        ),
      ),
    );
  }
}

class _HeroCompact extends StatelessWidget {
  const _HeroCompact({
    required this.anime,
    required this.media,
    required this.accent,
    required this.palette,
    required this.score,
    required this.heroTag,
    this.heroEnabled = true,
  });

  final AnimeMedia anime;
  final AnimeMedia media;
  final Color accent;
  final CoverPalette? palette;
  final String? score;
  final String heroTag;
  final bool heroEnabled;

  @override
  Widget build(BuildContext context) {
    final glow = palette?.accent ?? accent;

    final Widget posterContent = Material(
      type: MaterialType.transparency,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(kPosterRadius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            AnimeImage(
              anime.coverUrl,
              tint: anime.coverColor,
              cacheWidth: 450,
            ),
            if (score != null)
              Positioned(
                left: 8,
                bottom: 8,
                child: ScoreBadge(score!, tint: accent),
              ),
            if (media.statusLabel != null)
              Positioned(
                right: 8,
                bottom: 8,
                child: StatusBadge(
                  status: media.status,
                  label: media.statusLabel!,
                  tint: accent,
                ),
              ),
            if (media.isAdult)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.45),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Text(
                    '18+',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                      height: 1.1,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    final Widget poster = heroEnabled
        ? Hero(
            tag: heroTag,
            transitionOnUserGestures: true,
            child: posterContent,
          )
        : posterContent;

    return Center(
      child: Container(
        width: _kPosterWidth,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kPosterRadius),
          boxShadow: [
            BoxShadow(
              color: glow.withValues(alpha: 0.40),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: AspectRatio(aspectRatio: kPosterAspect, child: poster),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// Status selector button (Add to List / Current Watch Status)
// ═════════════════════════════════════════════════════════════════════════

class _StatusButton extends StatelessWidget {
  const _StatusButton({
    required this.status,
    required this.onTap,
    this.height = 48,
  });

  final String? status;
  final VoidCallback onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final resolved = CollectionStatus.fromId(status);
    final title = resolved?.title ?? 'Add to List';
    final icon = resolved?.icon ?? Icons.playlist_add_rounded;
    final color = resolved?.color ?? cs.onSurface;

    final isSet = status != null;

    return SizedBox(
      height: height,
      child: Material(
        color: isSet
            ? color.withValues(alpha: 0.12)
            : cs.surfaceContainerHighest.withValues(alpha: 0.9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isSet
                ? color.withValues(alpha: 0.4)
                : cs.outlineVariant.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20, color: isSet ? color : cs.primary),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSet ? FontWeight.w800 : FontWeight.w700,
                      color: isSet ? color : cs.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_drop_down_rounded,
                  size: 20,
                  color: isSet
                      ? color.withValues(alpha: 0.8)
                      : cs.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


// ═════════════════════════════════════════════════════════════════════════
// Action buttons row (Watch now, Save, Trailer)
// ═════════════════════════════════════════════════════════════════════════

class _WatchRow extends StatelessWidget {
  const _WatchRow({
    required this.savedNotifier,
    required this.subscribedNotifier,
    required this.watchStatusNotifier,
    required this.savedWatchStateNotifier,
    required this.watchProvider,
    required this.anime,
    this.nextAiring,
    this.onWatch,
    required this.onSave,
    this.onSubscribe,
    this.onStatusManage,
    required this.onShare,
    this.isUpcoming = false,
    this.onTrailer,
    this.showPlayButton = true,
  });

  final ValueListenable<bool> savedNotifier;
  final ValueListenable<bool> subscribedNotifier;
  final ValueListenable<String?> watchStatusNotifier;
  final ValueListenable<({int episode, String provider, String audio})?>
      savedWatchStateNotifier;
  final WatchProvider watchProvider;
  final AnimeMedia anime;
  final NextAiring? nextAiring;
  final VoidCallback? onWatch;
  final VoidCallback onSave;
  final VoidCallback? onSubscribe;
  final VoidCallback? onStatusManage;
  final VoidCallback onShare;
  final bool isUpcoming;
  final VoidCallback? onTrailer;
  final bool showPlayButton;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ListenableBuilder(
        listenable: Listenable.merge([
          savedNotifier,
          subscribedNotifier,
          watchStatusNotifier,
          savedWatchStateNotifier,
          watchProvider,
        ]),
        builder: (context, _) {
          final cs = Theme.of(context).colorScheme;
          final saved = savedNotifier.value;
          final subscribed = subscribedNotifier.value;
          final watchStatus = watchStatusNotifier.value;
          final epNum = watchProvider.currentEpisode?.number ??
              savedWatchStateNotifier.value?.episode;
          final watchLabel =
              epNum != null ? 'Resume Episode $epNum' : 'Watch Now';
          final canSubscribe = (subscribed ||
              SubscriptionRepository.instance.canSubscribe(anime, nextAiring)) &&
              onSubscribe != null;

          if (!showPlayButton) {
            return Row(
              children: [
                Expanded(
                  child: _StatusButton(
                    status: watchStatus,
                    onTap: onStatusManage ?? () {},
                    height: 50,
                  ),
                ),
                const SizedBox(width: 12),
                IconButton.filledTonal(
                  onPressed: onSave,
                  tooltip: saved ? 'Remove from favorites' : 'Add to favorites',
                  style: IconButton.styleFrom(
                    fixedSize: const Size(50, 50),
                    backgroundColor: cs.surfaceContainerHighest.withValues(
                      alpha: 0.9,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: Icon(
                    saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: saved ? Colors.redAccent : cs.onSurface,
                  ),
                ),
                if (canSubscribe) ...[
                  const SizedBox(width: 12),
                  IconButton.filledTonal(
                    onPressed: onSubscribe,
                    tooltip: subscribed
                        ? 'Unsubscribe from alerts'
                        : 'Get episode alerts',
                    style: IconButton.styleFrom(
                      fixedSize: const Size(50, 50),
                      backgroundColor: cs.surfaceContainerHighest.withValues(
                        alpha: 0.9,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: Icon(
                      subscribed
                          ? Icons.notifications_active_rounded
                          : Icons.notifications_none_rounded,
                      color: subscribed ? cs.primary : cs.onSurface,
                    ),
                  ),
                ],
                const SizedBox(width: 12),
                IconButton.filledTonal(
                  onPressed: onShare,
                  tooltip: 'Share',
                  style: IconButton.styleFrom(
                    fixedSize: const Size(50, 50),
                    backgroundColor: cs.surfaceContainerHighest.withValues(
                      alpha: 0.9,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: Icon(Icons.share_rounded, color: cs.onSurface),
                ),
              ],
            );
          }

          final primaryAction = isUpcoming
              ? (onTrailer != null
                    ? FilledButton.icon(
                        onPressed: onTrailer,
                        icon: const Icon(Icons.smart_display_rounded, size: 22),
                        label: const Text('Watch Trailer'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          backgroundColor: cs.primary,
                          foregroundColor: cs.onPrimary,
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                      )
                    : FilledButton.tonalIcon(
                        onPressed: onWatch,
                        icon: const Icon(Icons.schedule_rounded, size: 22),
                        label: const Text('Not Yet Aired'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          backgroundColor: cs.surfaceContainerHighest,
                          foregroundColor: cs.onSurfaceVariant,
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                      ))
              : FilledButton.icon(
                  onPressed: onWatch,
                  icon: const Icon(Icons.play_arrow_rounded, size: 24),
                  label: Text(watchLabel),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                );

          final isSingleRow =
              MediaQuery.sizeOf(context).shortestSide >= 600 ||
              context.contentWidth >= 540;

          if (isSingleRow) {
            return Row(
              children: [
                Expanded(
                  flex: 3,
                  child: primaryAction,
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: _StatusButton(
                    status: watchStatus,
                    onTap: onStatusManage ?? () {},
                    height: 50,
                  ),
                ),
                const SizedBox(width: 12),
                IconButton.filledTonal(
                  onPressed: onSave,
                  tooltip: saved ? 'Remove from favorites' : 'Add to favorites',
                  style: IconButton.styleFrom(
                    fixedSize: const Size(50, 50),
                    backgroundColor: cs.surfaceContainerHighest.withValues(
                      alpha: 0.9,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: Icon(
                    saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: saved ? Colors.redAccent : cs.onSurface,
                  ),
                ),
                if (canSubscribe) ...[
                  const SizedBox(width: 12),
                  IconButton.filledTonal(
                    onPressed: onSubscribe,
                    tooltip: subscribed
                        ? 'Unsubscribe from alerts'
                        : 'Get episode alerts',
                    style: IconButton.styleFrom(
                      fixedSize: const Size(50, 50),
                      backgroundColor: cs.surfaceContainerHighest.withValues(
                        alpha: 0.9,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: Icon(
                      subscribed
                          ? Icons.notifications_active_rounded
                          : Icons.notifications_none_rounded,
                      color: subscribed ? cs.primary : cs.onSurface,
                    ),
                  ),
                ],
                const SizedBox(width: 12),
                IconButton.filledTonal(
                  onPressed: onShare,
                  tooltip: 'Share',
                  style: IconButton.styleFrom(
                    fixedSize: const Size(50, 50),
                    backgroundColor: cs.surfaceContainerHighest.withValues(
                      alpha: 0.9,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: Icon(Icons.share_rounded, color: cs.onSurface),
                ),
              ],
            );
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              primaryAction,
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _StatusButton(
                      status: watchStatus,
                      onTap: onStatusManage ?? () {},
                      height: 48,
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filledTonal(
                    onPressed: onSave,
                    tooltip: saved ? 'Remove from favorites' : 'Add to favorites',
                    style: IconButton.styleFrom(
                      fixedSize: const Size(48, 48),
                      backgroundColor: cs.surfaceContainerHighest.withValues(
                        alpha: 0.9,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: Icon(
                      saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: saved ? Colors.redAccent : cs.onSurface,
                    ),
                  ),
                  if (canSubscribe) ...[
                    const SizedBox(width: 10),
                    IconButton.filledTonal(
                      onPressed: onSubscribe,
                      tooltip: subscribed
                          ? 'Unsubscribe from alerts'
                          : 'Get episode alerts',
                      style: IconButton.styleFrom(
                        fixedSize: const Size(48, 48),
                        backgroundColor: cs.surfaceContainerHighest.withValues(
                          alpha: 0.9,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: Icon(
                        subscribed
                            ? Icons.notifications_active_rounded
                            : Icons.notifications_none_rounded,
                        color: subscribed ? cs.primary : cs.onSurface,
                      ),
                    ),
                  ],
                  const SizedBox(width: 10),
                  IconButton.filledTonal(
                    onPressed: onShare,
                    tooltip: 'Share',
                    style: IconButton.styleFrom(
                      fixedSize: const Size(48, 48),
                      backgroundColor: cs.surfaceContainerHighest.withValues(
                        alpha: 0.9,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: Icon(Icons.share_rounded, color: cs.onSurface),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// Details body
// ═════════════════════════════════════════════════════════════════════════

class _InfoBody extends StatelessWidget {
  const _InfoBody({
    required this.anime,
    required this.details,
    required this.error,
    required this.accent,
    required this.inset,
    this.leftInset,
    required this.bottom,
    required this.savedNotifier,
    required this.subscribedNotifier,
    required this.watchStatusNotifier,
    required this.savedWatchStateNotifier,
    required this.watchProvider,
    required this.onRetry,
    required this.onWatch,
    required this.onSave,
    this.onSubscribe,
    this.onStatusManage,
    required this.onShare,
    required this.onTrailer,
    this.genreCoversNotifier,
    this.showWatchRow = true,
    this.showPlayButton = true,
  });

  final AnimeMedia anime;
  final AnimeDetails? details;
  final Object? error;
  final Color accent;
  final double inset;
  final double? leftInset;
  final double bottom;
  final ValueListenable<bool> savedNotifier;
  final ValueListenable<bool> subscribedNotifier;
  final ValueListenable<String?> watchStatusNotifier;
  final ValueListenable<({int episode, String provider, String audio})?>
      savedWatchStateNotifier;
  final WatchProvider watchProvider;
  final VoidCallback onRetry;
  final VoidCallback onWatch;
  final VoidCallback onSave;
  final VoidCallback? onSubscribe;
  final VoidCallback? onStatusManage;
  final VoidCallback onShare;
  final ValueChanged<AnimeTrailer> onTrailer;
  final ValueListenable<Map<String, String>?>? genreCoversNotifier;
  final bool showWatchRow;
  final bool showPlayButton;

  Widget _p(Widget w) => Padding(
    padding: EdgeInsets.fromLTRB(leftInset ?? inset, 0, inset, 0),
    child: w,
  );

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final d = details;
    final media = d?.media ?? anime;
    final loading = d == null && error == null;
    final genres = media.genres.isNotEmpty ? media.genres : anime.genres;
    final tags = d?.tags ?? const [];
    final next = media.nextAiring;
    final trailer = d?.trailer;
    final infoItems = _buildInfoItems(media, d);

    return Padding(
      padding: EdgeInsets.only(top: 10, bottom: bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Unified quick stats strip ──
          _p(
            DetailsStatsRow(popularity: media.popularity, favourites: d?.favourites),
          ),

          // ── Next episode countdown card ──
          if (next != null && media.status == 'RELEASING') ...[
            const SizedBox(height: 14),
            _p(DetailsNextEpisodeCard(next: next)),
          ],

          // ── Watch Row (below Next Episode card) ──
          if (showWatchRow) ...[
            const SizedBox(height: 16),
            _p(
              _WatchRow(
                savedNotifier: savedNotifier,
                subscribedNotifier: subscribedNotifier,
                watchStatusNotifier: watchStatusNotifier,
                savedWatchStateNotifier: savedWatchStateNotifier,
                watchProvider: watchProvider,
                anime: media,
                nextAiring: next,
                onWatch: onWatch,
                onSave: onSave,
                onSubscribe: onSubscribe,
                onStatusManage: onStatusManage,
                onShare: onShare,
                isUpcoming: media.isUpcoming,
                onTrailer: trailer != null ? () => onTrailer(trailer) : null,
                showPlayButton: showPlayButton,
              ),
            ),
          ],

          // ── Synopsis ──
          _Section(
            title: 'Synopsis',
            icon: Icons.notes_rounded,
            color: cs.primary,
            inset: inset,
            leftInset: leftInset,
            child: DetailsSynopsis(text: d?.description, loading: loading),
          ),

          // ── Genres (horizontal scroll cards) ──
          if (genres.isNotEmpty)
            _Section(
              title: 'Genres',
              icon: Icons.category_rounded,
              color: cs.primary,
              inset: inset,
              leftInset: leftInset,
              bleed: true,
              child: genreCoversNotifier != null
                  ? ValueListenableBuilder<Map<String, String>?>(
                      valueListenable: genreCoversNotifier!,
                      builder: (context, covers, _) => _HScroll(
                        height: 76,
                        inset: inset,
                        leftInset: leftInset,
                        itemCount: genres.length,
                        itemBuilder: (_, i) => DetailsGenreCard(
                          genre: genres[i],
                          coverUrl: covers?[genres[i]],
                        ),
                      ),
                    )
                  : _HScroll(
                      height: 76,
                      inset: inset,
                      leftInset: leftInset,
                      itemCount: genres.length,
                      itemBuilder: (_, i) => DetailsGenreCard(
                        genre: genres[i],
                      ),
                    ),
            ),

          // ── Tags (clean wrapped chips, collapsed by default) ──
          if (tags.isNotEmpty)
            _Section(
              title: 'Tags',
              icon: Icons.sell_rounded,
              color: cs.primary,
              inset: inset,
              leftInset: leftInset,
              child: DetailsTagsWrap(tags: tags),
            ),

          // ── Trailer ──
          if (trailer != null && trailer.thumbnail != null)
            _Section(
              title: 'Trailer',
              icon: Icons.smart_display_rounded,
              color: cs.primary,
              inset: inset,
              leftInset: leftInset,
              child: DetailsTrailerCard(
                trailer: trailer,
                onTap: () => onTrailer(trailer),
              ),
            ),

          // ── Information (One UI grouped table, without row icons) ──
          _Section(
            title: 'Information',
            icon: Icons.info_outline_rounded,
            color: cs.primary,
            inset: inset,
            leftInset: leftInset,
            child: DetailsMetadataTable(items: infoItems),
          ),

          // ── Error notice ──
          if (error != null && d == null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: _p(
                ErrorCard(
                  message: error is AnilistException
                      ? (error as AnilistException).message
                      : "Couldn't load all the details.",
                  onRetry: onRetry,
                ),
              ),
            ),

          // ── Characters ──
          if (loading)
            _Section(
              title: 'Characters',
              icon: Icons.groups_rounded,
              color: cs.primary,
              inset: inset,
              leftInset: leftInset,
              bleed: true,
              child: _HScroll(
                height: 108 / kPosterAspect + animeCardTextHeight(context),
                inset: inset,
                leftInset: leftInset,
                itemCount: 5,
                itemBuilder: (_, _) => const AnimeCardSkeleton(width: 108),
              ),
            ),

          if (d != null && d.characters.isNotEmpty)
            _Section(
              title: 'Characters',
              icon: Icons.groups_rounded,
              color: cs.primary,
              inset: inset,
              leftInset: leftInset,
              bleed: true,
              child: _HScroll(
                height: 108 / kPosterAspect + animeCardTextHeight(context),
                inset: inset,
                leftInset: leftInset,
                itemCount: d.characters.length,
                itemBuilder: (_, i) =>
                    DetailsCharacterCard(character: d.characters[i]),
              ),
            ),

          // ── Related anime ──
          if (d != null && d.relations.isNotEmpty)
            _Section(
              title: 'Related',
              icon: Icons.account_tree_rounded,
              color: cs.primary,
              inset: inset,
              leftInset: leftInset,
              bleed: true,
              child: _HScroll(
                height: 120 / kPosterAspect + animeCardTextHeight(context) + 28,
                inset: inset,
                leftInset: leftInset,
                itemCount: d.relations.length,
                itemBuilder: (_, i) {
                  final r = d.relations[i];
                  return SizedBox(
                    width: 120,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            r.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: cs.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        AnimeCard(
                          anime: r.media,
                          width: 120,
                          heroPrefix: 'details-related-${anime.id}',
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

          // ── Recommendations ──
          if (d != null && d.recommendations.isNotEmpty)
            _Section(
              title: 'You Might Also Like',
              icon: Icons.thumb_up_alt_rounded,
              color: cs.primary,
              inset: inset,
              leftInset: leftInset,
              bleed: true,
              child: _HScroll(
                height: 120 / kPosterAspect + animeCardTextHeight(context),
                inset: inset,
                leftInset: leftInset,
                itemCount: d.recommendations.length,
                itemBuilder: (_, i) => AnimeCard(
                  anime: d.recommendations[i].media,
                  width: 120,
                  heroPrefix: 'details-rec-${anime.id}',
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<DetailsMetadataItem> _buildInfoItems(AnimeMedia m, AnimeDetails? d) {
    final list = <DetailsMetadataItem>[];
    void add(String label, String? value) {
      if (value != null && value.trim().isNotEmpty) {
        list.add(DetailsMetadataItem(label: label, value: value));
      }
    }

    if (m.isAdult) {
      add('Rating', '18+ (Adult)');
    }
    add('Format', m.formatLabel);
    add('Status', m.statusLabel);
    add('Episodes', m.episodes?.toString());
    add('Duration', d?.duration == null ? null : '${d!.duration} min');
    add('Aired', d?.airedLabel ?? m.startDate?.label);
    add('Season', d?.seasonLabel);
    add('Studio', d == null || d.studios.isEmpty ? null : d.studios.join(', '));
    add('Native title', d?.nativeTitle);
    add(
      'Synonyms',
      d == null || d.synonyms.isEmpty ? null : d.synonyms.take(2).join(', '),
    );

    return list;
  }
}

// ── Section scaffolding ─────────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    this.color,
    required this.inset,
    this.leftInset,
    required this.child,
    this.bleed = false,
  });

  final String title;
  final IconData icon;
  final Color? color;
  final double inset;
  final double? leftInset;
  final Widget child;
  final bool bleed;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.primary;
    final effectiveLeft = leftInset ?? inset;
    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.only(top: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: title,
              icon: icon,
              color: effectiveColor,
              inset: inset,
              leftInset: effectiveLeft,
            ),
            const SizedBox(height: 14),
            if (bleed)
              child
            else
              Padding(
                padding: EdgeInsets.fromLTRB(effectiveLeft, 0, inset, 0),
                child: child,
              ),
          ],
        ),
      ),
    );
  }
}

class _HScroll extends StatelessWidget {
  const _HScroll({
    required this.height,
    required this.inset,
    this.leftInset,
    required this.itemCount,
    required this.itemBuilder,
  });

  final double height;
  final double inset;
  final double? leftInset;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        height: height,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const AppScrollPhysics(),
          padding: EdgeInsets.fromLTRB(leftInset ?? inset, 0, inset, 0),
          itemCount: itemCount,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: itemBuilder,
        ),
      ),
    );
  }
}
