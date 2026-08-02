# PokeMap Product Certification

This Flutter test package composes author export, package distribution, Hub
installation, installed runtime loading and game-scoped saves without creating
a production dependency between `map_editor` and `pokemap_hub`.

## Current evidence

- a second neutral project exports through `GamePackageExportService`;
- its author workspace and package source are removed before player launch;
- the installed project passes hostile inspection and a real runtime load;
- New Game writes an atomic `SaveEnvelope`, unloads, and Continue reloads from
  the installed version while HTTP client creation is denied;
- a 100-game library round-trips;
- a 2,000-file species catalogue exports and reopens;
- product receipts are deterministic, complete, bind passed entries to an
  executed command/result digest and reject paths/secrets;
- a dedicated Flutter test produces the neutral package consumed by the macOS
  release gate.

Run:

```bash
flutter pub get
flutter test
flutter analyze
```

To materialize the neutral release artifact:

```bash
flutter test test/build_neutral_package_artifact_test.dart \
  --dart-define=POKEMAP_CERTIFICATION_OUTPUT=/absolute/output/neutral.pokemapgame
```

## Certification limits

The time constants in `ProductCertificationBudgets` are conservative reference
guards for the current CI proposal. They are not P95 product claims until a
pinned reference runner has produced enough cold and warm samples.

This harness is intentionally fail-closed. It does not certify Phase 8 as
complete while these production contracts are absent:

- an authored no-code `Terminer le jeu` command wired post-commit to
  `GameCompleted`;
- a durable save-update/migration transaction with abort and recovery;
- the supervised desktop child-player protocol required by ADR-0002;
- an actual Developer ID-signed, notarized, stapled and cold-installed macOS
  artifact.

Tests must not replace these contracts with debug hooks or manual completion
events.
