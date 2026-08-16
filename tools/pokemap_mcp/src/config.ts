import { existsSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

export interface PokeMapMcpConfig {
  allowedRoots: string[];
  exportRoots: string[];
  authoringPackageRoot: string;
  repositoryRoot: string;
  runtimePackageRoot: string;
  runtimeHostRoot: string;
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
  const exportRoots: string[] = [];
  let authoringPackageRoot: string | undefined;
  let repositoryRoot: string | undefined;
  let runtimePackageRoot: string | undefined;
  let runtimeHostRoot: string | undefined;
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
      case "--export-root":
        exportRoots.push(resolve(value));
        break;
      case "--authoring-package":
        authoringPackageRoot = resolve(value);
        break;
      case "--dart":
        dartExecutable = value;
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
  const repository = repositoryRoot ?? resolve(packageRoot, "../..");
  const runtimePackage =
    runtimePackageRoot ?? resolve(repository, "packages/map_runtime");
  const runtimeHost =
    runtimeHostRoot ?? resolve(repository, "examples/playable_runtime_host");
  if (!existsSync(resolve(runtimePackage, "bin/pokemap_render.dart"))) {
    throw new PokeMapMcpConfigError("The map_runtime render worker is unavailable.");
  }
  if (!existsSync(resolve(runtimeHost, "tool/pokemap_eval.dart"))) {
    throw new PokeMapMcpConfigError("The playable runtime host is unavailable.");
  }
  return {
    allowedRoots,
    exportRoots,
    authoringPackageRoot: packageRoot,
    repositoryRoot: repository,
    runtimePackageRoot: runtimePackage,
    runtimeHostRoot: runtimeHost,
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
