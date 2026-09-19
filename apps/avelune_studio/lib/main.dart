import 'package:flutter/material.dart';

import 'src/bootstrap/studio_app.dart';
import 'src/features/project_session/application/project_session_controller.dart';
import 'src/features/project_session/infrastructure/local_project_session_adapter.dart';
import 'src/features/project_session/infrastructure/native_project_directory_picker.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  const picker = NativeProjectDirectoryPicker();
  runApp(
    StudioApp(
      createSession: () =>
          ProjectSessionController(LocalProjectSessionAdapter()),
      chooseDirectory: picker.choose,
    ),
  );
}
