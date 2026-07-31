# PMCP-023 — Authorization, Confirmation, Redaction, Limits, and Audit Evidence Pack

Date: 2026-07-31

Phase: PokeMap Authoring API/MCP phase 3

Lot: PMCP-023

Proposed status: `DONE`

## Executive summary

PMCP-023 adds the mandatory security boundary needed before mutation actions
are exposed to an agent adapter. The new pure-Dart layer provides:

- immutable server-side actors that are read-only by default;
- all 15 permission scopes from the canonical action catalog;
- independent plan, apply, recovery, asset-write, and external-network gates;
- high/critical destructive confirmation with opaque, expiring, one-use
  capabilities bound to actor, project, action/version, plan, and diff;
- deterministic request-size, touched-resource, and sliding-window rate limits;
- recursive secret, bearer credential, absolute-path, and exception redaction;
- a locked, flushed, append-only JSONL audit log with a validated hash chain;
- a secure executor that validates context and policy before delegating to the
  PMCP-022 transaction, then audits denied, failed, and successful attempts.

Fresh end-of-lot evidence:

- focused security suite: `+15: All tests passed!`;
- transaction plus security suites: `+59: All tests passed!`;
- full `map_authoring` package: `+158: All tests passed!`;
- analyzer: `No issues found!`;
- formatter verification: 79 files, 0 changed;
- real read-only CLI smoke: exit 0;
- `git diff --check`: exit 0.

## Initial audit

The lot started from a clean tree at:

```text
6cdf8da7b feat(authoring): add recoverable write transactions
```

PMCP-022 already provided a correct low-level transaction mechanism, but that
entry point intentionally trusted its caller. The audit found no uniform model
for actor grants, destructive confirmation, request/rate limits, output
redaction, or durable attempt logging. The existing action descriptor also had
only seven provisional permission values, including three short wire names
that did not match the catalog.

The implementation stays in `package:map_authoring`, remains Flutter/Flame
free, and does not alter gameplay/runtime rules. This is authoring
infrastructure, so no `FG-*` mechanics lot or mechanics roadmap status changed.

## Named pass verdicts

No sub-agent was dispatched; repository/session instructions did not authorize
delegation. Named local passes were used instead:

| Pass | Verdict | Evidence |
|---|---|---|
| TDD contract pass | PASS | Initial `test/security` run failed at load with `+0 -3` because every planned security type was absent; final suite is +15. |
| Least-privilege pass | PASS | Default actor has only `project.read`; every write-like operation requires an independent primary scope. |
| Catalog-scope pass | PASS | Descriptor and enforcement enums expose the same 15 canonical wire scopes; three phase-1 short names remain accepted only as input aliases. |
| Confirmation pass | PASS | Missing scope/token, expiry, replay, and wrong-plan binding all fail; secure apply consumes a token bound to the real plan diff. |
| Limit-before-write pass | PASS | Size, touched-resource, and rate denials leave resource bytes and transaction journal untouched. |
| Redaction pass | PASS | Nested secret-like fields, bearer credentials, POSIX/Windows paths, and raw internal exception text are absent from serialized output. |
| Audit durability pass | PASS after fix | Reopen, corruption, hash-chain, and concurrent multi-instance append tests pass. An observed intra-process append race led to adding a process-local queue in addition to the OS lock. |
| Secure executor pass | PASS | Actor/project/action/plan/idempotency scope must agree; denied, transaction-failed, and successful paths create linked audit records. |
| Regression pass | PASS | All 158 package tests and static analysis pass. |

## File inventory and precise changed zones

### Modified files

- `packages/map_authoring/lib/map_authoring.dart`
  - lines 31–37: exports all public security, confirmation, redaction, audit,
    and secure-executor APIs.
- `packages/map_authoring/lib/src/contracts/action_descriptor.dart`
  - lines 25–40: expands `AuthoringPermission` to the 15 canonical catalog
    scopes;
  - lines 44–48: accepts legacy `render`, `playtest`, and `recovery` input
    strings while all new serialization emits canonical names.

### Created production files

- `packages/map_authoring/lib/src/security/authoring_permission.dart`
  - canonical scopes, security operations, immutable read-only-default actor,
    and safe opaque identity validation.
