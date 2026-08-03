import { spawn, type ChildProcessWithoutNullStreams } from "node:child_process";
import { resolve } from "node:path";
import { createInterface, type Interface as ReadLineInterface } from "node:readline";

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

export interface LocalAuthoringClientOptions {
  allowedRoots: readonly string[];
  authoringPackageRoot: string;
  dartExecutable?: string;
  requestTimeoutMs?: number;
  workerTimeoutMs?: number;
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
  readonly #options: Required<LocalAuthoringClientOptions>;
  readonly #pending = new Map<string, PendingRequest>();
  readonly #projectRoots = new Map<string, string>();
  readonly #projectsByWorkspace = new Map<string, string>();
  #child: ChildProcessWithoutNullStreams | undefined;
  #stdout: ReadLineInterface | undefined;
  #nextRequestId = 0;
  #closing: Promise<void> | undefined;

  constructor(options: LocalAuthoringClientOptions) {
    if (options.allowedRoots.length === 0) {
      throw new AuthoringClientError(
        "configuration.allowed_roots_required",
        "At least one allowed project root is required.",
      );
    }
    this.#options = {
      ...options,
      allowedRoots: [...options.allowedRoots],
      dartExecutable: options.dartExecutable ?? "dart",
      requestTimeoutMs: options.requestTimeoutMs ?? 15_000,
      workerTimeoutMs: options.workerTimeoutMs ?? 10_000,
      maxInputBytes: options.maxInputBytes ?? DEFAULT_AUTHORING_MAX_INPUT_BYTES,
    };
  }

  async request(
    command: string,
    args: JsonRecord = {},
  ): Promise<AuthoringWorkerSuccess> {
    const child = this.#ensureStarted();
    const requestId = `mcp-${++this.#nextRequestId}`;
    const line = `${JSON.stringify({ id: requestId, command, args })}\n`;

    const result = await new Promise<AuthoringWorkerSuccess>((resolve, reject) => {
      const timer = setTimeout(() => {
        this.#pending.delete(requestId);
        reject(
          new AuthoringClientError(
            "worker.timeout",
            "The canonical Authoring worker did not answer in time.",
            true,
          ),
        );
      }, this.#options.requestTimeoutMs);
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
    this.#trackWorkspace(command, args, result.data);
    return result;
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
    const child = spawn(
      this.#options.dartExecutable,
      [
        "run",
        "bin/pokemap_authoring.dart",
        ...rootArgs,
        "--timeout-ms",
        String(this.#options.workerTimeoutMs),
        "--max-input-bytes",
        String(this.#options.maxInputBytes),
      ],
      {
        cwd: this.#options.authoringPackageRoot,
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

  #trackWorkspace(command: string, args: JsonRecord, data: JsonRecord): void {
    if (
      command === "open" &&
      typeof args.projectRoot === "string" &&
      typeof data.projectHandle === "string" &&
      typeof data.workspaceHandle === "string"
    ) {
      this.#projectRoots.set(data.projectHandle, resolve(args.projectRoot));
      this.#projectsByWorkspace.set(data.workspaceHandle, data.projectHandle);
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
