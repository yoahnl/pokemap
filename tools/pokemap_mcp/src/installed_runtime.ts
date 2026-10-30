import type { MemoryArtifactReader } from "./artifacts.js";
import {
  LocalAuthoringClient,
  isRecord,
  type AuthoringGateway,
  type JsonRecord,
} from "./authoring_client.js";
import {
  mkdtemp,
  mkdir,
  readFile,
  readdir,
  realpath,
  rm,
  stat,
  writeFile,
} from "node:fs/promises";
import { basename, join, resolve, relative, isAbsolute, sep } from "node:path";
import { tmpdir } from "node:os";
import { createHash } from "node:crypto";
import {
  NativeRenderHost,
  createNativeRender3dExecutor,
  createNativeScan3dExecutor,
} from "./native_render_host.js";
import type { PackagedRuntime } from "./packaged_runtime.js";
import type {
  LocalRuntimeGatewayOptions,
  RenderExecutor,
  PlaytestExecutor,
} from "./runtime_gateway.js";
import { collectEvaluationArtifacts } from "./runtime_gateway.js";
import {
  createLocalPlaytestProjectionFactory,
  type PlaytestProjectionFactory,
} from "./playtest_projection.js";
import { PokeMapToolError } from "./tool_error.js";

export function createInstalledRuntime(
  packaged: PackagedRuntime,
  artifacts: MemoryArtifactReader,
  authoring: AuthoringGateway,
  environment: Record<string, string> = {},
  companion = false,
) {
  const component = packaged.components.get(
    companion ? "runtime" : "runtime-headless",
  );
  const host = component
    ? new NativeRenderHost({
        resolveBinary: async () => component.absolutePath,
        environment,
      })
    : undefined;
  const unavailable = async (): Promise<never> => {
    throw new PokeMapToolError(
      "distribution.runtime_unavailable",
      "This installed distribution has no compatible runtime helper. Reinstall the complete Studio distribution.",
    );
  };
  const renderExecutor: RenderExecutor = host
    ? async (projectRoot, request) => {
        const response = await host.request("render-runtime", {
          projectRoot,
          request: {
            mapId: request.mapId,
            ...(request.region ? { region: request.region } : {}),
            layerIds: request.layerIds,
            overlays: request.overlays,
            cellPixelSize: request.cellPixelSize,
          },
        });
        if (response.status !== "success")
          throw new PokeMapToolError(
            "render.failed",
            "The installed runtime renderer failed.",
          );
        if (
          !isRecord(response.data) ||
          !isRecord(response.artifact) ||
          typeof response.blob !== "string" ||
          typeof response.artifact.uri !== "string" ||
          typeof response.artifact.mediaType !== "string"
        ) {
          throw new PokeMapToolError(
            "render.response_invalid",
            "The installed renderer returned an invalid artifact.",
          );
        }
        artifacts.registerBlob(
          response.artifact.uri,
          response.artifact.mediaType,
          response.blob,
        );
        return { data: response.data, artifacts: [response.artifact] };
      }
    : unavailable;
  let work: Promise<string> | undefined;
  const jobs = new Set<NativeRenderHost>();
  const workRoot = () =>
    (work ??= (async () => {
      const root = await realpath(
        await mkdtemp(join(tmpdir(), "avelune-mcp-")),
      );
      await mkdir(join(root, "runtime"));
      return root;
    })());
  const projectionFactory: PlaytestProjectionFactory = async (context) => {
    const root = await workRoot();
    return createLocalPlaytestProjectionFactory({
      authoring,
      authoringPackageRoot: packaged.bundleRoot,
      repositoryRoot: root,
      runtimeHostRoot: join(root, "runtime"),
      projectionValidator: async (projectRoot) => {
        const client = new LocalAuthoringClient({
          allowedRoots: [projectRoot],
          workerCommand: {
            ...packaged.command(companion ? "authoring" : "authoring-headless"),
            environment,
          },
        });
        try {
          const opened = await client.request("open", { projectRoot });
          return (
            await client.request("validate", {
              projectHandle: opened.data.projectHandle,
            })
          ).data;
        } finally {
          await client.close();
        }
      },
    })(context);
  };
  const playtestExecutor: PlaytestExecutor = component
    ? async (context) => {
        const root = await workRoot();
        const identity = basename(context.sourceProjectRoot);
        const scenario = await resolveInstalledScenario(
          context.projectRoot,
          context.request.scenarioId,
          identity,
        );
        if (context.request.policy) scenario.policy = context.request.policy;
        if (
          context.request.simulationSpeed &&
          context.request.simulationSpeed !== 1
        ) {
          if (!Array.isArray(scenario.steps))
            throw new PokeMapToolError(
              "playtest.scenario_invalid",
              "The scenario has no steps.",
            );
          const ids = new Set(
            scenario.steps.filter(isRecord).map((step) => step.id),
          );
          let stepId = "session-test-speed";
          while (ids.has(stepId)) stepId += "-session";
          scenario.steps = [
            {
              id: stepId,
              command: "simulation.setSpeed",
              multiplier: context.request.simulationSpeed,
            },
            ...scenario.steps,
          ];
        }
        const id = createHash("sha256").update(context.jobId).digest("hex");
        const scenarioPath = `runtime/scenario-${id}.json`,
          outputDirectory = `build/pokemap-eval/runs/${id}`;
        await writeFile(join(root, scenarioPath), JSON.stringify(scenario), {
          flag: "wx",
        });
        const evaluator = new NativeRenderHost({
          resolveBinary: async () => component.absolutePath,
          environment,
        });
        jobs.add(evaluator);
        const abort = () => {
          void evaluator.close().catch(() => {});
        };
        context.signal.addEventListener("abort", abort, { once: true });
        try {
          if (context.signal.aborted)
            throw new PokeMapToolError(
              "job.cancelled",
              "The playtest was cancelled.",
            );
          context.emit("playtest.scenario_resolved", {
            scenarioId: context.request.scenarioId,
          });
          const response = await evaluator.request("evaluate", {
            workRoot: root,
            target: context.request.target,
            projectIdentity: identity,
            request: {
              schemaVersion: 2,
              messageType: "run",
              runId: id,
              projectRoot: context.projectRelativeRoot,
              expectedProjectTreeHash: context.projectTreeHash,
              scenarioPath,
              outputDirectory,
            },
          });
          const summary = response.data;
          if (
            response.status !== "success" ||
            !isRecord(summary) ||
            summary.status !== "succeeded" ||
            typeof summary.receiptPath !== "string"
          ) {
            throw new PokeMapToolError(
              "playtest.scenario_failed",
              "The installed evaluation scenario did not succeed.",
            );
          }
          const collected = await collectEvaluationArtifacts(
            { artifacts, repositoryRoot: root },
            summary.receiptPath,
          );
          context.emit("playtest.artifacts_collected", {
            artifactCount: collected.artifacts.length,
          });
          const safeSummary = { ...summary };
          delete safeSummary.receiptPath;
          return {
            data: { ...safeSummary, receipt: collected.receipt },
            artifacts: collected.artifacts,
          };
        } finally {
          context.signal.removeEventListener("abort", abort);
          await evaluator.close();
          jobs.delete(evaluator);
          await rm(join(root, scenarioPath), { force: true });
          await rm(join(root, outputDirectory), {
            recursive: true,
            force: true,
          });
        }
      }
    : unavailable;
  const options: Pick<
    LocalRuntimeGatewayOptions,
    | "renderExecutor"
    | "render3dExecutor"
    | "scan3dExecutor"
    | "playtestExecutor"
    | "playtestProjectionFactory"
  > = {
    renderExecutor,
    render3dExecutor:
      host && process.platform === "darwin"
        ? createNativeRender3dExecutor({ host, artifacts })
        : unavailable,
    scan3dExecutor:
      host && process.platform === "darwin"
        ? createNativeScan3dExecutor({ host, artifacts })
        : unavailable,
    playtestExecutor,
    playtestProjectionFactory: component ? projectionFactory : unavailable,
  };
  return {
    options,
    close: async () => {
      await Promise.all([
        host?.close(),
        ...[...jobs].map((job) => job.close()),
      ]);
      if (work) await rm(await work, { recursive: true, force: true });
    },
  };
}

