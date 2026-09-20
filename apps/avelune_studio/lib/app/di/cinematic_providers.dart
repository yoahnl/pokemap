import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/cinematics/domain/cinematic_port.dart';
import '../../features/project_session/domain/project_session.dart';

final cinematicPortProvider = Provider.autoDispose
    .family<CinematicPort?, ProjectSession>((ref, session) => null);
