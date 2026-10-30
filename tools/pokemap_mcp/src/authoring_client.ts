import { spawn, type ChildProcessWithoutNullStreams } from "node:child_process";
import { stat } from "node:fs/promises";
import { isAbsolute, resolve } from "node:path";
import { createInterface, type Interface as ReadLineInterface } from "node:readline";
import type { PackagedWorkerCommand } from "./packaged_runtime.js";

export type JsonRecord = Record<string, unknown>;

/** Matches map_authoring.defaultAuthoringJsonlMaxInputBytes. */
export const DEFAULT_AUTHORING_MAX_INPUT_BYTES = 1024 * 1024;

export interface AuthoringWorkerError {
  code: string;
  message: string;
  retryable: boolean;
  remediation: string[];
  details: JsonRecord;
}

export interface AuthoringWorkerSuccess {
  requestId: string;
  data: JsonRecord;
  artifacts: JsonRecord[];
  receipt?: JsonRecord;
}

export interface AuthoringGateway {
  request(command: string, args?: JsonRecord): Promise<AuthoringWorkerSuccess>;
  close(): Promise<void>;
}

export interface ProjectRootResolver {
  resolveProjectRoot(projectHandle: string): string;
}

export class AuthoringClientError extends Error {
  constructor(
    readonly code: string,
    message: string,
    readonly retryable = false,
    readonly remediation: readonly string[] = [],
    readonly details: JsonRecord = {},
  ) {
    super(message);
    this.name = "AuthoringClientError";
  }

  get domainCode(): string | undefined {
    return typeof this.details.domainCode === "string"
      ? this.details.domainCode
      : undefined;
  }
}

export interface AuthoringMutationNotification {
  type: "mutation";
  projectRoot: string;
  revision: string;
  operationId?: string;
  resources: {kind: string; id: string}[];
}

function canonicalMutationResources(receipt: JsonRecord): unknown {
  if (!Array.isArray(receipt.affectedResources)) return receipt.affectedResources;
  const resources = [...receipt.affectedResources];
  const add = (kind: string, id: string): void => {
    if (!resources.some(value => isRecord(value) && value.kind === kind && value.id === id)) resources.push({kind,id});
  };
  const entries = isRecord(receipt.diff) ? receipt.diff.entries : undefined;
  if (!Array.isArray(entries)) return resources;
  for (const entry of entries) {
    if (!isRecord(entry) || !isRecord(entry.resource) ||
        !["project", "catalogHead"].includes(String(entry.resource.kind)) || typeof entry.path !== "string") continue;
    const segments = entry.path.split("/");
    if (segments.length >= 3 && segments[1] === "maps" && segments[2]) {
      add("mapMetadata", segments[2].replaceAll("~1", "/").replaceAll("~0", "~"));
    }
    for (const field of ["surf", "fieldAbilities", "audio"]) {
      if (entry.path === `/settings/${field}` || entry.path.startsWith(`/settings/${field}/`) ||
          entry.path === "/settings" && isRecord(entry.before) && isRecord(entry.after) &&
          JSON.stringify(entry.before[field]) !== JSON.stringify(entry.after[field])) add("projectSettings", field);
    }
  }
  return resources;
}

export interface LocalAuthoringClientOptions {
  allowedRoots: readonly string[];
  onMutation?: (event: AuthoringMutationNotification) => void;
  artifactRoots?: readonly string[];
  exportRoots?: readonly string[];
  authoringPackageRoot?: string;
  workerCommand?: PackagedWorkerCommand;
  discoveryOnly?: boolean;
  dartExecutable?: string;
  requestTimeoutMs?: number;
  workerTimeoutMs?: number;
  exportRequestTimeoutMs?: number;
  exportWorkerTimeoutMs?: number;
  maxInputBytes?: number;
}

interface PendingRequest {
  resolve: (value: AuthoringWorkerSuccess) => void;
  reject: (reason: Error) => void;
  timer: NodeJS.Timeout;
}

