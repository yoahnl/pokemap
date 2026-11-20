import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/home/data/memory_recent_projects_adapter.dart';
import '../../features/home/domain/recent_studio_project.dart';

final recentProjectsPortProvider = Provider<RecentProjectsPort>(
  (ref) => MemoryRecentProjectsAdapter(),
);
