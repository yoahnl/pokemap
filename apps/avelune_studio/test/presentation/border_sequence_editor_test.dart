import 'dart:convert';

import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/border_creation_owner_fixture.dart';
import '../support/spatial_border_fixture.dart';

void main() {
  for (final straightOnly in [true, false]) {
    test(
      'a new border sends all six configured steps (straight: $straightOnly)',
      () async {
        final project = spatialBorderVariantProject();
        final host = BorderCreationOwnerFixture(project: project);
        final draft = host.draft..name = 'Motif créé';
        draft.setStraightOnly(straightOnly);
        draft.followContourDirection = !straightOnly;
        final catalog = resourceCatalog(project);
        final model = catalog.firstWhere((item) => item.model3d?.id == 'oak');
        for (final role in draft.roles) {
          draft.assignRole(role, model);
        }
        if (!straightOnly) {
          expect(draft.setCornerJoin('lineCornerLeft', '1'), isTrue);
        }
        expect(draft.setSequenceLength('6'), isTrue);
        draft.setPrimitiveSource('lineStraight', 'replacement');
        draft.setPrimitiveSource('lineStraight_step_5', 'replacement');
        expect(await host.workflow.save(publish: true), isFalse);
        final request = host.port.requests.single;
        expect(request.sequenceLength, 6);
        expect(request.straightModelId, 'oak');
        expect(request.capModelId, 'oak');
        expect(request.straightOnly, straightOnly);
        if (!straightOnly) {
          expect(request.cornerModelId, 'oak');
          expect(request.innerCornerModelId, 'oak');
          expect(
            request.primitiveModelSettings['lineCornerLeft']!.cornerJoinCells,
            1,
          );
          expect(
            request
                .primitiveModelSettings['lineCornerLeft_step_5']!
                .cornerJoinCells,
            1,
          );
        }
        expect(request.primitiveModelIds['lineStraight'], 'replacement');
        expect(request.primitiveModelIds['lineStraight_step_5'], 'replacement');
        expect(request.publish, isTrue);
        expect(draft.error, contains('Requête reçue'));
      },
    );
  }

  for (final incomplete in [false, true]) {
    test(
      incomplete
          ? 'an incomplete sequence refuses publication before reaching its port'
          : 'six sequence steps remain editable and survive export draft capture',
      () async {
        final base = spatialBorderVariantProject();
        final raw = encodeBorderBlueprintRecordJson(
          base.borderCatalog.records.single,
          formatVersion: ProjectBorderCatalog.latestSupportedFormatVersion,
        );
        final definition = (raw['draft'] as Map)['definition'] as Map;
        definition['sequenceLength'] = 6;
        final primitives = (definition['primitives'] as List).cast<Map>();
        definition['primitives'] = [
          for (var step = 0; step < (incomplete ? 5 : 6); step++)
            for (final primitive in primitives)
              {
                ...primitive,
                'id': '${primitive['id']}-$step',
                'sequenceIndex': step,
              },
        ];
        final record = decodeBorderBlueprintRecordJson(
          raw,
          formatVersion: ProjectBorderCatalog.latestSupportedFormatVersion,
        );
        final project = base.copyWith(
          borderCatalog: ProjectBorderCatalog(
            formatVersion: ProjectBorderCatalog.latestSupportedFormatVersion,
            records: [record],
          ),
        );
        final host = BorderCreationOwnerFixture(
          project: project,
          initialRecord: record,
        );
        final draft = host.draft;
        expect(draft.sequenceLength, 6);
        if (incomplete) {
          expect(
            draft.sequenceProblem,
            'Chaque étape doit contenir un corps et des extrémités avant publication.',
          );
          expect(await host.workflow.save(publish: true), isFalse);
          expect(host.port.requests, isEmpty);
          return;
        }
        draft.setPrimitiveSource('south-cap-5', 'replacement');
        final captured = host.navigation.packBorderDraftOwners['fence']!();
        expect(
          captured.request.primitiveModelIds['south-cap-5'],
          'replacement',
        );
        expect((jsonDecode(captured.signature) as Map)['sequenceLength'], 6);
        expect(draft.setSequenceLength('0'), isFalse);
        expect(draft.sequenceLength, 6);
        expect(draft.setSequenceLength('3'), isTrue);
        expect(
          (jsonDecode(
            host.navigation.packBorderDraftOwners['fence']!().signature,
          ) as Map)['sequenceLength'],
          3,
        );
      },
    );
  }
}
