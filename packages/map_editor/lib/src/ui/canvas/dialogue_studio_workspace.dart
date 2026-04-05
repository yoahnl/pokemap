// -----------------------------------------------------------------------------
// Dialogue Studio — workspace central (wireframe produit : 3 colonnes)
// -----------------------------------------------------------------------------
// Colonne gauche   : bibliothèque (arborescence projet + actions).
// Colonne centrale : canvas par blocs + onglets Visuel / Aperçu / Yarn.
// Colonne droite   : inspecteur du bloc sélectionné + validation.
//
// Données : [DialogueEditorDocument] (pas le Yarn brut comme vérité UX).
// -----------------------------------------------------------------------------

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, SelectableText;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../features/dialogue/application/dialogue_editor_model.dart';
import '../../features/dialogue/application/dialogue_editor_validation.dart';
import '../../features/dialogue/application/dialogue_preview_runner.dart';
import '../../features/dialogue/application/dialogue_yarn_codec.dart';
import '../../features/dialogue/application/mistral_dialogue_client.dart';
import '../../features/editor/state/editor_notifier.dart';
import '../../features/editor/state/editor_state.dart';
import '../shared/cupertino_editor_widgets.dart';

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

class DialogueStudioWorkspace extends ConsumerStatefulWidget {
  const DialogueStudioWorkspace({super.key});

  @override
  ConsumerState<DialogueStudioWorkspace> createState() =>
      _DialogueStudioWorkspaceState();
}

class _DialogueStudioWorkspaceState extends ConsumerState<DialogueStudioWorkspace> {
  DialogueEditorDocument? _doc;
  String? _loadedDialogueId;
  bool _loading = false;
  _StepSelection? _selection;

  /// 0 = Visuel, 1 = Aperçu, 2 = Yarn
  int _mainTab = 0;

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _instructionController = TextEditingController();

  DialoguePreviewSession? _preview;

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
      final text = await File(abs).readAsString();
      var doc = parseYarnToDocument(text);
      if (doc.nodes.isEmpty) {
        doc = emptyDialogueDocument(startTitle: entry.name);
      }
      if (!mounted) return;
      setState(() {
        _doc = doc;
        _loadedDialogueId = id;
        _selection = null;
        _preview = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _doc = emptyDialogueDocument(startTitle: entry!.name);
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

    if (_loadedDialogueId != editor.selectedProjectDialogueId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadFromDisk(notifier, editor);
      });
    }

