import 'package:map_core/map_core.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show FutureProvider, Provider, Ref;
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../application/ports/narrative_event_registry_persistence_gateway.dart';
import '../../../application/authoring_api/authoring_query_adapter.dart';
import '../../../application/authoring_api/authoring_mutation_adapter.dart';
import '../../../application/authoring_api/authoring_session_lifecycle.dart';
import '../../../application/authoring_api/editor_receipt_presenter.dart';
import '../../../application/ports/narrative_event_migration_persistence_gateway.dart';
import '../../../application/ports/narrative_event_spatial_source_creation_gateway.dart';
import '../../../application/ports/narrative_authoring_persistence_gateway.dart';
import '../../../application/ports/project_workspace.dart';
import '../../../application/services/narrative_document_session.dart';
import '../../../application/services/narrative_activity_journal.dart';
import '../../../application/services/map_lifecycle_transaction_service.dart';
import '../../../application/services/editor_snapshot_profile_recorder.dart';
import '../../../application/services/pokemon_project_data_reader.dart';
import '../../../application/use_cases/execute_narrative_authoring_transaction.dart';
import '../../../domain/repositories/repositories.dart';
import '../../../features/personalization/application/personalization_studio_session_controller.dart';
import '../../../features/personalization/application/personalization_character_preview_source.dart';
import '../../../features/personalization/application/personalization_preview_context_source.dart';
import '../../../features/personalization/application/personalization_studio_asset_picker.dart';
import '../../../features/personalization/application/project_branding_image_import_service.dart';
import '../../../features/personalization/application/project_font_import_service.dart';
import '../../../features/personalization/application/project_intro_video_import_service.dart';
import '../../../features/personalization/application/project_presentation_preflight.dart';
import '../../../features/personalization/application/project_presentation_preset_service.dart';
import '../../../features/personalization/application/project_title_music_import_service.dart';
import '../../../features/personalization/application/project_title_motion_import_service.dart';
import '../../../features/personalization/application/project_title_music_preview_controller.dart';
import '../../../infrastructure/filesystem/project_filesystem.dart';
import '../../../infrastructure/authoring_api/editor_project_file_reader.dart';
import '../../../infrastructure/repositories/file_repositories.dart';
import '../../../infrastructure/repositories/file_narrative_document_recovery_store.dart';
import '../../../infrastructure/repositories/map_lifecycle_transaction_file_gateway.dart';
import '../../../infrastructure/repositories/narrative_event_spatial_link_journal_repository.dart';
import '../../../infrastructure/repositories/narrative_activity_journal_repository.dart';
import '../../../infrastructure/repositories/narrative_event_migration_persistence_repository.dart';
import '../../../infrastructure/repositories/project_presentation_document_gateway.dart';
import '../../../infrastructure/repositories/project_manifest_narrative_document_gateway.dart';

part 'repository_providers.g.dart';

final mapLifecycleTransactionCoordinatorProvider =
    Provider<MapLifecycleTransactionCoordinator?>((ref) {
      final mapRepository = ref.watch(mapRepositoryProvider);
      if (mapRepository is! RevisionedMapRepository) return null;
      return MapLifecycleTransactionCoordinator(
        MapLifecycleTransactionFileGateway(mapRepository: mapRepository),
      );
    });

final editorProjectFileReaderProvider = Provider<EditorProjectFileReader>(
  (ref) => const EditorProjectFileReader(),
);

final pokemonProjectDataReaderProvider = Provider<PokemonProjectDataReader>(
  (ref) => PokemonProjectDataReader(),
);

final authoringFingerprintCacheProvider =
    Provider<ProjectSnapshotFingerprintCache>(
      (ref) => ProjectSnapshotFingerprintCache(),
    );

final authoringSnapshotCacheProvider = Provider<ProjectSnapshotCache>(
  (ref) => ProjectSnapshotCache(),
);

/// Null unless the session was started with a profile destination, so the
/// ordinary path resolves this once and never records anything.
final editorSnapshotProfileRecorderProvider =
    Provider<EditorSnapshotProfileRecorder?>(
  (ref) => EditorSnapshotProfileRecorder.resolve(),
);

final editorAuthoringSessionLifecycleProvider =
    Provider<EditorAuthoringSessionLifecycle>((ref) {
      final lifecycle = EditorAuthoringSessionLifecycle(
        fileReader: ref.watch(editorProjectFileReaderProvider),
      );
      ref.onDispose(lifecycle.closeAll);
      return lifecycle;
    });

