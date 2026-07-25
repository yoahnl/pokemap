import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:pokemap_hub/pokemap_hub_ui.dart';
import 'package:pub_semver/pub_semver.dart';

void main() {
  late Directory root;
  late GameLibraryStore libraryStore;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('hub-dashboard-');
    libraryStore = GameLibraryStore(supportRoot: root);
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test('initialization exposes a guided empty library', () async {
    final controller = HubDashboardController(
      libraryStore: libraryStore,
      activityReader: (_) async => const HubGameActivity(),
    );

    await controller.initialize();

    expect(controller.snapshot.status, HubDashboardStatus.ready);
    expect(controller.snapshot.games, isEmpty);
    expect(controller.snapshot.library.revision, 0);
    controller.dispose();
  });

  test('initialization consumes editor exports before reading the library',
      () async {
    var consumed = false;
    final controller = HubDashboardController(
      libraryStore: libraryStore,
      activityReader: (_) async => const HubGameActivity(),
      editorExportConsumer: () async {
        consumed = true;
        await libraryStore.save(
          GameLibrary(
            revision: 1,
            updatedAt: DateTime.utc(2026, 7, 25),
            games: <InstalledGame>[
              _game('games.example.exported', 'Exported'),
            ],
          ),
        );
        return const <EditorExportInstallResult>[
          EditorExportInstallResult(
            requestId: 'export-004',
            status: EditorExportInstallStatus.installed,
            code: 'installed',
          ),
        ];
      },
    );

    await controller.initialize();

    expect(consumed, isTrue);
    expect(controller.snapshot.games.single.game.title, 'Exported');
    controller.dispose();
  });

  test('search, recent ordering, and selection are deterministic', () async {
    await libraryStore.save(
      GameLibrary(
        revision: 1,
        updatedAt: DateTime.utc(2026, 7, 25),
        games: <InstalledGame>[
          _game('games.example.aube', 'Aube'),
          _game('games.example.brume', 'Brume'),
        ],
      ),
    );
    final controller = HubDashboardController(
      libraryStore: libraryStore,
      activityReader: (game) async => HubGameActivity(
        canContinue: true,
        lastSaveAt: game.title == 'Brume'
            ? DateTime.utc(2026, 7, 25)
            : DateTime.utc(2026, 7, 24),
        playTimeSeconds: game.title == 'Brume' ? 7200 : 3600,
      ),
    );

    await controller.initialize();

    expect(
      controller.snapshot.games.map((game) => game.game.title),
      <String>['Brume', 'Aube'],
    );
    controller.setQuery('aub');
    expect(
      controller.snapshot.visibleGames.single.game.title,
      'Aube',
    );
    controller.selectGame('games.example.aube');
    expect(controller.snapshot.selectedGame?.game.title, 'Aube');
    controller.closeGameDetails();
    expect(controller.snapshot.selectedGame, isNull);
    controller.dispose();
  });

  test('package import publishes progress then refreshes the library',
      () async {
    final observed = <HubDashboardStatus>[];
    var storageReads = 0;
    late HubDashboardController controller;
    controller = HubDashboardController(
      libraryStore: libraryStore,
      activityReader: (_) async => const HubGameActivity(),
      storageReader: () async => HubStorageSnapshot(usedBytes: ++storageReads),
      importer: (_, token, onProgress) async {
        expect(token.isCancelled, isFalse);
        onProgress(
          const GameInstallProgress(
            stage: GameInstallStage.extracting,
            completedFiles: 2,
            totalFiles: 4,
            completedBytes: 20,
            totalBytes: 40,
            cancellable: true,
          ),
        );
        await libraryStore.save(
          GameLibrary(
            revision: 1,
            updatedAt: DateTime.utc(2026, 7, 25),
            games: <InstalledGame>[_game('games.example.aube', 'Aube')],
          ),
        );
      },
    )..addListener(() => observed.add(controller.snapshot.status));

    await controller.initialize();
    final package = File('${root.path}/aube.pokemapgame');
    await package.writeAsBytes(<int>[1, 2, 3]);
    await controller.importPackage(package);

    expect(observed, contains(HubDashboardStatus.installing));
    expect(controller.snapshot.games.single.game.title, 'Aube');
    expect(controller.snapshot.status, HubDashboardStatus.ready);
    expect(storageReads, 2, reason: 'Storage is refreshed after installation.');
    controller.dispose();
  });

  test('cancel forwards to the active installation token', () async {
    late GameInstallCancellationToken received;
    final started = Completer<void>();
    final release = Completer<void>();
    final controller = HubDashboardController(
      libraryStore: libraryStore,
      activityReader: (_) async => const HubGameActivity(),
      importer: (_, token, __) async {
        received = token;
        started.complete();
        await release.future;
      },
    );
    await controller.initialize();
    final package = File('${root.path}/aube.pokemapgame');
    await package.writeAsBytes(<int>[1]);

    final import = controller.importPackage(package);
    await started.future;
    controller.cancelImport();
    expect(received.isCancelled, isTrue);
    release.complete();
    await import;
    controller.dispose();
  });

  test('installer cancellation returns to the ready library state', () async {
    final controller = HubDashboardController(
      libraryStore: libraryStore,
      activityReader: (_) async => const HubGameActivity(),
      importer: (_, __, ___) async {
        throw const GameInstallationException(
          GameInstallationDiagnostic(
            code: GameInstallationErrorCode.cancelled,
            stage: GameInstallStage.cancelled,
            retryable: false,
            repairSuggested: false,
          ),
        );
      },
    );
    await controller.initialize();
    final package = File('${root.path}/aube.pokemapgame');
    await package.writeAsBytes(<int>[1]);

    await controller.importPackage(package);

    expect(controller.snapshot.status, HubDashboardStatus.ready);
    expect(controller.snapshot.safeErrorMessage, isNull);
    controller.dispose();
  });

  test('unexpected installer failures become player-safe diagnostics',
      () async {
    final controller = HubDashboardController(
      libraryStore: libraryStore,
      activityReader: (_) async => const HubGameActivity(),
      importer: (_, __, ___) async => throw StateError('private path'),
    );
    await controller.initialize();
    final package = File('${root.path}/aube.pokemapgame');
    await package.writeAsBytes(<int>[1]);

    await controller.importPackage(package);

    expect(controller.snapshot.status, HubDashboardStatus.error);
    expect(controller.snapshot.diagnostics.last.code, 'install.unexpected');
    expect(controller.snapshot.safeErrorMessage, isNot(contains(root.path)));
    controller.dispose();
  });

  test('installation failures persist their exact cause in the Hub log',
      () async {
    final log = File('${root.path}/logs/hub.log');
    final controller = HubDashboardController(
      libraryStore: libraryStore,
      activityReader: (_) async => const HubGameActivity(),
      diagnosticLogFile: log,
      importer: (_, __, ___) async {
        throw GameInstallationException(
          const GameInstallationDiagnostic(
            code: GameInstallationErrorCode.integrityFailed,
            stage: GameInstallStage.inspecting,
            retryable: true,
            repairSuggested: false,
          ),
          cause: FileSystemException(
            'Operation not permitted',
            '${root.path}/selbrume.pokemapgame',
            const OSError('Operation not permitted', 1),
          ),
        );
      },
    );
    await controller.initialize();
    final package = File('${root.path}/selbrume.pokemapgame');
    await package.writeAsBytes(<int>[1]);

    await controller.importPackage(package);

    final diagnostic = controller.snapshot.diagnostics.last;
    expect(diagnostic.code, 'install.integrityFailed');
    expect(diagnostic.technicalDetails, contains('Operation not permitted'));
    expect(diagnostic.technicalDetails, contains(package.path));
    expect(diagnostic.logPath, log.path);
    expect(await log.exists(), isTrue);
    final persisted = await log.readAsString();
    expect(persisted, contains('Operation not permitted'));
    expect(persisted, contains(package.path));
    controller.dispose();
  });

  test('file picker failures are visible and persisted before installation',
      () async {
    final log = File('${root.path}/logs/hub-import.log');
    final controller = HubDashboardController(
      libraryStore: libraryStore,
      activityReader: (_) async => const HubGameActivity(),
      diagnosticLogFile: log,
    );
    await controller.initialize();

    await controller.reportImportPickerFailure(
      code: 'importPicker.missingEntitlement',
      message: 'Le sélecteur de fichiers ne peut pas s’ouvrir.',
      recommendation: 'Fermez complètement le Hub puis relancez-le.',
      cause: StateError(
        'Missing com.apple.security.files.user-selected.read-only entitlement.',
      ),
      stackTrace: StackTrace.current,
    );

    final diagnostic = controller.snapshot.diagnostics.last;
    expect(controller.snapshot.status, HubDashboardStatus.error);
    expect(
      controller.snapshot.safeErrorMessage,
      'Le sélecteur de fichiers ne peut pas s’ouvrir.',
    );
    expect(diagnostic.code, 'importPicker.missingEntitlement');
    expect(diagnostic.recommendation, contains('relancez'));
    expect(
      diagnostic.technicalDetails,
      contains('com.apple.security.files.user-selected.read-only'),
    );
    expect(diagnostic.logPath, log.path);
    final persisted = await log.readAsString();
    expect(persisted, contains('"operation":"pickPackage"'));
    expect(persisted, contains('"code":"importPicker.missingEntitlement"'));
    controller.dispose();
  });

  test('rapid preference changes are persisted in order', () async {
    final preferences = HubPreferencesStore(supportRoot: root);
    final controller = HubDashboardController(
      libraryStore: libraryStore,
      activityReader: (_) async => const HubGameActivity(),
      preferencesStore: preferences,
    );
    await controller.initialize();
    final first =
        const PlayerPreferences().copyWith(language: PlayerLanguage.fr);
    final second =
        const PlayerPreferences().copyWith(language: PlayerLanguage.en);
    final last = second.copyWith(theme: PlayerThemePreference.dark);

    await Future.wait(<Future<void>>[
      controller.updatePreferences(first),
      controller.updatePreferences(second),
      controller.updatePreferences(last),
    ]);

    expect((await preferences.load()).preferences, last);
    controller.dispose();
  });
}

InstalledGame _game(String gameId, String title) {
  final version = InstalledGameVersion(
    gameVersion: Version.parse('1.0.0'),
    treeSha256: 'a' * 64,
    installedAt: DateTime.utc(2026, 7, 25),
    receiptFileName: '1.0.0-${'a' * 64}.json',
    source: GamePackageInstallSource.localFile,
    signatureStatus: PackageSignatureStatus.notPresent,
  );
  return InstalledGame(
    gameId: gameId,
    title: title,
    description: 'Une aventure',
    authorName: 'Studio',
    defaultLocale: 'fr',
    supportedLocales: <String>['fr'],
    current: version.pointer,
    versions: <InstalledGameVersion>[version],
  );
}
