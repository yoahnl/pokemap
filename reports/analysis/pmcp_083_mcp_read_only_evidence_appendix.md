# Appendice PMCP-083 — Contenu intégral des fichiers créés

Cet appendice accompagne `pmcp_083_mcp_read_only_evidence.md`.

## `tools/pokemap_mcp/README.md`

```markdown
# PokeMap MCP

Local MCP adapter for the canonical Dart `map_authoring` API. The server uses
stdio only and accepts explicit project roots. It never turns arbitrary paths
or UI gestures into an authoring contract.

## Build and verify

```bash
cd tools/pokemap_mcp
npm ci
npm run check
npm test
```

## Local client configuration

Build once, then configure the MCP client with an absolute command path:

```json
{
  "command": "node",
  "args": [
    "/absolute/path/to/pokemonProject/tools/pokemap_mcp/dist/src/index.js",
    "--root",
    "/absolute/path/to/a/pokemap/project"
  ]
}
```

Repeat `--root <path>` to authorize several projects. Optional advanced flags:

- `--authoring-package <path>` locates `packages/map_authoring` when the
  repository layout cannot be discovered;
- `--dart <executable>` selects a Dart executable.

All protocol output is written to stdout. Diagnostics are written to stderr.

## Read-only workflow

1. Call `pokemap_describe` to discover resource kinds and query operations.
2. Call `pokemap_workspace` with `operation: "open"` and an authorized root.
3. Keep the returned `projectHandle` and `workspaceHandle` opaque.
4. Use `pokemap_query`, following `nextCursor` without modification.
5. Use `pokemap_validate` or the project resource templates.
6. Close the workspace with its explicit handle.

The PMCP-083 server exposes no plan/apply/undo/recover tool. Artifact reads are
limited to handles registered inside this process; filesystem and arbitrary
HTTPS reads are forbidden.
```

## `tools/pokemap_mcp/src/authoring_client.ts`