    final project = editor.project;
    if (project == null) {
      return const Center(child: Text('Charger un projet pour Dialogue Studio.'));
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(width: 300, child: _buildLibraryColumn(context, editor, notifier)),
        const SizedBox(width: 10),
        Expanded(child: _buildCenterColumn(context, editor, notifier)),
        const SizedBox(width: 10),
        SizedBox(width: 320, child: _buildInspectorColumn(context, editor, notifier)),
      ],
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
                    color: CupertinoColors.label.resolveFrom(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Arborescence réelle du manifeste : dossiers et fichiers .yarn.',
                  style: TextStyle(
                    fontSize: 11,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
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
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
                const SizedBox(height: 6),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => setState(() => _sidebarTargetFolderId = null),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _sidebarTargetFolderId == null
                            ? EditorChrome.inspectorJoyBlue
                            : CupertinoColors.separator.resolveFrom(context),
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
                        color: CupertinoColors.label.resolveFrom(context),
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
                      color: CupertinoColors.secondaryLabel.resolveFrom(context),
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
                    onPressed: () => _promptNewDialogue(context, notifier),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: EditorChrome.inspectorJoyBlue,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        '+ Nouveau',
                        style: TextStyle(
                          color: CupertinoColors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => _promptNewFolder(context, notifier),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: CupertinoColors.separator.resolveFrom(context),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '+ Dossier',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: CupertinoColors.label.resolveFrom(context),
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
                    color: CupertinoColors.separator.resolveFrom(context),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Importer .yarn / .txt',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: CupertinoColors.label.resolveFrom(context),
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
                      notifier.selectProjectDialogue(dialogueId);
                      setState(() {
                        final p = parentFolderId?.trim() ?? '';
                        _sidebarTargetFolderId = p.isEmpty ? null : p;
                      });
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
                      notifier.selectProjectDialogue(d.id);
                      setState(() {
                        final p = d.folderId?.trim() ?? '';
                        _sidebarTargetFolderId = p.isEmpty ? null : p;
                      });
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
          if (editor.selectedProjectDialogueId != null) _selectionInfoCard(context, editor, notifier),
        ],
      ),
    );
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
            color: CupertinoColors.separator.resolveFrom(context),
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
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
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
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
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
                    child: const Text('Renommer', style: TextStyle(fontSize: 12)),
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
                    child: const Text('Déplacer…', style: TextStyle(fontSize: 12)),
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
                    child: Text(
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
      return EditorPaneSurface(
        radius: 20,
        tint: EditorChrome.islandWarmTint,
        child: Center(
          child: Text(
            'Sélectionnez un dialogue dans la liste à gauche.',
            style: TextStyle(
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
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
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  'Montage visuel — le Yarn est un export, pas la vue principale.',
                  style: TextStyle(
                    fontSize: 11,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _tabChip(context, 'Visuel', 0),
                const SizedBox(width: 8),
                _tabChip(context, 'Aperçu', 1),
                const SizedBox(width: 8),
                _tabChip(context, 'Yarn', 2),
                const Spacer(),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: _aiBusy ? null : () => _runAiGeneration(notifier, append: false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: EditorChrome.inspectorJoyBlue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _aiBusy
                        ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                        : const Text(
                            'Générer avec IA',
                            style: TextStyle(color: CupertinoColors.white, fontSize: 12),
                          ),
                  ),
                ),
                const SizedBox(width: 6),
                CupertinoButton(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  onPressed: _aiBusy ? null : () => _runAiGeneration(notifier, append: true),
                  child: const Text('Continuer avec IA', style: TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 6),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => _save(notifier, id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: EditorChrome.accentJade,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Sauvegarder',
                      style: TextStyle(color: CupertinoColors.white, fontSize: 12),
                    ),
                  ),
                ),
              ],
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
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Instruction IA',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
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
                    color: CupertinoColors.systemGrey6.resolveFrom(context),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                if (_iaError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _iaError!,
                    style: TextStyle(
                      fontSize: 11,
                      color: EditorChrome.inspectorJoyCoral,
                    ),
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
              : CupertinoColors.systemGrey6.resolveFrom(context),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: sel
                ? EditorChrome.inspectorJoyBlue
                : CupertinoColors.separator.resolveFrom(context),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: sel
                ? EditorChrome.inspectorJoyBlue
                : CupertinoColors.label.resolveFrom(context),
          ),
        ),
      ),
    );
  }

  Widget _buildVisualCanvas(BuildContext context, String dialogueId) {
    final doc = _doc!;
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CupertinoColors.separator.resolveFrom(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Row(
              children: [
                Text(
                  'Canvas de conversation',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
                const Spacer(),
                Text(
                  'Flux vertical • branches visibles pour les choix',
                  style: TextStyle(
                    fontSize: 10,
                    color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: CupertinoColors.separator.resolveFrom(context)),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              itemCount: doc.nodes.length,
              itemBuilder: (context, i) {
                final node = doc.nodes[i];
                return _NodeCanvasCard(
                  node: node,
                  selection: _selection,
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
        color: CupertinoColors.systemGrey6.resolveFrom(context),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _addLabel(context, 'Ajouter :'),
            _addKindButton(context, 'Réplique', () => _appendNewStep(_newLine())),
            _addKindButton(context, 'Narration', () => _appendNewStep(_newNarration())),
            _addKindButton(context, 'Choix', () => _appendNewStep(_newChoice())),
            _addKindButton(context, 'Condition', () => _appendNewStep(_newCondition())),
            _addKindButton(context, 'Jump', () => _appendNewStep(_newJump())),
            _addKindButton(context, 'Fin', () => _appendNewStep(DeEndStep(id: newDialogueEditorId()))),
            _addKindButton(context, 'Commande', () => _appendNewStep(_newCommand())),
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
          color: CupertinoColors.secondaryLabel.resolveFrom(context),
        ),
      ),
    );
  }

  Widget _addKindButton(BuildContext context, String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        minimumSize: Size.zero,
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(8),
        onPressed: onTap,
        child: Text(label, style: const TextStyle(fontSize: 11, color: Colors.black87)),
      ),
    );
  }

  Widget _buildPreview(BuildContext context) {
    _preview ??= DialoguePreviewSession(_doc!, startNodeTitle: null);
    final session = _preview!;
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CupertinoColors.separator.resolveFrom(context)),
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
                      _preview = DialoguePreviewSession(_doc!, startNodeTitle: null);
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: EditorChrome.inspectorJoyBlue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Rejouer depuis le début',
                      style: TextStyle(color: CupertinoColors.white, fontSize: 12),
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
                      child: Text(displayText, style: const TextStyle(fontSize: 14)),
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
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: EditorChrome.inspectorJoyMint.withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${j + 1}. ${options[j]}',
                                    style: const TextStyle(
                                      color: CupertinoColors.black,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  DialoguePreviewEnded(:final reason) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        reason == null ? '— Fin —' : 'Fin : $reason',
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: CupertinoColors.secondaryLabel.resolveFrom(context),
                        ),
                      ),
                    ),
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
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CupertinoColors.separator.resolveFrom(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Export Yarn (lecture seule depuis les blocs)',
            style: TextStyle(
              fontSize: 11,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6.resolveFrom(context),
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
    final issues = _doc == null ? <DialogueValidationIssue>[] : validateDialogueDocument(_doc!);

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
              color: CupertinoColors.label.resolveFrom(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Détail du bloc sélectionné.',
            style: TextStyle(
              fontSize: 11,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
          const SizedBox(height: 12),
          if (_doc == null || _selection == null)
            Text(
              'Cliquez sur un bloc au centre.',
              style: TextStyle(
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
                fontSize: 12,
              ),
            )
          else
            _buildInspectorBody(context, notifier),
          const SizedBox(height: 16),
          Text(
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
                          : CupertinoColors.secondaryLabel.resolveFrom(context),
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

  Widget _buildInspectorBody(BuildContext context, EditorNotifier notifier) {
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
              onChanged: (v) => _patchLine(sel, speaker: v.trim().isEmpty ? null : v.trim(), body: body),
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
              Text('Option ${i + 1}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11)),
              CupertinoTextField(
                controller: TextEditingController(text: branches[i].label),
                onChanged: (v) => _patchChoiceLabel(sel, branches[i].id, v),
                padding: const EdgeInsets.all(8),
              ),
              const SizedBox(height: 6),
            ],
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => _addChoiceOption(sel),
              child: const Align(
                alignment: Alignment.centerLeft,
                child: Text('+ Ajouter une option', style: TextStyle(fontSize: 12)),
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
      DeEndStep() => const Text('Fin de conversation (marqueur pour le montage).'),
    };
  }

  Widget _fieldLabel(BuildContext context, String t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        t,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: CupertinoColors.secondaryLabel.resolveFrom(context),
        ),
      ),
    );
  }

  Widget _aiMiniActions(BuildContext context, _StepSelection sel, {required String kind}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
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
              child: const Text('Générer 3 libellés', style: TextStyle(fontSize: 12)),
            ),
          ),
        CupertinoButton(
          padding: const EdgeInsets.symmetric(vertical: 8),
          onPressed: _aiBusy ? null : () => _runBlockRephrase(sel, tone: 'warmer'),
          child: const Text('Rendre plus chaleureux', style: TextStyle(fontSize: 12)),
        ),
        CupertinoButton(
          padding: const EdgeInsets.symmetric(vertical: 8),
          onPressed: _aiBusy ? null : () => _runBlockRephrase(sel, tone: 'shorter'),
          child: const Text('Raccourcir', style: TextStyle(fontSize: 12)),
        ),
      ],
    );
  }

  // --- Mutations document ---------------------------------------------------

  DialogueEditorStep? _findStep(DialogueEditorDocument doc, _StepSelection sel) {
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
  }

  void _replaceStep(_StepSelection sel, DialogueEditorStep next) {
    final list = _listForSelection(sel);
    final i = list.indexWhere((s) => s.id == sel.stepId);
    if (i < 0) return;
    list[i] = next;
    setState(() {});
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
          setState(() {});
          return;
        }
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
      setState(() {});
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

  DeJumpStep _newJump() => DeJumpStep(id: newDialogueEditorId(), targetTitle: '');

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

  Future<void> _runAiGeneration(EditorNotifier notifier, {required bool append}) async {
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

  Future<void> _runBlockRephrase(_StepSelection sel, {required String tone}) async {
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

  // --- Menus dossiers / déplacement (use cases réels du notifier) -----------

  Future<void> _openStudioDialogueFolderMenu(
    BuildContext hostContext,
    ProjectManifest project,
    EditorNotifier notifier,
    ProjectDialogueFolder folder, {
    required Offset anchorGlobal,
  }) async {
    final action = await showMacosEditorContextMenu<String>(
      context: hostContext,
      globalPosition: anchorGlobal,
      actions: const [
        MacosEditorSheetAction(label: 'Renommer le dossier', value: 'rename'),
        MacosEditorSheetAction(label: 'Nouveau sous-dossier', value: 'sub'),
        MacosEditorSheetAction(label: 'Déplacer le dossier…', value: 'move'),
        MacosEditorSheetAction(
          label: 'Supprimer le dossier',
          value: 'delete',
          isDestructive: true,
        ),
      ],
    );
    if (!hostContext.mounted || action == null) return;
    switch (action) {
      case 'rename':
        await _promptRenameDialogueFolder(hostContext, notifier, folder);
      case 'sub':
        await _promptNewFolder(hostContext, notifier, parentFolderId: folder.id);
      case 'move':
        await _pickMoveDialogueLibraryFolder(hostContext, project, notifier, folder.id);
      case 'delete':
        final ok = await showMacosEditorTwoChoiceAlert(
          hostContext,
          title: 'Supprimer le dossier ?',
          message:
              'Les dialogues qu’il contient doivent être déplacés ailleurs avant suppression.',
          primaryLabel: 'Supprimer',
          primaryIsDestructive: true,
        );
        if (ok && hostContext.mounted) {
          await notifier.deleteDialogueLibraryFolder(folder.id);
        }
    }
  }

  Future<void> _openStudioDialogueEntryMenu(
    BuildContext hostContext,
    ProjectManifest project,
    EditorNotifier notifier,
    ProjectDialogueEntry entry,
    Offset anchor,
  ) async {
    final inFolder = entry.folderId != null && entry.folderId!.trim().isNotEmpty;
    final action = await showMacosEditorContextMenu<String>(
      context: hostContext,
      globalPosition: anchor,
      actions: [
        const MacosEditorSheetAction(label: 'Renommer', value: 'rename'),
        const MacosEditorSheetAction(label: 'Déplacer vers un dossier…', value: 'move'),
        if (inFolder)
          const MacosEditorSheetAction(
            label: 'Mettre à la racine',
            value: 'root',
          ),
      ],
    );
    if (!hostContext.mounted || action == null) return;
    switch (action) {
      case 'rename':
        await _promptRename(hostContext, notifier, entry);
      case 'move':
        await _promptMoveDialogueToFolder(hostContext, notifier, project, entry);
      case 'root':
        await notifier.moveDialogueToLibraryRoot(entry.id);
    }
  }

  Future<void> _promptRenameDialogueFolder(
    BuildContext context,
    EditorNotifier notifier,
    ProjectDialogueFolder folder,
  ) async {
    final c = TextEditingController(text: folder.name);
    final ok = await showMacosEditorPromptSheet(
      context,
      title: 'Renommer le dossier',
      controller: c,
      confirmLabel: 'Enregistrer',
      placeholder: 'Nom',
      compact: true,
    );
    if (!ok || !context.mounted) return;
    final name = c.text.trim();
    if (name.isEmpty) return;
    await notifier.renameDialogueLibraryFolder(folderId: folder.id, name: name);
  }

  Future<void> _pickMoveDialogueLibraryFolder(
    BuildContext context,
    ProjectManifest project,
    EditorNotifier notifier,
    String folderId,
  ) async {
    final blocked = dialogueFolderSubtreeIds(project, folderId);
    final options = <_DialogueFolderMoveOption>[
      const _DialogueFolderMoveOption('Racine des dossiers', null),
    ];
    for (final row in flattenDialogueFoldersForPicker(project)) {
      if (row.id == folderId) continue;
      if (blocked.contains(row.id)) continue;
      options.add(_DialogueFolderMoveOption(row.label, row.id));
    }
    final picked = await showCupertinoListPicker<_DialogueFolderMoveOption>(
      context: context,
      title: 'Déplacer le dossier vers…',
      items: options,
      labelOf: (o) => o.label,
    );
    if (picked == null || !context.mounted) return;
    await notifier.moveDialogueLibraryFolder(
      folderId: folderId,
      newParentFolderId: picked.newParentId,
    );
  }

  Future<void> _promptMoveDialogueToFolder(
    BuildContext context,
    EditorNotifier notifier,
    ProjectManifest project,
    ProjectDialogueEntry entry,
  ) async {
    final options = <_AssignDialogueFolderDest>[
      const _AssignDialogueFolderDest('Racine (hors dossier)', null),
      ...flattenDialogueFoldersForPicker(project)
          .map((r) => _AssignDialogueFolderDest(r.label, r.id)),
    ];
    final picked = await showCupertinoListPicker<_AssignDialogueFolderDest>(
      context: context,
      title: 'Ranger le dialogue dans…',
      items: options,
      labelOf: (o) => o.label,
    );
    if (picked == null || !context.mounted) return;
    if (picked.folderId == null) {
      await notifier.moveDialogueToLibraryRoot(entry.id);
    } else {
      await notifier.assignDialogueToLibraryFolder(
        dialogueId: entry.id,
        folderId: picked.folderId!,
      );
    }
  }

  // --- Persistance / prompts ------------------------------------------------

  Future<void> _save(EditorNotifier notifier, String dialogueId) async {
    if (_doc == null) return;
    final yarn = emitDocumentToYarn(_doc!);
    await notifier.saveProjectDialogueYarnBody(
      dialogueId: dialogueId,
      yarnBody: yarn,
    );
  }

  Future<void> _promptNewDialogue(BuildContext context, EditorNotifier n) async {
    final c = TextEditingController();
    final ok = await showMacosEditorPromptSheet(
      context,
      title: 'Nouveau dialogue',
      controller: c,
      confirmLabel: 'Créer',
      placeholder: 'Nom affiché',
    );
    if (!ok || !context.mounted) return;
    final name = c.text.trim();
    if (name.isEmpty) return;
    await n.createProjectDialogue(
      name: name,
      folderId: _sidebarTargetFolderId,
    );
    n.selectDialogueWorkspace();
  }

  Future<void> _promptNewFolder(
    BuildContext context,
    EditorNotifier n, {
    String? parentFolderId,
  }) async {
    final c = TextEditingController();
    final ok = await showMacosEditorPromptSheet(
      context,
      title: parentFolderId == null ? 'Nouveau dossier' : 'Nouveau sous-dossier',
      controller: c,
      confirmLabel: 'Créer',
      placeholder: 'Nom du dossier',
    );
    if (!ok || !context.mounted) return;
    final name = c.text.trim();
    if (name.isEmpty) return;
    await n.createDialogueLibraryFolder(
      name: name,
      parentFolderId: parentFolderId ?? _sidebarTargetFolderId,
    );
  }

  Future<void> _importProjectDialogue(
    BuildContext context,
    EditorNotifier notifier,
  ) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['yarn', 'txt'],
    );
    if (result == null || result.files.single.path == null) return;
    final path = result.files.single.path!;
    if (!context.mounted) return;
    final baseName =
        p.basenameWithoutExtension(path).replaceAll(RegExp(r'[^\w\-]+'), '_');
    final nameController = TextEditingController(text: baseName);
    final ok = await showMacosEditorPromptSheet(
      context,
      title: 'Importer un dialogue',
      controller: nameController,
      confirmLabel: 'Importer',
      placeholder: 'Nom dans le projet',
    );
    if (!ok || !context.mounted) return;
    final displayName = nameController.text.trim();
    if (displayName.isEmpty) return;
    await notifier.importProjectDialogue(
      absoluteSourcePath: path,
      displayName: displayName,
      folderId: _sidebarTargetFolderId,
    );
  }

  Future<void> _promptRename(
    BuildContext context,
    EditorNotifier n,
    ProjectDialogueEntry entry,
  ) async {
    final c = TextEditingController(text: entry.name);
    final ok = await showMacosEditorPromptSheet(
      context,
      title: 'Renommer le dialogue',
      controller: c,
      confirmLabel: 'Enregistrer',
      placeholder: 'Nom',
    );
    if (!ok || !context.mounted) return;
    final name = c.text.trim();
    if (name.isEmpty) return;
    await n.renameProjectDialogue(dialogueId: entry.id, newName: name);
  }
}

