import { spawn, type ChildProcessWithoutNullStreams } from "node:child_process";
import { createHash, randomUUID } from "node:crypto";
import { existsSync } from "node:fs";
import { mkdtemp, readdir, readFile, rm, stat } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { createInterface } from "node:readline";

import type { JsonRecord } from "./authoring_client.js";
import type { MemoryArtifactReader } from "./artifacts.js";
import { PokeMapToolError } from "./tool_error.js";

export interface Render3dToolRequest {
  projectHandle: string;
  mapId: string;
  center?: { x: number; z: number };
  magnification: number;
  view: "game" | "top" | "orbit";
  minuteOfDay: number;
}

export interface Scan3dToolRequest {
  projectHandle: string;
  mapId: string;
  maxViews: number;
  magnification: number;
}

export type Scan3dExecutor = (
  projectRoot: string,
  request: Scan3dToolRequest,
) => Promise<{ data: JsonRecord; artifacts: JsonRecord[] }>;

export type Render3dExecutor = (
  projectRoot: string,
  request: Render3dToolRequest,
) => Promise<{ data: JsonRecord; artifacts: JsonRecord[] }>;

export interface NativeRenderHostOptions {
  resolveBinary: () => Promise<string>;
  requestTimeoutMs?: number;
  idleTimeoutMs?: number;
}

interface PendingRequest {
  resolve(response: JsonRecord): void;
  reject(error: Error): void;
  timer: NodeJS.Timeout;
}

/** One persistent native host process, serving one render at a time. */
export class NativeRenderHost {
  readonly #resolveBinary: () => Promise<string>;
  readonly #requestTimeoutMs: number;
  readonly #idleTimeoutMs: number;
  readonly #pending = new Map<string, PendingRequest>();
  #process: ChildProcessWithoutNullStreams | undefined;
  #stderrTail = "";
  #queue: Promise<unknown> = Promise.resolve();
  #idleTimer: NodeJS.Timeout | undefined;
  #closed = false;

  constructor(options: NativeRenderHostOptions) {
    this.#resolveBinary = options.resolveBinary;
    this.#requestTimeoutMs = options.requestTimeoutMs ?? 240_000;
    this.#idleTimeoutMs = options.idleTimeoutMs ?? 600_000;
  }

  get running(): boolean {
    return this.#process !== undefined;
  }

  request(command: string, args: JsonRecord = {}): Promise<JsonRecord> {
    const next = this.#queue.then(() => this.#send(command, args));
    this.#queue = next.catch(() => undefined);
    return next;
  }

