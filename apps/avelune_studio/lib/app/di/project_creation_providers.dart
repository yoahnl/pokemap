import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_authoring/map_authoring_project_creation.dart';

final projectCreationPortProvider = Provider<ProjectCreationPort?>(
  (ref) => null,
);
final projectCreationPickerProvider = Provider<Future<String?> Function()?>(
  (ref) => null,
);
final projectCreationReleaseProvider = Provider<Future<void> Function()?>(
  (ref) => null,
);
