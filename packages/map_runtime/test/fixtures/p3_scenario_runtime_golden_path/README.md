# P3 Scenario Runtime Golden Path Fixture

Technical non-Selbrume fixture for P3-02.

Purpose:

- load a real `project.json` through `loadRuntimeMapBundle`;
- expose one embedded `ScenarioAsset` from `ProjectManifest.scenarios`;
- execute the scenario with `ScenarioRuntimeExecutor`;
- verify `setFlag`, `completeStep`, and `emitOutcome` mutations.

This fixture intentionally avoids dialogue, battle, save/load roundtrip, world
rules, UI, and host smoke coverage. Those belong to later Phase 3 lots.
