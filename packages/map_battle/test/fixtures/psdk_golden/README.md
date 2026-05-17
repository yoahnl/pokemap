# PSDK Golden Fixtures

This directory stores canonical battle scenarios used to compare the Dart PSDK
battle lane with Pokemon SDK behavior.

Each fixture is intentionally small and deterministic. A fixture should describe
one behavior, one setup, one ordered action list, the Pokemon SDK source paths
that justify the expected behavior, and the observable final state and timeline
expected from that scenario. The goal is to grow parity without mixing many move
families inside the same golden file.

Run the focused golden suite from `packages/map_battle`:

```sh
dart test test/psdk_golden_fixture_test.dart --reporter compact
```

When a future fixture is copied from a real Pokemon SDK trace, keep the source
version and notes explicit so drift can be audited.
