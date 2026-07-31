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
