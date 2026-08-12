import 'dart:async';
import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('presentation authoring', () {
    test('validates every media reference against the canonical asset catalog',
        () {
      final profile = _profile(
        branding: const ProjectBrandingProfile(
          iconPath: 'presentation/icon.png',
          titleMusicPath: 'presentation/title.png',
        ),
      );
      final result = const PresentationAuthoringGate().inspect(
        profile,
        _catalog(),
      );

      expect(result.canPublish, isFalse);
      expect(
        result.diagnostics.map((diagnostic) => diagnostic.code),
        contains('presentationAssetMediaTypeMismatch'),
      );
      expect(
        result.diagnostics
            .where(
                (diagnostic) => diagnostic.code == 'presentationAssetMissing')
            .map((diagnostic) => diagnostic.path),
        contains(r'$.presentation.typography.body.licensePath'),
      );
    });

    test('editor adapter and mutation gate share the same projected state', () {
      final profile = _profile();
      final manifest = ProjectManifest(
        name: 'Presentation fixture',
        maps: const [],
        tilesets: const [],
      );
      final result = const ProjectPresentationEditorAdapter().prepare(
        manifest: manifest,
        profile: profile,
        assets: _catalog(includeLicense: true),
      );

      expect(result.canApply, isTrue);
      expect(result.projectedManifest.presentation, profile);
      expect(
        result.diagnostics,
        const PresentationAuthoringGate()
            .inspect(profile, _catalog(includeLicense: true))
            .diagnostics,
      );
    });

    test('preview handles are revision-bound and reject stale consumption', () {
      final preview = const PresentationPreviewService().create(
        profile: _profile(),
        projectRevision: _revision('a'),
        assets: _catalog(includeLicense: true),
      );

      expect(preview.assetHandles, hasLength(6));
      expect(preview.previewId, startsWith('presentation-preview:'));
      preview.requireRevision(_revision('a'));
      expect(
        () => preview.requireRevision(_revision('b')),
        throwsA(
          isA<PresentationAuthoringException>().having(
            (error) => error.code,
            'code',
            'presentation.preview_stale',
          ),
        ),
      );
    });

    test('media processing jobs are asynchronous and idempotent', () async {
      final processing = Completer<MediaProcessingResult>();
      final port = InMemoryMediaProcessingPort(
        processor: (request) => processing.future,
      );
      final request = MediaProcessingRequest(
        idempotencyKey: 'intro-transcode-1',
        kind: MediaProcessingKind.transcodeVideo,
        source: _artifact('video/mp4', 42),
        expectedProjectRevision: _revision('c'),
        targetMediaType: 'video/webm',
      );

      final first = await port.submit(request);
      final duplicate = await port.submit(request);
      expect(first.status, MediaProcessingStatus.queued);
      expect(duplicate.jobId, first.jobId);

      processing.complete(
        MediaProcessingResult(
          output: _artifact('video/webm', 43),
          metadata: const {'videoCodec': 'vp9'},
        ),
      );
      final completed = await port.wait(first.jobId);
      expect(completed.status, MediaProcessingStatus.succeeded);
      expect(completed.result?.output.mediaType, 'video/webm');
    });

    test('dispatcher exposes canonical presentation mutations', () {
      final ids = MapMutationDispatcher.canonical()
          .descriptors
          .map((descriptor) => descriptor.id)
          .toSet();

      expect(ids, containsAll({'presentation.update', 'presentation.delete'}));
    });

    test('presentation.update carries project-owned pause actions', () {
      const profile = ProjectPresentationProfile(
        pause: ProjectPausePresentationProfile(
          title: 'Interlude',
          actions: <ProjectPauseActionProfile>[
            ProjectPauseActionProfile(
              id: ProjectPauseActionId.pokedex,
              label: 'Carnet',
              icon: ProjectPauseActionIcon.book,
            ),
            ProjectPauseActionProfile(
              id: ProjectPauseActionId.resume,
              icon: ProjectPauseActionIcon.play,
            ),
          ],
        ),
      );
      final snapshot = _snapshot();
      final request = AuthoringRequest(
        requestId: 'request_presentation_labels',
        actionId: 'presentation.update',
        actionVersion: 1,
        workspaceHandle: 'ws_test',
        parameters: <String, Object?>{'profile': profile.toJson()},
        expectedRevision: snapshot.revision,
        idempotencyKey: 'presentation-labels',
        dryRun: true,
      );

      final draft = const PresentationActions().build(
        AuthoringPlanningContext(
          snapshot: snapshot,
          request: request,
          planId: 'plan_presentation_labels',
          seed: 42,
        ),
      );

      expect(
        draft.preview['profile'],
        containsPair(
          'pause',
          containsPair('title', 'Interlude'),
        ),
      );
      expect(
        draft.changeSet.diff.entries.single.after,
        containsPair(
          'pause',
          containsPair(
            'actions',
            contains(containsPair('label', 'Carnet')),
          ),
        ),
      );
    });

    test('presentation.update carries validated project window styles', () {
      final profile = ProjectPresentationProfile(
        windows: legacyProjectPresentationWindows.copyWith(
          battleStyleId: 'default',
        ),
      );
      final snapshot = _snapshot();
      final request = AuthoringRequest(
        requestId: 'request_presentation_windows',
        actionId: 'presentation.update',
        actionVersion: 1,
        workspaceHandle: 'ws_test',
        parameters: <String, Object?>{'profile': profile.toJson()},
        expectedRevision: snapshot.revision,
        idempotencyKey: 'presentation-windows',
        dryRun: true,
      );

      final draft = const PresentationActions().build(
        AuthoringPlanningContext(
          snapshot: snapshot,
          request: request,
          planId: 'plan_presentation_windows',
          seed: 42,
        ),
      );

      expect(
        draft.preview['profile'],
        containsPair(
          'windows',
          containsPair('pauseMenuStyleId', 'pause-menu'),
        ),
      );
      expect(
        draft.changeSet.diff.entries.single.after,
        containsPair(
          'windows',
          containsPair('dialogueStyleId', 'dialogue'),
        ),
      );
      expect(
        draft.preview['profile'],
        containsPair(
          'windows',
          containsPair('battleStyleId', 'default'),
        ),
      );
    });

    test('presentation.update carries complete V9 dialogue geometry', () {
      const profile = ProjectPresentationProfile(
        dialogue: ProjectDialoguePresentationProfile(
          placement: ProjectDialoguePlacement.top,
          maxWidthFactor: .64,
          margin: 20,
          contentPadding: 24,
          shape: ProjectWindowShape.speech,
          cornerRadius: 18,
          borderWidth: 3,
          fillOpacity: .82,
          surfaceColor: '#102030',
          borderColor: '#A0B0C0',
          textColor: '#F0F0F0',
          portraitSide: ProjectDialoguePortraitSide.end,
          portraitSize: 112,
          portraitShape: ProjectDialoguePortraitShape.circle,
          portraitFrameWidth: 4,
          portraitFrameColor: '#C0FFEE',
          nameplateStyle: ProjectDialogueNameplateStyle.floating,
          nameplateBorderWidth: 2,
          nameplateSurfaceColor: '#334455',
          nameplateBorderColor: '#778899',
          nameplateTextColor: '#FFFFFF',
          choiceSpacing: 14,
          choiceShape: ProjectDialogueChoiceShape.cutCorner,
          choiceDisabledOpacity: .35,
          choiceSelectedColor: '#FFAA00',
          progressIndicator: ProjectDialogueProgressIndicator.dots,
          progressIndicatorColor: '#00FFAA',
          portraitTransition: ProjectDialoguePortraitTransition.slide,
          portraitTransitionMilliseconds: 320,
        ),
      );
      final snapshot = _snapshot();
      final request = AuthoringRequest(
        requestId: 'request_presentation_dialogue',
        actionId: 'presentation.update',
        actionVersion: 1,
        workspaceHandle: 'ws_test',
        parameters: <String, Object?>{'profile': profile.toJson()},
        expectedRevision: snapshot.revision,
        idempotencyKey: 'presentation-dialogue',
        dryRun: true,
      );

      final draft = const PresentationActions().build(
        AuthoringPlanningContext(
          snapshot: snapshot,
          request: request,
          planId: 'plan_presentation_dialogue',
          seed: 42,
        ),
      );

      expect(
        draft.preview['profile'],
        containsPair(
          'dialogue',
          containsPair('placement', 'top'),
        ),
      );
      expect(
        draft.changeSet.diff.entries.single.after,
        containsPair(
          'dialogue',
          containsPair('surfaceColor', '#102030'),
        ),
      );
      expect(
        (draft.preview['profile']! as Map)['dialogue'],
        containsPair('portraitSide', 'end'),
      );
      expect(
        (draft.preview['profile']! as Map)['dialogue'],
        containsPair('nameplateStyle', 'floating'),
      );
      expect(
        (draft.preview['profile']! as Map)['dialogue'],
        containsPair('choiceShape', 'cutCorner'),
      );
      expect(
        (draft.preview['profile']! as Map)['dialogue'],
        containsPair('portraitTransition', 'slide'),
      );
    });

    test('presentation.update carries the complete V10 battle contract', () {
      const profile = ProjectPresentationProfile(
        battle: ProjectBattlePresentationProfile(
          commandLayout: ProjectBattleCommandLayout.radial,
          commandColumns: 2,
          commandShape: ProjectWindowShape.cutCorner,
          commandSelectionColor: '#00CCAA',
          commands: <ProjectBattleCommandProfile>[
            ProjectBattleCommandProfile(
              id: ProjectBattleCommandId.run,
              label: 'Retraite',
              icon: ProjectBattleCommandIcon.run,
            ),
            ProjectBattleCommandProfile(id: ProjectBattleCommandId.fight),
            ProjectBattleCommandProfile(id: ProjectBattleCommandId.party),
            ProjectBattleCommandProfile(id: ProjectBattleCommandId.bag),
          ],
          enemyHudPosition: ProjectBattleHudPosition.topEnd,
          playerHudPosition: ProjectBattleHudPosition.bottomStart,
          hpBarShape: ProjectBattleHpBarShape.segmented,
          moves: ProjectBattlePanelPresentationProfile(
            surfaceColor: '#102030',
          ),
          target: ProjectBattlePanelPresentationProfile(
            surfaceColor: '#203040',
          ),
          message: ProjectBattlePanelPresentationProfile(
            surfaceColor: '#304050',
          ),
        ),
      );
      final snapshot = _snapshot();
      final request = AuthoringRequest(
        requestId: 'request_presentation_battle_v10',
        actionId: 'presentation.update',
        actionVersion: 1,
        workspaceHandle: 'ws_test',
        parameters: <String, Object?>{'profile': profile.toJson()},
        expectedRevision: snapshot.revision,
        idempotencyKey: 'presentation-battle-v10',
        dryRun: true,
      );

      final draft = const PresentationActions().build(
        AuthoringPlanningContext(
          snapshot: snapshot,
          request: request,
          planId: 'plan_presentation_battle_v10',
          seed: 42,
        ),
      );
      final battle = (draft.preview['profile']! as Map)['battle']! as Map;

      expect(battle['commandLayout'], 'radial');
      expect((battle['commands']! as List).first, containsPair('id', 'run'));
      expect(battle['enemyHudPosition'], 'topEnd');
      expect((battle['moves']! as Map)['surfaceColor'], '#102030');
      expect(draft.changeSet.diff.entries.single.after,
          containsPair('battle', battle));
    });

    test('presentation.update carries responsive surface layouts', () {
      final profile = ProjectPresentationProfile(
        layouts: suggestedProjectPresentationLayouts('cinematic'),
      );
      final snapshot = _snapshot();
      final request = AuthoringRequest(
        requestId: 'request_presentation_layouts',
        actionId: 'presentation.update',
        actionVersion: 1,
        workspaceHandle: 'ws_test',
        parameters: <String, Object?>{'profile': profile.toJson()},
        expectedRevision: snapshot.revision,
        idempotencyKey: 'presentation-layouts',
        dryRun: true,
      );

      final draft = const PresentationActions().build(
        AuthoringPlanningContext(
          snapshot: snapshot,
          request: request,
          planId: 'plan_presentation_layouts',
          seed: 42,
        ),
      );

      expect(
        draft.preview['profile'],
        containsPair(
          'layouts',
          containsPair(
            'title',
            containsPair(
              'expanded',
              containsPair('slot', 'bottomLeft'),
            ),
          ),
        ),
      );
      expect(
        draft.preview['profile'],
        containsPair(
          'layouts',
          containsPair(
            'battle',
            containsPair(
              'expanded',
              containsPair('slot', 'bottomCenter'),
            ),
          ),
        ),
      );
    });

    test('presentation.update carries combat typography', () {
      const profile = ProjectPresentationProfile(
        typography: ProjectTypographyProfile(
          combat: ProjectTypographyRoleProfile(family: 'Battle Mono'),
        ),
      );
      final snapshot = _snapshot();
      final request = AuthoringRequest(
        requestId: 'request_presentation_combat_typography',
        actionId: 'presentation.update',
        actionVersion: 1,
        workspaceHandle: 'ws_test',
        parameters: <String, Object?>{'profile': profile.toJson()},
        expectedRevision: snapshot.revision,
        idempotencyKey: 'presentation-combat-typography',
        dryRun: true,
      );

      final draft = const PresentationActions().build(
        AuthoringPlanningContext(
          snapshot: snapshot,
          request: request,
          planId: 'plan_presentation_combat_typography',
          seed: 42,
        ),
      );

      expect(
        draft.preview['profile'],
        containsPair(
          'typography',
          containsPair(
            'combat',
            containsPair('family', 'Battle Mono'),
          ),
        ),
      );
    });

    test('presentation.update carries V7 title copy and visual contract', () {
      final profile = ProjectPresentationProfile(
        title: const ProjectTitlePresentationProfile(
          title: 'Aube sur Hanazuki',
          subtitle: 'Studio Brume',
          prompt: 'Appuyez pour commencer',
          actions: <ProjectTitleActionProfile>[
            ProjectTitleActionProfile(
              id: ProjectTitleActionId.newGame,
              label: 'Commencer',
              icon: ProjectTitleActionIcon.sparkles,
            ),
            ProjectTitleActionProfile(
              id: ProjectTitleActionId.options,
              visible: false,
            ),
          ],
        ),
        typography: const ProjectTypographyProfile(
          dialogue: ProjectTypographyRoleProfile(
            metrics: ProjectTypographyMetricsProfile(
              sizeScale: 1.1,
              weight: 600,
              lineHeight: 1.4,
              letterSpacing: .5,
            ),
          ),
        ),
        surfacePalettes: const ProjectPresentationSurfacePalettesProfile(
          dialogue: ProjectSurfacePaletteProfile(
            surface: '#102030',
            border: '#63E6FF',
            text: '#FFFFFF',
            accent: '#63E6FF',
          ),
        ),
        windows: legacyProjectPresentationWindows.copyWith(
          styles: <ProjectWindowStyleProfile>[
            for (final style in legacyProjectPresentationWindows.styles)
              if (style.id == 'dialogue')
                style.copyWith(
                  shape: ProjectWindowShape.speech,
                  fillOpacity: .85,
                )
              else
                style,
          ],
        ),
      );
      final snapshot = _snapshot();
      final request = AuthoringRequest(
        requestId: 'request_presentation_v6_visual_contract',
        actionId: 'presentation.update',
        actionVersion: 1,
        workspaceHandle: 'ws_test',
        parameters: <String, Object?>{'profile': profile.toJson()},
        expectedRevision: snapshot.revision,
        idempotencyKey: 'presentation-v6-visual-contract',
        dryRun: true,
      );

      final draft = const PresentationActions().build(
        AuthoringPlanningContext(
          snapshot: snapshot,
          request: request,
          planId: 'plan_presentation_v6_visual_contract',
          seed: 42,
        ),
      );
      final projected = draft.preview['profile']! as Map<String, Object?>;
      final title = projected['title']! as Map<String, Object?>;
      final typography = projected['typography']! as Map<String, Object?>;
      final dialogue = typography['dialogue']! as Map<String, Object?>;
      final metrics = dialogue['metrics']! as Map<String, Object?>;
      final palettes = projected['surfacePalettes']! as Map<String, Object?>;
      final dialoguePalette = palettes['dialogue']! as Map<String, Object?>;
      final windows = projected['windows']! as Map<String, Object?>;
      final styles = windows['styles']! as List<Object?>;
      final dialogueStyle = styles.cast<Map<String, Object?>>().firstWhere(
            (style) => style['id'] == 'dialogue',
          );

      expect(metrics['weight'], 600);
      expect(title['title'], 'Aube sur Hanazuki');
      expect(title['subtitle'], 'Studio Brume');
      expect(title['prompt'], 'Appuyez pour commencer');
      final titleActions = title['actions']! as List<Object?>;
      expect(
        titleActions.cast<Map<String, Object?>>().first['id'],
        'newGame',
      );
      expect(
        titleActions.cast<Map<String, Object?>>().last['visible'],
        isFalse,
      );
      expect(dialoguePalette['surface'], '#102030');
      expect(dialogueStyle['shape'], 'speech');
      expect(dialogueStyle['fillOpacity'], .85);
    });

    test('validates every authored responsive intro and title loop asset', () {
      final profile = _profile().copyWith(
        titleMotion: const ProjectTitleMotionProfile(
          promptLoop: ProjectResponsiveVideoProfile(
            landscape: ProjectVideoVariantProfile(
              videoPath: 'presentation/prompt-landscape.mp4',
              posterPath: 'presentation/prompt-landscape.png',
              durationMilliseconds: 7000,
              width: 1920,
              height: 1080,
              bitrateKbps: 3000,
              sizeBytes: 6000000,
              videoCodec: 'h264',
              audioCodec: 'none',
            ),
            portrait: ProjectVideoVariantProfile(
              videoPath: 'presentation/prompt-portrait.mp4',
              posterPath: 'presentation/prompt-portrait.png',
              durationMilliseconds: 7000,
              width: 1080,
              height: 1920,
              bitrateKbps: 3000,
              sizeBytes: 6000000,
              videoCodec: 'h264',
              audioCodec: 'none',
            ),
          ),
        ),
      );

      final result = const PresentationAuthoringGate().inspect(
        profile,
        _catalog(includeLicense: true, includeMotion: true),
      );

      expect(result.canPublish, isTrue);
      final preview = const PresentationPreviewService().create(
        profile: profile,
        projectRevision: _revision('d'),
        assets: _catalog(includeLicense: true, includeMotion: true),
      );
      expect(
        preview.assetHandles,
        containsAll(<String>[
          _catalog(includeMotion: true)
              .records
              .singleWhere((asset) => asset.id == 'prompt-landscape')
              .artifact
              .handle,
          _catalog(includeMotion: true)
              .records
              .singleWhere((asset) => asset.id == 'prompt-portrait')
              .artifact
              .handle,
        ]),
      );
    });
  });
}

