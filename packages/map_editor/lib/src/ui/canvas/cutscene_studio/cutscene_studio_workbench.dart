// =============================================================================
// Cutscene Studio — composition écran (PokeMap)
// =============================================================================
//
// Ce fichier matérialise le wireframe produit :
//   [ Top bar : fil d’Ariane + nom + actions ]
//   [ Palette gauche | Flow vertical centre | Inspecteur droite ]
//
// Intentions UX (à lire avant de modifier) :
// - **Gauche** : bibliothèque d’« actions » drag-and-drop, vocabulaire métier,
//   recherche + catégories repliables. Aucun graphe libre ici : seulement des
//   briques prêtes à glisser.
// - **Centre** : le cœur narratif — lecture **verticale** Start → blocs → End,
//   avec zones de dépôt explicites (« Déposer un bloc ici »). Les embranchements
//   Oui/Non restent **alignés** pour éviter l’effet « spaghetti ».
// - **Droite** : configuration **contextuelle** du bloc sélectionné. Le centre
//   montre un **résumé** ; le détail vit ici (principe séparation composition /
//   inspection, comme dans un outil no-code sérieux).
// - **Suppression d’une cutscene entière** : liste des scénarios ([NarrativeWorkspaceCanvas]).
// - **Suppression d’une étape** : corbeille sur chaque carte du flow + bouton « Retirer »
//   dans l’inspecteur quand un bloc est sélectionné.
// - **Poignées** entre les trois colonnes : redimensionnement horizontal (curseur
//   « resize column »), avec garde-fous min/max pour la palette, la scène et les propriétés.
//
// Drag-and-drop (mutations = fonctions pures côté authoring, pas dans ce widget) :
// - Palette → tronc : [insertMainFlowEntryAt] après drop sur une fente du fil principal.
// - Réordonnancement tronc : [moveMainFlowEntry].
// - Branche Oui / Non : [insertIntoChoiceBranch] (index du choix sur le tronc connu).
// - Suppression : [removeCutsceneFlowBlockEntryWithId] (icône corbeille sur la carte + inspecteur).
// Payloads UI : [CutsceneStudioPaletteDragData], [CutsceneCanvasReorderDragData].
// Les [DragTarget] acceptent l’union des deux pour un seul type de « fente ».
//
// Évolutions prévues (non bloquantes pour cette base) :
// - Glisser un bloc déjà posé d’une branche vers une autre ;
// - Dupliquer / couper-coller ;
// - Mini-cartes de prévisualisation (portrait PNJ) sur les blocs dialogue.
//
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Material, Tooltip;
import 'package:macos_ui/macos_ui.dart';

import '../../../features/narrative/application/cutscene_studio_authoring.dart';
import '../../shared/cupertino_editor_widgets.dart';

// ---------------------------------------------------------------------------
// Données de drag partagées (palette + canvas)
// ---------------------------------------------------------------------------

/// Glisser depuis la colonne gauche : on instanciera un bloc via le [kind].
@immutable
class CutsceneStudioPaletteDragData {
  const CutsceneStudioPaletteDragData(this.kind);
  final CutsceneStudioBlockKind kind;
}

/// Glisser un bloc déjà sur le tronc principal pour le réordonner.
@immutable
class CutsceneCanvasReorderDragData {
  const CutsceneCanvasReorderDragData(this.mainIndex);
  final int mainIndex;
}

/// Catégories palette alignées sur le vocabulaire produit (pas sur l’enum technique).
enum CutsceneWorkbenchPaletteCategory {
  dialogue,
  characters,
  movement,
  camera,
  waits,
  conditions,
}

String cutsceneWorkbenchPaletteCategoryLabel(
  CutsceneWorkbenchPaletteCategory c,
) {
  return switch (c) {
    CutsceneWorkbenchPaletteCategory.dialogue => 'Dialogue',
    CutsceneWorkbenchPaletteCategory.characters => 'Personnages',
    CutsceneWorkbenchPaletteCategory.movement => 'Déplacements',
    CutsceneWorkbenchPaletteCategory.camera => 'Caméra',
    CutsceneWorkbenchPaletteCategory.waits => 'Attentes',
    CutsceneWorkbenchPaletteCategory.conditions => 'Conditions',
  };
}

CutsceneWorkbenchPaletteCategory categoryForWorkbenchPaletteKind(
  CutsceneStudioBlockKind kind,
) {
  return switch (kind) {
    CutsceneStudioBlockKind.dialogue ||
    CutsceneStudioBlockKind.narration =>
      CutsceneWorkbenchPaletteCategory.dialogue,
    CutsceneStudioBlockKind.characterAppear ||
    CutsceneStudioBlockKind.characterDisappear ||
    CutsceneStudioBlockKind.faceCharacter =>
      CutsceneWorkbenchPaletteCategory.characters,
    CutsceneStudioBlockKind.moveCharacter ||
    CutsceneStudioBlockKind.pathfindMove ||
    CutsceneStudioBlockKind.followCharacter ||
    CutsceneStudioBlockKind.transitionMap =>
      CutsceneWorkbenchPaletteCategory.movement,
    CutsceneStudioBlockKind.cameraCenter ||
    CutsceneStudioBlockKind.cameraTransition =>
      CutsceneWorkbenchPaletteCategory.camera,
    CutsceneStudioBlockKind.wait => CutsceneWorkbenchPaletteCategory.waits,
    CutsceneStudioBlockKind.playerQuestion ||
    CutsceneStudioBlockKind.callCutscene ||
    CutsceneStudioBlockKind.starterChoice ||
    CutsceneStudioBlockKind.sceneResult ||
    CutsceneStudioBlockKind.runScript ||
    CutsceneStudioBlockKind.setFlag ||
    CutsceneStudioBlockKind.clearFlag ||
    CutsceneStudioBlockKind.emitOutcome =>
      CutsceneWorkbenchPaletteCategory.conditions,
  };
}

