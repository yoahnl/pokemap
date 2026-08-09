# map_distribution

Pure Dart contracts and security tooling for deterministic PokeMap game
packages (`.avelunegame`).

The package owns:

- format-v1 manifest models, strict codecs, SemVer and canonical JSON;
- normalized payload inventories, per-file SHA-256 and content-tree hashes;
- deterministic, data-only ZIP building;
- bounded ZIP inspection, hostile-input validation and trust policy;
- host compatibility, release activation rules and install receipts.
- canonical, hash-bound `GamePackageInstallRequest` handoffs between
  independently built authoring and Hub applications.

It does not install files, choose Application Support paths, launch sessions,
render UI, or depend on Flutter, Flame, the runtime, editor, Hub, or developer
host. Filesystem staging and atomic promotion belong to the Hub installer.

## Basic flow

```dart
final built = GamePackageBuilder().build(
  manifest: manifestDraft,
  payloadFiles: projectedRuntimeFiles,
);

final inspector = GamePackageInspector(
  hostCompatibility: hostCompatibility,
);
final inspected = inspector.inspect(built.packageBytes);

final inspectedFromFile = inspector.inspectSourceSync(
  immutableRandomAccessPackageSource,
);
```

`GamePackageInspector` treats all bytes as hostile. It validates the central
directory before reading payloads, requires the deterministic ZIP profile,
checks inventory bijection and hashes, and enforces data-only, quota, secret,
reference, and signature policies. A public-catalog caller must inject a
trusted `GamePackageSignatureVerifier` and select
`PackageTrustRequirement.signatureRequired`.

The random-access source must remain immutable for the whole inspection. The
Hub filesystem adapter is intentionally outside this pure-Dart package and
must hold a stable file handle or otherwise guarantee that contract.

Direct editor installation uses a two-file inbox protocol. The producer
promotes immutable `<requestId>.avelunegame` bytes first and the canonical
`<requestId>.request.json` marker last. The Hub treats both as hostile, checks
the relative basename and SHA-256 again, and only then invokes its normal
atomic installer with the `localExport` source.

`GamePackageBuilder.build` accepts an already prepared, player-safe runtime
projection. It must not be pointed at an author workspace: the Phase 7 editor
exporter owns dialogue compilation, reference rewriting, cache/debug/save
exclusion, and secret removal. The current convenience builder materializes
its input and output; a source-to-sink streaming builder is required before
certifying large public exports near the v1 byte ceilings.

The Phase 1 hostile validator covers package cases HP-001–HP-032 and
HP-036–HP-039. HP-033, HP-034, and HP-035 are installer
crash/atomic-promotion cases and belong to the Phase 3 staging and library
implementation.

The authoritative format and security contracts are under
`reports/product/pokemap_hub/phase_0/`.
