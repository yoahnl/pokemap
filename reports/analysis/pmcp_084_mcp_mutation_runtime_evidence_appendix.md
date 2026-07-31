# Appendice PMCP-084 — Contenu intégral des fichiers créés

Cet appendice accompagne `pmcp_084_mcp_mutation_runtime_evidence.md`.
Les rapports eux-mêmes ne sont pas reproduits récursivement.

## `packages/map_runtime/bin/pokemap_render.dart`

```dart
import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/authoring_preview/runtime_authoring_map_render_adapter.dart';

Future<void> main(List<String> arguments) async {
  try {
    final projectRoot = _parseRoot(arguments);
    final decoded = jsonDecode(await utf8.decoder.bind(stdin).join());
    if (decoded is! Map) throw const FormatException();
    final request = Map<String, dynamic>.from(decoded);
    _expectKeys(
      request,
      const {
        'mapId',
        'region',
        'layerIds',
        'overlays',
        'cellPixelSize',
      },
    );

    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: [projectRoot],
      fileReader: reader,
    );
    final handles = WorkspaceHandleStore();
    final opened = await ProjectOpenService(
      policy: policy,
      fileReader: reader,
      handles: handles,
    ).openProject(projectRoot);
    final snapshot = await ProjectSnapshotLoader(handles: handles).load(
      opened.projectHandle,
    );
    const queries = MapRenderQueries(RuntimeAuthoringMapRenderAdapter());
    final mapId = _string(request['mapId'], 'mapId');
    final layerIds = _strings(request['layerIds'], 'layerIds');
    final overlays = _overlays(request['overlays']);
    final cellPixelSize = _integer(
      request['cellPixelSize'] ?? 8,
      'cellPixelSize',
    );
    final region = _region(request['region']);
    final result = region == null
        ? await queries.renderMap(
            snapshot: snapshot,
            mapId: mapId,
            layerIds: layerIds,
            overlays: overlays,
            cellPixelSize: cellPixelSize,
          )
        : await queries.renderRegion(
            snapshot: snapshot,
            mapId: mapId,
            region: region,
            layerIds: layerIds,
            overlays: overlays,
            cellPixelSize: cellPixelSize,
          );
    final content = ContentArtifactRef.fromBytes(
      result.bytes,
      mediaType: result.mimeType,
    );
    stdout.write(
      jsonEncode({
        'status': 'success',
        'data': result.toJson(),
        'artifact': {
          'id': 'render-$mapId',
          'mediaType': result.mimeType,
          'uri': content.handle,
          'byteLength': content.byteLength,
          'sha256': content.hexDigest,
        },
        'blob': base64Encode(result.bytes),
      }),
    );
  } on FormatException {
    _writeFailure(
      'render.request_invalid',
      'The render request does not match the canonical contract.',
    );
    exitCode = 2;
  } on ArgumentError {
    _writeFailure(
      'render.request_invalid',
      'The render request does not match the canonical contract.',
    );
    exitCode = 2;
  } on ProjectSnapshotException catch (error) {
    _writeFailure(error.code, error.message);
    exitCode = 3;
  } on WorkspaceAccessException catch (error) {
    _writeFailure(error.code, error.message);
    exitCode = 3;
  } on Object {
    _writeFailure(
      'render.failed',
      'The revision-bound runtime render failed unexpectedly.',
    );
    exitCode = 3;
  }
}

String _parseRoot(List<String> arguments) {
  if (arguments.length != 2 || arguments.first != '--root') {
    throw const FormatException();
  }
  return _string(arguments[1], 'root');
}

void _expectKeys(Map<String, dynamic> value, Set<String> expected) {
  if (value.keys.toSet().difference(expected).isNotEmpty) {
    throw const FormatException();
  }
}

String _string(Object? value, String field) {
  if (value is! String || value.trim().isEmpty || value != value.trim()) {
    throw FormatException('$field must be nonblank and trimmed');
  }
  return value;
}

int _integer(Object? value, String field) {
  if (value is! int) throw FormatException('$field must be an integer');
  return value;
}

List<String> _strings(Object? value, String field) {
  if (value == null) return const [];
  if (value is! List) throw FormatException('$field must be a list');
  return List<String>.unmodifiable(
    value.map((entry) => _string(entry, field)),
  );
}

List<MapRenderOverlay> _overlays(Object? value) {
  return _strings(value, 'overlays').map((name) {
    return MapRenderOverlay.values.firstWhere(
      (candidate) => candidate.name == name,
      orElse: () => throw const FormatException(),
    );
  }).toList(growable: false);
}

MapRect? _region(Object? value) {
  if (value == null) return null;
  if (value is! Map) throw const FormatException();
  final json = Map<String, dynamic>.from(value);
  if (json.keys
          .toSet()
          .difference(const {'x', 'y', 'width', 'height'}).isNotEmpty ||
      json.length != 4) {
    throw const FormatException();
  }
  return MapRect(
    pos: GridPos(
      x: _integer(json['x'], 'region.x'),
      y: _integer(json['y'], 'region.y'),
    ),
    size: GridSize(
      width: _integer(json['width'], 'region.width'),
      height: _integer(json['height'], 'region.height'),
    ),
  );
}

void _writeFailure(String code, String message) {
  stdout.write(
    jsonEncode({
      'status': 'failure',
      'error': {'code': code, 'message': message},
    }),
  );
}
```

## `tools/pokemap_mcp/src/runtime_gateway.ts`

