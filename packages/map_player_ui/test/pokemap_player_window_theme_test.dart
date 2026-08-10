import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart';

void main() {
  testWidgets('keeps the legacy PlayerSurface default padding', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapPlayerTheme.light(),
        home: const PlayerSurface(
          key: ValueKey<String>('legacy-surface'),
          child: Text('Surface'),
        ),
      ),
    );

    final defaultPadding = find.descendant(
      of: find.byKey(const ValueKey<String>('legacy-surface')),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Padding &&
            widget.padding == const EdgeInsets.all(PlayerSpacing.lg),
      ),
    );

    expect(defaultPadding, findsOneWidget);
  });

  testWidgets('keeps the legacy PlayerPanel geometry without a window profile',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapPlayerTheme.light(),
        home: const Scaffold(
          body: PlayerPanel(
            key: ValueKey<String>('legacy-panel'),
            elevated: true,
            role: PlayerPanelRole.menu,
            child: Text('Pause'),
          ),
        ),
      ),
    );

    final material = tester.widget<Material>(
      find.descendant(
        of: find.byKey(const ValueKey<String>('legacy-panel')),
        matching: find.byType(Material),
      ),
    );
    final shape = material.shape! as RoundedRectangleBorder;
    final padding = tester.widget<Padding>(
      find.descendant(
        of: find.byKey(const ValueKey<String>('legacy-panel')),
        matching: find.byType(Padding),
      ),
    );

    expect(shape.borderRadius, BorderRadius.circular(16));
    expect(shape.side.width, 1);
    expect(material.elevation, 8);
    expect(padding.padding, const EdgeInsets.all(24));
  });

  testWidgets('resolves authored Pause geometry and semantic color tokens',
      (tester) async {
    final theme = PokeMapPlayerTheme.withWindowProfile(
      PokeMapPlayerTheme.withSemanticTheme(
        PokeMapPlayerTheme.light(),
        _semanticTheme,
      ),
      _windows,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Scaffold(
          body: PlayerPanel(
            key: ValueKey<String>('pause-panel'),
            elevated: true,
            role: PlayerPanelRole.menu,
            child: Text('Pause'),
          ),
        ),
      ),
    );

    final material = tester.widget<Material>(
      find.descendant(
        of: find.byKey(const ValueKey<String>('pause-panel')),
        matching: find.byType(Material),
      ),
    );
    final shape = material.shape! as RoundedRectangleBorder;
    final padding = tester.widget<Padding>(
      find.descendant(
        of: find.byKey(const ValueKey<String>('pause-panel')),
        matching: find.byType(Padding),
      ),
    );

    expect(material.color, _semanticTheme.surface);
    expect(material.elevation, 12);
    expect(shape.borderRadius, BorderRadius.circular(24));
    expect(shape.side.color, _semanticTheme.primary);
    expect(shape.side.width, 2);
    expect(padding.padding, const EdgeInsets.all(16));
  });

  testWidgets('resolves Dialogue independently from Pause', (tester) async {
    final theme = PokeMapPlayerTheme.withWindowProfile(
      PokeMapPlayerTheme.withSemanticTheme(
        PokeMapPlayerTheme.light(),
        _semanticTheme,
      ),
      _windows,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Scaffold(
          body: PlayerPanel(
            key: ValueKey<String>('dialogue-panel'),
            elevated: true,
            role: PlayerPanelRole.dialogue,
            child: Text('Dialogue'),
          ),
        ),
      ),
    );

    final material = tester.widget<Material>(
      find.descendant(
        of: find.byKey(const ValueKey<String>('dialogue-panel')),
        matching: find.byType(Material),
      ),
    );
    final shape = material.shape! as RoundedRectangleBorder;

    expect(material.color, _semanticTheme.dialogueSurface);
    expect(material.elevation, 4);
    expect(shape.borderRadius, BorderRadius.circular(10));
    expect(shape.side.color, _semanticTheme.outline);
  });

  for (final role in <ProjectPresentationSurfaceRole>[
    ProjectPresentationSurfaceRole.party,
    ProjectPresentationSurfaceRole.notification,
    ProjectPresentationSurfaceRole.battleHud,
  ]) {
    testWidgets('resolves the owned theme and window for ${role.name}', (
      tester,
    ) async {
      final theme = PokeMapPlayerTheme.withWindowProfile(
        PokeMapPlayerTheme.withSemanticTheme(
          PokeMapPlayerTheme.light(),
          _semanticTheme,
        ),
        _windows,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: PlayerPanel(
              key: ValueKey<String>('surface-${role.name}'),
              surfaceRole: role,
              child: Text(role.name),
            ),
          ),
        ),
      );

      final material = tester.widget<Material>(
        find.descendant(
          of: find.byKey(ValueKey<String>('surface-${role.name}')),
          matching: find.byType(Material),
        ),
      );
      expect(material.color, _semanticTheme.surfaceElevated);
      expect(material.elevation, 8);
    });
  }

  testWidgets('resolves each surface semantic token without window styles', (
    tester,
  ) async {
    final theme = PokeMapPlayerTheme.withSemanticTheme(
      PokeMapPlayerTheme.light(),
      _semanticTheme,
    );
    const roles = <ProjectPresentationSurfaceRole>[
      ProjectPresentationSurfaceRole.party,
      ProjectPresentationSurfaceRole.notification,
      ProjectPresentationSurfaceRole.battleHud,
    ];
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: Column(
            children: <Widget>[
              for (final role in roles)
                PlayerPanel(
                  key: ValueKey<String>('semantic-${role.name}'),
                  surfaceRole: role,
                  child: Text('Surface'),
                ),
            ],
          ),
        ),
      ),
    );

    final expected = <ProjectPresentationSurfaceRole, Color>{
      ProjectPresentationSurfaceRole.party: _semanticTheme.menuSurface,
      ProjectPresentationSurfaceRole.notification:
          _semanticTheme.overworldHudSurface,
      ProjectPresentationSurfaceRole.battleHud: _semanticTheme.battleHudSurface,
    };
    for (final role in roles) {
      final material = tester.widget<Material>(
        find.descendant(
          of: find.byKey(ValueKey<String>('semantic-${role.name}')),
          matching: find.byType(Material),
        ),
      );
      expect(material.color, expected[role]);
    }
  });

  testWidgets('keeps the title surface borderless by ownership',
      (tester) async {
    final theme = PokeMapPlayerTheme.withWindowProfile(
      PokeMapPlayerTheme.withSemanticTheme(
        PokeMapPlayerTheme.light(),
        _semanticTheme,
      ),
      _windows,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Scaffold(
          body: PlayerPanel(
            surfaceRole: ProjectPresentationSurfaceRole.title,
            child: Text('Titre'),
          ),
        ),
      ),
    );

    final material = tester.widget<Material>(find.byType(Material).last);
    final shape = material.shape! as RoundedRectangleBorder;

    expect(material.color, _semanticTheme.titleSurface);
    expect(shape.borderRadius, BorderRadius.circular(PlayerRadii.md));
  });

  testWidgets('renders a zero-width authored border as no border',
      (tester) async {
    final theme = PokeMapPlayerTheme.withWindowProfile(
      PokeMapPlayerTheme.light(),
      _windows.copyWith(
        styles: <ProjectWindowStyleProfile>[
          for (final style in _windows.styles)
            style.id == 'pause' ? style.copyWith(borderWidth: 0) : style,
        ],
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Scaffold(
          body: PlayerPanel(
            role: PlayerPanelRole.menu,
            child: Text('Pause'),
          ),
        ),
      ),
    );

    final material = tester.widget<Material>(find.byType(Material).last);
    final shape = material.shape! as RoundedRectangleBorder;

    expect(shape.side, BorderSide.none);
  });

  test('exposes authored Pause backdrop opacity', () {
    final extension = PokeMapPlayerWindowTheme(_windows);

    expect(extension.pauseBackdropOpacity, .85);
  });
}

