// -----------------------------------------------------------------------------
// Dialogue Studio — workspace central (wireframe produit : 3 colonnes)
// -----------------------------------------------------------------------------
// Colonne gauche   : bibliothèque (arborescence projet + actions).
// Colonne centrale : canvas par blocs + onglets Visuel / Aperçu / Yarn.
// Colonne droite   : inspecteur du bloc sélectionné + validation.
//
// Données : [DialogueEditorDocument] (pas le Yarn brut comme vérité UX).
// -----------------------------------------------------------------------------

import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show SelectableText;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_editor/src/ui/shared/pokemap_macos_ui_shim.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../features/dialogue/application/dialogue_editor_model.dart';
import '../../features/dialogue/application/dialogue_document_session.dart';
import '../../features/dialogue/application/dialogue_editor_validation.dart';
import '../../features/dialogue/application/dialogue_preview_runner.dart';
import '../../features/dialogue/application/dialogue_yarn_codec.dart';
import '../../features/dialogue/application/mistral_dialogue_client.dart';
import '../../features/editor/state/editor_notifier.dart';
import '../../features/editor/state/editor_state.dart';
import '../../theme/theme.dart';
import '../design_system/design_system.dart';
import '../shared/cupertino_editor_widgets.dart';
import 'narrative_studio/narrative_studio_route_presentation.dart';
import 'narrative_studio/narrative_studio_workspace_page.dart';
part 'dialogue_studio/dialogs/dialogue_studio_dialogs.dart';
part 'dialogue_studio/widgets/library/dialogue_library_tree.dart';
part 'dialogue_studio/widgets/canvas/dialogue_canvas_cards.dart';

/// Sélection d’un bloc dans le graphe (racine d’un nœud ou branche de choix).
@immutable
class _StepSelection {
  const _StepSelection({
    required this.nodeId,
    required this.stepId,
    this.branchId,
  });

  final String nodeId;

  /// `null` si le bloc est dans la séquence principale du nœud.
  final String? branchId;
  final String stepId;
}

/// Option de liste pour déplacer un dossier de dialogues (parent manifeste).
class _DialogueFolderMoveOption {
  const _DialogueFolderMoveOption(this.label, this.newParentId);
  final String label;
  final String? newParentId;
}

/// Option de liste pour rattacher un dialogue à un dossier (ou racine).
class _AssignDialogueFolderDest {
  const _AssignDialogueFolderDest(this.label, this.folderId);
  final String label;
  final String? folderId;
}

@visibleForTesting
class DialoguePreviewEndedView extends StatelessWidget {
  const DialoguePreviewEndedView({
    super.key,
    required this.event,
  });

  final DialoguePreviewEnded event;

  @override
  Widget build(BuildContext context) {
    final reason = event.reason;
    final outcomeId = event.outcomeId;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            reason == null ? '— Fin —' : 'Fin : $reason',
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: PokeMapLegacyColors.secondaryLabel(context),
            ),
          ),
          if (outcomeId != null) ...[
            const SizedBox(height: 6),
            PokeMapBadge(
              label: 'Résultat · $outcomeId',
              variant: PokeMapBadgeVariant.narrative,
            ),
          ],
        ],
      ),
    );
  }
}

class DialogueStudioWorkspace extends ConsumerStatefulWidget {
  const DialogueStudioWorkspace({super.key});

  @override
  ConsumerState<DialogueStudioWorkspace> createState() =>
      _DialogueStudioWorkspaceState();
}

