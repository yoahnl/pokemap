# P3 Fact World Rule Projection Fixture

Technical non-Selbrume fixture for P3-05.

It proves that existing runtime predicates can passively read technical truths:

- `storyFlags`
- `completedStepIds`
- `completedCutsceneIds`
- `scenario.outcome.*` as story flags
- `battle:*` as story flags
- chapter completion derived from Global Story metadata
- Step Studio world presence derived from ScenarioAsset metadata
- conditional dialogues resolved by existing predicates

It does not create a FactRegistry, WorldRuleRegistry, UI, save/load roundtrip,
reward model, money, XP, level-up, or Selbrume content.