- `packages/map_authoring/lib/src/security/authorization_policy.dart`
  - least-privilege decision model, deterministic limits, rate buckets,
    destructive-scope enforcement, and confirmation consumption.
- `packages/map_authoring/lib/src/security/confirmation_token.dart`
  - secure opaque token generation/transport, server-side bindings, expiry,
    replay refusal, and exact plan-diff binding helper.
- `packages/map_authoring/lib/src/security/output_redaction.dart`
  - recursive JSON sanitizer and stable raw-exception mapping.
- `packages/map_authoring/lib/src/security/audit_record.dart`
  - strict actor/request/plan/receipt/decision/risk/timestamp record contract
    with mandatory details redaction.
- `packages/map_authoring/lib/src/security/audit_log.dart`
  - project-local locked/flushed JSONL append, intra-process queue, OS lock,
    strict reopen, unique IDs, and hash-chain validation.
- `packages/map_authoring/lib/src/security/secure_mutation_executor.dart`
  - trusted context checks, descriptor-permission mapping, pre-write policy,
    PMCP-022 delegation, and final outcome audit.

### Created tests

- `packages/map_authoring/test/security/authorization_policy_test.dart`
  - default/independent scopes, catalog parity, destructive confirmation,
    binding, expiry, replay, size/resource/rate limits.
- `packages/map_authoring/test/security/output_redaction_test.dart`
  - nested keys, credentials, paths, safe relative values, and exceptions.
- `packages/map_authoring/test/security/audit_log_test.dart`
  - reopen, redaction-at-rest, hash chain, concurrent append, corruption,
    secure-executor outcomes, pre-write limits, and real confirmation apply.

### Reporting artifacts

- `reports/analysis/pmcp_023_authorization_audit_evidence.md`
  - this Evidence Pack.
- `reports/analysis/pmcp_023_created_files_full_content.md`
  - exact full content of all ten created source/test files.

The exhaustive created-file appendix is:

```text
reports/analysis/pmcp_023_created_files_full_content.md
```

The appendix intentionally excludes itself and this report to prevent
recursive reporting content.

## Authorization and confirmation model

The canonical permission set is:

```text
project.read
project.write
project.destructive
asset.read
asset.write
render.run
playtest.run
playtest.control
import.run
export.run
migration.run
network.external
process.execute
secret.use
recovery.apply
```

Primary operation mapping:

| Operation | Mandatory scope |
|---|---|
| plan | `project.read` |
| apply | `project.write` |
| recover | `recovery.apply` |
| asset write | `asset.write` |
| external network | `network.external` |

An action cannot hide a write behind a read-only descriptor: the operation's
primary scope is always required independently, then every descriptor scope is
added. The secure executor also rejects disagreement between actor, project,
action/version, frozen plan, and durable idempotency scope.

For a destructive change at `high` or `critical` risk, authorization additionally
requires `project.destructive` and a confirmation token. The binding includes:

```text
actorId + projectId + actionId + actionVersion + planId + diffFingerprint
```

The binding remains server-side. The transport value is opaque, generated from
32 secure random bytes by default, has a redacted `toString`, expires after five
minutes by default, and is marked consumed only after an exact match.

## Limit and audit ordering

The secure apply sequence is:

1. validate trusted actor/project/action/plan/scope linkage;
2. derive mandatory and descriptor permissions;
3. reject missing scopes;
4. reject request-byte and touched-resource excess;
5. enforce the actor/project/operation sliding-window rate bucket;
6. validate and consume confirmation when required;
7. delegate once to the journaled transaction;
8. append exactly one final denied, failed, or succeeded audit record.

Denied policy attempts write audit metadata but never create transaction
artifacts or change project resources. A transaction exception is logged as
`failed`; a committed receipt is linked as `succeeded`.

Audit events are serialized under the project metadata area. Each event stores
the previous digest, a strictly parsed redacted record, and a deterministic
digest over both. Append holds a process-local queue and an exclusive OS lock,
revalidates the complete chain, refuses duplicate audit IDs, writes one JSONL
line, and flushes it before releasing the lock.

## TDD evidence

### Initial RED

Command:

```bash
cd packages/map_authoring
dart test test/security
```

Initial result: exit 1, `+0 -3`. All three test files failed to load because
the permission, authorization, confirmation, redaction, audit, and secure
executor types did not yet exist.

