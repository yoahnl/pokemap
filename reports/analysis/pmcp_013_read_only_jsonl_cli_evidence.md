# PMCP-013 — Read-only JSONL CLI Evidence Pack

Date: 2026-07-31
Lot: `PMCP-013 — CLI JSONL en lecture seule`
Verdict proposed: `DONE`

## Executive summary

PokeMap now has one shared read application API and a runnable pure-Dart JSONL
CLI. The application API owns project opening, coherent snapshot loading,
generic queries, reference validation, explicit capability truth, and closing.
The transport performs no domain work of its own.

The JSONL worker accepts only `describe`, `open`, `query`, `validate`, and
`close`. It requires one strict JSON object per input line, limits UTF-8 input
bytes, applies a per-command timeout, emits exactly one `AuthoringResult`
object, survives malformed requests, and redacts unexpected exceptions.

The process executable reserves stdout for JSON envelopes. A real process test
opens the P3 fixture, queries and validates it, closes it, recovers after
malformed JSON, produces no success-session stderr, and returns query data
identical to the direct API.

## Scope confirmation

Implemented:

- shared `AuthoringReadApiPort` and concrete `AuthoringReadApi`;
- deterministic read-only API description;
- direct `open`, `query`, `validate`, and idempotent `close`;
- reference and explicit capability-truth validation;
- strict top-level and command-specific JSON objects;
- request IDs and one response object per input line;
- five-command allow-list with no write command;
- UTF-8 byte limit and positive configuration validation;
- per-command response timeout;
- safe mapping of workspace, handle, manifest, snapshot, query, and region
  errors;
- generic redaction for unexpected exceptions and stack/path text;
- strict promoted/deferred capability record semantics;
- deterministic golden transcript;
- CLI argument parsing for repeated roots, timeout, and byte limit;
- sysexits-style constants and executable declaration;
- stdout/stderr separation;
- source-process end-to-end parity proof;
- standalone native executable compilation.

Explicitly not implemented:

- filesystem mutation or write commands;
- MCP transport or tool schemas;
- network listener, authentication, or authorization beyond allowed roots;
- durable handle/session persistence;
- concurrent command dispatch;
- cancellation of an already-running Dart future after a timeout response;
- signed cursors or write revision locks.

## Initial audit

Initial branch and state:

```text
7c7bf3f2e (HEAD -> main) feat(authoring): add reference diagnostics
<clean working tree>
```

Dependencies consumed from earlier phase 2 lots:

- secure root policy, read-only filesystem port, opaque expiring handles, and
  open/close service from `PMCP-010`;
- immutable snapshots and strict query contracts from `PMCP-011`;
- reference diagnostics and explicit capability truth from `PMCP-012`;
- canonical `AuthoringResult` and `AuthoringError` contracts from phase 1.

Key design decisions:

1. The transport depends on `AuthoringReadApiPort`. Direct and CLI consumers
   therefore execute the same application methods.
2. Every command-specific argument object rejects unknown fields.
3. Expected domain failures retain safe codes/messages; unexpected failures
   collapse to `worker.internal` without exception text.
4. Capability records preserve incomplete evidence for fail-closed validation,
   but contradictory promoted/deferred field combinations are rejected as
   malformed protocol input.
5. CLI stdout contains envelopes only. Usage and startup diagnostics use
   stderr and never echo unknown user-provided arguments.

## Named pass verdicts

No sub-agent was launched because delegation was not requested or authorized.
The independent passes were executed inline:

