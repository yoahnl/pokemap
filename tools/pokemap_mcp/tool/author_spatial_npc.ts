import assert from "node:assert/strict";
import { realpath } from "node:fs/promises";
import { resolve } from "node:path";
import { randomUUID } from "node:crypto";
import { Client } from "@modelcontextprotocol/client";
import { StdioClientTransport } from "@modelcontextprotocol/client/stdio";
import type { JsonRecord } from "../src/authoring_client.js";

function record(value: unknown): JsonRecord {
  assert.ok(value && typeof value === "object" && !Array.isArray(value));
  return value as JsonRecord;
}

const projectRoot = await realpath(resolve(process.argv[2] ?? "../../apps/hgss_first_map"));
const transport = new StdioClientTransport({
  command: process.execPath,
  args: [resolve("dist/src/index.js"), "--root", projectRoot],
  cwd: process.cwd(),
  stderr: "pipe",
});
const client = new Client({ name: "avelune-spatial-npc-authoring", version: "1.0.0" });

async function call(name: string, args: JsonRecord = {}): Promise<JsonRecord> {
  const result = await client.callTool({ name, arguments: args });
  const envelope = record(result.structuredContent);
  assert.equal(envelope.ok, true, JSON.stringify(envelope));
  return record(envelope.data);
}

try {
  await client.connect(transport);
  const catalog = await call("pokemap_describe");
  const actions = (catalog.mutationActions as JsonRecord[]).map((action) => action.id);
  for (const action of ["entity.upsert", "npc.set_dialogue", "dialogue.create", "dialogue.update"]) {
    assert.ok(actions.includes(action), action);
  }
  const opened = await call("pokemap_workspace", { operation: "open", projectRoot });
  const projectHandle = String(opened.projectHandle);
  const workspaceHandle = String(opened.workspaceHandle);
  async function query(resourceKind: string, id: string): Promise<JsonRecord> {
    return call("pokemap_query", { projectHandle, resourceKind, operation: "get", ids: [id], view: "detail" });
  }
  async function mutate(actionId: string, parameters: JsonRecord): Promise<void> {
    const snapshot = await query("project", "project");
    const id = randomUUID();
    const plan = await call("pokemap_plan", { projectHandle, request: {
      requestId: id, actionId, actionVersion: 1, workspaceHandle, parameters,
      expectedRevision: snapshot.snapshotRevision, idempotencyKey: id,
    } });
    await call("pokemap_apply", { operation: "apply", projectHandle, planId: plan.planId, operationId: id });
  }
  try {
    const project = record((await query("project", "project")).items![0]);
    assert.equal(record(project.settings).dimension, "threeD");
    const characters = project.characters as JsonRecord[];
    const character = characters.find((entry) => entry.id === "voyageur-psdk");
    assert.ok(character, "Import the existing Voyageur PSDK character before running this recipe.");
    const map = record((await query("map", "first-map")).items![0]);
    assert.ok(map.spatialScene, "The first-map must be a spatial map.");
    const entry = {
      id: "halte-voyageur", name: "Le voyageur de la halte",
      relativePath: "dialogues/halte-voyageur.yarn", defaultStartNode: "Accueil",
    };
    const source = "title: Accueil\n---\nVoyageur: Salut ! Les falaises sont belles vues d’ici, hein ?\nVoyageur: Pour rejoindre le plateau, prends les escaliers au milieu.\n===\n";
    const exists = (project.dialogues as JsonRecord[]).some((dialogue) => dialogue.id === entry.id);
    await mutate(exists ? "dialogue.update" : "dialogue.create", { entry, source });
    await mutate("entity.upsert", {
      mapId: "first-map", entity: {
        id: "voyageur-halte", name: "Voyageur de la halte", kind: "npc",
        pos: { x: 8, y: 9 }, size: { width: 1, height: 1 }, blocksMovement: true,
        npc: { displayName: "Voyageur", characterId: character.id, facing: "south" },
      },
    });
    await mutate("npc.set_dialogue", {
      mapId: "first-map", entityId: "voyageur-halte",
      dialogue: { dialogueId: entry.id, startNode: "Accueil" },
    });
    const persisted = record((await query("map", "first-map")).items![0]);
    const npc = (persisted.entities as JsonRecord[]).find((entity) => entity.id === "voyageur-halte");
    assert.equal(record(record(npc!.npc).dialogue).dialogueId, entry.id);
    assert.equal(record(npc!.pos).y, 9);
    const validation = await call("pokemap_validate", { projectHandle });
    process.stdout.write(`${JSON.stringify({ projectRoot, npcId: npc!.id, dialogueId: entry.id, validation })}\n`);
  } finally {
    await call("pokemap_workspace", { operation: "close", workspaceHandle });
  }
} finally {
  await client.close();
}
