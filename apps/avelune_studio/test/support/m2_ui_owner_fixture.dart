import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/resources/data/local_resource_adapter.dart';
import 'package:avelune_studio/platform/rendering/studio_map_resources.dart';
import 'package:flutter_test/flutter_test.dart';

import 'real_test_io.dart';

class M2UiOwnerFixture {
  M2UiOwnerFixture(
    this.directory,
    this.session,
    this.port,
    this.controller,
    this.resources,
  );
  final Directory directory;
  final ProjectSession session;
  final LocalMapWorkspaceAdapter port;
  final MapWorkspaceController controller;
  final LocalResourceAdapter resources;
  StudioMapResources? visuals;
}

Future<void> pumpIo(WidgetTester tester, {int frames = 30}) =>
    RealTestIo.pump(tester, frames: frames);
