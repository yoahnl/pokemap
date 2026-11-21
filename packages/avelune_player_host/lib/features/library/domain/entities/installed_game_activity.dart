import 'package:avelune_player_host/core/diagnostics/hub_diagnostic.dart';

final class HubGameActivity {
  const HubGameActivity({
    this.canContinue = false,
    this.lastSaveAt,
    this.playTimeSeconds = 0,
    this.installationHealthy = true,
    this.updateAvailable = false,
    this.iconPath,
    this.coverPath,
    this.heroPath,
    this.diagnostic,
  });

  final bool canContinue;
  final DateTime? lastSaveAt;
  final int playTimeSeconds;
  final bool installationHealthy;
  final bool updateAvailable;
  final String? iconPath;
  final String? coverPath;
  final String? heroPath;
  final HubDiagnostic? diagnostic;
}
