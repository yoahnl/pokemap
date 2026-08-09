# Phase 5 personalization golden slice

`presentation.json` is the shared authoring fixture for the Phase 5
Personalization Hub gate. Its schema V3 profile covers branding, responsive
intro and title motion metadata, menu labels, typography roles and licensing
evidence, semantic theme tokens, and the authored geometry of Pause and
Dialogue windows.

The editor gate validates and previews this project-owned contract before
export, then verifies its package projection and assets. The Hub gate resolves
the installed presentation and verifies that player surfaces consume the
semantic typography and color roles. Legacy projects remain covered by the
existing null-presentation fallback tests.

Run the focused gate from the relevant packages:

```bash
cd packages/map_editor
flutter test test/personalization/phase_5_personalization_golden_gate_test.dart

cd ../../apps/pokemap_hub
flutter test test/ui/player/phase_5_personalization_golden_gate_test.dart
```
