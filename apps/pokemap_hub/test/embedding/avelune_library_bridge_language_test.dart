import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart'
    show RuntimeAudioMix, RuntimePlayerLanguageChoice;
import 'package:path/path.dart' as p;
import 'package:pokemap_hub/embedding/avelune_library_bridge.dart';
import 'package:pokemap_hub/features/preferences/data/repositories/hub_preferences_repository_impl.dart';
import 'package:pokemap_hub/features/session/application/gateways/hub_player_preferences_gateway.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const channel = MethodChannel('com.avelune.runtime/library');
  const codec = StandardMethodCodec();
  late Directory root;
  late AveluneLibraryBridge bridge;
  late Future<Directory> Function() resolveRoot;
  late Future<void> Function() onConfirmed;
  late List<Object?> notifications;

  Iterable<String> systemLocales() => binding.platformDispatcher.locales.map(
    (locale) => locale.toLanguageTag(),
  );

  Future<Object?> invoke(String method, [Object? arguments]) {
    final result = Completer<Object?>();
    messenger.handlePlatformMessage(
      channel.name,
      codec.encodeMethodCall(MethodCall(method, arguments)),
      (data) {
        try {
          if (data == null) throw MissingPluginException();
          result.complete(codec.decodeEnvelope(data));
        } on Object catch (error) {
          result.completeError(error);
        }
      },
    );
    return result.future;
  }

  setUp(() async {
    root = await Directory.systemTemp.createTemp('avelune-library-language-');
    resolveRoot = () async => root;
    onConfirmed = () async {};
    notifications = [];
    binding.platformDispatcher.localesTestValue = const [
      Locale('es', 'ES'),
      Locale('fr', 'CA'),
    ];
    bridge = AveluneLibraryBridge(
      supportRootResolver: () => resolveRoot(),
      systemLocales: systemLocales,
      onAppLanguageChanged: () => onConfirmed(),
    );
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'languagePreferencesChanged') {
        notifications.add(call.arguments);
      }
      return null;
    });
  });

  tearDown(() async {
    bridge.detach();
    messenger.setMockMethodCallHandler(channel, null);
    binding.platformDispatcher.clearLocalesTestValue();
    await root.delete(recursive: true);
  });

  test('reads language preferences from the runtimeReady callback', () async {
    final resolving = Completer<void>();
    final readyRoot = Completer<Directory>();
    final reading = Completer<Object?>();
    var rootReads = 0;
    resolveRoot = () {
      rootReads++;
      resolving.complete();
      return readyRoot.future;
    };
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'runtimeReady') {
        reading.complete(invoke('getLanguagePreferences'));
      }
      return null;
    });

    bridge.attach();
    await resolving.future;
    readyRoot.complete(root);

    expect(await reading.future, _language('system', 'fr'));
    expect(await invoke('getLanguagePreferences'), _language('system', 'fr'));
    expect(rootReads, 1);
  });

  test('rejects invalid app choices without creating preferences', () async {
    bridge.attach();

    for (final arguments in [
      null,
      {'appLanguage': 1},
      {'appLanguage': 'es'},
      {'appLanguage': 'fr '},
      {'appLanguage': 'EN'},
    ]) {
      await expectLater(
        invoke('setAppLanguage', arguments),
        throwsA(
          isA<PlatformException>().having(
            (error) => error.code,
            'code',
            'invalidArguments',
          ),
        ),
      );
    }

    expect(await root.list().toList(), isEmpty);
    expect(notifications, isEmpty);
  });

  test('persists and reports an app override and return to system', () async {
    bridge.attach();
    final store = HubPreferencesStore(supportRoot: root);
    expect(await invoke('getLanguagePreferences'), _language('system', 'fr'));

    expect(
      await invoke('setAppLanguage', {'appLanguage': 'en'}),
      _language('en', 'en'),
    );
    expect((await store.load()).preferences.language, PlayerLanguage.en);
    expect(
      await invoke('setAppLanguage', {'appLanguage': 'system'}),
      _language('system', 'fr'),
    );
    expect((await store.load()).preferences.language, PlayerLanguage.system);
    expect(notifications, [_language('en', 'en'), _language('system', 'fr')]);
  });

  test('keeps the prior language on failure and allows a retry', () async {
    final store = HubPreferencesStore(supportRoot: root);
    await store.save(const PlayerPreferences(language: PlayerLanguage.fr));
    final unsafeBackup = await Directory(
      p.join(root.path, 'preferences.backup.json'),
    ).create();
    var callbacks = 0;
    onConfirmed = () async {
      callbacks++;
    };
    bridge.attach();

    await expectLater(
      invoke('setAppLanguage', {'appLanguage': 'en'}),
      throwsA(
        isA<PlatformException>().having(
          (error) => error.code,
          'code',
          'preferencesStorage',
        ),
      ),
    );

    expect(notifications, isEmpty);
    expect(callbacks, 0);
    await unsafeBackup.delete();
    expect(await invoke('getLanguagePreferences'), _language('fr', 'fr'));
    expect(
      await invoke('setAppLanguage', {'appLanguage': 'en'}),
      _language('en', 'en'),
    );
    expect(notifications, [_language('en', 'en')]);
    expect(callbacks, 1);
  });

  test('signals the shell and Player after saving the new choice', () async {
    final observed = Completer<PlayerPreferences>();
    final finishCallback = Completer<void>();
    onConfirmed = () async {
      observed.complete((await bridge.preferencesStore.load()).preferences);
      await finishCallback.future;
    };
    bridge.attach();

    final response = invoke('setAppLanguage', {'appLanguage': 'en'});
    try {
      expect((await observed.future).language, PlayerLanguage.en);
      expect(notifications, isEmpty);
    } finally {
      finishCallback.complete();
    }

    expect(await response, _language('en', 'en'));
    expect(notifications, [_language('en', 'en')]);
  });

  test(
    'refreshes a changed system locale and preserves the Player override',
    () async {
      bridge.attach();
      expect(await invoke('getLanguagePreferences'), _language('system', 'fr'));
      await bridge.preferencesStore.update(
        (preferences) => preferences.copyWith(
          playerLanguage: RuntimePlayerLanguageChoice.explicit('fr'),
        ),
      );
      final player = HubPlayerPreferencesGateway(
        store: bridge.preferencesStore,
        fallbackLocale: 'en',
        systemLocales: systemLocales,
      );

      binding.platformDispatcher.localesTestValue = const [Locale('en', 'GB')];
      await bridge.refreshLanguagePreferences();
      await bridge.refreshLanguagePreferences();

      expect(notifications, [_language('system', 'en')]);
      expect(await invoke('getLanguagePreferences'), _language('system', 'en'));
      expect((await player.load()).locale, 'fr');
    },
  );

  test('app choices merge with concurrent Player option changes', () async {
    bridge.attach();
    await invoke('getLanguagePreferences');
    final player = HubPlayerPreferencesGateway(
      store: bridge.preferencesStore,
      fallbackLocale: 'fr',
      systemLocales: systemLocales,
    );
    final before = await player.load();
    final override = RuntimePlayerLanguageChoice.explicit('es');

    await Future.wait([
      invoke('setAppLanguage', {'appLanguage': 'en'}),
      player.save(
        before.copyWith(
          audioMix: const RuntimeAudioMix(masterVolume: 0.35),
        ),
      ),
      player.save(before.copyWith(languageChange: override)),
    ]);

    final saved = (await HubPreferencesStore(
      supportRoot: root,
    ).load()).preferences;
    expect(saved.language, PlayerLanguage.en);
    expect(saved.playerLanguage, override);
    expect(saved.masterVolume, 0.35);
  });

  test('confirms saved choices when the host has no event handler', () async {
    messenger.setMockMethodCallHandler(channel, null);
    bridge.attach();

    expect(
      await invoke('setAppLanguage', {'appLanguage': 'en'}),
      _language('en', 'en'),
    );
    expect(await invoke('getLanguagePreferences'), _language('en', 'en'));
  });
}

Map<String, Object> _language(String choice, String locale) => {
  'appLanguage': choice,
  'appLocale': locale,
  'supportedAppLanguages': ['fr', 'en'],
};
