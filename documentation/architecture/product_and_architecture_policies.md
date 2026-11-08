# Product, Architecture and Operations Policies

Detailed rules that the root `AGENTS.md` routes to by task. They are not loaded
automatically, so `AGENTS.md` stays small enough for every client to load in
full; they remain mandatory for the tasks that trigger them. Open only the
section you need. The short invariants of `AGENTS.md` never relax them.

## Mandatory local and incremental authoring


**This is a blocking architecture and acceptance requirement for Avelune Studio,
the Map Editor and their shared authoring APIs. It is not optional polish.**
Yoahn reaffirmed this requirement on **2026-10-25** because disproportionate
work behind simple interactions was a reason for abandoning the former PokeMap.
Only a direct, explicit user instruction may authorize a bounded exception;
convenience, existing code, deadlines or another workflow do not authorize one.

- A local interaction (toggle, field edit, selection, placement, movement,
  rotation, deletion, brush stroke or undo/redo) must update the affected draft
  and preview incrementally. Its work must be bounded by the changed data and
  their actual dependencies, not unrelated project size or accumulated history.
- Never make a local edit, its first save, autosave or undo/redo trigger a full
  project snapshot/load, traversal of every map or resource, rehash/decode of
  unrelated assets, complete journal replay, global validation, renderer
  reconstruction, export or rebuild. Do not hide that work in a helper or
  require it as a prerequisite to completing the local operation.
- Persist through the canonical authoring boundary using targeted writes to the
  affected storage units. A shared document may require atomic replacement of
  that document; this does not justify loading or rewriting unrelated files.
  Preserve concurrent-write checks, crash safety, undo semantics and protected
  data compatibility. Never bypass these guarantees with an editor-only writer.
  If the current storage or transaction path cannot meet this requirement,
  report the architectural defect and correct the narrow owning boundary.
- Keep integrity and validation proportional to the mutation and its affected
  dependencies. Project-wide validation, export, migration and reconstruction
  belong to explicit operations with visible progress. Necessary initial
  project loading must be measured separately and must not recur per edit or
  be deferred onto the first save. Recovery must be explicit when required;
  routine edits must not silently replay the entire project history.
- An isolate, background queue, debounce, spinner or warm cache does not make
  disproportionate work acceptable. Caches may reduce necessary work, but a
  fast repeated operation does not excuse an expensive first operation.
  Do not acknowledge a durable save before persistence has actually succeeded.
- Before implementing a local authoring change, identify its affected storage
  units, dependency scope and latency budget. Default acceptance targets for a
  simple property edit on a documented representative local project are visible
  feedback within **100 ms** and durable persistence within **500 ms**, for
  both the first operation after opening and repeated operations. These are
  acceptance targets, not claims of existing performance. Any different budget
  requires explicit user agreement; never silently relax it to fit the result.
- Prove the real UI-to-persistence path with focused tests counting relevant
  reads, writes, decodes and invalidations, including added unrelated project
  content/history. Measure first and repeated latency separately, document the
  machine/build mode and verify persisted values after reopening. Use stable
  work-count assertions for regression tests and local timing measurements;
  do not add expensive CI soaks. Preserve API/CLI/MCP semantics and assess parity.
- A working button with excessive or unproven cost is **PARTIAL**, not ready
  for acceptance. Do not claim compliance from a small fixture, a warm-only
  benchmark, debug-only timing or source inspection. Apply this gate to new
  work and touched paths; never imply the whole existing editor is certified.

## Avelune project and exported game compatibility policy

Yoahn established the compatibility baseline on **2026-10-24**, at Avelune
Studio **0.3.31+331** (`apps/avelune_studio/pubspec.yaml`). This is a product
obligation; this rule alone does not certify implementation.

