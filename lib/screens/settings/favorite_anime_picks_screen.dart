import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:aniways/core/network/anilist_service.dart';
import 'package:aniways/core/responsive.dart';
import 'package:aniways/core/storage/shared_preferences_service.dart';
import 'package:aniways/core/widgets/one_ui_scroll_view.dart';
import 'package:aniways/screens/onboarding/cards/anime_picks_card.dart';
import 'package:aniways/screens/settings/settings_components.dart';

/// Standalone screen allowing users to pick favorite anime franchises anytime
/// to tune and shape their personalized recommendations.
class FavoriteAnimePicksScreen extends StatefulWidget {
  const FavoriteAnimePicksScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<FavoriteAnimePicksScreen> createState() =>
      _FavoriteAnimePicksScreenState();
}

class _FavoriteAnimePicksScreenState extends State<FavoriteAnimePicksScreen> {
  final SharedPreferencesService _prefs = SharedPreferencesService();
  late final Set<int> _selectedIds;
  List<CuratedAnime> _animeList = const [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedIds = _prefs.onboardingFavoriteAnimeIds.toSet();
    _fetchLivePopular();
  }

  Future<void> _fetchLivePopular() async {
    try {
      final distinctAnime = await anilistService.popularFranchises(limit: 52);
      if (distinctAnime.isNotEmpty && mounted) {
        final items = distinctAnime
            .where((m) => (m.coverUrl?.isNotEmpty ?? false))
            .map((m) => CuratedAnime(
                  id: m.id,
                  title: m.title,
                  coverUrl: m.coverUrl!,
                ))
            .toList();

        setState(() {
          _animeList = items;
          _isLoading = false;
        });
        return;
      }
    } catch (_) {
      // Handled below
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _save() {
    _prefs.setOnboardingFavoriteAnimeIds(_selectedIds.toList());
  }

  void _toggle(int id) {
    HapticFeedback.selectionClick();
    setState(() {
      if (!_selectedIds.remove(id)) _selectedIds.add(id);
    });
    _save();
  }

  void _clearAll() {
    if (_selectedIds.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() => _selectedIds.clear());
    _save();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final inset = pageInset(context);

    const gridDelegate = SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: 150,
      childAspectRatio: 0.68,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
    );

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {},
      child: Scaffold(
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            OneUiSliverHeader(
              title: 'Anime you love',
              showBackButton: !widget.embedded,
              actions: [
                if (_selectedIds.isNotEmpty)
                  TextButton(
                    onPressed: _clearAll,
                    child: Text(
                      'Clear',
                      style: TextStyle(
                        color: cs.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(inset, 8, inset, 8),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tap the shows and movies you enjoy to tailor your personalized recommendations.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SettingsSwitchTile(
                      icon: Icons.auto_awesome_rounded,
                      color: cs.primary,
                      title: 'Show on Home',
                      value: _prefs.showHomeRecommendations,
                      isFirst: true,
                      isLast: true,
                      onChanged: (val) async {
                        await _prefs.setShowHomeRecommendations(val);
                        if (val) {
                          await _prefs.setDismissedAnimePicksBanner(false);
                        }
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_selectedIds.length} selected',
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: cs.primary,
                          ),
                        ),
                        if (_animeList.isNotEmpty)
                          Text(
                            '52 popular franchises',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.outline,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            if (_isLoading && _animeList.isEmpty)
              SliverPadding(
                padding: EdgeInsets.fromLTRB(inset, 0, inset, 32),
                sliver: SliverGrid.builder(
                  itemCount: 18,
                  gridDelegate: gridDelegate,
                  itemBuilder: (context, index) =>
                      const AnimePickCardSkeleton(),
                ),
              )
            else if (_animeList.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() => _isLoading = true);
                        _fetchLivePopular();
                      },
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry loading popular anime'),
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(inset, 0, inset, 32),
                sliver: SliverGrid.builder(
                  itemCount: _animeList.length,
                  gridDelegate: gridDelegate,
                  itemBuilder: (context, index) {
                    final anime = _animeList[index];
                    return AnimePickTile(
                      key: ValueKey(anime.id),
                      anime: anime,
                      isSelected: _selectedIds.contains(anime.id),
                      onTap: () => _toggle(anime.id),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