/// Items affichés dans la palette (sous-ensemble volontairement orienté produit).
const List<CutsceneStudioBlockKind> kCutsceneWorkbenchPaletteKinds =
    <CutsceneStudioBlockKind>[
  CutsceneStudioBlockKind.dialogue,
  CutsceneStudioBlockKind.characterAppear,
  CutsceneStudioBlockKind.characterDisappear,
  CutsceneStudioBlockKind.faceCharacter,
  CutsceneStudioBlockKind.moveCharacter,
  CutsceneStudioBlockKind.pathfindMove,
  CutsceneStudioBlockKind.followCharacter,
  CutsceneStudioBlockKind.cameraCenter,
  CutsceneStudioBlockKind.cameraTransition,
  CutsceneStudioBlockKind.wait,
  CutsceneStudioBlockKind.playerQuestion,
  CutsceneStudioBlockKind.callCutscene,
];

/// Largeur de chaque poignée entre palette / scène / propriétés.
const double _kCutsceneWorkbenchSplitterWidth = 6;

/// Largeurs de colonnes après contraintes (zone flux toujours >= [_kMinFlowW] si possible).
@immutable
class _CutsceneBenchColumnLayout {
  const _CutsceneBenchColumnLayout({
    required this.palette,
    required this.flow,
    required this.inspector,
  });

  final double palette;
  final double flow;
  final double inspector;
}

_CutsceneBenchColumnLayout _resolveCutsceneBenchColumns({
  required double totalWidth,
  required double paletteW,
  required double inspectorW,
  double minPalette = 168,
  double maxPalette = 440,
  double minInspector = 200,
  double maxInspector = 560,
  double minFlow = 220,
}) {
  const overhead = 2 * _kCutsceneWorkbenchSplitterWidth;
  var p = paletteW.clamp(minPalette, maxPalette);
  var ins = inspectorW.clamp(minInspector, maxInspector);
  var flow = totalWidth - p - ins - overhead;
  while (flow < minFlow) {
    final deficit = minFlow - flow;
    if (ins > minInspector) {
      final sub = math.min(deficit, ins - minInspector);
      ins -= sub;
      flow += sub;
    } else if (p > minPalette) {
      final sub = math.min(deficit, p - minPalette);
      p -= sub;
      flow += sub;
    } else {
      break;
    }
  }
  flow = math.max(0, flow);
  return _CutsceneBenchColumnLayout(
    palette: p,
    flow: flow,
    inspector: ins,
  );
}

// ---------------------------------------------------------------------------
// Shell principal
// ---------------------------------------------------------------------------

class CutsceneStudioWorkbench extends StatefulWidget {
  const CutsceneStudioWorkbench({
    super.key,
    required this.cutsceneName,
    required this.onRename,
    required this.flow,
    required this.onCommitFlow,
    required this.canEdit,
    required this.busy,
    required this.hasUnsavedChanges,
    required this.onSave,
    required this.onReset,
    required this.onTest,
    required this.onSimulate,
    required this.onCreateNew,
    required this.selectedBlockId,
    required this.onSelectBlock,
    required this.paletteBlockFactory,
    required this.flowSummaryBuilder,
    required this.inspector,
    required this.sourceStrip,
    required this.compatibilityBanner,
    this.runtimeHonestyBanner,
  });

  final String cutsceneName;
  final ValueChanged<String> onRename;
  final List<CutsceneFlowEntry> flow;
  final ValueChanged<List<CutsceneFlowEntry>> onCommitFlow;
  final bool canEdit;
  final bool busy;
  final bool hasUnsavedChanges;
  final VoidCallback onSave;
  final VoidCallback onReset;
  final VoidCallback onTest;
  final VoidCallback onSimulate;
  final VoidCallback onCreateNew;
  final String? selectedBlockId;
  final ValueChanged<String?> onSelectBlock;

  /// Crée un bloc neuf (ids uniques, défauts PNJ/map) à partir d’un kind palette.
  final CutsceneStudioBlock Function(CutsceneStudioBlockKind kind)
      paletteBlockFactory;

  /// Sous-titre lisible dans la carte de flow (ex. prénom PNJ, extrait texte).
  final String Function(CutsceneStudioBlock block) flowSummaryBuilder;

  /// Colonne droite : détail du bloc sélectionné ou méta cutscene.
  final Widget inspector;