async function resolveInstalledScenario(
  projectRoot: string,
  scenarioId: string,
  identity: string,
): Promise<JsonRecord> {
  const root = await realpath(projectRoot);
  let directory: string;
  try {
    directory = await realpath(join(root, "evaluation", "scenarios"));
  } catch {
    throw new PokeMapToolError(
      "playtest.scenario_unknown",
      "This project has no evaluation scenario catalog.",
    );
  }
  const requireContained = (path: string) => {
    const rel = relative(root, path);
    if (isAbsolute(rel) || rel === ".." || rel.startsWith(`..${sep}`))
      throw new PokeMapToolError(
        "playtest.scenario_invalid",
        "A scenario escaped its project.",
      );
  };
  requireContained(directory);
  const matches: JsonRecord[] = [];
  const entries = await readdir(directory, { withFileTypes: true });
  if (entries.length > 2000)
    throw new PokeMapToolError(
      "playtest.scenario_invalid",
      "The scenario catalog exceeds its file limit.",
    );
  for (const entry of entries) {
    if (!entry.isFile() || !entry.name.endsWith(".json")) continue;
    const file = await realpath(resolve(directory, entry.name));
    requireContained(file);
    if ((await stat(file)).size > 1024 * 1024)
      throw new PokeMapToolError(
        "playtest.scenario_invalid",
        "An evaluation scenario exceeds its byte limit.",
      );
    const value: unknown = JSON.parse(await readFile(file, "utf8"));
    if (isRecord(value) && value.id === scenarioId) matches.push(value);
  }
  if (matches.length !== 1)
    throw new PokeMapToolError(
      "playtest.scenario_unknown",
      "The project scenario is unknown or ambiguous.",
    );
  if (matches[0]!.projectId !== identity)
    throw new PokeMapToolError(
      "playtest.project_mismatch",
      "The scenario does not identify the opened project.",
    );
  return matches[0]!;
}
