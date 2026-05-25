# P3 Event Source Bridge Fixture

Technical non-Selbrume fixture for P3-03.

It proves that a real `project.json` loaded through `loadRuntimeMapBundle`
can expose `ScenarioAsset` entries for the four runtime source events:

- `mapEnter`
- `triggerEnter`
- `entityInteract`
- `outcomeReceived`

The fixture is intentionally small and does not prove PlayableMapGame hooks,
host smoke flow, battle continuation, save/load roundtrip, World Rules, or UI.
