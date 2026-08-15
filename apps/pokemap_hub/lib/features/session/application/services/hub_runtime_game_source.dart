import 'dart:convert';
import 'dart:math';

import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import 'package:pokemap_hub/features/session/domain/entities/installed_game_launch_context.dart';

typedef HubOpaqueIdFactory = String Function();

/// Projects one verified installed version into the host-neutral runtime port.
///
/// Installation paths and library records remain owned by the Hub. The
/// runtime receives only the identity, opaque handles, declared capabilities,
/// locale, and accessibility data required by a session descriptor.
final class HubRuntimeGameSource implements RuntimeGameSource {
  HubRuntimeGameSource({
    required InstalledGameLaunchContext launch,
    required this.preferencesGateway,
    HubOpaqueIdFactory? sessionIdFactory,
    HubOpaqueIdFactory? sessionTokenFactory,
  })  : _launch = launch,
        _sessionIdFactory =
            sessionIdFactory ?? (() => _secureOpaqueId('session')),
        _sessionTokenFactory =
            sessionTokenFactory ?? (() => _secureOpaqueId('token'));

  final InstalledGameLaunchContext _launch;
  final PlayerPreferencesGateway preferencesGateway;
  final HubOpaqueIdFactory _sessionIdFactory;
  final HubOpaqueIdFactory _sessionTokenFactory;

  @override
  get identity => _launch.identity;

  @override
  String get displayTitle => _launch.manifest.title;

  @override
  Set<ProjectPauseActionId> get defaultVisiblePauseActions {
    final actions = _launch.manifest.presentation?.pause?.actions;
    if (actions == null) {
      return Set<ProjectPauseActionId>.unmodifiable(
        ProjectPauseActionId.values,
      );
    }
    return Set<ProjectPauseActionId>.unmodifiable(<ProjectPauseActionId>{
      ProjectPauseActionId.resume,
      for (final action in actions)
        if (action.visible)
          ProjectPauseActionId.values.firstWhere(
            (candidate) => candidate.name == action.id,
          ),
    });
  }

  @override
  Future<GameSessionDescriptor> createSessionDescriptor({
    required GameSessionLaunchMode launchMode,
    required String profileId,
    required String slotId,
    String? saveReadHandle,
    GameState? initialGameState,
  }) async {
    final preferences = await preferencesGateway.load();
    return GameSessionDescriptor(
      sessionId: _sessionIdFactory(),
      sessionToken: _sessionTokenFactory(),
      identity: _launch.identity,
      profileId: profileId,
      slotId: slotId,
      launchMode: launchMode,
      installedVersionHandle: _launch.installedVersionHandle,
      saveReadHandle: saveReadHandle,
      runtimeApiVersion: _launch.runtimeApiVersion,
      grantedCapabilities: _launch.grantedCapabilities,
      locale: ProjectLocaleResolver.resolve(
        preferredLocale: preferences.locale,
        supportedLocales: _launch.manifest.locales.supported,
        fallbackLocale: _launch.manifest.locales.defaultLocale,
      ),
      accessibility: preferences.accessibility,
      initialGameState: initialGameState,
    );
  }
}

String _secureOpaqueId(String prefix) {
  final random = Random.secure();
  final bytes = List<int>.generate(24, (_) => random.nextInt(256));
  return '$prefix-${base64UrlEncode(bytes).replaceAll('=', '')}';
}
