import 'package:map_runtime/map_runtime.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('converts the runtime Menu control into a shared player command', () {
    final command = playerInputCommandFromRuntimeEvent(
      const RuntimeInputEvent.press(RuntimeInputControl.menu),
      source: PlayerInputSource.controller,
    );

    expect(command.action, PlayerInputAction.menu);
    expect(command.source, PlayerInputSource.controller);
    expect(command.isPress, isTrue);
  });

  test('routes gameplay commands and reserves Menu for the shell', () async {
    var surface = PlayerInputSurface.gameplay;
    final gameplay = <RuntimeInputEvent>[];
    final shell = <PlayerInputCommand>[];
    var menuToggles = 0;
    var releases = 0;
    final router = PlayerInputRouter(
      surface: () => surface,
      routeGameplay: (event) {
        gameplay.add(event);
        return true;
      },
      routeSurface: (command) async => shell.add(command),
      toggleMenu: () async {
        menuToggles++;
        surface = surface == PlayerInputSurface.gameplay
            ? PlayerInputSurface.pause
            : PlayerInputSurface.gameplay;
      },
      releaseGameplayDirections: () => releases++,
    );

    expect(
      await router.route(
        const PlayerInputCommand.press(
          PlayerInputAction.right,
          source: PlayerInputSource.controller,
        ),
      ),
      isTrue,
    );
    expect(
      gameplay.single,
      const RuntimeInputEvent.press(RuntimeInputControl.right),
    );

    await router.route(
      const PlayerInputCommand.press(
        PlayerInputAction.menu,
        source: PlayerInputSource.controller,
      ),
    );
    expect(menuToggles, 1);
    expect(releases, 1);
    expect(gameplay, hasLength(1));

    await router.route(
      const PlayerInputCommand.press(
        PlayerInputAction.down,
        source: PlayerInputSource.controller,
      ),
    );
    expect(shell.single.action, PlayerInputAction.down);

    await router.route(
      const PlayerInputCommand.press(
        PlayerInputAction.menu,
        source: PlayerInputSource.controller,
      ),
    );
    expect(menuToggles, 2);
    expect(releases, 2);
  });

  test('ignores repeated confirm/menu while allowing directional repeat',
      () async {
    final routed = <PlayerInputCommand>[];
    var toggles = 0;
    final router = PlayerInputRouter(
      surface: () => PlayerInputSurface.title,
      routeGameplay: (_) => false,
      routeSurface: (command) async => routed.add(command),
      toggleMenu: () async => toggles++,
      releaseGameplayDirections: () {},
    );

    await router.route(
      const PlayerInputCommand.press(
        PlayerInputAction.confirm,
        source: PlayerInputSource.keyboard,
        isRepeat: true,
      ),
    );
    expect(
      await router.route(
        const PlayerInputCommand.press(
          PlayerInputAction.menu,
          source: PlayerInputSource.keyboard,
        ),
      ),
      isTrue,
    );
    await router.route(
      const PlayerInputCommand.press(
        PlayerInputAction.menu,
        source: PlayerInputSource.keyboard,
        isRepeat: true,
      ),
    );
    await router.route(
      const PlayerInputCommand.press(
        PlayerInputAction.down,
        source: PlayerInputSource.keyboard,
        isRepeat: true,
      ),
    );

    expect(toggles, 0);
    expect(routed.map((command) => command.action), <PlayerInputAction>[
      PlayerInputAction.menu,
      PlayerInputAction.down,
    ]);
  });

  test('blocked surface consumes commands without leaking to gameplay',
      () async {
    var gameplayCalls = 0;
    var shellCalls = 0;
    var menuToggles = 0;
    final router = PlayerInputRouter(
      surface: () => PlayerInputSurface.blocked,
      routeGameplay: (_) {
        gameplayCalls++;
        return true;
      },
      routeSurface: (_) async => shellCalls++,
      toggleMenu: () async => menuToggles++,
      releaseGameplayDirections: () {},
    );

    expect(
      await router.route(
        const PlayerInputCommand.press(
          PlayerInputAction.confirm,
          source: PlayerInputSource.touch,
        ),
      ),
      isTrue,
    );
    expect(
      await router.route(
        const PlayerInputCommand.press(
          PlayerInputAction.menu,
          source: PlayerInputSource.controller,
        ),
      ),
      isTrue,
    );
    expect(gameplayCalls, 0);
    expect(shellCalls, 0);
    expect(menuToggles, 0);
  });

  test('Menu is not forwarded from result or credits surfaces', () async {
    var surface = PlayerInputSurface.result;
    final routed = <PlayerInputCommand>[];
    final router = PlayerInputRouter(
      surface: () => surface,
      routeGameplay: (_) => false,
      routeSurface: (command) async => routed.add(command),
      toggleMenu: () async {},
      releaseGameplayDirections: () {},
    );
    const menu = PlayerInputCommand.press(
      PlayerInputAction.menu,
      source: PlayerInputSource.controller,
    );

    expect(await router.route(menu), isTrue);
    surface = PlayerInputSurface.credits;
    expect(await router.route(menu), isTrue);
    expect(routed, isEmpty);
  });
}