// --- Sous-widgets canvas ----------------------------------------------------

/// Nœud dossier : repliable, cible d’import/création au tap sur le nom, menu ⋯ branché au notifier.
class _StudioDialogueFolderTreeNode extends StatefulWidget {
  const _StudioDialogueFolderTreeNode({
    required this.branch,
    required this.depth,
    required this.project,
    required this.selectedDialogueId,
    required this.targetFolderId,
    required this.filter,
    required this.onDialogueTap,
    required this.onFolderTargetTap,
    required this.onFolderMenu,
    required this.onDialogueEntryMenuButton,
  });

  final DialogueLibraryBranch branch;
  final int depth;
  final ProjectManifest project;
  final String? selectedDialogueId;
  final String? targetFolderId;
  final bool Function(ProjectDialogueEntry) filter;
  final void Function(String dialogueId, String? parentFolderId) onDialogueTap;
  final ValueChanged<String> onFolderTargetTap;
  final void Function(BuildContext buttonContext, ProjectDialogueFolder folder)
      onFolderMenu;
  /// Bouton ⋯ : [BuildContext] du bouton sert à ancrer le menu macOS.
  final void Function(ProjectDialogueEntry entry, BuildContext menuButtonContext)
      onDialogueEntryMenuButton;

  @override
  State<_StudioDialogueFolderTreeNode> createState() =>
      _StudioDialogueFolderTreeNodeState();
}

