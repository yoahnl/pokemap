import { createHash } from "node:crypto";
import {
  chmod,
  lstat,
  mkdir,
  readFile,
  readdir,
  realpath,
  rm,
  writeFile,
} from "node:fs/promises";
import { relative, resolve, sep } from "node:path";

import {
  AuthoringClientError,
  LocalAuthoringClient,
  isRecord,
  type AuthoringGateway,
  type JsonRecord,
} from "./authoring_client.js";
import type { PlaytestToolRequest } from "./runtime_gateway.js";
import { PokeMapToolError } from "./tool_error.js";

export interface PlaytestProjectionContext {
  jobId: string;
  projectHandle: string;
  sourceProjectRoot: string;
  request: PlaytestToolRequest;
  signal: AbortSignal;
  emit(type: string, payload?: JsonRecord): void;
}

export interface CertifiedPlaytestProjection {
  projectRoot: string;
  projectRelativeRoot: string;
  projectTreeHash: string;
  authoringRevision: string;
  dispose(): Promise<void>;
}

export type PlaytestProjectionFactory = (
  context: PlaytestProjectionContext,
) => Promise<CertifiedPlaytestProjection>;

export interface LocalPlaytestProjectionFactoryOptions {
  authoring: AuthoringGateway;
  authoringPackageRoot: string;
  repositoryRoot: string;
  runtimeHostRoot: string;
  dartExecutable?: string;
  projectionValidator?: (projectRoot: string) => Promise<JsonRecord>;
  maxFileCount?: number;
  maxFileBytes?: number;
  maxTotalBytes?: number;
  platform?: NodeJS.Platform;
}

interface ProjectFileSnapshot {
  relativePath: string;
  bytes: Buffer;
}

interface ProjectSnapshot {
  files: ProjectFileSnapshot[];
  directories: string[];
}

export function createLocalPlaytestProjectionFactory(
  options: LocalPlaytestProjectionFactoryOptions,
): PlaytestProjectionFactory {
  const maxFileCount = options.maxFileCount ?? 20_000;
  const maxFileBytes = options.maxFileBytes ?? 256 * 1024 * 1024;
  const maxTotalBytes = options.maxTotalBytes ?? 1024 * 1024 * 1024;
  const platform = options.platform ?? process.platform;
  return async (context) => {
    requireActive(context.signal);
    if (platform === "win32") {
      throw new PokeMapToolError(
        "playtest.projection_immutable_unavailable",
        "Certified playtest projections require filesystem immutability that is unavailable on Windows.",
      );
    }
    const sourceValidation = await validateSource(context, options.authoring);
    const authoringRevision = requireRevision(sourceValidation);
    let projectionParent: string | undefined;
    let retained = false;
    try {
      const destination = await prepareProjectionDestination(
        options.repositoryRoot,
        options.runtimeHostRoot,
        context.jobId,
      );
      projectionParent = destination.projectionParent;
      const projectRoot = destination.projectRoot;
      const sourceRoot = await realpath(context.sourceProjectRoot);
      const snapshot = await snapshotProject(sourceRoot, context.signal, {
        maxFileCount,
        maxFileBytes,
        maxTotalBytes,
      });
      await materializeProject(projectRoot, snapshot, context.signal);
      const projectedHash = digestProjectFiles(snapshot.files);
      const sourceHash = await digestProjectRoot(sourceRoot, context.signal, {
        maxFileCount,
        maxFileBytes,
        maxTotalBytes,
      });
      if (projectedHash !== sourceHash) {
        throw new PokeMapToolError(
          "playtest.revision_drift",
          "The project changed while its playtest projection was captured.",
          true,
          ["Retry the playtest after project writes have completed."],
        );
      }
      context.emit("playtest.projection_captured", {
        projectTreeHash: projectedHash,
        authoringRevision,
      });
      const projectedValidation = await (
        options.projectionValidator ??
        ((root) => validateProjection(root, options))
      )(projectRoot);
      requireCatalogReady(projectedValidation);
      if (requireRevision(projectedValidation) !== authoringRevision) {
        throw new PokeMapToolError(
          "playtest.revision_drift",
          "The certified projection does not match the Authoring revision.",
          true,
        );
      }
      const validatedHash = await digestProjectRoot(
        projectRoot,
        context.signal,
        { maxFileCount, maxFileBytes, maxTotalBytes },
      );
      if (validatedHash !== projectedHash) {
        throw new PokeMapToolError(
          "playtest.revision_drift",
          "The playtest projection changed during validation.",
          true,
        );
      }
      await freezeProjection(projectRoot, platform);
      const projectRelativeRoot = portableRelativePath(
        destination.repositoryRoot,
        projectRoot,
      );
      retained = true;
      return {
        projectRoot,
        projectRelativeRoot,
        projectTreeHash: projectedHash,
        authoringRevision,
        dispose: async () => {
          await removeProjection(destination.projectionParent, platform);
        },
      };
    } catch (error) {
      if (error instanceof PokeMapToolError) throw error;
      if (error instanceof AuthoringClientError) {
        throw new PokeMapToolError(
          "pokemon.catalog_not_ready",
          "The canonical Pokemon catalog preflight is unavailable.",
          error.retryable,
          [...error.remediation],
          { authoringCode: error.domainCode ?? error.code },
        );
      }
      throw new PokeMapToolError(
        "pokemon.catalog_not_ready",
        "The certified Pokemon playtest projection could not be prepared.",
      );
    } finally {
      if (!retained && projectionParent != null) {
        await removeProjection(projectionParent, platform);
      }
    }
  };
}

