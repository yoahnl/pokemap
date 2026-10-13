import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';

Sha256Hash _hash(String value) => Sha256Hash(List.filled(64, value).join());

SourceSemanticResolver _resolver({bool qualified = true}) =>
    SourceSemanticResolver(
      profile: SourceSemanticProfile.kantoPlayerWalk(
        scriptsArchiveHash: qualified
            ? Sha256Hash(SourceSemanticProfile.kantoScriptsArchiveSha256)
            : _hash('c'),
        sourceSnapshotHash: _hash('a'),
        sourceSelectionHash: _hash('b'),
      ),
    );

SourceSemanticCell _cell(int x, int y,
        {int passage = 0, int terrain = 0, int priority = 0}) =>
    SourceSemanticCell(
      sourceMapId: 98,
      x: x,
      y: y,
      width: 72,
      height: 61,
      stack: [
        const SourceSemanticTile(sourceZ: 2, tileId: 0),
        const SourceSemanticTile(sourceZ: 1, tileId: 0),
        SourceSemanticTile(
          sourceZ: 0,
          tileId: terrain == 1 ? 1212 : 386,
          passage: passage,
          priority: priority,
          terrainTag: terrain,
        ),
      ],
    );

void main() {
  test('north entry into Route 9 ledge is blocked before jump detection', () {
    final passage = _resolver().resolveTransition(
      _cell(68, 21),
      _cell(68, 20, passage: 7, terrain: 1),
      SourceCardinalDirection.up,
    );
    expect(passage.status, SourcePassageStatus.blocked);
    expect(passage.reason, SourcePassageReason.directionBlocked);
    expect(passage.entry.direction, SourceCardinalDirection.down);
    expect(passage.entry.trace.last.tile.tileId, 1212);
  });

  for (final direction in SourceCardinalDirection.values) {
    test('ledge departure honors the ${direction.name} bit before a jump', () {
      final passage = _resolver().resolveTransition(
        _cell(20, 20, passage: direction.bit, terrain: 1),
        _cell(20 + direction.dx, 20 + direction.dy),
        direction,
      );
      expect(passage.status, SourcePassageStatus.blocked);
      expect(passage.reason, SourcePassageReason.directionBlocked);
      expect(passage.exit.trace.last.reason,
          SourcePassageReason.directionBlocked);
    });
  }

  test('a fully blocked ledge cannot become a jump candidate', () {
    final passage = _resolver().resolveTransition(
      _cell(64, 8),
      _cell(64, 9, passage: 15, terrain: 1),
      SourceCardinalDirection.down,
    );
    expect(passage.status, SourcePassageStatus.blocked);
    expect(passage.reason, SourcePassageReason.allDirectionsBlocked);
  });

  test('the legal south admission still requires a separate jump decision', () {
    final passage = _resolver().resolveTransition(
      _cell(64, 8),
      _cell(64, 9, passage: 7, terrain: 1),
      SourceCardinalDirection.down,
    );
    expect(passage.status, SourcePassageStatus.unqualified);
    expect(passage.reason, SourcePassageReason.ledgeRequiresGameplay);
    expect(passage.isPassable, isNull);
  });

  test('an unattested profile cannot qualify a ledge refusal', () {
    final passage = _resolver(qualified: false).resolveTransition(
      _cell(68, 21),
      _cell(68, 20, passage: 7, terrain: 1),
      SourceCardinalDirection.up,
    );
    expect(passage.status, SourcePassageStatus.unqualified);
    expect(passage.reason, SourcePassageReason.unqualifiedProfile);
  });

  test('an unsupported actor context remains an explicit ledge gap', () {
    final passage = _resolver().resolveTransition(
      _cell(68, 21),
      _cell(68, 20, passage: 7, terrain: 1),
      SourceCardinalDirection.up,
      context: const SourceSemanticContext(actorWidth: 2),
    );
    expect(passage.status, SourcePassageStatus.unqualified);
    expect(passage.reason, SourcePassageReason.unsupportedContext);
  });

  test('d0 landing permission does not authorize a cardinal ledge entry', () {
    final resolver = _resolver();
    final ledge = _cell(68, 20, passage: 7, terrain: 1);
    expect(resolver.resolveConnectionEntryTile(ledge).isPassable, isTrue);
    expect(
      resolver
          .resolveTransition(_cell(68, 21), ledge, SourceCardinalDirection.up)
          .isPassable,
      isFalse,
    );
  });
}