class _DialogueStudioWorkspaceState
    extends ConsumerState<DialogueStudioWorkspace> {
  DialogueEditorDocument? _doc;
  String? _loadedDialogueId;
  bool _loading = false;
  _StepSelection? _selection;

  /// 0 = Visuel, 1 = Aperçu, 2 = Yarn
  int _mainTab = 0;

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _instructionController = TextEditingController();

  DialoguePreviewSession? _preview;
  DialogueDocumentSession? _documentSession;
  String? _documentSessionError;
  bool _autosaveEnabled = false;
  // Compatibility state consumed by the independently staged dialog part.
  bool _savingDocument = false;
  String? _documentError;
  String? _baselineYarn;
  Future<void> _documentMutationQueue = Future<void>.value();
  int _documentOperationSequence = 0;

  bool _aiBusy = false;

  /// Erreurs IA / validation légère affichées sous le champ d’instruction.
  String? _iaError;

  /// Dossier « cible » pour les actions **Nouveau**, **Nouveau dossier** et **Importer**.
  ///
  /// `null` = racine du manifeste (dialogues sans `folderId`), comme dans les use cases
  /// [EditorNotifier.createProjectDialogue] / [EditorNotifier.importProjectDialogue].
  /// Ce n’est pas un second état de navigation décoratif : il pilote uniquement le
  /// paramètre `folderId` / `parentFolderId` passé au notifier.
  String? _sidebarTargetFolderId;

  @override
  void dispose() {
    _documentSession?.dispose();
    _searchController.dispose();
    _instructionController.dispose();
    super.dispose();
  }

  String _resolveMistralApiKey() {
    final editor = ref.read(editorNotifierProvider);
    return resolveEditorMistralApiKey(editor.project?.settings);
  }

  Future<void> _loadFromDisk(
    EditorNotifier notifier,
    EditorState editor,
  ) async {
    if (_loading) return;
    final id = editor.selectedProjectDialogueId;
    final root = editor.projectRootPath;
    final project = editor.project;
    if (id == null || root == null || project == null) {
      setState(() {
        _doc = null;
        _loadedDialogueId = null;
      });
      return;
    }
    ProjectDialogueEntry? entry;
    for (final d in project.dialogues) {
      if (d.id == id) {
        entry = d;
        break;
      }
    }
    if (entry == null) {
      setState(() {
        _doc = null;
        _loadedDialogueId = null;
      });
      return;
    }
    setState(() => _loading = true);
    try {
      final abs = p.join(root, entry.relativePath);
      final sourceFile = File(abs);
      final text = await sourceFile.readAsString();
      _documentSession?.dispose();
      final session = DialogueDocumentSession(
        dialogueId: id,
        initialYarn: text,
        load: sourceFile.readAsString,
        persist: (yarn) async {
          await notifier.saveProjectDialogueYarnBody(
            dialogueId: id,
            yarnBody: yarn,
          );
          final error = ref.read(editorNotifierProvider).errorMessage;
          if (error != null) throw FileSystemException(error, abs);
        },
        autosaveEnabled: _autosaveEnabled,
      );
      await session.initialize();
      var doc = session.document;
      if (doc.nodes.isEmpty) {
        doc = emptyDialogueDocument(startTitle: entry.name);
        await session.apply(
          operationId: 'initialize-empty-dialogue',
          label: 'Initialiser le dialogue vide',
          document: doc,
        );
      }
      if (!mounted) return;
      setState(() {
        _doc = doc;
        _documentSession = session;
        _documentSessionError = session.state.message;
        _loadedDialogueId = id;
        _selection = null;
        _preview = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _doc = emptyDialogueDocument(startTitle: entry!.name);
        _documentSession?.dispose();
        _documentSession = null;
        _documentSessionError = 'Lecture impossible : $e';
        _loadedDialogueId = id;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final editor = ref.watch(editorNotifierProvider);
    final notifier = ref.read(editorNotifierProvider.notifier);

    ref.listen<String?>(
      editorNotifierProvider.select((s) => s.selectedProjectDialogueId),
      (prev, next) {
        _loadFromDisk(
          ref.read(editorNotifierProvider.notifier),
          ref.read(editorNotifierProvider),
        );
      },
    );

    if (!_loading && _loadedDialogueId != editor.selectedProjectDialogueId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadFromDisk(notifier, editor);
      });
    }

    final project = editor.project;
    final hasProjectWorkspace =
        project != null && (editor.projectRootPath?.trim().isNotEmpty ?? false);
    final presentation = narrativeStudioRoutePresentationFor(
      EditorWorkspaceMode.dialogue,
    )!;

    return NarrativeStudioWorkspacePage(
      presentation: presentation,
      actions: [
        if (hasProjectWorkspace)
          PokeMapButton(
            key: const ValueKey<String>('dialogue-studio-new-dialogue'),
            onPressed: () => _promptNewDialogue(context, notifier),
            size: PokeMapButtonSize.compact,
            leading: const Icon(CupertinoIcons.add, size: 14),
            child: const Text('Nouveau dialogue'),
          ),
      ],
      body: switch ((project, hasProjectWorkspace)) {
        (null, _) => const PokeMapEmptyState(
            title: 'Aucun projet chargé',
            description:
                'Chargez un projet pour ouvrir sa bibliothèque de dialogues.',
            icon: Icon(CupertinoIcons.chat_bubble_2),
          ),
        (_, false) => const PokeMapEmptyState(
            key: ValueKey<String>('dialogue-studio-workspace-unavailable'),
            title: 'Dossier projet indisponible',
            description:
                'Ouvrez le dossier du projet pour créer, importer ou modifier ses dialogues.',
            icon: Icon(CupertinoIcons.folder_badge_minus),
          ),
        (_, true) => Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 300,
                child: _buildLibraryColumn(context, editor, notifier),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildCenterColumn(context, editor, notifier),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 320,
                child: _buildInspectorColumn(context, editor, notifier),
              ),
            ],
          ),
      },
    );
  }

  // --- Bibliothèque ----------------------------------------------------------

  String _folderTargetHint(ProjectManifest project, String folderId) {
    for (final f in project.dialogueFolders) {
      if (f.id == folderId) {
        return 'Import / nouveaux → dossier « ${f.name} »';
      }
    }
    return 'Import / nouveaux → dossier sélectionné';
  }

  Widget _buildLibraryColumn(
    BuildContext context,
    EditorState editor,
    EditorNotifier notifier,
  ) {
    final project = editor.project!;
    final tree = buildDialogueLibraryTree(project);
    final q = _searchController.text.trim().toLowerCase();

    bool matchEntry(ProjectDialogueEntry d) {
      if (q.isEmpty) return true;
      return d.name.toLowerCase().contains(q);
    }

    return EditorPaneSurface(
      radius: 20,
      tint: EditorChrome.islandCoolTint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dialogues du projet',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: PokeMapLegacyColors.label(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Arborescence réelle du manifeste : dossiers et fichiers .yarn.',
                  style: TextStyle(
                    fontSize: 11,
                    color: PokeMapLegacyColors.secondaryLabel(context),
                  ),
                ),
              ],
            ),
          ),
          // Cible explicite pour import / création (évite l’ambiguïté « où ça part ? »).
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Nouveaux fichiers et import vont dans :',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: PokeMapLegacyColors.secondaryLabel(context),
                  ),
                ),
                const SizedBox(height: 6),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () =>
                      setState(() => _sidebarTargetFolderId = null),
                  child: Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _sidebarTargetFolderId == null
                            ? EditorChrome.inspectorJoyBlue
                            : PokeMapLegacyColors.separator(context),
                        width: _sidebarTargetFolderId == null ? 1.5 : 1,
                      ),
                      color: _sidebarTargetFolderId == null
                          ? EditorChrome.inspectorJoyBlue.withValues(alpha: 0.1)
                          : null,
                    ),
                    child: Text(
                      'Racine — dialogues sans dossier',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: _sidebarTargetFolderId == null
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: PokeMapLegacyColors.label(context),
                      ),
                    ),
                  ),
                ),
                if (_sidebarTargetFolderId != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _folderTargetHint(project, _sidebarTargetFolderId!),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: PokeMapLegacyColors.secondaryLabel(context),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => _promptNewFolder(context, notifier),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: PokeMapLegacyColors.separator(context),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '+ Dossier',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: PokeMapLegacyColors.label(context),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => _importProjectDialogue(context, notifier),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: PokeMapLegacyColors.separator(context),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Importer .yarn / .txt',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: PokeMapLegacyColors.label(context),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: CupertinoSearchTextField(
              controller: _searchController,
              placeholder: 'Rechercher un dialogue…',
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              children: [
                ...tree.rootFolders.map(
                  (b) => _StudioDialogueFolderTreeNode(
                    branch: b,
                    depth: 0,
                    project: project,
                    selectedDialogueId: editor.selectedProjectDialogueId,
                    targetFolderId: _sidebarTargetFolderId,
                    filter: matchEntry,
                    onDialogueTap: (dialogueId, parentFolderId) {
                      unawaited(
                        _selectDialogueSafely(
                          notifier,
                          dialogueId,
                          parentFolderId,
                        ),
                      );
                    },
                    onFolderTargetTap: (folderId) {
                      setState(() => _sidebarTargetFolderId = folderId);
                    },
                    onFolderMenu: (btnContext, folder) {
                      _openStudioDialogueFolderMenu(
                        context,
                        project,
                        notifier,
                        folder,
                        anchorGlobal: editorMenuAnchorBelowWidget(btnContext),
                      );
                    },
                    onDialogueEntryMenuButton: (entry, btnCtx) {
                      _openStudioDialogueEntryMenu(
                        context,
                        project,
                        notifier,
                        entry,
                        editorMenuAnchorBelowWidget(btnCtx),
                      );
                    },
                  ),
                ),
                ...tree.rootDialogues.where(matchEntry).map(
                      (d) => _DialogueEntryRow(
                        entry: d,
                        selected: editor.selectedProjectDialogueId == d.id,
                        depth: 0,
                        onTap: () {
                          unawaited(
                            _selectDialogueSafely(
                              notifier,
                              d.id,
                              d.folderId,
                            ),
                          );
                        },
                        onMenuButton: (btnCtx) => _openStudioDialogueEntryMenu(
                          context,
                          project,
                          notifier,
                          d,
                          editorMenuAnchorBelowWidget(btnCtx),
                        ),
                      ),
                    ),
              ],
            ),
          ),
          if (editor.selectedProjectDialogueId != null)
            _selectionInfoCard(context, editor, notifier),
        ],
      ),
    );
  }

  Future<void> _selectDialogueSafely(
    EditorNotifier notifier,
    String dialogueId,
    String? parentFolderId,
  ) async {
    final session = _documentSession;
    if (session != null && session.state.blocksNavigation) {
      final saved = await session.save(operationId: 'navigate-save-dialogue');
      if (!saved) {
        if (!mounted) return;
        setState(() {
          _documentSessionError = session.state.message ??
              'Navigation bloquée : sauvegardez ou corrigez le dialogue.';
        });
        return;
      }
    }
    notifier.selectProjectDialogue(dialogueId);
    if (!mounted) return;
    setState(() {
      final folderId = parentFolderId?.trim() ?? '';
      _sidebarTargetFolderId = folderId.isEmpty ? null : folderId;
    });
  }

  Widget _selectionInfoCard(
    BuildContext context,
    EditorState editor,
    EditorNotifier notifier,
  ) {
    final id = editor.selectedProjectDialogueId!;
    ProjectDialogueEntry? entry;
    for (final d in editor.project!.dialogues) {
      if (d.id == id) {
        entry = d;
        break;
      }
    }
    if (entry == null) return const SizedBox.shrink();

    final stats = _docStats(_doc);
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: EditorChrome.largeIslandSurfaceColor(
            context,
            tint: EditorChrome.inspectorJoyBlue.withValues(alpha: 0.08),
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: PokeMapLegacyColors.separator(context),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Infos sélection',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 11,
                color: PokeMapLegacyColors.secondaryLabel(context),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              entry.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Text(
              '${stats.nodes} nœuds • ${stats.choices} choix • ${stats.ends} fins',
              style: TextStyle(
                fontSize: 11,
                color: PokeMapLegacyColors.secondaryLabel(context),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    minimumSize: Size.zero,
                    onPressed: () => _promptRename(context, notifier, entry!),
                    child:
                        const Text('Renommer', style: TextStyle(fontSize: 12)),
                  ),
                ),
                Expanded(
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    minimumSize: Size.zero,
                    onPressed: () => _promptMoveDialogueToFolder(
                      context,
                      notifier,
                      editor.project!,
                      entry!,
                    ),
                    child:
                        const Text('Déplacer…', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    minimumSize: Size.zero,
                    onPressed: () => notifier.deleteProjectDialogue(entry!.id),
                    child: const Text(
                      'Supprimer',
                      style: TextStyle(
                        fontSize: 12,
                        color: EditorChrome.inspectorJoyCoral,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- Centre ---------------------------------------------------------------

  Widget _buildCenterColumn(
    BuildContext context,
    EditorState editor,
    EditorNotifier notifier,
  ) {
    final id = editor.selectedProjectDialogueId;
    if (id == null) {
      return const EditorPaneSurface(
        radius: 20,
        tint: EditorChrome.islandWarmTint,
        child: PokeMapEmptyState(
          title: 'Sélectionnez un dialogue',
          description:
              'Choisissez un fichier dans la bibliothèque pour afficher son montage.',
          icon: Icon(CupertinoIcons.chat_bubble_text),
        ),
      );
    }
    if (_loading || _doc == null) {
      return const EditorPaneSurface(
        radius: 20,
        child: Center(child: CupertinoActivityIndicator()),
      );
    }

    final entryName = _dialogueName(editor.project!, id);

    return EditorPaneSurface(
      radius: 20,
      tint: EditorChrome.islandWarmTint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dialogue : $entryName',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  'Montage visuel — le Yarn est un export, pas la vue principale.',
                  style: TextStyle(
                    fontSize: 11,
                    color: PokeMapLegacyColors.secondaryLabel(context),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _tabChip(context, 'Visuel', 0),
                  const SizedBox(width: 8),
                  _tabChip(context, 'Aperçu', 1),
                  const SizedBox(width: 8),
                  _tabChip(context, 'Yarn', 2),
                  const SizedBox(width: 24),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _aiBusy
                        ? null
                        : () => _runAiGeneration(notifier, append: false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: EditorChrome.inspectorJoyBlue,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _aiBusy
                          ? const CupertinoActivityIndicator(
                              color: PokeMapLegacyColors.white)
                          : const Text(
                              'Générer avec IA',
                              style: TextStyle(
                                  color: PokeMapLegacyColors.white,
                                  fontSize: 12),
                            ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  CupertinoButton(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    onPressed: _aiBusy
                        ? null
                        : () => _runAiGeneration(notifier, append: true),
                    child: const Text('Continuer avec IA',
                        style: TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(width: 6),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _savingDocument
                        ? null
                        : () => unawaited(
                              _saveDialogueDocument(notifier, id),
                            ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: EditorChrome.accentJade,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Sauvegarder',
                        style: TextStyle(
                          color: PokeMapLegacyColors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'La clé Mistral est définie dans les paramètres du projet '
                  '(barre d’outils → engrenage → section « IA (éditeur) »). '
                  'À défaut, la variable d’environnement MISTRAL_API_KEY est utilisée.',
                  style: TextStyle(
                    fontSize: 10,
                    height: 1.35,
                    color: PokeMapLegacyColors.secondaryLabel(context),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Instruction IA',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: PokeMapLegacyColors.secondaryLabel(context),
                  ),
                ),
                const SizedBox(height: 4),
                CupertinoTextField(
                  controller: _instructionController,
                  placeholder:
                      'Ex. « Réveil du héros, professeur bienveillant, 1 choix final »',
                  maxLines: 2,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: PokeMapLegacyColors.systemGrey6(context),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                if (_iaError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _iaError!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: EditorChrome.inspectorJoyCoral,
                    ),
                  ),
                ],
                if (_documentSessionError != null ||
                    _documentError != null) ...[
                  const SizedBox(height: 8),
                  PokeMapDiagnosticCallout(
                    severity: PokeMapDiagnosticSeverity.warning,
                    title: 'Session du dialogue',
                    message: _documentSessionError ?? _documentError!,
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: switch (_mainTab) {
                0 => _buildVisualCanvas(context, id),
                1 => _buildPreview(context),
                _ => _buildYarnReadout(context),
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabChip(BuildContext context, String label, int index) {
    final sel = _mainTab == index;
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      minimumSize: Size.zero,
      onPressed: () {
        setState(() {
          _mainTab = index;
          if (index == 1) {
            _preview = DialoguePreviewSession(
              _doc!,
              startNodeTitle: null,
            );
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: sel
              ? EditorChrome.inspectorJoyBlue.withValues(alpha: 0.15)
              : PokeMapLegacyColors.systemGrey6(context),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: sel
                ? EditorChrome.inspectorJoyBlue
                : PokeMapLegacyColors.separator(context),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: sel
                ? EditorChrome.inspectorJoyBlue
                : PokeMapLegacyColors.label(context),
          ),
        ),
      ),
    );
  }

  Future<void> _saveDialogueDocument(
    EditorNotifier notifier,
    String dialogueId,
  ) async {
    final session = _documentSession;
    final document = _doc;
    if (session == null || document == null) return;
    final entry = _selectedDialogueEntry(ref.read(editorNotifierProvider));
    final blocking = validateDialogueDocument(
      document,
      declaredOutcomeIds:
          entry?.declaredOutcomes.map((outcome) => outcome.id) ?? const [],
    ).where(
      (issue) => issue.severity == DialogueValidationSeverity.error,
    );
    if (blocking.isNotEmpty) {
      setState(() {
        _documentSessionError =
            'Sauvegarde refusée : ${blocking.first.message}';
      });
      return;
    }
    setState(() {
      _savingDocument = true;
      _documentSessionError = null;
    });
    await _documentMutationQueue;
    final saved = await session.save(
      operationId: 'save-dialogue-$dialogueId',
    );
    if (!mounted) return;
    setState(() {
      _savingDocument = false;
      _baselineYarn = saved ? session.state.document : _baselineYarn;
      _documentSessionError = saved
          ? null
          : session.state.message ?? 'Le dialogue n’a pas pu être sauvegardé.';
    });
  }

  Widget _buildVisualCanvas(BuildContext context, String dialogueId) {
    final doc = _doc!;
    return Container(
      decoration: BoxDecoration(
        color: PokeMapLegacyColors.systemBackground(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PokeMapLegacyColors.separator(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Canvas de conversation',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: PokeMapLegacyColors.secondaryLabel(context),
                    ),
                  ),
                  const SizedBox(width: 24),
                  PokeMapButton(
                    key: const ValueKey<String>('dialogue-undo'),
                    onPressed: _documentSession?.state.canUndo == true
                        ? () => unawaited(_undoDialogue())
                        : null,
                    variant: PokeMapButtonVariant.ghost,
                    size: PokeMapButtonSize.small,
                    leading:
                        const Icon(CupertinoIcons.arrow_uturn_left, size: 13),
                    child: const Text('Annuler'),
                  ),
                  PokeMapButton(
                    key: const ValueKey<String>('dialogue-redo'),
                    onPressed: _documentSession?.state.canRedo == true
                        ? () => unawaited(_redoDialogue())
                        : null,
                    variant: PokeMapButtonVariant.ghost,
                    size: PokeMapButtonSize.small,
                    leading:
                        const Icon(CupertinoIcons.arrow_uturn_right, size: 13),
                    child: const Text('Rétablir'),
                  ),
                  PokeMapButton(
                    key: const ValueKey<String>('dialogue-add-node'),
                    onPressed: _createDialogueNode,
                    variant: PokeMapButtonVariant.secondary,
                    size: PokeMapButtonSize.small,
                    leading: const Icon(CupertinoIcons.add_circled, size: 13),
                    child: const Text('Nœud'),
                  ),
                  PokeMapButton(
                    key: const ValueKey<String>('dialogue-autosave'),
                    onPressed: () {
                      final enabled = !_autosaveEnabled;
                      _documentSession?.setAutosaveEnabled(enabled);
                      setState(() => _autosaveEnabled = enabled);
                    },
                    variant: _autosaveEnabled
                        ? PokeMapButtonVariant.primary
                        : PokeMapButtonVariant.ghost,
                    size: PokeMapButtonSize.small,
                    leading: const Icon(CupertinoIcons.cloud_upload, size: 13),
                    child:
                        Text(_autosaveEnabled ? 'Autosave actif' : 'Autosave'),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Flux vertical • branches visibles pour les choix',
                    style: TextStyle(
                      fontSize: 10,
                      color: PokeMapLegacyColors.tertiaryLabel(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            height: 1,
            color: PokeMapLegacyColors.separator(context),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              itemCount: doc.nodes.length,
              itemBuilder: (context, i) {
                final node = doc.nodes[i];
                return _NodeCanvasCard(
                  node: node,
                  isEntry: node.id == doc.effectiveEntryNodeId,
                  selection: _selection,
                  onSelectEntry: () => _selectEntryNode(node.id),
                  onDuplicate: () => _duplicateDialogueNode(node.id),
                  onDeleteNode: () => _deleteDialogueNode(node.id),
                  onSelectStep: (sel) => setState(() => _selection = sel),
                  onDeleteStep: (sel) => setState(() => _deleteStep(sel)),
                );
              },
            ),
          ),
          _addBlockToolbar(context, dialogueId),
        ],
      ),
    );
  }

  Widget _addBlockToolbar(BuildContext context, String dialogueId) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: PokeMapLegacyColors.systemGrey6(context),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _addLabel(context, 'Ajouter :'),
            _addKindButton(
                context, 'Réplique', () => _appendNewStep(_newLine())),
            _addKindButton(
                context, 'Narration', () => _appendNewStep(_newNarration())),
            _addKindButton(
                context, 'Choix', () => _appendNewStep(_newChoice())),
            _addKindButton(
                context, 'Condition', () => _appendNewStep(_newCondition())),
            _addKindButton(context, 'Jump', () => _appendNewStep(_newJump())),
            _addKindButton(context, 'Fin',
                () => _appendNewStep(DeEndStep(id: newDialogueEditorId()))),
            _addKindButton(
                context, 'Commande', () => _appendNewStep(_newCommand())),
          ],
        ),
      ),
    );
  }

  Widget _addLabel(BuildContext context, String t) {
    return Padding(
      padding: const EdgeInsets.only(right: 8, left: 4),
      child: Text(
        t,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: PokeMapLegacyColors.secondaryLabel(context),
        ),
      ),
    );
  }

  Widget _addKindButton(
      BuildContext context, String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        minimumSize: Size.zero,
        color: PokeMapLegacyColors.white,
        borderRadius: BorderRadius.circular(8),
        onPressed: onTap,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: PokeMapLegacyColors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildPreview(BuildContext context) {
    _preview ??= DialoguePreviewSession(_doc!, startNodeTitle: null);
    final session = _preview!;
    return Container(
      decoration: BoxDecoration(
        color: PokeMapLegacyColors.systemBackground(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PokeMapLegacyColors.separator(context)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    setState(() {
                      _preview =
                          DialoguePreviewSession(_doc!, startNodeTitle: null);
                    });
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: EditorChrome.inspectorJoyBlue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Rejouer depuis le début',
                      style: TextStyle(
                        color: PokeMapLegacyColors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: session.transcript.length,
              itemBuilder: (context, i) {
                final ev = session.transcript[i];
                return switch (ev) {
                  DialoguePreviewLine(:final displayText) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(displayText,
                          style: const TextStyle(fontSize: 14)),
                    ),
                  DialoguePreviewChoicePrompt(:final options) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var j = 0; j < options.length; j++)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: CupertinoButton(
                                padding: EdgeInsets.zero,
                                onPressed: () {
                                  setState(() {
                                    session.choose(j);
                                  });
                                },
                                child: Container(
                                  width: double.infinity,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: EditorChrome.inspectorJoyMint
                                        .withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${j + 1}. ${options[j]}',
                                    style: const TextStyle(
                                      color: PokeMapLegacyColors.black,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  DialoguePreviewTrace(
                    :final kind,
                    :final source,
                    :final message,
                    :final state,
                  ) =>
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: PokeMapDiagnosticCallout(
                        severity: kind == DialoguePreviewTraceKind.unsupported
                            ? PokeMapDiagnosticSeverity.error
                            : PokeMapDiagnosticSeverity.info,
                        title: switch (kind) {
                          DialoguePreviewTraceKind.condition => 'Condition',
                          DialoguePreviewTraceKind.command => 'Commande',
                          DialoguePreviewTraceKind.outcome => 'Résultat',
                          DialoguePreviewTraceKind.unsupported =>
                            'Commande non supportée',
                        },
                        message: '$message\n$source'
                            '${state.isEmpty ? '' : '\nÉtat : $state'}',
                      ),
                    ),
                  DialoguePreviewEnded() => DialoguePreviewEndedView(event: ev),
                };
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYarnReadout(BuildContext context) {
    final text = emitDocumentToYarn(_doc!);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PokeMapLegacyColors.systemBackground(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PokeMapLegacyColors.separator(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Export Yarn (lecture seule depuis les blocs)',
            style: TextStyle(
              fontSize: 11,
              color: PokeMapLegacyColors.secondaryLabel(context),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: PokeMapLegacyColors.systemGrey6(context),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(10),
                child: SelectableText(
                  text,
                  style: const TextStyle(
                    fontFamily: 'Menlo',
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Inspecteur -----------------------------------------------------------

  Widget _buildInspectorColumn(
    BuildContext context,
    EditorState editor,
    EditorNotifier notifier,
  ) {
    final dialogueEntry = _selectedDialogueEntry(editor);
    final issues = _doc == null
        ? <DialogueValidationIssue>[]
        : validateDialogueDocument(
            _doc!,
            declaredOutcomeIds:
                dialogueEntry?.declaredOutcomes.map((outcome) => outcome.id) ??
                    const <String>[],
          );

    return EditorPaneSurface(
      radius: 20,
      tint: EditorChrome.islandCoolTint,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
        children: [
          Text(
            'Inspecteur',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: PokeMapLegacyColors.label(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Détail du bloc sélectionné.',
            style: TextStyle(
              fontSize: 11,
              color: PokeMapLegacyColors.secondaryLabel(context),
            ),
          ),
          const SizedBox(height: 12),
          if (_doc == null || _selection == null)
            Text(
              'Cliquez sur un bloc au centre.',
              style: TextStyle(
                color: PokeMapLegacyColors.secondaryLabel(context),
                fontSize: 12,
              ),
            )
          else
            _buildInspectorBody(context, editor, notifier),
          const SizedBox(height: 16),
          const Text(
            'Validation',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 12,
              color: EditorChrome.inspectorJoyCoral,
            ),
          ),
          const SizedBox(height: 8),
          ...issues.map(
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    i.severity == DialogueValidationSeverity.error
                        ? '●'
                        : i.severity == DialogueValidationSeverity.warning
                            ? '◆'
                            : '○',
                    style: TextStyle(
                      fontSize: 11,
                      color: i.severity == DialogueValidationSeverity.error
                          ? EditorChrome.inspectorJoyCoral
                          : PokeMapLegacyColors.secondaryLabel(context),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      i.message,
                      style: const TextStyle(fontSize: 11, height: 1.25),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  ProjectDialogueEntry? _selectedDialogueEntry(EditorState editor) {
    final selectedId = editor.selectedProjectDialogueId;
    if (selectedId == null) return null;
    for (final entry
        in editor.project?.dialogues ?? const <ProjectDialogueEntry>[]) {
      if (entry.id == selectedId) return entry;
    }
    return null;
  }

  Widget _buildInspectorBody(
    BuildContext context,
    EditorState editor,
    EditorNotifier notifier,
  ) {
    final doc = _doc!;
    final sel = _selection!;
    final step = _findStep(doc, sel);
    if (step == null) {
      return const Text('Bloc introuvable (recharger le dialogue).');
    }
    return switch (step) {
      DeStartStep() => const Text('Début de conversation (marqueur visuel).'),
      DeLineStep(:final speaker, :final body) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _fieldLabel(context, 'Interlocuteur'),
            CupertinoTextField(
              controller: TextEditingController(text: speaker ?? ''),
              onChanged: (v) => _patchLine(sel,
                  speaker: v.trim().isEmpty ? null : v.trim(), body: body),
              placeholder: 'hero, professor…',
              padding: const EdgeInsets.all(10),
            ),
            const SizedBox(height: 10),
            _fieldLabel(context, 'Texte'),
            CupertinoTextField(
              controller: TextEditingController(text: body),
              onChanged: (v) => _patchLine(sel, speaker: speaker, body: v),
              maxLines: 4,
              padding: const EdgeInsets.all(10),
            ),
            const SizedBox(height: 10),
            _aiMiniActions(context, sel, kind: 'line'),
          ],
        ),
      DeNarrationStep(:final text) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _fieldLabel(context, 'Narration'),
            CupertinoTextField(
              controller: TextEditingController(text: text),
              onChanged: (v) => _patchNarration(sel, v),
              maxLines: 4,
              padding: const EdgeInsets.all(10),
            ),
            const SizedBox(height: 10),
            _aiMiniActions(context, sel, kind: 'narration'),
          ],
        ),
      DeChoiceStep(:final branches) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _fieldLabel(context, 'Question (libellé du bloc choix)'),
            const Text(
              'Éditez chaque option ci-dessous ; les branches s’affichent sur le canvas.',
              style: TextStyle(fontSize: 10, height: 1.2),
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < branches.length; i++) ...[
              Text('Option ${i + 1}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 11)),
              CupertinoTextField(
                controller: TextEditingController(text: branches[i].label),
                onChanged: (v) => _patchChoiceLabel(sel, branches[i].id, v),
                padding: const EdgeInsets.all(8),
              ),
              const SizedBox(height: 6),
              _buildChoiceOutcomePicker(
                context,
                editor,
                notifier,
                sel,
                branches[i],
              ),
              const SizedBox(height: 10),
            ],
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => _addChoiceOption(sel),
              child: const Align(
                alignment: Alignment.centerLeft,
                child: Text('+ Ajouter une option',
                    style: TextStyle(fontSize: 12)),
              ),
            ),
            const SizedBox(height: 8),
            _aiMiniActions(context, sel, kind: 'choice'),
          ],
        ),
      DeJumpStep(:final targetTitle) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _fieldLabel(context, 'Nœud cible (titre Yarn)'),
            CupertinoTextField(
              controller: TextEditingController(text: targetTitle),
              onChanged: (v) => _patchJump(sel, v),
              padding: const EdgeInsets.all(10),
            ),
          ],
        ),
      DeConditionStep(:final raw) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _fieldLabel(context, 'Ligne condition (Yarn)'),
            CupertinoTextField(
              controller: TextEditingController(text: raw),
              onChanged: (v) => _patchCondition(sel, v),
              maxLines: 2,
              padding: const EdgeInsets.all(10),
            ),
          ],
        ),
      DeCommandStep(:final raw) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _fieldLabel(context, 'Commande <<…>>'),
            CupertinoTextField(
              controller: TextEditingController(text: raw),
              onChanged: (v) => _patchCommand(sel, v),
              maxLines: 2,
              padding: const EdgeInsets.all(10),
            ),
          ],
        ),
      DeEndStep() =>
        const Text('Fin de conversation (marqueur pour le montage).'),
    };
  }

  Widget _buildChoiceOutcomePicker(
    BuildContext context,
    EditorState editor,
    EditorNotifier notifier,
    _StepSelection selection,
    DeChoiceBranch branch,
  ) {
    final entry = _selectedDialogueEntry(editor);
    final outcomes =
        entry?.declaredOutcomes ?? const <DialogueDeclaredOutcome>[];
    final currentOutcomeId = branch.outcomeId?.trim() ?? '';
    final knownCurrent = currentOutcomeId.isEmpty ||
        outcomes.any((outcome) => outcome.id == currentOutcomeId);
    final items = <PokeMapDropdownItem<String>>[
      const PokeMapDropdownItem<String>(
        value: '',
        label: 'Aucun résultat',
      ),
      for (final outcome in outcomes)
        PokeMapDropdownItem<String>(
          value: outcome.id,
          label: '${outcome.label} · ${outcome.id}',
        ),
      if (!knownCurrent)
        PokeMapDropdownItem<String>(
          value: currentOutcomeId,
          label: 'Résultat inconnu · $currentOutcomeId',
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PokeMapDropdownField<String>(
          key: ValueKey('dialogue-choice-outcome-${branch.id}'),
          label: 'Résultat envoyé à la Scene',
          value: currentOutcomeId,
          items: items,
          onChanged: (value) =>
              _patchChoiceOutcome(selection, branch.id, value),
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerLeft,
          child: PokeMapButton(
            key: ValueKey('dialogue-choice-new-outcome-${branch.id}'),
            onPressed: entry == null
                ? null
                : () => _promptNewDialogueOutcome(
                      context,
                      notifier,
                      entry,
                      selection,
                      branch,
                    ),
            variant: PokeMapButtonVariant.ghost,
            size: PokeMapButtonSize.small,
            leading: const Icon(CupertinoIcons.add, size: 14),
            child: const Text('Nouveau résultat'),
          ),
        ),
        if (outcomes.isEmpty) ...[
          const SizedBox(height: 6),
          const PokeMapDiagnosticCallout(
            severity: PokeMapDiagnosticSeverity.info,
            title: 'Aucun résultat public',
            message:
                'Créez un résultat nommé : son identifiant stable sera généré automatiquement.',
          ),
        ],
      ],
    );
  }

  Widget _fieldLabel(BuildContext context, String t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        t,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: PokeMapLegacyColors.secondaryLabel(context),
        ),
      ),
    );
  }

  Widget _aiMiniActions(BuildContext context, _StepSelection sel,
      {required String kind}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Actions IA',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: EditorChrome.inspectorJoyBlue,
          ),
        ),
        const SizedBox(height: 6),
        if (kind == 'choice')
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _aiBusy ? null : () => _runChoiceRephrase(sel),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: EditorChrome.inspectorJoyBlue.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: const Text('Générer 3 libellés',
                  style: TextStyle(fontSize: 12)),
            ),
          ),
        CupertinoButton(
          padding: const EdgeInsets.symmetric(vertical: 8),
          onPressed:
              _aiBusy ? null : () => _runBlockRephrase(sel, tone: 'warmer'),
          child: const Text('Rendre plus chaleureux',
              style: TextStyle(fontSize: 12)),
        ),
        CupertinoButton(
          padding: const EdgeInsets.symmetric(vertical: 8),
          onPressed:
              _aiBusy ? null : () => _runBlockRephrase(sel, tone: 'shorter'),
          child: const Text('Raccourcir', style: TextStyle(fontSize: 12)),
        ),
      ],
    );
  }

  // --- Mutations document ---------------------------------------------------

  void _recordDocumentEdit(String label) {
    final document = _doc;
    final session = _documentSession;
    if (document == null || session == null) return;
    final snapshot = emitDocumentToYarn(document);
    final operationId = 'dialogue-edit-${++_documentOperationSequence}';
    _preview = null;
    _documentMutationQueue = _documentMutationQueue.then((_) async {
      final accepted = await session.apply(
        operationId: operationId,
        label: label,
        document: parseYarnToDocument(snapshot),
      );
      if (!accepted && mounted) {
        setState(() {
          _documentSessionError = session.state.message ??
              'La modification du dialogue a été refusée.';
        });
      } else if (mounted) {
        setState(() => _documentSessionError = session.state.message);
      }
    });
    setState(() {});
  }

  Future<void> _undoDialogue() async {
    final session = _documentSession;
    if (session == null) return;
    await _documentMutationQueue;
    if (!await session.undo() || !mounted) return;
    setState(() {
      _doc = session.document;
      _selection = null;
      _preview = null;
      _documentSessionError = session.state.message;
    });
  }

  Future<void> _redoDialogue() async {
    final session = _documentSession;
    if (session == null) return;
    await _documentMutationQueue;
    if (!await session.redo() || !mounted) return;
    setState(() {
      _doc = session.document;
      _selection = null;
      _preview = null;
      _documentSessionError = session.state.message;
    });
  }

  void _createDialogueNode() {
    final document = _doc;
    if (document == null) return;
    _doc = document.createNode(title: 'Nouveau nœud');
    _recordDocumentEdit('Créer un nœud');
  }

  void _selectEntryNode(String nodeId) {
    final document = _doc;
    if (document == null) return;
    _doc = document.selectEntryNode(nodeId);
    _selection = null;
    _recordDocumentEdit('Définir le nœud de départ');
  }

  void _duplicateDialogueNode(String nodeId) {
    final document = _doc;
    if (document == null) return;
    _doc = document.duplicateNode(nodeId);
    _recordDocumentEdit('Dupliquer un nœud');
  }

  void _deleteDialogueNode(String nodeId) {
    final document = _doc;
    if (document == null || document.nodes.length <= 1) return;
    _doc = document.deleteNode(nodeId);
    _selection = null;
    _recordDocumentEdit('Supprimer un nœud');
  }

  DialogueEditorStep? _findStep(
      DialogueEditorDocument doc, _StepSelection sel) {
    final node = doc.nodeById(sel.nodeId);
    if (node == null) return null;
    if (sel.branchId == null) {
      for (final s in node.steps) {
        if (s.id == sel.stepId) return s;
      }
      return null;
    }
    for (final s in node.steps) {
      if (s is! DeChoiceStep) continue;
      for (final b in s.branches) {
        if (b.id != sel.branchId) continue;
        for (final inner in b.steps) {
          if (inner.id == sel.stepId) return inner;
        }
      }
    }
    return null;
  }

  List<DialogueEditorStep> _listForSelection(_StepSelection sel) {
    final node = _doc!.nodeById(sel.nodeId);
    if (node == null) return [];
    if (sel.branchId == null) return node.steps;
    for (final s in node.steps) {
      if (s is! DeChoiceStep) continue;
      for (final b in s.branches) {
        if (b.id == sel.branchId) return b.steps;
      }
    }
    return [];
  }

  void _deleteStep(_StepSelection sel) {
    final list = _listForSelection(sel);
    list.removeWhere((s) => s.id == sel.stepId);
    setState(() {
      if (_selection?.stepId == sel.stepId) _selection = null;
    });
    _recordDocumentEdit('Supprimer un bloc');
  }

  void _appendNewStep(DialogueEditorStep step) {
    final doc = _doc!;
    if (doc.nodes.isEmpty) return;
    final DialogueEditorNode targetNode = _selection == null
        ? doc.nodes.first
        : (doc.nodeById(_selection!.nodeId) ?? doc.nodes.first);

    final List<DialogueEditorStep> list = _selection?.branchId == null
        ? targetNode.steps
        : _listForSelection(
            _StepSelection(
              nodeId: targetNode.id,
              branchId: _selection!.branchId,
              stepId: _selection!.stepId,
            ),
          );
    var insertAt = list.length;
    if (_selection != null && _selection!.branchId == null) {
      final idx = list.indexWhere((s) => s.id == _selection!.stepId);
      if (idx >= 0) insertAt = idx + 1;
    } else if (_selection?.branchId != null) {
      final idx = list.indexWhere((s) => s.id == _selection!.stepId);
      if (idx >= 0) insertAt = idx + 1;
    }
    list.insert(insertAt, step);
    setState(() => _selection = _StepSelection(
          nodeId: targetNode.id,
          branchId: _selection?.branchId,
          stepId: step.id,
        ));
    _recordDocumentEdit('Ajouter un bloc');
  }

  void _replaceStep(_StepSelection sel, DialogueEditorStep next) {
    final list = _listForSelection(sel);
    final i = list.indexWhere((s) => s.id == sel.stepId);
    if (i < 0) return;
    list[i] = next;
    _recordDocumentEdit('Modifier un bloc');
  }

  void _patchLine(_StepSelection sel, {String? speaker, required String body}) {
    final cur = _findStep(_doc!, sel);
    if (cur is! DeLineStep) return;
    _replaceStep(
      sel,
      DeLineStep(id: cur.id, speaker: speaker, body: body),
    );
  }

  void _patchNarration(_StepSelection sel, String text) {
    final cur = _findStep(_doc!, sel);
    if (cur is! DeNarrationStep) return;
    _replaceStep(sel, DeNarrationStep(id: cur.id, text: text));
  }

  void _patchJump(_StepSelection sel, String target) {
    final cur = _findStep(_doc!, sel);
    if (cur is! DeJumpStep) return;
    _replaceStep(sel, DeJumpStep(id: cur.id, targetTitle: target));
  }

  void _patchCondition(_StepSelection sel, String raw) {
    final cur = _findStep(_doc!, sel);
    if (cur is! DeConditionStep) return;
    _replaceStep(sel, DeConditionStep(id: cur.id, raw: raw));
  }

  void _patchCommand(_StepSelection sel, String raw) {
    final cur = _findStep(_doc!, sel);
    if (cur is! DeCommandStep) return;
    _replaceStep(sel, DeCommandStep(id: cur.id, raw: raw));
  }

  void _patchChoiceLabel(_StepSelection sel, String branchId, String label) {
    final node = _doc!.nodeById(sel.nodeId);
    if (node == null) return;
    for (final s in node.steps) {
      if (s is! DeChoiceStep || s.id != sel.stepId) continue;
      for (final b in s.branches) {
        if (b.id == branchId) {
          b.label = label;
          _recordDocumentEdit('Renommer une option');
          return;
        }
      }
    }
  }

  void _patchChoiceOutcome(
    _StepSelection sel,
    String branchId,
    String outcomeId,
  ) {
    final node = _doc!.nodeById(sel.nodeId);
    if (node == null) return;
    for (final step in node.steps) {
      if (step is! DeChoiceStep || step.id != sel.stepId) continue;
      for (final branch in step.branches) {
        if (branch.id != branchId) continue;
        final normalized = outcomeId.trim();
        branch.outcomeId = normalized.isEmpty ? null : normalized;
        _recordDocumentEdit('Associer un résultat');
        return;
      }
    }
  }

  void _addChoiceOption(_StepSelection sel) {
    final node = _doc!.nodeById(sel.nodeId);
    if (node == null) return;
    for (final s in node.steps) {
      if (s is! DeChoiceStep || s.id != sel.stepId) continue;
      s.branches.add(
        DeChoiceBranch(
          id: newDialogueEditorId(),
          label: 'Nouvelle option',
          steps: [
            DeJumpStep(id: newDialogueEditorId(), targetTitle: ''),
          ],
        ),
      );
      _recordDocumentEdit('Ajouter une option');
      return;
    }
  }

  DeLineStep _newLine() =>
      DeLineStep(id: newDialogueEditorId(), speaker: 'hero', body: '…');

  DeNarrationStep _newNarration() =>
      DeNarrationStep(id: newDialogueEditorId(), text: '…');

  DeChoiceStep _newChoice() => DeChoiceStep(
        id: newDialogueEditorId(),
        branches: [
          DeChoiceBranch(
            id: newDialogueEditorId(),
            label: 'Option A',
            steps: [DeJumpStep(id: newDialogueEditorId(), targetTitle: '')],
          ),
          DeChoiceBranch(
            id: newDialogueEditorId(),
            label: 'Option B',
            steps: [DeJumpStep(id: newDialogueEditorId(), targetTitle: '')],
          ),
        ],
      );

  DeJumpStep _newJump() =>
      DeJumpStep(id: newDialogueEditorId(), targetTitle: '');

  DeConditionStep _newCondition() =>
      DeConditionStep(id: newDialogueEditorId(), raw: '<<if \$flag>>');

  DeCommandStep _newCommand() =>
      DeCommandStep(id: newDialogueEditorId(), raw: '<<set \$x to 1>>');

  // --- IA -------------------------------------------------------------------

  static const _kYarnSystemPrompt = '''
Tu écris des dialogues au format Yarn simplifié pour RPG.
Règles strictes :
- Un ou plusieurs blocs : ligne "title: Nom", puis "---", puis le corps, puis ligne "===".
- Répliques : "Speaker: texte" ou narration entre parenthèses une ligne : (texte).
- Choix : lignes commençant par "-> libellé", puis lignes indentées (deux espaces) sous chaque option ; termine souvent par "<<jump AutreNoeud>>".
- Réponds en français. Pas de markdown, pas de commentaire hors du Yarn.
''';

  Future<void> _runAiGeneration(EditorNotifier notifier,
      {required bool append}) async {
    final key = _resolveMistralApiKey();
    final instr = _instructionController.text.trim();
    if (instr.isEmpty) {
      setState(() => _iaError = 'Saisissez une instruction pour l’IA.');
      return;
    }
    if (key.isEmpty) {
      setState(() {
        _iaError =
            'Clé Mistral absente : renseignez-la dans Projet → Paramètres (IA) ou MISTRAL_API_KEY.';
      });
      return;
    }
    setState(() {
      _aiBusy = true;
      _iaError = null;
    });
    try {
      final client = MistralDialogueClient();
      final existing = append && _doc != null ? emitDocumentToYarn(_doc!) : '';
      final user = append
          ? 'Voici le dialogue existant :\n$existing\n\nEnchaîne ou enrichis selon : $instr'
          : instr;
      final raw = await client.completeChat(
        apiKey: key,
        systemPrompt: _kYarnSystemPrompt,
        userMessage: user,
      );
      client.close();
      final yarn = stripMarkdownFences(raw);
      var doc = parseYarnToDocument(yarn);
      if (doc.nodes.isEmpty) {
        doc = emptyDialogueDocument();
      }
      if (!mounted) return;
      setState(() {
        _doc = doc;
        _selection = null;
        _preview = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _iaError = 'IA : $e');
      }
    } finally {
      if (mounted) setState(() => _aiBusy = false);
    }
  }

  Future<void> _runBlockRephrase(_StepSelection sel,
      {required String tone}) async {
    final step = _findStep(_doc!, sel);
    if (step == null) return;
    final key = _resolveMistralApiKey();
    if (key.isEmpty) {
      setState(() {
        _iaError =
            'Clé Mistral absente : Projet → Paramètres (IA) ou MISTRAL_API_KEY.';
      });
      return;
    }
    final base = switch (step) {
      DeLineStep(:final speaker, :final body) =>
        'Réplique ${speaker != null ? '$speaker: ' : ''}$body',
      DeNarrationStep(:final text) => 'Narration: $text',
      _ => step.toString(),
    };
    final toneHint = switch (tone) {
      'warmer' => 'Rends le passage plus chaleureux, toujours en français.',
      'shorter' => 'Raccourcis fortement, garde le sens.',
      _ => 'Réécris naturellement.',
    };
    setState(() => _aiBusy = true);
    try {
      final client = MistralDialogueClient();
      final raw = await client.completeChat(
        apiKey: key,
        systemPrompt:
            'Tu réécris une seule ligne ou réplique de dialogue RPG. Réponds uniquement par le texte réécrit, sans guillemets.',
        userMessage: '$toneHint\n\n$base',
      );
      client.close();
      final text = stripMarkdownFences(raw).trim();
      switch (step) {
        case DeLineStep(:final id, :final speaker):
          _replaceStep(sel, DeLineStep(id: id, speaker: speaker, body: text));
        case DeNarrationStep(:final id):
          _replaceStep(sel, DeNarrationStep(id: id, text: text));
        default:
          break;
      }
      setState(() {});
    } catch (e) {
      if (mounted) setState(() => _iaError = 'IA reformulation : $e');
    } finally {
      if (mounted) setState(() => _aiBusy = false);
    }
  }

  Future<void> _runChoiceRephrase(_StepSelection sel) async {
    final step = _findStep(_doc!, sel);
    if (step is! DeChoiceStep) return;
    final key = _resolveMistralApiKey();
    if (key.isEmpty) {
      setState(() {
        _iaError =
            'Clé Mistral absente : Projet → Paramètres (IA) ou MISTRAL_API_KEY.';
      });
      return;
    }
    setState(() => _aiBusy = true);
    try {
      final client = MistralDialogueClient();
      final raw = await client.completeChat(
        apiKey: key,
        systemPrompt:
            'Tu proposes exactement 3 libellés de choix pour un jeu RPG, en français, séparés par des lignes, sans numérotation.',
        userMessage:
            'Contexte des options actuelles : ${step.branches.map((b) => b.label).join(' | ')}',
      );
      client.close();
      final lines = stripMarkdownFences(raw)
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .take(3)
          .toList();
      if (lines.length < 3) return;
      for (var i = 0; i < step.branches.length && i < 3; i++) {
        step.branches[i].label = lines[i];
      }
      setState(() {});
    } catch (e) {
      debugPrint('IA choix: $e');
    } finally {
      if (mounted) setState(() => _aiBusy = false);
    }
  }
}