  /// Bandeau compact « quand la scène démarre » (hook monde).
  final Widget sourceStrip;

  /// Bannière lecture seule si graphe incompatible.
  final Widget? compatibilityBanner;

  /// Rappels honnêteté runtime (placeholder, choix MVP, waitMs…) — optionnel.
  final Widget? runtimeHonestyBanner;

  @override
  State<CutsceneStudioWorkbench> createState() =>
      _CutsceneStudioWorkbenchState();
}

class _CutsceneStudioWorkbenchState extends State<CutsceneStudioWorkbench> {
  final TextEditingController _search = TextEditingController();
  final Set<CutsceneWorkbenchPaletteCategory> _openCategories = {
    for (final c in CutsceneWorkbenchPaletteCategory.values) c,
  };

  /// Largeur souhaitée de la palette (ajustée au drag + contraintes dans [_resolveCutsceneBenchColumns]).
  double _paletteWidth = 236;

  /// Largeur souhaitée de l’inspecteur (idem).
  double _inspectorWidth = 276;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _acceptDropOnMain({
    required int insertIndex,
    Object? data,
  }) {
    if (!widget.canEdit || data == null) return;
    if (data is CutsceneStudioPaletteDragData) {
      final block = widget.paletteBlockFactory(data.kind);
      final next = insertMainFlowEntryAt(
        widget.flow,
        insertIndex,
        CutsceneFlowBlockEntry(block),
      );
      widget.onCommitFlow(next);
      widget.onSelectBlock(block.id);
      return;
    }
    if (data is CutsceneCanvasReorderDragData) {
      if (data.mainIndex == insertIndex ||
          data.mainIndex + 1 == insertIndex) {
        return;
      }
      var to = insertIndex;
      if (data.mainIndex < insertIndex) {
        to -= 1;
      }
      final next = moveMainFlowEntry(widget.flow, data.mainIndex, to);
      widget.onCommitFlow(next);
    }
  }

  void _acceptDropOnBranch({
    required int choiceMainIndex,
    required bool yesBranch,
    required int branchInsertIndex,
    Object? data,
  }) {
    if (!widget.canEdit || data == null) return;
    if (data is! CutsceneStudioPaletteDragData) {
      return;
    }
    final block = widget.paletteBlockFactory(data.kind);
    final next = insertIntoChoiceBranch(
      widget.flow,
      choiceMainIndex,
      yesBranch: yesBranch,
      branchInsertIndex: branchInsertIndex,
      newEntry: CutsceneFlowBlockEntry(block),
    );
    widget.onCommitFlow(next);
    widget.onSelectBlock(block.id);
  }

