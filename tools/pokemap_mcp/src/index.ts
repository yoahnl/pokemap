import { serveStdio } from "@modelcontextprotocol/server/stdio";
import { parseConfig, PokeMapMcpConfigError } from "./config.js";
import { resolvePackagedRuntime } from "./packaged_runtime.js";
import { createPokeMapServerRuntime } from "./server_runtime.js";
import { startStudioCompanion } from "./studio_companion.js";
import { startPokeMapHttp } from "./http_transport.js";
import { AuthoringClientError } from "./authoring_client.js";
import { PackagedRuntimeError } from "./packaged_runtime.js";

let companionControl = false;

async function main(): Promise<void> {
  const config = parseConfig(process.argv.slice(2));
  companionControl = config.companion;
  let cleanup: (() => Promise<void>) | undefined;
  let stopped = false;
  const cancellation = new AbortController();
  const stop = async () => {
    stopped = true;
    cancellation.abort();
    await cleanup?.();
  };
  process.once("SIGINT", () => {
    void stop();
  });
  process.once("SIGTERM", () => {
    void stop();
  });
  const packaged = config.runtimeManifest
    ? await resolvePackagedRuntime(config.runtimeManifest)
    : undefined;
  if (stopped) return;
  if (config.companion) {
    const owner = process.ppid;
    const watchdog = setInterval(() => {
      if (process.ppid !== owner) void stop();
    }, 250);
    watchdog.unref();
    const service = await startStudioCompanion(config, {
      input: process.stdin,
      output: process.stdout,
      signal: cancellation.signal,
      ...(packaged ? { packaged } : {}),
    });
    cleanup = service.close;
  } else if (config.transport === "http") {
    const service = await startPokeMapHttp({
      port: config.port,
      createRuntime: () => createPokeMapServerRuntime(config, packaged),
    });
    cleanup = service.close;
    process.stdout.write(
      JSON.stringify({
        type: "ready",
        url: service.url,
        token: service.token,
      }) + "\n",
    );
  } else {
    const runtime = createPokeMapServerRuntime(config, packaged);
    const handle = serveStdio(() => runtime.createServer(), {
      legacy: "serve",
      onerror: () => {
        process.stderr.write("[pokemap-mcp] Protocol request failed.\n");
      },
    });
    cleanup = async () => {
      await handle.close();
      await runtime.close();
    };
    process.stdin.once("end", () => {
      void stop();
    });
  }
  if (stopped) await cleanup?.();
}

main().catch((error) => {
  const message =
    error instanceof PokeMapMcpConfigError
      ? error.message
      : "Unable to initialize PokeMap MCP.";
  const code =
    error instanceof AuthoringClientError ||
    error instanceof PackagedRuntimeError
      ? error.code
      : typeof error?.code === "string" && /^E[A-Z_]+$/.test(error.code)
        ? `launch.${error.code}`
        : "companion.initialization_failed";
  if (companionControl)
    process.stdout.write(JSON.stringify({ type: "failed", code }) + "\n");
  process.stderr.write("[pokemap-mcp] " + message + "\n");
  process.exitCode = 64;
});
