import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/events/domain/event_port.dart';
import '../../features/project_session/domain/project_session.dart';

final eventPortProvider = Provider.autoDispose
    .family<EventPort?, ProjectSession>((ref, session) => null);
