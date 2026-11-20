import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test('every direct filesystem writer is classified and new bypasses fail',
      () async {
    final sourceRoot = Directory(p.join(Directory.current.path, 'lib', 'src'));
    final actual = <String>{};
    await for (final entity in sourceRoot.list(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final source = await entity.readAsString();
      if (_hasDirectFileWrite(source)) {
        actual.add(p.relative(entity.path, from: Directory.current.path));
      }
    }

    final classified = <String>{
      ..._platformAndAssetSinks,
      ..._transactionAndRecoverySinks,
    };
    expect(
      actual.difference(classified),
      isEmpty,
      reason: 'A new direct writer must use AuthoringMutationAdapter or be '
          'classified here with an explicit architecture reason.',
    );
    expect(
      classified.difference(actual),
      isEmpty,
      reason: 'Remove stale exceptions so the guardrail cannot hide debt.',
    );
  });

  test('the registered PMCP-081 exceptions still reach legacy writers', () async {
    expect(_legacyStructuredAuthoringDebt, _legacyWriteMarkers.keys.toSet());
    for (final entry in _legacyWriteMarkers.entries) {
      final source = await File(entry.key).readAsString();
      expect(source, contains(entry.value), reason: entry.key);
    }
  });

  test('Authoring editor adapters keep Flutter state and raw writes separate',
      () async {
    final adapterRoot = Directory(
      p.join(
          Directory.current.path, 'lib', 'src', 'application', 'authoring_api'),
    );
    await for (final entity in adapterRoot.list()) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final source = await entity.readAsString();
      final name = p.basename(entity.path);
      if (_flutterStateControllers.contains(name)) {
        expect(source, contains('extends ChangeNotifier'), reason: entity.path);
      } else {
        expect(source, isNot(contains('package:flutter/')), reason: entity.path);
      }
      expect(source, isNot(contains("import 'dart:io'")), reason: entity.path);
      expect(_hasDirectFileWrite(source), isFalse, reason: entity.path);
    }
  });

  test('the product SaveMap provider injects canonical Authoring mutations',
      () async {
    final provider = await File(
      p.join(Directory.current.path, 'lib', 'src', 'app', 'providers', 'editor',
          'map_use_case_providers.dart'),
    ).readAsString();
    expect(provider, contains('authoringMutationAdapterProvider'));
    expect(provider, contains('authoringMutations:'));
  });

  test('encounter use cases inject canonical Authoring mutations', () async {
    final provider = await File(
      p.join(Directory.current.path, 'lib', 'src', 'app', 'providers', 'editor',
          'project_use_case_providers.dart'),
    ).readAsString();
    final gateway = await File(
      p.join(Directory.current.path, 'lib', 'src', 'application',
          'authoring_api', 'encounter_table_persistence_gateway.dart'),
    ).readAsString();
    final useCases = await File(
      p.join(Directory.current.path, 'lib', 'src', 'application', 'use_cases',
          'encounter_table_use_cases.dart'),
    ).readAsString();

    expect(provider, contains('authoringMutationAdapterProvider'));
    expect(provider, contains('encounterTablePersistenceGatewayProvider'));
    expect(gateway, contains('campaign.encounter_table.upsert'));
    expect(gateway, contains('campaign.encounter_table.delete'));
    expect(useCases, isNot(contains('.saveProject(')));
  });
}

final _writeFileBytes = RegExp(r'\.(?:writeAsBytes|writeAsString)\s*\(');
final _moveOrRemoveFile = RegExp(
  r'\.rename\s*\(|\.delete\s*\(\s*(?:\)|recursive\s*:)',
);

bool _hasDirectFileWrite(String source) =>
    _writeFileBytes.hasMatch(source) ||
    (source.contains('dart:io') && _moveOrRemoveFile.hasMatch(source));

const _flutterStateControllers = <String>{
  'presentation_studio_document_controller.dart',
  'presentation_timeline_projection_gateway.dart',
};

const _legacyWriteMarkers = <String, String>{
  'lib/src/features/editor/state/editor_notifier.dart':
      '.saveProject(project,',
  'lib/src/ui/canvas/events_v2/event_builder_v2_product_route.dart':
      'narrativeEventRegistryPersistenceGatewayProvider',
  'lib/src/ui/canvas/storylines_workspace.dart': 'applyInMemoryProjectManifest(',
};

/// Packaging, settings, imported media and Border artifacts are not PokeMap
/// structured authoring documents. Their dedicated ports remain legitimate.
const _platformAndAssetSinks = <String>{
  // Diagnosis log written outside the project, to a destination the operator
  // names, and only when they name one. It holds no authoring document.
  'lib/src/application/services/editor_snapshot_profile_recorder.dart',
  'lib/src/application/tools/export_pokemon_sdk_studio_catalog_cli.dart',
  'lib/src/features/border_studio/infrastructure/filesystem/file_border_asset_snapshot_store.dart',
  'lib/src/features/border_studio/infrastructure/filesystem/file_border_publication_manifest_port.dart',
  'lib/src/features/editor/state/editor_notifier.dart',
  'lib/src/features/game_export/infrastructure/hub_install_request_publisher.dart',
  'lib/src/features/personalization/application/project_branding_image_import_service.dart',
  'lib/src/features/personalization/application/project_font_import_service.dart',
  'lib/src/features/personalization/application/project_intro_video_import_service.dart',
  'lib/src/features/personalization/application/project_presentation_preset_service.dart',
  'lib/src/features/personalization/application/project_presentation_asset_lifecycle.dart',
  'lib/src/features/personalization/application/project_title_music_import_service.dart',
  'lib/src/infrastructure/filesystem/pokemon_menu_sprite_source.dart',
  'lib/src/infrastructure/filesystem/project_filesystem.dart',
  'lib/src/infrastructure/repositories/file_narrative_document_route_store.dart',
  'lib/src/infrastructure/repositories/file_presentation_studio_layout_store.dart',
};

/// Atomic stores, journals and recovery gateways are infrastructure owned by
/// existing crash-safe protocols. They are not additional product commands.
const _transactionAndRecoverySinks = <String>{
  'lib/src/application/services/pokemon_catalog_rebuild_transaction.dart',
  'lib/src/infrastructure/repositories/atomic_project_manifest_persistence.dart',
  'lib/src/infrastructure/repositories/file_narrative_document_recovery_store.dart',
  'lib/src/infrastructure/repositories/file_repositories.dart',
  'lib/src/infrastructure/repositories/journaled_file_promotion_repository.dart',
  'lib/src/infrastructure/repositories/map_lifecycle_transaction_file_gateway.dart',
  'lib/src/infrastructure/repositories/narrative_activity_journal_repository.dart',
  'lib/src/infrastructure/repositories/narrative_event_migration_persistence_repository.dart',
  'lib/src/infrastructure/repositories/narrative_event_registry_persistence.dart',
  'lib/src/infrastructure/repositories/narrative_event_spatial_link_journal_repository.dart',
  'lib/src/infrastructure/repositories/narrative_template_transaction_file_gateway.dart',
  'lib/src/infrastructure/repositories/pokemon_file_write_repository.dart',
};

/// Explicit PMCP-081 residual debt. Keeping this set exact prevents claiming
/// full migration while these specialized paths still perform direct I/O.
const _legacyStructuredAuthoringDebt = <String>{
  'lib/src/features/editor/state/editor_notifier.dart',
  'lib/src/ui/canvas/events_v2/event_builder_v2_product_route.dart',
  'lib/src/ui/canvas/storylines_workspace.dart',
};
