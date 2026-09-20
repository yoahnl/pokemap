import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/stories/domain/story_port.dart';
import '../../features/project_session/domain/project_session.dart';

final storyPortProvider = Provider.autoDispose
    .family<StoryPort?, ProjectSession>((ref, session) => null);
