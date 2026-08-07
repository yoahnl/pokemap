/// Flutter product UI for PokeMap Hub.
///
/// Keep recovery workers on `pokemap_hub.dart`; this barrel intentionally
/// loads Flutter and the reusable player design system.
library;

export 'package:pokemap_hub/pokemap_hub_player.dart';
export 'package:pokemap_hub/presentation/features/home/widgets/avelune_cartridge.dart';
export 'package:pokemap_hub/presentation/features/home/widgets/avelune_console.dart';
export 'package:pokemap_hub/presentation/design_system/avelune_design_system.dart';
export 'package:pokemap_hub/presentation/design_system/assets/avelune_material_catalog.dart';
export 'package:pokemap_hub/presentation/features/home/widgets/avelune_game_details.dart';
export 'package:pokemap_hub/presentation/features/home/widgets/avelune_game_presentation.dart';
export 'package:pokemap_hub/presentation/theme/avelune_theme.dart';
export 'package:pokemap_hub/features/appearance/domain/entities/avelune_appearance_catalog.dart';
export 'package:pokemap_hub/features/appearance/application/notifiers/avelune_appearance_notifier.dart';
export 'package:pokemap_hub/features/appearance/application/notifiers/avelune_appearance_dependencies.dart';
export 'package:pokemap_hub/features/appearance/domain/entities/avelune_appearance_preferences.dart';
export 'package:pokemap_hub/presentation/features/settings/pages/avelune_appearance_settings_page.dart';
export 'package:pokemap_hub/presentation/features/settings/pages/avelune_settings_menu.dart';
export 'package:pokemap_hub/presentation/features/settings/widgets/avelune_storage_panel.dart';
export 'package:pokemap_hub/presentation/features/settings/widgets/avelune_motion_panel.dart';
export 'package:pokemap_hub/features/appearance/data/repositories/avelune_appearance_repository_impl.dart';
export 'package:pokemap_hub/features/appearance/data/repositories/custom_background_repository_impl.dart';
export 'package:pokemap_hub/features/appearance/domain/repositories/custom_background_repository_interface.dart';
export 'package:pokemap_hub/presentation/features/home/state/avelune_home_controller.dart';
export 'package:pokemap_hub/presentation/features/home/widgets/avelune_game_shelf.dart';
export 'package:pokemap_hub/presentation/features/home/state/avelune_home_geometry.dart';
export 'package:pokemap_hub/presentation/features/home/widgets/avelune_hero_details_panel.dart';
export 'package:pokemap_hub/presentation/features/home/widgets/avelune_home_header.dart';
export 'package:pokemap_hub/presentation/features/home/widgets/avelune_insertion_hint.dart';
export 'package:pokemap_hub/core/utils/relative_time.dart';
export 'package:pokemap_hub/presentation/features/home/pages/avelune_home_screen.dart';
export 'package:pokemap_hub/presentation/features/home/state/avelune_home_view_data.dart';
export 'package:pokemap_hub/presentation/features/home/state/avelune_home_view_data_mapper.dart';
export 'package:pokemap_hub/presentation/features/home/widgets/avelune_room_scene.dart';
export 'package:pokemap_hub/presentation/design_system/motion/avelune_motion.dart';
export 'package:pokemap_hub/presentation/features/home/state/avelune_exchange_controller.dart';
export 'package:pokemap_hub/presentation/features/home/state/avelune_insertion_controller.dart';
export 'package:pokemap_hub/app/ui/app_widget.dart';
export 'package:pokemap_hub/core/diagnostics/hub_diagnostic.dart';
export 'package:pokemap_hub/features/dashboard/application/notifiers/hub_dashboard_notifier.dart';
export 'package:pokemap_hub/features/dashboard/application/notifiers/hub_dashboard_state.dart';
export 'package:pokemap_hub/features/dashboard/application/notifiers/hub_dashboard_dependencies.dart';
export 'package:pokemap_hub/features/dashboard/application/services/hub_directory_storage_reader.dart';
export 'package:pokemap_hub/features/dashboard/application/services/installed_game_activity_reader.dart';
export 'package:pokemap_hub/presentation/shell/hub_game_views.dart';
export 'package:pokemap_hub/presentation/shell/hub_shell.dart';
export 'package:pokemap_hub/presentation/features/player/pages/hub_installed_game_player.dart';
export 'package:pokemap_hub/features/session/domain/entities/hub_player_launch_intent.dart';
export 'package:pokemap_hub/features/preferences/data/repositories/hub_preferences_repository_impl.dart';
export 'package:pokemap_hub/features/preferences/domain/entities/hub_preferences_read.dart';
export 'package:pokemap_hub/features/appearance/domain/entities/avelune_appearance_read.dart';
