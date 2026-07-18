import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/narrative/state/narrative_event_builder_v2_state.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/events_v2/event_builder_v2_element_library.dart';
import 'package:map_editor/src/ui/canvas/events_v2/event_builder_v2_workspace.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

import 'narrative_studio_capture_fonts.dart';

const eventBuilderV2PhaseKReferenceViewport = Size(1672, 941);
const eventBuilderV2PhaseKCaptureViewports = <Size>[
  Size(1280, 941),
  Size(1440, 941),
  Size(1480, 941),
  eventBuilderV2PhaseKReferenceViewport,
  Size(1920, 941),
];

const eventBuilderV2PhaseKSelectedStableKey = 'event:rival';
const eventBuilderV2PhaseKBrokenSourceStableKey = 'event:broken-lantern';
const eventBuilderV2PhaseKCaptureFontFamily = 'NsEventV2PhaseKCaptureFont';

const eventBuilderV2PhaseKCaptureKey =
    ValueKey<String>('event-builder-v2-phase-k-capture');
const eventBuilderV2PhaseKHeaderKey =
    ValueKey<String>('event-builder-v2-phase-k-header');
const eventBuilderV2PhaseKContextBarKey =
    ValueKey<String>('event-builder-v2-phase-k-context-bar');
const eventBuilderV2PhaseKProjectSelectorKey =
    ValueKey<String>('event-builder-v2-phase-k-project-selector');
const eventBuilderV2PhaseKNavigationKey =
    ValueKey<String>('event-builder-v2-phase-k-navigation');
const eventBuilderV2PhaseKWorkspaceFrameKey =
    ValueKey<String>('event-builder-v2-phase-k-workspace-frame');

final File eventBuilderV2PhaseKAppIconFile = File(
  '${Directory.current.path}/'
  'macos/Runner/Assets.xcassets/AppIcon.appiconset/32.png',
);

Future<ui.Image>? _eventBuilderV2PhaseKAppIcon;

Future<ui.Image> _loadEventBuilderV2PhaseKAppIcon() {
  return _eventBuilderV2PhaseKAppIcon ??= () async {
    final codec = await ui.instantiateImageCodec(
      eventBuilderV2PhaseKAppIconFile.readAsBytesSync(),
    );
    final frame = await codec.getNextFrame();
    codec.dispose();
    return frame.image;
  }();
}

Future<void> loadEventBuilderV2PhaseKCaptureFonts() =>
    loadNarrativeStudioCaptureFonts(
      textFamilies: const <String>[eventBuilderV2PhaseKCaptureFontFamily],
    );

Future<void> pumpEventBuilderV2PhaseK(
  WidgetTester tester, {
  required Size viewport,
  double textScaleFactor = 1,
  String selectedStableKey = eventBuilderV2PhaseKSelectedStableKey,
  NarrativeEventBuilderProjectReadModel? readModel,
  VoidCallback? onCreateEvent,
  String? fontFamily,
}) async {
  final appIcon = await tester.runAsync(_loadEventBuilderV2PhaseKAppIcon);
  if (appIcon == null) {
    throw TestFailure('Phase K could not decode the PokeMap app icon.');
  }
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = viewport;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    EventBuilderV2PhaseKVisualHarness(
      viewport: viewport,
      appIcon: appIcon,
      textScaleFactor: textScaleFactor,
      readModel: readModel ?? buildEventBuilderV2PhaseKReadModel(),
      selectedStableKey: selectedStableKey,
      onCreateEvent: onCreateEvent,
      fontFamily: fontFamily,
    ),
  );
  await tester.pumpAndSettle();
}

class EventBuilderV2PhaseKVisualHarness extends StatefulWidget {
  const EventBuilderV2PhaseKVisualHarness({
    super.key,
    required this.viewport,
    required this.appIcon,
    required this.textScaleFactor,
    required this.readModel,
    required this.selectedStableKey,
    this.onCreateEvent,
    this.fontFamily,
  });

  final Size viewport;
  final ui.Image appIcon;
  final double textScaleFactor;
  final NarrativeEventBuilderProjectReadModel readModel;
  final String selectedStableKey;
  final VoidCallback? onCreateEvent;
  final String? fontFamily;