final authoringQueryAdapterProvider = Provider<AuthoringQueryAdapter>((ref) {
  final adapter = AuthoringQueryAdapter(
    fileReader: ref.watch(editorProjectFileReaderProvider),
    fingerprintCache: ref.watch(authoringFingerprintCacheProvider),
    snapshotCache: ref.watch(authoringSnapshotCacheProvider),
    profileRecorder: ref.watch(editorSnapshotProfileRecorderProvider),
  );
  ref.watch(editorAuthoringSessionLifecycleProvider).attach(adapter);
  ref.onDispose(adapter.closeAll);
  return adapter;
});

final personalizationPreviewContextSourceProvider =
    Provider<PersonalizationPreviewContextSource>((ref) {
      return AuthoringPersonalizationPreviewContextSource(
        queries: ref.watch(authoringQueryAdapterProvider),
      );
    });

final personalizationPreviewContextOptionsProvider = FutureProvider.autoDispose
    .family<
      List<PersonalizationPreviewContextOption>,
      ({String projectRoot, PersonalizationPreviewContextScope scope})
    >(
      (ref, request) => ref
          .watch(personalizationPreviewContextSourceProvider)
          .load(request.projectRoot, scope: request.scope),
    );

final personalizationCharacterPreviewSourceProvider =
    Provider<PersonalizationCharacterPreviewSource>((ref) {
      return AuthoringPersonalizationCharacterPreviewSource(
        queries: ref.watch(authoringQueryAdapterProvider),
      );
    });

final personalizationCharacterPreviewOptionsProvider = FutureProvider
    .autoDispose
    .family<List<PersonalizationCharacterPreviewOption>, String>(
      (ref, projectRoot) => ref
          .watch(personalizationCharacterPreviewSourceProvider)
          .load(projectRoot),
    );

final authoringMutationAdapterProvider = Provider<AuthoringMutationAdapter>((
  ref,
) {
  final projectFiles = ref.watch(editorProjectFileReaderProvider);
  final adapter = AuthoringMutationAdapter(
    fileReader: projectFiles,
    queries: ref.watch(authoringQueryAdapterProvider),
    projectRoots: projectFiles,
    fingerprintCache: ref.watch(authoringFingerprintCacheProvider),
    snapshotCache: ref.watch(authoringSnapshotCacheProvider),
    profileRecorder: ref.watch(editorSnapshotProfileRecorderProvider),
    invalidatePokemonSpeciesSnapshot: ref
        .watch(pokemonProjectDataReaderProvider)
        .invalidateSpeciesSnapshotForProjectRoot,
  );
  ref.watch(editorAuthoringSessionLifecycleProvider).attach(adapter);
  ref.onDispose(adapter.closeAll);
  return adapter;
});

final editorReceiptPresenterProvider = Provider<EditorReceiptPresenter>(
  (ref) => const EditorReceiptPresenter(),
);

final fileProjectRepositoryProvider = Provider<FileProjectRepository>((ref) {
  return FileProjectRepository(
    mapLifecycleTransactions: ref.watch(
      mapLifecycleTransactionCoordinatorProvider,
    ),
    authoringQueries: ref.watch(authoringQueryAdapterProvider),
  );
});

final personalizationStudioAssetPickerProvider =
    Provider<PersonalizationStudioAssetPicker>((ref) {
      return const FilePickerPersonalizationStudioAssetPicker();
    });

final personalizationStudioBrandingImagePickerProvider =
    Provider<PersonalizationStudioBrandingImagePicker>((ref) {
      return const FilePickerPersonalizationStudioBrandingImagePicker();
    });

final personalizationStudioTitleMusicPickerProvider =
    Provider<PersonalizationStudioTitleMusicPicker>((ref) {
      return const FilePickerPersonalizationStudioTitleMusicPicker();
    });

final personalizationStudioPresetFilePickerProvider =
    Provider<PersonalizationStudioPresetFilePicker>((ref) {
      return const FilePickerPersonalizationStudioPresetFilePicker();
    });

final projectPresentationPresetServiceProvider =
    Provider<ProjectPresentationPresetService>((ref) {
      return ProjectPresentationPresetService(
        mutations: ref.watch(authoringMutationAdapterProvider),
        queries: ref.watch(authoringQueryAdapterProvider),
      );
    });

final projectBrandingImageImportServiceProvider =
    Provider<ProjectBrandingImageImporter>((ref) {
      return const ProjectBrandingImageImportService();
    });

final projectTitleMusicImportServiceProvider =
    Provider<ProjectTitleMusicImporter>((ref) {
      return const ProjectTitleMusicImportService();
    });

