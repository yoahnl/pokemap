import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { lstat, readdir, readFile, realpath } from "node:fs/promises";
import { isAbsolute, join, relative, resolve, sep } from "node:path";
import type { JsonRecord } from "./authoring_client.js";

export interface RecipeAction {
  readonly actionId: string;
  readonly parameters: JsonRecord;
  readonly capture?: Readonly<Record<string, string>>;
}

export interface RecipeChoice {
  readonly resource: { readonly kind: string; readonly id?: string; readonly filters?: JsonRecord; readonly collection?: string; readonly memberId?: string };
  readonly present: RecipeAction | null;
  readonly absent: RecipeAction | null;
  readonly matches?: JsonRecord;
  readonly capture?: Readonly<Record<string, string>>;
}

export interface RecipeArtifact {
  readonly input: string;
  readonly path: string;
  readonly sha256: string;
  readonly mediaType: string;
}

export interface ContentRecipe {
  readonly schemaVersion: 1;
  readonly id: string;
  readonly validation: "authoring" | "project";
  readonly exportProfile?: JsonRecord;
  readonly provenance?: JsonRecord;
  readonly qa?: JsonRecord;
  readonly artifacts: Readonly<Record<string, RecipeArtifact>>;
  readonly requiredFiles: Readonly<Record<string, string>>;
  readonly requirements: readonly { readonly resourceKind: string; readonly id: string; readonly expected: JsonRecord }[];
  readonly actions: readonly (RecipeAction | RecipeChoice)[];
}

export function recipeRecord(value: unknown): JsonRecord {
  assert.ok(value && typeof value === "object" && !Array.isArray(value), "Expected an object");
  return value as JsonRecord;
}

function keys(value: JsonRecord, allowed: readonly string[]): void {
  assert.ok(Object.keys(value).every(key => allowed.includes(key)), "Unknown recipe field");
}

function identifier(value: unknown): asserts value is string {
  assert.ok(typeof value === "string" && /^[a-zA-Z][a-zA-Z0-9_.-]{0,127}$/.test(value), "Invalid recipe identifier");
}

export function relativeRecipePath(value: unknown): asserts value is string {
  assert.ok(typeof value === "string" && value.length > 0 && !isAbsolute(value) && !value.includes("\\") && !value.includes(":"), "Expected a relative recipe path");
  assert.ok(value.split("/").every(part => part !== "" && part !== "." && part !== ".."), "Unsafe recipe path");
}

function hash(value: unknown): asserts value is string {
  assert.ok(typeof value === "string" && /^[a-f0-9]{64}$/.test(value), "Expected SHA-256");
}