  @override
  State<EventBuilderV2PhaseKVisualHarness> createState() =>
      _EventBuilderV2PhaseKVisualHarnessState();
}

class _EventBuilderV2PhaseKVisualHarnessState
    extends State<EventBuilderV2PhaseKVisualHarness> {
  late NarrativeEventBuilderV2State _state;
  late String _selectedStableKey;

  @override
  void initState() {
    super.initState();
    _state = NarrativeEventBuilderV2State(readModel: widget.readModel);
    _selectedStableKey = widget.selectedStableKey;
  }

  @override
  void didUpdateWidget(covariant EventBuilderV2PhaseKVisualHarness oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.readModel != widget.readModel) {
      _state = NarrativeEventBuilderV2State(readModel: widget.readModel);
    }
    if (oldWidget.selectedStableKey != widget.selectedStableKey) {
      _selectedStableKey = widget.selectedStableKey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseTheme = PokeMapTheme.dark();
    final theme = widget.fontFamily == null
        ? baseTheme
        : baseTheme.copyWith(
            textTheme: baseTheme.textTheme.apply(
              fontFamily: widget.fontFamily,
            ),
            primaryTextTheme: baseTheme.primaryTextTheme.apply(
              fontFamily: widget.fontFamily,
            ),
          );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: TextScaler.linear(widget.textScaleFactor),
          ),
          child: DefaultTextStyle.merge(
            style: TextStyle(fontFamily: widget.fontFamily),
            child: child!,
          ),
        );
      },
      home: Scaffold(
        body: RepaintBoundary(
          key: eventBuilderV2PhaseKCaptureKey,
          child: SizedBox.expand(
            child: _PhaseKReferenceChrome(
              viewport: widget.viewport,
              appIcon: widget.appIcon,
              workspace: Builder(
                builder: (workspaceContext) => EventBuilderV2Workspace(
                  state: _state,
                  mode: EventSystemMode.dualRead,
                  selectedStableKey: _selectedStableKey,
                  viewportWidth: widget.viewport.width,
                  onQueryChanged: (value) {
                    setState(() => _state = _state.withQuery(value));
                  },
                  onFilterChanged: (value) {
                    setState(() => _state = _state.withFilter(value));
                  },
                  onSelectEvent: (event) {
                    setState(() => _selectedStableKey = event.stableKey);
                  },
                  onCreateEvent: widget.onCreateEvent ?? () {},
                  onOpenLibrary: () => _openLibrary(workspaceContext),
                  onChangeSource: () {},
                  onSeeOnMap: () {},
                  onAddCondition: () {},
                  onChangeScene: () {},
                  onOpenScene: () {},
                  onChangeBehavior: () {},
                  onManageEvaluationOrder: () {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openLibrary(BuildContext workspaceContext) {
    showPokeMapDesktopSideSheet<void>(
      context: workspaceContext,
      title: 'Bibliothèque d’éléments',
      semanticLabel: 'Bibliothèque d’éléments de l’événement',
      barrierLabel: 'Fermer la bibliothèque d’éléments',
      barrierDismissible: false,
      width: 420,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(8),
        child: EventBuilderV2ElementLibrary(
          hasLinkedScene: _state.readModel
                  .eventByStableKey(_selectedStableKey)
                  ?.scene
                  .sceneId !=
              null,
          onOpenScene: () {},
        ),
      ),
    );
  }
}

class _PhaseKReferenceChrome extends StatelessWidget {
  const _PhaseKReferenceChrome({
    required this.viewport,
    required this.appIcon,
    required this.workspace,
  });

  final Size viewport;
  final ui.Image appIcon;
  final Widget workspace;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final navigationWidth = _navigationWidth(viewport.width);
    final businessStart = 8 + navigationWidth + 8;
    final rightMargin = viewport.width == 1672 ? 9.0 : 8.0;

    return ColoredBox(
      color: colors.chromeBackground,
      child: Column(
        children: [
          Container(
            key: eventBuilderV2PhaseKHeaderKey,
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: colors.topBarBackground,
              border: Border(bottom: BorderSide(color: colors.divider)),
            ),
            child: Row(
              children: [
                RawImage(
                  image: appIcon,
                  width: 28,
                  height: 28,
                  filterQuality: FilterQuality.medium,
                ),
                const SizedBox(width: 10),
                Text(
                  'PokeMap',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 10),
                const PokeMapBadge(
                  label: 'beta',
                  variant: PokeMapBadgeVariant.info,
                ),
                const Spacer(),
                PokeMapIconButton(
                  onPressed: () {},
                  tooltip: 'Rechercher',
                  icon: const Icon(CupertinoIcons.search),
                ),
                const SizedBox(width: 5),
                PokeMapIconButton(
                  onPressed: () {},
                  tooltip: 'Notifications',
                  icon: const Icon(CupertinoIcons.bell),
                ),
                const SizedBox(width: 5),
                PokeMapIconButton(
                  onPressed: () {},
                  tooltip: 'Réglages',
                  icon: const Icon(CupertinoIcons.gear),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 52,
            child: ColoredBox(
              color: colors.chromeBackground,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: businessStart,
                    child: const Padding(
                      padding: EdgeInsets.fromLTRB(16, 8, 9, 8),
                      child: PokeMapCard(
                        key: eventBuilderV2PhaseKProjectSelectorKey,
                        padding: EdgeInsets.symmetric(horizontal: 7),
                        child: Row(
                          children: [
                            PokeMapIconTile(
                              icon: CupertinoIcons.map,
                              tone: PokeMapTone.map,
                              size: 26,
                              iconSize: 13,
                            ),
                            SizedBox(width: 7),
                            Expanded(
                              child: Text(
                                'Selbrume Demo',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Icon(CupertinoIcons.chevron_down, size: 11),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      key: eventBuilderV2PhaseKContextBarKey,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: colors.topBarBackground,
                        border: Border(
                          bottom: BorderSide(color: colors.divider),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            CupertinoIcons.house,
                            size: 14,
                            color: colors.textMuted,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Narrative Studio  /  Event Builder',
                            style: TextStyle(
                              color: colors.brandPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          if (viewport.width >= 1480) ...[
                            PokeMapButton(
                              onPressed: () {},
                              size: PokeMapButtonSize.small,
                              variant: PokeMapButtonVariant.success,
                              leading: const Icon(CupertinoIcons.add),
                              child: const Text('Nouvel événement'),
                            ),
                            const SizedBox(width: 8),
                          ],
                          PokeMapButton(
                            onPressed: () {},
                            size: PokeMapButtonSize.small,
                            variant: PokeMapButtonVariant.secondary,
                            leading: const Icon(CupertinoIcons.eye),
                            child: const Text('Aperçu'),
                          ),
                          const SizedBox(width: 8),
                          PokeMapButton(
                            onPressed: () {},
                            size: PokeMapButtonSize.small,
                            variant: PokeMapButtonVariant.success,
                            leading:
                                const Icon(CupertinoIcons.checkmark_shield),
                            child: const Text('Valider'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                left: 8,
                right: rightMargin,
                bottom: 22,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    key: eventBuilderV2PhaseKNavigationKey,
                    width: navigationWidth,
                    child: const _PhaseKNavigationPanel(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      key: eventBuilderV2PhaseKWorkspaceFrameKey,
                      child: workspace,
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
}

class _PhaseKNavigationPanel extends StatelessWidget {
  const _PhaseKNavigationPanel();

  @override
  Widget build(BuildContext context) {
    return const PokeMapPanel(
      expandChild: true,
      padding: EdgeInsets.all(8),
      child: Column(
        children: [
          _PhaseKNavigationItem(
            icon: CupertinoIcons.house,
            label: 'Aperçu',
          ),
          _PhaseKNavigationItem(
            icon: CupertinoIcons.rectangle_grid_1x2,
            label: 'Storylines',
          ),
          _PhaseKNavigationItem(
            icon: CupertinoIcons.map,
            label: 'Maps',
          ),
          _PhaseKNavigationItem(
            icon: CupertinoIcons.photo,
            label: 'Scenes',
          ),
          _PhaseKNavigationItem(
            icon: CupertinoIcons.bolt_horizontal_circle,
            label: 'Événements',
            selected: true,
          ),
          _PhaseKNavigationItem(
            icon: CupertinoIcons.film,
            label: 'Cinématiques',
          ),
          _PhaseKNavigationItem(
            icon: CupertinoIcons.text_bubble,
            label: 'Dialogues',
          ),
          _PhaseKNavigationItem(
            icon: CupertinoIcons.doc_text,
            label: 'Facts',
          ),
          _PhaseKNavigationItem(
            icon: CupertinoIcons.checkmark_shield,
            label: 'World Rules',
          ),
          _PhaseKNavigationItem(
            icon: CupertinoIcons.shield,
            label: 'Validateur',
            trailing: PokeMapBadge(
              label: '3',
              variant: PokeMapBadgeVariant.success,
            ),
          ),
          Spacer(),
          PokeMapCard(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            child: Row(
              children: [
                Icon(CupertinoIcons.chart_bar, size: 12),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Project Health',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700),
                  ),
                ),
                PokeMapStatusLabel(
                  label: 'Bon',
                  tone: PokeMapTone.success,
                  icon: CupertinoIcons.circle_fill,
                ),
              ],
            ),
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Icon(
                CupertinoIcons.circle_fill,
                size: 7,
              ),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Tous les changements enregistrés',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PhaseKNavigationItem extends StatelessWidget {
  const _PhaseKNavigationItem({
    required this.icon,
    required this.label,
    this.selected = false,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: PokeMapSidebarItem(
        icon: Icon(icon),
        label: label,
        compact: true,
        trailing: trailing,
        selected: selected,
        onTap: () {},
      ),
    );
  }
}

double _navigationWidth(double viewportWidth) {
  if (viewportWidth >= 1672) return 191;
  if (viewportWidth >= 1480) return 176;
  return 168;
}

NarrativeEventBuilderProjectReadModel buildEventBuilderV2PhaseKReadModel() {
  final richProjection = NarrativeEventProjectionSummary(
    outcomeLabels: const ['Victoire', 'Défaite', 'Échec'],
    consequences: [
      NarrativeEventProjectedConsequenceSummary(
        kind: SceneConsequenceKind.setFact,
        humanLabel: 'Rival battu = vrai',
        debugReference: 'fact:rival_defeated',
      ),
      NarrativeEventProjectedConsequenceSummary(
        kind: SceneConsequenceKind.markEventConsumed,
        humanLabel: 'Rencontre du port terminée',
        debugReference: 'event:rival',
      ),
    ],
    worldRules: [
      NarrativeEventProjectedWorldRuleSummary(
        ruleId: 'world_rule:guardian_gone',
        humanLabel: 'Le gardien a disparu',
        enabled: true,
      ),
    ],
    readOnly: true,
  );

  return NarrativeEventBuilderProjectReadModel(
    groups: [
      NarrativeEventProjectGroup(
        stableKey: 'group:map:port',
        label: 'Port Selbrume',
        kind: NarrativeEventProjectGroupKind.map,
        events: [
          _phaseKSummary(
            stableKey: eventBuilderV2PhaseKSelectedStableKey,
            title: 'Rencontre rival au port',
            group: NarrativeEventProjectGroupKind.map,
            groupKey: 'map:port',
            groupLabel: 'Port Selbrume',
            status: NarrativeEventProjectStatus.configuredEnabledReady,
            enabled: true,
            source: NarrativeEventSourceRef.entityInteract(
              'map_port_selbrume',
              'entity_rival',
            ),
            sourceTypeLabel: 'Interaction avec un personnage',
            sourceSentence: 'Quand le joueur parle au Rival, au Port Selbrume.',
            mapId: 'map_port_selbrume',
            mapLabel: 'Port Selbrume',
            sceneId: 'scene_rival_meeting',
            sceneLabel: 'Rencontre rival',
            conditionsCount: 2,
            conditionsLabel: 'Étape « Aller au port » et rival non battu',
            conditionDetails: [
              NarrativeEventConditionDetailSummary(
                kind: NarrativeEventConditionDetailKind.fact,
                targetLabel: 'Étape active',
                expectedValue: true,
                humanLabel: 'Étape active : Aller au port',
                resolved: true,
              ),
              NarrativeEventConditionDetailSummary(
                kind: NarrativeEventConditionDetailKind.narrativeEventConsumed,
                targetLabel: 'Rival battu',
                expectedValue: false,
                humanLabel: 'Rival battu : faux',
                resolved: true,
              ),
            ],
            lifecycleLabel: 'Une seule fois · actif',
            priority: 10,
            order: 0,
            activeCandidateCount: 2,
            projection: richProjection,
            diagnostics: [
              NarrativeEventProjectReadDiagnostic(
                code: 'evaluation-order-information',
                severity: NarrativeEventProjectSummarySeverity.info,
                message:
                    'Le prochain événement éligible peut être évalué ensuite.',
              ),
            ],
          ),
          _phaseKSummary(
            stableKey: 'event:fisherman',
            title: 'Pêcheur en détresse',
            group: NarrativeEventProjectGroupKind.map,
            groupKey: 'map:port',
            groupLabel: 'Port Selbrume',
            status: NarrativeEventProjectStatus.configuredEnabledReady,
            enabled: true,
            source: NarrativeEventSourceRef.entityInteract(
              'map_port_selbrume',
              'entity_fisherman',
            ),
            sourceTypeLabel: 'Interaction avec un personnage',
            sourceSentence: 'Quand le joueur parle au pêcheur sur le quai.',
            mapId: 'map_port_selbrume',
            mapLabel: 'Port Selbrume',
          ),
          _phaseKSummary(
            stableKey: 'event:abandoned-chest',
            title: 'Coffre abandonné',
            group: NarrativeEventProjectGroupKind.map,
            groupKey: 'map:port',
            groupLabel: 'Port Selbrume',
            status: NarrativeEventProjectStatus.configuredDisabledReady,
            enabled: false,
            source: NarrativeEventSourceRef.entityInteract(
              'map_port_selbrume',
              'entity_abandoned_chest',
            ),
            sourceTypeLabel: 'Interaction avec un objet',
            sourceSentence: 'Quand le joueur examine le coffre abandonné.',
            mapId: 'map_port_selbrume',
            mapLabel: 'Port Selbrume',
          ),
          _phaseKSummary(
            stableKey: 'event:sleeping-guard',
            title: 'Garde somnolent',
            group: NarrativeEventProjectGroupKind.map,
            groupKey: 'map:port',
            groupLabel: 'Port Selbrume',
            status: NarrativeEventProjectStatus.attentionRequired,
            enabled: false,
            source: NarrativeEventSourceRef.triggerEnter(
              'map_port_selbrume',
              'trigger_guard_post',
            ),
            sourceTypeLabel: 'Entrée dans une zone',
            sourceSentence: 'Quand le joueur approche du poste de garde.',
            mapId: 'map_port_selbrume',
            mapLabel: 'Port Selbrume',
          ),
          _phaseKSummary(
            stableKey: 'event:tavern-rumor',
            title: 'Rumeur au comptoir',
            group: NarrativeEventProjectGroupKind.map,
            groupKey: 'map:port',
            groupLabel: 'Port Selbrume',
            status: NarrativeEventProjectStatus.configuredEnabledReady,
            enabled: true,
            source: NarrativeEventSourceRef.entityInteract(
              'map_port_selbrume',
              'entity_bartender',
            ),
            sourceTypeLabel: 'Interaction avec un personnage',
            sourceSentence: 'Quand le joueur parle au tavernier.',
            mapId: 'map_port_selbrume',
            mapLabel: 'Port Selbrume',
          ),
        ],
      ),
      NarrativeEventProjectGroup(
        stableKey: 'group:map:forest',
        label: 'Forêt Brumeuse',
        kind: NarrativeEventProjectGroupKind.map,
        events: [
          _mapEvent('injured-creature', 'Créature blessée', 'Forêt Brumeuse'),
          _mapEvent('medicinal-herbs', 'Herbes médicinales', 'Forêt Brumeuse'),
          _mapEvent('team-ambush', 'Embuscade de la Team', 'Forêt Brumeuse'),
          _mapEvent('forest-spirit', 'Esprit de la forêt', 'Forêt Brumeuse'),
        ],
      ),
      NarrativeEventProjectGroup(
        stableKey: 'group:map:cave',
        label: 'Grotte Marine',
        kind: NarrativeEventProjectGroupKind.map,
        events: [
          _mapEvent(
              'ancient-inscription', 'Ancienne inscription', 'Grotte Marine'),
          _mapEvent('fragile-rock', 'Roche friable', 'Grotte Marine'),
          _mapEvent('mysterious-echo', 'Écho mystérieux', 'Grotte Marine'),
        ],
      ),
      NarrativeEventProjectGroup(
        stableKey: 'group:outcomes',
        label: 'Événements globaux',
        kind: NarrativeEventProjectGroupKind.outcomes,
        events: [
          _phaseKSummary(
            stableKey: 'event:league-qualified',
            title: 'Qualification pour la ligue',
            group: NarrativeEventProjectGroupKind.outcomes,
            groupKey: 'outcomes',
            groupLabel: 'Événements globaux',
            status: NarrativeEventProjectStatus.configuredEnabledReady,
            enabled: true,
            source: NarrativeEventSourceRef.outcomeReceived(
              NarrativeOutcomeRef(
                producerKind: NarrativeOutcomeProducerKind.battle,
                producerId: 'battle_port_champion',
                outcomeId: 'victory',
              ),
            ),
            sourceTypeLabel: 'Résultat reçu',
            sourceSentence: 'Quand la victoire du champion est reçue.',
          ),
          _phaseKSummary(
            stableKey: 'event:chapter-complete',
            title: 'Chapitre du port terminé',
            group: NarrativeEventProjectGroupKind.outcomes,
            groupKey: 'outcomes',
            groupLabel: 'Événements globaux',
            status: NarrativeEventProjectStatus.configuredDisabledReady,
            enabled: false,
            source: NarrativeEventSourceRef.outcomeReceived(
              NarrativeOutcomeRef(
                producerKind: NarrativeOutcomeProducerKind.scene,
                producerId: 'scene_port_departure',
                outcomeId: 'chapter_complete',
              ),
            ),
            sourceTypeLabel: 'Résultat reçu',
            sourceSentence: 'Quand le chapitre du port est terminé.',
          ),
        ],
      ),
      NarrativeEventProjectGroup(
        stableKey: 'group:drafts',
        label: 'Brouillons à terminer',
        kind: NarrativeEventProjectGroupKind.drafts,
        events: [
          _phaseKSummary(
            stableKey: 'event:draft-market',
            title: 'Marché nocturne à configurer',
            group: NarrativeEventProjectGroupKind.drafts,
            groupKey: 'drafts',
            groupLabel: 'Brouillons à terminer',
            status: NarrativeEventProjectStatus.draftIncomplete,
            enabled: null,
            sourceTypeLabel: 'Élément déclencheur',
            sourceSentence: 'Aucun élément déclencheur choisi.',
            sceneId: null,
            sceneLabel: 'Aucune Scene choisie',
            lifecycleLabel: 'Comportement à décider',
          ),
          _phaseKSummary(
            stableKey: 'event:draft-lighthouse',
            title: 'Lumière du phare après la tempête',
            group: NarrativeEventProjectGroupKind.drafts,
            groupKey: 'drafts',
            groupLabel: 'Brouillons à terminer',
            status: NarrativeEventProjectStatus.draftIncomplete,
            enabled: null,
            source: NarrativeEventSourceRef.mapEnter('map_lighthouse'),
            sourceTypeLabel: 'Entrée sur une map',
            sourceSentence: 'Quand le joueur arrive au phare.',
            mapId: 'map_lighthouse',
            mapLabel: 'Phare de Selbrume',
            sceneId: null,
            sceneLabel: 'Aucune Scene choisie',
          ),
        ],
      ),
      NarrativeEventProjectGroup(
        stableKey: 'group:missing',
        label: 'Références à réparer',
        kind: NarrativeEventProjectGroupKind.missingReferences,
        events: [
          _phaseKSummary(
            stableKey: eventBuilderV2PhaseKBrokenSourceStableKey,
            title: 'Lanterne du vieux quai',
            group: NarrativeEventProjectGroupKind.missingReferences,
            groupKey: 'missing',
            groupLabel: 'Références à réparer',
            status: NarrativeEventProjectStatus.sourceMissing,
            enabled: false,
            source: NarrativeEventSourceRef.entityInteract(
              'map_port_selbrume',
              'entity_missing_lantern',
            ),
            sourceTypeLabel: 'Interaction avec un objet',
            sourceSentence: 'L’élément déclencheur n’existe plus sur la map.',
            mapId: 'map_port_selbrume',
            mapLabel: 'Port Selbrume',
            sourceAvailable: false,
            diagnostics: [
              NarrativeEventProjectReadDiagnostic(
                code: 'source-missing',
                severity: NarrativeEventProjectSummarySeverity.error,
                message:
                    'Choisissez un autre élément ou détachez la référence.',
              ),
            ],
          ),
          _phaseKSummary(
            stableKey: 'event:unsupported-source',
            title: 'Signal ancien non pris en charge',
            group: NarrativeEventProjectGroupKind.missingReferences,
            groupKey: 'missing',
            groupLabel: 'Références à réparer',
            status: NarrativeEventProjectStatus.unsupported,
            enabled: false,
            sourceTypeLabel: 'Format non pris en charge',
            sourceSentence:
                'Cet élément déclencheur doit être remplacé avant activation.',
            sourceAvailable: false,
          ),
        ],
      ),
      NarrativeEventProjectGroup(
        stableKey: 'group:legacy',
        label: 'Ancien format à convertir',
        kind: NarrativeEventProjectGroupKind.legacyCompatibility,
        events: [
          _phaseKSummary(
            stableKey: 'legacy:messenger',
            title: 'Messager existant',
            group: NarrativeEventProjectGroupKind.legacyCompatibility,
            groupKey: 'legacy',
            groupLabel: 'Ancien format à convertir',
            status: NarrativeEventProjectStatus.legacyOnly,
            enabled: null,
            origin: NarrativeEventProjectOrigin.legacyMapEvent,
            readOnly: true,
            sourceTypeLabel: 'Déclencheur existant',
            sourceSentence: 'Événement existant en lecture seule.',
          ),
          _phaseKSummary(
            stableKey: 'legacy:storm-scenario',
            title: 'Ancien scénario de tempête',
            group: NarrativeEventProjectGroupKind.legacyCompatibility,
            groupKey: 'legacy',
            groupLabel: 'Ancien format à convertir',
            status: NarrativeEventProjectStatus.migrationAssistanceRequired,
            enabled: null,
            origin: NarrativeEventProjectOrigin.legacyScenario,
            readOnly: true,
            sourceTypeLabel: 'Ancien scénario',
            sourceSentence: 'Conversion guidée nécessaire.',
          ),
        ],
      ),
    ],
    diagnostics: [
      NarrativeEventProjectReadDiagnostic(
        code: 'fixture-stable',
        severity: NarrativeEventProjectSummarySeverity.info,
        message: 'Fixture visuelle Phase K déterministe.',
      ),
    ],
  );
}

NarrativeEventProjectSummary _mapEvent(
  String slug,
  String title,
  String mapLabel,
) {
  final mapSlug = mapLabel == 'Forêt Brumeuse' ? 'forest' : 'cave';
  return _phaseKSummary(
    stableKey: 'event:$slug',
    title: title,
    group: NarrativeEventProjectGroupKind.map,
    groupKey: 'map:$mapSlug',
    groupLabel: mapLabel,
    status: NarrativeEventProjectStatus.configuredEnabledReady,
    enabled: true,
    source: NarrativeEventSourceRef.triggerEnter(
      'map_$mapSlug',
      'trigger_$slug',
    ),
    sourceTypeLabel: 'Entrée dans une zone',
    sourceSentence: 'Quand le joueur entre dans la zone « $title ».',
    mapId: 'map_$mapSlug',
    mapLabel: mapLabel,
  );
}

NarrativeEventProjectSummary _phaseKSummary({
  required String stableKey,
  required String title,
  required NarrativeEventProjectGroupKind group,
  required String groupKey,
  required String groupLabel,
  required NarrativeEventProjectStatus status,
  required bool? enabled,
  required String sourceTypeLabel,
  required String sourceSentence,
  NarrativeEventSourceRef? source,
  String? mapId,
  String? mapLabel,
  bool sourceAvailable = true,
  String? sceneId = 'scene_default',
  String sceneLabel = 'Scene liée',
  int conditionsCount = 0,
  String conditionsLabel = 'Aucune condition',
  List<NarrativeEventConditionDetailSummary> conditionDetails = const [],
  String lifecycleLabel = 'À chaque fois',
  int? priority,
  int? order,
  int activeCandidateCount = 0,
  NarrativeEventProjectionSummary? projection,
  List<NarrativeEventProjectReadDiagnostic> diagnostics = const [],
  NarrativeEventProjectOrigin origin = NarrativeEventProjectOrigin.v2,
  bool readOnly = false,
}) {
  return NarrativeEventProjectSummary(
    stableKey: stableKey,
    eventId: origin == NarrativeEventProjectOrigin.v2
        ? stableKey.replaceFirst('event:', 'evt_')
        : null,
    title: title,
    origin: origin,
    readOnly: readOnly,
    enabled: enabled,
    group: group,
    groupKey: groupKey,
    groupLabel: groupLabel,
    status: status,
    severity: diagnostics.any(
      (diagnostic) =>
          diagnostic.severity == NarrativeEventProjectSummarySeverity.error,
    )
        ? NarrativeEventProjectSummarySeverity.error
        : diagnostics.isEmpty
            ? NarrativeEventProjectSummarySeverity.info
            : NarrativeEventProjectSummarySeverity.warning,
    source: NarrativeEventSourceSummary(
      source: source,
      humanSentence: sourceSentence,
      sourceTypeLabel: sourceTypeLabel,
      mapId: mapId,
      mapLabel: mapLabel,
      available: sourceAvailable,
      debugTechnicalLabel: 'fixture:$stableKey',
    ),
    scene: NarrativeEventSceneSummary(
      sceneId: sceneId,
      humanLabel: sceneLabel,
      valid: sceneId != null,
    ),
    conditions: NarrativeEventConditionsSummary(
      count: conditionsCount,
      valid: true,
      unresolvedCount: 0,
      humanLabel: conditionsLabel,
      details: conditionDetails,
    ),
    lifecycle: NarrativeEventLifecycleSummary(
      reusePolicy: status == NarrativeEventProjectStatus.draftIncomplete
          ? null
          : NarrativeEventReusePolicy.oneShot,
      enabled: enabled,
      humanLabel: lifecycleLabel,
      priority: priority,
      order: order,
      activeCandidateCount: activeCandidateCount,
    ),
    migration: NarrativeEventMigrationSummary(
      humanLabel: readOnly ? 'Ancien format à convertir' : 'Format V2',
    ),
    projection: projection ??
        NarrativeEventProjectionSummary(
          outcomeLabels: const [],
          consequences: const [],
          worldRules: const [],
          readOnly: true,
        ),
    compatibilityOrigins: const [],
    diagnostics: diagnostics,
    debug: NarrativeEventProjectDebugFields(
      eventId: origin == NarrativeEventProjectOrigin.v2
          ? stableKey.replaceFirst('event:', 'evt_')
          : null,
      sourceTechnicalLabel: source == null ? null : 'fixture-source',
      sceneId: sceneId,
      provenanceTechnicalLabels: const [],
      targetEventIds: const [],
    ),
  );
}