typedef ProjectTitleMusicPreviewControllerFactory =
    ProjectTitleMusicPreviewController Function();

final projectTitleMusicPreviewControllerFactoryProvider =
    Provider<ProjectTitleMusicPreviewControllerFactory>((ref) {
      return DefaultProjectTitleMusicPreviewController.new;
    });

final projectIntroVideoImportServiceProvider =
    Provider<ProjectIntroVideoImporter>((ref) {
      return const ProjectIntroVideoImportService();
    });

final projectTitleMotionImportServiceProvider =
    Provider<ProjectTitleMotionLoopImporter>((ref) {
      return const ProjectTitleMotionImportService();
    });

final projectFontImportServiceProvider = Provider<ProjectFontImporter>((ref) {
  return const ProjectFontImportService();
});

final projectPresentationPreflightProvider =
    Provider<ProjectPresentationPreflight>((ref) {
      return const FileSystemProjectPresentationPreflight();
    });

final projectFontPreviewLoaderProvider = Provider<ProjectFontPreviewRegistry>((
  ref,
) {
  return const ProjectFontPreviewLoader();
});

final narrativeEventRegistryPersistenceGatewayProvider =
    Provider<NarrativeEventRegistryPersistenceGateway>((ref) {
      return ref.watch(fileProjectRepositoryProvider);
    });

final narrativeAuthoringPersistenceGatewayProvider =
    Provider<NarrativeAuthoringPersistenceGateway>((ref) {
      return ref
          .watch(fileProjectRepositoryProvider)
          .narrativeAuthoringPersistence;
    });

final executeNarrativeAuthoringTransactionProvider =
    Provider<ExecuteNarrativeAuthoringTransaction>((ref) {
      return ExecuteNarrativeAuthoringTransaction(
        ref.watch(narrativeAuthoringPersistenceGatewayProvider),
      );
    });

typedef NarrativeProjectDocumentSessionFactory =
    NarrativeDocumentSession<ProjectManifest> Function({
      required String projectPath,
      required ProjectManifest initialDocument,
    });

typedef PersonalizationStudioSessionControllerFactory =
    PersonalizationStudioSessionController Function({
      required String projectPath,
      required ProjectManifest initialDocument,
    });

final personalizationRecoveryStoreDiagnosticsProvider =
    Provider<NarrativeRecoveryStoreDiagnostics>(
      (ref) => NarrativeRecoveryStoreDiagnostics(),
    );

final personalizationStudioSessionControllerFactoryProvider =
    Provider<PersonalizationStudioSessionControllerFactory>((ref) {
      final persistence = ref
          .watch(fileProjectRepositoryProvider)
          .narrativeAuthoringPersistence;
      final authoringMutations = ref.watch(authoringMutationAdapterProvider);
      final recoveryDiagnostics = ref.watch(
        personalizationRecoveryStoreDiagnosticsProvider,
      );
      return ({
        required String projectPath,
        required ProjectManifest initialDocument,
      }) {
        final journalPath = p.join(
          p.dirname(projectPath),
          '.pokemap',
          'recovery',
          'personalization-studio.json',
        );
        final gateway = ProjectPresentationDocumentGateway(
          projectPath: projectPath,
          persistence: persistence,
          canonicalSave:
              ({
                required profile,
                required expectedProjectRevision,
                required operationId,
              }) async {
                await authoringMutations.savePresentation(
                  profile,
                  p.dirname(projectPath),
                  expectedProjectRevision: expectedProjectRevision,
                  operationId: operationId,
                );
              },
        );
        return PersonalizationStudioSessionController(
          session: NarrativeDocumentSession<ProjectPresentationProfile>(
            documentId: 'personalization-studio',
            initialDocument: initialDocument.effectivePresentation,
            gateway: gateway,
            recoveryStore:
                FileNarrativeDocumentRecoveryStore<ProjectPresentationProfile>(
                  journalPath: journalPath,
                  encodeDocument: (profile) => profile.toJson(),
                  decodeDocument: _decodeRecoveryPresentationProfile,
                  needsMigration: _isLegacyRecoveryPresentationDocument,
                  diagnostics: recoveryDiagnostics,
                ),
          ),
          initialProject: initialDocument,
          projectSnapshot: () => gateway.currentProject,
        );
      };
    });

