import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProjectManifest project;

  setUpAll(() async {
    project = await _readAcceptanceProject();
    final fontBytes = await _fixtureFile(
      'assets/presentation/fonts/display.ttf',
    ).readAsBytes();
    await (FontLoader('Aube Display')
          ..addFont(
            Future<ByteData>.value(ByteData.sublistView(fontBytes)),
          ))
        .load();
  });

  testWidgets('player renders the validated V3 acceptance project', (
    tester,
  ) async {
    expect(() => ProjectValidator.validate(project), returnsNormally);
    final profile = project.presentation!;
    final presentation = RuntimePlayerPresentation.fromProfile(profile);

    await tester.binding.setSurfaceSize(const Size(960, 540));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: presentation.applyTo(PokeMapPlayerTheme.light()),
        home: PlayerTitleSurface(
          data: PlayerTitleSurfaceData(
            gameTitle: project.name,
            author: 'PokeMap',
            description: 'Projet d’acceptation visuelle',
            layoutVariant: presentation.title.layoutVariant,
            accentColor: presentation.title.accentColor,
            actions: <PlayerTitleMenuAction, PlayerActionAvailability>{
              for (final action in PlayerTitleMenuAction.values)
                action: PlayerActionAvailability.enabled,
            },
          ),
          onSelected: (_) {},
        ),
      ),
    );
    await tester.pump();

    expect(find.text('L’Aube de Vermeil'), findsOneWidget);
    expect(
      tester.widget<Text>(find.text('L’Aube de Vermeil')).style?.fontFamily,
      'Aube Display',
    );
    expect(
      presentation.pausePresentation.actionLabels[PlayerPauseAction.pokedex],
      'Carnet de route',
    );
    expect(
      presentation.windowProfile
          ?.resolve(ProjectWindowRole.dialogue)
          .cornerRadius,
      8,
    );
    expect(
      presentation.battleProfile?.commandLayout,
      ProjectBattleCommandLayout.radial,
    );
    expect(
      presentation.battleProfile?.effectiveCommands.first.id,
      ProjectBattleCommandId.run,
    );
    expect(
      presentation.battleProfile?.message.shape,
      ProjectWindowShape.cutCorner,
    );
    expect(tester.takeException(), isNull);
  });
}

Future<ProjectManifest> _readAcceptanceProject() async {
  final decoded = jsonDecode(await _fixtureFile('project.json').readAsString())
      as Map<String, dynamic>;
  return ProjectManifest.fromJson(decoded);
}

File _fixtureFile(String relativePath) => File(
      '${Directory.current.path}/../../examples/playable_runtime_host/'
      'golden_personalization_v3/$relativePath',
    );
