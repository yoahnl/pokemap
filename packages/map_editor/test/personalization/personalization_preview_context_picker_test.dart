import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/personalization_hub.dart';
import 'package:map_editor/src/features/personalization/presentation/personalization_preview_context_picker.dart';
import 'package:map_editor/src/theme/pokemap_theme.dart';

void main() {
  testWidgets('labels each project-backed context in the dialogue scene', (
    tester,
  ) async {
    PersonalizationPreviewContextKind? changedKind;
    String? changedId;
    await tester.pumpWidget(
      _app(
        PersonalizationPreviewContextPicker(
          scene: PersonalizationStudioScene.dialogue,
          contexts: _contexts,
          selectedIds: const <PersonalizationPreviewContextKind, String?>{},
          onSelected: (kind, id) {
            changedKind = kind;
            changedId = id;
          },
        ),
      ),
    );

    expect(find.text('Scène de test'), findsOneWidget);
    expect(
      find.text(
        'Choisissez la carte et le contenu utilisés pour essayer ce rendu.',
      ),
      findsOneWidget,
    );
    for (final kind in <PersonalizationPreviewContextKind>[
      PersonalizationPreviewContextKind.map,
      PersonalizationPreviewContextKind.dialogueScenario,
    ]) {
      expect(
        find.byKey(
          ValueKey<String>('personalization-preview-context-${kind.name}'),
        ),
        findsOneWidget,
      );
    }
    expect(
      find.byKey(
        const ValueKey<String>('personalization-preview-context-encounter'),
      ),
      findsNothing,
    );

    await tester.tap(
      find.byKey(
        const ValueKey<String>(
          'personalization-preview-context-dialogueScenario',
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choix de bienvenue').last);
    await tester.pumpAndSettle();

    expect(changedKind, PersonalizationPreviewContextKind.dialogueScenario);
    expect(changedId, 'dialogueScenario:welcome:0:2');
  });

  testWidgets('keeps legacy dialogue and portrait pickers as fallback', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        PersonalizationPreviewContextPicker(
          scene: PersonalizationStudioScene.dialogue,
          contexts: _contexts
              .where(
                (context) =>
                    context.kind !=
                    PersonalizationPreviewContextKind.dialogueScenario,
              )
              .toList(),
          selectedIds: const <PersonalizationPreviewContextKind, String?>{},
          onSelected: (_, _) {},
        ),
      ),
    );

    expect(
      find.byKey(
        const ValueKey<String>('personalization-preview-context-dialogue'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey<String>(
          'personalization-preview-context-characterPortrait',
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows explicit loading, failure and missing-content states', (
    tester,
  ) async {
    var loading = true;
    String? error;
    late StateSetter update;
    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return PersonalizationPreviewContextPicker(
              scene: PersonalizationStudioScene.battle,
              contexts: const <PersonalizationPreviewContextOption>[],
              selectedIds: const <PersonalizationPreviewContextKind, String?>{},
              onSelected: (_, _) {},
              isLoading: loading,
              errorMessage: error,
            );
          },
        ),
      ),
    );

    expect(
      find.byKey(
        const ValueKey<String>('personalization-preview-context-loading'),
      ),
      findsOneWidget,
    );
    update(() {
      loading = false;
      error = 'Lecture impossible.';
    });
    await tester.pump();
    expect(find.text('Lecture impossible.'), findsOneWidget);
    update(() => error = null);
    await tester.pump();
    expect(
      find.byKey(
        const ValueKey<String>('personalization-preview-context-empty'),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('décor de carte ni rencontre'), findsOneWidget);
  });

  testWidgets('remains usable at narrow width and 200 percent text', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: PersonalizationPreviewContextPicker(
            scene: PersonalizationStudioScene.dialogue,
            contexts: _contexts,
            selectedIds: const <PersonalizationPreviewContextKind, String?>{},
            onSelected: (_, _) {},
          ),
        ),
        width: 540,
      ),
    );

    expect(find.text('Scène de test'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

final _contexts = <PersonalizationPreviewContextOption>[
  _option(
    id: 'map:village',
    kind: PersonalizationPreviewContextKind.map,
    label: 'Village',
  ),
  _option(
    id: 'dialogue:first',
    kind: PersonalizationPreviewContextKind.dialogue,
    label: 'Premier dialogue',
  ),
  _option(
    id: 'dialogue:second',
    kind: PersonalizationPreviewContextKind.dialogue,
    label: 'Deuxième dialogue',
  ),
  _option(
    id: 'characterPortrait:leo:happy',
    kind: PersonalizationPreviewContextKind.characterPortrait,
    label: 'Léo · Heureux',
  ),
  _option(
    id: 'dialogueScenario:welcome:0:0',
    kind: PersonalizationPreviewContextKind.dialogueScenario,
    label: 'Réplique de Léo',
  ),
  _option(
    id: 'dialogueScenario:welcome:0:2',
    kind: PersonalizationPreviewContextKind.dialogueScenario,
    label: 'Choix de bienvenue',
  ),
];

PersonalizationPreviewContextOption _option({
  required String id,
  required PersonalizationPreviewContextKind kind,
  required String label,
}) => PersonalizationPreviewContextOption(
  id: id,
  kind: kind,
  sourceId: id.split(':')[1],
  label: label,
  availability: 'ready',
  diagnosticCodes: const <String>[],
  detail: const <String, Object?>{},
);

Widget _app(Widget child, {double width = 900}) => MaterialApp(
  theme: PokeMapTheme.light(),
  home: Scaffold(
    body: Center(
      child: SizedBox(width: width, height: 500, child: child),
    ),
  ),
);
