import 'dart:async';

import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:avelune_studio/app/di/event_providers.dart';
import 'package:avelune_studio/features/world/domain/world_port.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_services.dart';
import 'package:avelune_studio/presentation/features/story/story_page.dart';
import 'package:avelune_studio/features/events/domain/event_port.dart';
import 'package:avelune_studio/app/di/map_workspace_providers.dart';
import 'package:avelune_studio/app/di/narrative_providers.dart';
import 'package:avelune_studio/app/di/story_draft_providers.dart';
import 'package:avelune_studio/app/di/project_session_providers.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_draft.dart';
import 'package:avelune_studio/features/project_session/application/project_draft.dart';
import 'package:avelune_studio/features/project_session/application/studio_exit_guard.dart';
import 'package:avelune_studio/features/map_workspace/coordination/editor_shortcuts.dart';
import 'package:avelune_studio/features/map_workspace/application/map_selection_context.dart';
import 'package:avelune_studio/features/map_workspace/application/map_story_elements.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_input_session.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_visual_projection_queue.dart';
import 'package:avelune_studio/features/project_session/application/project_opening_progress.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/playtest/contracts/studio_playtest_builders.dart';
import 'package:avelune_studio/features/rendering/contracts/map_canvas_readiness.dart';
import 'package:avelune_studio/features/rendering/contracts/map_workspace_visuals.dart';
import 'package:avelune_studio/platform/rendering/viewports/map_editing_surface.dart';
import 'package:avelune_studio/presentation/shell/studio_rail.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_header.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_canvas.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_binding.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_ambiance_binding.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_gameplay_binding.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_gameplay_inspector.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_connection_port.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_inspector.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_opening.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_space.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_side_panel.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_resource_binding.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_status_bar.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_playtest_page.dart';
import 'package:avelune_studio/features/map_workspace/application/map_palette_intent.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/presentation/shared/widgets/minimum_size_viewport.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_tool_labels.dart';

part 'map_builder_page_layout.dart';
part 'map_builder_page_leave_guard.dart';
part 'map_builder_page_state.dart';
part 'map_builder_page_story.dart';

const mapBuilderMinimumSize = Size(1280, 720);

class MapBuilderPage extends ConsumerStatefulWidget {
  const MapBuilderPage({
    super.key,
    required this.session,
    required this.onHome,
    this.progress,
  });

  final ProjectSession session;
  final Future<void> Function() onHome;
  final ProjectOpeningProgress? progress;

  @override
  ConsumerState<MapBuilderPage> createState() => _MapBuilderPageState();
}
