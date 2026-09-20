import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/scenes/domain/scene_port.dart';
import '../../features/project_session/domain/project_session.dart';

final scenePortProvider = Provider.autoDispose
    .family<ScenePort?, ProjectSession>((ref, session) => null);