```typescript
import { spawn, type ChildProcessWithoutNullStreams } from "node:child_process";
import { createInterface, type Interface as ReadLineInterface } from "node:readline";

export type JsonRecord = Record<string, unknown>;

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

export class LocalAuthoringClient implements AuthoringGateway {
  readonly #options: Required<LocalAuthoringClientOptions>;
  readonly #pending = new Map<string, PendingRequest>();
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
      maxInputBytes: options.maxInputBytes ?? 64 * 1024,
    };
  }

  async request(
    command: string,
    args: JsonRecord = {},
  ): Promise<AuthoringWorkerSuccess> {
    const child = this.#ensureStarted();
    const requestId = `mcp-${++this.#nextRequestId}`;
    const line = `${JSON.stringify({ id: requestId, command, args })}\n`;

    return new Promise<AuthoringWorkerSuccess>((resolve, reject) => {
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
```

## `tools/pokemap_mcp/src/artifacts.ts`

```typescript
export interface ReadArtifact {
  uri: string;
  mediaType: string;
  text?: string;
  blob?: string;
}

export interface ArtifactReader {
  read(uri: string): Promise<ReadArtifact>;
}

export class ArtifactReadError extends Error {
  constructor(readonly code: string, message: string) {
    super(message);
    this.name = "ArtifactReadError";
  }
}

export class MemoryArtifactReader implements ArtifactReader {
  readonly #artifacts = new Map<string, ReadArtifact>();

  registerText(uri: string, mediaType: string, text: string): void {
    assertArtifactUri(uri);
    this.#artifacts.set(uri, { uri, mediaType, text });
  }

  registerBlob(uri: string, mediaType: string, blob: string): void {
    assertArtifactUri(uri);
    this.#artifacts.set(uri, { uri, mediaType, blob });
  }

  async read(uri: string): Promise<ReadArtifact> {
    assertArtifactUri(uri);
    const artifact = this.#artifacts.get(uri);
    if (!artifact) {
      throw new ArtifactReadError(
        "artifact.unknown",
        "The artifact handle is unknown or has expired.",
      );
    }
    return { ...artifact };
  }
}

function assertArtifactUri(uri: string): void {
  let parsed: URL;
  try {
    parsed = new URL(uri);
  } catch {
    throw new ArtifactReadError(
      "artifact.uri_invalid",
      "The artifact URI is invalid.",
    );
  }
  if (parsed.protocol !== "artifact:") {
    throw new ArtifactReadError(
      "artifact.scheme_forbidden",
      "Only opaque artifact:// handles can be read.",
    );
  }
}
```

## `tools/pokemap_mcp/src/config.ts`

```typescript
import { existsSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

export interface PokeMapMcpConfig {
  allowedRoots: string[];
  authoringPackageRoot: string;
  dartExecutable: string;
}

export class PokeMapMcpConfigError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "PokeMapMcpConfigError";
  }
}

export function parseConfig(args: readonly string[]): PokeMapMcpConfig {
  const allowedRoots: string[] = [];
  let authoringPackageRoot: string | undefined;
  let dartExecutable = "dart";
  for (let index = 0; index < args.length; index += 1) {
    const option = args[index];
    const value = args[index + 1];
    if (!value || value.startsWith("--")) {
      throw new PokeMapMcpConfigError("A configuration option is missing its value.");
    }
    index += 1;
    switch (option) {
      case "--root":
        allowedRoots.push(resolve(value));
        break;
      case "--authoring-package":
        authoringPackageRoot = resolve(value);
        break;
      case "--dart":
        dartExecutable = value;
        break;
      default:
        throw new PokeMapMcpConfigError("An unknown configuration option was provided.");
    }
  }
  if (allowedRoots.length === 0) {
    throw new PokeMapMcpConfigError("At least one --root option is required.");
  }
  const packageRoot = authoringPackageRoot ?? findAuthoringPackageRoot();
  if (!existsSync(resolve(packageRoot, "pubspec.yaml"))) {
    throw new PokeMapMcpConfigError("The map_authoring package is unavailable.");
  }
  return {
    allowedRoots,
    authoringPackageRoot: packageRoot,
    dartExecutable,
  };
}

function findAuthoringPackageRoot(): string {
  const moduleDirectory = dirname(fileURLToPath(import.meta.url));
  const candidates = [
    resolve(process.cwd(), "packages/map_authoring"),
    resolve(process.cwd(), "../../packages/map_authoring"),
    resolve(moduleDirectory, "../../../packages/map_authoring"),
    resolve(moduleDirectory, "../../../../packages/map_authoring"),
  ];
  const found = candidates.find((candidate) =>
    existsSync(resolve(candidate, "pubspec.yaml")),
  );
  if (!found) {
    throw new PokeMapMcpConfigError(
      "Unable to locate map_authoring; pass --authoring-package.",
    );
  }
  return found;
}
```

## `tools/pokemap_mcp/src/resources/read_only.ts`

```typescript
import {
  type McpServer,
  ResourceTemplate,
  type Variables,
} from "@modelcontextprotocol/server";

import type { AuthoringGateway, JsonRecord } from "../authoring_client.js";

export function registerReadOnlyResources(
  server: McpServer,
  authoring: AuthoringGateway,
): void {
  server.registerResource(
    "pokemap-project",
    new ResourceTemplate("pokemap://project/{projectHandle}", {
      list: undefined,
    }),
    projectMetadata("PokeMap project", "Detailed immutable project snapshot."),
    async (uri, variables) =>
      queryResource(uri, authoring, {
        projectHandle: variable(variables, "projectHandle"),
        request: query("project", "get", ["project"]),
      }),
  );

  server.registerResource(
    "pokemap-catalog",
    new ResourceTemplate(
      "pokemap://project/{projectHandle}/catalog/{resourceKind}",
      { list: undefined },
    ),
    projectMetadata(
      "PokeMap catalog",
      "A bounded first page of one canonical project resource catalog.",
    ),
    async (uri, variables) =>
      queryResource(uri, authoring, {
        projectHandle: variable(variables, "projectHandle"),
        request: query(variable(variables, "resourceKind"), "list"),
      }),
  );

  server.registerResource(
    "pokemap-diagnostics",
    new ResourceTemplate(
      "pokemap://project/{projectHandle}/diagnostics",
      { list: undefined },
    ),
    projectMetadata(
      "PokeMap diagnostics",
      "Reference validation and explicit capability truth for one snapshot.",
    ),
    async (uri, variables) => {
      const result = await authoring.request("validate", {
        projectHandle: variable(variables, "projectHandle"),
      });
      return jsonResource(uri, result.data);
    },
  );

  server.registerResource(
    "pokemap-map",
    new ResourceTemplate(
      "pokemap://project/{projectHandle}/map/{mapId}",
      { list: undefined },
    ),
    projectMetadata("PokeMap map", "Detailed immutable map snapshot."),
    async (uri, variables) =>
      queryResource(uri, authoring, {
        projectHandle: variable(variables, "projectHandle"),
        request: query(
          "map",
          "get",
          [variable(variables, "mapId")],
          "summary",
        ),
      }),
  );
}

function projectMetadata(title: string, description: string) {
  return {
    title,
    description,
    mimeType: "application/json",
  };
}

function query(
  resourceKind: string,
  operation: "list" | "get",
  ids: string[] = [],
  view: "summary" | "detail" = "detail",
): JsonRecord {
  return {
    resourceKind,
    operation,
    view,
    ids,
    fieldMask: [],
    filters: {},
    sort: [],
    pageSize: 200,
  };
}

async function queryResource(
  uri: URL,
  authoring: AuthoringGateway,
  args: JsonRecord,
) {
  const result = await authoring.request("query", args);
  return jsonResource(uri, result.data);
}

function jsonResource(uri: URL, data: JsonRecord) {
  return {
    contents: [
      {
        uri: uri.href,
        mimeType: "application/json",
        text: JSON.stringify(data),
      },
    ],
  };
}

function variable(variables: Variables, name: string): string {
  const value = variables[name];
  if (typeof value !== "string" || value.length === 0) {
    throw new Error(`Missing resource variable: ${name}`);
  }
  return value;
}
```

## `tools/pokemap_mcp/src/server.ts`

```typescript
import { McpServer } from "@modelcontextprotocol/server";

import type { AuthoringGateway } from "./authoring_client.js";
import type { ArtifactReader } from "./artifacts.js";
import {
  MCP_SERVER_NAME,
  MCP_SERVER_VERSION,
  SUPPORTED_PROTOCOL_VERSIONS,
} from "./protocol.js";
import { registerReadOnlyResources } from "./resources/read_only.js";
import { registerReadOnlyTools } from "./tools/read_only.js";

export interface PokeMapMcpServerDependencies {
  authoring: AuthoringGateway;
  artifacts: ArtifactReader;
}

export function createPokeMapMcpServer(
  dependencies: PokeMapMcpServerDependencies,
): McpServer {
  const server = new McpServer(
    { name: MCP_SERVER_NAME, version: MCP_SERVER_VERSION },
    {
      supportedProtocolVersions: [...SUPPORTED_PROTOCOL_VERSIONS],
      instructions:
        "This PokeMap server is read-only. Open only configured roots, keep opaque handles, follow nextCursor, and never invent resource URIs.",
    },
  );
  registerReadOnlyTools(server, dependencies.authoring, dependencies.artifacts);
  registerReadOnlyResources(server, dependencies.authoring);
  return server;
}
```

## `tools/pokemap_mcp/src/tools/read_only.ts`

```typescript
import { type McpServer } from "@modelcontextprotocol/server";
import { z } from "zod";

import {
  AuthoringClientError,
  type AuthoringGateway,
  type AuthoringWorkerSuccess,
  type JsonRecord,
} from "../authoring_client.js";
import {
  ArtifactReadError,
  type ArtifactReader,
  type ReadArtifact,
} from "../artifacts.js";

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
const toolEnvelopeSchema = z.object({
  ok: z.boolean(),
  data: jsonRecordSchema,
  artifacts: z.array(artifactReferenceSchema),
  error: errorSchema.optional(),
});

const readOnlyAnnotations = {
  readOnlyHint: true,
  destructiveHint: false,
  idempotentHint: true,
  openWorldHint: false,
} as const;

export function registerReadOnlyTools(
  server: McpServer,
  authoring: AuthoringGateway,
  artifacts: ArtifactReader,
): void {
  registerArtifactTool(server, artifacts);

  server.registerTool(
    "pokemap_describe",
    {
      title: "Describe PokeMap authoring",
      description:
        "Lists canonical resource kinds, query operations, action contracts, and validation capabilities.",
      inputSchema: z.object({}).strict(),
      outputSchema: toolEnvelopeSchema,
      annotations: readOnlyAnnotations,
    },
    async () => authoringResult(() => authoring.request("describe")),
  );

  server.registerTool(
    "pokemap_query",
    {
      title: "Query a PokeMap snapshot",
      description:
        "Runs a deterministic, cursor-aware query against an explicit project handle.",
      inputSchema: z
        .object({
          projectHandle: z.string().min(1),
          resourceKind: z.string().regex(/^[a-z][A-Za-z0-9_]*$/),
          operation: z.enum(["list", "get", "batch_get", "search", "summary"]),
          view: z.enum(["summary", "detail"]).default("summary"),
          ids: z.array(z.string().min(1)).default([]),
          searchTerm: z.string().min(1).optional(),
          fieldMask: z.array(z.string().min(1)).default([]),
          filters: jsonRecordSchema.default({}),
          sort: z
            .array(
              z
                .object({
                  field: z.string().min(1),
                  descending: z.boolean().default(false),
                })
                .strict(),
            )
            .default([]),
          pageSize: z.number().int().min(1).max(200).default(50),
          cursor: z.string().min(1).optional(),
          extensions: jsonRecordSchema.optional(),
        })
        .strict(),
      outputSchema: toolEnvelopeSchema,
      annotations: readOnlyAnnotations,
    },
    async ({ projectHandle, ...request }) =>
      authoringResult(() =>
        authoring.request("query", { projectHandle, request }),
      ),
  );

  server.registerTool(
    "pokemap_validate",
    {
      title: "Validate a PokeMap project",
      description:
        "Checks references and explicit capability truth on an immutable snapshot.",
      inputSchema: z
        .object({
          projectHandle: z.string().min(1),
          capabilityTruth: z
            .object({
              records: z.array(jsonRecordSchema),
              requiredCapabilityIds: z.array(z.string().min(1)),
            })
            .strict()
            .optional(),
        })
        .strict(),
      outputSchema: toolEnvelopeSchema,
      annotations: readOnlyAnnotations,
    },
    async ({ projectHandle, capabilityTruth }) =>
      authoringResult(() =>
        authoring.request("validate", {
          projectHandle,
          ...(capabilityTruth ? { capabilityTruth } : {}),
        }),
      ),
  );

  server.registerTool(
    "pokemap_workspace",
    {
      title: "Manage a read-only PokeMap workspace",
      description:
        "Opens an allowed project or closes an explicit opaque workspace handle. It never writes project files.",
      inputSchema: z.discriminatedUnion("operation", [
        z
          .object({
            operation: z.literal("open"),
            projectRoot: z.string().min(1),
          })
          .strict(),
        z
          .object({
            operation: z.literal("close"),
            workspaceHandle: z.string().min(1),
          })
          .strict(),
      ]),
      outputSchema: toolEnvelopeSchema,
      annotations: readOnlyAnnotations,
    },
    async (input) =>
      input.operation === "open"
        ? authoringResult(() =>
            authoring.request("open", { projectRoot: input.projectRoot }),
          )
        : authoringResult(() =>
            authoring.request("close", {
              workspaceHandle: input.workspaceHandle,
            }),
          ),
  );
}

function registerArtifactTool(
  server: McpServer,
  artifacts: ArtifactReader,
): void {
  server.registerTool(
    "pokemap_artifact",
    {
      title: "Read a PokeMap artifact",
      description:
        "Reads bytes already registered under an opaque artifact:// handle. Filesystem and arbitrary HTTPS reads are forbidden.",
      inputSchema: z
        .object({
          uri: z.string().regex(/^artifact:\/\//),
        })
        .strict(),
      outputSchema: toolEnvelopeSchema,
      annotations: readOnlyAnnotations,
    },
    async ({ uri }) => {
      try {
        const artifact = await artifacts.read(uri);
        const data = artifactData(artifact);
        return {
          content: [
            {
              type: "resource" as const,
              resource: artifact.text === undefined
                ? {
                    uri: artifact.uri,
                    mimeType: artifact.mediaType,
                    blob: artifact.blob ?? "",
                  }
                : {
                    uri: artifact.uri,
                    mimeType: artifact.mediaType,
                    text: artifact.text,
                  },
            },
          ],
          structuredContent: successEnvelope(data, []),
        };
      } catch (error) {
        return failureEnvelope(error);
      }
    },
  );
}

async function authoringResult(
  operation: () => Promise<AuthoringWorkerSuccess>,
) {
  try {
    const result = await operation();
    const structuredContent = successEnvelope(result.data, result.artifacts);
    return {
      content: [{ type: "text" as const, text: JSON.stringify(result.data) }],
      structuredContent,
    };
  } catch (error) {
    return failureEnvelope(error);
  }
}

function artifactData(artifact: ReadArtifact): JsonRecord {
  return {
    uri: artifact.uri,
    mediaType: artifact.mediaType,
    ...(artifact.text === undefined ? {} : { text: artifact.text }),
    ...(artifact.blob === undefined ? {} : { blob: artifact.blob }),
  };
}

function successEnvelope(
  data: JsonRecord,
  artifacts: JsonRecord[],
): JsonRecord {
  return { ok: true, data, artifacts };
}

function failureEnvelope(error: unknown) {
  const failure = normalizeError(error);
  const structuredContent = {
    ok: false,
    data: {},
    artifacts: [],
    error: failure,
  };
  return {
    isError: true,
    content: [
      {
        type: "text" as const,
        text: `${failure.code}: ${failure.message}`,
      },
    ],
    structuredContent,
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
  if (error instanceof ArtifactReadError) {
    return {
      code: error.code,
      message: error.message,
      retryable: false,
      remediation: [],
      details: {},
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

## `tools/pokemap_mcp/test/read_only_server.test.ts`

```typescript
import assert from "node:assert/strict";
import { resolve } from "node:path";
import { test } from "node:test";

import { Client } from "@modelcontextprotocol/client";
import { InMemoryTransport } from "@modelcontextprotocol/server";

import { LocalAuthoringClient } from "../src/authoring_client.js";
import { MemoryArtifactReader } from "../src/artifacts.js";
import { createPokeMapMcpServer } from "../src/server.js";

const repositoryRoot = resolve(process.cwd(), "../..");
const projectRoot = resolve(
  repositoryRoot,
  "examples/playable_runtime_host/golden_fangame_slice",
);
const authoringPackageRoot = resolve(repositoryRoot, "packages/map_authoring");

type JsonRecord = Record<string, unknown>;

function record(value: unknown): JsonRecord {
  assert.ok(value && typeof value === "object" && !Array.isArray(value));
  return value as JsonRecord;
}

async function connectReadOnlyServer() {
  const authoring = new LocalAuthoringClient({
    allowedRoots: [projectRoot],
    authoringPackageRoot,
  });
  const artifacts = new MemoryArtifactReader();
  const artifactUri = `artifact://sha256/${"a".repeat(64)}`;
  artifacts.registerText(artifactUri, "application/json", '{"ready":true}');

  const server = createPokeMapMcpServer({ authoring, artifacts });
  const [clientTransport, serverTransport] = InMemoryTransport.createLinkedPair();
  const client = new Client({ name: "pokemap-read-only-test", version: "1.0.0" });
  await server.connect(serverTransport);
  await client.connect(clientTransport);
  return { artifacts, artifactUri, authoring, client, server };
}

async function toolData(
  client: Client,
  name: string,
  args: JsonRecord = {},
): Promise<JsonRecord> {
  const result = await client.callTool({ name, arguments: args });
  assert.equal(result.isError, undefined, JSON.stringify(result.structuredContent));
  const envelope = record(result.structuredContent);
  assert.equal(envelope.ok, true);
  return record(envelope.data);
}

test("read-only MCP inspects a real project with cursor pagination", async () => {
  const fixture = await connectReadOnlyServer();
  try {
    const tools = await fixture.client.listTools();
    assert.deepEqual(
      tools.tools.map((tool) => tool.name),
      [
        "pokemap_artifact",
        "pokemap_describe",
        "pokemap_query",
        "pokemap_validate",
        "pokemap_workspace",
      ],
    );
    assert.ok(tools.tools.every((tool) => tool.annotations?.readOnlyHint));
    assert.ok(tools.tools.every((tool) => !tool.name.includes("apply")));

    const description = await toolData(fixture.client, "pokemap_describe");
    assert.equal(description.protocol, "pokemap.authoring.v1");
    assert.equal(description.readOnly, false);

    const opened = await toolData(fixture.client, "pokemap_workspace", {
      operation: "open",
      projectRoot,
    });
    const projectHandle = String(opened.projectHandle);
    const workspaceHandle = String(opened.workspaceHandle);

    const first = await toolData(fixture.client, "pokemap_query", {
      projectHandle,
      resourceKind: "map",
      operation: "list",
      view: "summary",
      pageSize: 1,
    });
    assert.equal(first.returned, 1);
    assert.equal(first.totalAvailable, 3);
    assert.equal(typeof first.nextCursor, "string");

    const second = await toolData(fixture.client, "pokemap_query", {
      projectHandle,
      resourceKind: "map",
      operation: "list",
      view: "summary",
      pageSize: 1,
      cursor: first.nextCursor,
    });
    assert.equal(second.returned, 1);
    assert.notDeepEqual(first.items, second.items);

    const validation = await toolData(fixture.client, "pokemap_validate", {
      projectHandle,
    });
    assert.match(String(validation.snapshotRevision), /^sha256:[0-9a-f]{64}$/);
    assert.ok(record(validation.references));

    const closed = await toolData(fixture.client, "pokemap_workspace", {
      operation: "close",
      workspaceHandle,
    });
    assert.equal(closed.closed, true);
  } finally {
    await fixture.client.close();
    await fixture.server.close();
    await fixture.authoring.close();
  }
});

test("resource templates project map catalog and diagnostics use explicit handles", async () => {
  const fixture = await connectReadOnlyServer();
  try {
    const opened = await toolData(fixture.client, "pokemap_workspace", {
      operation: "open",
      projectRoot,
    });
    const projectHandle = String(opened.projectHandle);

    const templates = await fixture.client.listResourceTemplates();
    assert.deepEqual(
      templates.resourceTemplates.map((template) => template.uriTemplate),
      [
        "pokemap://project/{projectHandle}",
        "pokemap://project/{projectHandle}/catalog/{resourceKind}",
        "pokemap://project/{projectHandle}/diagnostics",
        "pokemap://project/{projectHandle}/map/{mapId}",
      ],
    );

    const projectResource = await fixture.client.readResource({
      uri: `pokemap://project/${encodeURIComponent(projectHandle)}`,
    });
    const projectContent = projectResource.contents[0];
    assert.ok(projectContent && "text" in projectContent);
    const project = record(JSON.parse(projectContent.text));
    assert.equal(record((project.items as unknown[])[0]).name, "Golden Fangame Slice");

    const maps = await toolData(fixture.client, "pokemap_query", {
      projectHandle,
      resourceKind: "map",
      operation: "list",
      view: "summary",
      pageSize: 1,
    });
    const mapId = String(record((maps.items as unknown[])[0]).id);
    const mapResource = await fixture.client.readResource({
      uri: `pokemap://project/${encodeURIComponent(projectHandle)}/map/${encodeURIComponent(mapId)}`,
    });
    const mapContent = mapResource.contents[0];
    assert.ok(mapContent && "text" in mapContent);
    assert.equal(record((record(JSON.parse(mapContent.text)).items as unknown[])[0]).id, mapId);

    const diagnostics = await fixture.client.readResource({
      uri: `pokemap://project/${encodeURIComponent(projectHandle)}/diagnostics`,
    });
    assert.equal(diagnostics.contents[0]?.mimeType, "application/json");

    const catalog = await fixture.client.readResource({
      uri: `pokemap://project/${encodeURIComponent(projectHandle)}/catalog/asset`,
    });
    assert.equal(catalog.contents[0]?.mimeType, "application/json");

    await assert.rejects(
      fixture.client.readResource({ uri: "pokemap://project/../../etc/passwd" }),
      /resource|uri|not found/i,
    );
  } finally {
    await fixture.client.close();
    await fixture.server.close();
    await fixture.authoring.close();
  }
});

test("artifact reads are handle-only and unknown handles fail closed", async () => {
  const fixture = await connectReadOnlyServer();
  try {
    const artifact = await toolData(fixture.client, "pokemap_artifact", {
      uri: fixture.artifactUri,
    });
    assert.equal(artifact.uri, fixture.artifactUri);
    assert.equal(artifact.mediaType, "application/json");
    assert.equal(artifact.text, '{"ready":true}');

    const unknown = await fixture.client.callTool({
      name: "pokemap_artifact",
      arguments: { uri: `artifact://sha256/${"b".repeat(64)}` },
    });
    assert.equal(unknown.isError, true);
    const envelope = record(unknown.structuredContent);
    assert.equal(record(envelope.error).code, "artifact.unknown");

    const invalidScheme = await fixture.client.callTool({
      name: "pokemap_artifact",
      arguments: { uri: "file:///etc/passwd" },
    });
    assert.equal(invalidScheme.isError, true);
  } finally {
    await fixture.client.close();
    await fixture.server.close();
    await fixture.authoring.close();
  }
});

test("workspace open cannot escape the configured roots", async () => {
  const fixture = await connectReadOnlyServer();
  try {
    const result = await fixture.client.callTool({
      name: "pokemap_workspace",
      arguments: { operation: "open", projectRoot: repositoryRoot },
    });
    assert.equal(result.isError, true);
    const envelope = record(result.structuredContent);
    const error = record(envelope.error);
    assert.equal(error.code, "permission_denied");
    assert.equal(error.domainCode, "workspace.path_outside_allowed_roots");
  } finally {
    await fixture.client.close();
    await fixture.server.close();
    await fixture.authoring.close();
  }
});
```
