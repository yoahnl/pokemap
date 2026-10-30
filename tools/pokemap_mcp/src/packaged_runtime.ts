import { createHash } from "node:crypto";
import { constants, createReadStream } from "node:fs";
import { access, readFile, realpath, stat } from "node:fs/promises";
import { dirname, isAbsolute, relative, resolve, sep } from "node:path";

export interface PackagedWorkerCommand {
  executable: string;
  args: readonly string[];
  cwd: string;
  environment?: Record<string, string>;
}

export interface PackagedRuntimeComponent {
  id: string;
  kind: "executable" | "resource";
  path: string;
  sha256: string;
  capabilities: string[];
  licenses: string[];
  entrypoint?: string;
}

export interface PackagedRuntimeManifest {
  schemaVersion: 1;
  platform: string;
  architecture: string;
  provenance: { version: string; commit: string };
  components: PackagedRuntimeComponent[];
}

export interface ResolvedPackagedRuntimeComponent extends PackagedRuntimeComponent {
  absolutePath: string;
}

export interface PackagedRuntime {
  manifest: PackagedRuntimeManifest;
  bundleRoot: string;
  components: ReadonlyMap<string, ResolvedPackagedRuntimeComponent>;
  command(id: string): PackagedWorkerCommand;
}

export class PackagedRuntimeError extends Error {
  constructor(
    readonly code: string,
    message: string,
  ) {
    super(message);
    this.name = "PackagedRuntimeError";
  }
}

export async function resolvePackagedRuntime(
  manifestPath: string,
  options: { platform?: string; architecture?: string } = {},
): Promise<PackagedRuntime> {
  if (!isAbsolute(manifestPath)) {
    throw new PackagedRuntimeError(
      "distribution.manifest_path_invalid",
      "The distribution manifest path must be absolute.",
    );
  }
  let manifest: PackagedRuntimeManifest;
  let canonicalManifest: string;
  try {
    canonicalManifest = await realpath(manifestPath);
    manifest = parseManifest(
      JSON.parse(await readFile(canonicalManifest, "utf8")),
    );
  } catch (error) {
    if (error instanceof PackagedRuntimeError) throw error;
    throw new PackagedRuntimeError(
      "distribution.manifest_unavailable",
      "The distribution manifest is unavailable or invalid.",
    );
  }
  if (manifest.platform !== (options.platform ?? process.platform)) {
    throw new PackagedRuntimeError(
      "distribution.platform_incompatible",
      "The distribution platform is incompatible.",
    );
  }
  if (manifest.architecture !== (options.architecture ?? process.arch)) {
    throw new PackagedRuntimeError(
      "distribution.architecture_incompatible",
      "The distribution architecture is incompatible.",
    );
  }
  const bundleRoot = dirname(canonicalManifest);
  const components = new Map<string, ResolvedPackagedRuntimeComponent>();
  for (const component of manifest.components) {
    let absolutePath: string;
    try {
      absolutePath = await realpath(resolve(bundleRoot, component.path));
      const fromRoot = relative(bundleRoot, absolutePath);
      if (
        isAbsolute(fromRoot) ||
        fromRoot === ".." ||
        fromRoot.startsWith(`..${sep}`)
      ) {
        throw new PackagedRuntimeError(
          "distribution.component_outside_bundle",
          "A distribution component resolves outside its bundle.",
        );
      }
      const entry = await stat(absolutePath);
      if (!entry.isFile()) {
        throw new PackagedRuntimeError(
          "distribution.component_invalid",
          "A distribution component must be a file.",
        );
      }
      if (component.kind === "executable") {
        try {
          await access(absolutePath, constants.X_OK);
        } catch {
          throw new PackagedRuntimeError(
            "distribution.component_not_executable",
            "A distribution component is not executable.",
          );
        }
      }
      const digest = createHash("sha256");
      for await (const chunk of createReadStream(absolutePath))
        digest.update(chunk);
      if (digest.digest("hex") !== component.sha256) {
        throw new PackagedRuntimeError(
          "distribution.component_integrity_failed",
          "Distribution component integrity verification failed.",
        );
      }
    } catch (error) {
      if (error instanceof PackagedRuntimeError) throw error;
      throw new PackagedRuntimeError(
        "distribution.component_unavailable",
        "A required distribution component is unavailable.",
      );
    }
    components.set(component.id, { ...component, absolutePath });
  }
  return {
    manifest,
    bundleRoot,
    components,
    command(id) {
      const component = components.get(id);
      if (!component || component.kind !== "executable") {
        throw new PackagedRuntimeError(
          "distribution.executable_unavailable",
          "The requested distribution executable is unavailable.",
        );
      }
      const entrypoint = component.entrypoint
        ? components.get(component.entrypoint)
        : undefined;
      if (
        component.entrypoint &&
        (!entrypoint || entrypoint.kind !== "resource")
      ) {
        throw new PackagedRuntimeError(
          "distribution.entrypoint_unavailable",
          "The executable snapshot is unavailable.",
        );
      }
      return {
        executable: component.absolutePath,
        args: entrypoint ? [entrypoint.absolutePath] : [],
        cwd: bundleRoot,
      };
    },
  };
}

