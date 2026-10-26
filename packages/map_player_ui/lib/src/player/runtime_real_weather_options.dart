import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

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
    final french = Localizations.localeOf(context).languageCode == 'fr';
    String text(String fr, String en) => french ? fr : en;
    return [
      Row(
        children: [
          const Icon(Icons.cloud_outlined),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text('Météo de ma localisation', 'Weather at my location'),
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
        label: text('Choisir une autre ville', 'Choose another city'),
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
                      french: french,
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
          label: text('Revenir à la détection par IP', 'Use IP location again'),
          onPressed: onChanged == null
              ? null
              : () => onChanged!(
                  RealWeatherPreferences(enabled: preferences.enabled),
                ),
        ),
      Text(
        text(
          'Météo réelle pour les jeux compatibles.',
          'Real weather for supported games.',
        ),
        style: context.playerMenuTheme.body,
      ),
      Text(
        text(
          'Localisation approximative par IP, sans GPS.',
          'Approximate IP location, without GPS.',
        ),
        style: context.playerMenuTheme.body,
      ),
      Text(
        text(
          'GeoJS et Open-Meteo reçoivent votre IP.',
          'GeoJS and Open-Meteo receive your IP.',
        ),
        style: context.playerMenuTheme.body,
      ),
      const SizedBox(height: 8),
      ValueListenableBuilder<RealWeatherStatus>(
        valueListenable: weather,
        builder: (context, status, _) {
          final kind = status.snapshot?.conditions.choice(SpatialVisualParameter.weatherKind);
          if (kind == null) return const SizedBox.shrink();
          final names = <String, (String, String)>{
            'clear': ('Ciel dégagé', 'Clear sky'), 'cloudy': ('Couvert', 'Cloudy'),
            'drizzle': ('Bruine', 'Drizzle'), 'rain': ('Pluie', 'Rain'),
            'downpour': ('Averse', 'Downpour'), 'storm': ('Orage', 'Thunderstorm'),
            'snow': ('Neige', 'Snow'), 'blizzard': ('Blizzard', 'Blizzard'),
            'hail': ('Grêle', 'Hail'), 'mist': ('Brume légère', 'Mist'),
            'fog': ('Brouillard', 'Fog'), 'dust': ('Poussières', 'Dust'),
            'sandstorm': ('Tempête de sable', 'Sandstorm'), 'petals': ('Pétales', 'Petals'),
            'partlyCloudy': ('Éclaircies', 'Partly cloudy'),
            'windy': ('Vent soutenu', 'Windy'),
            'heavySnow': ('Forte neige', 'Heavy snow'),
            'sleet': ('Pluie et neige', 'Sleet'),
            'tempest': ('Tempête violente', 'Severe thunderstorm'),
            'leaves': ('Feuilles d’automne', 'Autumn leaves'),
          };
          final name = names[kind];
          return Text('${text('Météo reçue', 'Received weather')} : ${name == null ? kind : french ? name.$1 : name.$2}',
            key: const ValueKey('real-weather-observation'), style: context.playerMenuTheme.body);
        },
      ),
      ValueListenableBuilder<RealWeatherStatus>(
        valueListenable: weather,
        builder: (context, status, _) => Text(
          '${text('Ville', 'City')} : ${preferences.location?.label ?? status.snapshot?.location.label ?? text('Détection IP à l’ouverture du jeu', 'Detected by IP when gameplay starts')}',
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
              ? text('Actualisation…', 'Refreshing…')
              : status.offline
              ? text(
                  'Hors ligne · cache ou météo du jeu',
                  'Offline · cached or game weather',
                )
              : text(
                  'Actualisation toutes les 20 minutes',
                  'Refresh every 20 minutes',
                ),
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
                  SnackBar(
                    content: Text(
                      text('Lien indisponible.', 'Link unavailable.'),
                    ),
                  ),
                );
              }
            }
          },
          child: Text(entry.key),
        ),
      Text(
        text(
          'Données météo adaptées pour le rendu du jeu.',
          'Weather data adapted for game rendering.',
        ),
        style: context.playerMenuTheme.meta,
      ),
    ];
  }
}

class _WeatherCityPicker extends StatefulWidget {
  const _WeatherCityPicker({required this.provider, required this.french});
  final RealWeatherProvider provider;
  final bool french;
  @override
  State<_WeatherCityPicker> createState() => _WeatherCityPickerState();
}

class _WeatherCityPickerState extends State<_WeatherCityPicker> {
  final query = TextEditingController();
  List<RealWeatherLocation>? results;
  bool loading = false, failed = false;
  String text(String fr, String en) => widget.french ? fr : en;
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
                text('Ville de référence météo', 'Weather location'),
                style: context.playerMenuTheme.title,
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('real-weather-city-query'),
                controller: query,
                maxLength: 120,
                enabled: !loading,
                decoration: InputDecoration(
                  labelText: text(
                    'Ville, région ou pays',
                    'City, region or country',
                  ),
                ),
                onSubmitted: (_) => search(),
              ),
              PlayerActionButton(
                icon: Icons.location_city_outlined,
                key: const ValueKey('real-weather-city-search'),
                label: loading
                    ? text('Recherche…', 'Searching…')
                    : text('Rechercher', 'Search'),
                onPressed: loading ? null : search,
              ),
              if (failed)
                Text(
                  text(
                    'Recherche indisponible. Réessayez plus tard.',
                    'Search unavailable. Please try later.',
                  ),
                  style: context.playerMenuTheme.body,
                ),
              if (results != null && results!.isEmpty && !failed)
                Text(
                  text('Aucune ville trouvée.', 'No city found.'),
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
                label: text('Annuler', 'Cancel'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
