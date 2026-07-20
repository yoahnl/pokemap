import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/theme/pokemap_theme.dart';
import 'package:map_editor/src/ui/canvas/cinematics/builder/cinematic_stage_panel.dart';

void main() {
  testWidgets('stage renders dialogue, shake and FX from playback cues', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: SizedBox(
          width: 800,
          height: 500,
          child: CinematicStagePanel(
            cinematic: CinematicAsset(
              id: 'cine.selbrume.port',
              title: 'Arrivée à Selbrume',
              timeline: CinematicTimeline(),
            ),
            playbackTimeMs: 1125,
            activeCues: const [
              CinematicPlaybackCue(
                stepId: 'dialogue',
                stepIndex: 0,
                kind: CinematicPlaybackCueKind.dialogue,
                startMs: 1000,
                endMs: 1500,
                referenceId: 'dialogue.port',
                referenceLabel: 'Rencontre au port',
                dialogueText: 'La brume se lève sur le port.',
              ),
              CinematicPlaybackCue(
                stepId: 'shake',
                stepIndex: 1,
                kind: CinematicPlaybackCueKind.shake,
                startMs: 1000,
                endMs: 1500,
                intensity: 0.7,
              ),
              CinematicPlaybackCue(
                stepId: 'fx',
                stepIndex: 2,
                kind: CinematicPlaybackCueKind.fx,
                startMs: 1000,
                endMs: 1500,
                referenceId: 'fx.fog',
                referenceLabel: 'Brume montante',
                channel: 'atmosphere',
              ),
            ],
            child: const ColoredBox(
              key: ValueKey('preview-stage-child'),
              color: Colors.transparent,
            ),
          ),
        ),
      ),
    );

    expect(find.text('La brume se lève sur le port.'), findsOneWidget);
    expect(find.text('Secousse'), findsOneWidget);
    expect(find.text('FX · Brume montante'), findsOneWidget);
    expect(find.textContaining('marker'), findsNothing);

    final transform = tester.widget<Transform>(
      find.byKey(const ValueKey('cinematic-stage-playback-transform')),
    );
    expect(transform.transform.getTranslation().x, isNot(0));
  });
}
