import 'package:flutter/material.dart';

/// Single source of truth for Anime Watch and Library Collection statuses.
enum CollectionStatus {
  favorites(
    id: 'favorites',
    title: 'Favorites',
    subtitle: 'Your all-time favorite anime',
    icon: Icons.favorite_rounded,
    color: Colors.redAccent,
  ),
  watching(
    id: 'watching',
    title: 'Watching',
    subtitle: 'Currently watching episodes',
    icon: Icons.play_arrow_rounded,
    color: Colors.blueAccent,
  ),
  planToWatch(
    id: 'plan_to_watch',
    title: 'Plan to Watch',
    subtitle: 'Planned to watch later',
    icon: Icons.bookmark_rounded,
    color: Colors.amber,
  ),
  completed(
    id: 'completed',
    title: 'Completed',
    subtitle: 'Finished watching all episodes',
    icon: Icons.done_all_rounded,
    color: Colors.green,
  ),
  onHold(
    id: 'on_hold',
    title: 'On Hold',
    subtitle: 'Temporarily paused watching',
    icon: Icons.pause_circle_outline_rounded,
    color: Colors.orange,
  ),
  dropped(
    id: 'dropped',
    title: 'Dropped',
    subtitle: 'Stopped watching before finishing',
    icon: Icons.delete_outline_rounded,
    color: Colors.redAccent,
  );

  const CollectionStatus({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  /// Alias for [title] to fit chip and tab label semantics.
  String get label => title;

  /// All collections available in the Saved & Library screen.
  static const List<CollectionStatus> all = values;

  /// The 5 primary user watch statuses (excluding Favorites).
  static const List<CollectionStatus> watchStatuses = [
    watching,
    planToWatch,
    completed,
    onHold,
    dropped,
  ];

  /// Resolves a [CollectionStatus] from its unique ID string, or `null` if unset.
  static CollectionStatus? fromId(String? id) {
    if (id == null) return null;
    for (final s in values) {
      if (s.id == id) return s;
    }
    return null;
  }

  /// Convenience helper for title with fallback (e.g. 'Add to List').
  static String titleFor(String? id, [String fallback = 'Add to List']) {
    return fromId(id)?.title ?? fallback;
  }

  /// Convenience helper for icon with fallback (e.g. Icons.playlist_add_rounded).
  static IconData iconFor(
    String? id, [
    IconData fallback = Icons.playlist_add_rounded,
  ]) {
    return fromId(id)?.icon ?? fallback;
  }

  /// Convenience helper for color with fallback.
  static Color colorFor(String? id, Color fallback) {
    return fromId(id)?.color ?? fallback;
  }
}
