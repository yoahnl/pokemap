import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/game_memory/domain/narrative_index_port.dart';
import '../../features/project_session/domain/project_session.dart';
import '../../features/storyline/domain/storyline_read_port.dart';

final narrativeIndexPortProvider = Provider.autoDispose
    .family<NarrativeIndexPort?, ProjectSession>((ref, session) => null);

final storylineReadPortProvider = Provider.autoDispose
    .family<StorylineReadPort?, ProjectSession>((ref, session) => null);