export class LocalAuthoringClient
  implements AuthoringGateway, ProjectRootResolver
{
  readonly #options: Required<Omit<LocalAuthoringClientOptions, "workerCommand" | "onMutation">>;
  readonly #onMutation: LocalAuthoringClientOptions["onMutation"];
  readonly #workerCommand: PackagedWorkerCommand;
  readonly #pending = new Map<string, PendingRequest>();
  readonly #projectRoots = new Map<string, string>();
  readonly #projectsByWorkspace = new Map<string, string>();
  #child: ChildProcessWithoutNullStreams | undefined;
  #stdout: ReadLineInterface | undefined;
  #nextRequestId = 0;
  #closing: Promise<void> | undefined;

  constructor(options: LocalAuthoringClientOptions) {
    if (options.allowedRoots.length === 0 && !options.discoveryOnly) {
      throw new AuthoringClientError(
        "configuration.allowed_roots_required",
        "At least one allowed project root is required.",
      );
    }
    if (options.discoveryOnly && (options.allowedRoots.length > 0 ||
        (options.artifactRoots?.length ?? 0) > 0 || (options.exportRoots?.length ?? 0) > 0)) {
      throw new AuthoringClientError("configuration.discovery_roots_forbidden", "Discovery-only workers cannot authorize filesystem roots.");
    }
    if (options.workerCommand && (!isAbsolute(options.workerCommand.executable) || !isAbsolute(options.workerCommand.cwd))) {
      throw new AuthoringClientError("configuration.worker_command_invalid", "Packaged worker executables and working directories must be absolute.");
    }
    if (!options.workerCommand && !options.authoringPackageRoot) {
      throw new AuthoringClientError("configuration.authoring_package_required", "The development Authoring package is required.");
    }
    this.#onMutation = options.onMutation;
    this.#workerCommand = options.workerCommand
      ? { ...options.workerCommand, args: [...options.workerCommand.args] }
      : {
          executable: options.dartExecutable ?? "dart",
          args: ["run", "bin/pokemap_authoring.dart"],
          cwd: options.authoringPackageRoot!,
        };
    this.#options = {
      ...options,
      allowedRoots: [...options.allowedRoots],
      artifactRoots: [...(options.artifactRoots ?? [])],
      exportRoots: [...(options.exportRoots ?? [])],
      authoringPackageRoot: options.authoringPackageRoot ?? this.#workerCommand.cwd,
      discoveryOnly: options.discoveryOnly ?? false,
      dartExecutable: options.dartExecutable ?? "dart",
      requestTimeoutMs: options.requestTimeoutMs ?? 15_000,
      workerTimeoutMs: options.workerTimeoutMs ?? 10_000,
      exportRequestTimeoutMs: options.exportRequestTimeoutMs ?? 125_000,
      exportWorkerTimeoutMs: options.exportWorkerTimeoutMs ?? 120_000,
      maxInputBytes: options.maxInputBytes ?? DEFAULT_AUTHORING_MAX_INPUT_BYTES,
    };
  }

  get workerProcessId(): number | undefined {
    const child = this.#child;
    if (
      !child ||
      this.#closing ||
      child.killed ||
      child.exitCode !== null ||
      child.signalCode !== null
    ) {
      return undefined;
    }
    return child.pid;
  }

  async request(
    command: string,
    args: JsonRecord = {},
  ): Promise<AuthoringWorkerSuccess> {
    if (this.#options.discoveryOnly && command !== "describe") {
      throw new AuthoringClientError("workspace.path_outside_allowed_roots", "Discovery-only workers cannot access projects or files.");
    }
    const projectHandle = typeof args.projectHandle === "string" ? args.projectHandle : undefined;
    const boundRoot = projectHandle ? this.#projectRoots.get(projectHandle) :
      typeof args.projectRoot === "string" && this.#options.allowedRoots.includes(resolve(args.projectRoot))
      ? resolve(args.projectRoot) : undefined;
    const child = this.#ensureStarted();
    const requestId = `mcp-${++this.#nextRequestId}`;
    const line = `${JSON.stringify({ id: requestId, command, args })}\n`;

    const result = await new Promise<AuthoringWorkerSuccess>((resolve, reject) => {
      const timeoutMs =
        (command === "game_export" || command.startsWith("project_native_"))
          ? this.#options.exportRequestTimeoutMs
          : this.#options.requestTimeoutMs;
      const timer = setTimeout(() => {
        this.#pending.delete(requestId);
        reject(
          new AuthoringClientError(
            "worker.timeout",
            "The canonical Authoring worker did not answer in time.",
            true,
          ),
        );
      }, timeoutMs);
      timer.unref();
      this.#pending.set(requestId, { resolve, reject, timer });
      child.stdin.write(line, (error) => {
        if (!error) {
          return;
        }
        const pending = this.#pending.get(requestId);
        if (!pending) {
          return;
        }
        clearTimeout(pending.timer);
        this.#pending.delete(requestId);
        pending.reject(
          new AuthoringClientError(
            "worker.write_failed",
            "Unable to send a request to the canonical Authoring worker.",
          ),
        );
      });
    });
    await this.#trackWorkspace(command, args, result.data);
    if (this.#onMutation && boundRoot && this.#mutationBindingCurrent(projectHandle, boundRoot)) {
      try {
        await this.#publishMutation(result.data, projectHandle, boundRoot, command);
      } catch {}
    }
    return result;
  }

  #mutationBindingCurrent(projectHandle: string | undefined, root: string): boolean {
    return !this.#closing && (projectHandle ? this.#projectRoots.get(projectHandle) === root : this.#options.allowedRoots.includes(root));
  }

  async #publishMutation(data: JsonRecord, projectHandle: string | undefined, projectRoot: string, command: string): Promise<void> {
    if (["describe", "open", "close", "query", "validate", "plan", "confirm", "history", "projection", "recovery_status"].includes(command)) return;
    if (isRecord(data.result) && isRecord(data.snapshot) && data.snapshot.state === "succeeded") {
      await this.#publishMutation(data.result, projectHandle, projectRoot, command);
      return;
    }
    let notification = data.changeNotification;
    if (!isRecord(notification) && isRecord(data.receipt) &&
        /(?:_set|_undo|_edit|_configure|_save|_remove|_upsert|_import|_adopt|_reorder|_recover|_redo|_revert|_publish|_apply)$/.test(command)) {
      const receipt = data.receipt;
      const extension = isRecord(receipt.extensions) ? receipt.extensions : {};
      const status = receipt.status === "applied" ? "applied" :
        receipt.status === "recovered" && ["resumed", "compensated"].includes(String(extension.recoveryOutcome))
        ? extension.recoveryOutcome : undefined;
      notification = {revision:receipt.afterRevision,revisionScope:"transaction_resource_set",status,
        resources:canonicalMutationResources(receipt),...(typeof extension.operationId === "string" ? {operationId:extension.operationId} : {})};
    }
    if (!isRecord(notification) || notification.revisionScope !== "transaction_resource_set" ||
        !["applied", "resumed", "compensated"].includes(String(notification.status)) ||
        typeof notification.revision !== "string") return;
    let resources = notification.resources;
    if (isRecord(resources) && resources.projectionType === "jsonPayload" &&
        typeof resources.payloadRef === "string" && typeof resources.byteLength === "number" && projectHandle) {
      const chunks: Buffer[] = [];
      let offset = 0;
      while (offset < resources.byteLength) {
        if (!this.#mutationBindingCurrent(projectHandle, projectRoot)) return;
        const page = await this.request("projection", {operation:"payload", projectHandle,
          payloadRef: resources.payloadRef, offset});
        const chunk = page.data;
        if (typeof chunk.bytesBase64 !== "string" || typeof chunk.nextOffset !== "number" ||
            chunk.nextOffset <= offset || chunk.nextOffset > resources.byteLength) return;
        chunks.push(Buffer.from(chunk.bytesBase64, "base64"));
        offset = chunk.nextOffset;
      }
      resources = JSON.parse(Buffer.concat(chunks).toString("utf8")) as unknown;
    }
    if (!Array.isArray(resources) || !resources.every(resource => isRecord(resource) &&
        typeof resource.kind === "string" && typeof resource.id === "string")) return;
    if (!this.#mutationBindingCurrent(projectHandle, projectRoot)) return;
    for (let start = 0; start < resources.length; start += 100) {
      this.#onMutation?.({type:"mutation",projectRoot,revision:notification.revision,
        ...(typeof notification.operationId === "string" ? {operationId:notification.operationId} : {}),
        resources: resources.slice(start, start + 100).map(resource => ({kind:resource.kind as string,id:resource.id as string})),
      });
    }
  }

  resolveProjectRoot(projectHandle: string): string {
    const root = this.#projectRoots.get(projectHandle);
    if (!root) {
      throw new AuthoringClientError(
        "workspace.project_binding_unknown",
        "The project handle has no active server-side root binding.",
      );
    }
    return root;
  }

  async close(): Promise<void> {
    if (this.#closing) {
      return this.#closing;
    }
    const child = this.#child;
    if (!child) {
      return;
    }
    this.#closing = this.#closeChild(child);
    return this.#closing;
  }

  #ensureStarted(): ChildProcessWithoutNullStreams {
    if (this.#child) {
      return this.#child;
    }
    const rootArgs = this.#options.allowedRoots.flatMap((root) => [
      "--root",
      root,
    ]);
    const exportRootArgs = this.#options.exportRoots.flatMap((root) => [
      "--export-root",
      root,
    ]);
    const artifactRootArgs = this.#options.artifactRoots.flatMap((root) => [
      "--artifact-root",
      root,
    ]);
    const child = spawn(
      this.#workerCommand.executable,
      [
        ...this.#workerCommand.args,
        ...(this.#options.discoveryOnly ? ["--discovery-only"] : []),
        ...rootArgs,
        ...artifactRootArgs,
        ...exportRootArgs,
        "--timeout-ms",
        String(this.#options.workerTimeoutMs),
        "--export-timeout-ms",
        String(this.#options.exportWorkerTimeoutMs),
        "--max-input-bytes",
        String(this.#options.maxInputBytes),
      ],
      {
        cwd: this.#workerCommand.cwd,
        env: {...process.env,...this.#workerCommand.environment},
        stdio: ["pipe", "pipe", "pipe"],
      },
    );
    this.#child = child;
    this.#stdout = createInterface({ input: child.stdout });
    this.#stdout.on("line", (line) => this.#acceptLine(line));
    child.stderr.resume();
    child.once("error", () => {
      this.#failPending(
        new AuthoringClientError(
          "worker.start_failed",
          "Unable to start the canonical Authoring worker.",
        ),
      );
    });
    child.once("exit", (code) => {
      if (this.#child === child) {
        this.#child = undefined;
      }
      if (this.#pending.size > 0) {
        this.#failPending(
          new AuthoringClientError(
            "worker.exited",
            `The canonical Authoring worker exited unexpectedly (code ${code ?? "signal"}).`,
            false,
            [],
            code === null ? {} : { exitCode: code },
          ),
        );
      }
    });
    return child;
  }

  #acceptLine(line: string): void {
    let decoded: unknown;
    try {
      decoded = JSON.parse(line);
    } catch {
      this.#failPending(
        new AuthoringClientError(
          "worker.response_invalid",
          "The canonical Authoring worker returned invalid JSON.",
        ),
      );
      return;
    }
    if (!isRecord(decoded) || typeof decoded.requestId !== "string") {
      this.#failPending(
        new AuthoringClientError(
          "worker.response_invalid",
          "The canonical Authoring worker returned an invalid envelope.",
        ),
      );
      return;
    }
    const pending = this.#pending.get(decoded.requestId);
    if (!pending) {
      return;
    }
    clearTimeout(pending.timer);
    this.#pending.delete(decoded.requestId);
    if (decoded.status === "success") {
      pending.resolve({
        requestId: decoded.requestId,
        data: isRecord(decoded.data) ? decoded.data : {},
        artifacts: Array.isArray(decoded.artifacts)
          ? decoded.artifacts.filter(isRecord)
          : [],
        ...(isRecord(decoded.receipt) ? { receipt: decoded.receipt } : {}),
      });
      return;
    }
    const error = isRecord(decoded.error) ? decoded.error : {};
    pending.reject(
      new AuthoringClientError(
        typeof error.code === "string" ? error.code : "worker.failure",
        typeof error.message === "string"
          ? error.message
          : "The canonical Authoring request failed.",
        error.retryable === true,
        Array.isArray(error.remediation)
          ? error.remediation.filter(
              (item): item is string => typeof item === "string",
            )
          : [],
        isRecord(error.details) ? error.details : {},
      ),
    );
  }

  #failPending(error: AuthoringClientError): void {
    for (const pending of this.#pending.values()) {
      clearTimeout(pending.timer);
      pending.reject(error);
    }
    this.#pending.clear();
  }

  async #authorizedRootSpelling(requestedRoot: string): Promise<string> {
    if (this.#options.allowedRoots.includes(requestedRoot)) return requestedRoot;
    try {
      const requested = await stat(requestedRoot, { bigint: true });
      if (!requested.isDirectory() || requested.ino === 0n) return requestedRoot;
      for (const allowedRoot of this.#options.allowedRoots) {
        try {
          const allowed = await stat(allowedRoot, { bigint: true });
          if (allowed.isDirectory() && allowed.dev === requested.dev && allowed.ino === requested.ino) return allowedRoot;
        } catch {}
      }
    } catch {}
    return requestedRoot;
  }

  async #trackWorkspace(command: string, args: JsonRecord, data: JsonRecord): Promise<void> {
    if (
      command === "open" &&
      typeof args.projectRoot === "string" &&
      typeof data.projectHandle === "string" &&
      typeof data.workspaceHandle === "string"
    ) {
      const requestedRoot = resolve(args.projectRoot);
      this.#projectRoots.set(data.projectHandle, requestedRoot);
      this.#projectsByWorkspace.set(data.workspaceHandle, data.projectHandle);
      const boundRoot = await this.#authorizedRootSpelling(requestedRoot);
      if (!this.#closing && this.#projectsByWorkspace.get(data.workspaceHandle) === data.projectHandle &&
          this.#projectRoots.get(data.projectHandle) === requestedRoot) {
        this.#projectRoots.set(data.projectHandle, boundRoot);
      }
      return;
    }
    if (command === "close" && typeof args.workspaceHandle === "string") {
      const projectHandle = this.#projectsByWorkspace.get(args.workspaceHandle);
      if (projectHandle) {
        this.#projectsByWorkspace.delete(args.workspaceHandle);
        this.#projectRoots.delete(projectHandle);
      }
    }
  }

  async #closeChild(child: ChildProcessWithoutNullStreams): Promise<void> {
    this.#stdout?.close();
    this.#stdout = undefined;
    const exited = new Promise<void>((resolveExit) => {
      if (child.exitCode !== null || child.signalCode !== null) {
        resolveExit();
      } else {
        child.once("exit", () => resolveExit());
      }
    });
    child.stdin.end();
    const timeout = new Promise<void>((resolveTimeout) => {
      const timer = setTimeout(resolveTimeout, 2_000);
      timer.unref();
    });
    await Promise.race([exited, timeout]);
    if (child.exitCode === null && child.signalCode === null) {
      child.kill("SIGTERM");
      await exited;
    }
    if (this.#child === child) {
      this.#child = undefined;
    }
    this.#failPending(
      new AuthoringClientError(
        "worker.closed",
        "The canonical Authoring worker was closed.",
      ),
    );
  }
}

export function isRecord(value: unknown): value is JsonRecord {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}