/// Creates the crash-safe document session used by the Cinematics pilot.
///
/// Autosave is opt-in at product level. The journal still protects every local
/// edit immediately, independently of that preference.
final narrativeProjectDocumentSessionFactoryProvider =
    Provider<NarrativeProjectDocumentSessionFactory>((ref) {
      final persistence = ref.watch(
        narrativeAuthoringPersistenceGatewayProvider,
      );
      return ({
        required String projectPath,
        required ProjectManifest initialDocument,
      }) {
        final journalPath = p.join(
          p.dirname(projectPath),
          '.pokemap',
          'recovery',
          'narrative-cinematics.json',
        );
        final session = NarrativeDocumentSession<ProjectManifest>(
          documentId: 'cinematics',
          initialDocument: initialDocument,
          gateway: ProjectManifestNarrativeDocumentGateway(
            projectPath: projectPath,
            persistence: persistence,
          ),
          recoveryStore: FileNarrativeDocumentRecoveryStore<ProjectManifest>(
            journalPath: journalPath,
            encodeDocument: (document) => document.toJson(),
            decodeDocument: _decodeRecoveryProjectManifest,
          ),
          rebasePolicy: projectManifestNarrativeDocumentRebasePolicy,
        );
        final projectRootPath = p.dirname(projectPath);
        final activityRepository = NarrativeActivityJournalRepository(
          projectRootPath: projectRootPath,
        );
        NarrativeActivitySessionRecorder<ProjectManifest>(
          session: session,
          store: activityRepository,
          destination: NarrativeActivityDestination.cinematics,
          onPersisted: () =>
              ref.invalidate(narrativeActivityJournalProvider(projectRootPath)),
          // Activity telemetry must never make a crash-safe authoring edit fail.
          // The Overview exposes repository read failures separately.
          onError: (_) {},
        );
        return session;
      };
    });

final narrativeActivityJournalProvider = FutureProvider.autoDispose
    .family<NarrativeActivityJournal, String>((ref, projectRootPath) {
      return NarrativeActivityJournalRepository(
        projectRootPath: projectRootPath,
      ).load();
    });

final narrativeEventSpatialSourceCreationGatewayProvider =
    Provider<NarrativeEventSpatialSourceCreationGateway>((ref) {
      return NarrativeEventSpatialLinkJournalRepository();
    });

final narrativeEventMigrationPersistenceGatewayProvider =
    Provider<NarrativeEventMigrationPersistenceGateway>((ref) {
      return NarrativeEventMigrationPersistenceRepository();
    });

/// Providers transverses de bas niveau pour la composition root.
///
/// Ce fichier reste volontairement petit :
/// - uniquement les frontières d'accès aux données / workspace ;
/// - aucune orchestration métier ;
/// - aucune dépendance à des thèmes UI.
@riverpod
ProjectRepository projectRepository(Ref ref) {
  return ref.watch(fileProjectRepositoryProvider);
}

@riverpod
MapRepository mapRepository(Ref ref) {
  return FileMapRepository(
    authoringQueries: ref.watch(authoringQueryAdapterProvider),
  );
}

@riverpod
TilesetRepository tilesetRepository(Ref ref) {
  return FileTilesetRepository();
}

@riverpod
ProjectWorkspaceFactory projectWorkspaceFactory(Ref ref) {
  return const FileProjectWorkspaceFactory();
}

ProjectManifest _decodeRecoveryProjectManifest(Object? value) {
  if (value is! Map) {
    throw const FormatException(
      'A recovery project manifest must be a JSON object.',
    );
  }
  final json = <String, dynamic>{};
  for (final entry in value.entries) {
    if (entry.key is! String) {
      throw const FormatException(
        'A recovery project manifest contains a non-string key.',
      );
    }
    json[entry.key as String] = entry.value;
  }
  final manifest = ProjectManifest.fromJson(json);
  ProjectValidator.validate(manifest);
  return manifest;
}

ProjectPresentationProfile _decodeRecoveryPresentationProfile(Object? value) {
  if (value is! Map) {
    throw const FormatException(
      'A recovery presentation profile must be a JSON object.',
    );
  }
  final json = <String, dynamic>{};
  for (final entry in value.entries) {
    if (entry.key is! String) {
      throw const FormatException(
        'A recovery presentation profile contains a non-string key.',
      );
    }
    json[entry.key as String] = entry.value;
  }
  if (json.containsKey('name') && json.containsKey('maps')) {
    return _decodeRecoveryProjectManifest(json).effectivePresentation;
  }
  return ProjectPresentationProfile.fromJson(json);
}

bool _isLegacyRecoveryPresentationDocument(Object? value) {
  return value is Map && value.containsKey('name') && value.containsKey('maps');
}