class _StudioDialogueFolderTreeNodeState extends State<_StudioDialogueFolderTreeNode> {
  /// État UI local de repli — ne duplique pas la hiérarchie manifeste.
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final f = widget.branch.folder;
    final isTarget = widget.targetFolderId == f.id;
    final left = widget.depth * 12.0 + 4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.only(left: left, top: 4, bottom: 2),
          child: Row(
            children: [
              CupertinoButton(
                padding: const EdgeInsets.all(4),
                minimumSize: Size.zero,
                onPressed: () => setState(() => _expanded = !_expanded),
                child: AnimatedRotation(
                  turns: _expanded ? 0.25 : 0,
                  duration: const Duration(milliseconds: 140),
                  child: MacosIcon(
                    CupertinoIcons.chevron_right,
                    size: 14,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
              ),
              Expanded(
                child: CupertinoButton(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  minimumSize: Size.zero,
                  alignment: Alignment.centerLeft,
                  onPressed: () => widget.onFolderTargetTap(f.id),
                  child: Row(
                    children: [
                      MacosIcon(
                        CupertinoIcons.folder_fill,
                        size: 15,
                        color: isTarget
                            ? EditorChrome.inspectorJoyBlue
                            : CupertinoColors.secondaryLabel.resolveFrom(context),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          f.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: isTarget
                                ? EditorChrome.inspectorJoyBlue
                                : CupertinoColors.label.resolveFrom(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Builder(
                builder: (btnContext) => EditorToolbarIconButton(
                  icon: CupertinoIcons.ellipsis_vertical,
                  tooltip: 'Actions dossier',
                  iconSize: 16,
                  onPressed: () => widget.onFolderMenu(btnContext, f),
                ),
              ),
            ],
          ),
        ),
        if (_expanded) ...[
          ...widget.branch.childFolders.map(
            (c) => _StudioDialogueFolderTreeNode(
              branch: c,
              depth: widget.depth + 1,
              project: widget.project,
              selectedDialogueId: widget.selectedDialogueId,
              targetFolderId: widget.targetFolderId,
              filter: widget.filter,
              onDialogueTap: widget.onDialogueTap,
              onFolderTargetTap: widget.onFolderTargetTap,
              onFolderMenu: widget.onFolderMenu,
              onDialogueEntryMenuButton: widget.onDialogueEntryMenuButton,
            ),
          ),
          ...widget.branch.dialogues.where(widget.filter).map(
                (d) => _DialogueEntryRow(
                  entry: d,
                  selected: widget.selectedDialogueId == d.id,
                  depth: widget.depth + 1,
                  onTap: () => widget.onDialogueTap(d.id, d.folderId),
                  onMenuButton: (btnCtx) =>
                      widget.onDialogueEntryMenuButton(d, btnCtx),
                ),
              ),
        ],
      ],
    );
  }
}

class _DialogueEntryRow extends StatelessWidget {
  const _DialogueEntryRow({
    required this.entry,
    required this.selected,
    required this.depth,
    required this.onTap,
    this.onMenuButton,
  });

  final ProjectDialogueEntry entry;
  final bool selected;
  final int depth;
  final VoidCallback onTap;
  final void Function(BuildContext menuButtonContext)? onMenuButton;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: depth * 12.0),
      child: Row(
        children: [
          Expanded(
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              minimumSize: Size.zero,
              onPressed: onTap,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: selected
                      ? EditorChrome.inspectorJoyBlue.withValues(alpha: 0.14)
                      : null,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: selected
                        ? EditorChrome.inspectorJoyBlue
                        : CupertinoColors.separator
                            .resolveFrom(context)
                            .withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  entry.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
          if (onMenuButton != null)
            Builder(
              builder: (btnContext) => EditorToolbarIconButton(
                icon: CupertinoIcons.ellipsis_vertical,
                tooltip: 'Actions dialogue',
                iconSize: 16,
                onPressed: () => onMenuButton!(btnContext),
              ),
            ),
        ],
      ),
    );
  }
}

class _NodeCanvasCard extends StatelessWidget {
  const _NodeCanvasCard({
    required this.node,
    required this.selection,
    required this.onSelectStep,
    required this.onDeleteStep,
  });

  final DialogueEditorNode node;
  final _StepSelection? selection;
  final void Function(_StepSelection sel) onSelectStep;
  final void Function(_StepSelection sel) onDeleteStep;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CupertinoColors.separator.resolveFrom(context)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6.resolveFrom(context),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
              ),
              child: Text(
                'Nœud : ${node.title}',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final s in node.steps) ...[
                    _StepBlockTile(
                      step: s,
                      nodeId: node.id,
                      branchId: null,
                      selected: selection?.nodeId == node.id &&
                          selection?.branchId == null &&
                          selection?.stepId == s.id,
                      onTap: () => onSelectStep(
                            _StepSelection(nodeId: node.id, stepId: s.id),
                          ),
                      onDelete: () => onDeleteStep(
                            _StepSelection(nodeId: node.id, stepId: s.id),
                          ),
                    ),
                    if (s is DeChoiceStep)
                      ...s.branches.map(
                        (b) => Padding(
                          padding: const EdgeInsets.only(left: 12, top: 8),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: EditorChrome.inspectorJoyMint.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Branche : ${b.label}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                for (final inner in b.steps)
                                  _StepBlockTile(
                                    step: inner,
                                    nodeId: node.id,
                                    branchId: b.id,
                                    selected: selection?.nodeId == node.id &&
                                        selection?.branchId == b.id &&
                                        selection?.stepId == inner.id,
                                    onTap: () => onSelectStep(
                                          _StepSelection(
                                            nodeId: node.id,
                                            branchId: b.id,
                                            stepId: inner.id,
                                          ),
                                        ),
                                    onDelete: () => onDeleteStep(
                                          _StepSelection(
                                            nodeId: node.id,
                                            branchId: b.id,
                                            stepId: inner.id,
                                          ),
                                        ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepBlockTile extends StatelessWidget {
  const _StepBlockTile({
    required this.step,
    required this.nodeId,
    required this.branchId,
    required this.selected,
    required this.onTap,
    required this.onDelete,
  });

  final DialogueEditorStep step;
  final String nodeId;
  final String? branchId;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final (String title, String subtitle) = switch (step) {
      DeStartStep() => ('Début', 'Point d’entrée visuel'),
      DeLineStep(:final speaker, :final body) => (
          'Réplique',
          '${speaker ?? '?' }: $body',
        ),
      DeNarrationStep(:final text) => ('Narration', text),
      DeChoiceStep() => ('Choix joueur', 'Plusieurs branches'),
      DeJumpStep(:final targetTitle) => ('Jump', '→ $targetTitle'),
      DeConditionStep(:final raw) => ('Condition', raw),
      DeCommandStep(:final raw) => ('Commande', raw),
      DeEndStep() => ('Fin', 'Termine ici'),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: selected
                ? EditorChrome.inspectorJoyBlue.withValues(alpha: 0.12)
                : CupertinoColors.systemBackground.resolveFrom(context),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? EditorChrome.inspectorJoyBlue
                  : CupertinoColors.separator.resolveFrom(context),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        color: EditorChrome.inspectorJoyBlue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, height: 1.25),
                    ),
                  ],
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: const Size(28, 28),
                onPressed: onDelete,
                child: Icon(
                  CupertinoIcons.trash,
                  size: 16,
                  color: EditorChrome.inspectorJoyCoral,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

({int nodes, int choices, int ends}) _docStats(DialogueEditorDocument? doc) {
  if (doc == null) return (nodes: 0, choices: 0, ends: 0);
  var choices = 0;
  var ends = 0;
  void walk(List<DialogueEditorStep> list) {
    for (final s in list) {
      if (s is DeChoiceStep) {
        choices++;
        for (final b in s.branches) {
          walk(b.steps);
        }
      }
      if (s is DeEndStep) ends++;
    }
  }
  for (final n in doc.nodes) {
    walk(n.steps);
  }
  return (nodes: doc.nodes.length, choices: choices, ends: ends);
}

String _dialogueName(ProjectManifest project, String id) {
  for (final d in project.dialogues) {
    if (d.id == id) return d.name;
  }
  return id;
}
