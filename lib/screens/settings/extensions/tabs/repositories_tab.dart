import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:aniways/core/database/app_database.dart';
import 'package:aniways/core/extensions/manager/extension_manager.dart';
import 'package:aniways/core/widgets/aniways_snackbar.dart';
import 'package:aniways/core/widgets/one_ui_bottom_sheet.dart';
import 'package:aniways/screens/settings/extensions/extensions_shared.dart';

/// Add / edit repository bottom sheet. Public so the header "+" action in
/// RepositoriesScreen can open it.
void showRepoDialog(BuildContext context, {ExtensionRepository? existing}) {
  HapticFeedback.lightImpact();
  showOneUiBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: false,
    builder: (sheetContext) => _RepoEditSheet(existing: existing),
  );
}

/// Alias for [showRepoDialog] matching bottom sheet naming.
void showRepoBottomSheet(BuildContext context, {ExtensionRepository? existing}) =>
    showRepoDialog(context, existing: existing);

class _RepoEditSheet extends StatefulWidget {
  const _RepoEditSheet({this.existing});

  final ExtensionRepository? existing;

  @override
  State<_RepoEditSheet> createState() => _RepoEditSheetState();
}

class _RepoEditSheetState extends State<_RepoEditSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _urlCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
    _urlCtrl = TextEditingController(text: widget.existing?.url ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isEditing = widget.existing != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const OneUiDragHandle(margin: EdgeInsets.only(bottom: 16)),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: isDark ? 0.20 : 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      isEditing ? Icons.edit_note_rounded : Icons.add_link_rounded,
                      color: cs.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing ? 'Edit Repository' : 'Add Repository',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 18.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isEditing
                              ? 'Update the repository name and catalog URL.'
                              : 'Catalog URL (index.json) to install extensions.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              TextField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Repository Name',
                  hintText: 'e.g. My Anime Extensions',
                  prefixIcon: const Icon(Icons.bookmark_border_rounded),
                  filled: true,
                  fillColor: cs.surfaceContainerHigh,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _urlCtrl,
                keyboardType: TextInputType.url,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: 'Catalog URL (index.json)',
                  hintText: 'https://.../index.json',
                  prefixIcon: const Icon(Icons.link_rounded),
                  filled: true,
                  fillColor: cs.surfaceContainerHigh,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        side: BorderSide(
                          color: cs.outlineVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () async {
                        final url = _urlCtrl.text.trim();
                        final name = _nameCtrl.text.trim();
                        if (url.isEmpty || !url.startsWith('http')) {
                          AniwaysSnackBar.error(
                            context,
                            message: 'Please enter a valid HTTP(S) URL.',
                          );
                          return;
                        }

                        Navigator.of(context).pop();

                        if (isEditing) {
                          await extensionManager.dbRepository.updateRepository(
                            id: widget.existing!.id,
                            name: name.isNotEmpty
                                ? name
                                : widget.existing!.name,
                            url: url,
                          );
                          if (context.mounted) {
                            AniwaysSnackBar.success(
                              context,
                              message: 'Repository updated.',
                            );
                          }
                        } else {
                          final id =
                              'repo_${DateTime.now().millisecondsSinceEpoch}';
                          await extensionManager.dbRepository.addRepository(
                            id: id,
                            name: name.isNotEmpty ? name : 'Custom Repository',
                            url: url,
                          );
                          if (context.mounted) {
                            AniwaysSnackBar.success(
                              context,
                              message: 'Repository added.',
                            );
                          }
                        }
                      },
                      child: Text(isEditing ? 'Save' : 'Add'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RepositoriesTab extends StatelessWidget {
  const RepositoriesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ExtensionRepository>>(
      stream: extensionManager.dbRepository.watchRepositories(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }

        final repos = snapshot.data!;

        if (repos.isEmpty) {
          return ExtensionEmptyState(
            icon: Icons.link_off_rounded,
            title: 'No Repositories Added',
            message:
                'Add an extension repository URL to discover, install, and update streaming providers.',
            actionLabel: 'Add Repository',
            actionIcon: Icons.add_link_rounded,
            onAction: () => showRepoDialog(context),
          );
        }

        return ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 48),
          children: [
            for (var i = 0; i < repos.length; i++)
              _RepoTile(
                repo: repos[i],
                index: i,
                count: repos.length,
                onEdit: () => showRepoDialog(context, existing: repos[i]),
              ),
          ],
        );
      },
    );
  }
}

class _RepoTile extends StatelessWidget {
  const _RepoTile({
    required this.repo,
    required this.index,
    required this.count,
    required this.onEdit,
  });

  final ExtensionRepository repo;
  final int index;
  final int count;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 2),
      child: Material(
        color: cs.surfaceContainerHigh,
        borderRadius: groupRadius(index, count),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: repo.isEnabled
                      ? cs.primaryContainer
                      : cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.folder_open_rounded,
                  color: repo.isEnabled
                      ? cs.onPrimaryContainer
                      : cs.onSurfaceVariant,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            repo.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: repo.isEnabled
                                  ? cs.onSurface
                                  : cs.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isOfficialRepo(repo.url))
                          const VerifiedBadge(size: 16),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      repo.url,
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Transform.scale(
                scale: 0.82,
                child: Switch.adaptive(
                  value: repo.isEnabled,
                  onChanged: (val) {
                    HapticFeedback.selectionClick();
                    extensionManager.dbRepository.setRepositoryEnabled(
                      repo.id,
                      val,
                    );
                  },
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: cs.onSurfaceVariant,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                onSelected: (action) {
                  if (action == 'edit') {
                    onEdit();
                  } else if (action == 'delete') {
                    _confirmDelete(context);
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 20),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.red,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    HapticFeedback.lightImpact();
    showOneUiBottomSheet<void>(
      context: context,
      isScrollControlled: false,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final cs = theme.colorScheme;
        final isDark = theme.brightness == Brightness.dark;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const OneUiDragHandle(margin: EdgeInsets.only(bottom: 20)),
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: cs.error.withValues(alpha: isDark ? 0.20 : 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.delete_forever_rounded,
                    color: cs.error,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Delete Repository?',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 19,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Are you sure you want to delete "${repo.name}"? This repository will be removed from your catalog list.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontSize: 13.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          side: BorderSide(
                            color: cs.outlineVariant.withValues(alpha: 0.5),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: cs.error,
                          foregroundColor: cs.onError,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () async {
                          Navigator.of(sheetContext).pop();
                          await extensionManager.dbRepository
                              .deleteRepository(repo.id);
                          if (context.mounted) {
                            AniwaysSnackBar.info(
                              context,
                              message: 'Repository removed.',
                            );
                          }
                        },
                        child: const Text('Delete'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
