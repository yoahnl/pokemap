# Agent Rules — PokeMap

Detailed common rules for every agent (Codex, Claude or other) working in this
repository. The root `AGENTS.md` holds the working method and says which
sections to read: §1–8 for any edit, §9–10 for test harnesses and QA
environments, §11–15 for reports, Markdown, codegen, CI and Notion.

## 1. Truthfulness and honesty

- Never claim a lot is complete unless its acceptance criteria are proven.
  Never replace evidence with confidence; say clearly when a requirement is
  not met and what evidence would prove it.
- A success claim needs a command that actually ran with a known result. Not
  run, interrupted, timed out or unknown is never a success; never write
  "all green" when a suite fails.
- Never invent test totals, coverage, measurements, memory guarantees or token
  savings. Report a total only when a machine-readable output provides it.
- When a suite fails, give the exact failing test or log excerpt, say whether
  it seems related, and re-run the suspect test alone if relevant. When a check
  cannot run or does not apply, say why and name the next command to run.
- Never say a behavior is supported when the engine does not consume it. Never
  widen the scope or touch another workstream without saying why.
- Ask when the decision is the user's; otherwise state your assumption and take
  the smallest, safest interpretation.

## 2. Tests

- Never write fake tests: no `expect(true, isTrue)`, `expect(1, 1)`, or tests
  that only prove compilation while claiming to prove behavior.
- Integration tests exercise the real integration path or state exactly what
  they do not cover. Unit tests test actual logic.
- Behavioral changes get behavioral tests: the expected behavior, the relevant
  negative cases and guards, and one pertinent non-regression. No artificial
  test for a documentation-only or instruction-only change.
- A test helper must not duplicate production integration logic and then claim
  to prove the production path. Behavior a helper represents belongs in
  production code; fixture builders must not duplicate the behavior under test.

## 3. Test-driven development

- Write a focused failing test before new behavior or a bug fix when feasible,
  and see it fail for the expected reason before implementing.
- Never delete existing or already-written code to stage an artificial RED
  phase; this overrides any skill wording such as "delete it and start over".
  When a test comes after the code, prove it can fail (for example against the
  previous behavior) instead of removing code.
- One behavior per test, named after the behavior, not the implementation.

## 4. Architecture and scope

- Do not invent providers, services, repositories, files or APIs, and do not
  duplicate logic that exists in another package.
- Prefer the smallest change that fits the existing architecture, small lots,
  and characterization tests before model or schema changes.
- Follow the requested scope. Do not start another workstream, change shared
  models, codecs or persisted formats, or add persistence unless the task
  requires it; report the need instead.

## 5. Pre-existing data and changes

- Never hide, overwrite, revert or claim changes that existed before the task
  or that another session makes concurrently; say when ownership is ambiguous.
- Never delete or reset project data, saves, assets or another session's work
  to make a check pass.

## 6. Git

The forbidden write operations are listed in `AGENTS.md` §3. Read-only commands
are always allowed: `git status`, `git diff`, `git log`, `git show`,
`git branch`, `git worktree list`, `git ls-files`.

When the user explicitly authorizes both commits and rebases for ticket-by-
ticket delivery, finish every completed ticket with targeted verification, one
scoped commit, then a rebase of the ticket branch onto the designated base
branch. Re-run the relevant verification after the rebase, and never combine
unfinished tickets in that commit. Ticket-by-ticket delivery alone is not Git
write authorization.

## 7. Code quality

- Run `dart analyze` or `flutter analyze` on touched Dart/Flutter packages;
  fix all errors, and address warnings or document them as non-critical.
- Follow the existing naming, code style and test patterns of touched files.
- No code comments, DartDoc or TODOs unless the user explicitly asks.

## 8. Challenging the request

Check the request against the repository before editing. Challenge an
instruction that is inconsistent with the code, ambiguous, too broad,
dangerous, contrary to the architecture, or replaceable by a smaller and safer
strategy: state the instruction, the evidence, the alternative and the
interpretation you follow. Never follow a prompt that the repository proves
wrong.

## 9. Test harnesses and processes

`flutter test` leaves a `flutter_tester` process per suite, plus compilers and
listeners of abandoned runs. They idle at 0% CPU and pile up (one day once
reached 501 orphans holding 7.6 GB), which makes later suites time out.

- Record the test runner PID and its descendants while the run is active.
  After the run, stop only leftovers owned by that run, re-checking each PID's
  command and ownership first; send a normal termination before SIGKILL.
