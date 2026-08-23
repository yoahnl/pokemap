import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/ui/panels/gameplay_zone_properties_panel.dart';
import 'package:map_editor/src/ui/shared/pokemap_macos_ui_shim.dart';

// BETA-BAT-015, avenant Encounter Studio : une zone de rencontre porte ses
// musiques de combat et de rencontre, et le panneau doit les préserver à la
// sauvegarde. Le point qui craint : `_save` reconstruit le payload champ par
// champ — un champ oublié serait EFFACÉ silencieusement à chaque save.

const _zone = MapGameplayZone(
  id: 'grass_zone',
  kind: GameplayZoneKind.encounter,
  area: MapRect(
    pos: GridPos(x: 1, y: 1),
    size: GridSize(width: 3, height: 3),
  ),
  encounter: EncounterZonePayload(
    encounterTableId: 'grass_table',
    battleBackgroundRelativePath: 'assets/battle_backgrounds/grass.png',
    battleMusicPath: 'assets/audio/music/zone_battle.ogg',
    encounterMusicPath: 'assets/audio/music/zone_spotted.ogg',
  ),
);

EditorState _stateWithZone() {
  return const EditorState(
    projectRootPath: '/tmp/zone_music_panel_test',
    project: ProjectManifest(
      name: 'zone_music_panel_test',
      maps: <ProjectMapEntry>[
        ProjectMapEntry(
          id: 'field_map',
          name: 'Field Map',
          relativePath: 'maps/field_map.json',
        ),
      ],
      tilesets: <ProjectTilesetEntry>[],
      battleAudio: ProjectBattleAudioConfig(
        wildBattleMusicPath: 'assets/audio/music/wild.ogg',
        encounterMusicPath: 'assets/audio/music/spotted.ogg',
      ),
    ),
    activeMap: MapData(
      id: 'field_map',
      name: 'Field Map',
      size: GridSize(width: 10, height: 10),
      gameplayZones: <MapGameplayZone>[_zone],
    ),
    selectedGameplayZoneId: 'grass_zone',
  );
}

Future<void> _pumpPanel(WidgetTester tester, ProviderContainer container) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1400, 2400);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MacosTheme(
        data: MacosThemeData.light(),
        child: MaterialApp(
          home: Material(
            child: CupertinoPageScaffold(
              child: SizedBox(
                width: 1280,
                height: 2200,
                child: GameplayZonePropertiesPanel(),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  testWidgets('affiche les musiques de la zone et les préserve au save',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = _stateWithZone();

    await _pumpPanel(tester, container);

    expect(
      find.text('assets/audio/music/zone_battle.ogg'),
      findsOneWidget,
    );
    expect(
      find.text('assets/audio/music/zone_spotted.ogg'),
      findsOneWidget,
    );

    await tester.ensureVisible(find.text('Save Zone'));
    await tester.tap(find.text('Save Zone'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final saved = container
        .read(editorNotifierProvider)
        .activeMap!
        .gameplayZones
        .single
        .encounter!;
    expect(saved.battleMusicPath, 'assets/audio/music/zone_battle.ogg');
    expect(saved.encounterMusicPath, 'assets/audio/music/zone_spotted.ogg');
    expect(
      saved.battleBackgroundRelativePath,
      'assets/battle_backgrounds/grass.png',
      reason: 'le save ne doit effacer aucun champ voisin',
    );
  });

  testWidgets('zone sans musique : le panneau montre le défaut effectif',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final base = _stateWithZone();
    container.read(editorNotifierProvider.notifier).state = base.copyWith(
      activeMap: base.activeMap!.copyWith(
        gameplayZones: <MapGameplayZone>[
          _zone.copyWith(
            encounter: const EncounterZonePayload(
              encounterTableId: 'grass_table',
            ),
          ),
        ],
      ),
    );

    await _pumpPanel(tester, container);

    expect(find.text('Default: wild.ogg (project, wild)'), findsOneWidget);
    expect(find.text('Default: spotted.ogg (project)'), findsOneWidget);
  });

  testWidgets('le clear efface la musique de la zone au save', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = _stateWithZone();

    await _pumpPanel(tester, container);

    await tester.ensureVisible(
      find.byKey(const Key('gameplay-zone-battle-music-clear')),
    );
    await tester.tap(
      find.byKey(const Key('gameplay-zone-battle-music-clear')),
    );
    await tester.pump();
    await tester.ensureVisible(find.text('Save Zone'));
    await tester.tap(find.text('Save Zone'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final saved = container
        .read(editorNotifierProvider)
        .activeMap!
        .gameplayZones
        .single
        .encounter!;
    expect(saved.battleMusicPath, isNull);
    expect(
      saved.encounterMusicPath,
      'assets/audio/music/zone_spotted.ogg',
      reason: 'le clear d’un champ ne touche pas l’autre',
    );
  });
}
