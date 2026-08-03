enum SmartTilesStudioCapability {
  durableDrafts,
  canonicalPublication,
  smartTilesOnlyProject,
}

final class SmartTilesStudioAvailability {
  const SmartTilesStudioAvailability({
    required this.durableDrafts,
    required this.canonicalPublication,
    required this.smartTilesOnlyProject,
  });

  static const stn04Baseline = SmartTilesStudioAvailability(
    durableDrafts: false,
    canonicalPublication: false,
    smartTilesOnlyProject: false,
  );

  final bool durableDrafts;
  final bool canonicalPublication;
  final bool smartTilesOnlyProject;

  bool get isReady => missingCapabilities.isEmpty;

  Set<SmartTilesStudioCapability> get missingCapabilities => {
        if (!durableDrafts) SmartTilesStudioCapability.durableDrafts,
        if (!canonicalPublication)
          SmartTilesStudioCapability.canonicalPublication,
        if (!smartTilesOnlyProject)
          SmartTilesStudioCapability.smartTilesOnlyProject,
      };
}