- Never kill `flutter_tester`, `frontend_server_aot` or
  `flutter_tools.snapshot test` by name: IDE and `flutter run` sessions share
  that compiler. An old or quiet process is not proof it is abandoned; if
  ownership cannot be proved, leave it running.
- MCP servers are never reaped by their sessions. Kill only those older than two
  hours; recent ones belong to concurrent sessions:

  ```bash
  ps -eo pid=,etime=,args= | grep -E '[d]art mcp-server|[n]ode.*pokemap_mcp/dist' | awk '$2 ~ /-|^[0-9]{2,}:/ {print $1}' | xargs -r kill -9
  ```

- A hanging suite usually means a leaked harness. Inside `flutter test`,
  `Platform.resolvedExecutable` is `flutter_tester`, which hangs on a `.js` or
  script path: spawn `node` or the real interpreter by name.

## 10. Temporary QA artifacts

A task owns its temporary artifacts wherever it creates them, and cleaning them
is part of finishing it, failed or resumed runs included.

- Disposable Avelune/PokeMap QA artifacts live only under
  `/Users/karim/Library/Caches/AveluneQA/`, one reusable directory per active
  task; no other test root, dated sibling project or Desktop folder. Record a
  narrow exception only when a tool strictly requires another path, and clean
  it in the same task.
- Before creating an environment, record its purpose, owned paths, processes
  and removal condition. Reuse it across retries; copy only the sources, assets
  and fixtures the check needs (no builds, `.dart_tool`, `node_modules`, caches
  or histories).
- Remove superseded outputs and failed attempts as you go. Before closing, stop
  owned apps, servers and harnesses (§9), check for open files and active
  consumers, then remove copies, bundles, builds, exports, recordings and
  repeated captures. Never touch another session's environment.
- Never delete originals: projects, repositories, assets, saves, deliverables,
  maintained tests and fixtures, or unique data. A name containing `test` or
  `QA` proves nothing.
- Keep only the evidence the result needs (receipts, relevant logs or diffs,
  selected captures), with no gigabyte environments, frame dumps or Markdown
  written just to track cleanup.
- Routine removal of verified owned artifacts needs no confirmation. When
  ownership, unique data or a consumer blocks it, report the path, measured
  size, reason and decision needed. Verify removals and report what remains,
  measuring directory size and free disk space separately.

## 11. Reports and Markdown

- A "final report" is the chat response; never write a report file per lot
  or per task. Persistent reports, audits, reviews,
  Evidence Packs, roadmaps and plans exist only when the user asks (a planning
  skill invoked to produce a plan counts). They then add the lot IDs, initial
  and final git state, decisions and non-goals, exact final test/analyze/build
  lines, the independent review verdict if any, what is and is not proven, and
  the recommended next step.