  async close(): Promise<void> {
    this.#closed = true;
    clearTimeout(this.#idleTimer);
    await this.#stop();
  }

  async #send(command: string, args: JsonRecord): Promise<JsonRecord> {
    if (this.#closed) {
      throw new PokeMapToolError("render3d.host_closed", "The 3D render host has been closed.");
    }
    clearTimeout(this.#idleTimer);
    const child = await this.#ensureStarted();
    const id = randomUUID();
    const response = await new Promise<JsonRecord>((resolveResponse, reject) => {
      const timer = setTimeout(() => {
        this.#pending.delete(id);
        reject(new PokeMapToolError(
          "render3d.host_timeout",
          "The 3D render host did not answer in time; it has been stopped.",
          true,
          ["Retry the render; the host restarts on demand."],
          { command, timeoutMs: this.#requestTimeoutMs },
        ));
        void this.#stop();
      }, this.#requestTimeoutMs);
      this.#pending.set(id, { resolve: resolveResponse, reject, timer });
      child.stdin.write(`${JSON.stringify({ id, command, args })}\n`);
    });
    this.#idleTimer = setTimeout(() => void this.#stop(), this.#idleTimeoutMs);
    this.#idleTimer.unref();
    return response;
  }

  async #ensureStarted(): Promise<ChildProcessWithoutNullStreams> {
    if (this.#process) return this.#process;
    const binary = await this.#resolveBinary();
    const child = spawn(binary, [], { stdio: ["pipe", "pipe", "pipe"] });
    this.#process = child;
    this.#stderrTail = "";
    child.stderr.setEncoding("utf8");
    child.stderr.on("data", (chunk: string) => {
      this.#stderrTail = (this.#stderrTail + chunk).slice(-4096);
    });
    createInterface({ input: child.stdout }).on("line", (line) => {
      let message: unknown;
      try {
        message = JSON.parse(line);
      } catch {
        return;
      }
      if (!message || typeof message !== "object") return;
      const id = (message as JsonRecord).id;
      const pending = typeof id === "string" ? this.#pending.get(id) : undefined;
      if (!pending) return;
      this.#pending.delete(id as string);
      clearTimeout(pending.timer);
      pending.resolve(message as JsonRecord);
    });
    child.on("error", (error) => this.#fail(child, error.message));
    child.on("exit", (code, signal) => this.#fail(child, `exit ${signal ?? code}`));
    return child;
  }

  #fail(child: ChildProcessWithoutNullStreams, reason: string): void {
    if (this.#process !== child) return;
    this.#process = undefined;
    for (const [id, pending] of this.#pending) {
      this.#pending.delete(id);
      clearTimeout(pending.timer);
      pending.reject(new PokeMapToolError(
        "render3d.host_exited",
        "The 3D render host stopped before answering.",
        true,
        ["Retry the render; the host restarts on demand."],
        { reason, stderrTail: this.#stderrTail },
      ));
    }
  }

  async #stop(): Promise<void> {
    const child = this.#process;
    if (!child) return;
    this.#process = undefined;
    if (child.exitCode !== null || child.signalCode !== null) return;
    const exited = new Promise<void>((resolveExit) => child.once("exit", () => resolveExit()));
    child.stdin.end(`${JSON.stringify({ id: "shutdown", command: "shutdown" })}\n`);
    const forced = setTimeout(() => child.kill("SIGKILL"), 5_000);
    await exited;
    clearTimeout(forced);
  }
}

export interface RenderHostBuildOptions {
  hostRoot: string;
  repositoryRoot: string;
  flutterExecutable: string;
  buildTimeoutMs?: number;
  platform?: NodeJS.Platform;
}

const hostBinaryPath = "build/macos/Build/Products/Release/pokemap_render_host.app/Contents/MacOS/pokemap_render_host";
const hostSourceRoots = [
  "tools/pokemap_render_host/lib",
  "tools/pokemap_render_host/macos/Runner",
  "tools/pokemap_render_host/pubspec.yaml",
  "packages/map_core/lib",
  "packages/map_authoring/lib",
  "packages/map_render_3d/lib",
  "packages/map_render_3d/pubspec.yaml",
  "packages/avelune_rendering/lib",
  "third_party/flame_3d/lib",
];

/** Returns a release host binary no older than the sources it renders with. */
export function createRenderHostBinaryResolver(options: RenderHostBuildOptions): () => Promise<string> {
  let building: Promise<string> | undefined;
  return () => {
    building ??= resolveRenderHostBinary(options).finally(() => {
      building = undefined;
    });
    return building;
  };
}

async function resolveRenderHostBinary(options: RenderHostBuildOptions): Promise<string> {
  if ((options.platform ?? process.platform) !== "darwin") {
    throw new PokeMapToolError(
      "render3d.unsupported_platform",
      "Native 3D rendering currently requires macOS with Metal.",
    );
  }
  const binary = resolve(options.hostRoot, hostBinaryPath);
  const builtAt = existsSync(binary) ? (await stat(binary)).mtimeMs : 0;
  const newest = await newestModification(hostSourceRoots.map((path) => resolve(options.repositoryRoot, path)));
  if (builtAt > newest) return binary;
  const build = await runBuild(options);
  if (build.exitCode !== 0 || !existsSync(binary)) {
    throw new PokeMapToolError(
      "render3d.host_build_failed",
      "The native 3D render host could not be built.",
      false,
      ["Run `flutter build macos --release` in tools/pokemap_render_host to see the full error."],
      { exitCode: build.exitCode, outputTail: build.outputTail },
    );
  }
  return binary;
}

async function newestModification(paths: string[]): Promise<number> {
  let newest = 0;
  const visit = async (path: string): Promise<void> => {
    let entry;
    try {
      entry = await stat(path);
    } catch {
      return;
    }
    newest = Math.max(newest, entry.mtimeMs);
    if (!entry.isDirectory()) return;
    for (const child of await readdir(path)) {
      if (!child.startsWith(".")) await visit(join(path, child));
    }
  };
  await Promise.all(paths.map(visit));
  return newest;
}

function runBuild(options: RenderHostBuildOptions): Promise<{ exitCode: number | null; outputTail: string }> {
  return new Promise((resolveBuild) => {
    let outputTail = "";
    const child = spawn(options.flutterExecutable, ["build", "macos", "--release"], {
      cwd: options.hostRoot,
      stdio: ["ignore", "pipe", "pipe"],
    });
    const append = (chunk: Buffer) => {
      outputTail = (outputTail + chunk.toString("utf8")).slice(-4096);
    };
    child.stdout.on("data", append);
    child.stderr.on("data", append);
    const timer = setTimeout(() => child.kill("SIGKILL"), options.buildTimeoutMs ?? 900_000);
    child.on("error", (error) => {
      clearTimeout(timer);
      resolveBuild({ exitCode: null, outputTail: `${outputTail}\n${error.message}` });
    });
    child.on("exit", (exitCode) => {
      clearTimeout(timer);
      resolveBuild({ exitCode, outputTail });
    });
  });
}

/** Renders through the persistent host and registers the PNG as an opaque artifact. */
export function createNativeRender3dExecutor(options: {
  artifacts: MemoryArtifactReader;
  host: NativeRenderHost;
}): Render3dExecutor {
  return async (projectRoot, request) => {
    const temporaryRoot = await mkdtemp(join(tmpdir(), "pokemap-render3d-"));
    try {
      const outputPath = join(temporaryRoot, "render.png");
      const response = await options.host.request("render", {
        projectRoot,
        mapId: request.mapId,
        outputPath,
        ...(request.center ? { center: request.center } : {}),
        magnification: request.magnification,
        view: request.view,
        minuteOfDay: request.minuteOfDay,
      });
      if (response.status !== "success") {
        const error = isRecord(response.error) ? response.error : {};
        throw new PokeMapToolError(
          typeof error.code === "string" ? error.code : "render3d.failed",
          typeof error.message === "string" ? error.message : "The 3D render failed.",
        );
      }
      const bytes = await readFile(outputPath);
      const digest = createHash("sha256").update(bytes).digest("hex");
      const uri = `artifact://sha256/${digest}`;
      options.artifacts.registerBlob(uri, "image/png", bytes.toString("base64"));
      const data = isRecord(response.data) ? { ...response.data } : {};
      delete data.outputPath;
      return {
        data: { ...data, mimeType: "image/png" },
        artifacts: [{
          id: `render3d-${request.mapId}`,
          mediaType: "image/png",
          uri,
          byteLength: bytes.byteLength,
          sha256: digest,
        }],
      };
    } finally {
      await rm(temporaryRoot, { recursive: true, force: true });
    }
  };
}

/** Frames every gap cluster and Border/object overlap, measuring see-through holes. */
export function createNativeScan3dExecutor(options: {
  artifacts: MemoryArtifactReader;
  host: NativeRenderHost;
}): Scan3dExecutor {
  return async (projectRoot, request) => {
    const temporaryRoot = await mkdtemp(join(tmpdir(), "pokemap-scan3d-"));
    try {
      const response = await options.host.request("scan", {
        projectRoot,
        mapId: request.mapId,
        outputDirectory: temporaryRoot,
        maxViews: request.maxViews,
        magnification: request.magnification,
      });
      if (response.status !== "success") {
        const error = isRecord(response.error) ? response.error : {};
        throw new PokeMapToolError(
          typeof error.code === "string" ? error.code : "render3d.scan_failed",
          typeof error.message === "string" ? error.message : "The 3D scan failed.",
        );
      }
      const data = isRecord(response.data) ? { ...response.data } : {};
      const artifacts: JsonRecord[] = [];
      const views: JsonRecord[] = [];
      for (const [index, raw] of (Array.isArray(data.views) ? data.views : []).entries()) {
        if (!isRecord(raw) || typeof raw.outputPath !== "string") continue;
        const bytes = await readFile(resolve(temporaryRoot, raw.outputPath));
        const digest = createHash("sha256").update(bytes).digest("hex");
        const uri = `artifact://sha256/${digest}`;
        options.artifacts.registerBlob(uri, "image/png", bytes.toString("base64"));
        artifacts.push({
          id: `scan3d-${request.mapId}-${index}`,
          mediaType: "image/png",
          uri,
          byteLength: bytes.byteLength,
          sha256: digest,
        });
        const view: JsonRecord = { ...raw, artifactUri: uri };
        delete view.outputPath;
        views.push(view);
      }
      return { data: { ...data, views }, artifacts };
    } finally {
      await rm(temporaryRoot, { recursive: true, force: true });
    }
  };
}

function isRecord(value: unknown): value is JsonRecord {
  return Boolean(value) && typeof value === "object" && !Array.isArray(value);
}
