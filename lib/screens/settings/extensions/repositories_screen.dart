import 'package:flutter/material.dart';
import 'package:aniways/core/widgets/one_ui_scroll_view.dart';

import 'tabs/repositories_tab.dart';

/// Secondary screen for managing extension repositories.
///
/// NOTE: assumes `OneUiSliverHeader` treats `bottom` as optional. If it is
/// required in your implementation, pass `bottom: null` or a zero-height
/// PreferredSize.
class RepositoriesScreen extends StatelessWidget {
  const RepositoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          OneUiSliverHeader(
            title: 'Repositories',
            showBackButton: true,
            actions: [
              IconButton(
                tooltip: 'Add repository',
                icon: const Icon(Icons.add_link_rounded),
                onPressed: () => showRepoDialog(context),
              ),
            ],
          ),
        ],
        body: const RepositoriesTab(),
      ),
    );
  }
}