ProjectPresentationProfile _profile({ProjectBrandingProfile? branding}) =>
    ProjectPresentationProfile(
      branding: branding ??
          const ProjectBrandingProfile(
            iconPath: 'presentation/icon.png',
            titleMusicPath: 'presentation/title.ogg',
          ),
      intro: const ProjectIntroVideoProfile(
        media: ProjectResponsiveVideoProfile(
          landscape: ProjectVideoVariantProfile(
            videoPath: 'presentation/intro.mp4',
            posterPath: 'presentation/poster.png',
            durationMilliseconds: 3000,
            width: 1280,
            height: 720,
            bitrateKbps: 4000,
            sizeBytes: 42,
            videoCodec: 'h264',
            audioCodec: 'aac',
          ),
        ),
      ),
      typography: const ProjectTypographyProfile(
        body: ProjectTypographyRoleProfile(
          fontPath: 'presentation/body.ttf',
          family: 'Fixture Sans',
          licensePath: 'presentation/body-license.txt',
          redistributable: true,
          fallbackFamilies: ['sans-serif'],
          glyphCoverage: ['latin', 'latinExtended', 'digits', 'punctuation'],
        ),
      ),
      theme: safeProjectSemanticTheme,
    );

ProjectSnapshot _snapshot() {
  final manifest = ProjectManifest(
    name: 'Presentation fixture',
    maps: const [],
    tilesets: const [],
  );
  final bytes = utf8.encode(jsonEncode(manifest.toJson()));
  final revision =
      computeNarrativeProjectFingerprint(<NarrativeProjectFingerprintEntry>[
    NarrativeProjectFingerprintEntry(
      relativePath: 'project.json',
      bytes: bytes,
    ),
  ]);
  return ProjectSnapshot(
    projectHandle: const ProjectHandle('prj_test'),
    revision: revision,
    manifest: manifest,
    maps: const [],
    resourceFingerprints: <String, String>{'project': revision},
    resourceBytes: <String, List<int>>{'project': bytes},
  );
}

