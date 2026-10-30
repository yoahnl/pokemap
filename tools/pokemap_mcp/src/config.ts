import { existsSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

export interface PokeMapMcpConfig {
  transport: "stdio" | "http";
  companion: boolean;
  port: number;
  runtimeManifest?: string;
  profile: "full" | "map-builder";
  allowedRoots: string[];
  artifactRoots: string[];
  exportRoots: string[];
  authoringPackageRoot: string;
  repositoryRoot: string;
  runtimePackageRoot: string;
  runtimeHostRoot: string;
  renderHostRoot: string;
  dartExecutable: string;
  flutterExecutable: string;
  authoringTimeoutMs?: number;
  exportTimeoutMs?: number;
}

export class PokeMapMcpConfigError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "PokeMapMcpConfigError";
  }
}

export function parseConfig(args: readonly string[]): PokeMapMcpConfig {
  const allowedRoots: string[] = [];
  const artifactRoots: string[] = [];
  const exportRoots: string[] = [];
  let authoringPackageRoot: string | undefined;
  let repositoryRoot: string | undefined;
  let runtimePackageRoot: string | undefined;
  let runtimeHostRoot: string | undefined;
  let renderHostRoot: string | undefined;
  let dartExecutable = "dart";
  let flutterExecutable = "flutter";
  let authoringTimeoutMs: number | undefined;
  let exportTimeoutMs: number | undefined;
  let profile: PokeMapMcpConfig["profile"] = "full";
  let transport:PokeMapMcpConfig["transport"]="stdio",companion=false,port=0;
  let runtimeManifest:string|undefined;
  for (let index = 0; index < args.length; index += 1) {
    const option = args[index];
    const value = args[index + 1];
    if (!value || value.startsWith("--")) {
      throw new PokeMapMcpConfigError("A configuration option is missing its value.");
    }
    index += 1;
    switch (option) {
      case "--transport":
        if(value!=="stdio"&&value!=="http") throw new PokeMapMcpConfigError("Transport must be stdio or http.");
        transport=value;
        break;
      case "--companion":
        if(value!=="true"&&value!=="false") throw new PokeMapMcpConfigError("Companion must be true or false.");
        companion=value==="true";
        break;
      case "--port":
        port=Number(value);
        if(!Number.isInteger(port)||port<0||port>65535) throw new PokeMapMcpConfigError("Port must be between 0 and 65535.");
        break;
      case "--runtime-manifest":
        runtimeManifest=resolve(value);
        break;
      case "--profile":
        if (value !== "full" && value !== "map-builder") {
          throw new PokeMapMcpConfigError("Profile must be full or map-builder.");
        }
        profile = value;
        break;
      case "--root":
        allowedRoots.push(resolve(value));
        break;
      case "--artifact-root":
        artifactRoots.push(resolve(value));
        break;
      case "--export-root":
        exportRoots.push(resolve(value));
        break;
      case "--authoring-package":
        authoringPackageRoot = resolve(value);
        break;
      case "--dart":
        dartExecutable = value;
        break;
      case "--flutter":
        flutterExecutable = value;
        break;
      case "--authoring-timeout-ms":
        authoringTimeoutMs = Number(value);
        if (!Number.isInteger(authoringTimeoutMs) || authoringTimeoutMs < 1 || authoringTimeoutMs > 120_000) {
          throw new PokeMapMcpConfigError("Authoring timeout must be an integer between 1 and 120000 milliseconds.");
        }
        break;
      case "--export-timeout-ms":
        exportTimeoutMs = Number(value);
        if (!Number.isInteger(exportTimeoutMs) || exportTimeoutMs < 1 || exportTimeoutMs > 600_000) {
          throw new PokeMapMcpConfigError("Export timeout must be an integer between 1 and 600000 milliseconds.");
        }
        break;
      case "--repository-root":
        repositoryRoot = resolve(value);
        break;
      case "--runtime-package":
        runtimePackageRoot = resolve(value);
        break;
      case "--runtime-host":
        runtimeHostRoot = resolve(value);
        break;
      case "--render-host":
        renderHostRoot = resolve(value);
        break;
      default:
        throw new PokeMapMcpConfigError("An unknown configuration option was provided.");
    }
  }
  if(companion&&transport!=="http") throw new PokeMapMcpConfigError("The Studio companion requires the local HTTP transport.");
  if (allowedRoots.length === 0 && !companion) {
    throw new PokeMapMcpConfigError("At least one --root option is required.");
  }
  const installedRoot=runtimeManifest?dirname(runtimeManifest):undefined;
  if(installedRoot&&(authoringPackageRoot||repositoryRoot||runtimePackageRoot||runtimeHostRoot||renderHostRoot||dartExecutable!=="dart"||flutterExecutable!=="flutter")) {
    throw new PokeMapMcpConfigError("Installed runtimes cannot use development command or checkout overrides.");
  }
  const packageRoot = installedRoot??authoringPackageRoot ?? findAuthoringPackageRoot();
  if (!installedRoot&&!existsSync(resolve(packageRoot, "pubspec.yaml"))) {
    throw new PokeMapMcpConfigError("The map_authoring package is unavailable.");
  }
  const repository = installedRoot??repositoryRoot ?? resolve(packageRoot, "../..");
  const runtimePackage =
    runtimePackageRoot ?? resolve(repository, "packages/map_runtime");
  const runtimeHost =
    runtimeHostRoot ?? resolve(repository, "examples/playable_runtime_host");
  if (!installedRoot&&!existsSync(resolve(runtimePackage, "tool/pokemap_render_worker_test.dart"))) {
    throw new PokeMapMcpConfigError("The map_runtime render worker is unavailable.");
  }
  if (!installedRoot&&!existsSync(resolve(runtimeHost, "tool/pokemap_eval.dart"))) {
    throw new PokeMapMcpConfigError("The playable runtime host is unavailable.");
  }
  return {
    transport,companion,port,...(runtimeManifest?{runtimeManifest}:{}),
    profile,
    allowedRoots,
    artifactRoots,
    exportRoots,
    authoringPackageRoot: packageRoot,
    repositoryRoot: repository,
    runtimePackageRoot: runtimePackage,
    runtimeHostRoot: runtimeHost,
    renderHostRoot: renderHostRoot ?? resolve(repository, "tools/pokemap_render_host"),
    dartExecutable,
    flutterExecutable,
    ...(authoringTimeoutMs === undefined ? {} : {authoringTimeoutMs}),
    ...(exportTimeoutMs === undefined ? {} : {exportTimeoutMs}),
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