export function parseContentRecipe(value: unknown): ContentRecipe {
  const recipe = recipeRecord(value);
  keys(recipe, ["schemaVersion", "id", "validation", "provenance", "qa", "artifacts", "requiredFiles", "exportProfile", "requirements", "actions"]);
  assert.equal(recipe.schemaVersion, 1, "Unsupported recipe schemaVersion");
  identifier(recipe.id);
  assert.ok(recipe.validation === "authoring" || recipe.validation === "project", "A recipe must declare its validation scope");
  if (recipe.exportProfile !== undefined) recipeRecord(recipe.exportProfile);
  if (recipe.provenance !== undefined) recipeRecord(recipe.provenance);
  if (recipe.qa !== undefined) recipeRecord(recipe.qa);
  const artifacts = recipeRecord(recipe.artifacts ?? {});
  for (const [id, value] of Object.entries(artifacts)) {
    identifier(id);
    const artifact = recipeRecord(value);
    keys(artifact, ["input", "path", "sha256", "mediaType"]);
    identifier(artifact.input);
    relativeRecipePath(artifact.path);
    hash(artifact.sha256);
    assert.ok(typeof artifact.mediaType === "string" && /^[a-zA-Z0-9.+-]+\/[a-zA-Z0-9.+-]+$/.test(artifact.mediaType));
  }
  const requiredFiles = recipeRecord(recipe.requiredFiles ?? {});
  for (const [path, sha256] of Object.entries(requiredFiles)) {
    relativeRecipePath(path);
    hash(sha256);
  }
  const requirements = recipe.requirements ?? [];
  assert.ok(Array.isArray(requirements) && requirements.length <= 256);
  for (const value of requirements) {
    const requirement = recipeRecord(value);
    keys(requirement, ["resourceKind", "id", "expected"]);
    identifier(requirement.resourceKind);
    assert.ok(typeof requirement.id === "string" && requirement.id.length > 0 && requirement.id.length <= 256);
    recipeRecord(requirement.expected);
  }
  assert.ok(Array.isArray(recipe.actions) && (recipe.actions.length > 0 || recipe.exportProfile !== undefined), "Empty recipe");
  for (const value of recipe.actions) {
    const action = recipeRecord(value);
    if ("resource" in action) {
      keys(action, ["resource", "present", "absent", "matches", "capture"]);
      for (const [id, path] of Object.entries(recipeRecord(action.capture ?? {}))) {
        identifier(id);
        assert.ok(path === "/id" || path === "/beforeBytesBase64", "Only canonical identity and preimage values can be captured from resources");
      }
      if (action.matches !== undefined) recipeRecord(action.matches);
      const resource = recipeRecord(action.resource);
      keys(resource, ["kind", "id", "filters", "collection", "memberId"]);
      if (resource.collection !== undefined || resource.memberId !== undefined) {
        identifier(resource.collection);
        assert.ok(typeof resource.memberId === "string" && resource.memberId.length > 0 && resource.memberId.length <= 256);
      }
      identifier(resource.kind);
      assert.ok((resource.id !== undefined) !== (resource.filters !== undefined), "Select exactly one resource identity or canonical metadata filter");
      if (resource.id !== undefined) assert.ok(typeof resource.id === "string" && resource.id.length > 0 && resource.id.length <= 256);
      if (resource.filters !== undefined) assert.ok(Object.keys(recipeRecord(resource.filters)).length > 0);
      assert.ok(action.present !== undefined && action.absent !== undefined && (action.present !== null || action.absent !== null));
      if (action.present !== null) parseAction(action.present);
      if (action.absent !== null) parseAction(action.absent);
    } else parseAction(action);
  }
  return { ...recipe, artifacts, requiredFiles, requirements } as unknown as ContentRecipe;
}

function parseAction(value: unknown): void {
  const action = recipeRecord(value);
  keys(action, ["actionId", "parameters", "capture"]);
  assert.ok(typeof action.actionId === "string" && /^[a-zA-Z][a-zA-Z0-9_.]+$/.test(action.actionId));
  recipeRecord(action.parameters);
  for (const [id, path] of Object.entries(recipeRecord(action.capture ?? {}))) {
    identifier(id);
    assert.ok(typeof path === "string" && /^\/preview\/(?:[a-zA-Z0-9_-]+\/?)+$/.test(path), "Only declared plan preview values can be captured");
  }
}

export function resolveRecipeBindings(value: unknown, bindings: ReadonlyMap<string, unknown>): unknown {
  if (Array.isArray(value)) return value.map(entry => resolveRecipeBindings(entry, bindings));
  if (value !== null && typeof value === "object") {
    const object = recipeRecord(value);
    if ("$binding" in object) {
      assert.deepEqual(Object.keys(object), ["$binding"]);
      identifier(object.$binding);
      assert.ok(bindings.has(object.$binding), `Missing binding ${object.$binding}`);
      return structuredClone(bindings.get(object.$binding));
    }
    return Object.fromEntries(Object.entries(object).map(([key, entry]) => [key, resolveRecipeBindings(entry, bindings)]));
  }
  return value;
}

