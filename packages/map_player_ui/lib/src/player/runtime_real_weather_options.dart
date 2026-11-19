import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import '../localization/player_localizations.dart';
import '../foundation/player_components.dart';
import '../foundation/player_menu_components.dart';
import '../theme/pokemap_player_menu_theme.dart';
import 'runtime_player_actions.dart';

class RuntimeRealWeatherOptions extends StatelessWidget {
  const RuntimeRealWeatherOptions({
    super.key,
    required this.preferences,
    required this.onChanged,
    this.service,
  });
  final RealWeatherPreferences preferences;
  final Future<void> Function(RealWeatherPreferences)? onChanged;
  final RealWeatherService? service;
  RealWeatherService get weather => service ?? RealWeatherService.shared;
  @override
  Widget build(BuildContext context) => PlayerMenuPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: sections(context),
    ),
  );
  List<Widget> sections(BuildContext context) {
    final strings = context.playerL10n;
    return [
      Row(
        children: [
          const Icon(Icons.cloud_outlined),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.playerL10n.weatherMyLocation,
              style: context.playerMenuTheme.label,
            ),
          ),
          Switch.adaptive(
            key: const ValueKey('real-weather-enabled'),
            value: preferences.enabled,
            onChanged: onChanged == null
                ? null
                : (enabled) => onChanged!(
                    RealWeatherPreferences(
                      enabled: enabled,
                      location: preferences.location,
                    ),
                  ),
          ),
        ],
      ),
      PlayerActionButton(
        icon: Icons.location_city_outlined,
        key: const ValueKey('real-weather-city'),
        label: context.playerL10n.weatherChooseCity,
        onPressed: onChanged == null
            ? null
            : () async {
                RuntimePlayerLocalActionNotification().dispatch(context);
                final location = await showDialog<RealWeatherLocation>(
                  context: context,
                  builder: (_) => PlayerMenuThemeScope(
                    role: ProjectPresentationSurfaceRole.options,
                    child: _WeatherCityPicker(
                      provider: weather.provider,
                      strings: strings,
                    ),
                  ),
                );
                if (context.mounted) {
                  RuntimePlayerLocalActionNotification().dispatch(context);
                }
                if (location != null && context.mounted) {
                  await onChanged!(
                    RealWeatherPreferences(
                      enabled: preferences.enabled,
                      location: location,
                    ),
                  );
                }
              },
      ),
      if (preferences.location != null)
        PlayerActionButton(
          icon: Icons.location_city_outlined,
          key: const ValueKey('real-weather-ip'),
          label: context.playerL10n.weatherUseIpLocation,
          onPressed: onChanged == null
              ? null
              : () => onChanged!(
                  RealWeatherPreferences(enabled: preferences.enabled),
                ),
        ),
      Text(
        context.playerL10n.weatherCompatibleGames,
        style: context.playerMenuTheme.body,
      ),
      Text(
        context.playerL10n.weatherApproximateLocation,
        style: context.playerMenuTheme.body,
      ),
      Text(
        context.playerL10n.weatherIpDisclosure,
        style: context.playerMenuTheme.body,
      ),
      const SizedBox(height: 8),
      ValueListenableBuilder<RealWeatherStatus>(
        valueListenable: weather,
        builder: (context, status, _) {
          final kind = status.snapshot?.conditions.choice(SpatialVisualParameter.weatherKind);
          if (kind == null) return const SizedBox.shrink();
          final name = switch (kind) {
            'clear' => strings.weatherClear,
            'cloudy' => strings.weatherCloudy,
            'drizzle' => strings.weatherDrizzle,
            'rain' => strings.weatherRain,
            'downpour' => strings.weatherDownpour,
            'storm' => strings.weatherStorm,
            'snow' => strings.weatherSnow,
            'blizzard' => strings.weatherBlizzard,
            'hail' => strings.weatherHail,
            'mist' => strings.weatherMist,
            'fog' => strings.weatherFog,
            'dust' => strings.weatherDust,
            'sandstorm' => strings.weatherSandstorm,
            'petals' => strings.weatherPetals,
            'partlyCloudy' => strings.weatherPartlyCloudy,
            'windy' => strings.weatherWindy,
            'heavySnow' => strings.weatherHeavySnow,
            'sleet' => strings.weatherSleet,
            'tempest' => strings.weatherTempest,
            'leaves' => strings.weatherLeaves,
            _ => kind,
          };
          return Text(
            strings.weatherReceived(weather: name),
            key: const ValueKey('real-weather-observation'), style: context.playerMenuTheme.body);
        },
      ),
      ValueListenableBuilder<RealWeatherStatus>(
        valueListenable: weather,
        builder: (context, status, _) => Text(
          strings.weatherCity(
            city:
                preferences.location?.label ??
                status.snapshot?.location.label ??
                strings.weatherDetectLocation,
          ),
          key: const ValueKey('real-weather-status'),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: context.playerMenuTheme.body,
        ),
      ),
      ValueListenableBuilder<RealWeatherStatus>(
        valueListenable: weather,
        builder: (context, status, _) => Text(
          status.loading
              ? context.playerL10n.weatherRefreshing
              : status.offline
              ? context.playerL10n.weatherOffline
              : context.playerL10n.weatherRefreshInterval,
          style: context.playerMenuTheme.meta,
        ),
      ),
      const SizedBox(height: 8),
      for (final entry in {
        'Open-Meteo · CC BY 4.0': 'https://open-meteo.com/',
        'CC BY 4.0': 'https://creativecommons.org/licenses/by/4.0/',
        'GeoJS': 'https://www.geojs.io/',
      }.entries)
        TextButton(
          style: TextButton.styleFrom(foregroundColor: context.playerMenuTheme.text),
          onPressed: () async {
            try {
              await launchUrl(
                Uri.parse(entry.value),
                mode: LaunchMode.externalApplication,
              );
            } on Object {
              if (context.mounted) {
                ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                  SnackBar(content: Text(context.playerL10n.linkUnavailable)),
                );
              }
            }
          },
          child: Text(entry.key),
        ),
      Text(
        context.playerL10n.weatherDataAdapted,
        style: context.playerMenuTheme.meta,
      ),
    ];
  }
}

