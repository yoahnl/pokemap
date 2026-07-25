import 'dart:convert';
import 'dart:math';

import 'package:map_runtime/map_runtime.dart';

import '../session/installed_game_launch_resolver.dart';

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
  Future<GameSessionDescriptor> createSessionDescriptor({
    required GameSessionLaunchMode launchMode,
    required String profileId,
    required String slotId,
    String? saveReadHandle,
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
      locale: _installedLocaleFor(preferences.locale),
      accessibility: preferences.accessibility,
    );
  }

  String _installedLocaleFor(String preferredLocale) {
    final locales = _launch.manifest.locales;
    if (locales.supported.contains(preferredLocale)) return preferredLocale;
    final preferredLanguage = _languageCode(preferredLocale);
    for (final supported in locales.supported) {
      if (_languageCode(supported) == preferredLanguage) return supported;
    }
    return locales.defaultLocale;
  }
}

String _languageCode(String locale) =>
    locale.split(RegExp('[-_]')).first.toLowerCase();

String _secureOpaqueId(String prefix) {
  final random = Random.secure();
  final bytes = List<int>.generate(24, (_) => random.nextInt(256));
  return '$prefix-${base64UrlEncode(bytes).replaceAll('=', '')}';
}
