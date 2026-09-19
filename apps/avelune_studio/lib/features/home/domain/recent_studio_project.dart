class RecentStudioProject {
  const RecentStudioProject({
    required this.name,
    required this.directoryPath,
    required this.lastOpenedAt,
  });

  final String name;
  final String directoryPath;
  final DateTime lastOpenedAt;
}

abstract interface class RecentProjectsPort {
  Future<List<RecentStudioProject>> load();
  Future<void> save(List<RecentStudioProject> entries);
}