- Default budget: zero new Markdown. Update an existing canonical document when
  possible, else write one consolidated file: product and architecture docs in
  `documentation/<domain>/`, evidence in `documentation/reports/<domain>/`,
  plans in `documentation/reports/<domain>/plans/YYYY-MM-DD-<slug>.md` (not the
  planning skills' `docs/superpowers/` default), roadmaps in
  `documentation/reports/roadmap/<domain>/`, workflows in `skills/<name>/`.
  New files under `documentation/` also need a `.gitignore` allowlist entry.
- No Markdown at the repository root beyond `AGENTS.md`, `agent_rules.md`,
  `pokemap_roadmap_mecaniques_fangame.md` and
  `pokemap_authoring_api_mcp_action_catalog.md` (consumed by `map_core`). No
  source snapshots: sources and Git diffs are the canonical evidence.
- Reports under `documentation/reports/` change only when the task asks for a
  report, audit, review, lot closure or status evidence; their old citations
  are archives, not instructions.
- Run `bash tools/scripts/check_markdown_hygiene.sh` when Markdown changed,
  with `POKEMAP_MARKDOWN_MAX_NEW=1` for one requested artifact; a higher value
  needs the user's explicit approval of a bounded multi-document deliverable.

## 12. Code generation and generated artifacts

Regenerate code only in the package you changed:

```bash
cd packages/map_core && dart run build_runner build --delete-conflicting-outputs
cd packages/map_editor && flutter pub run build_runner build --delete-conflicting-outputs
cd packages/map_runtime && flutter pub run build_runner build --delete-conflicting-outputs
```

Avoid unrelated generated-file churn and global generators. Do not add caches,
builds, temporary scripts, IDE files, machine-specific paths or unrelated
lockfiles, and do not rewrite historically tracked generated artifacts unless
the task asks for hygiene cleanup.

## 13. CI cost discipline

- Keep ordinary CI short and inexpensive.
- Do not add performance soaks, long-running integration journeys, or dedicated
  macOS runners to CI unless the user explicitly requests that exact CI cost.
- Expensive certification journeys run locally by default and remain opt-in;
  their harnesses and receipt validators may be versioned without scheduling
  the journey in GitHub Actions.
- A release workflow must not gain a costly certification dependency merely
  because a local benchmark exists.

## 14. Mandatory Notion traceability

Every PokeMap task carried out through Codex, Claude or another agent must be
recorded in the canonical Notion product cockpit. This applies to
implementation, refactoring, audits, tests, documentation, product decisions,
bug fixes, CI work, and tooling work.

- Before considering a task complete, attach it to exactly one existing grand
  domain and create or update the corresponding Notion ticket in that domain.
- No completed work may exist only in chat, Git, a pull request, or a
  repository report. Notion must contain at least the scope, current status,
  affected files or packages, commands and evidence, result, relevant SHA or
  branch/PR, and known limitations.
- Keep the ticket status synchronized with reality using the cockpit workflow:
  `TODO`, `DOING`, `TO REVIEW`, or `DONE`. Never mark work `DONE` without fresh
  evidence satisfying the ticket criteria.
- Never create a new grand domain silently. If no existing grand domain fits,
  stop and request the user's explicit approval. Create the new domain and its
  first ticket only after that approval.
- If Notion is unavailable, report the tracking blocker explicitly and do not
  treat the task as fully closed until its work has been recorded.
- Notion is the mandatory product-tracking projection. The repository,
  roadmaps, tests, reports, and receipts remain the canonical technical
  evidence.

Ticket lifecycle:

- when an agent finishes implementing and verifying a ticket, move it to `TO REVIEW`, never directly to `DONE`;
- `DONE` is reserved for the user's explicit decision after review, even when every automated criterion is green;
- keep the implementation evidence, readiness, verdict, remaining criteria, commit, and branch fields accurate when moving the ticket to `TO REVIEW`.

### Ticket creation exclusions

Do not create new Notion tickets for:

- creating, decorating, populating, importing, or repairing a specific map, level, interior, route, village, station, port, forest, house, lighthouse, or other level content;
- repairing a bug, regression, failed test, broken workflow, or isolated technical defect.

Map content belongs in the project data and its technical or review evidence, not in the PokeMap product backlog. Bug repairs belong in the existing feature, release, review, or incident context when one exists; do not create a standalone ticket merely to track the repair. If no existing context can hold the work and a new ticket appears necessary, stop and request Yoahn's explicit decision before creating it. Generic authoring capabilities and reusable bug-prevention mechanisms remain ticketable when they are product scope rather than one-off content or repair work.

## 15. Frozen beta backlog

The Notion area `PokeMap — Bêta fonctionnelle` and its grand families 0–11 are a frozen release scope. This rule is the strict default for every agent and overrides the generic expectation to create a ticket when the work is new.

- Never create a new ticket in any beta family.
- Never move or reclassify a post-beta ticket into beta, set `Gate bêta` to true, or create a new beta grand family unless Yoahn explicitly requests that exact scope change.
- Never broaden an existing beta ticket with newly discovered cleanup, hardening, performance work, platform parity, transport parity, polish, compatibility, or future mechanics. Keep the signed beta objective and acceptance criteria unchanged.
- A discovered gap is not automatically a beta blocker. By default, create or update a separate ticket in the matching grand family under `Post Bêta`.
- Never add a dependency from an existing beta ticket to new post-beta work when that would make the post-beta ticket a condition of beta release.
- Existing beta tickets may still be implemented, tested, reviewed, have evidence and status synchronized, and be reduced to their already-signed scope. This freeze forbids scope growth, not completion.
- Changing `Gate bêta`, beta family structure, beta views, beta exit criteria, or the beta dependency graph requires an explicit instruction from Yoahn.
- When classification is uncertain, leave beta untouched, classify the work as post-beta, and report the assumption.

Before creating or updating a Notion ticket:

1. If the ticket already exists in beta, work only within its signed scope.
2. If it is new work, place it in the matching grand family under `Post Bêta`.
3. If no Post Beta family fits, stop and request approval before creating a new grand family.