### Intermediate concurrency failure and fix

The first audit implementation used only `FileLock.exclusive`. Concurrent log
instances in one Dart process exposed platform lock semantics that allowed a
lost ordering assumption, and the hash-chain test failed with `audit.corrupt`.
The adapter now queues operations by canonical project root inside the process
and also keeps the OS lock for inter-process writers. The same concurrent test
then passed without lost records.

### Final focused GREEN

```bash
cd packages/map_authoring
dart test test/security
```

```text
+15: All tests passed!
```

## Final commands and exact results

```bash
cd packages/map_authoring
dart test test/transactions test/security
```

```text
+59: All tests passed!
```

```bash
cd packages/map_authoring
dart test
```

```text
+158: All tests passed!
```

```bash
cd packages/map_authoring
dart analyze
```

```text
Analyzing map_authoring...
No issues found!
```

```bash
cd packages/map_authoring
dart format --output=none --set-exit-if-changed lib test
```

```text
Formatted 79 files (0 changed) in 0.17 seconds.
```

```bash
cd packages/map_authoring
dart run bin/pokemap_authoring.dart \
  --root ../../examples/playable_runtime_host/p3_narrative_smoke_slice \
  </dev/null
```

```text
exit 0; stdout empty; stderr empty
```

```bash
git diff --check
```

```text
exit 0; no output
```

## Final Git state before commit

Expected lot-only state:

```text
 M packages/map_authoring/lib/map_authoring.dart
 M packages/map_authoring/lib/src/contracts/action_descriptor.dart
?? packages/map_authoring/lib/src/security/audit_log.dart
?? packages/map_authoring/lib/src/security/audit_record.dart
?? packages/map_authoring/lib/src/security/authoring_permission.dart
?? packages/map_authoring/lib/src/security/authorization_policy.dart
?? packages/map_authoring/lib/src/security/confirmation_token.dart
?? packages/map_authoring/lib/src/security/output_redaction.dart
?? packages/map_authoring/lib/src/security/secure_mutation_executor.dart
?? packages/map_authoring/test/security/audit_log_test.dart
?? packages/map_authoring/test/security/authorization_policy_test.dart
?? packages/map_authoring/test/security/output_redaction_test.dart
?? reports/analysis/pmcp_023_authorization_audit_evidence.md
?? reports/analysis/pmcp_023_created_files_full_content.md
```

No unrelated pre-existing change was present or absorbed.

## Critique finale and known limits

- `AuthoringActor` is intentionally a server-side value and has no request JSON
  parser. A future MCP adapter must construct it exclusively from authenticated
  server policy; accepting actor grants from tool arguments would defeat this
  boundary.
- Confirmation bindings and rate buckets are process-local. Restart invalidates
  outstanding confirmations (fail closed) and resets rate history. A
  distributed MCP deployment will need shared stores.
- A consumed high-risk confirmation is not restored when the underlying
  transaction later fails. Retrying that destructive operation requires a new
  explicit confirmation.
- If success-audit persistence fails after a transaction commits, the secure
  executor returns the audit error. The durable idempotency key prevents byte
  reapplication, but a high-risk caller must provide a newly confirmed retry.
- The audit digest chain detects truncation, reordering, corruption, and edits
  whose digest is not recomputed. It is not a keyed signature against an
  attacker who already controls the project filesystem.
- A torn final audit append is rejected as `audit.corrupt`; this lot fails
  closed rather than silently ignoring a partial final event.
- Redaction covers secret-like fields, bearer credentials, common absolute-path
  syntax, and all raw exception objects. It is defense in depth, not a general
  data-loss-prevention classifier for secrets embedded in arbitrary prose.
- The public low-level PMCP-022 transaction remains available for trusted
  internal composition and tests. Agent-facing adapters must expose only the
  secure executor for mutation.
- The audit directory uses regular-file and no-symlink checks, but a hostile
  local process with concurrent filesystem control remains outside this
  cooperative trust model.

With these boundaries explicit and all fresh checks green, PMCP-023 can be
proposed as `DONE`. PMCP-024 should build durable history, retained blobs,
undo/redo/revert, deterministic batches, and the mutation admission gate on top
of this secure transaction path.
