import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/environment_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';
import '../support/map_workspace_fixture.dart';

void main() {
  final project = workspaceProject.copyWith(
    environmentPresets: [
      EnvironmentPreset(
        id: 'garden',
        name: 'Jardin',
        templateId: 'manual',
        sortOrder: 0,
        palette: [EnvironmentPaletteItem(elementId: 'tree', weight: 1)],
        defaultParams: EnvironmentGenerationParams(
          density: 1,
          variation: 0,
          edgeDensity: 1,
          minSpacingCells: 0,
        ),
      ),
    ],
  );
  EditableMapDocument document() => EditableMapDocument(
    MapWorkspaceDocument(map: workspaceMap('a'), mapId: 'a', revision: 'r0'),
  );

  test('one stroke keeps exact cells and holes with one undo', () {
    final doc = document();
    final commands = EnvironmentEditingCommands(doc, project);
    final session = commands.create(project.environmentPresets.single);
    final before = doc.current;
    final history = doc.undoCount;
    commands.paint(session, [
      const GridPos(x: 2, y: 2),
      const GridPos(x: 4, y: 2),
    ], erase: false);
    expect(commands.area(session)!.mask.activeCellCount, 2);
    expect(commands.area(session)!.mask.isActiveAt(3, 2), isFalse);
    expect(doc.undoCount, history + 1);
    doc.restore(redo: false);
    expect(doc.current, before);
  });

  test(
    'preview writes nothing and erased outer cells remove generated decors',
    () {
      final doc = document();
      final commands = EnvironmentEditingCommands(doc, project);
      final session = commands.create(project.environmentPresets.single);
      commands.paintRectangle(
        session,
        const GridPos(x: 2, y: 2),
        const GridPos(x: 3, y: 3),
      );
      commands.paintRectangle(
        session,
        const GridPos(x: 8, y: 2),
        const GridPos(x: 9, y: 3),
      );
      final source = doc.current;
      commands.preview(session);
      expect(doc.current, source);
      commands.apply(session);
      expect(
        doc.current.placedElements.map((p) => p.pos),
        contains(const GridPos(x: 8, y: 2)),
      );
      commands.paint(session, [const GridPos(x: 8, y: 2)], erase: true);
      commands.preview(session);
      commands.apply(session);
      expect(
        doc.current.placedElements.map((p) => p.pos),
        isNot(contains(const GridPos(x: 8, y: 2))),
      );
      expect(commands.area(session)!.mask.isActiveAt(8, 2), isFalse);
    },
  );

  test('stale preview refuses without overwriting an intervening edit', () {
    final doc = document();
    final commands = EnvironmentEditingCommands(doc, project);
    final session = commands.create(project.environmentPresets.single);
    commands.paint(session, [const GridPos(x: 2, y: 2)], erase: false);
    commands.preview(session);
    doc.commit(doc.current.copyWith(name: 'Édition indépendante'));
    final source = doc.current;
    expect(() => commands.apply(session), throwsStateError);
    expect(doc.current, source);
  });
}
