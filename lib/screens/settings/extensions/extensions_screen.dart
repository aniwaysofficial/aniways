import 'package:flutter/material.dart';
import 'package:aniways/core/extensions/manager/extension_manager.dart';
import 'package:aniways/core/extensions/models/extension_manifest.dart';
import 'package:aniways/core/widgets/one_ui_scroll_view.dart';
import 'package:aniways/navigation/main_navigation.dart' show pushFullScreen;

import 'repositories_screen.dart';
import 'tabs/browse_extensions_tab.dart';
import 'tabs/installed_extensions_tab.dart';

/// One UI Extension Manager Screen providing centralized management, browsing,
/// and updating of decentralized streaming extensions.
///
/// Primary navigation is just Installed / Browse. Repositories are a
/// secondary screen reached from the header.
class ExtensionsScreen extends StatefulWidget {
  const ExtensionsScreen({
    super.key,
    this.initialTabIndex = 0,
    this.embedded = false,
  });

  final int initialTabIndex;
  final bool embedded;

  @override
  State<ExtensionsScreen> createState() => _ExtensionsScreenState();
}

class _ExtensionsScreenState extends State<ExtensionsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final GlobalKey<BrowseExtensionsTabState> _browseTabKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 1),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _goToBrowse() => _tabController.animateTo(1);

  Future<void> _openRepos() async {
    await pushFullScreen(context, const RepositoriesScreen());
    // Repos may have been added / removed / toggled - refresh the catalog.
    _browseTabKey.currentState?.reloadCatalog();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: StreamBuilder<List<ExtensionManifest>>(
        stream: extensionManager.dbRepository.watchInstalledExtensions(),
        builder: (context, snapshot) {
          final installedCount = snapshot.data?.length ?? 0;

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                OneUiSliverHeader(
                  title: 'Extensions',
                  showBackButton: !widget.embedded,
                  actions: [
                    IconButton(
                      tooltip: 'Repositories',
                      icon: const Icon(Icons.source_rounded),
                      onPressed: _openRepos,
                    ),
                  ],
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(56),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Container(
                        height: 42,
                        padding: const EdgeInsets.all(3.5),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: Colors.transparent,
                          indicator: BoxDecoration(
                            color: cs.primary,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: cs.primary.withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          labelColor: cs.onPrimary,
                          unselectedLabelColor: cs.onSurfaceVariant,
                          labelStyle: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                          unselectedLabelStyle: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                          tabs: [
                            Tab(text: 'Installed ($installedCount)'),
                            const Tab(text: 'Browse'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                InstalledExtensionsTab(onNavigateToBrowse: _goToBrowse),
                BrowseExtensionsTab(
                  key: _browseTabKey,
                  onNavigateToRepos: _openRepos,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