  void _removeFlowStep(String blockOrQuestionId) {
    if (!widget.canEdit) return;
    final next =
        removeCutsceneFlowBlockEntryWithId(widget.flow, blockOrQuestionId);
    widget.onCommitFlow(next);
    if (widget.selectedBlockId == blockOrQuestionId) {
      widget.onSelectBlock(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = EditorChrome.largeIslandSurfaceColor(
      context,
      tint: EditorChrome.islandWarmTint.withValues(alpha: 0.05),
    );
    final filteredKinds = _filteredPaletteKinds();

    return ColoredBox(
      color: bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _WorkbenchTopBar(
            key: ValueKey<String>(widget.cutsceneName),
            cutsceneName: widget.cutsceneName,
            onRename: widget.onRename,
            busy: widget.busy,
            hasUnsavedChanges: widget.hasUnsavedChanges,
            canEdit: widget.canEdit,
            onSave: widget.onSave,
            onReset: widget.onReset,
            onTest: widget.onTest,
            onSimulate: widget.onSimulate,
            onCreateNew: widget.onCreateNew,
          ),
          if (widget.compatibilityBanner != null) widget.compatibilityBanner!,
          if (widget.runtimeHonestyBanner != null) widget.runtimeHonestyBanner!,
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: widget.sourceStrip,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final total = constraints.maxWidth;
                  final layout = _resolveCutsceneBenchColumns(
                    totalWidth: total,
                    paletteW: _paletteWidth,
                    inspectorW: _inspectorWidth,
                  );
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: layout.palette,
                        child: _PaletteColumn(
                          searchController: _search,
                          onSearchChanged: (_) => setState(() {}),
                          openCategories: _openCategories,
                          onToggleCategory: (c) {
                            setState(() {
                              if (_openCategories.contains(c)) {
                                _openCategories.remove(c);
                              } else {
                                _openCategories.add(c);
                              }
                            });
                          },
                          filteredKinds: filteredKinds,
                        ),
                      ),
                      _CutsceneWorkbenchHorizontalSplitter(
                        tooltip: 'Redimensionner la palette',
                        onDrag: (dx) {
                          setState(() {
                            final next = _resolveCutsceneBenchColumns(
                              totalWidth: total,
                              paletteW: _paletteWidth + dx,
                              inspectorW: _inspectorWidth,
                            );
                            _paletteWidth = next.palette;
                            _inspectorWidth = next.inspector;
                          });
                        },
                      ),
                      SizedBox(
                        width: layout.flow,
                        child: _FlowCanvasColumn(
                          flow: widget.flow,
                          canEdit: widget.canEdit,
                          selectedBlockId: widget.selectedBlockId,
                          onSelectBlock: widget.onSelectBlock,
                          flowSummaryBuilder: widget.flowSummaryBuilder,
                          onDropMain: _acceptDropOnMain,
                          onDropBranch: _acceptDropOnBranch,
                          onRemoveFlowStep: _removeFlowStep,
                        ),
                      ),
                      _CutsceneWorkbenchHorizontalSplitter(
                        tooltip: 'Redimensionner les propriétés',
                        onDrag: (dx) {
                          setState(() {
                            // Bord gauche du panneau Propriétés : élargir = tirer vers la gauche
                            // ([dx] négatif), d’où le signe opposé au séparateur palette | scène.
                            final next = _resolveCutsceneBenchColumns(
                              totalWidth: total,
                              paletteW: _paletteWidth,
                              inspectorW: _inspectorWidth - dx,
                            );
                            _paletteWidth = next.palette;
                            _inspectorWidth = next.inspector;
                          });
                        },
                      ),
                      SizedBox(
                        width: layout.inspector,
                        child: _InspectorColumn(
                          child: widget.inspector,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<CutsceneStudioBlockKind> _filteredPaletteKinds() {
    final q = _search.text.trim().toLowerCase();
    final kinds = <CutsceneStudioBlockKind>{...kCutsceneWorkbenchPaletteKinds};
    if (q.isEmpty) {
      return kinds.toList();
    }
    return kinds.where((k) {
      final label = cutsceneStudioBlockKindLabel(k).toLowerCase();
      final cat = cutsceneWorkbenchPaletteCategoryLabel(
        categoryForWorkbenchPaletteKind(k),
      ).toLowerCase();
      return label.contains(q) || cat.contains(q);
    }).toList();
  }
}

/// Séparateur vertical draggable entre deux colonnes du workbench.
class _CutsceneWorkbenchHorizontalSplitter extends StatelessWidget {
  const _CutsceneWorkbenchHorizontalSplitter({
    required this.onDrag,
    required this.tooltip,
  });

  final ValueChanged<double> onDrag;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final line = EditorChrome.subtleLabel(context).withValues(alpha: 0.38);
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      child: MacosTooltip(
        message: tooltip,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragUpdate: (details) => onDrag(details.delta.dx),
          child: SizedBox(
            width: _kCutsceneWorkbenchSplitterWidth,
            child: Center(
              child: Container(
                width: 1.5,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: line,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Top bar
// ---------------------------------------------------------------------------

class _WorkbenchTopBar extends StatefulWidget {
  const _WorkbenchTopBar({
    super.key,
    required this.cutsceneName,
    required this.onRename,
    required this.busy,
    required this.hasUnsavedChanges,
    required this.canEdit,
    required this.onSave,
    required this.onReset,
    required this.onTest,
    required this.onSimulate,
    required this.onCreateNew,
  });

  final String cutsceneName;
  final ValueChanged<String> onRename;
  final bool busy;
  final bool hasUnsavedChanges;
  final bool canEdit;
  final VoidCallback onSave;
  final VoidCallback onReset;
  final VoidCallback onTest;
  final VoidCallback onSimulate;
  final VoidCallback onCreateNew;

  @override
  State<_WorkbenchTopBar> createState() => _WorkbenchTopBarState();
}

class _WorkbenchTopBarState extends State<_WorkbenchTopBar> {
  late final TextEditingController _name = TextEditingController();

  @override
  void initState() {
    super.initState();
    _name.text = widget.cutsceneName;
  }

  @override
  void didUpdateWidget(covariant _WorkbenchTopBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cutsceneName != widget.cutsceneName &&
        widget.cutsceneName != _name.text) {
      _name.text = widget.cutsceneName;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(context),
        border: Border(
          bottom: BorderSide(
            color: CupertinoColors.separator.resolveFrom(context),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Narrative Studio  ›  Step  ›  Cutscene',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: EditorChrome.subtleLabel(context),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: CupertinoTextField(
                        placeholder: 'Nom de la cutscene',
                        controller: _name,
                        onSubmitted:
                            widget.canEdit ? (v) => widget.onRename(v) : null,
                        enabled: widget.canEdit && !widget.busy,
                        style: TextStyle(
                          color: EditorChrome.primaryLabel(context),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: const BoxDecoration(),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                    if (widget.hasUnsavedChanges)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          'Modifications non sauvegardées',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: EditorChrome.inspectorJoyCoral,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _TopBarTextButton(
                label: 'Tester',
                enabled: !widget.busy,
                onPressed: widget.onTest,
              ),
              const SizedBox(width: 6),
              _TopBarTextButton(
                label: 'Simuler',
                enabled: !widget.busy,
                onPressed: widget.onSimulate,
              ),
              const SizedBox(width: 10),
              _TopBarPrimaryButton(
                label: 'Sauvegarder',
                enabled: widget.canEdit &&
                    widget.hasUnsavedChanges &&
                    !widget.busy,
                onPressed: widget.onSave,
              ),
              const SizedBox(width: 8),
              _TopBarTextButton(
                label: 'Réinitialiser',
                enabled: widget.canEdit &&
                    widget.hasUnsavedChanges &&
                    !widget.busy,
                onPressed: widget.onReset,
              ),
              const SizedBox(width: 8),
              _TopBarTextButton(
                label: 'Nouvelle cutscene',
                enabled: !widget.busy,
                onPressed: widget.onCreateNew,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TopBarTextButton extends StatelessWidget {
  const _TopBarTextButton({
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      minimumSize: Size.zero,
      onPressed: enabled ? onPressed : null,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: enabled
              ? EditorChrome.primaryLabel(context)
              : EditorChrome.subtleLabel(context),
        ),
      ),
    );
  }
}

class _TopBarPrimaryButton extends StatelessWidget {
  const _TopBarPrimaryButton({
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton.filled(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      onPressed: enabled ? onPressed : null,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Palette
// ---------------------------------------------------------------------------

class _PaletteColumn extends StatelessWidget {
  const _PaletteColumn({
    required this.searchController,
    required this.onSearchChanged,
    required this.openCategories,
    required this.onToggleCategory,
    required this.filteredKinds,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final Set<CutsceneWorkbenchPaletteCategory> openCategories;
  final ValueChanged<CutsceneWorkbenchPaletteCategory> onToggleCategory;
  final List<CutsceneStudioBlockKind> filteredKinds;

  @override
  Widget build(BuildContext context) {
    final surface = EditorChrome.largeIslandSurfaceColor(
      context,
      tint: CupertinoColors.systemGrey.withValues(alpha: 0.06),
    );
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CupertinoColors.separator.resolveFrom(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
            child: CupertinoSearchTextField(
              controller: searchController,
              placeholder: 'Rechercher une action…',
              onChanged: onSearchChanged,
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
              children: [
                for (final category in CutsceneWorkbenchPaletteCategory.values)
                  if (filteredKinds.any(
                    (k) => categoryForWorkbenchPaletteKind(k) == category,
                  ))
                    _PaletteCategorySection(
                      category: category,
                      expanded: openCategories.contains(category),
                      onToggle: () => onToggleCategory(category),
                      kinds: filteredKinds
                          .where(
                            (k) =>
                                categoryForWorkbenchPaletteKind(k) == category,
                          )
                          .toList(),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaletteCategorySection extends StatelessWidget {
  const _PaletteCategorySection({
    required this.category,
    required this.expanded,
    required this.onToggle,
    required this.kinds,
  });

  final CutsceneWorkbenchPaletteCategory category;
  final bool expanded;
  final VoidCallback onToggle;
  final List<CutsceneStudioBlockKind> kinds;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CupertinoButton(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          minimumSize: Size.zero,
          onPressed: onToggle,
          child: Row(
            children: [
              Icon(
                expanded
                    ? CupertinoIcons.chevron_down
                    : CupertinoIcons.chevron_right,
                size: 14,
                color: EditorChrome.subtleLabel(context),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  cutsceneWorkbenchPaletteCategoryLabel(category),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: EditorChrome.primaryLabel(context),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (expanded)
          for (final kind in kinds)
            _PaletteDraggableTile(kind: kind),
      ],
    );
  }
}

class _PaletteDraggableTile extends StatelessWidget {
  const _PaletteDraggableTile({required this.kind});

  final CutsceneStudioBlockKind kind;

  @override
  Widget build(BuildContext context) {
    final label = cutsceneStudioBlockKindLabel(kind);
    final accent = _familyAccent(kind);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Draggable<Object>(
        data: CutsceneStudioPaletteDragData(kind),
        feedback: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 220,
            child: _FlowBlockCard(
              title: label,
              subtitle: 'Déposer dans le scénario',
              selected: true,
              accent: accent,
            ),
          ),
        ),
        childWhenDragging: Opacity(opacity: 0.35, child: _buildTile(context)),
        child: _buildTile(context),
      ),
    );
  }

  Widget _buildTile(BuildContext context) {
    final label = cutsceneStudioBlockKindLabel(kind);
    final accent = _familyAccent(kind);
    return _FlowBlockCard(
      title: label,
      subtitle: 'Glisser vers le scénario',
      selected: false,
      accent: accent,
    );
  }
}

Color _familyAccent(CutsceneStudioBlockKind kind) {
  switch (categoryForWorkbenchPaletteKind(kind)) {
    case CutsceneWorkbenchPaletteCategory.dialogue:
      return EditorChrome.inspectorJoyMint;
    case CutsceneWorkbenchPaletteCategory.characters:
      return EditorChrome.inspectorJoyBlue;
    case CutsceneWorkbenchPaletteCategory.movement:
      return EditorChrome.inspectorJoyCyan;
    case CutsceneWorkbenchPaletteCategory.camera:
      return EditorChrome.inspectorJoyPlum;
    case CutsceneWorkbenchPaletteCategory.waits:
      return EditorChrome.inspectorJoyCoral;
    case CutsceneWorkbenchPaletteCategory.conditions:
      return EditorChrome.inspectorJoyMint;
  }
}

// ---------------------------------------------------------------------------
// Flow canvas
// ---------------------------------------------------------------------------

class _FlowCanvasColumn extends StatelessWidget {
  const _FlowCanvasColumn({
    required this.flow,
    required this.canEdit,
    required this.selectedBlockId,
    required this.onSelectBlock,
    required this.flowSummaryBuilder,
    required this.onDropMain,
    required this.onDropBranch,
    required this.onRemoveFlowStep,
  });

  final List<CutsceneFlowEntry> flow;
  final bool canEdit;
  final String? selectedBlockId;
  final ValueChanged<String?> onSelectBlock;
  final String Function(CutsceneStudioBlock block) flowSummaryBuilder;
  final void Function({required int insertIndex, Object? data}) onDropMain;
  final void Function({
    required int choiceMainIndex,
    required bool yesBranch,
    required int branchInsertIndex,
    Object? data,
  }) onDropBranch;
  final ValueChanged<String> onRemoveFlowStep;

  @override
  Widget build(BuildContext context) {
    final surface = EditorChrome.largeIslandSurfaceColor(context);
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CupertinoColors.separator.resolveFrom(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Text(
              'Scène',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: EditorChrome.primaryLabel(context),
              ),
            ),
          ),
          Expanded(
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                scrollbars: true,
              ),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                children: [
                  const _FlowAnchorLabel(text: 'Start'),
                  _FlowConnector(),
                  _MainDropSlot(
                    enabled: canEdit,
                    insertIndex: 0,
                    onDrop: onDropMain,
                  ),
                  for (var i = 0; i < flow.length; i++) ...[
                    _FlowMainEntry(
                      entry: flow[i],
                      mainIndex: i,
                      canEdit: canEdit,
                      selectedBlockId: selectedBlockId,
                      onSelectBlock: onSelectBlock,
                      flowSummaryBuilder: flowSummaryBuilder,
                      onDropMain: onDropMain,
                      onDropBranch: onDropBranch,
                      onRemoveFlowStep: onRemoveFlowStep,
                    ),
                    _FlowConnector(),
                    _MainDropSlot(
                      enabled: canEdit,
                      insertIndex: i + 1,
                      onDrop: onDropMain,
                    ),
                  ],
                  const _FlowAnchorLabel(text: 'End'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FlowAnchorLabel extends StatelessWidget {
  const _FlowAnchorLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: CupertinoColors.separator.resolveFrom(context),
          ),
          color: EditorChrome.largeIslandSurfaceColor(
            context,
            tint: CupertinoColors.systemGrey.withValues(alpha: 0.12),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 12,
            color: EditorChrome.primaryLabel(context),
          ),
        ),
      ),
    );
  }
}

class _FlowConnector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Center(
        child: Container(
          width: 2,
          height: 14,
          decoration: BoxDecoration(
            color: CupertinoColors.separator.resolveFrom(context),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

class _MainDropSlot extends StatelessWidget {
  const _MainDropSlot({
    required this.enabled,
    required this.insertIndex,
    required this.onDrop,
  });

  final bool enabled;
  final int insertIndex;
  final void Function({required int insertIndex, Object? data}) onDrop;

  @override
  Widget build(BuildContext context) {
    return DragTarget<Object>(
      onAcceptWithDetails: (details) {
        onDrop(insertIndex: insertIndex, data: details.data);
      },
      builder: (context, candidate, rejected) {
        final active = candidate.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: active
                  ? EditorChrome.inspectorJoyPlum.withValues(alpha: 0.65)
                  : CupertinoColors.separator.resolveFrom(context),
              width: active ? 1.4 : 1,
            ),
            color: active
                ? EditorChrome.inspectorJoyPlum.withValues(alpha: 0.08)
                : EditorChrome.largeIslandSurfaceColor(
                    context,
                    tint: CupertinoColors.systemGrey.withValues(alpha: 0.05),
                  ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.plus_circled,
                size: 16,
                color: EditorChrome.subtleLabel(context),
              ),
              const SizedBox(width: 8),
              Text(
                enabled
                    ? '+ Déposer un bloc ici'
                    : 'Lecture seule — dépôt désactivé',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: EditorChrome.subtleLabel(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FlowMainEntry extends StatelessWidget {
  const _FlowMainEntry({
    required this.entry,
    required this.mainIndex,
    required this.canEdit,
    required this.selectedBlockId,
    required this.onSelectBlock,
    required this.flowSummaryBuilder,
    required this.onDropMain,
    required this.onDropBranch,
    required this.onRemoveFlowStep,
  });

  final CutsceneFlowEntry entry;
  final int mainIndex;
  final bool canEdit;
  final String? selectedBlockId;
  final ValueChanged<String?> onSelectBlock;
  final String Function(CutsceneStudioBlock block) flowSummaryBuilder;
  final void Function({required int insertIndex, Object? data}) onDropMain;
  final void Function({
    required int choiceMainIndex,
    required bool yesBranch,
    required int branchInsertIndex,
    Object? data,
  }) onDropBranch;
  final ValueChanged<String> onRemoveFlowStep;

  @override
  Widget build(BuildContext context) {
    switch (entry) {
      case CutsceneFlowBlockEntry(:final block):
        return _DraggableMainBlock(
          mainIndex: mainIndex,
          canEdit: canEdit,
          child: _SelectableFlowBlock(
            block: block,
            selected: selectedBlockId == block.id,
            onTap: () => onSelectBlock(block.id),
            subtitle: flowSummaryBuilder(block),
            canEdit: canEdit,
            onDelete: () => onRemoveFlowStep(block.id),
          ),
        );
      case CutsceneFlowChoiceEntry(:final question, :final onYes, :final onNo):
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SelectableFlowBlock(
              block: question,
              selected: selectedBlockId == question.id,
              onTap: () => onSelectBlock(question.id),
              subtitle: flowSummaryBuilder(question),
              canEdit: canEdit,
              onDelete: () => onRemoveFlowStep(question.id),
            ),
            const SizedBox(height: 8),
            _BranchColumn(
              label: _branchTitleForQuestion(question, 0),
              choiceMainIndex: mainIndex,
              yesBranch: true,
              branch: onYes,
              canEdit: canEdit,
              selectedBlockId: selectedBlockId,
              onSelectBlock: onSelectBlock,
              flowSummaryBuilder: flowSummaryBuilder,
              onDropBranch: onDropBranch,
              onRemoveFlowStep: onRemoveFlowStep,
            ),
            const SizedBox(height: 8),
            _BranchColumn(
              label: _branchTitleForQuestion(question, 1),
              choiceMainIndex: mainIndex,
              yesBranch: false,
              branch: onNo,
              canEdit: canEdit,
              selectedBlockId: selectedBlockId,
              onSelectBlock: onSelectBlock,
              flowSummaryBuilder: flowSummaryBuilder,
              onDropBranch: onDropBranch,
              onRemoveFlowStep: onRemoveFlowStep,
            ),
          ],
        );
    }
  }

}

String _branchTitleForQuestion(CutsceneStudioBlock question, int i) {
  final opts = question.choiceOptions;
  if (opts.length > i && opts[i].trim().isNotEmpty) {
    return opts[i].trim();
  }
  return i == 0 ? 'Oui' : 'Non';
}

class _BranchColumn extends StatelessWidget {
  const _BranchColumn({
    required this.label,
    required this.choiceMainIndex,
    required this.yesBranch,
    required this.branch,
    required this.canEdit,
    required this.selectedBlockId,
    required this.onSelectBlock,
    required this.flowSummaryBuilder,
    required this.onDropBranch,
    required this.onRemoveFlowStep,
  });

  final String label;
  final int choiceMainIndex;
  final bool yesBranch;
  final List<CutsceneFlowEntry> branch;
  final bool canEdit;
  final String? selectedBlockId;
  final ValueChanged<String?> onSelectBlock;
  final String Function(CutsceneStudioBlock block) flowSummaryBuilder;
  final void Function({
    required int choiceMainIndex,
    required bool yesBranch,
    required int branchInsertIndex,
    Object? data,
  }) onDropBranch;
  final ValueChanged<String> onRemoveFlowStep;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 14, right: 8),
          child: Text(
            '├',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: EditorChrome.subtleLabel(context),
            ),
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: CupertinoColors.separator.resolveFrom(context),
              ),
              color: EditorChrome.largeIslandSurfaceColor(
                context,
                tint: CupertinoColors.systemGrey.withValues(alpha: 0.04),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: EditorChrome.subtleLabel(context),
                  ),
                ),
                const SizedBox(height: 6),
                _BranchDropSlot(
                  enabled: canEdit,
                  choiceMainIndex: choiceMainIndex,
                  yesBranch: yesBranch,
                  insertIndex: 0,
                  onDrop: onDropBranch,
                ),
                for (var i = 0; i < branch.length; i++) ...[
                  _BranchInnerEntry(
                    entry: branch[i],
                    canEdit: canEdit,
                    selectedBlockId: selectedBlockId,
                    onSelectBlock: onSelectBlock,
                    flowSummaryBuilder: flowSummaryBuilder,
                    onRemoveFlowStep: onRemoveFlowStep,
                  ),
                  _BranchDropSlot(
                    enabled: canEdit,
                    choiceMainIndex: choiceMainIndex,
                    yesBranch: yesBranch,
                    insertIndex: i + 1,
                    onDrop: onDropBranch,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BranchInnerEntry extends StatelessWidget {
  const _BranchInnerEntry({
    required this.entry,
    required this.canEdit,
    required this.selectedBlockId,
    required this.onSelectBlock,
    required this.flowSummaryBuilder,
    required this.onRemoveFlowStep,
  });

  final CutsceneFlowEntry entry;
  final bool canEdit;
  final String? selectedBlockId;
  final ValueChanged<String?> onSelectBlock;
  final String Function(CutsceneStudioBlock block) flowSummaryBuilder;
  final ValueChanged<String> onRemoveFlowStep;

  @override
  Widget build(BuildContext context) {
    switch (entry) {
      case CutsceneFlowBlockEntry(:final block):
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: _SelectableFlowBlock(
            block: block,
            selected: selectedBlockId == block.id,
            onTap: () => onSelectBlock(block.id),
            subtitle: flowSummaryBuilder(block),
            canEdit: canEdit,
            onDelete: () => onRemoveFlowStep(block.id),
          ),
        );
      case CutsceneFlowChoiceEntry(:final question):
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            'Embranchement imbriqué : ${cutsceneStudioBlockKindLabel(question.kind)} — '
            'édition complète à venir dans cette branche.',
            style: TextStyle(
              fontSize: 11,
              color: EditorChrome.subtleLabel(context),
            ),
          ),
        );
    }
  }
}

class _BranchDropSlot extends StatelessWidget {
  const _BranchDropSlot({
    required this.enabled,
    required this.choiceMainIndex,
    required this.yesBranch,
    required this.insertIndex,
    required this.onDrop,
  });

  final bool enabled;
  final int choiceMainIndex;
  final bool yesBranch;
  final int insertIndex;
  final void Function({
    required int choiceMainIndex,
    required bool yesBranch,
    required int branchInsertIndex,
    Object? data,
  }) onDrop;

  @override
  Widget build(BuildContext context) {
    if (choiceMainIndex < 0) {
      return const SizedBox.shrink();
    }
    return DragTarget<Object>(
      onAcceptWithDetails: (details) {
        onDrop(
          choiceMainIndex: choiceMainIndex,
          yesBranch: yesBranch,
          branchInsertIndex: insertIndex,
          data: details.data,
        );
      },
      builder: (context, candidate, rejected) {
        final active = candidate.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: active
                  ? EditorChrome.inspectorJoyBlue.withValues(alpha: 0.55)
                  : CupertinoColors.separator.resolveFrom(context),
            ),
            color: active
                ? EditorChrome.inspectorJoyBlue.withValues(alpha: 0.06)
                : null,
          ),
          child: Text(
            enabled ? '+ Déposer un bloc ici' : '—',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: EditorChrome.subtleLabel(context),
            ),
          ),
        );
      },
    );
  }
}

class _DraggableMainBlock extends StatelessWidget {
  const _DraggableMainBlock({
    required this.mainIndex,
    required this.canEdit,
    required this.child,
  });

  final int mainIndex;
  final bool canEdit;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!canEdit) return child;
    return Draggable<Object>(
      data: CutsceneCanvasReorderDragData(mainIndex),
      feedback: Material(
        elevation: 3,
        borderRadius: BorderRadius.circular(12),
        child: Opacity(opacity: 0.9, child: child),
      ),
      childWhenDragging: Opacity(opacity: 0.25, child: child),
      child: child,
    );
  }
}

class _SelectableFlowBlock extends StatelessWidget {
  const _SelectableFlowBlock({
    required this.block,
    required this.selected,
    required this.onTap,
    required this.subtitle,
    required this.canEdit,
    required this.onDelete,
  });

  final CutsceneStudioBlock block;
  final bool selected;
  final VoidCallback onTap;
  final String subtitle;
  final bool canEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final accent = _familyAccent(block.kind);
    final destructive = CupertinoColors.destructiveRed.resolveFrom(context);
    return _FlowBlockCard(
      title: cutsceneStudioBlockKindLabel(block.kind),
      subtitle: subtitle,
      selected: selected,
      accent: accent,
      onTap: onTap,
      trailing: canEdit
          ? Tooltip(
              message: 'Retirer du scénario',
              child: CupertinoButton(
                padding: const EdgeInsets.all(6),
                minimumSize: Size.zero,
                onPressed: onDelete,
                child: Icon(
                  CupertinoIcons.trash,
                  size: 18,
                  color: destructive,
                ),
              ),
            )
          : null,
    );
  }
}

class _FlowBlockCard extends StatelessWidget {
  const _FlowBlockCard({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.accent,
    this.onTap,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final Color accent;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final textColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: EditorChrome.primaryLabel(context),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: EditorChrome.subtleLabel(context),
          ),
        ),
      ],
    );

    final main = onTap != null
        ? GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: textColumn,
          )
        : textColumn;

    final inner = trailing == null
        ? main
        : Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: main),
              const SizedBox(width: 4),
              trailing!,
            ],
          );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected
              ? accent.withValues(alpha: 0.75)
              : CupertinoColors.separator.resolveFrom(context),
          width: selected ? 1.6 : 1,
        ),
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: accent.withValues(alpha: selected ? 0.12 : 0.05),
        ),
      ),
      child: inner,
    );
  }
}

// ---------------------------------------------------------------------------
// Inspecteur — coque + actions globales cutscene
// ---------------------------------------------------------------------------

class _InspectorColumn extends StatelessWidget {
  const _InspectorColumn({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final surface = EditorChrome.largeIslandSurfaceColor(
      context,
      tint: CupertinoColors.systemGrey.withValues(alpha: 0.06),
    );
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CupertinoColors.separator.resolveFrom(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: Text(
              'Propriétés',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: EditorChrome.primaryLabel(context),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