On **2026-11-08** Yoahn suspended this guarantee for player progression saves
(position, party, inventory, facts and progression). Those saves follow the
"Player progression saves" section of the root `AGENTS.md`: current-format
save/load stays reliable and tested, unsupported saves are reported without
touching the original, but older saves need no legacy reader or migration.
The rules below keep protecting authoring projects, maps and exported games,
and the non-destruction of any save file.

- Every valid native project and game package exported by Studio at this
  baseline or later must remain readable and playable by all subsequent
  Avelune Player/runtime releases on the platforms supporting that game's
  execution profile. The guarantee is cumulative: later exports acquire the
  same protection. Do not impose a rolling expiry or require a game update or
  re-export merely because the Player application was updated.
- Backward compatibility is mandatory even before `1.0.0`. A Player update
  must preserve protected games. A newer game may require a newer Player when
  its format or required capabilities are genuinely unknown to an older Player;
  future-format support is not promised.
- Keep application/build versions, game content versions, project/package/save
  formats and required runtime capabilities distinct. Never use release age,
  an exact application version match or a bare numeric format comparison as
  proof of incompatibility. Preserve previously supported capability semantics.
- Any format or persisted-behavior change affecting protected projects or games
  must retain a tested reader or provide an explicit, deterministic conversion
  into the current canonical model. This includes nested schemas and changed
  defaults within an unchanged top-level format. Keep compatibility handling at
  data boundaries rather than scattering legacy branches through gameplay.
  A player progression save change needs no legacy reader or conversion unless
  explicitly requested, but must identify the break and its save format version.
- Never silently drop required fields, commands, resources or progression to
  make a game load. Optional presentation degradation is allowed only when the
  contract explicitly defines it and gameplay/save semantics remain intact.
- Validate packages before conversion, preserve original package integrity
  evidence and perform conversions on copies. Any save migration that exists or
  is requested must preserve a recoverable original, validate the result and activate it transactionally.
  A failed load, conversion or update must not overwrite, delete or reset a
  game or save, or silently start a new game in place of the existing playthrough.
- For invalid, corrupted, unsafe or genuinely unsupported data, display a clear,
  actionable error identifying the cause and preserve recoverable originals.
  An error message does not satisfy the compatibility obligation for an otherwise
  valid protected game; such a failure is a regression to fix.
- Before shipping a relevant change, verify representative baseline and later
  exports through install/load, save and Continue on the current save format,
  and verify that failures and unknown future game or save formats leave
  original bytes intact. Record the
  exact fixtures, producer versions, commands, results and limits; do not claim
  all historical games are certified from a current-format fixture alone.
- Projects predating this baseline and obsolete internal APIs have no blanket
  compatibility guarantee. Preserve or convert them when explicitly requested
  or already covered by a protected contract; otherwise reject safely. Clean
  internal architecture remains the target, with protected data converted at
  the boundary when needed.

## Product rules and package boundaries

No-code first:

- guided pickers over manual IDs;
- previews over raw data;
- clear labels over engine jargon;
- validations before runtime surprises;
- no forced JSON editing for normal users.
- keep UI/editor work readable, validated and feedback-rich; do not expose
  engine internals as the normal workflow.

Design system first for `map_editor` UI:

- use only widgets from the PokeMap design system for editor UI primitives such as surfaces, panels, cards, buttons, icon buttons, badges, sidebars, toolbar controls, empty states, and repeated layout blocks;
- if the design system does not provide the needed primitive or variant, create a design-system widget or extend an existing one with focused flexibility before using local/ad hoc UI;
- never hardcode UI colors in feature screens or widgets: no direct `Color(0x...)`, `Colors.*`, or package palette constants for product UI;
- all UI colors must come from design-system/theme tokens such as `PokeMapColorTokens`, `context.pokeMapColors`, or semantic design-system helpers;
- new color values belong only in theme/design-system token definitions, with semantic names and existing light/dark behavior preserved.

Mechanics-first when requested:

```text
exploration -> event/dialogue -> encounter/battle -> reward/progression -> party/bag/PC -> save/story
```

