import 'package:avelune_studio/features/resources/application/resource_usage_presentation.dart';
import 'package:avelune_studio/features/resources/domain/resource_usage_port.dart';
import 'package:flutter_test/flutter_test.dart';

ResourceUsageEntry _entry(
  String ownerKind,
  ResourceUsageRelation relation, {
  String id = 'owner',
}) => ResourceUsageEntry(
  ownerKind: ownerKind,
  ownerId: id,
  ownerLabel: id,
  location: 'ici',
  relation: relation,
);

ResourceUsageReport _report(
  List<ResourceUsageEntry> entries, {
  List<String> issues = const [],
}) => ResourceUsageReport(
  target: const ResourceUsageTarget(family: 'element', id: 'tree'),
  revision: 'r1',
  fingerprints: const {},
  entries: entries,
  coverageIssues: issues,
);

void main() {
  test('entries are grouped by owner kind keeping the report order', () {
    final first = _entry('map', ResourceUsageRelation.direct, id: 'a');
    final other = _entry('scene', ResourceUsageRelation.indirect);
    final second = _entry('map', ResourceUsageRelation.technical, id: 'b');
    final groups = groupResourceUsageEntries(_report([first, other, second]));
    expect(groups.keys, ['map', 'scene']);
    expect(groups['map'], [first, second]);
    expect(groupResourceUsageEntries(null), isEmpty);
  });

  test('relation and owner labels are the displayed French wording', () {
    expect({
      for (final relation in ResourceUsageRelation.values)
        relation: resourceUsageRelationLabel(relation),
    }, {
      ResourceUsageRelation.direct: 'Direct',
      ResourceUsageRelation.indirect: 'Indirect',
      ResourceUsageRelation.technical: 'Conservation technique',
      ResourceUsageRelation.ambiguous: 'Identité ambiguë',
    });
    expect(resourceUsageOwnerLabel('map'), 'Cartes et instances');
    expect(resourceUsageOwnerLabel('border'), 'Bordures et snapshots');
    expect(resourceUsageOwnerLabel('borderSnapshot'), 'Bordures et snapshots');
    expect(resourceUsageOwnerLabel('smartTileDraft'), 'Brouillons de terrains');
    expect(resourceUsageOwnerLabel('inconnu'), 'inconnu');
  });

  test('the relation summary counts every relation, including empty ones', () {
    final report = _report([
      _entry('map', ResourceUsageRelation.direct),
      _entry('map', ResourceUsageRelation.direct, id: 'b'),
      _entry('scene', ResourceUsageRelation.ambiguous),
    ]);
    expect(
      resourceUsageRelationSummary(report),
      'Direct : 2 · Indirect : 0 · Conservation technique : 0 · Identité ambiguë : 1',
    );
  });

  test('an empty report claims "no usage" only when the scope is complete, clean and current', () {
    final complete = _report(const []);
    expect(
      resourceUsageEmptyMessage(complete, dirtyOwners: const [], stale: false),
      'Aucun usage trouvé dans le périmètre complet de cette révision.',
    );
    const inconclusive =
        'Aucun résultat disponible. Cela ne signifie pas « inutilisé ».';
    expect(
      resourceUsageEmptyMessage(complete, dirtyOwners: ['Carte A'], stale: false),
      inconclusive,
    );
    expect(
      resourceUsageEmptyMessage(complete, dirtyOwners: const [], stale: true),
      inconclusive,
    );
    expect(
      resourceUsageEmptyMessage(
        _report(const [], issues: ['Scène illisible']),
        dirtyOwners: const [],
        stale: false,
      ),
      inconclusive,
    );
  });

  test('a report with entries has no empty message', () {
    expect(
      resourceUsageEmptyMessage(
        _report([_entry('map', ResourceUsageRelation.direct)]),
        dirtyOwners: const [],
        stale: false,
      ),
      isNull,
    );
  });
}