class _WeatherCityPicker extends StatefulWidget {
  const _WeatherCityPicker({required this.provider, required this.strings});
  final RealWeatherProvider provider;
  final PokeMapPlayerLocalizations strings;
  @override
  State<_WeatherCityPicker> createState() => _WeatherCityPickerState();
}

class _WeatherCityPickerState extends State<_WeatherCityPicker> {
  final query = TextEditingController();
  List<RealWeatherLocation>? results;
  bool loading = false, failed = false;
  Future<void> search() async {
    if (loading) return;
    setState(() {
      loading = true;
      failed = false;
    });
    try {
      final matches = await widget.provider.search(query.text);
      if (mounted) setState(() => results = matches);
    } on Object {
      if (mounted) setState(() => failed = true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 500),
      child: SingleChildScrollView(
        child: PlayerMenuPanel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.strings.weatherLocationTitle,
                style: context.playerMenuTheme.title,
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('real-weather-city-query'),
                controller: query,
                maxLength: 120,
                enabled: !loading,
                decoration: InputDecoration(
                  labelText: widget.strings.weatherLocationSearchHint,
                ),
                onSubmitted: (_) => search(),
              ),
              PlayerActionButton(
                icon: Icons.location_city_outlined,
                key: const ValueKey('real-weather-city-search'),
                label: loading
                    ? widget.strings.weatherSearching
                    : widget.strings.search,
                onPressed: loading ? null : search,
              ),
              if (failed)
                Text(
                  widget.strings.weatherSearchUnavailable,
                  style: context.playerMenuTheme.body,
                ),
              if (results != null && results!.isEmpty && !failed)
                Text(
                  widget.strings.weatherNoCityFound,
                  style: context.playerMenuTheme.body,
                ),
              for (final location in results ?? <RealWeatherLocation>[])
                PlayerActionButton(
                  icon: Icons.location_city_outlined,
                  label: location.label,
                  onPressed: () => Navigator.of(context).pop(location),
                ),
              PlayerActionButton(
                icon: Icons.location_city_outlined,
                label: widget.strings.cancel,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
