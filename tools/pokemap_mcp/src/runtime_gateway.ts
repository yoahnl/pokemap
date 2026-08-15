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
import type {
  CertifiedPlaytestProjection,
  PlaytestProjectionFactory,
} from "./playtest_projection.js";
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
  sourceProjectRoot: string;
  projectRelativeRoot: string;
  projectTreeHash: string;
  authoringRevision: string;
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
  playtestProjectionFactory?: PlaytestProjectionFactory;
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
  readonly #playtestProjectionFactory: PlaytestProjectionFactory;
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
    this.#playtestProjectionFactory =
      options.playtestProjectionFactory ?? unavailableProjectionFactory;
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
    let projection: CertifiedPlaytestProjection | undefined;
    try {
      projection = await this.#playtestProjectionFactory({
        jobId: record.jobId,
        projectHandle: record.request.projectHandle,
        sourceProjectRoot: record.projectRoot,
        request: record.request,
        signal: record.controller.signal,
        emit: (type, payload = {}) => this.#emit(record, type, record.state, payload),
      });
      if (record.controller.signal.aborted) {
        await projection.dispose();
        projection = undefined;
        this.#emit(record, "job.cancelled", "cancelled");
        return;
      }
      record.result = await this.#playtestExecutor({
        jobId: record.jobId,
        projectRoot: projection.projectRoot,
        sourceProjectRoot: record.projectRoot,
        projectRelativeRoot: projection.projectRelativeRoot,
        projectTreeHash: projection.projectTreeHash,
        authoringRevision: projection.authoringRevision,
        request: record.request,
        signal: record.controller.signal,
        emit: (type, payload = {}) => this.#emit(record, type, record.state, payload),
      });
      await projection.dispose();
      projection = undefined;
      if (record.controller.signal.aborted) {
        this.#emit(record, "job.cancelled", "cancelled");
      } else {
        this.#emit(record, "job.succeeded", "succeeded");
      }
    } catch (error) {
      if (projection) {
        try {
          await projection.dispose();
        } catch (cleanupError) {
          if (!(error instanceof PokeMapToolError)) error = cleanupError;
        }
        projection = undefined;
      }
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
  return async ({
    sourceProjectRoot,
    projectRelativeRoot,
    projectTreeHash,
    request,
    signal,
    emit,
  }) => {
    const scenario = await resolveScenario(
      options,
      sourceProjectRoot,
      request.scenarioId,
    );
    emit("playtest.scenario_resolved", { scenarioId: request.scenarioId });
    const args = [
      "run",
      "tool/pokemap_eval.dart",
      "run",
      request.scenarioId,
      "--json",
      "--project-root",
      projectRelativeRoot,
      "--expected-project-tree-hash",
      projectTreeHash,
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

const unavailableProjectionFactory: PlaytestProjectionFactory = async () => {
  throw new PokeMapToolError(
    "pokemon.catalog_not_ready",
    "The certified Pokemon playtest projection is unavailable.",
  );
};

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
