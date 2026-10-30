import { createInterface } from "node:readline";
import { homedir } from "node:os";
import { dirname, isAbsolute, resolve } from "node:path";
import type { Readable, Writable } from "node:stream";
import type { PokeMapMcpConfig } from "./config.js";
import { isRecord } from "./authoring_client.js";
import { startPokeMapHttp } from "./http_transport.js";
import {
  createPokeMapServerRuntime,
  type PokeMapServerRuntime,
} from "./server_runtime.js";
import type { PackagedRuntime } from "./packaged_runtime.js";
import { FALLBACK_PROTOCOL_VERSION } from "./protocol.js";
import {
  createProjectAccess,
  type ProjectAccessGrant,
} from "./project_access.js";

export async function startStudioCompanion(
  config: PokeMapMcpConfig,
  options: {
    input: Readable;
    output: Writable;
    packaged?: PackagedRuntime;
    signal?: AbortSignal;
    createRuntime?: (config: PokeMapMcpConfig) => PokeMapServerRuntime;
  },
) {
  let activeConfig = { ...config },
    closed = false,
    generation = 0;
  let http: Awaited<ReturnType<typeof startPokeMapHttp>> | undefined;
  let closing: Promise<void> | undefined;
  let initialized!: () => void;
  const initialization = new Promise<void>((accept) => {
    initialized = accept;
  });
  const resources = new Set<PokeMapServerRuntime>();
  const projectAccess = createProjectAccess(options.packaged);
  const lines = createInterface({ input: options.input });
  function emit(value: unknown) {
    options.output.write(`${JSON.stringify(value)}\n`);
  }
  const factory = () => {
    if (closed) throw new Error("The Studio companion is stopping.");
    const admittedGeneration = generation;
    const runtime =
      options.createRuntime?.(activeConfig) ??
      createPokeMapServerRuntime(activeConfig, options.packaged, {
        workerEnvironment: projectAccess.environment(),
        onMutation: (event) => {
          if (
            !closed &&
            admittedGeneration === generation &&
            activeConfig.allowedRoots.includes(event.projectRoot)
          )
            emit(event);
        },
      });
    let released: Promise<void> | undefined;
    const tracked = {
      ...runtime,
      close: () =>
        (released ??= (async () => {
          try {
            await runtime.close();
          } finally {
            resources.delete(tracked);
          }
        })()),
    };
    resources.add(tracked);
    return tracked;
  };
  function close(): Promise<void> {
    if (closing) return closing;
    closed = true;
    lines.close();
    options.input.pause();
    options.signal?.removeEventListener("abort", onStop);
    closing = (async () => {
      const results = await Promise.allSettled(
        [...resources].map((runtime) => runtime.close()),
      );
      await initialization;
      await http?.close();
      projectAccess.close();
      const failure = results.find((result) => result.status === "rejected");
      if (failure?.status === "rejected") throw failure.reason;
    })();
    return closing;
  }
  function onStop() {
    if (!closed) void close().catch(() => {});
  }
  options.signal?.addEventListener("abort", onStop, { once: true });
  lines.once("close", onStop);
  let serial = Promise.resolve();
  lines.on("line", (line) => {
    serial = serial
      .then(async () => {
        let id: unknown;
        try {
          const command: unknown = JSON.parse(line);
          if (!isRecord(command) || typeof command.id !== "string")
            throw Error("control.invalid_request");
          id = command.id;
          if (command.command === "shutdown") {
            await close();
            emit({ type: "response", id, ok: true });
            return;
          }
          if (
            closed ||
            command.command !== "set_roots" ||
            Object.keys(command).some(
              (key) => !["id", "command", "roots", "grants"].includes(key),
            ) ||
            !Array.isArray(command.roots) ||
            command.roots.length > 1 ||
            command.roots.some(
              (root) =>
                typeof root !== "string" ||
                !isAbsolute(root) ||
                resolve(root) !== root ||
                dirname(root) === root ||
                root === homedir(),
            )
          ) {
            throw Error("control.root_invalid");
          }
          await initialization;
          if (closed || !http) throw Error("control.stopped");
          const roots = command.roots as string[];
          const grants: ProjectAccessGrant[] = [];
          if (command.grants !== undefined) {
            if (
              !Array.isArray(command.grants) ||
              command.grants.length !== roots.length
            )
              throw Error("control.grant_invalid");
            for (const [index, grant] of command.grants.entries()) {
              if (
                !isRecord(grant) ||
                grant.root !== roots[index] ||
                typeof grant.bookmark !== "string" ||
                grant.bookmark.length > 2 * 1024 * 1024 ||
                !/^[A-Za-z0-9+/]+={0,2}$/.test(grant.bookmark)
              )
                throw Error("control.grant_invalid");
              grants.push({ root: roots[index]!, bookmark: grant.bookmark });
            }
          }
          if (
            options.packaged &&
            process.platform === "darwin" &&
            grants.length !== roots.length
          )
            throw Error("control.grant_missing");
          if (
            JSON.stringify(roots) !== JSON.stringify(activeConfig.allowedRoots)
          ) {
            generation++;
            activeConfig = {
              ...activeConfig,
              allowedRoots: [],
              artifactRoots: [],
              exportRoots: [],
            };
            await http.invalidateSessions();
            if (closed) throw Error("control.stopped");
            projectAccess.replace(grants);
            activeConfig = { ...activeConfig, allowedRoots: [...roots] };
            const probe = factory();
            try {
              await probe.authoring.request("describe");
            } catch (error) {
              activeConfig = { ...activeConfig, allowedRoots: [] };
              projectAccess.close();
              throw error;
            } finally {
              await probe.close();
            }
          }
          emit({ type: "response", id, ok: true });
        } catch (error) {
          emit({
            type: "response",
            ...(typeof id === "string" ? { id } : {}),
            ok: false,
            code:
              error instanceof Error &&
              /^(control\.[a-z_]+|permission\.transfer_failed_[1-5])$/.test(
                error.message,
              )
                ? error.message
                : "control.request_rejected",
          });
        }
      })
      .catch(() => {});
  });
  try {
    if (options.signal?.aborted || options.input.readableEnded) closed = true;
    const probe = factory();
    try {
      await probe.authoring.request("describe");
    } finally {
      await probe.close();
    }
    if (closed)
      throw new Error("The Studio companion stopped during initialization.");
    http = await startPokeMapHttp({
      port: config.port,
      createRuntime: factory,
    });
    if (closed) {
      await http.close();
      throw new Error("The Studio companion stopped during initialization.");
    }
    emit({
      type: "ready",
      controlVersion: 1,
      url: http.url,
      token: http.token,
      protocolVersions: [FALLBACK_PROTOCOL_VERSION],
    });
  } catch (error) {
    initialized();
    await close();
    throw error;
  } finally {
    initialized();
  }
  return { close };
}
