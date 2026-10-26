import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import '../foundation/player_components.dart';
import '../foundation/player_menu_components.dart';
import '../theme/pokemap_player_menu_theme.dart';

class RuntimeRealWeatherOptions extends StatelessWidget {
  const RuntimeRealWeatherOptions({super.key, required this.preferences, required this.onChanged, this.service});
  final RealWeatherPreferences preferences;
  final Future<void> Function(RealWeatherPreferences)? onChanged;
  final RealWeatherService? service;
  RealWeatherService get weather => service ?? RealWeatherService.shared;
  @override
  Widget build(BuildContext context) {
    final french = Localizations.localeOf(context).languageCode == 'fr';
    String text(String fr, String en) => french ? fr : en;
    return PlayerMenuPanel(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [const Icon(Icons.cloud_outlined), const SizedBox(width: 8), Expanded(child: Text(text('Météo de ma localisation', 'Weather at my location'), style: context.playerMenuTheme.label)), Switch.adaptive(
        key: const ValueKey('real-weather-enabled'), value: preferences.enabled,
        onChanged: onChanged == null ? null : (enabled) => onChanged!(RealWeatherPreferences(enabled: enabled, location: preferences.location)),
      )]),
      Text(text('Dans les jeux qui l’autorisent, la météo suit votre ville estimée par IP. GeoJS reçoit votre IP ; Open-Meteo reçoit les coordonnées approximatives. Aucune permission GPS.', 'In supported games, weather follows your approximate IP location. GeoJS receives your IP; Open-Meteo receives approximate coordinates. No GPS permission.'), style: context.playerMenuTheme.body),
      const SizedBox(height: 8),
      ValueListenableBuilder<RealWeatherStatus>(valueListenable: weather, builder: (context, status, _) => Text(
        '${text('Ville', 'City')} : ${preferences.location?.label ?? status.snapshot?.location.label ?? text('Détection par IP au lancement de la partie', 'Detected by IP when gameplay starts')}\n${status.loading ? text('Actualisation en arrière-plan…', 'Refreshing in background…') : status.offline ? text('Hors ligne · dernière météo connue ou météo du jeu', 'Offline · last known weather or game fallback') : text('Actualisation toutes les 20 minutes · données Open-Meteo / GeoJS', 'Refresh every 20 minutes · Open-Meteo / GeoJS data')}',
        key: const ValueKey('real-weather-status'), style: context.playerMenuTheme.body,
      )),
      const SizedBox(height: 8),
      PlayerActionButton(icon: Icons.location_city_outlined, key: const ValueKey('real-weather-city'), label: text('Choisir une autre ville', 'Choose another city'), onPressed: onChanged == null ? null : () async {
        final location = await showDialog<RealWeatherLocation>(context: context, builder: (_) => _WeatherCityPicker(provider: weather.provider, french: french));
        if (location != null && context.mounted) await onChanged!(RealWeatherPreferences(enabled: preferences.enabled, location: location));
      }),
      if (preferences.location != null) PlayerActionButton(icon: Icons.location_city_outlined, key: const ValueKey('real-weather-ip'), label: text('Revenir à la détection par IP', 'Use IP location again'), onPressed: onChanged == null ? null : () => onChanged!(RealWeatherPreferences(enabled: preferences.enabled))),
    ]));
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
    setState(() { loading = true; failed = false; });
    try {
      final matches = await widget.provider.search(query.text);
      if (mounted) setState(() => results = matches);
    } on Object { if (mounted) setState(() => failed = true); }
    finally { if (mounted) setState(() => loading = false); }
  }
  @override
  void dispose() { query.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Dialog(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 500), child: SingleChildScrollView(child: PlayerMenuPanel(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    Text(text('Ville de référence météo', 'Weather location'), style: context.playerMenuTheme.title),
    const SizedBox(height: 12),
    TextField(key: const ValueKey('real-weather-city-query'), controller: query, maxLength: 120, enabled: !loading, decoration: InputDecoration(labelText: text('Ville, région ou pays', 'City, region or country')), onSubmitted: (_) => search()),
    PlayerActionButton(icon: Icons.location_city_outlined, key: const ValueKey('real-weather-city-search'), label: loading ? text('Recherche…', 'Searching…') : text('Rechercher', 'Search'), onPressed: loading ? null : search),
    if (failed) Text(text('Recherche indisponible. Réessayez plus tard.', 'Search unavailable. Please try later.'), style: context.playerMenuTheme.body),
    if (results != null && results!.isEmpty && !failed) Text(text('Aucune ville trouvée.', 'No city found.'), style: context.playerMenuTheme.body),
    for (final location in results ?? <RealWeatherLocation>[]) PlayerActionButton(icon: Icons.location_city_outlined, label: location.label, onPressed: () => Navigator.of(context).pop(location)),
    PlayerActionButton(icon: Icons.location_city_outlined, label: text('Annuler', 'Cancel'), onPressed: () => Navigator.of(context).pop()),
  ])))));
}