```typescript
import { spawn } from "node:child_process";
import { createHash, randomUUID } from "node:crypto";
import {
  readFile,
  readdir,
  realpath,
  stat,
} from "node:fs/promises";
import { dirname, extname, relative, resolve } from "node:path";

import type { JsonRecord, ProjectRootResolver } from "./authoring_client.js";
import type { MemoryArtifactReader } from "./artifacts.js";
import { PokeMapToolError } from "./tool_error.js";

export interface RenderToolRequest {
  projectHandle: string;
  mapId: string;
  region?: { x: number; y: number; width: number; height: number };
  layerIds: string[];
  overlays: string[];
  cellPixelSize: number;
}

export interface PlaytestToolRequest {
  projectHandle: string;
  scenarioId: string;
  target: "headless" | "interactive";
  policy?: "probe" | "certify";
}

export interface RuntimeToolResult {
  data: JsonRecord;
  artifacts?: JsonRecord[];
}

export interface RuntimeGateway {
  render(request: RenderToolRequest): Promise<RuntimeToolResult>;
  startPlaytest(request: PlaytestToolRequest): Promise<RuntimeToolResult>;
  getJob(jobId: string): Promise<RuntimeToolResult>;
  jobEvents(jobId: string, afterSequence: number): Promise<RuntimeToolResult>;
  cancelJob(jobId: string): Promise<RuntimeToolResult>;
  retryJob(jobId: string): Promise<RuntimeToolResult>;
  close(): Promise<void>;
}

export interface PlaytestExecutionContext {
  jobId: string;
  projectRoot: string;
  request: PlaytestToolRequest;
  signal: AbortSignal;
  emit(type: string, payload?: JsonRecord): void;
}

export type RenderExecutor = (
  projectRoot: string,
  request: RenderToolRequest,
) => Promise<RuntimeToolResult>;
export type PlaytestExecutor = (
  context: PlaytestExecutionContext,
) => Promise<RuntimeToolResult>;

export interface LocalRuntimeGatewayOptions {
  roots: ProjectRootResolver;
  artifacts: MemoryArtifactReader;
  runtimePackageRoot: string;
  runtimeHostRoot: string;
  repositoryRoot: string;
  dartExecutable?: string;
  renderExecutor?: RenderExecutor;
  playtestExecutor?: PlaytestExecutor;
  jobIdFactory?: () => string;
}

type JobState =
  | "queued"
  | "running"
  | "cancelling"
  | "succeeded"
  | "failed"
  | "cancelled";

interface JobEvent {
  sequence: number;
  type: string;
  state: JobState;
  occurredAtUtc: string;
  payload: JsonRecord;
}

interface JobRecord {
  jobId: string;
  request: PlaytestToolRequest;
  projectRoot: string;
  attempt: number;
  retryOfJobId?: string;
  state: JobState;
  createdAtUtc: string;
  updatedAtUtc: string;
  events: JobEvent[];
  controller: AbortController;
  completion?: Promise<void>;
  result?: RuntimeToolResult;
  error?: PokeMapToolError;
}

export class LocalRuntimeGateway implements RuntimeGateway {
  readonly #roots: ProjectRootResolver;
  readonly #renderExecutor: RenderExecutor;
  readonly #playtestExecutor: PlaytestExecutor;
  readonly #jobIdFactory: () => string;
  readonly #jobs = new Map<string, JobRecord>();
  #closed = false;

  constructor(options: LocalRuntimeGatewayOptions) {
    this.#roots = options.roots;
    this.#renderExecutor =
      options.renderExecutor ??
      createLocalRenderExecutor({
        artifacts: options.artifacts,
        dartExecutable: options.dartExecutable ?? "dart",
        runtimePackageRoot: options.runtimePackageRoot,
      });
    this.#playtestExecutor =
      options.playtestExecutor ??
      createLocalPlaytestExecutor({
        artifacts: options.artifacts,
        dartExecutable: options.dartExecutable ?? "dart",
        repositoryRoot: options.repositoryRoot,
        runtimeHostRoot: options.runtimeHostRoot,
      });
    this.#jobIdFactory = options.jobIdFactory ?? (() => `job-${randomUUID()}`);
  }

  async render(request: RenderToolRequest): Promise<RuntimeToolResult> {
    this.#ensureOpen();
    return this.#renderExecutor(
      this.#roots.resolveProjectRoot(request.projectHandle),
      request,
    );
  }

  async startPlaytest(request: PlaytestToolRequest): Promise<RuntimeToolResult> {
    this.#ensureOpen();
    const record = this.#createJob(
      request,
      this.#roots.resolveProjectRoot(request.projectHandle),
      1,
    );
    record.completion = Promise.resolve().then(() => this.#run(record));
    return { data: this.#snapshot(record) };
  }

  async getJob(jobId: string): Promise<RuntimeToolResult> {
    const record = this.#requireJob(jobId);
    return {
      data: this.#snapshot(record),
      artifacts: record.result?.artifacts ?? [],
    };
  }

  async jobEvents(
    jobId: string,
    afterSequence: number,
  ): Promise<RuntimeToolResult> {
    const record = this.#requireJob(jobId);
    return {
      data: {
        jobId,
        events: record.events.filter(
          (event) => event.sequence > afterSequence,
        ),
      },
    };
  }

  async cancelJob(jobId: string): Promise<RuntimeToolResult> {
    const record = this.#requireJob(jobId);
    if (record.state === "cancelled") {
      return { data: this.#snapshot(record) };
    }
    if (isTerminal(record.state)) {
      throw new PokeMapToolError(
        "job.already_terminal",
        `Job ${jobId} is already ${record.state}.`,
      );
    }
    this.#emit(record, "job.cancelling", "cancelling");
    record.controller.abort();
    return { data: this.#snapshot(record) };
  }

  async retryJob(jobId: string): Promise<RuntimeToolResult> {
    this.#ensureOpen();
    const source = this.#requireJob(jobId);
    if (source.state !== "failed" && source.state !== "cancelled") {
      throw new PokeMapToolError(
        "job.retry_forbidden",
        "Only failed or cancelled jobs can be retried.",
      );
    }
    const record = this.#createJob(
      source.request,
      source.projectRoot,
      source.attempt + 1,
      source.jobId,
    );
    record.completion = Promise.resolve().then(() => this.#run(record));
    return { data: this.#snapshot(record) };
  }

  async close(): Promise<void> {
    if (this.#closed) return;
    this.#closed = true;
    for (const record of this.#jobs.values()) {
      if (!isTerminal(record.state)) record.controller.abort();
    }
    await Promise.all(
      [...this.#jobs.values()].flatMap((record) =>
        record.completion ? [record.completion] : [],
      ),
    );
  }

  #createJob(
    request: PlaytestToolRequest,
    projectRoot: string,
    attempt: number,
    retryOfJobId?: string,
  ): JobRecord {
    const jobId = this.#jobIdFactory();
    if (!jobId || this.#jobs.has(jobId)) {
      throw new PokeMapToolError(
        "job.identity_invalid",
        "The runtime job identity is invalid or duplicated.",
      );
    }
    const now = new Date().toISOString();
    const record: JobRecord = {
      jobId,
      request: { ...request },
      projectRoot,
      attempt,
      ...(retryOfJobId ? { retryOfJobId } : {}),
      state: "queued",
      createdAtUtc: now,
      updatedAtUtc: now,
      events: [],
      controller: new AbortController(),
    };
    this.#jobs.set(jobId, record);
    this.#emit(record, "job.queued", "queued");
    return record;
  }

  async #run(record: JobRecord): Promise<void> {
    if (record.controller.signal.aborted) {
      this.#emit(record, "job.cancelled", "cancelled");
      return;
    }
    this.#emit(record, "job.running", "running");
    try {
      record.result = await this.#playtestExecutor({
        jobId: record.jobId,
        projectRoot: record.projectRoot,
        request: record.request,
        signal: record.controller.signal,
        emit: (type, payload = {}) => this.#emit(record, type, record.state, payload),
      });
      if (record.controller.signal.aborted) {
        this.#emit(record, "job.cancelled", "cancelled");
      } else {
        this.#emit(record, "job.succeeded", "succeeded");
      }
    } catch (error) {
      if (record.controller.signal.aborted) {
        this.#emit(record, "job.cancelled", "cancelled");
        return;
      }
      record.error =
        error instanceof PokeMapToolError
          ? error
          : new PokeMapToolError(
              "playtest.failed",
              "The sandboxed playtest failed unexpectedly.",
            );
      this.#emit(record, "job.failed", "failed", {
        errorCode: record.error.code,
        message: record.error.message,
      });
    }
  }

  #emit(
    record: JobRecord,
    type: string,
    state: JobState,
    payload: JsonRecord = {},
  ): void {
    record.state = state;
    record.updatedAtUtc = new Date().toISOString();
    record.events.push({
      sequence: record.events.length + 1,
      type,
      state,
      occurredAtUtc: record.updatedAtUtc,
      payload,
    });
  }

  #snapshot(record: JobRecord): JsonRecord {
    return {
      jobId: record.jobId,
      request: {
        projectHandle: record.request.projectHandle,
        scenarioId: record.request.scenarioId,
        target: record.request.target,
        ...(record.request.policy ? { policy: record.request.policy } : {}),
      },
      attempt: record.attempt,
      state: record.state,
      createdAtUtc: record.createdAtUtc,
      updatedAtUtc: record.updatedAtUtc,
      lastEventSequence: record.events.length,
      ...(record.retryOfJobId ? { retryOfJobId: record.retryOfJobId } : {}),
      ...(record.result ? { result: record.result.data } : {}),
      ...(record.error
        ? {
            error: {
              code: record.error.code,
              message: record.error.message,
              retryable: record.error.retryable,
              remediation: [...record.error.remediation],
            },
          }
        : {}),
    };
  }

  #requireJob(jobId: string): JobRecord {
    const record = this.#jobs.get(jobId);
    if (!record) {
      throw new PokeMapToolError("job.unknown", "The runtime job is unknown.");
    }
    return record;
  }

  #ensureOpen(): void {
    if (this.#closed) {
      throw new PokeMapToolError("runtime.closed", "The runtime gateway is closed.");
    }
  }
}

interface RenderExecutorOptions {
  artifacts: MemoryArtifactReader;
  dartExecutable: string;
  runtimePackageRoot: string;
}

function createLocalRenderExecutor(
  options: RenderExecutorOptions,
): RenderExecutor {
  return async (projectRoot, request) => {
    const result = await runProcess(
      options.dartExecutable,
      ["run", "bin/pokemap_render.dart", "--root", projectRoot],
      options.runtimePackageRoot,
      JSON.stringify({
        mapId: request.mapId,
        ...(request.region ? { region: request.region } : {}),
        layerIds: request.layerIds,
        overlays: request.overlays,
        cellPixelSize: request.cellPixelSize,
      }),
      undefined,
      30_000,
    );
    const decoded = decodeRecord(result.stdout, "render.response_invalid");
    if (decoded.status !== "success") {
      const error = isRecord(decoded.error) ? decoded.error : {};
      throw new PokeMapToolError(
        typeof error.code === "string" ? error.code : "render.failed",
        typeof error.message === "string"
          ? error.message
          : "The revision-bound runtime render failed.",
      );
    }
    if (
      !isRecord(decoded.data) ||
      !isRecord(decoded.artifact) ||
      typeof decoded.blob !== "string" ||
      typeof decoded.artifact.uri !== "string" ||
      typeof decoded.artifact.mediaType !== "string"
    ) {
      throw new PokeMapToolError(
        "render.response_invalid",
        "The runtime render returned an invalid artifact envelope.",
      );
    }
    options.artifacts.registerBlob(
      decoded.artifact.uri,
      decoded.artifact.mediaType,
      decoded.blob,
    );
    return { data: decoded.data, artifacts: [decoded.artifact] };
  };
}

interface PlaytestExecutorOptions {
  artifacts: MemoryArtifactReader;
  dartExecutable: string;
  repositoryRoot: string;
  runtimeHostRoot: string;
}

function createLocalPlaytestExecutor(
  options: PlaytestExecutorOptions,
): PlaytestExecutor {
  return async ({ projectRoot, request, signal, emit }) => {
    const scenario = await resolveScenario(options, projectRoot, request.scenarioId);
    emit("playtest.scenario_resolved", { scenarioId: request.scenarioId });
    const args = [
      "run",
      "tool/pokemap_eval.dart",
      "run",
      request.scenarioId,
      "--json",
      "--target",
      request.target,
      ...(request.policy ? ["--policy", request.policy] : []),
    ];
    const execution = await runProcess(
      options.dartExecutable,
      args,
      options.runtimeHostRoot,
      undefined,
      signal,
      180_000,
    );
    const summary = decodeRecord(execution.stdout, "playtest.response_invalid");
    if (execution.exitCode !== 0 || summary.status !== "succeeded") {
      throw new PokeMapToolError(
        "playtest.scenario_failed",
        "The sandboxed evaluation scenario did not succeed.",
        false,
        ["Inspect the job events and correct the project or scenario."],
        { scenarioId: scenario.id, exitCode: execution.exitCode },
      );
    }
    const receiptPath = summary.receiptPath;
    if (typeof receiptPath !== "string") {
      throw new PokeMapToolError(
        "playtest.receipt_missing",
        "The successful playtest did not return a receipt.",
      );
    }
    const collected = await collectEvaluationArtifacts(
      options,
      receiptPath,
    );
    emit("playtest.artifacts_collected", {
      artifactCount: collected.artifacts.length,
    });
    const safeSummary = { ...summary };
    delete safeSummary.receiptPath;
    return {
      data: {
        ...safeSummary,
        receipt: collected.receipt,
      },
      artifacts: collected.artifacts,
    };
  };
}

async function resolveScenario(
  options: PlaytestExecutorOptions,
  projectRoot: string,
  scenarioId: string,
): Promise<JsonRecord> {
  const scenarioRoot = resolve(
    options.runtimeHostRoot,
    "evaluation/scenarios",
  );
  const candidates = await jsonFiles(scenarioRoot);
  const matches: JsonRecord[] = [];
  for (const file of candidates) {
    const decoded = decodeRecord(await readFile(file, "utf8"), "playtest.scenario_invalid");
    if (decoded.id === scenarioId) matches.push(decoded);
  }
  if (matches.length !== 1 || typeof matches[0]?.projectId !== "string") {
    throw new PokeMapToolError(
      "playtest.scenario_unknown",
      "The requested playtest scenario is unknown or ambiguous.",
      false,
      ["Choose one scenario id returned by the PokeMap evaluation catalog."],
    );
  }
  const actualRoot = await realpath(projectRoot);
  const expectedRoot = await realpath(resolve(options.repositoryRoot, matches[0].projectId));
  if (actualRoot !== expectedRoot) {
    throw new PokeMapToolError(
      "playtest.project_mismatch",
      "The scenario is not bound to the opened project handle.",
    );
  }
  return matches[0];
}

async function jsonFiles(root: string): Promise<string[]> {
  const entries = await readdir(root, { withFileTypes: true });
  const files: string[] = [];
  for (const entry of entries) {
    const path = resolve(root, entry.name);
    if (entry.isDirectory()) files.push(...(await jsonFiles(path)));
    else if (entry.isFile() && extname(entry.name) === ".json") files.push(path);
  }
  return files.sort();
}

async function collectEvaluationArtifacts(
  options: PlaytestExecutorOptions,
  receiptPath: string,
): Promise<{ receipt: JsonRecord; artifacts: JsonRecord[] }> {
  const root = await realpath(options.repositoryRoot);
  const receiptFile = await boundedFile(resolve(root, receiptPath), root);
  const receiptBytes = await readFile(receiptFile);
  const receipt = decodeRecord(receiptBytes.toString("utf8"), "playtest.receipt_invalid");
  const declared = receipt.artifacts;
  if (!Array.isArray(declared) || declared.some((value) => typeof value !== "string")) {
    throw new PokeMapToolError(
      "playtest.receipt_invalid",
      "The playtest receipt has an invalid artifact list.",
    );
  }
  const files = [receiptFile];
  for (const declaredPath of declared as string[]) {
    if (
      declaredPath.length === 0 ||
      resolve(dirname(receiptFile), declaredPath) === root ||
      declaredPath.split(/[\\/]/u).includes("..")
    ) {
      throw new PokeMapToolError(
        "playtest.artifact_path_invalid",
        "A playtest artifact path is invalid.",
      );
    }
    files.push(await boundedFile(resolve(dirname(receiptFile), declaredPath), root));
  }
  const artifacts: JsonRecord[] = [];
  for (let index = 0; index < files.length; index += 1) {
    const file = files[index]!;
    const bytes = await readFile(file);
    const digest = createHash("sha256").update(bytes).digest("hex");
    const uri = `artifact://sha256/${digest}`;
    const mediaType = mediaTypeFor(file, index === 0);
    options.artifacts.registerBlob(uri, mediaType, bytes.toString("base64"));
    artifacts.push({
      id: index === 0 ? "receipt" : `artifact-${index}`,
      mediaType,
      uri,
      byteLength: bytes.length,
      sha256: digest,
    });
  }
  // The evaluator persists relative paths in its private receipt. MCP clients
  // receive only the same evidence with those paths replaced by opaque links.
  const publicReceipt: JsonRecord = { ...receipt, artifacts };
  delete publicReceipt.relativeReceiptPath;
  return { receipt: publicReceipt, artifacts };
}

