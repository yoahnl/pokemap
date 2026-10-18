import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";
import { cp, lstat, mkdir, mkdtemp, readdir, readFile, realpath, rm } from "node:fs/promises";
import { setTimeout as delay } from "node:timers/promises";
import { tmpdir } from "node:os";
import { basename, dirname, isAbsolute, join, relative, resolve, sep } from "node:path";
import { Client } from "@modelcontextprotocol/client";
import { StdioClientTransport } from "@modelcontextprotocol/client/stdio";
import type { JsonRecord } from "./authoring_client.js";
import { assertRegularRecipeTree, assertStagedRecipeArtifact, captureRecipeArtifact, captureRecipeBindings, matchesRecipeState, parseContentRecipe, recipeCollection, recipeRecord as record, resolveRecipeBindings, verifyRecipeFile } from "./content_recipe.js";

async function main(): Promise<void> {
  const projectRoot = await realpath(requiredArgument("--project-root"));
  const serverPath = requiredArgument("--server");
  const actionsPath = requiredArgument("--actions");
  const requestedOutput = requiredArgument("--project-out");
  const projectOut = join(await realpath(dirname(requestedOutput)), basename(requestedOutput));
  const suffix = relative(projectRoot, projectOut);
  assert.ok(suffix !== "" && (suffix === ".." || suffix.startsWith(`..${sep}`) || isAbsolute(suffix)), "Output must be outside the source project");
  await assert.rejects(lstat(projectOut), { code: "ENOENT" }, "Output already exists");
  const recipe = parseContentRecipe(JSON.parse(await readFile(actionsPath, "utf8")));
  await assertRegularRecipeTree(projectRoot);
  for (const [path, sha256] of Object.entries(recipe.requiredFiles)) await verifyRecipeFile(projectRoot, path, sha256);
  const inputs = new Map<string, string>();
  for (let index = 2; index < process.argv.length; index++) {
    if (process.argv[index] !== "--input") continue;
    const argument = process.argv[++index] ?? "";
    const equals = argument.indexOf("=");
    assert.ok(equals > 0, "Expected --input name=absolute-directory");
    const name = argument.slice(0, equals), path = argument.slice(equals + 1);
    assert.ok(/^[a-zA-Z][a-zA-Z0-9_.-]{0,127}$/.test(name) && isAbsolute(path) && !inputs.has(name));
    inputs.set(name, await realpath(path));
  }
  const artifactFiles = new Map<string, { file: string; digest: string; byteLength: number }>();
  for (const [id, artifact] of Object.entries(recipe.artifacts)) {
    const root = inputs.get(artifact.input);
    assert.ok(root, `Missing declared input ${artifact.input}`);
    artifactFiles.set(id, await captureRecipeArtifact(root, artifact.path, artifact.sha256));
  }
  assert.ok([...inputs.keys()].every(input => Object.values(recipe.artifacts).some(artifact => artifact.input === input)), "Unused input root");
  const temporaryRoot = await mkdtemp(join(tmpdir(), "pokemap-mcp-sequence-"));
  const workingRoot = join(temporaryRoot, basename(projectRoot));
  const args = [serverPath, "--root", workingRoot, "--authoring-timeout-ms", "60000"];
  for (const root of inputs.values()) args.push("--artifact-root", root);
  const transport = new StdioClientTransport({ command: process.execPath, args, cwd: resolve(dirname(serverPath), "../.."), stderr: "pipe" });
  const client = new Client({ name: "pokemap-authoring-sequence-runner", version: "1.0.0" });
  let published = false;
  try {
    await cp(projectRoot, workingRoot, { recursive: true, dereference: false });
    await assertRegularRecipeTree(workingRoot);
    for (const [path, sha256] of Object.entries(recipe.requiredFiles)) await verifyRecipeFile(workingRoot, path, sha256);
    await client.connect(transport);
    const catalog = await toolData(client, "pokemap_describe", {});
    const descriptors = new Map((catalog.mutationActions as JsonRecord[]).map(value => [String(value.id), value]));
    for (const step of recipe.actions) {
      const actions = "resource" in step ? [step.present, step.absent].filter(value => value !== null) : [step];
      for (const action of actions) assert.ok(descriptors.has(action.actionId), `Undiscovered action ${action.actionId}`);
    }
    const opened = await toolData(client, "pokemap_workspace", { operation: "open", projectRoot: workingRoot });
    const projectHandle = String(opened.projectHandle), workspaceHandle = String(opened.workspaceHandle);
    const snapshot = async () => toolData(client, "pokemap_query", { projectHandle, resourceKind: "project", operation: "get", ids: ["project"], view: "detail" });
    let revision = String((await snapshot()).snapshotRevision);
    const initialRevision = revision;
    for (const requirement of recipe.requirements) {
      const found = await toolData(client, "pokemap_query", { projectHandle, resourceKind: requirement.resourceKind, operation: "get", ids: [requirement.id], view: "detail" });
      assert.ok(matchesRecipeState((found.items as unknown[])[0], requirement.expected), `Recipe precondition changed: ${requirement.resourceKind}/${requirement.id}`);
    }
    const bindings = new Map<string, unknown>();
    for (const [id, artifact] of Object.entries(recipe.artifacts)) {
      const root = inputs.get(artifact.input)!;
      await verifyRecipeFile(root, artifact.path, artifact.sha256);
      const staged = await toolData(client, "pokemap_artifact_stage", { sourcePath: artifactFiles.get(id)!.file, declaredMediaType: artifact.mediaType });
      assertStagedRecipeArtifact(staged, artifactFiles.get(id)!);
      bindings.set(id, staged.artifactHandle);
    }
    const appliedActionIds: string[] = [], unchangedActionIds: string[] = [];
    for (const step of recipe.actions) {
      let action;
      if ("resource" in step) {
        const found = await toolData(client, "pokemap_query", { projectHandle, resourceKind: step.resource.kind, operation: step.resource.id === undefined ? "list" : "batch_get",
          ...(step.resource.id === undefined ? { filters: step.resource.filters, pageSize: 2 } : { ids: [step.resource.id] }), view: "detail" });
        const items = found.items as JsonRecord[];
        assert.ok(items.length <= 1 && !found.nextCursor, "Recipe resource selection must be unambiguous");
        const foundResource = step.resource.collection === undefined ? items[0]
          : items.flatMap(item => recipeCollection(item, step.resource.collection!)).find(member => member.id === step.resource.memberId);
        if (foundResource !== undefined) captureRecipeBindings(foundResource, step.capture ?? {}, bindings);
        if (foundResource !== undefined && step.matches !== undefined && matchesRecipeState(foundResource, step.matches)) {
          if (step.present !== null) unchangedActionIds.push(step.present.actionId);
          continue;
        }
        action = foundResource !== undefined ? step.present : step.absent;
      } else action = step;
      if (action === null) continue;
      const descriptor = descriptors.get(action.actionId)!;
      const operationId = randomUUID();
      let planned: JsonRecord;
      try {
        planned = await toolData(client, "pokemap_plan", { projectHandle, request: {
        requestId: operationId, actionId: action.actionId, actionVersion: descriptor.version,
        workspaceHandle, parameters: resolveRecipeBindings(action.parameters, bindings),
        expectedRevision: revision, idempotencyKey: operationId, dryRun: false,
      } });
      } catch (error) {
        if (error instanceof RecipeAuthoringError && error.code.endsWith(".no_change") && action.capture === undefined) {
          unchangedActionIds.push(action.actionId);
          continue;
        }
        throw error;
      }
      captureRecipeBindings(planned, action.capture ?? {}, bindings);
      if (planned.applicable === false && planned.nonApplicableReason === "no_changes") {
        unchangedActionIds.push(action.actionId);
        continue;
      }
      assert.equal(planned.applicable, true, JSON.stringify(planned));
      let confirmationToken: string | undefined;
      if (["high", "critical"].includes(String(descriptor.riskLevel))) {
        confirmationToken = String((await toolData(client, "pokemap_apply", { operation: "confirm", projectHandle, planId: planned.planId })).confirmationToken);
      }
      const applied = await toolData(client, "pokemap_apply", { operation: "apply", projectHandle, planId: planned.planId, operationId,
        ...(confirmationToken ? { confirmationToken } : {}),
      });
      const receipt = record(applied.receipt);
      assert.equal(receipt.actionId, action.actionId);
      assert.equal(receipt.status, "applied");
      appliedActionIds.push(action.actionId);
      revision = String((await snapshot()).snapshotRevision);
    }
    let exportProfileReceipt: JsonRecord | null = null;
    if (recipe.exportProfile !== undefined) {
      const checked = await toolData(client, "pokemap_game_export_profile_validate", { projectHandle, profile: recipe.exportProfile });
      exportProfileReceipt = await toolData(client, "pokemap_game_export_profile_save", { projectHandle, profile: recipe.exportProfile, expectedProfileRevision: checked.profileRevision, expectedContextRevision: checked.contextRevision });
    }
    const validation = await toolData(client, "pokemap_validate", { projectHandle });
    assert.equal(record(validation.structure).valid, true, JSON.stringify(validation));
    assert.equal(record(validation.references).valid, true, JSON.stringify(validation));
    if (recipe.validation === "project") assert.equal(validation.valid, true, JSON.stringify(validation));
    await toolData(client, "pokemap_workspace", { operation: "close", workspaceHandle });
    await mkdir(projectOut);
    published = true;
    for (const entry of await readdir(workingRoot)) {
      await cp(join(workingRoot, entry), join(projectOut, entry), { recursive: true, errorOnExist: true, force: false });
    }
    process.stdout.write(JSON.stringify({ schemaVersion: 1, recipeId: recipe.id, transport: "mcp", projectOut,
      appliedActionIds, unchangedActionIds, initialRevision, finalRevision: revision,
      validationScope: recipe.validation, validation, exportProfileReceipt, provenance: recipe.provenance ?? null, qa: recipe.qa ?? null,
    }));
  } catch (error) {
    if (published) await rm(projectOut, { recursive: true, force: true });
    throw error;
  } finally {
    try {
      await client.close();
    } finally {
      try {
        await transport.close();
      } finally {
        await rm(temporaryRoot, { recursive: true, force: true });
      }
    }
  }
}

