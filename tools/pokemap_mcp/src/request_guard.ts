import type {
  AuthoringGateway,
  AuthoringWorkerSuccess,
  JsonRecord,
} from "./authoring_client.js";
import type {
  ArtifactReader,
  ReadArtifact,
} from "./artifacts.js";
import type {
  PlaytestToolRequest,
  RenderToolRequest,
  RuntimeGateway,
  RuntimeToolResult,
} from "./runtime_gateway.js";
import { PokeMapToolError } from "./tool_error.js";

export interface PokeMapRequestGuardOptions {
  maxRequestsPerWindow?: number;
  windowMs?: number;
  maxInputBytes?: number;
  clock?: () => number;
}

/** Shared MCP admission gate for rate and serialized-input budgets. */
export class PokeMapRequestGuard {
  readonly #maxRequestsPerWindow: number;
  readonly #windowMs: number;
  readonly #maxInputBytes: number;
  readonly #clock: () => number;
  #windowStartedAt: number;
  #requestsInWindow = 0;

  constructor(options: PokeMapRequestGuardOptions = {}) {
    this.#maxRequestsPerWindow = positiveInteger(
      options.maxRequestsPerWindow ?? 512,
      "maxRequestsPerWindow",
    );
    this.#windowMs = positiveInteger(options.windowMs ?? 60_000, "windowMs");
    this.#maxInputBytes = positiveInteger(
      options.maxInputBytes ?? 64 * 1024,
      "maxInputBytes",
    );
    this.#clock = options.clock ?? Date.now;
    this.#windowStartedAt = this.#clock();
  }

  async run<T>(
    operation: string,
    input: unknown,
    execute: () => Promise<T>,
  ): Promise<T> {
    const byteLength = Buffer.byteLength(JSON.stringify(input), "utf8");
    if (byteLength > this.#maxInputBytes) {
      throw new PokeMapToolError(
        "resource_limit",
        "The MCP tool input exceeds the configured UTF-8 byte limit.",
        false,
        ["Split the request into smaller semantic batches."],
        {
          operation,
          byteLength,
          maximumBytes: this.#maxInputBytes,
        },
      );
    }
    this.#admitRate(operation);
    return execute();
  }

  #admitRate(operation: string): void {
    const now = this.#clock();
    if (now - this.#windowStartedAt >= this.#windowMs) {
      this.#windowStartedAt = now;
      this.#requestsInWindow = 0;
    }
    if (this.#requestsInWindow >= this.#maxRequestsPerWindow) {
      throw new PokeMapToolError(
        "rate_limited",
        "The MCP request rate exceeds the configured local budget.",
        true,
        ["Wait for the current rate window before retrying."],
        {
          operation,
          maximumRequests: this.#maxRequestsPerWindow,
          windowMs: this.#windowMs,
        },
      );
    }
    this.#requestsInWindow += 1;
  }
}

export function guardAuthoringGateway(
  gateway: AuthoringGateway,
  guard: PokeMapRequestGuard,
): AuthoringGateway {
  return {
    request(
      command: string,
      args: JsonRecord = {},
    ): Promise<AuthoringWorkerSuccess> {
      return guard.run(`authoring.${command}`, { command, args }, () =>
        gateway.request(command, args),
      );
    },
    close(): Promise<void> {
      return gateway.close();
    },
  };
}

export function guardArtifactReader(
  reader: ArtifactReader,
  guard: PokeMapRequestGuard,
): ArtifactReader {
  return {
    read(uri: string): Promise<ReadArtifact> {
      return guard.run("artifact.read", { uri }, () => reader.read(uri));
    },
  };
}

export function guardRuntimeGateway(
  gateway: RuntimeGateway,
  guard: PokeMapRequestGuard,
): RuntimeGateway {
  return {
    render(request: RenderToolRequest): Promise<RuntimeToolResult> {
      return guard.run("runtime.render", request, () => gateway.render(request));
    },
    startPlaytest(request: PlaytestToolRequest): Promise<RuntimeToolResult> {
      return guard.run("runtime.playtest", request, () =>
        gateway.startPlaytest(request),
      );
    },
    getJob(jobId: string): Promise<RuntimeToolResult> {
      return guard.run("runtime.job.get", { jobId }, () => gateway.getJob(jobId));
    },
    jobEvents(jobId: string, afterSequence: number): Promise<RuntimeToolResult> {
      return guard.run(
        "runtime.job.events",
        { jobId, afterSequence },
        () => gateway.jobEvents(jobId, afterSequence),
      );
    },
    cancelJob(jobId: string): Promise<RuntimeToolResult> {
      return guard.run("runtime.job.cancel", { jobId }, () =>
        gateway.cancelJob(jobId),
      );
    },
    retryJob(jobId: string): Promise<RuntimeToolResult> {
      return guard.run("runtime.job.retry", { jobId }, () =>
        gateway.retryJob(jobId),
      );
    },
    close(): Promise<void> {
      return gateway.close();
    },
  };
}

function positiveInteger(value: number, field: string): number {
  if (!Number.isSafeInteger(value) || value <= 0) {
    throw new PokeMapToolError(
      "configuration.invalid_request_guard",
      `The ${field} request-guard option must be a positive integer.`,
    );
  }
  return value;
}