async function boundedFile(candidate: string, root: string): Promise<string> {
  const resolved = await realpath(candidate);
  const rel = relative(root, resolved);
  if (rel === "" || rel === ".." || rel.startsWith(`..${process.platform === "win32" ? "\\" : "/"}`)) {
    throw new PokeMapToolError(
      "playtest.artifact_escape",
      "A playtest artifact escaped the repository boundary.",
    );
  }
  if (!(await stat(resolved)).isFile()) {
    throw new PokeMapToolError(
      "playtest.artifact_unavailable",
      "A declared playtest artifact is unavailable.",
    );
  }
  return resolved;
}

function mediaTypeFor(path: string, receipt: boolean): string {
  if (receipt) return "application/json";
  return (
    {
      ".json": "application/json",
      ".jsonl": "application/x-ndjson",
      ".png": "image/png",
      ".jpg": "image/jpeg",
      ".jpeg": "image/jpeg",
      ".webp": "image/webp",
    } as Record<string, string>
  )[extname(path).toLowerCase()] ?? "text/plain";
}

async function runProcess(
  command: string,
  args: string[],
  cwd: string,
  input?: string,
  signal?: AbortSignal,
  timeoutMs = 30_000,
): Promise<{ stdout: string; exitCode: number }> {
  return new Promise((resolveResult, reject) => {
    const grouped = process.platform !== "win32";
    const child = spawn(command, args, {
      cwd,
      detached: grouped,
      stdio: ["pipe", "pipe", "pipe"],
    });
    const stdout: Buffer[] = [];
    let stdoutBytes = 0;
    let settled = false;
    let abortTimer: NodeJS.Timeout | undefined;
    const kill = (processSignal: NodeJS.Signals) => {
      if (child.pid && grouped) {
        try {
          process.kill(-child.pid, processSignal);
          return;
        } catch {
          // The process may already have exited; fall back to the child handle.
        }
      }
      child.kill(processSignal);
    };
    const finish = (operation: () => void) => {
      if (settled) return;
      settled = true;
      clearTimeout(timer);
      if (abortTimer) clearTimeout(abortTimer);
      signal?.removeEventListener("abort", abort);
      operation();
    };
    const abort = () => {
      kill("SIGTERM");
      abortTimer = setTimeout(() => kill("SIGKILL"), 2_000);
      abortTimer.unref();
    };
    signal?.addEventListener("abort", abort, { once: true });
    const timer = setTimeout(() => {
      kill("SIGKILL");
      finish(() =>
        reject(
          new PokeMapToolError(
            "runtime.timeout",
            "The runtime process exceeded its bounded execution time.",
            true,
          ),
        ),
      );
    }, timeoutMs);
    timer.unref();
    if (signal?.aborted) abort();
    child.stdout.on("data", (chunk: Buffer) => {
      stdoutBytes += chunk.length;
      if (stdoutBytes > 32 * 1024 * 1024) {
        kill("SIGKILL");
        finish(() =>
          reject(
            new PokeMapToolError(
              "runtime.output_too_large",
              "The runtime process exceeded its output limit.",
            ),
          ),
        );
        return;
      }
      stdout.push(chunk);
    });
    child.stderr.resume();
    child.once("error", () =>
      finish(() =>
        reject(
          new PokeMapToolError(
            "runtime.start_failed",
            "Unable to start the local PokeMap runtime process.",
          ),
        ),
      ),
    );
    child.once("close", (code) =>
      finish(() => {
        if (signal?.aborted) {
          reject(new PokeMapToolError("job.cancelled", "The runtime job was cancelled."));
        } else {
          resolveResult({
            stdout: Buffer.concat(stdout).toString("utf8").trim(),
            exitCode: code ?? 3,
          });
        }
      }),
    );
    child.stdin.end(input);
  });
}

