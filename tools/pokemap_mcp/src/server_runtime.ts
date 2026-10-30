import type { McpServer } from "@modelcontextprotocol/server";
import {
  LocalAuthoringClient,
  type AuthoringGateway,
  type ProjectRootResolver,
  type AuthoringMutationNotification,
} from "./authoring_client.js";
import { MemoryArtifactReader } from "./artifacts.js";
import type { PokeMapMcpConfig } from "./config.js";
import { createPokeMapMcpServer } from "./server.js";
import { LocalRuntimeGateway, type RuntimeGateway } from "./runtime_gateway.js";
import { createLocalPlaytestProjectionFactory } from "./playtest_projection.js";
import type { PackagedRuntime } from "./packaged_runtime.js";
import { createInstalledRuntime } from "./installed_runtime.js";

export interface PokeMapServerRuntime {
  authoring: AuthoringGateway & ProjectRootResolver;
  runtime: RuntimeGateway;
  createServer(protocolVersions?: readonly string[]): McpServer;
  close(): Promise<void>;
}

export function createPokeMapServerRuntime(
  config: PokeMapMcpConfig,
  packaged?: PackagedRuntime,
  options: {
    onMutation?: (event: AuthoringMutationNotification) => void;
    workerEnvironment?: Record<string, string>;
  } = {},
): PokeMapServerRuntime {
  const workerEnvironment = {
    AVELUNE_OWNER_PID: String(process.pid),
    ...(packaged?.components.has("parent-watchdog-library")
      ? {
          AVELUNE_PARENT_WATCHDOG_LIBRARY: packaged.components.get(
            "parent-watchdog-library",
          )!.absolutePath,
        }
      : {}),
    ...(packaged?.components.has("project-access-library")
      ? {
          AVELUNE_PROJECT_ACCESS_LIBRARY: packaged.components.get(
            "project-access-library",
          )!.absolutePath,
        }
      : {}),
    ...options.workerEnvironment,
  };
  const authoring = new LocalAuthoringClient({
    allowedRoots: config.allowedRoots,
    ...(options.onMutation ? { onMutation: options.onMutation } : {}),
    artifactRoots: config.artifactRoots,
    exportRoots: config.exportRoots,
    authoringPackageRoot: config.authoringPackageRoot,
    ...(packaged
      ? {
          workerCommand: {
            ...packaged.command(
              config.companion ? "authoring" : "authoring-headless",
            ),
            environment: workerEnvironment,
          },
        }
      : {}),
    dartExecutable: config.dartExecutable,
    ...(config.allowedRoots.length === 0 ? { discoveryOnly: true } : {}),
    ...(config.exportTimeoutMs === undefined
      ? {}
      : {
          exportWorkerTimeoutMs: config.exportTimeoutMs,
          exportRequestTimeoutMs: config.exportTimeoutMs + 5000,
        }),
    ...(config.authoringTimeoutMs === undefined
      ? {}
      : {
          workerTimeoutMs: config.authoringTimeoutMs,
          requestTimeoutMs: config.authoringTimeoutMs + 5000,
        }),
  });
  const artifacts = new MemoryArtifactReader();
  const installed = packaged
    ? createInstalledRuntime(
        packaged,
        artifacts,
        authoring,
        workerEnvironment,
        config.companion,
      )
    : undefined;
  const runtime = new LocalRuntimeGateway({
    roots: authoring,
    artifacts,
    runtimePackageRoot: config.runtimePackageRoot,
    runtimeHostRoot: config.runtimeHostRoot,
    renderHostRoot: config.renderHostRoot,
    repositoryRoot: config.repositoryRoot,
    dartExecutable: config.dartExecutable,
    flutterExecutable: config.flutterExecutable,
    playtestProjectionFactory: createLocalPlaytestProjectionFactory({
      authoring,
      authoringPackageRoot: config.authoringPackageRoot,
      repositoryRoot: config.repositoryRoot,
      runtimeHostRoot: config.runtimeHostRoot,
      dartExecutable: config.dartExecutable,
    }),
    ...installed?.options,
  });
  let closed: Promise<void> | undefined;
  return {
    authoring,
    runtime,
    createServer: (protocolVersions) =>
      createPokeMapMcpServer({
        profile: config.profile,
        authoring,
        projectRoots: authoring,
        artifacts,
        runtime,
        ...(protocolVersions ? { protocolVersions } : {}),
      }),
    close: () =>
      (closed ??= (async () => {
        const failures: unknown[] = [];
        for (const stop of [
          () => runtime.close(),
          () => authoring.close(),
          () => installed?.close(),
        ]) {
          try {
            await stop();
          } catch (error) {
            failures.push(error);
          }
        }
        if (failures.length) throw failures[0];
      })()),
  };
}