Do not pivot from mechanics to shadows, surfaces, tileset polish, or rendering unless required by the lot.

PokeMap owns its data. Do not make Tiled, RMXP, Pokemon SDK, or other external editors/formats runtime requirements. They can inspire layouts/imports, but PokeMap must author and run its own project data.

Native map construction is mandatory for reconstructions as well as new maps:

- Paint repeatable ground through the native terrain system, and water and roads through connected native paths.
- Author shores, cliffs and relief edges with native Borders, including their contour and corner rules.
- Place complete reusable trees through the Environment/tree system, including their base when it belongs to the tree.
- Keep other objects complete and reusable. Border profile modules remain owned by their native contour; do not assemble terrain or objects from independently placed visual fragments.
- Verify visual fidelity and native editability separately. A matching screenshot alone does not prove that a map uses these systems.

Package boundaries:

- shared contracts and JSON models: `map_core`;
- pure overworld decisions: `map_gameplay`;
- battle mechanics: `map_battle`;
- runtime integration: `map_runtime`;
- authoring UI and editor use cases: `map_editor`;
- gameplay rules must not hide inside Flame components;
- schema changes usually require tests, fixtures, editor/runtime updates and an
  explicit schema-version change where applicable; changes affecting projects
  or exported games protected by the compatibility baseline require a tested
  compatibility path even before `1.0.0`; player progression save changes
  follow the root `AGENTS.md` save policy.

## Mandatory architecture boundaries and renderer independence


**Respect Avelune's architecture and dependency direction in every change.**
Replaceable infrastructure and external providers must be integrated through
Avelune-owned contracts and adapters. This is a blocking requirement, with
particular attention to the 3D renderer. For capabilities already covered by
those contracts, adding another engine must require its adapter, platform
integration and composition registration, without vendor-specific rewrites of
gameplay, story, sessions, project/save formats or editor commands.
Existing coupling is migration debt, not permission to extend it or proof that
the current code already satisfies this requirement. Only a direct, explicit
user instruction may authorize a bounded exception.

- Avelune owns the semantics of scenes, cameras, animation, asset identity,
  picking, visual profiles, capabilities, timing and renderer lifecycle.
  Keep provider-specific imports, scene objects, materials, textures, animation
  objects, ECS entities and GPU/native handles inside the provider adapter.
  Do not leak them through neutral public signatures, generics, callbacks,
  inheritance, exports, persisted data, aliases, casts or untyped escape hatches.
- Runtime and authoring consumers depend on Avelune contracts. Construct and
  select providers at composition boundaries through injected factories.
  Composition roots may import adapter entry points to register providers, but
  must not expose or manipulate vendor engine types.
  Do not spread engine checks or provider construction across gameplay, session
  logic or editor tools. Keep pure Dart contracts free of Flutter; widgets,
  canvas and image types belong only in separate presentation boundaries.
  Flutter UI and existing Flame 2D presentation remain valid in their own
  responsibilities. Ordinary data/math utilities do not need artificial wrappers.
- Separate scene semantics from their presentation surface. A provider may use
  Flutter GPU, an external texture or a native view, and may initialize, pick,
  prepare or present asynchronously. Do not require every renderer to expose
  a Flame Game, a Canvas-only synchronous draw or a specific GPU resource.
  Specify which readiness/presentation event is actually observable; submitting
  work or completing a Flutter frame is not a universal display acknowledgement.
- Keep simulation and story clocks under host ownership. Reading visual state,
  rendering, repainting, warm-up, capture, multiple views, skipped/repeated frames
  and retries must not implicitly advance gameplay, even with a zero time step.
  Define update, simulation pause, presentation pause and preparation semantics
  explicitly, without silently changing the gameplay time model.
