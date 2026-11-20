import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:aniways/core/database/repositories/collection_repository.dart';
import 'package:aniways/core/responsive.dart';
import 'package:aniways/core/widgets/anime_card.dart';
import 'package:aniways/core/widgets/one_ui_scroll_view.dart';
import 'package:aniways/models/anime_media.dart';
import 'package:aniways/models/collection_status.dart';
import 'package:aniways/navigation/main_navigation.dart'
    show MainNavigation, navBarClearance;

/// Library & Saved screen - view saved anime across Favorites, Watching,
/// Plan to Watch, Completed, On Hold, and Dropped lists with One UI collapsible appbar
/// and instant offline SQLite caching.
class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  String _selectedCollectionId = CollectionStatus.favorites.id;
  final ScrollController _tabsScrollController = ScrollController();
  late final List<GlobalKey> _tabKeys;

  static const List<CollectionStatus> _collections = CollectionStatus.all;

  @override
  void initState() {
    super.initState();
    _tabKeys = List.generate(_collections.length, (_) => GlobalKey());
  }

  @override
  void dispose() {
    _tabsScrollController.dispose();
    super.dispose();
  }

  void _selectCollection(String id) {
    if (_selectedCollectionId == id) return;
    HapticFeedback.selectionClick();
    setState(() => _selectedCollectionId = id);
    final index = _collections.indexWhere((c) => c.id == id);
    if (index != -1) {
      _scrollToTab(index);
    }
  }

  void _scrollToTab(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (index >= 0 && index < _tabKeys.length) {
        final ctx = _tabKeys[index].currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            alignment: 0.5,
          );
        }
      }
    });
  }

  void _selectNextTab() {
    final curIndex = _collections.indexWhere(
      (c) => c.id == _selectedCollectionId,
    );
    if (curIndex < _collections.length - 1) {
      _selectCollection(_collections[curIndex + 1].id);
    }
  }

  void _selectPreviousTab() {
    final curIndex = _collections.indexWhere(
      (c) => c.id == _selectedCollectionId,
    );
    if (curIndex > 0) {
      _selectCollection(_collections[curIndex - 1].id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final inset = pageInset(context);

    return Scaffold(
      body: StreamBuilder<List<AnimeMedia>>(
        stream: CollectionRepository.instance.watchCollection(
          _selectedCollectionId,
        ),
        builder: (context, snapshot) {
          final isLoading =
              snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData;
          final items = snapshot.data ?? const [];

          return GestureDetector(
            onHorizontalDragEnd: (details) {
              final velocity = details.primaryVelocity ?? 0;
              if (velocity < -250) {
                _selectNextTab();
              } else if (velocity > 250) {
                _selectPreviousTab();
              }
            },
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── One UI Collapsible Header with Pinned Collection Chips ──
                OneUiSliverHeader(
                  title: 'Library',
                  showBackButton: false,
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(54),
                    child: _buildChips(context, cs, inset),
                  ),
                ),

                // ── Body content ──
                if (isLoading)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                  )
                else if (items.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(context, cs),
                  )
                else ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(inset, 8, inset, 12),
                      child: Text(
                        '${items.length} ${items.length == 1 ? 'title' : 'titles'}',
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: inset),
                    sliver: SliverGrid.builder(
                      gridDelegate: _buildGridDelegate(context, inset),
                      itemCount: items.length,
                      itemBuilder: (context, i) {
                        final anime = items[i];
                        return AnimeCard(
                          anime: anime,
                          heroPrefix: 'saved-$_selectedCollectionId',
                        );
                      },
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(height: navBarClearance(context)),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildChips(BuildContext context, ColorScheme cs, double inset) {
    return StreamBuilder<Map<String, int>>(
      stream: CollectionRepository.instance.watchAllCollectionCounts(),
      builder: (context, countSnapshot) {
        final counts = countSnapshot.data ?? const {};

        return SizedBox(
          height: 64,
          child: SingleChildScrollView(
            controller: _tabsScrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: EdgeInsets.symmetric(horizontal: inset),
            child: Row(
              children: [
                for (int i = 0; i < _collections.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  _LibraryTabPill(
                    key: _tabKeys[i],
                    icon: _collections[i].icon,
                    label: _collections[i].title,
                    count: counts[_collections[i].id] ?? 0,
                    isSelected: _selectedCollectionId == _collections[i].id,
                    onTap: () => _selectCollection(_collections[i].id),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  SliverGridDelegate _buildGridDelegate(BuildContext context, double inset) {
    final gridWidth = context.contentWidth - inset * 2;
    const crossSpacing = 12.0;
    final columns = context.layoutSize.isCompact
        ? 2
        : gridColumns(
            gridWidth,
            minTileWidth: 170,
            maxColumns: 7,
            spacing: crossSpacing,
          );
    final cardWidth = (gridWidth - crossSpacing * (columns - 1)) / columns;
    final childAspectRatio =
        cardWidth / (cardWidth / kPosterAspect + animeCardTextHeight(context));

    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: columns,
      mainAxisSpacing: 18,
      crossAxisSpacing: crossSpacing,
      childAspectRatio: childAspectRatio,
    );
  }

  Widget _buildEmptyState(BuildContext context, ColorScheme cs) {
    final current = _collections.firstWhere(
      (c) => c.id == _selectedCollectionId,
      orElse: () => _collections.first,
    );

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(current.icon, size: 34, color: cs.primary),
            ),
            const SizedBox(height: 18),
            Text(
              'No titles in ${current.title}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Add anime to ${current.title} to access them quickly here.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: cs.onSurfaceVariant, height: 1.4),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () {
                MainNavigation.switchToTab(1); // Jump to Search / Discover tab
              },
              icon: const Icon(Icons.explore_rounded, size: 20),
              label: const Text('Explore Anime'),
              style: FilledButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

class _LibraryTabPill extends StatelessWidget {
  const _LibraryTabPill({
    super.key,
    required this.icon,
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        splashColor: cs.primary.withValues(alpha: 0.14),
        highlightColor: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? cs.primary
                : cs.surfaceContainerHighest.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isSelected
                  ? cs.primary
                  : cs.outlineVariant.withValues(alpha: 0.35),
              width: 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: cs.primary.withValues(alpha: 0.32),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16.5,
                color: isSelected ? cs.onPrimary : cs.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? cs.onPrimary : cs.onSurface,
                  letterSpacing: -0.2,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 6.5),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6.5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? cs.onPrimary.withValues(alpha: 0.22)
                        : cs.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? cs.onPrimary : cs.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