AssetCatalog _catalog({
  bool includeLicense = false,
  bool includeMotion = false,
}) =>
    AssetCatalog(records: [
      _asset('icon', 'presentation/icon.png', 'image/png', 1),
      _asset('wrong-music', 'presentation/title.png', 'image/png', 7),
      _asset('music', 'presentation/title.ogg', 'audio/ogg', 2),
      _asset('intro', 'presentation/intro.mp4', 'video/mp4', 3),
      _asset('poster', 'presentation/poster.png', 'image/png', 4),
      if (includeMotion) ...<AssetRecord>[
        _asset(
          'prompt-landscape',
          'presentation/prompt-landscape.mp4',
          'video/mp4',
          8,
        ),
        _asset(
          'prompt-landscape-poster',
          'presentation/prompt-landscape.png',
          'image/png',
          9,
        ),
        _asset(
          'prompt-portrait',
          'presentation/prompt-portrait.mp4',
          'video/mp4',
          10,
        ),
        _asset(
          'prompt-portrait-poster',
          'presentation/prompt-portrait.png',
          'image/png',
          11,
        ),
      ],
      _asset('font', 'presentation/body.ttf', 'font/ttf', 5),
      if (includeLicense)
        _asset(
          'font-license',
          'presentation/body-license.txt',
          'text/plain',
          6,
        ),
    ]);

AssetRecord _asset(String id, String path, String mediaType, int byte) =>
    AssetRecord(
      id: id,
      logicalPath: path,
      artifact: _artifact(mediaType, byte),
    );

ContentArtifactRef _artifact(String mediaType, int byte) =>
    ContentArtifactRef.fromBytes([byte], mediaType: mediaType);

String _revision(String digit) => 'sha256:${List.filled(64, digit).join()}';
