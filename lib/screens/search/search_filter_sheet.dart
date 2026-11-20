import 'package:flutter/material.dart';
import 'package:aniways/core/storage/shared_preferences_service.dart';
import 'package:aniways/core/widgets/one_ui_bottom_sheet.dart';
import 'package:aniways/core/theme/genre_colors.dart';
import 'search_filter.dart';

const List<String> _kGenres = [
  'Action',
  'Adventure',
  'Comedy',
  'Drama',
  'Ecchi',
  'Fantasy',
  'Horror',
  'Mahou Shoujo',
  'Mecha',
  'Music',
  'Mystery',
  'Psychological',
  'Romance',
  'Sci-Fi',
  'Slice of Life',
  'Sports',
  'Supernatural',
  'Thriller',
];

List<int> get _kYears {
  final current = DateTime.now().year;
  return [
    current + 1,
    for (var y = current; y >= current - 12; y--) y,
    2010,
    2005,
    2000,
    1990,
  ];
}

/// Shows the One UI style search filter bottom sheet.
Future<AnimeSearchFilter?> showSearchFilterSheet(
  BuildContext context, {
  required AnimeSearchFilter initialFilter,
}) {
  return showModalBottomSheet<AnimeSearchFilter>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _SearchFilterSheet(initialFilter: initialFilter),
  );
}

class _SearchFilterSheet extends StatefulWidget {
  const _SearchFilterSheet({required this.initialFilter});

  final AnimeSearchFilter initialFilter;

  @override
  State<_SearchFilterSheet> createState() => _SearchFilterSheetState();
}

class _SearchFilterSheetState extends State<_SearchFilterSheet> {
  late AnimeSearchFilter _filter = widget.initialFilter;

  void _reset() {
    setState(() => _filter = AnimeSearchFilter.empty);
  }