export function captureRecipeBindings(plan: JsonRecord, capture: Readonly<Record<string, string>>, bindings: Map<string, unknown>): void {
  for (const [id, path] of Object.entries(capture)) {
    assert.ok(!bindings.has(id), `Duplicate binding ${id}`);
    let value: unknown = plan;
    for (const part of path.slice(1).split("/")) value = recipeRecord(value)[part];
    assert.ok(value !== undefined, `Missing captured preview ${path}`);
    bindings.set(id, structuredClone(value));
  }
}

export async function regularRecipeFile(root: string, path: string): Promise<string> {
  relativeRecipePath(path);
  const canonicalRoot = await realpath(root);
  let candidate = canonicalRoot;
  const parts = path.split("/");
  for (const [index, part] of parts.entries()) {
    candidate = join(candidate, part);
    const type = await lstat(candidate);
    assert.ok(index === parts.length - 1 ? type.isFile() : type.isDirectory(), "Recipe inputs must be regular files inside their declared root");
  }
  const canonical = await realpath(candidate);
  const suffix = relative(canonicalRoot, canonical);
  assert.ok(suffix !== ".." && !suffix.startsWith(`..${sep}`) && !isAbsolute(suffix));
  return canonical;
}

export async function verifyRecipeFile(root: string, path: string, sha256: string): Promise<string> {
  const file = await regularRecipeFile(root, path);
  assert.equal(createHash("sha256").update(await readFile(file)).digest("hex"), sha256, `Recipe input changed: ${path}`);
  return file;
}

export async function assertRegularRecipeTree(root: string): Promise<void> {
  assert.ok((await lstat(root)).isDirectory(), "A project root must be a regular directory");
  for (const entry of await readdir(root, { withFileTypes: true })) {
    const path = resolve(root, entry.name);
    if (entry.isDirectory()) await assertRegularRecipeTree(path);
    else assert.ok(entry.isFile(), `Unsupported project file: ${entry.name}`);
  }
}

export function matchesRecipeState(actual: unknown, expected: unknown): boolean {
  if (Array.isArray(expected)) return Array.isArray(actual) && actual.length === expected.length && expected.every((value, index) => matchesRecipeState(actual[index], value));
  if (expected !== null && typeof expected === "object") return actual !== null && typeof actual === "object" && !Array.isArray(actual) && Object.entries(recipeRecord(expected)).every(([key, value]) => matchesRecipeState(recipeRecord(actual)[key], value));
  return Object.is(actual, expected);
}

export function recipeCollection(value: unknown, path: string): JsonRecord[] {
  let selected: unknown = value;
  for (const part of path.split(".")) {
    if (selected === null || typeof selected !== "object" || Array.isArray(selected) || !Object.hasOwn(selected, part)) return [];
    selected = recipeRecord(selected)[part];
  }
  if (selected === undefined) return [];
  assert.ok(Array.isArray(selected), "Recipe collection must be an array");
  return selected.map(recipeRecord);
}

export async function captureRecipeArtifact(root: string, path: string, sha256: string): Promise<{ file: string; digest: string; byteLength: number }> {
  const file = await regularRecipeFile(root, path);
  const metadata = await lstat(file);
  assert.ok(metadata.size <= 256 * 1024 * 1024, "Recipe artifact exceeds the canonical byte budget");
  const bytes = await readFile(file);
  assert.equal(createHash("sha256").update(bytes).digest("hex"), sha256, `Recipe input changed: ${path}`);
  const name = Buffer.from("artifact-content");
  const size = (value: number): Buffer => { const result = Buffer.alloc(8); result.writeBigUInt64BE(BigInt(value)); return result; };
  const digest = createHash("sha256").update(size(name.length)).update(name).update(size(bytes.length)).update(bytes).digest("hex");
  return { file, digest: `sha256:${digest}`, byteLength: bytes.length };
}

export function assertStagedRecipeArtifact(staged: JsonRecord, expected: { digest: string; byteLength: number }): void {
  assert.equal(staged.digest, expected.digest, "Staged artifact differs from the approved recipe input");
  assert.equal(staged.byteLength, expected.byteLength, "Staged artifact length differs from the approved recipe input");
}
