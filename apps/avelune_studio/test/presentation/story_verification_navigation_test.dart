import 'package:avelune_studio/features/dialogues/domain/dialogue_catalog_port.dart';
import 'package:avelune_studio/features/events/domain/event_record_view.dart';
import 'package:avelune_studio/features/game_memory/domain/narrative_index_port.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../dialogues/dialogue_catalog_support.dart';
import '../support/map_workspace_fixture.dart';
import '../verification/verification_fakes.dart';
import 'story_interactions_support.dart';
import 'story_memory_harness.dart';

final class _ScopedWorkspace extends WorkspaceMemoryPort
    implements MapWorkspaceWorkshopPort {
  _ScopedWorkspace(ProjectManifest manifest) : super(manifest: manifest);

  final workshops = <MapWorkspaceWorkshop>[];

  @override
  Future<MapWorkspaceCatalog> loadCatalog(ProjectSession session) async =>
      MapWorkspaceCatalog(metadata: manifest, revision: 'r0');

  @override
  Future<MapWorkspaceSelection> loadMapSelection(
    ProjectSession session,
    ProjectMapEntry entry,
  ) async => MapWorkspaceSelection(
    document: await loadMap(session, entry),
    definitions: manifest,
    catalogRevision: 'r0',
    snapshotRevision: 'r0',
  );

  @override
  Future<ProjectManifest> materializeProject(ProjectSession session) async =>
      manifest;

  @override
  Future<MapWorkspaceCatalog> loadWorkshop(
    ProjectSession session,
    MapWorkspaceWorkshop workshop,
  ) {
    workshops.add(workshop);
    return loadCatalog(session);
  }
}

Future<void> _tap(WidgetTester tester, String key) async {
  final target = interactionKey(key);
  await tester.ensureVisible(target);
  await tester.tap(target);
  await settleMemory(tester);
}

void main() {
  testWidgets(
    'opens the precise trigger and world rule on B and returns to the report with A active',
    (tester) async {
      final rule = WorldRuleDefinition(
        id: 'gate',
        label: 'Porte de B',
        enabled: false,
        source: const WorldRuleSource(
          kind: WorldRuleSourceKind.fact,
          sourceId: 'met',
          predicate: WorldRuleSourcePredicate.isTrue,
        ),
        target: const WorldRuleTarget(
          kind: WorldRuleTargetKind.mapEntity,
          mapId: 'b',
          entityId: 'mother',
        ),
        effect: const WorldRuleEffect(kind: WorldRuleEffectKind.entityHidden),
      );
      final verification = FakeVerificationPort(
        diagnostics: [
          verificationDiagnostic(
            'trigger',
            NarrativeProjectDiagnosticDestination.event,
            eventId: motherTalk,
            mapId: 'b',
          ),
          verificationDiagnostic(
            'rule',
            NarrativeProjectDiagnosticDestination.worldRule,
            severity: NarrativeProjectDiagnosticSeverity.warning,
            worldRuleId: rule.id,
            mapId: 'b',
          ),
          verificationDiagnostic(
            'moved',
            NarrativeProjectDiagnosticDestination.event,
            eventId: motherTalk,
            mapId: 'a',
            severity: NarrativeProjectDiagnosticSeverity.info,
          ),
        ],
      );
      final first = interactionRecord(
        guideTalk,
        'a',
        'guide',
        'Parler au guide',
      );
      final second = interactionRecord(
        motherTalk,
        'b',
        'mother',
        'Parler à Maman',
      );
      final index = memoryIndex()
        ..titlesByKind[NarrativeTitleKind.events] = [
          NarrativeTitle(id: first.id, title: first.name),
          NarrativeTitle(id: second.id, title: second.name),
        ]
        ..rules = [rule];
      final workspace = await openMemoryStudio(
        tester,
        index,
        verification: verification,
        world: MapOnlyWorld.new,
        workspace: _ScopedWorkspace.new,
        project: memoryProject.copyWith(
          maps: workspaceEntries,
          worldRules: [rule],
          eventRegistry: NarrativeEventRegistry(
            schemaVersion: 1,
            mode: EventSystemMode.v2Only,
            records: [first, second],
            legacyClaims: const [],
          ),
        ),
        initialMaps: {
          'b': workspaceMap('b').copyWith(
            entities: const [
              MapEntity(
                id: 'mother',
                name: 'Maman',
                kind: MapEntityKind.npc,
                pos: GridPos(x: 4, y: 4),
              ),
            ],
          ),
        },
      );
      await openTrame(tester);
      await _tap(tester, 'story-section-verification');
      await _tap(tester, 'verification-start');
      final active = interactionMaps(tester).active;
      expect(active!.base.mapId, 'a');
      expect(find.textContaining('À compléter'), findsWidgets);
      expect(find.textContaining('Désactivé'), findsOneWidget);
      final scoped = workspace as _ScopedWorkspace;
      expect(scoped.workshops, isNot(contains(MapWorkspaceWorkshop.events)));

      await _tap(tester, 'verification-open-0');
      expect(scoped.workshops, contains(MapWorkspaceWorkshop.events));
      expect(interactionFilter(tester).value, 'b');
      expect(
        interactionKey('map-story-behaviour-name-$motherTalk'),
        findsOneWidget,
      );
      expect(interactionMaps(tester).active, same(active));
      await _tap(tester, 'story-return');

      await _tap(tester, 'verification-open-1');
      expect(interactionKey('memory-rule-name-${rule.id}'), findsOneWidget);
      expect(interactionMaps(tester).active, same(active));
      await _tap(tester, 'story-return');

      await _tap(tester, 'verification-open-2');
      expect(
        interactionKey('verification-destination-unavailable'),
        findsOneWidget,
      );
      expect(interactionMaps(tester).active, same(active));
      expect(verification.analyses, 1);
    },
  );

  testWidgets(
    'opens the shared localized document by identity and reports its removal',
    (tester) async {
      final dialogue = catalogDialogue('letter');
      final index = memoryIndex()
        ..titlesByKind[NarrativeTitleKind.dialogues] = [
          NarrativeTitle(id: dialogue.id, title: dialogue.entry.name),
        ];
      final catalog = FakeDialogueCatalog()
        ..documents[dialogue.id] = DialogueCatalogDocument(
          dialogue: dialogue,
          sceneIds: const ['first', 'second'],
          notCovered: const [],
        );
      final port = FakeVerificationPort(
        diagnostics: [
          verificationDiagnostic(
            'letter',
            NarrativeProjectDiagnosticDestination.dialogue,
            dialogueId: dialogue.id,
          ),
        ],
      );
      await openMemoryStudio(
        tester,
        index,
        project: memoryProject.copyWith(dialogues: [dialogue.entry]),
        dialogueCatalog: catalog,
        loadDialogue: (id) async => catalog.documents[id]!.dialogue,
        verification: port,
      );
      await openTrame(tester);
      await _tap(tester, 'story-section-verification');
      await _tap(tester, 'verification-start');
      expect(find.textContaining('Contrôle du Yarn source'), findsOneWidget);

      await _tap(tester, 'verification-open-0');
      expect(find.text(dialogue.entry.name), findsWidgets);
      expect(
        find.byKey(ValueKey('dialogue-document-${dialogue.id}')),
        findsOneWidget,
      );
      expect(catalog.requests, everyElement(dialogue.id));
      await _tap(tester, 'story-return');

      catalog.documents.remove(dialogue.id);
      await _tap(tester, 'verification-open-0');
      expect(
        interactionKey('verification-destination-unavailable'),
        findsOneWidget,
      );
      expect(port.analyses, 1);
    },
  );
}