  void _apply() {
    Navigator.of(context).pop(_filter);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.88;
    final bottomPadding = MediaQuery.paddingOf(context).bottom + 16;
    final adultEnabled = SharedPreferencesService().enableAdultContent;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag Handle ──
          const OneUiDragHandle(margin: EdgeInsets.only(top: 12, bottom: 8)),

          // ── Header: Title & Reset ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Filters',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (_filter.activeFilterCount > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_filter.activeFilterCount}',
                          style: TextStyle(
                            color: cs.onPrimaryContainer,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                TextButton(
                  onPressed: _filter.isDefault ? null : _reset,
                  style: TextButton.styleFrom(
                    foregroundColor: cs.primary,
                    disabledForegroundColor: cs.onSurface.withValues(alpha: 0.3),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const Text(
                    'Reset',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: cs.outlineVariant.withValues(alpha: 0.3),
          ),

          // ── Scrollable Filter Sections ──
          Flexible(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              physics: const BouncingScrollPhysics(),
              children: [
                // 1. Sort by
                _buildSectionHeader(context, 'SORT BY', Icons.sort_rounded),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _FilterChipItem<AnimeSort?>(
                      label: 'Default',
                      selected: _filter.sort == null,
                      onTap: () => setState(
                        () => _filter = _filter.copyWith(sort: () => null),
                      ),
                    ),
                    ...AnimeSort.values.map(
                      (s) => _FilterChipItem<AnimeSort>(
                        label: s.label,
                        selected: _filter.sort == s,
                        onTap: () => setState(
                          () => _filter = _filter.copyWith(
                            sort: () => _filter.sort == s ? null : s,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Age Rating (Only shown when 18+ adult mode is enabled in Settings)
                if (adultEnabled) ...[
                  _buildSectionHeader(
                    context,
                    'AGE RATING',
                    Icons.eighteen_up_rating_rounded,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...AdultFilter.values.map(
                        (af) => _FilterChipItem<AdultFilter>(
                          label: af.label,
                          icon: af == AdultFilter.adultOnly
                              ? Icons.eighteen_up_rating_rounded
                              : null,
                          accentColor:
                              af == AdultFilter.adultOnly ? cs.error : null,
                          selected:
                              (_filter.adultFilter ?? AdultFilter.all) == af,
                          onTap: () => setState(
                            () => _filter = _filter.copyWith(
                              adultFilter: () => af,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],

                // 2. Format
                _buildSectionHeader(context, 'FORMAT', Icons.video_library_rounded),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _FilterChipItem<AnimeFormat?>(
                      label: 'All Formats',
                      selected: _filter.format == null,
                      onTap: () => setState(
                        () => _filter = _filter.copyWith(format: () => null),
                      ),
                    ),
                    ...AnimeFormat.values.map(
                      (f) => _FilterChipItem<AnimeFormat>(
                        label: f.label,
                        selected: _filter.format == f,
                        onTap: () => setState(
                          () => _filter = _filter.copyWith(
                            format: () => _filter.format == f ? null : f,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 3. Status
                _buildSectionHeader(context, 'AIRING STATUS', Icons.timelapse_rounded),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _FilterChipItem<AnimeStatus?>(
                      label: 'All Statuses',
                      selected: _filter.status == null,
                      onTap: () => setState(
                        () => _filter = _filter.copyWith(status: () => null),
                      ),
                    ),
                    ...AnimeStatus.values.map(
                      (st) => _FilterChipItem<AnimeStatus>(
                        label: st.label,
                        selected: _filter.status == st,
                        onTap: () => setState(
                          () => _filter = _filter.copyWith(
                            status: () => _filter.status == st ? null : st,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 4. Season
                _buildSectionHeader(context, 'SEASON', Icons.calendar_today_rounded),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _FilterChipItem<AnimeSeason?>(
                      label: 'All Seasons',
                      selected: _filter.season == null,
                      onTap: () => setState(
                        () => _filter = _filter.copyWith(season: () => null),
                      ),
                    ),
                    ...AnimeSeason.values.map(
                      (sn) => _FilterChipItem<AnimeSeason>(
                        label: sn.label,
                        selected: _filter.season == sn,
                        onTap: () => setState(
                          () => _filter = _filter.copyWith(
                            season: () => _filter.season == sn ? null : sn,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 5. Release Year
                _buildSectionHeader(context, 'YEAR', Icons.date_range_rounded),
                const SizedBox(height: 10),
                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _FilterChipItem<int?>(
                        label: 'All Years',
                        selected: _filter.year == null,
                        onTap: () => setState(
                          () => _filter = _filter.copyWith(year: () => null),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ..._kYears.map(
                        (y) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _FilterChipItem<int>(
                            label: '$y',
                            selected: _filter.year == y,
                            onTap: () => setState(
                              () => _filter = _filter.copyWith(
                                year: () => _filter.year == y ? null : y,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 6. Genres
                _buildSectionHeader(context, 'GENRES', Icons.category_rounded),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _FilterChipItem<String?>(
                      label: 'All Genres',
                      selected: _filter.genre == null,
                      onTap: () => setState(
                        () => _filter = _filter.copyWith(genre: () => null),
                      ),
                    ),
                    ...(adultEnabled ? [..._kGenres, 'Hentai'] : _kGenres).map(
                      (g) => _FilterChipItem<String>(
                        label: g,
                        icon: genreIcon(g),
                        accentColor: genreColor(g),
                        selected: _filter.genre == g,
                        onTap: () => setState(
                          () => _filter = _filter.copyWith(
                            genre: () => _filter.genre == g ? null : g,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // ── Pinned Apply Button ──
          Container(
            padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPadding),
            decoration: BoxDecoration(
              color: cs.surface,
              border: Border(
                top: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: _apply,
                style: FilledButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  _filter.activeFilterCount > 0
                      ? 'Apply Filters (${_filter.activeFilterCount})'
                      : 'Show All Anime',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 16, color: cs.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: cs.onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

class _FilterChipItem<T> extends StatelessWidget {
  const _FilterChipItem({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.accentColor,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = accentColor ?? cs.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.16)
                : cs.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? color
                  : cs.outlineVariant.withValues(alpha: 0.4),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 15,
                  color: selected ? color : cs.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: selected ? color : cs.onSurface,
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