- Define typed resource identities, ownership, sharing, budgets, generations,
  asynchronous readiness, cancellation, replacement, errors and idempotent
  disposal. Reject stale results and respect resources still in use. Keep source
  assets and protected project/save data independent of providers; compiled
  provider resources are rebuildable products, not their sole durable form.
- Preserve bounded incremental updates and the authoring and compatibility
  requirements above. Do not rebuild or reload an entire scene/project, decode
  or upload unrelated assets, or copy the complete world each frame to service
  a local mutation. Bounded updates and transfers for affected resources remain
  allowed. Keep batching, instancing and caching possible; do not hide vendor
  coupling in shared helpers or move gameplay authority into a provider's ECS.
- Declare supported capabilities and explicit unsupported/fallback behavior.
  Do not silently ignore required semantics or equate an adapter with automatic
  visual/performance parity. A genuinely new product capability may extend an
  Avelune contract with compatibility evidence; it must not enter through a
  provider-specific escape hatch. Hot-swapping engines during a live session
  is a separate capability, not an implicit requirement.
- Before adding a shared API or changing a rendering boundary, identify its
  owner, consumers and replacement contract. Verify allowed dependencies and
  exported types with focused checks and shared contract tests. A second real
  implementation must exercise the same contracts on a declared representative
  scope before claiming proven engine substitutability; a fake or renamed
  wrapper alone does not prove GPU integration, parity or performance.
  Address touched coupling in a scoped change; record other debt without
  silently starting an unrelated global refactor.