const _windows = ProjectPresentationWindowsProfile(
  styles: <ProjectWindowStyleProfile>[
    ProjectWindowStyleProfile(
      id: 'default',
      fillToken: 'surfaceElevated',
      borderToken: 'outline',
      borderWidth: 1,
      cornerRadius: 16,
      contentPadding: 24,
      shadowElevation: 8,
    ),
    ProjectWindowStyleProfile(
      id: 'pause',
      fillToken: 'surface',
      borderToken: 'primary',
      borderWidth: 2,
      cornerRadius: 24,
      contentPadding: 16,
      shadowElevation: 12,
    ),
    ProjectWindowStyleProfile(
      id: 'dialogue',
      fillToken: 'dialogueSurface',
      borderToken: 'outline',
      borderWidth: 1,
      cornerRadius: 10,
      contentPadding: 20,
      shadowElevation: 4,
    ),
  ],
  defaultStyleId: 'default',
  pauseMenuStyleId: 'pause',
  dialogueStyleId: 'dialogue',
  pauseBackdropOpacity: .85,
);

const _semanticTheme = PokeMapPlayerSemanticTheme(
  primary: Color(0xff126e78),
  onPrimary: Color(0xffffffff),
  background: Color(0xfff4f7fb),
  surface: Color(0xffffffff),
  surfaceElevated: Color(0xffeaf0f8),
  textPrimary: Color(0xff101827),
  textSecondary: Color(0xff526176),
  outline: Color(0xff65758b),
  success: Color(0xff16794b),
  warning: Color(0xff8a5100),
  danger: Color(0xffb4233c),
  titleSurface: Color(0xffd9f4f6),
  dialogueSurface: Color(0xffffffff),
  menuSurface: Color(0xffeaf0f8),
  overworldHudSurface: Color(0xffffffff),
  battleHudSurface: Color(0xffffffff),
);