| Pass | Verdict | Evidence |
|---|---|---|
| Audit / Architecture | `PASS` | shared services and canonical envelopes inspected before transport design |
| Worker TDD | `PASS` | missing API/worker types observed RED; 10 focused tests green |
| Process TDD | `PASS` | missing executable observed RED; 4 real-process tests green |
| Security / Redaction | `PASS_WITH_FIXES`, then `PASS` | contradictory attestations, ambiguous root argument, and argv path echo fixed |
| Transport / Parity | `PASS` | exact golden, malformed recovery, direct/worker/CLI query equality |
| Build / Package | `PASS` | 99 tests, analyzer/formatter clean, native executable generated |
| Upstream Regression | `PASS` | 4,656 `map_core` tests and analyzer clean |
| Critique finale | `PASS` | no PMCP-013 blocker remains |

## File inventory

### Modified files

`packages/map_authoring/lib/map_authoring.dart`

- Zone: canonical public exports.
- Change: exports the shared read API, CLI exit codes, and JSONL worker.

Exact diff:

```diff
+export 'src/api/authoring_read_api.dart';
+export 'src/tooling/cli_exit_codes.dart';
+export 'src/tooling/jsonl_worker.dart';
```

`packages/map_authoring/pubspec.yaml`

- Zone: package executable declaration.
- Change: registers `pokemap_authoring`.

Exact diff:

```diff
+executables:
+  pokemap_authoring: pokemap_authoring
```

### Created production and executable files

`packages/map_authoring/lib/src/api/authoring_read_api.dart`

- Protocol-neutral port and concrete shared read application service.
- Truthful command/resource description.
- Open/query/reference-capability validation/close projections.

`packages/map_authoring/lib/src/tooling/jsonl_worker.dart`

- Strict parsing and dispatch.
- Limits, timeout, error mapping, redaction, and result serialization.
- Explicit capability truth JSON adapter.

`packages/map_authoring/lib/src/tooling/cli_exit_codes.dart`

- Documented sysexits-style process constants.

`packages/map_authoring/bin/pokemap_authoring.dart`

- Root/limit argument parser.
- Secure service composition.
- Sequential stdin JSONL to stdout envelope loop.
- Operator-only stderr failures.

### Created tests and golden

`packages/map_authoring/test/tooling/jsonl_worker_test.dart`

- Golden, command allow-list, real fixture, malformed recovery, strict fields,
  byte limit, timeout, unexpected exception redaction, API parity, capability
  adaptation, and contradictory status fields.

`packages/map_authoring/test/tooling/cli_golden_test.dart`

- Real Dart process session.
- Direct API parity, stdout JSON-only, stderr separation, malformed recovery,
  usage exit, ambiguous option value, and unknown-argument redaction.

`packages/map_authoring/test/tooling/goldens/describe_and_error.jsonl`

- Exact describe success and malformed-input failure envelopes.

### Full-content appendix

`reports/analysis/pmcp_013_created_files_full_content.md` reproduces all seven
production, executable, test, and golden files created by the lot. Evidence
reports and the appendix exclude themselves to avoid recursion.

## TDD evidence

Worker RED:

```text
Command:
dart test test/tooling/jsonl_worker_test.dart

Result:
Error: Type 'AuthoringReadApi' not found.
Error: Type 'JsonlWorker' not found.
Error: Type 'AuthoringReadApiPort' not found.
+0 -1: Some tests failed.
Exit code: 1
```

Worker first implementation:

```text
+7 -1: Some tests failed.
```

All behavioral tests were green; only the intentionally absent golden file
remained. After recording the exact deterministic transcript:

```text
+8: All tests passed!
Exit code: 0
```

CLI RED:

```text
Expected: true
Actual: false
The declared CLI executable must exist.
+0 -2: Some tests failed.
Exit code: 1
```

CLI first GREEN:

```text
+2: All tests passed!
Exit code: 0
```

Critical-review RED regressions:

```text
Contradictory capability:
Expected: AuthoringResultStatus.failure
Actual: AuthoringResultStatus.success

Ambiguous root option:
Expected exit code: 64
Actual exit code: 78

Unknown argument:
Expected stderr not to contain /Users/secret/project
Actual stderr echoed that value.
```

Fixes:

