import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:aniways/core/database/app_database.dart';
import 'package:aniways/core/extensions/manager/extension_manager.dart';
import 'package:aniways/core/extensions/manager/repo_sync_service.dart';
import 'package:aniways/core/extensions/models/extension_manifest.dart';
import 'package:aniways/core/widgets/anime_states.dart';
import 'package:aniways/core/widgets/extension_icon.dart';
import 'package:aniways/core/widgets/aniways_snackbar.dart';

import 'package:aniways/screens/settings/extensions/extensions_shared.dart';

class BrowseExtensionsTab extends StatefulWidget {
  const BrowseExtensionsTab({super.key, required this.onNavigateToRepos});

  final VoidCallback onNavigateToRepos;

  @override
  State<BrowseExtensionsTab> createState() => BrowseExtensionsTabState();
}

class BrowseExtensionsTabState extends State<BrowseExtensionsTab>
    with AutomaticKeepAliveClientMixin {
  final RepoSyncService _syncService = RepoSyncService();
  final TextEditingController _searchCtrl = TextEditingController();

  List<ExtensionRepository> _repos = [];
  List<CatalogExtensionItem> _items = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _selectedRepoId; // null = all repositories
  final Set<String> _installingIds = {};
  StreamSubscription<List<ExtensionManifest>>? _installedSub;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadCatalog();
    _installedSub = extensionManager.dbRepository
        .watchInstalledExtensions()
        .listen(_syncInstalledStatus);
  }

  @override
  void dispose() {
    _installedSub?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _syncInstalledStatus(List<ExtensionManifest> installed) {
    if (!mounted || _items.isEmpty) return;
    final installedMap = {for (final ext in installed) ext.id: ext};
    var changed = false;
    final updated = _items.map((item) {
      final local = installedMap[item.manifest.id];
      final isInstalled = local != null;
      final hasUpdate =
          local != null && item.manifest.versionCode > local.versionCode;
      if (item.isInstalled != isInstalled ||
          item.hasUpdate != hasUpdate ||
          item.installedVersion != local?.version) {
        changed = true;
        return CatalogExtensionItem(
          manifest: item.manifest,
          pkgUrl: item.pkgUrl,
          repoId: item.repoId,
          repoName: item.repoName,
          isInstalled: isInstalled,
          hasUpdate: hasUpdate,
          installedVersion: local?.version,
        );
      }
      return item;
    }).toList();

    if (changed) {
      setState(() => _items = updated);
    }
  }

  /// Exposed so the parent screen can refresh after repositories change.
  void reloadCatalog() {
    _loadCatalog();
  }

  Future<void> _loadCatalog({bool silent = false}) async {
    if (!silent && _items.isEmpty) {
      setState(() => _isLoading = true);
    }

    try {
      final repos = await extensionManager.dbRepository.getRepositories();
      final installed = await extensionManager.dbRepository
          .getInstalledExtensions();

      final allItems = <CatalogExtensionItem>[];
      for (final repo in repos) {
        if (!repo.isEnabled) continue;
        final list = await _syncService.fetchCatalog(
          repoId: repo.id,
          repoName: repo.name,
          repoUrl: repo.url,
          installed: installed,
        );
        allItems.addAll(list);
      }

      if (mounted) {
        setState(() {
          _repos = repos;
          _items = allItems;
          // If the selected repo was deleted, fall back to "All".
          if (_selectedRepoId != null &&
              !repos.any((r) => r.id == _selectedRepoId)) {
            _selectedRepoId = null;
          }
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _installOrUpdate(CatalogExtensionItem item) async {
    final id = item.manifest.id;
    setState(() => _installingIds.add(id));
    HapticFeedback.lightImpact();

    try {
      final script = await _syncService.downloadScript(item.pkgUrl);
      if (script != null && script.isNotEmpty) {
        final success = await extensionManager.installExtension(
          item.manifest,
          script,
        );
        if (success && mounted) {
          AniwaysSnackBar.success(
            context,
            message: item.hasUpdate
                ? '${item.manifest.name} updated successfully!'
                : '${item.manifest.name} installed successfully!',
          );
          // Update the installed status in-place immediately without reloading the catalog
          setState(() {
            final idx = _items.indexWhere((i) => i.manifest.id == id);
            if (idx != -1) {
              _items[idx] = CatalogExtensionItem(
                manifest: item.manifest,
                pkgUrl: item.pkgUrl,
                repoId: item.repoId,
                repoName: item.repoName,
                isInstalled: true,
                hasUpdate: false,
                installedVersion: item.manifest.version,
              );
            }
          });
        } else if (mounted) {
          AniwaysSnackBar.error(
            context,
            message: 'Failed to install ${item.manifest.name}.',
          );
        }
      } else if (mounted) {
        AniwaysSnackBar.error(
          context,
          message: 'Could not download ${item.manifest.name} script bundle.',
        );
      }
    } catch (e) {
      if (mounted) {
        AniwaysSnackBar.error(
          context,
          message: 'Error installing ${item.manifest.name}: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _installingIds.remove(id));
      }
    }
  }

  /// Filtered by repo + search, then sorted: updates → not installed → installed.
  List<CatalogExtensionItem> get _filteredItems {
    final list = _items.where((item) {
      if (_selectedRepoId != null && item.repoId != _selectedRepoId) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final nameMatches = item.manifest.name.toLowerCase().contains(q);
        final descMatches =
            item.manifest.description?.toLowerCase().contains(q) ?? false;
        final idMatches = item.manifest.id.toLowerCase().contains(q);
        return nameMatches || descMatches || idMatches;
      }
      return true;
    }).toList();

    int rank(CatalogExtensionItem i) =>
        i.hasUpdate ? 0 : (i.isInstalled ? 2 : 1);
    list.sort((a, b) => rank(a).compareTo(rank(b))); // List.sort is not stable
    return list;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final cs = Theme.of(context).colorScheme;
    final filtered = _filteredItems;

    if (_repos.isEmpty && !_isLoading) {
      return ExtensionEmptyState(
        icon: Icons.link_off_rounded,
        title: 'No Repositories Configured',
        message: 'Add an extension repository to discover and install streaming providers.',
        actionLabel: 'Add Repository',
        actionIcon: Icons.add_link_rounded,
        onAction: widget.onNavigateToRepos,
      );
    }

    return Column(
      children: [
        // Search
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: cs.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search extensions...',
                      hintStyle: TextStyle(
                        fontSize: 14,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (val) =>
                        setState(() => _searchQuery = val.trim()),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchCtrl.clear();
                      setState(() => _searchQuery = '');
                    },
                    child: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Repository filter chips (only when there is something to filter)
        if (_repos.length > 1)
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _repoChip('All', _selectedRepoId == null, () {
                  setState(() => _selectedRepoId = null);
                }),
                for (final repo in _repos)
                  _repoChip(repo.name, _selectedRepoId == repo.id, () {
                    setState(() => _selectedRepoId = repo.id);
                  }),
              ],
            ),
          ),

        const SizedBox(height: 2),

        // Catalog list
        Expanded(
          child: _isLoading && _items.isEmpty
              ? const _BrowseCatalogSkeletonList()
              : RefreshIndicator(
                  onRefresh: _loadCatalog,
                  child: filtered.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          children: [
                            const SizedBox(height: 80),
                            Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.search_off_rounded,
                                    size: 56,
                                    color: cs.onSurfaceVariant.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _searchQuery.isEmpty
                                        ? 'No extensions found in selected repository.'
                                        : 'No results matching "$_searchQuery".',
                                    style: TextStyle(
                                      color: cs.onSurfaceVariant,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 48),
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) => Divider(
                            height: 1,
                            indent: 58, // aligns with text, past the 44px icon
                            color: cs.outlineVariant.withValues(alpha: 0.25),
                          ),
                          itemBuilder: (context, index) =>
                              _buildTile(filtered[index], cs),
                        ),
                ),
        ),
      ],
    );
  }

  Widget _repoChip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        selected: selected,
        label: Text(label),
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
        onSelected: (_) {
          HapticFeedback.selectionClick();
          onTap();
        },
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  /// Flat catalog row: icon · name / meta / one-line description · action.
  Widget _buildTile(CatalogExtensionItem item, ColorScheme cs) {
    final m = item.manifest;
    final installing = _installingIds.contains(m.id);

    final Widget action;
    if (installing) {
      if (item.hasUpdate) {
        action = FilledButton(
          onPressed: () {},
          style: FilledButton.styleFrom(
            minimumSize: Size.zero,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: cs.onPrimary,
            ),
          ),
        );
      } else {
        action = Material(
          color: cs.secondaryContainer,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: CircularProgressIndicator(
                    strokeWidth: 4.5,
                    strokeCap: StrokeCap.round,
                    color: cs.primary,
                    backgroundColor: cs.primary.withValues(alpha: 0.18),
                  ),
                ),
                Icon(Icons.download_rounded, size: 20, color: cs.primary),
              ],
            ),
          ),
        );
      }
    } else if (item.hasUpdate) {
      action = FilledButton(
        onPressed: () => _installOrUpdate(item),
        style: FilledButton.styleFrom(
          minimumSize: Size.zero,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: const Text(
          'Update',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      );
    } else if (item.isInstalled) {
      action = SizedBox(
        width: 40,
        height: 40,
        child: Center(
          child: Icon(Icons.check_circle_rounded, color: cs.primary, size: 24),
        ),
      );
    } else {
      action = Material(
        color: cs.secondaryContainer,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: Tooltip(
          message: 'Install',
          child: InkWell(
            onTap: () => _installOrUpdate(item),
            child: SizedBox(
              width: 40,
              height: 40,
              child: Center(
                child: Icon(
                  Icons.download_rounded,
                  size: 20,
                  color: cs.primary,
                ),
              ),
            ),
          ),
        ),
      );
    }

    final hasDesc = m.description != null && m.description!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          ExtensionIcon(
            name: m.name,
            iconUrl: m.iconUrl,
            size: 44,
            borderRadius: 13,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        m.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (isVerifiedExtension(m))
                      const VerifiedBadge(),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  extensionMetaLine(m),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
                if (hasDesc) ...[
                  const SizedBox(height: 2),
                  Text(
                    m.description!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          action,
        ],
      ),
    );
  }
}

class _BrowseCatalogSkeletonList extends StatelessWidget {
  const _BrowseCatalogSkeletonList();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 48),
      itemCount: 8,
      separatorBuilder: (_, _) => Divider(
        height: 1,
        indent: 58,
        color: cs.outlineVariant.withValues(alpha: 0.25),
      ),
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              const Skeleton(width: 44, height: 44, radius: 13),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Skeleton(
                      width: 110.0 + (index % 3) * 35.0,
                      height: 14,
                      radius: 6,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Skeleton(width: 48, height: 10, radius: 4),
                        const SizedBox(width: 8),
                        Skeleton(
                          width: 60.0 + (index % 2) * 20.0,
                          height: 10,
                          radius: 4,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Skeleton(
                      width: double.infinity,
                      height: 11,
                      radius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Skeleton(width: 40, height: 40, radius: 20),
            ],
          ),
        );
      },
    );
  }
}
