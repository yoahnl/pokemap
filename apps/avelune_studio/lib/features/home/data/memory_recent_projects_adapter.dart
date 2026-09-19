import '../domain/recent_studio_project.dart';

class MemoryRecentProjectsAdapter implements RecentProjectsPort {
  List<RecentStudioProject> _entries = [];

  @override
  Future<List<RecentStudioProject>> load() async => List.of(_entries);

  @override
  Future<void> save(List<RecentStudioProject> entries) async {
    _entries = List.of(entries);
  }
}