class RecipeAuthoringError extends Error {
  constructor(readonly code: string, message: string) { super(message); }
}

const lastToolCalls = new Map<string, number>();

async function toolData(client: Client, name: string, args: JsonRecord): Promise<JsonRecord> {
  const wait = 1100 - (Date.now() - (lastToolCalls.get(name) ?? 0));
  if (wait > 0) await delay(wait);
  lastToolCalls.set(name, Date.now());
  const result = await client.callTool({ name, arguments: args });
  const envelope = record(result.structuredContent);
  if (envelope.ok !== true) {
    const error = record(envelope.error);
    const details = record(error.details ?? {});
    throw new RecipeAuthoringError(String(error.domainCode ?? details.domainCode ?? error.code), JSON.stringify(envelope));
  }
  assert.equal(result.isError, undefined, JSON.stringify(result.structuredContent ?? result.content));
  return record(envelope.data);
}

function requiredArgument(name: string): string {
  const index = process.argv.indexOf(name);
  assert.ok(index >= 0 && index + 1 < process.argv.length, `Missing ${name}`);
  return resolve(process.argv[index + 1]!);
}

void main().catch((error: unknown) => {
  process.stderr.write(`${error instanceof Error ? error.stack : String(error)}\n`);
  process.exitCode = 1;
});