async function prepareProjectionDestination(
  repositoryRoot: string,
  runtimeHostRoot: string,
  jobId: string,
): Promise<{
  repositoryRoot: string;
  projectionParent: string;
  projectRoot: string;
}> {
  const repositoryInput = resolve(repositoryRoot);
  const repositoryCanonical = await realpath(repositoryInput);
  const runtimeRelative = portableRelativePath(
    repositoryInput,
    resolve(runtimeHostRoot),
  );
  let current = repositoryCanonical;
  for (const part of [
    ...runtimeRelative.split("/"),
    "build",
    "pokemap-eval",
    "input",
  ]) {
    current = resolve(current, part);
    try {
      await mkdir(current);
    } catch (error) {
      if (!isAlreadyExists(error)) throw error;
    }
    const entry = await lstat(current);
    if (!entry.isDirectory() || entry.isSymbolicLink()) {
      throw unsafeProjectionDestination(current);
    }
    const canonical = await realpath(current);
    portableRelativePath(repositoryCanonical, canonical);
    current = canonical;
  }
  const projectionParent = resolve(
    current,
    createHash("sha256").update(jobId).digest("hex").slice(0, 24),
  );
  try {
    await mkdir(projectionParent);
  } catch (error) {
    if (isAlreadyExists(error)) {
      throw new PokeMapToolError(
        "playtest.projection_identity_collision",
        "A certified playtest projection already exists for this job.",
        true,
      );
    }
    throw error;
  }
  try {
    const projectionEntry = await lstat(projectionParent);
    if (!projectionEntry.isDirectory() || projectionEntry.isSymbolicLink()) {
      throw unsafeProjectionDestination(projectionParent);
    }
    const projectRoot = resolve(projectionParent, "project");
    await mkdir(projectRoot);
    return {
      repositoryRoot: repositoryCanonical,
      projectionParent,
      projectRoot,
    };
  } catch (error) {
    await rm(projectionParent, { recursive: true, force: true });
    throw error;
  }
}

async function validateSource(
  context: PlaytestProjectionContext,
  authoring: AuthoringGateway,
): Promise<JsonRecord> {
  try {
    const result = await authoring.request("validate", {
      projectHandle: context.projectHandle,
    });
    requireCatalogReady(result.data);
    context.emit("playtest.preflight_succeeded", {
      authoringRevision: requireRevision(result.data),
    });
    return result.data;
  } catch (error) {
    if (error instanceof PokeMapToolError) throw error;
    if (error instanceof AuthoringClientError) {
      throw new PokeMapToolError(
        "pokemon.catalog_not_ready",
        "The canonical Pokemon catalog preflight is unavailable.",
        error.retryable,
        [...error.remediation],
        { authoringCode: error.domainCode ?? error.code },
      );
    }
    throw new PokeMapToolError(
      "pokemon.catalog_not_ready",
      "The canonical Pokemon catalog preflight is unavailable.",
    );
  }
}

async function validateProjection(
  projectRoot: string,
  options: LocalPlaytestProjectionFactoryOptions,
): Promise<JsonRecord> {
  const authoring = new LocalAuthoringClient({
    allowedRoots: [projectRoot],
    authoringPackageRoot: options.authoringPackageRoot,
    ...(options.dartExecutable
      ? { dartExecutable: options.dartExecutable }
      : {}),
  });
  try {
    const opened = await authoring.request("open", { projectRoot });
    if (
      typeof opened.data.projectHandle !== "string" ||
      typeof opened.data.workspaceHandle !== "string"
    ) {
      throw new PokeMapToolError(
        "pokemon.catalog_not_ready",
        "The projected Authoring workspace returned invalid handles.",
      );
    }
    const validation = await authoring.request("validate", {
      projectHandle: opened.data.projectHandle,
    });
    await authoring.request("close", {
      workspaceHandle: opened.data.workspaceHandle,
    });
    return validation.data;
  } finally {
    await authoring.close();
  }
}

