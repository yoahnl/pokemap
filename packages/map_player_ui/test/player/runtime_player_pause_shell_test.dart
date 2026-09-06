import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  for (final size in [
    const Size(1440, 900),
    const Size(390, 844),
    const Size(844, 390)
  ]) {
    testWidgets(
        'illustrated shared shell preserves resume with missing media $size',
        (tester) async {
      await _setSurface(tester, size);
      PlayerPauseAction? selected;
      await tester.pumpWidget(_app(RuntimePlayerPauseShell.root(
          gameTitle: 'Voyage',
          actions: _actions(),
          onSelected: (action) => selected = action,
          detail: const Text('Contenu existant'),
          presentation: const PlayerPausePresentation(
              style: ProjectPauseMenuStyle.nightIllustrated,
              background: ProjectPauseBackgroundProfile(
                  imagePath: 'assets/missing.png')))));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('runtime-night-illustrated-frame')),
          findsOneWidget);
      expect(find.text('Voyage'), findsOneWidget);
      expect(find.text('Reprendre'), findsOneWidget);
      expect(find.byType(PlayerEmptyState), findsNothing);
      expect(find.byKey(const ValueKey('pause.resume')), findsNothing);
      expect(find.byKey(const ValueKey('runtime-player-actions-context')),
          findsOneWidget);
      expect(find.text('Fond du menu indisponible.'), findsOneWidget);
      await tester
          .tap(find.byKey(const ValueKey('pause-frame-return-surface')));
      expect(selected, PlayerPauseAction.resume);
    });
  }

  testWidgets('illustrated footer respects pending resume availability',
      (tester) async {
    await _setSurface(tester, const Size(1440, 900));
    var commands = 0;
    await tester.pumpWidget(_app(RuntimePlayerPauseShell.root(
        gameTitle: 'Voyage',
        actions: {
          ..._actions(),
          PlayerPauseAction.resume:
              const PlayerActionAvailability.disabled('Enregistrement')
        },
        onSelected: (_) => commands++,
        detail: const SizedBox(),
        presentation: const PlayerPausePresentation(
            style: ProjectPauseMenuStyle.nightIllustrated))));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('pause-frame-return-surface')));
    expect(commands, 0);
  });

  testWidgets('illustrated header and body use the outer landscape composition',
      (tester) async {
    await _setSurface(tester, const Size(844, 390));
    await tester.pumpWidget(_app(RuntimePlayerPauseShell.root(
      gameTitle: 'Voyage',
      actions: _actions(),
      onSelected: (_) {},
      detail: const Text('Résumé du voyage'),
      presentation: const PlayerPausePresentation(
        style: ProjectPauseMenuStyle.nightIllustrated,
        title: 'Titre auteur',
        composition: ProjectResponsivePauseCompositionProfile(
          compactPortrait:
              ProjectPauseCompositionVariantProfile(showTitle: true),
          compactLandscape: ProjectPauseCompositionVariantProfile(
            showTitle: false,
            showRootDetailPanel: false,
          ),
        ),
      ),
    )));
    await tester.pumpAndSettle();
    expect(find.text('Titre auteur'), findsNothing);
    expect(find.byKey(const ValueKey('runtime-pause-layout-compactLandscape')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('runtime-menu-background-unavailable')),
        findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('illustrated root preserves explicitly enabled authored detail',
      (tester) async {
    await _setSurface(tester, const Size(1440, 900));
    await tester.pumpWidget(_app(RuntimePlayerPauseShell.root(
      gameTitle: 'Voyage',
      actions: _actions(),
      onSelected: (_) {},
      detail: const Text('Résumé du voyage'),
      presentation: const PlayerPausePresentation(
        style: ProjectPauseMenuStyle.nightIllustrated,
        title: 'Titre auteur',
        composition: ProjectResponsivePauseCompositionProfile(),
      ),
    )));
    await tester.pumpAndSettle();
    expect(find.text('Titre auteur'), findsOneWidget);
    expect(find.text('Résumé du voyage'), findsOneWidget);
    expect(find.byType(PlayerEmptyState), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('illustrated authored narrow layout applies width only once',
      (tester) async {
    await _setSurface(tester, const Size(1280, 720));
    final base = suggestedProjectPresentationLayouts('standard');
    final layouts = base.copyWith(
        pauseMenu: base.pauseMenu.copyWith(
      expanded: base.pauseMenu.expanded.copyWith(
        width: ProjectPresentationContentWidth.narrow,
        spacing: ProjectPresentationSpacing.airy,
      ),
    ));
    await tester.pumpWidget(_app(
        RuntimePlayerPauseShell.root(
          gameTitle: 'Voyage',
          actions: _actions(),
          onSelected: (_) {},
          detail: const Text('Résumé du voyage'),
          presentation: const PlayerPausePresentation(
            style: ProjectPauseMenuStyle.nightIllustrated,
            composition: ProjectResponsivePauseCompositionProfile(),
          ),
        ),
        layouts: layouts));
    await tester.pumpAndSettle();
    expect(find.text('Résumé du voyage'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('illustrated detail has one title and one working return',
      (tester) async {
    await _setSurface(tester, const Size(390, 844));
    var returns = 0;
    await tester.pumpWidget(_app(RuntimePlayerPauseShell(
      gameTitle: 'Voyage',
      pauseSection: RuntimePlayerPauseSection.party,
      actions: _actions(),
      onSelected: (_) {},
      onBackToRoot: () => returns++,
      detailTitle: 'Compagnons',
      detail: const Text('Contenu de l’équipe'),
      presentation: const PlayerPausePresentation(
          style: ProjectPauseMenuStyle.nightIllustrated),
    )));
    await tester.pumpAndSettle();
    expect(find.text('Compagnons'), findsOneWidget);
    expect(find.text('Contenu de l’équipe'), findsOneWidget);
    expect(
        find.byKey(const ValueKey('runtime-pause-back-to-root')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('pause-frame-return-surface')));
    expect(returns, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('illustrated footer retains logical controller resume identity',
      (tester) async {
    await _setSurface(tester, const Size(1440, 900));
    final focus = RuntimePlayerFocusController(
        logicalSelectionId: 'pause.resume',
        activeInputSource: PlayerInputSource.controller);
    addTearDown(focus.dispose);
    final selected = <PlayerPauseAction>[];
    await tester.pumpWidget(_app(RuntimePlayerPauseShell.root(
      gameTitle: 'Voyage',
      actions: _actions(),
      onSelected: selected.add,
      detail: const SizedBox.shrink(),
      focusController: focus,
      logicalSelectionId: 'pause.resume',
      presentation: const PlayerPausePresentation(
          style: ProjectPauseMenuStyle.nightIllustrated,
          actionLabels: {PlayerPauseAction.resume: 'Poursuivre'}),
    )));
    await tester.pumpAndSettle();
    expect(focus.logicalSelectionId, 'pause.resume');
    expect(
        FocusManager.instance.primaryFocus?.debugLabel, contains('Poursuivre'));
    Actions.invoke(
      tester.element(
          find.byKey(const ValueKey('runtime-player-actions-context'))),
      const RuntimePlayerLogicalIntent(PlayerInputAction.confirm,
          source: PlayerInputSource.controller),
    );
    await tester.pump();
    expect(selected, [PlayerPauseAction.resume]);
  });

  testWidgets('corrupt illustrated background reports failure and keeps return',
      (tester) async {
    await _setSurface(tester, const Size(390, 844));
    PlayerPauseAction? selected;
    await tester.pumpWidget(_app(RuntimePlayerPauseShell.root(
      gameTitle: 'Voyage',
      actions: _actions(),
      onSelected: (action) => selected = action,
      detail: const SizedBox.shrink(),
      presentation: PlayerPausePresentation(
        style: ProjectPauseMenuStyle.nightIllustrated,
        background:
            const ProjectPauseBackgroundProfile(imagePath: 'broken.png'),
        backgroundImage: MemoryImage(Uint8List.fromList([137, 80, 78, 71])),
      ),
    )));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('runtime-menu-background-fallback')),
        findsOneWidget);
    expect(find.text('Fond du menu indisponible.'), findsOneWidget);
    final diagnostic = tester.widget<Semantics>(
        find.byKey(const ValueKey('runtime-menu-background-unavailable')));
    expect(diagnostic.properties.liveRegion, isTrue);
    await tester.tap(find.byKey(const ValueKey('pause-frame-return-surface')));
    expect(selected, PlayerPauseAction.resume);
    expect(tester.takeException(), isNull);
    final recoveredBytes = await tester.runAsync(() async {
      final recorder = ui.PictureRecorder();
      Canvas(recorder).drawColor(const Color(0xFF204060), BlendMode.src);
      final picture = recorder.endRecording();
      final image = await picture.toImage(1, 1);
      final png = (await image.toByteData(format: ui.ImageByteFormat.png))!;
      image.dispose();
      picture.dispose();
      return png.buffer.asUint8List();
    });
    await tester.pumpWidget(_app(RuntimePlayerPauseShell.root(
      gameTitle: 'Voyage',
      actions: _actions(),
      onSelected: (action) => selected = action,
      detail: const SizedBox.shrink(),
      presentation: PlayerPausePresentation(
        style: ProjectPauseMenuStyle.nightIllustrated,
        background: const ProjectPauseBackgroundProfile(imagePath: 'fixed.png'),
        backgroundImage: MemoryImage(recoveredBytes!),
      ),
    )));
    final recovered = await _waitForMenuImage(tester);
    expect(recovered.width, 1);
    expect(recovered.height, 1);
    expect(find.byKey(const ValueKey('runtime-menu-background-unavailable')),
        findsNothing);
    expect(find.byKey(const ValueKey('runtime-menu-background-fallback')),
        findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'illustrated background decodes within its viewport budget without distortion',
      (tester) async {
    await _setSurface(tester, const Size(3840, 2160));
    final baselineLiveImages =
        PaintingBinding.instance.imageCache.liveImageCount;
    final bytes = await tester.runAsync(() async {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawColor(const Color(0xFF204060), BlendMode.src);
      final picture = recorder.endRecording();
      final source = await picture.toImage(4096, 2048);
      final png = (await source.toByteData(format: ui.ImageByteFormat.png))!;
      source.dispose();
      picture.dispose();
      return png.buffer.asUint8List();
    });
    await tester.pumpWidget(_app(RuntimePlayerPauseShell.root(
      gameTitle: 'Voyage',
      actions: _actions(),
      onSelected: (_) {},
      detail: const SizedBox.shrink(),
      presentation: PlayerPausePresentation(
        style: ProjectPauseMenuStyle.nightIllustrated,
        background: const ProjectPauseBackgroundProfile(
            imagePath: 'panorama.png',
            focalX: .8,
            sampling: ProjectMenuImageSampling.pixelArt),
        backgroundImage: MemoryImage(bytes!),
      ),
    )));
    final imageWidget = tester
        .widget<Image>(find.byKey(const ValueKey('runtime-menu-background')));
    expect(imageWidget.fit, BoxFit.cover);
    expect((imageWidget.alignment as Alignment).x, closeTo(.6, .001));
    expect(imageWidget.filterQuality, FilterQuality.none);
    final provider = imageWidget.image as ResizeImage;
    expect(provider.width, 1920);
    expect(provider.height, 1080);
    expect(provider.policy, ResizeImagePolicy.fit);
    final decoded = await _waitForMenuImage(tester);
    expect(Size(decoded.width.toDouble(), decoded.height.toDouble()),
        const Size(1920, 960));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(
        PaintingBinding.instance.imageCache.liveImageCount, baselineLiveImages);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pause preview refuses unavailable quests', (tester) async {
    await _setSurface(tester, const Size(390, 844));
    PlayerPauseAction? selected;
    const reason = 'Le journal de quêtes n’est pas encore disponible.';
    await tester.pumpWidget(_app(PlayerPausePreviewShell(
      gameTitle: 'Aube',
      actions: <PlayerPauseAction, PlayerActionAvailability>{
        ..._actions(),
        PlayerPauseAction.quests:
            const PlayerActionAvailability.disabled(reason),
      },
      presentation: const PlayerPausePresentation(),
      details: const <PlayerPauseAction, PlayerPausePreviewDetailData>{
        PlayerPauseAction.quests: PlayerPausePreviewDetailData(
          action: PlayerPauseAction.quests,
          title: 'Quêtes',
          message: 'Aucun moteur disponible',
        ),
      },
      onSelected: (action) => selected = action,
    )));
    final button = find.byKey(const ValueKey<String>('pause.quests'));
    await tester.ensureVisible(button);
    final control = tester.widget<PlayerActionButton>(button);
    expect(control.onPressed, isNull);
    expect(control.disabledReason, reason);
    await tester.tap(button);
    await tester.pump();
    expect(selected, isNull);
    expect(
        find.byKey(
            const ValueKey<String>('player-pause-preview-detail-quests')),
        findsNothing);
  });

  for (final size in [const Size(1440, 900), const Size(390, 844)]) {
    testWidgets('pause preview renders typed Pokédex and profile at $size',
        (tester) async {
      await _setSurface(tester, size);
      final selected = <PlayerPauseAction>[];
      await tester.pumpWidget(_app(PlayerPausePreviewShell(
        gameTitle: 'Aube',
        actions: _actions(),
        presentation: const PlayerPausePresentation(
            style: ProjectPauseMenuStyle.nightIllustrated),
        details: {
          PlayerPauseAction.pokedex: PlayerPausePreviewDetailData(
            action: PlayerPauseAction.pokedex,
            title: 'Pokédex',
            message: 'Catalogue de démonstration.',
            entries: [
              PlayerPausePreviewEntryData(
                id: 'preview.species.133',
                title: 'Évoli',
                pokedexEntry: RuntimePlayerPokedexEntrySnapshot(
                  knowledge: RuntimePlayerPokedexKnowledge.caught,
                  nationalDex: 133,
                  typeIds: ['normal'],
                  description: 'Son évolution réserve bien des surprises.',
                ),
              ),
              PlayerPausePreviewEntryData(
                id: 'preview.species.secret',
                title: 'Nom privé du catalogue',
                pokedexEntry: RuntimePlayerPokedexEntrySnapshot(
                  knowledge: RuntimePlayerPokedexKnowledge.unknown,
                  nationalDex: 151,
                ),
              ),
            ],
          ),
          PlayerPauseAction.profile:
              PlayerPausePreviewDetailData.demonstrationProfile(),
        },
        onSelected: selected.add,
      )));
      await tester.pumpAndSettle();
      await _tapPreviewControl(tester, 'pause.pokedex');
      expect(find.byKey(const ValueKey('pokedex-search')), findsOneWidget);
      expect(find.text('Évoli'), findsWidgets);
      expect(find.text('Nom privé du catalogue'), findsNothing);
      expect(find.text('preview.species.133'), findsNothing);
      expect(tester.takeException(), isNull);

      await tester.enterText(
          find.byKey(const ValueKey('pokedex-search')), 'evo');
      await tester.pump();
      await _tapPreviewControl(tester, 'pokedex-entry-preview.species.133');
      expect(find.text('Son évolution réserve bien des surprises.'),
          findsOneWidget);
      expect(find.text('#133 · Capturé'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _tapPreviewControl(tester, 'pause-frame-return-surface');
      if (size.width < size.height) {
        expect(find.byKey(const ValueKey('pokedex-search')), findsOneWidget);
        expect(
            find.byKey(const ValueKey('player-pause-preview-detail-pokedex')),
            findsOneWidget);
        await _tapPreviewControl(tester, 'pause-frame-return-surface');
      }
      expect(find.byKey(const ValueKey('pokedex-search')), findsNothing);
      await _tapPreviewControl(tester, 'pause.pokedex');
      expect(
          tester
              .widget<TextField>(find.byKey(const ValueKey('pokedex-search')))
              .controller!
              .text,
          'evo');
      expect(
          tester
              .widget<PlayerMenuSelectableRow>(find
                  .byKey(const ValueKey('pokedex-entry-preview.species.133')))
              .selected,
          isTrue);
      await _tapPreviewControl(tester, 'pause-frame-return-surface');
      await _tapPreviewControl(tester, 'pause.profile');
      expect(find.text('Camille'), findsOneWidget);
      expect(find.text('Village de démonstration'), findsOneWidget);
      expect(find.text('preview-village'), findsNothing);
      expect(find.text('Aperçu uniquement'), findsOneWidget);
      expect(
          tester
              .widget<RuntimePlayerPauseShell>(
                  find.byType(RuntimePlayerPauseShell))
              .detailOwnsScroll,
          isTrue);
      expect(tester.takeException(), isNull);
      expect(selected, [
        PlayerPauseAction.pokedex,
        PlayerPauseAction.pokedex,
        PlayerPauseAction.profile,
      ]);
    });
  }

  testWidgets('classic profile preview retains its visible return control',
      (tester) async {
    await _setSurface(tester, const Size(390, 844));
    await tester.pumpWidget(_app(PlayerPausePreviewShell(
      gameTitle: 'Aube',
      actions: _actions(),
      presentation: const PlayerPausePresentation(),
      details: {
        PlayerPauseAction.profile:
            PlayerPausePreviewDetailData.demonstrationProfile(),
      },
      onSelected: (_) {},
    )));
    await _tapPreviewControl(tester, 'pause.profile');
    expect(find.text('Camille'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _tapPreviewControl(tester, 'runtime-pause-back-to-root');
    expect(find.byKey(const ValueKey('player-pause-preview-detail-profile')),
        findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('layout classification uses available constraints only', () {
    expect(
      classifyRuntimePlayerLayout(
        const BoxConstraints.tightFor(width: 390, height: 844),
      ),
      RuntimePlayerLayoutClass.compactPortrait,
    );
    expect(
      classifyRuntimePlayerLayout(
        const BoxConstraints.tightFor(width: 390, height: 340),
      ),
      RuntimePlayerLayoutClass.compactPortrait,
      reason: 'A portrait phone must not become two-column above a keyboard.',
    );
    expect(
      classifyRuntimePlayerLayout(
        const BoxConstraints.tightFor(width: 844, height: 390),
      ),
      RuntimePlayerLayoutClass.compactLandscape,
    );
    expect(
      classifyRuntimePlayerLayout(
        const BoxConstraints.tightFor(width: 1280, height: 800),
      ),
      RuntimePlayerLayoutClass.expanded,
    );
  });

  testWidgets('compact portrait shows root then a dedicated detail page',
      (tester) async {
    await _setSurface(tester, const Size(390, 844));
    PlayerPauseAction? selected;
    var backCalls = 0;

    await tester.pumpWidget(_app(RuntimePlayerPauseShell(
      gameTitle: 'Aube',
      pauseSection: RuntimePlayerPauseSection.root,
      actions: _actions(),
      onSelected: (action) => selected = action,
      onBackToRoot: () => backCalls++,
      detail: const Text('DÉTAIL ÉQUIPE'),
    )));

    expect(find.byType(PlayerPauseSurface), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey<String>(
          'runtime-pause-layout-compactPortrait',
        ),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey<String>('runtime-pause-navigation')),
        findsOneWidget);
    expect(find.text('DÉTAIL ÉQUIPE'), findsNothing);
    expect(find.text('Boutique'), findsNothing);
    expect(find.text('Centre Pokémon'), findsNothing);
    expect(find.text('PC'), findsNothing);

    await tester.tap(find.text('Équipe'));
    expect(selected, PlayerPauseAction.party);

    await tester.pumpWidget(_app(RuntimePlayerPauseShell(
      gameTitle: 'Aube',
      pauseSection: RuntimePlayerPauseSection.party,
      actions: _actions(),
      onSelected: (_) {},
      onBackToRoot: () => backCalls++,
      detail: const Text('DÉTAIL ÉQUIPE'),
    )));

    expect(find.text('DÉTAIL ÉQUIPE'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('runtime-pause-navigation')),
        findsNothing);
    await tester.tap(
      find.byKey(const ValueKey<String>('runtime-pause-back-to-root')),
    );
    expect(backCalls, 1);
  });

  testWidgets('compact landscape uses independently scrollable columns',
      (tester) async {
    await _setSurface(tester, const Size(844, 390));

    await tester.pumpWidget(_app(RuntimePlayerPauseShell(
      gameTitle: 'Aube',
      pauseSection: RuntimePlayerPauseSection.party,
      actions: _actions(),
      onSelected: (_) {},
      onBackToRoot: () {},
      detail: const Text('DÉTAIL ÉQUIPE'),
    )));

    expect(
      find.byKey(
        const ValueKey<String>(
          'runtime-pause-layout-compactLandscape',
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('runtime-pause-navigation-scroll')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('runtime-pause-detail-scroll')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey<String>('runtime-pause-navigation-scrollbar'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('runtime-pause-detail-scrollbar')),
      findsOneWidget,
    );
    expect(find.text('DÉTAIL ÉQUIPE'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('expanded uses a right panel and leaves the world perceptible',
      (tester) async {
    await _setSurface(tester, const Size(1280, 800));

    await tester.pumpWidget(_app(Stack(
      fit: StackFit.expand,
      children: <Widget>[
        const ColoredBox(
          key: ValueKey<String>('world'),
          color: Colors.green,
        ),
        RuntimePlayerPauseShell(
          gameTitle: 'Aube',
          pauseSection: RuntimePlayerPauseSection.party,
          actions: _actions(),
          onSelected: (_) {},
          onBackToRoot: () {},
          detail: const Text('DÉTAIL ÉQUIPE'),
        ),
      ],
    )));

    final panel = find.byKey(
      const ValueKey<String>('runtime-pause-expanded-panel'),
    );
    expect(panel, findsOneWidget);
    expect(tester.getSize(panel).width, lessThan(900));
    expect(find.byKey(const ValueKey<String>('world')), findsOneWidget);
  });

  testWidgets('authored pause layout uses the shared regular breakpoint', (
    tester,
  ) async {
    await _setSurface(tester, const Size(1024, 768));
    final base = suggestedProjectPresentationLayouts('standard');
    final layouts = base.copyWith(
      pauseMenu: base.pauseMenu.copyWith(
        regular: base.pauseMenu.regular.copyWith(
          slot: ProjectPresentationLayoutSlot.right,
        ),
      ),
    );

    await tester.pumpWidget(
      _app(
        RuntimePlayerPauseShell(
          gameTitle: 'Aube',
          pauseSection: RuntimePlayerPauseSection.party,
          actions: _actions(),
          onSelected: (_) {},
          onBackToRoot: () {},
          detail: const Text('DÉTAIL ÉQUIPE'),
        ),
        layouts: layouts,
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('runtime-pause-responsive-regular')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('authored expanded placement moves the real pause panel', (
    tester,
  ) async {
    await _setSurface(tester, const Size(1280, 800));
    final base = suggestedProjectPresentationLayouts('standard');

    for (final (slot, expected) in <(ProjectPresentationLayoutSlot, Alignment)>[
      (ProjectPresentationLayoutSlot.left, Alignment.centerLeft),
      (ProjectPresentationLayoutSlot.center, Alignment.center),
      (ProjectPresentationLayoutSlot.right, Alignment.centerRight),
    ]) {
      final layouts = base.copyWith(
        pauseMenu: base.pauseMenu.copyWith(
          expanded: base.pauseMenu.expanded.copyWith(slot: slot),
        ),
      );
      await tester.pumpWidget(
        _app(
          RuntimePlayerPauseShell.root(
            gameTitle: 'Aube',
            actions: _actions(),
            onSelected: (_) {},
            detail: const SizedBox.shrink(),
          ),
          layouts: layouts,
        ),
      );
      await tester.pumpAndSettle();

      final alignedAncestors = tester
          .widgetList<Align>(
            find.ancestor(
              of: find.byKey(
                const ValueKey<String>('runtime-pause-navigation'),
              ),
              matching: find.byType(Align),
            ),
          )
          .map((align) => align.alignment);
      expect(alignedAncestors, contains(expected));
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('text scale 2 keeps every action target at least 48 pixels',
      (tester) async {
    await _setSurface(tester, const Size(390, 844));

    await tester.pumpWidget(_app(
      RuntimePlayerPauseShell(
        gameTitle: 'Aube',
        pauseSection: RuntimePlayerPauseSection.root,
        actions: _actions(),
        onSelected: (_) {},
        onBackToRoot: () {},
        detail: const SizedBox.shrink(),
      ),
      textScaler: const TextScaler.linear(2),
    ));

    final targets =
        find.byKey(const ValueKey<String>('player-action-focus-frame'));
    expect(targets, findsNWidgets(PlayerPauseAction.values.length));
    for (final element in targets.evaluate()) {
      expect(
          tester.getSize(find.byElementPredicate((e) => e == element)).height,
          greaterThanOrEqualTo(48));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('safe areas and long labels keep controller focus visible', (
    tester,
  ) async {
    await _setSurface(tester, const Size(390, 844));
    final focusController = RuntimePlayerFocusController(
      activeInputSource: PlayerInputSource.controller,
    );
    addTearDown(focusController.dispose);
    const safePadding = EdgeInsets.fromLTRB(24, 59, 18, 34);
    final presentation = PlayerPausePresentation.fromProfile(
      ProjectPausePresentationProfile(
        hint: 'Bouton A pour sélectionner une entrée',
        actions: <ProjectPauseActionProfile>[
          for (final action in defaultProjectPauseActions)
            action.copyWith(
              label: '${action.id.name} — libellé volontairement très long',
            ),
        ],
        composition: const ProjectResponsivePauseCompositionProfile(
          compactPortrait: ProjectPauseCompositionVariantProfile(
            entrySize: ProjectPauseEntrySize.large,
            entrySpacing: ProjectPauseEntrySpacing.airy,
          ),
        ),
      ),
    );

    await tester.pumpWidget(
      _app(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 844),
            padding: safePadding,
          ),
          child: RuntimePlayerPauseShell.root(
            gameTitle: 'Aube',
            actions: _actions(),
            onSelected: (_) {},
            detail: const SizedBox.shrink(),
            focusController: focusController,
            activeInputSource: PlayerInputSource.controller,
            presentation: presentation,
          ),
        ),
        textScaler: const TextScaler.linear(2),
      ),
    );
    await tester.pumpAndSettle();

    final actionsContext = tester.element(
      find.byKey(const ValueKey<String>('runtime-player-actions-context')),
    );
    for (var index = 1; index < PlayerPauseAction.values.length; index++) {
      Actions.invoke(
        actionsContext,
        const RuntimePlayerLogicalIntent(
          PlayerInputAction.down,
          source: PlayerInputSource.controller,
        ),
      );
      await tester.pumpAndSettle();
    }

    expect(focusController.logicalSelectionId, 'pause.returnToTitle');
    expect(
      find.byKey(
        const ValueKey<String>('runtime-pause-navigation-scrollbar'),
      ),
      findsOneWidget,
    );
    final focusedRect = tester.getRect(
      find.byKey(const ValueKey<String>('pause.returnToTitle')),
    );
    expect(focusedRect.left, greaterThanOrEqualTo(safePadding.left));
    expect(focusedRect.right, lessThanOrEqualTo(390 - safePadding.right));
    expect(focusedRect.top, greaterThanOrEqualTo(safePadding.top));
    expect(focusedRect.bottom, lessThanOrEqualTo(844 - safePadding.bottom));
    expect(tester.takeException(), isNull);
  });

  testWidgets('mobile touch menu stays mounted and dims after controller input',
      (tester) async {
    await _setSurface(tester, const Size(844, 390));
    var resumeCalls = 0;

    await tester.pumpWidget(_app(RuntimePlayerPauseShell(
      gameTitle: 'Aube',
      pauseSection: RuntimePlayerPauseSection.root,
      actions: _actions(),
      onSelected: (_) {},
      onBackToRoot: () {},
      onTouchMenu: () => resumeCalls++,
      activeInputSource: PlayerInputSource.controller,
      detail: const SizedBox.shrink(),
    )));

    final opacity = tester.widget<AnimatedOpacity>(
      find.byKey(const ValueKey<String>('runtime-pause-touch-menu-opacity')),
    );
    expect(opacity.opacity, lessThan(1));

    await tester.tap(
      find.byKey(const ValueKey<String>('runtime-pause-touch-menu')),
    );
    expect(resumeCalls, 1);
  });

  testWidgets('project labels apply to navigation and detail titles',
      (tester) async {
    await _setSurface(tester, const Size(1280, 800));

    await tester.pumpWidget(_app(RuntimePlayerPauseShell(
      gameTitle: 'Aube',
      pauseSection: RuntimePlayerPauseSection.pokedex,
      actions: _actions(),
      labels: const PlayerPauseMenuLabels(
        pauseTitle: 'Interlude',
        pokedex: 'Carnet',
      ),
      onSelected: (_) {},
      onBackToRoot: () {},
      detail: const Text('DÉTAIL CARNET'),
    )));

    expect(find.text('Interlude'), findsOneWidget);
    expect(find.text('Carnet'), findsNWidgets(2));
    expect(find.text('Pokédex'), findsNothing);
  });

  testWidgets('authored action order visibility and identity drive navigation',
      (
    tester,
  ) async {
    await _setSurface(tester, const Size(1280, 800));
    final selected = <PlayerPauseAction>[];
    final presentation = PlayerPausePresentation.fromProfile(
      const ProjectPausePresentationProfile(
        title: 'Interlude',
        hint: 'A pour choisir',
        actions: <ProjectPauseActionProfile>[
          ProjectPauseActionProfile(
            id: ProjectPauseActionId.pokedex,
            label: 'Bestiaire',
            icon: ProjectPauseActionIcon.book,
          ),
          ProjectPauseActionProfile(
            id: ProjectPauseActionId.resume,
            label: 'Continuer',
            icon: ProjectPauseActionIcon.play,
          ),
          ProjectPauseActionProfile(
            id: ProjectPauseActionId.party,
            visible: false,
          ),
        ],
      ),
    );

    await tester.pumpWidget(
      _app(
        RuntimePlayerPauseShell(
          gameTitle: 'Aube',
          pauseSection: RuntimePlayerPauseSection.root,
          actions: _actions(),
          presentation: presentation,
          onSelected: selected.add,
          onBackToRoot: () {},
          detail: const SizedBox.shrink(),
        ),
      ),
    );

    final buttons = tester
        .widgetList<PlayerActionButton>(find.byType(PlayerActionButton))
        .toList(growable: false);
    expect(buttons.map((button) => button.label), <String>[
      'Bestiaire',
      'Continuer',
    ]);
    expect(find.text('Équipe'), findsNothing);
    expect(find.text('A pour choisir'), findsOneWidget);
    expect(
        FocusManager.instance.primaryFocus?.debugLabel, contains('Bestiaire'));

    await tester.tap(find.text('Bestiaire'));
    expect(selected, <PlayerPauseAction>[PlayerPauseAction.pokedex]);
  });

  testWidgets('controller focus follows visible authored order only', (
    tester,
  ) async {
    await _setSurface(tester, const Size(1280, 800));
    final selected = <PlayerPauseAction>[];
    final focusController = RuntimePlayerFocusController(
      logicalSelectionId: 'pause.party',
      activeInputSource: PlayerInputSource.controller,
    );
    addTearDown(focusController.dispose);
    final presentation = PlayerPausePresentation.fromProfile(
      const ProjectPausePresentationProfile(
        actions: <ProjectPauseActionProfile>[
          ProjectPauseActionProfile(
            id: ProjectPauseActionId.pokedex,
            label: 'Bestiaire',
          ),
          ProjectPauseActionProfile(
            id: ProjectPauseActionId.resume,
            label: 'Continuer',
          ),
          ProjectPauseActionProfile(
            id: ProjectPauseActionId.party,
            visible: false,
          ),
        ],
      ),
    );

    await tester.pumpWidget(
      _app(
        RuntimePlayerPauseShell.root(
          gameTitle: 'Aube',
          actions: _actions(),
          onSelected: selected.add,
          detail: const SizedBox.shrink(),
          focusController: focusController,
          logicalSelectionId: 'pause.party',
          activeInputSource: PlayerInputSource.controller,
          presentation: presentation,
        ),
      ),
    );
    await tester.pump();

    expect(focusController.logicalSelectionId, 'pause.pokedex');
    expect(
      FocusManager.instance.primaryFocus?.debugLabel,
      contains('Bestiaire'),
    );
    expect(find.byKey(const ValueKey<String>('pause.party')), findsNothing);

    final actionsContext = tester.element(
      find.byKey(const ValueKey<String>('runtime-player-actions-context')),
    );
    Actions.invoke(
      actionsContext,
      const RuntimePlayerLogicalIntent(
        PlayerInputAction.down,
        source: PlayerInputSource.controller,
      ),
    );
    await tester.pump();

    expect(focusController.logicalSelectionId, 'pause.resume');
    expect(
      FocusManager.instance.primaryFocus?.debugLabel,
      contains('Continuer'),
    );

    Actions.invoke(
      actionsContext,
      const RuntimePlayerLogicalIntent(
        PlayerInputAction.confirm,
        source: PlayerInputSource.controller,
      ),
    );
    await tester.pump();

    expect(selected, <PlayerPauseAction>[PlayerPauseAction.resume]);
  });

  testWidgets('controller skips a visible unavailable authored action', (
    tester,
  ) async {
    await _setSurface(tester, const Size(1280, 800));
    final selected = <PlayerPauseAction>[];
    final focusController = RuntimePlayerFocusController(
      logicalSelectionId: 'pause.resume',
      activeInputSource: PlayerInputSource.controller,
    );
    addTearDown(focusController.dispose);
    final actions = _actions()
      ..[PlayerPauseAction.pokedex] = const PlayerActionAvailability.disabled(
        'Pokédex indisponible',
      );

    await tester.pumpWidget(
      _app(
        RuntimePlayerPauseShell.root(
          gameTitle: 'Aube',
          actions: actions,
          onSelected: selected.add,
          detail: const SizedBox.shrink(),
          focusController: focusController,
          activeInputSource: PlayerInputSource.controller,
          presentation: PlayerPausePresentation.fromProfile(
            const ProjectPausePresentationProfile(
              actions: <ProjectPauseActionProfile>[
                ProjectPauseActionProfile(id: ProjectPauseActionId.resume),
                ProjectPauseActionProfile(
                  id: ProjectPauseActionId.pokedex,
                  label: 'Bestiaire',
                ),
                ProjectPauseActionProfile(id: ProjectPauseActionId.party),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Bestiaire'), findsOneWidget);
    final actionsContext = tester.element(
      find.byKey(const ValueKey<String>('runtime-player-actions-context')),
    );
    Actions.invoke(
      actionsContext,
      const RuntimePlayerLogicalIntent(
        PlayerInputAction.down,
        source: PlayerInputSource.controller,
      ),
    );
    await tester.pump();

    expect(focusController.logicalSelectionId, 'pause.party');
    Actions.invoke(
      actionsContext,
      const RuntimePlayerLogicalIntent(
        PlayerInputAction.confirm,
        source: PlayerInputSource.controller,
      ),
    );
    await tester.pump();
    expect(selected, <PlayerPauseAction>[PlayerPauseAction.party]);
  });

  testWidgets('authored expanded composition controls entries and root panel', (
    tester,
  ) async {
    await _setSurface(tester, const Size(1280, 800));
    const presentation = PlayerPausePresentation(
      title: 'Interlude',
      hint: 'A pour choisir',
      composition: ProjectResponsivePauseCompositionProfile(
        expanded: ProjectPauseCompositionVariantProfile(
          entrySize: ProjectPauseEntrySize.large,
          entrySpacing: ProjectPauseEntrySpacing.airy,
          showTitle: false,
          showRootDetailPanel: false,
        ),
      ),
    );

    await tester.pumpWidget(
      _app(
        RuntimePlayerPauseShell.root(
          gameTitle: 'Aube',
          actions: _actions(),
          onSelected: (_) {},
          detail: const Text('DÉTAIL RACINE'),
          presentation: presentation,
        ),
      ),
    );

    expect(find.text('Interlude'), findsNothing);
    expect(find.text('A pour choisir'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('runtime-pause-detail-scroll')),
      findsNothing,
    );
    expect(
      find.byKey(
        const ValueKey<String>(
          'runtime-pause-composition-expanded-large-airy',
        ),
      ),
      findsOneWidget,
    );
    for (final element in find
        .byKey(const ValueKey<String>('player-action-focus-frame'))
        .evaluate()) {
      expect(
        tester
            .getSize(find.byElementPredicate((value) => value == element))
            .height,
        greaterThanOrEqualTo(68),
      );
    }
  });

  testWidgets('portrait composition can expose the root detail panel', (
    tester,
  ) async {
    await _setSurface(tester, const Size(390, 844));

    await tester.pumpWidget(
      _app(
        RuntimePlayerPauseShell.root(
          gameTitle: 'Aube',
          actions: _actions(),
          onSelected: (_) {},
          detail: const SizedBox.shrink(),
          presentation: const PlayerPausePresentation(
            composition: ProjectResponsivePauseCompositionProfile(
              compactPortrait: ProjectPauseCompositionVariantProfile(
                showRootDetailPanel: true,
              ),
            ),
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('runtime-pause-detail-scroll')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('installed runtime shell consumes authored window styling',
      (tester) async {
    await _setSurface(tester, const Size(1280, 800));
    final windows = legacyProjectPresentationWindows.copyWith(
      pauseBackdropOpacity: .82,
    );

    await tester.pumpWidget(_app(
      RuntimePlayerPauseShell(
        gameTitle: 'Aube',
        pauseSection: RuntimePlayerPauseSection.root,
        actions: _actions(),
        onSelected: (_) {},
        onBackToRoot: () {},
        detail: const SizedBox.shrink(),
      ),
      theme: PokeMapPlayerTheme.withWindowProfile(
        PokeMapPlayerTheme.dark(),
        windows,
      ),
    ));

    final backdrop = tester.widget<Material>(
      find.byKey(const ValueKey<String>('runtime-pause-backdrop')),
    );
    expect(backdrop.color?.a, closeTo(.82, .01));
    expect(tester.takeException(), isNull);
  });
}

Future<void> _tapPreviewControl(WidgetTester tester, String key) async {
  final control = find.byKey(ValueKey(key));
  await tester.ensureVisible(control);
  await tester.tap(control);
  await tester.pumpAndSettle();
}

Future<ui.Image> _waitForMenuImage(WidgetTester tester) async {
  final rawImage = find.descendant(
    of: find.byKey(const ValueKey('runtime-menu-background')),
    matching: find.byType(RawImage),
  );
  for (var attempt = 0; attempt < 50; attempt++) {
    await tester.pump();
    final decoded = tester
        .widgetList<RawImage>(rawImage)
        .map((widget) => widget.image)
        .nonNulls
        .firstOrNull;
    if (decoded != null) return decoded;
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
  }
  fail('The menu background did not finish decoding.');
}

Map<PlayerPauseAction, PlayerActionAvailability> _actions() =>
    <PlayerPauseAction, PlayerActionAvailability>{
      for (final action in PlayerPauseAction.values)
        action: PlayerActionAvailability.enabled,
    };

Future<void> _setSurface(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Widget _app(
  Widget child, {
  TextScaler textScaler = TextScaler.noScaling,
  ThemeData? theme,
  ProjectPresentationLayoutsProfile? layouts,
}) {
  var resolvedTheme = theme ?? PokeMapPlayerTheme.dark();
  if (layouts != null) {
    resolvedTheme = PokeMapPlayerTheme.withLayoutProfile(
      resolvedTheme,
      layouts,
    );
  }
  return MaterialApp(
    locale: const Locale('fr'),
    supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
    localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
    theme: resolvedTheme,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: textScaler),
      child: child!,
    ),
    home: child,
  );
}