function decodeRecord(value: string, code: string): JsonRecord {
  try {
    const decoded: unknown = JSON.parse(value);
    if (isRecord(decoded)) return decoded;
  } catch {
    // Normalized below.
  }
  throw new PokeMapToolError(code, "The runtime returned an invalid JSON envelope.");
}

function isRecord(value: unknown): value is JsonRecord {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function isTerminal(state: JobState): boolean {
  return state === "succeeded" || state === "failed" || state === "cancelled";
}
```

## `tools/pokemap_mcp/src/tool_error.ts`

```typescript
import type { JsonRecord } from "./authoring_client.js";

/**
 * Transport-safe error raised by MCP adapters outside the Dart worker.
 * Codes and remediation remain stable, while callers never receive private
 * process errors, command lines, or filesystem paths.
 */
export class PokeMapToolError extends Error {
  constructor(
    readonly code: string,
    message: string,
    readonly retryable = false,
    readonly remediation: readonly string[] = [],
    readonly details: JsonRecord = {},
  ) {
    super(message);
    this.name = "PokeMapToolError";
  }
}
```

## `tools/pokemap_mcp/src/tools/mutations.ts`

```typescript
import { type McpServer } from "@modelcontextprotocol/server";
import { z } from "zod";

import type { AuthoringGateway } from "../authoring_client.js";
import { PokeMapToolError } from "../tool_error.js";
import {
  authoringResult,
  mutationAnnotations,
  toolEnvelopeSchema,
} from "./result.js";

const jsonRecordSchema = z.record(z.string(), z.unknown());
const revisionSchema = z.string().regex(/^sha256:[0-9a-f]{64}$/);

export function registerMutationTools(
  server: McpServer,
  authoring: AuthoringGateway,
): void {
  server.registerTool(
    "pokemap_plan",
    {
      title: "Plan a PokeMap mutation",
      description:
        "Builds a revision-bound preview and planned receipt without writing project files.",
      inputSchema: z
        .object({
          projectHandle: z.string().min(1),
          request: z
            .object({
              requestId: z.string().min(1),
              actionId: z.string().min(1),
              actionVersion: z.number().int().positive(),
              workspaceHandle: z.string().min(1),
              parameters: jsonRecordSchema,
              expectedRevision: revisionSchema.optional(),
              idempotencyKey: z.string().min(1),
              dryRun: z.boolean().default(false),
              extensions: jsonRecordSchema.optional(),
            })
            .strict(),
        })
        .strict(),
      outputSchema: toolEnvelopeSchema,
      annotations: {
        ...mutationAnnotations,
        destructiveHint: false,
      },
    },
    async ({ projectHandle, request }) =>
      authoringResult(() =>
        authoring.request("plan", { projectHandle, request }),
      ),
  );

  server.registerTool(
    "pokemap_apply",
    {
      title: "Confirm or apply a PokeMap mutation",
      description:
        "Issues a plan-bound confirmation or applies a frozen plan with an explicit operation id.",
      inputSchema: z.discriminatedUnion("operation", [
        z
          .object({
            operation: z.literal("confirm"),
            projectHandle: z.string().min(1),
            planId: z.string().min(1),
          })
          .strict(),
        z
          .object({
            operation: z.literal("apply"),
            projectHandle: z.string().min(1),
            planId: z.string().min(1),
            operationId: z.string().min(1),
            confirmationToken: z.string().min(1).optional(),
          })
          .strict(),
      ]),
      outputSchema: toolEnvelopeSchema,
      annotations: mutationAnnotations,
    },
    async (input) =>
      input.operation === "confirm"
        ? authoringResult(() =>
            authoring.request("confirm", {
              projectHandle: input.projectHandle,
              planId: input.planId,
            }),
          )
        : authoringResult(() =>
            authoring.request("apply", {
              projectHandle: input.projectHandle,
              planId: input.planId,
              operationId: input.operationId,
              ...(input.confirmationToken
                ? { confirmationToken: input.confirmationToken }
                : {}),
            }),
          ),
  );

  server.registerTool(
    "pokemap_history",
    {
      title: "Inspect or undo PokeMap history",
      description:
        "Lists committed receipts with stable pagination or requests a revision-safe undo.",
      inputSchema: z.discriminatedUnion("operation", [
        z
          .object({
            operation: z.literal("list"),
            projectHandle: z.string().min(1),
            limit: z.number().int().min(1).max(100).default(20),
            cursor: z.string().min(1).optional(),
          })
          .strict(),
        z
          .object({
            operation: z.literal("undo"),
            projectHandle: z.string().min(1),
            entryId: z.string().min(1),
            idempotencyKey: z.string().min(1),
          })
          .strict(),
      ]),
      outputSchema: toolEnvelopeSchema,
      annotations: mutationAnnotations,
    },
    async (input) =>
      input.operation === "list"
        ? authoringResult(() =>
            authoring.request("history", {
              projectHandle: input.projectHandle,
              limit: input.limit,
              ...(input.cursor ? { cursor: input.cursor } : {}),
            }),
          )
        : authoringResult(() =>
            authoring.request("undo", {
              projectHandle: input.projectHandle,
              entryId: input.entryId,
              idempotencyKey: input.idempotencyKey,
            }),
          ),
  );

  server.registerTool(
    "pokemap_recovery",
    {
      title: "Recover a PokeMap transaction",
      description:
        "Resumes one recoverable transaction only after an exact human-readable confirmation phrase.",
      inputSchema: z
        .object({
          projectHandle: z.string().min(1),
          operationId: z.string().min(1),
          confirmation: z.string().min(1),
        })
        .strict(),
      outputSchema: toolEnvelopeSchema,
      annotations: mutationAnnotations,
    },
    async ({ projectHandle, operationId, confirmation }) => {
      const expected = `RECOVER ${operationId}`;
      if (confirmation !== expected) {
        return authoringResult(() =>
          Promise.reject(
            new PokeMapToolError(
              "confirmation.required",
              "Recovery requires the exact confirmation phrase.",
              false,
              [`Retry with confirmation exactly equal to \"${expected}\".`],
              { expectedConfirmation: expected },
            ),
          ),
        );
      }
      return authoringResult(() =>
        authoring.request("recover", { projectHandle, operationId }),
      );
    },
  );
}
```

## `tools/pokemap_mcp/src/tools/result.ts`

```typescript
import { z } from "zod";

import {
  AuthoringClientError,
  type AuthoringWorkerSuccess,
  type JsonRecord,
} from "../authoring_client.js";
import { ArtifactReadError } from "../artifacts.js";
import { PokeMapToolError } from "../tool_error.js";

const jsonRecordSchema = z.record(z.string(), z.unknown());
const artifactReferenceSchema = z.record(z.string(), z.unknown());
const errorSchema = z.object({
  code: z.string(),
  domainCode: z.string().optional(),
  message: z.string(),
  retryable: z.boolean(),
  remediation: z.array(z.string()),
  details: jsonRecordSchema,
});

export const toolEnvelopeSchema = z.object({
  ok: z.boolean(),
  data: jsonRecordSchema,
  artifacts: z.array(artifactReferenceSchema),
  error: errorSchema.optional(),
});

export const readOnlyAnnotations = {
  readOnlyHint: true,
  destructiveHint: false,
  idempotentHint: true,
  openWorldHint: false,
} as const;

export const mutationAnnotations = {
  readOnlyHint: false,
  destructiveHint: true,
  idempotentHint: true,
  openWorldHint: false,
} as const;

export async function authoringResult(
  operation: () => Promise<AuthoringWorkerSuccess>,
) {
  try {
    const result = await operation();
    return operationSuccess(result.data, result.artifacts);
  } catch (error) {
    return failureEnvelope(error);
  }
}

export async function toolResult(
  operation: () => Promise<{ data: JsonRecord; artifacts?: JsonRecord[] }>,
) {
  try {
    const result = await operation();
    return operationSuccess(result.data, result.artifacts ?? []);
  } catch (error) {
    return failureEnvelope(error);
  }
}

export function successEnvelope(
  data: JsonRecord,
  artifacts: JsonRecord[],
): JsonRecord {
  return { ok: true, data, artifacts };
}

export function failureEnvelope(error: unknown) {
  const failure = normalizeError(error);
  return {
    isError: true,
    content: [
      {
        type: "text" as const,
        text: `${failure.code}: ${failure.message}`,
      },
    ],
    structuredContent: {
      ok: false,
      data: {},
      artifacts: [],
      error: failure,
    },
  };
}

function operationSuccess(data: JsonRecord, artifacts: JsonRecord[]) {
  return {
    content: [{ type: "text" as const, text: JSON.stringify(data) }],
    structuredContent: successEnvelope(data, artifacts),
  };
}

function normalizeError(error: unknown) {
  if (error instanceof AuthoringClientError) {
    return {
      code: error.code,
      ...(error.domainCode ? { domainCode: error.domainCode } : {}),
      message: error.message,
      retryable: error.retryable,
      remediation: [...error.remediation],
      details: error.details,
    };
  }
  if (error instanceof ArtifactReadError || error instanceof PokeMapToolError) {
    return {
      code: error.code,
      message: error.message,
      retryable:
        error instanceof PokeMapToolError ? error.retryable : false,
      remediation:
        error instanceof PokeMapToolError ? [...error.remediation] : [],
      details: error instanceof PokeMapToolError ? error.details : {},
    };
  }
  return {
    code: "mcp.internal",
    message: "The PokeMap MCP request failed unexpectedly.",
    retryable: false,
    remediation: [],
    details: {},
  };
}
```

## `tools/pokemap_mcp/src/tools/runtime.ts`

```typescript
import { type McpServer } from "@modelcontextprotocol/server";
import { z } from "zod";

import type { RuntimeGateway } from "../runtime_gateway.js";
import {
  mutationAnnotations,
  readOnlyAnnotations,
  toolEnvelopeSchema,
  toolResult,
} from "./result.js";

export function registerRuntimeTools(
  server: McpServer,
  runtime: RuntimeGateway,
): void {
  server.registerTool(
    "pokemap_render",
    {
      title: "Render a PokeMap snapshot",
      description:
        "Renders an explicit map or region at its current revision and returns an opaque image artifact handle.",
      inputSchema: z
        .object({
          projectHandle: z.string().min(1),
          mapId: z.string().min(1),
          region: z
            .object({
              x: z.number().int().nonnegative(),
              y: z.number().int().nonnegative(),
              width: z.number().int().positive(),
              height: z.number().int().positive(),
            })
            .strict()
            .optional(),
          layerIds: z.array(z.string().min(1)).default([]),
          overlays: z
            .array(z.enum(["collision", "zones", "warps", "entities"]))
            .default([]),
          cellPixelSize: z.number().int().min(1).max(64).default(8),
        })
        .strict(),
      outputSchema: toolEnvelopeSchema,
      annotations: readOnlyAnnotations,
    },
    async (request) =>
      toolResult(() =>
        runtime.render({
          projectHandle: request.projectHandle,
          mapId: request.mapId,
          ...(request.region ? { region: request.region } : {}),
          layerIds: request.layerIds,
          overlays: request.overlays,
          cellPixelSize: request.cellPixelSize,
        }),
      ),
  );

  server.registerTool(
    "pokemap_playtest",
    {
      title: "Start a sandboxed PokeMap playtest",
      description:
        "Starts a bounded evaluation job for a scenario bound to the opened project. Poll it with pokemap_job.",
      inputSchema: z
        .object({
          projectHandle: z.string().min(1),
          scenarioId: z.string().min(1),
          target: z.enum(["headless", "interactive"]).default("headless"),
          policy: z.enum(["probe", "certify"]).optional(),
        })
        .strict(),
      outputSchema: toolEnvelopeSchema,
      annotations: {
        ...mutationAnnotations,
        destructiveHint: false,
      },
    },
    async (request) =>
      toolResult(() =>
        runtime.startPlaytest({
          projectHandle: request.projectHandle,
          scenarioId: request.scenarioId,
          target: request.target,
          ...(request.policy ? { policy: request.policy } : {}),
        }),
      ),
  );

  server.registerTool(
    "pokemap_job",
    {
      title: "Manage a PokeMap runtime job",
      description:
        "Gets state, reads ordered events, cancels, or retries a playtest job. Terminal jobs expose receipt and artifact links.",
      inputSchema: z.discriminatedUnion("operation", [
        z
          .object({
            operation: z.literal("get"),
            jobId: z.string().min(1),
          })
          .strict(),
        z
          .object({
            operation: z.literal("events"),
            jobId: z.string().min(1),
            afterSequence: z.number().int().nonnegative().default(0),
          })
          .strict(),
        z
          .object({
            operation: z.literal("cancel"),
            jobId: z.string().min(1),
          })
          .strict(),
        z
          .object({
            operation: z.literal("retry"),
            jobId: z.string().min(1),
          })
          .strict(),
      ]),
      outputSchema: toolEnvelopeSchema,
      annotations: mutationAnnotations,
    },
    async (input) =>
      toolResult(() => {
        switch (input.operation) {
          case "get":
            return runtime.getJob(input.jobId);
          case "events":
            return runtime.jobEvents(input.jobId, input.afterSequence);
          case "cancel":
            return runtime.cancelJob(input.jobId);
          case "retry":
            return runtime.retryJob(input.jobId);
        }
      }),
  );
}
```

## `tools/pokemap_mcp/test/mutation_server.test.ts`

```typescript
import assert from "node:assert/strict";
import { mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { test } from "node:test";

import { Client } from "@modelcontextprotocol/client";
import { InMemoryTransport } from "@modelcontextprotocol/server";

import {
  AuthoringClientError,
  type AuthoringGateway,
  type JsonRecord,
  LocalAuthoringClient,
} from "../src/authoring_client.js";
import { MemoryArtifactReader } from "../src/artifacts.js";
import { createPokeMapMcpServer } from "../src/server.js";

const repositoryRoot = resolve(process.cwd(), "../..");
const authoringPackageRoot = resolve(repositoryRoot, "packages/map_authoring");
const scaffold = resolve(
  repositoryRoot,
  "examples/playable_runtime_host/phase6_authoring_golden_slice/project.json",
);

function record(value: unknown): JsonRecord {
  assert.ok(value && typeof value === "object" && !Array.isArray(value));
  return value as JsonRecord;
}

async function toolData(
  client: Client,
  name: string,
  args: JsonRecord,
): Promise<JsonRecord> {
  const result = await client.callTool({ name, arguments: args });
  assert.equal(result.isError, undefined, JSON.stringify(result.structuredContent));
  const envelope = record(result.structuredContent);
  assert.equal(envelope.ok, true);
  return record(envelope.data);
}

async function mutationFixture() {
  const root = await mkdtemp(join(tmpdir(), "pokemap-mcp-mutation-"));
  await writeFile(join(root, "project.json"), await readFile(scaffold));
  const authoring = new LocalAuthoringClient({
    allowedRoots: [root],
    authoringPackageRoot,
  });
  const server = createPokeMapMcpServer({
    authoring,
    artifacts: new MemoryArtifactReader(),
  });
  const [clientTransport, serverTransport] = InMemoryTransport.createLinkedPair();
  const client = new Client({ name: "pokemap-mutation-test", version: "1.0.0" });
  await server.connect(serverTransport);
  await client.connect(clientTransport);
  return { authoring, client, root, server };
}

test("MCP preserves CLI plan/apply parity for one complete map batch", async () => {
  const fixture = await mutationFixture();
  try {
    const opened = await toolData(fixture.client, "pokemap_workspace", {
      operation: "open",
      projectRoot: fixture.root,
    });
    const projectHandle = String(opened.projectHandle);
    const workspaceHandle = String(opened.workspaceHandle);
    const validation = await toolData(fixture.client, "pokemap_validate", {
      projectHandle,
    });

    const planned = await toolData(fixture.client, "pokemap_plan", {
      projectHandle,
      request: {
        requestId: "mcp-map-create",
        actionId: "map.create",
        actionVersion: 1,
        workspaceHandle,
        parameters: { mapId: "mcp_batch_map", width: 3, height: 2 },
        expectedRevision: validation.snapshotRevision,
        idempotencyKey: "idem-mcp-map-create",
        dryRun: false,
      },
    });
    assert.equal(record(planned.receipt).status, "planned");
    await assert.rejects(readFile(join(fixture.root, "maps/mcp_batch_map.json")));

    const applied = await toolData(fixture.client, "pokemap_apply", {
      operation: "apply",
      projectHandle,
      planId: planned.planId,
      operationId: "operation-mcp-map-create",
    });
    const retried = await toolData(fixture.client, "pokemap_apply", {
      operation: "apply",
      projectHandle,
      planId: planned.planId,
      operationId: "operation-mcp-map-create",
    });
    assert.deepEqual(retried, applied);

    const queried = await toolData(fixture.client, "pokemap_query", {
      projectHandle,
      resourceKind: "map",
      operation: "get",
      view: "detail",
      ids: ["mcp_batch_map"],
    });
    assert.equal(record((queried.items as unknown[])[0]).id, "mcp_batch_map");

    const history = await toolData(fixture.client, "pokemap_history", {
      operation: "list",
      projectHandle,
      limit: 1,
    });
    assert.equal((history.entries as unknown[]).length, 1);
    assert.equal(record((history.entries as unknown[])[0]).operationId, "operation-mcp-map-create");

    const afterValidation = await toolData(fixture.client, "pokemap_validate", {
      projectHandle,
    });
    assert.notEqual(afterValidation.snapshotRevision, validation.snapshotRevision);

    const batchPlan = await toolData(fixture.client, "pokemap_plan", {
      projectHandle,
      request: {
        requestId: "mcp-map-batch",
        actionId: "map.apply_operations",
        actionVersion: 1,
        workspaceHandle,
        parameters: {
          mapId: "mcp_batch_map",
          operations: [
            {
              kind: "layer.add",
              layerKind: "tile",
              layerId: "ground",
              name: "Ground",
            },
            {
              kind: "region.fill",
              layerId: "ground",
              x: 0,
              y: 0,
              width: 3,
              height: 2,
              value: 7,
            },
          ],
        },
        expectedRevision: afterValidation.snapshotRevision,
        idempotencyKey: "idem-mcp-map-batch",
        dryRun: false,
      },
    });
    assert.equal(record(batchPlan.receipt).status, "planned");
    const batchApplied = await toolData(fixture.client, "pokemap_apply", {
      operation: "apply",
      projectHandle,
      planId: batchPlan.planId,
      operationId: "operation-mcp-map-batch",
    });
    assert.equal(record(batchApplied.receipt).actionId, "map.apply_operations");

    const batchHistory = await toolData(fixture.client, "pokemap_history", {
      operation: "list",
      projectHandle,
      limit: 2,
    });
    assert.deepEqual(
      (batchHistory.entries as JsonRecord[]).map((entry) => entry.operationId),
      ["operation-mcp-map-batch", "operation-mcp-map-create"],
    );
  } finally {
    await fixture.client.close();
    await fixture.server.close();
    await fixture.authoring.close();
    await rm(fixture.root, { recursive: true, force: true });
  }
});

test("MCP returns a revision conflict without silently rebuilding the plan", async () => {
  const fixture = await mutationFixture();
  try {
    const opened = await toolData(fixture.client, "pokemap_workspace", {
      operation: "open",
      projectRoot: fixture.root,
    });
    const projectHandle = String(opened.projectHandle);
    const validation = await toolData(fixture.client, "pokemap_validate", {
      projectHandle,
    });
    const planned = await toolData(fixture.client, "pokemap_plan", {
      projectHandle,
      request: {
        requestId: "mcp-conflict",
        actionId: "map.create",
        actionVersion: 1,
        workspaceHandle: opened.workspaceHandle,
        parameters: { mapId: "conflicted_map", width: 2, height: 2 },
        expectedRevision: validation.snapshotRevision,
        idempotencyKey: "idem-mcp-conflict",
        dryRun: false,
      },
    });
    const manifestPath = join(fixture.root, "project.json");
    await writeFile(manifestPath, `${await readFile(manifestPath, "utf8")}\n`);

    const result = await fixture.client.callTool({
      name: "pokemap_apply",
      arguments: {
        operation: "apply",
        projectHandle,
        planId: planned.planId,
        operationId: "operation-mcp-conflict",
      },
    });
    assert.equal(result.isError, true);
    const error = record(record(result.structuredContent).error);
    assert.equal(error.code, "revision_conflict");
    assert.equal(error.retryable, true);
    await assert.rejects(readFile(join(fixture.root, "maps/conflicted_map.json")));
  } finally {
    await fixture.client.close();
    await fixture.server.close();
    await fixture.authoring.close();
    await rm(fixture.root, { recursive: true, force: true });
  }
});

test("recovery requires an exact confirmation and preserves permission errors", async () => {
  const calls: string[] = [];
  const authoring: AuthoringGateway = {
    async request(command) {
      calls.push(command);
      throw new AuthoringClientError(
        "permission_denied",
        "The actor lacks recovery permission.",
        false,
        ["Grant project.recovery before retrying."],
        { domainCode: "authorization.permission_denied" },
      );
    },
    async close() {},
  };
  const server = createPokeMapMcpServer({
    authoring,
    artifacts: new MemoryArtifactReader(),
  });
  const [clientTransport, serverTransport] = InMemoryTransport.createLinkedPair();
  const client = new Client({ name: "pokemap-recovery-test", version: "1.0.0" });
  await server.connect(serverTransport);
  await client.connect(clientTransport);
  try {
    const missingConfirmation = await client.callTool({
      name: "pokemap_recovery",
      arguments: {
        projectHandle: "project-test",
        operationId: "operation-recovery",
        confirmation: "yes",
      },
    });
    let error = record(record(missingConfirmation.structuredContent).error);
    assert.equal(error.code, "confirmation.required");
    assert.deepEqual(calls, []);

    const denied = await client.callTool({
      name: "pokemap_recovery",
      arguments: {
        projectHandle: "project-test",
        operationId: "operation-recovery",
        confirmation: "RECOVER operation-recovery",
      },
    });
    error = record(record(denied.structuredContent).error);
    assert.equal(error.code, "permission_denied");
    assert.equal(error.domainCode, "authorization.permission_denied");
    assert.deepEqual(calls, ["recover"]);
  } finally {
    await client.close();
    await server.close();
  }
});
```
## `tools/pokemap_mcp/test/runtime_server.test.ts`

```typescript
import assert from "node:assert/strict";
import { resolve } from "node:path";
import { setTimeout as delay } from "node:timers/promises";
import { test } from "node:test";

import { Client } from "@modelcontextprotocol/client";
import { InMemoryTransport } from "@modelcontextprotocol/server";

import { LocalAuthoringClient, type JsonRecord } from "../src/authoring_client.js";
import { MemoryArtifactReader } from "../src/artifacts.js";
import { LocalRuntimeGateway } from "../src/runtime_gateway.js";
import { createPokeMapMcpServer } from "../src/server.js";

const repositoryRoot = resolve(process.cwd(), "../..");
const projectRoot = resolve(
  repositoryRoot,
  "examples/playable_runtime_host/golden_fangame_slice",
);

function record(value: unknown): JsonRecord {
  assert.ok(value && typeof value === "object" && !Array.isArray(value));
  return value as JsonRecord;
}

async function tool(
  client: Client,
  name: string,
  args: JsonRecord,
): Promise<{ data: JsonRecord; artifacts: JsonRecord[] }> {
  const result = await client.callTool({ name, arguments: args });
  assert.equal(result.isError, undefined, JSON.stringify(result.structuredContent));
  const envelope = record(result.structuredContent);
  assert.equal(envelope.ok, true);
  return {
    data: record(envelope.data),
    artifacts: envelope.artifacts as JsonRecord[],
  };
}

async function runtimeFixture() {
  const authoring = new LocalAuthoringClient({
    allowedRoots: [projectRoot],
    authoringPackageRoot: resolve(repositoryRoot, "packages/map_authoring"),
  });
  const artifacts = new MemoryArtifactReader();
  let nextJob = 0;
  let failOnce = true;
  const runtime = new LocalRuntimeGateway({
    roots: authoring,
    artifacts,
    runtimePackageRoot: resolve(repositoryRoot, "packages/map_runtime"),
    runtimeHostRoot: resolve(repositoryRoot, "examples/playable_runtime_host"),
    repositoryRoot,
    jobIdFactory: () => `job-test-${++nextJob}`,
    playtestExecutor: async ({ jobId, request, signal, emit }) => {
      emit("playtest.sandbox_started", { isolated: true });
      if (request.scenarioId === "slow.cancel") {
        await new Promise<never>((_resolve, reject) => {
          signal.addEventListener(
            "abort",
            () => reject(new Error("cancelled")),
            { once: true },
          );
        });
      }
      if (request.scenarioId === "fail.once" && failOnce) {
        failOnce = false;
        throw new Error("controlled failure");
      }
      const uri = `artifact://sha256/${jobId.padEnd(64, "0").slice(0, 64)}`;
      artifacts.registerText(uri, "application/json", '{"sandboxed":true}');
      return {
        data: {
          receipt: {
            receiptId: `receipt-${jobId}`,
            scenarioId: request.scenarioId,
            terminalState: "stopped",
          },
        },
        artifacts: [
          {
            id: "receipt",
            uri,
            mediaType: "application/json",
          },
        ],
      };
    },
  });
  const server = createPokeMapMcpServer({ authoring, artifacts, runtime });
  const [clientTransport, serverTransport] = InMemoryTransport.createLinkedPair();
  const client = new Client({ name: "pokemap-runtime-test", version: "1.0.0" });
  await server.connect(serverTransport);
  await client.connect(clientTransport);
  const opened = await tool(client, "pokemap_workspace", {
    operation: "open",
    projectRoot,
  });
  return {
    authoring,
    artifacts,
    client,
    projectHandle: String(opened.data.projectHandle),
    runtime,
    server,
  };
}

async function terminalJob(client: Client, jobId: string): Promise<{
  data: JsonRecord;
  artifacts: JsonRecord[];
}> {
  for (let attempt = 0; attempt < 100; attempt += 1) {
    const snapshot = await tool(client, "pokemap_job", {
      operation: "get",
      jobId,
    });
    if (["succeeded", "failed", "cancelled"].includes(String(snapshot.data.state))) {
      return snapshot;
    }
    await delay(10);
  }
  assert.fail("runtime job did not reach a terminal state");
}

test("runtime MCP renders through map_runtime and registers opaque PNG bytes", async () => {
  const fixture = await runtimeFixture();
  try {
    const rendered = await tool(fixture.client, "pokemap_render", {
      projectHandle: fixture.projectHandle,
      mapId: "golden_town",
      cellPixelSize: 1,
      overlays: ["collision", "entities"],
    });
    assert.equal(rendered.data.mimeType, "image/png");
    assert.equal(rendered.data.width, 6);
    assert.equal(rendered.data.height, 5);
    assert.equal(rendered.artifacts.length, 1);
    const uri = String(rendered.artifacts[0]?.uri);
    assert.match(uri, /^artifact:\/\/sha256\/[0-9a-f]{64}$/);

    const artifact = await tool(fixture.client, "pokemap_artifact", { uri });
    assert.equal(artifact.data.mediaType, "image/png");
    assert.ok(Buffer.from(String(artifact.data.blob), "base64").subarray(0, 4).equals(
      Buffer.from([137, 80, 78, 71]),
    ));
  } finally {
    await fixture.client.close();
    await fixture.server.close();
    await fixture.runtime.close();
    await fixture.authoring.close();
  }
});

test("sandboxed playtest job returns receipt, artifacts and ordered events", async () => {
  const fixture = await runtimeFixture();
  try {
    const started = await tool(fixture.client, "pokemap_playtest", {
      projectHandle: fixture.projectHandle,
      scenarioId: "fake.sandbox",
    });
    const jobId = String(started.data.jobId);
    const terminal = await terminalJob(fixture.client, jobId);
    assert.equal(terminal.data.state, "succeeded");
    assert.equal(record(record(terminal.data.result).receipt).terminalState, "stopped");
    assert.equal(terminal.artifacts.length, 1);

    const events = await tool(fixture.client, "pokemap_job", {
      operation: "events",
      jobId,
      afterSequence: 0,
    });
    const values = events.data.events as JsonRecord[];
    assert.deepEqual(
      values.map((event) => event.sequence),
      values.map((_event, index) => index + 1),
    );
    assert.ok(values.some((event) => event.type === "playtest.sandbox_started"));
  } finally {
    await fixture.client.close();
    await fixture.server.close();
    await fixture.runtime.close();
    await fixture.authoring.close();
  }
});

test("playtest jobs support bounded cancellation", async () => {
  const fixture = await runtimeFixture();
  try {
    const started = await tool(fixture.client, "pokemap_playtest", {
      projectHandle: fixture.projectHandle,
      scenarioId: "slow.cancel",
    });
    const jobId = String(started.data.jobId);
    await tool(fixture.client, "pokemap_job", {
      operation: "cancel",
      jobId,
    });
    const terminal = await terminalJob(fixture.client, jobId);
    assert.equal(terminal.data.state, "cancelled");
  } finally {
    await fixture.client.close();
    await fixture.server.close();
    await fixture.runtime.close();
    await fixture.authoring.close();
  }
});

test("failed playtest jobs can be retried as a new traced attempt", async () => {
  const fixture = await runtimeFixture();
  try {
    const started = await tool(fixture.client, "pokemap_playtest", {
      projectHandle: fixture.projectHandle,
      scenarioId: "fail.once",
    });
    const failed = await terminalJob(fixture.client, String(started.data.jobId));
    assert.equal(failed.data.state, "failed");

    const retried = await tool(fixture.client, "pokemap_job", {
      operation: "retry",
      jobId: failed.data.jobId,
    });
    const succeeded = await terminalJob(fixture.client, String(retried.data.jobId));
    assert.equal(succeeded.data.state, "succeeded");
    assert.equal(succeeded.data.attempt, 2);
    assert.equal(succeeded.data.retryOfJobId, failed.data.jobId);
  } finally {
    await fixture.client.close();
    await fixture.server.close();
    await fixture.runtime.close();
    await fixture.authoring.close();
  }
});

test("production playtest rejects a scenario bound to another project", async () => {
  const authoring = new LocalAuthoringClient({
    allowedRoots: [projectRoot],
    authoringPackageRoot: resolve(repositoryRoot, "packages/map_authoring"),
  });
  const artifacts = new MemoryArtifactReader();
  const runtime = new LocalRuntimeGateway({
    roots: authoring,
    artifacts,
    runtimePackageRoot: resolve(repositoryRoot, "packages/map_runtime"),
    runtimeHostRoot: resolve(repositoryRoot, "examples/playable_runtime_host"),
    repositoryRoot,
    jobIdFactory: () => "job-project-mismatch",
  });
  try {
    const opened = await authoring.request("open", { projectRoot });
    const started = await runtime.startPlaytest({
      projectHandle: String(opened.data.projectHandle),
      scenarioId: "selbrume.healing-service",
      target: "headless",
    });
    const jobId = String(started.data.jobId);
    let snapshot = await runtime.getJob(jobId);
    for (let attempt = 0; attempt < 100 && snapshot.data.state !== "failed"; attempt += 1) {
      await delay(10);
      snapshot = await runtime.getJob(jobId);
    }
    assert.equal(snapshot.data.state, "failed");
    assert.equal(record(snapshot.data.error).code, "playtest.project_mismatch");
  } finally {
    await runtime.close();
    await authoring.close();
  }
});
```