function requireCatalogReady(validation: JsonRecord): void {
  const pokemonCatalog = validation.pokemonCatalog;
  if (
    validation.valid !== true ||
    !isRecord(pokemonCatalog) ||
    pokemonCatalog.canPlaytest !== true
  ) {
    throw new PokeMapToolError(
      "pokemon.catalog_not_ready",
      "The projected Pokemon catalog is not ready for playtest.",
      false,
      ["Run pokemap_validate and resolve every blocking Pokemon diagnostic."],
      {
        ...(isRecord(pokemonCatalog) ? { pokemonCatalog } : {}),
      },
    );
  }
}

function requireRevision(validation: JsonRecord): string {
  const revision = validation.snapshotRevision;
  if (
    typeof revision !== "string" ||
    !/^sha256:[0-9a-f]{64}$/u.test(revision)
  ) {
    throw new PokeMapToolError(
      "pokemon.catalog_not_ready",
      "The Authoring preflight did not attest a snapshot revision.",
    );
  }
  return revision;
}

async function snapshotProject(
  root: string,
  signal: AbortSignal,
  limits: {
    maxFileCount: number;
    maxFileBytes: number;
    maxTotalBytes: number;
  },
): Promise<ProjectSnapshot> {
  const listing = await listProjectTree(root, signal, limits.maxFileCount);
  const files: ProjectFileSnapshot[] = [];
  let totalBytes = 0;
  for (const relativePath of listing.files) {
    requireActive(signal);
    const file = resolve(root, ...relativePath.split("/"));
    const before = await lstat(file);
    if (!before.isFile() || before.isSymbolicLink()) {
      throw unsafeProjectionPath(relativePath);
    }
    if (before.size > limits.maxFileBytes) {
      throw new PokeMapToolError(
        "playtest.projection_quota_exceeded",
        "A project file exceeds the playtest projection quota.",
      );
    }
    const bytes = await readFile(file);
    const after = await lstat(file);
    if (
      !after.isFile() ||
      after.isSymbolicLink() ||
      after.size !== before.size ||
      after.mtimeMs !== before.mtimeMs ||
      after.ctimeMs !== before.ctimeMs ||
      bytes.length !== before.size
    ) {
      throw new PokeMapToolError(
        "playtest.revision_drift",
        "A project file changed while the playtest projection was captured.",
        true,
      );
    }
    totalBytes += bytes.length;
    if (totalBytes > limits.maxTotalBytes) {
      throw new PokeMapToolError(
        "playtest.projection_quota_exceeded",
        "The project exceeds the total playtest projection quota.",
      );
    }
    files.push({ relativePath, bytes });
  }
  return { files, directories: listing.directories };
}

async function listProjectTree(
  root: string,
  signal: AbortSignal,
  maxEntryCount: number,
): Promise<{ files: string[]; directories: string[] }> {
  const files: string[] = [];
  const directories: string[] = [];
  let entryCount = 0;
  async function walk(directory: string, prefix: string): Promise<void> {
    requireActive(signal);
    const entries = await readdir(directory, { withFileTypes: true });
    entries.sort((left, right) => left.name.localeCompare(right.name));
    for (const entry of entries) {
      const relativePath = prefix ? `${prefix}/${entry.name}` : entry.name;
      if (excludedProjectPath(relativePath)) continue;
      entryCount += 1;
      if (entryCount > maxEntryCount) {
        throw new PokeMapToolError(
          "playtest.projection_quota_exceeded",
          "The project contains too many entries for a playtest projection.",
        );
      }
      if (entry.isSymbolicLink()) throw unsafeProjectionPath(relativePath);
      const absolute = resolve(directory, entry.name);
      if (entry.isDirectory()) {
        directories.push(relativePath);
        await walk(absolute, relativePath);
      } else if (entry.isFile()) {
        files.push(relativePath);
      } else {
        throw unsafeProjectionPath(relativePath);
      }
    }
  }
  await walk(root, "");
  files.sort();
  directories.sort();
  return { files, directories };
}

