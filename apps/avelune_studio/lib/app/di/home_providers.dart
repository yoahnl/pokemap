import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/home/domain/recent_studio_project.dart';

final recentProjectsPortProvider = Provider<RecentProjectsPort>(
  (ref) => throw StateError('Recent project preferences must be configured'),
);