- promoted records now require `reason == null`;
- deferred records now require all promotion-evidence fields to be null;
- option tokens cannot be consumed as option values;
- unknown CLI arguments produce a generic usage diagnostic.

Final focused results:

```text
dart test test/tooling/jsonl_worker_test.dart
+10: All tests passed!
Exit code: 0

dart test test/tooling/cli_golden_test.dart
+4: All tests passed!
Exit code: 0
```

## Final commands and exact results

Full `map_authoring` package tests:

```text
Command:
dart test

Result:
+99: All tests passed!
Exit code: 0
```

Static analysis:

```text
Command:
dart analyze

Result:
Analyzing map_authoring...
No issues found!
Exit code: 0
```

Formatting:

```text
Command:
dart format --output=none --set-exit-if-changed bin lib test

Result:
Formatted 49 files (0 changed) in 0.07 seconds.
Exit code: 0
```

Native executable:

```text
Command:
dart compile exe bin/pokemap_authoring.dart \
  -o /tmp/pokemap_authoring_phase_2

Result:
Generated: /tmp/pokemap_authoring_phase_2
Exit code: 0
```

Upstream `map_core` regression:

```text
Command:
dart test

Result:
+4656: All tests passed!
Exit code: 0
```

Upstream static analysis:

```text
Command:
dart analyze

Result:
Analyzing map_core...
No issues found!
Exit code: 0
```

## Final Git state before the lot commit

```text
 M packages/map_authoring/lib/map_authoring.dart
 M packages/map_authoring/pubspec.yaml
?? packages/map_authoring/bin/pokemap_authoring.dart
?? packages/map_authoring/lib/src/api/authoring_read_api.dart
?? packages/map_authoring/lib/src/tooling/cli_exit_codes.dart
?? packages/map_authoring/lib/src/tooling/jsonl_worker.dart
?? packages/map_authoring/test/tooling/cli_golden_test.dart
?? packages/map_authoring/test/tooling/goldens/describe_and_error.jsonl
?? packages/map_authoring/test/tooling/jsonl_worker_test.dart
?? reports/analysis/pmcp_013_created_files_full_content.md
?? reports/analysis/pmcp_013_read_only_jsonl_cli_evidence.md
?? reports/analysis/pmcp_phase_2_read_api_evidence.md
```

## Critical self-review

Strengths:

- direct and transported reads share one application layer;
- successful process stdout is valid JSONL only;
- malformed input does not terminate the session;
- request and command objects reject unknown fields;
- input size and command duration have configurable positive bounds;
- expected errors stay coded while unexpected details are redacted;
- CLI diagnostics do not repeat machine-local arguments;
- no advertised or implemented command can mutate the filesystem;
- the standalone executable compiles without Flutter or Flame.

Remaining risks:

1. `Future.timeout` returns a bounded response but cannot cancel the underlying
   Dart future. A timed-out operation may finish in memory later. Durable
   mutation is absent, so phase 2 has no disk side effect from this limitation.
2. The worker checks bytes on a completed line. The CLI's standard line decoder
   can buffer a very large newline-free stream before dispatch. A future remote
   or hostile-input adapter should use a byte-bounded line decoder.
3. Handles are in-memory and expire after the process-local TTL. Restarting the
   CLI invalidates every handle by design.
4. `validate` covers reference domains emitted by the canonical narrative
   dependency index; later content domains must extend canonical discovery.
5. Capability truth remains caller-attested and fail-closed. It does not scan
   runtime code automatically.
6. This is a local protocol proof, not an MCP server. Authentication, tool
   consent, remote transport, and SDK compatibility remain later work.

## Next step

Phase 2 is ready to close. The recommended next lot is the phase 3 write kernel:
revision-checked dry-run/apply transactions with impact plans, atomic staging,
undo receipts, and no direct exposure of filesystem paths.

## Full-content appendix

`reports/analysis/pmcp_013_created_files_full_content.md`