async function materializeProject(
  projectRoot: string,
  snapshot: ProjectSnapshot,
  signal: AbortSignal,
): Promise<void> {
  for (const directory of snapshot.directories) {
    requireActive(signal);
    await mkdir(resolve(projectRoot, ...directory.split("/")), {
      recursive: true,
    });
  }
  for (const file of snapshot.files) {
    requireActive(signal);
    const target = resolve(projectRoot, ...file.relativePath.split("/"));
    await mkdir(resolve(target, ".."), { recursive: true });
    await writeFile(target, file.bytes, { flag: "wx" });
  }
}

async function digestProjectRoot(
  root: string,
  signal: AbortSignal,
  limits: {
    maxFileCount: number;
    maxFileBytes: number;
    maxTotalBytes: number;
  },
): Promise<string> {
  return digestProjectFiles(
    (await snapshotProject(root, signal, limits)).files,
  );
}

function digestProjectFiles(files: readonly ProjectFileSnapshot[]): string {
  const canonical = createHash("sha256");
  canonical.update("pokemap-project-tree-v1\n");
  for (const file of files) {
    canonical.update(file.relativePath);
    canonical.update("\0");
    canonical.update(String(file.bytes.length));
    canonical.update("\0");
    canonical.update(createHash("sha256").update(file.bytes).digest("hex"));
    canonical.update("\n");
  }
  return canonical.digest("hex");
}

function excludedProjectPath(path: string): boolean {
  const parts = path.split("/");
  if (
    parts.some((part) =>
      [".git", ".dart_tool", ".pokemap", "build", "saves"].includes(part),
    )
  ) {
    return true;
  }
  const name = parts.at(-1) ?? "";
  return (
    name === ".DS_Store" ||
    (name.startsWith(".pokemap-project-") && name.endsWith(".lock"))
  );
}

async function freezeProjection(
  root: string,
  platform: NodeJS.Platform,
): Promise<void> {
  if (platform === "win32") {
    throw new PokeMapToolError(
      "playtest.projection_immutable_unavailable",
      "Certified playtest projections cannot be frozen on Windows.",
    );
  }
  const directories: string[] = [root];
  const files: string[] = [];
  async function collect(directory: string): Promise<void> {
    const entries = await readdir(directory, { withFileTypes: true });
    for (const entry of entries) {
      const path = resolve(directory, entry.name);
      if (entry.isDirectory()) {
        directories.push(path);
        await collect(path);
      } else if (entry.isFile()) {
        files.push(path);
      }
    }
  }
  await collect(root);
  for (const file of files) await chmod(file, 0o444);
  directories.sort((left, right) => right.length - left.length);
  for (const directory of directories) await chmod(directory, 0o555);
}

async function removeProjection(
  root: string,
  platform: NodeJS.Platform,
): Promise<void> {
  try {
    if (platform !== "win32") await thawDirectories(root);
    await rm(root, { recursive: true, force: true });
  } catch {
    await rm(root, { recursive: true, force: true });
  }
}

async function thawDirectories(root: string): Promise<void> {
  try {
    async function thaw(directory: string): Promise<void> {
      await chmod(directory, 0o700);
      const entries = await readdir(directory, { withFileTypes: true });
      for (const entry of entries) {
        const path = resolve(directory, entry.name);
        if (entry.isDirectory()) await thaw(path);
        else if (entry.isFile()) await chmod(path, 0o600);
      }
    }
    await thaw(root);
  } catch {
    return;
  }
}

function portableRelativePath(root: string, candidate: string): string {
  const normalized = relative(resolve(root), resolve(candidate)).split(sep).join("/");
  if (
    normalized.length === 0 ||
    normalized === ".." ||
    normalized.startsWith("../") ||
    normalized.startsWith("/")
  ) {
    throw new PokeMapToolError(
      "playtest.projection_path_invalid",
      "The playtest projection escaped the repository boundary.",
    );
  }
  return normalized;
}

function isAlreadyExists(error: unknown): boolean {
  return (
    error instanceof Error &&
    "code" in error &&
    (error as NodeJS.ErrnoException).code === "EEXIST"
  );
}

function unsafeProjectionDestination(path: string): PokeMapToolError {
  return new PokeMapToolError(
    "playtest.projection_path_unsafe",
    "The playtest projection destination contains an unsafe filesystem entry.",
    false,
    [],
    { path },
  );
}

function requireActive(signal: AbortSignal): void {
  if (signal.aborted) {
    throw new PokeMapToolError(
      "playtest.cancelled",
      "The playtest projection was cancelled.",
      true,
    );
  }
}

function unsafeProjectionPath(relativePath: string): PokeMapToolError {
  return new PokeMapToolError(
    "playtest.projection_path_unsafe",
    "The project contains an unsafe filesystem entry.",
    false,
    [],
    { relativePath },
  );
}