The detailed audit, migration boundaries and acceptance criteria are tracked in
[the renderer-independence issue](https://github.com/yoahnl/pokemap/issues/13).

## Gameplay mechanics roadmap procedure

For any fangame-mechanics task, read first, in `pokemap_roadmap_mecaniques_fangame.md`
(about 78 KB), the status rows and sections of the relevant `FG-*` lots, found by
searching their IDs. Read the whole file only for a roadmap-wide task.

Expected location: repository root. If missing, search once; if still missing, say so and do not invent roadmap status.

Mechanics work includes:

```text
new game, starter flow, party, PC/boxes, bag/items, shops,
healing, save/load gameplay, encounters, capture, trainer battles,
XP, level-up, move learning, evolution, rewards, badges, money,
field moves, hazards, story/event commands, runtime menus,
project playability validation, golden-slice runtime flow.
```

Before mechanics work: identify the relevant `FG-*` lot/gap, state it in your answer, and respect its done criteria.

After mechanics work: say in the chat answer whether each relevant lot remains `TODO`, `PARTIAL`, `BLOCKED`, or can be proposed as `DONE`. Never mark `DONE` without fresh proof: files changed, commands run, exact results, final git status, and known limits.

Update the roadmap only when the task explicitly asks. Otherwise, propose the status update in the chat answer. Do not write a report file per lot: since 2026-11-08 Yoahn wants none unless he asks for one.

When the user asks about fangame readiness, mechanics beat visual polish unless the current mechanic directly depends on visuals.

## Flame, runtime documentation and PSDK parity

For Flame APIs, runtime rendering, game loop, components, overlays, input, camera, asset loading, collision, or lifecycle, consult configured Flame docs first when available.

Expected MCP server:

```text
flame_docs
```

If unavailable: say so, inspect installed Flame version in `pubspec.yaml` / lockfile, search existing runtime code for working patterns, and avoid inventing Flame APIs.

PokeMap architecture wins over generic Flame examples: pure Dart packages stay Flutter/Flame-free, and gameplay rules stay out of runtime components.

### PSDK parity sources (on this machine, outside the repository)

Two checkouts are the parity oracle. They are NOT in this repository and never
get committed into it:

```text
/Users/karim/Project/pokemonProject autre dossiers/pokemonsdk-development/
/Users/karim/Project/pokemonProject autre dossiers/pokémon_sdk_test_project/
```

`pokemonsdk-development` is the PSDK engine itself — ~1500 Ruby files. The
directories that answer most questions:

| Path | Answers |
| --- | --- |
| `scripts/5 Battle/01 Scene` | battle scene flow, phase order, transitions |
| `scripts/5 Battle/20 MoveAnimation` | move animation choreography and timing |
| `scripts/5 Battle/04 Logic` | turn resolution and damage application order |
| `scripts/4 Systems` | audio, transitions, shared systems |

`pokémon_sdk_test_project` is a runnable RMXP/PSDK project: `audio/`,
`graphics/`, `Data/` hold the real asset layout and naming, which is what
settles questions a script alone cannot (which file plays when, how a cell zoom
is authored).

Rules:

- For any parity question — animation order, timing, zoom and scale conversions,
  audio triggers, transitions — the **Ruby source is authoritative**. Write the
  reference from it, never from the Dart code, and never from a web article.
  A web search is fine for general game-feel principles; it does not settle
  what PSDK does.
- Quote the Ruby file and line in the ticket or the commit, so the next reader
  can check the claim instead of trusting it.
- Never copy Ruby verbatim into Dart. Never copy code from the Showdown
  client either: it is AGPLv3, and reading it as a choreography reference is
  the only permitted use.
- Assets from the runnable test project MAY be embedded in the engine's
  runtime assets, following the existing precedent: the 181 RMXP animation
  sheets and the battle sound effects under
  `packages/map_runtime/assets/` were imported from it by the tools in
  `packages/map_runtime/tool/`. Yoahn designated these directories as the
  battle asset source on 2026-08-23. Always import through a rerunnable tool
  that records its source, never by hand-copying files.

## Test harnesses and processes

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

## Temporary QA artifacts

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
  owned apps, servers and harnesses (see Test harnesses and processes), check for open files and active
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

## Reports and Markdown

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
- No Markdown at the repository root beyond `AGENTS.md`,
  `pokemap_roadmap_mecaniques_fangame.md` and
  `pokemap_authoring_api_mcp_action_catalog.md` (consumed by `map_core`). No
  source snapshots: sources and Git diffs are the canonical evidence.
- Reports under `documentation/reports/` change only when the task asks for a
  report, audit, review, lot closure or status evidence; their old citations
  are archives, not instructions.
- Run `bash tools/scripts/check_markdown_hygiene.sh` when Markdown changed,
  with `POKEMAP_MARKDOWN_MAX_NEW=1` for one requested artifact; a higher value
  needs the user's explicit approval of a bounded multi-document deliverable.

## Code generation and generated artifacts

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

## CI cost discipline

- Keep ordinary CI short and inexpensive.
- Do not add performance soaks, long-running integration journeys, or dedicated
  macOS runners to CI unless the user explicitly requests that exact CI cost.
- Expensive certification journeys run locally by default and remain opt-in;
  their harnesses and receipt validators may be versioned without scheduling
  the journey in GitHub Actions.
- A release workflow must not gain a costly certification dependency merely
  because a local benchmark exists.

## Notion tickets and frozen beta

Notion tracking is not mandatory (Yoahn, 2026-11-08): finishing a task needs
no ticket, status update or report. Touch Notion only when Yoahn asks; then:

- attach the work to one existing grand domain; never create a grand domain
  without his explicit approval;
- move a verified ticket to `TO REVIEW`, never to `DONE`, which is Yoahn's
  decision; keep its evidence, commit and branch fields accurate;
- create no ticket for one-off map or level content or an isolated bug repair:
  they belong to an existing feature, release, review or incident context.

The Notion area `PokeMap — Bêta fonctionnelle` and its grand families 0–11 are a frozen release scope. This rule applies whenever an agent creates or updates a ticket.

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

## History

On 2026-11-08 the root `AGENTS.md` (42 KB, which Codex truncated at 32 KiB)
was reduced to an entry point; `codex_rule.md`, `agent_rules.md` and the unused
`.cursor/` folder were folded into it and into this document. Git keeps the
former texts.