function parseManifest(value: unknown): PackagedRuntimeManifest {
  if (!record(value) || value.schemaVersion !== 1) {
    throw new PackagedRuntimeError(
      "distribution.manifest_version_unsupported",
      "The distribution manifest version is unsupported.",
    );
  }
  if (
    !nonempty(value.platform) ||
    !nonempty(value.architecture) ||
    !record(value.provenance) ||
    !nonempty(value.provenance.version) ||
    typeof value.provenance.commit !== "string" ||
    !/^[0-9a-f]{40,64}$/u.test(value.provenance.commit) ||
    !Array.isArray(value.components) ||
    value.components.length === 0
  ) {
    throw new PackagedRuntimeError(
      "distribution.manifest_invalid",
      "The distribution manifest metadata is invalid.",
    );
  }
  const ids = new Set<string>();
  for (const component of value.components) {
    if (
      !record(component) ||
      !nonempty(component.id) ||
      !/^[a-z0-9][a-z0-9._-]*$/u.test(component.id) ||
      (component.kind !== "executable" && component.kind !== "resource") ||
      typeof component.sha256 !== "string" ||
      !/^[0-9a-f]{64}$/u.test(component.sha256) ||
      !Array.isArray(component.capabilities) ||
      !component.capabilities.every(nonempty)
    ) {
      throw new PackagedRuntimeError(
        "distribution.component_invalid",
        "A distribution component declaration is invalid.",
      );
    }
    if (
      !nonempty(component.path) ||
      isAbsolute(component.path) ||
      component.path.includes("\\") ||
      component.path.includes(":") ||
      component.path
        .split("/")
        .some((part) => part === "." || part === ".." || part === "")
    ) {
      throw new PackagedRuntimeError(
        "distribution.component_path_invalid",
        "A distribution component path must be relative and confined to its bundle.",
      );
    }
    if (
      !Array.isArray(component.licenses) ||
      component.licenses.length === 0 ||
      !component.licenses.every(nonempty)
    ) {
      throw new PackagedRuntimeError(
        "distribution.component_license_missing",
        "A distribution component must declare its licences.",
      );
    }
    if (ids.has(component.id)) {
      throw new PackagedRuntimeError(
        "distribution.component_duplicate",
        "The distribution contains duplicate component IDs.",
      );
    }
    if (
      component.entrypoint !== undefined &&
      (typeof component.entrypoint !== "string" ||
        !/^[a-z0-9][a-z0-9._-]*$/u.test(component.entrypoint))
    ) {
      throw new PackagedRuntimeError(
        "distribution.entrypoint_invalid",
        "A distribution entrypoint must reference a component ID.",
      );
    }
    ids.add(component.id);
  }
  return value as unknown as PackagedRuntimeManifest;
}

function record(value: unknown): value is Record<string, unknown> {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function nonempty(value: unknown): value is string {
  return (
    typeof value === "string" &&
    value.trim().length > 0 &&
    !value.includes("\0")
  );
}
