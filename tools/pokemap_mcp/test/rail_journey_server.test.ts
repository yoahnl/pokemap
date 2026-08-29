import assert from "node:assert/strict";
import { mkdir, mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { test } from "node:test";

import { Client } from "@modelcontextprotocol/client";
import { InMemoryTransport } from "@modelcontextprotocol/server";

import {
  type JsonRecord,
  LocalAuthoringClient,
} from "../src/authoring_client.js";
import { MemoryArtifactReader } from "../src/artifacts.js";
import { createPokeMapMcpServer } from "../src/server.js";

const repositoryRoot = resolve(process.cwd(), "../..");
const authoringPackageRoot = resolve(repositoryRoot, "packages/map_authoring");
const scaffold = resolve(
  repositoryRoot,
  "examples/playable_runtime_host/phase6_authoring_golden_slice/project.json",
);

function record(value: unknown): JsonRecord {
  assert.ok(value && typeof value === "object" && !Array.isArray(value));
  return value as JsonRecord;
}

async function toolData(
  client: Client,
  name: string,
  args: JsonRecord = {},
): Promise<JsonRecord> {
  const result = await client.callTool({ name, arguments: args });
  assert.equal(result.isError, undefined, JSON.stringify(result.structuredContent));
  const envelope = record(result.structuredContent);
  assert.equal(envelope.ok, true);
  return record(envelope.data);
}

test("MCP discovers, queries, upserts and deletes RailJourneys", async () => {
  const root = await mkdtemp(join(tmpdir(), "pokemap-mcp-rail-journey-"));
  await writeFixture(root);
  const authoring = new LocalAuthoringClient({
    allowedRoots: [root],
    authoringPackageRoot,
  });
  const server = createPokeMapMcpServer({
    authoring,
    artifacts: new MemoryArtifactReader(),
  });
  const [clientTransport, serverTransport] = InMemoryTransport.createLinkedPair();
  const client = new Client({ name: "pokemap-rail-test", version: "1.0.0" });
  await server.connect(serverTransport);
  await client.connect(clientTransport);

  try {
    const description = await toolData(client, "pokemap_describe");
    const resource = (description.resourceKinds as JsonRecord[]).find(
      (candidate) => candidate.id === "railJourney",
    );
    const actions = (description.mutationActions as JsonRecord[]).filter(
      (candidate) => String(candidate.id).startsWith("rail_journey."),
    );
    assert.equal(resource?.version, 1);
    assert.deepEqual(
      actions.map((action) => action.id),
      ["rail_journey.delete", "rail_journey.upsert"],
    );
    for (const action of actions) {
      assert.deepEqual(action.capabilityIds, ["authoring.narrative.modern"]);
    }

    const opened = await toolData(client, "pokemap_workspace", {
      operation: "open",
      projectRoot: root,
    });
    const projectHandle = String(opened.projectHandle);
    const workspaceHandle = String(opened.workspaceHandle);
    const empty = await toolData(client, "pokemap_query", {
      projectHandle,
      resourceKind: "railJourney",
      operation: "list",
      view: "detail",
    });
    assert.equal(empty.totalAvailable, 0);

    const createPlan = await toolData(client, "pokemap_plan", {
      projectHandle,
      request: {
        requestId: "mcp-rail-create",
        actionId: "rail_journey.upsert",
        actionVersion: 1,
        workspaceHandle,
        parameters: { journey: railJourney },
        expectedRevision: empty.snapshotRevision,
        idempotencyKey: "mcp-rail-create-v1",
        dryRun: false,
      },
    });
    const createApply = await toolData(client, "pokemap_apply", {
      operation: "apply",
      projectHandle,
      planId: createPlan.planId,
      operationId: "mcp-rail-create-operation",
    });
    assert.equal(record(createApply.receipt).status, "applied");

    const created = await toolData(client, "pokemap_query", {
      projectHandle,
      resourceKind: "railJourney",
      operation: "get",
      view: "detail",
      ids: ["T1"],
    });
    const createdJourney = record((created.items as JsonRecord[])[0]);
    assert.equal(createdJourney.resourceKind, "railJourney");
    assert.equal(createdJourney.vehicleMapId, "map_train_car");
    assert.equal(record(createdJourney.origin).stationMapId, "map_origin_station");

    const deletePlan = await toolData(client, "pokemap_plan", {
      projectHandle,
      request: {
        requestId: "mcp-rail-delete",
        actionId: "rail_journey.delete",
        actionVersion: 1,
        workspaceHandle,
        parameters: { journeyId: "T1" },
        expectedRevision: created.snapshotRevision,
        idempotencyKey: "mcp-rail-delete-v1",
        dryRun: false,
      },
    });
    const confirmation = await toolData(client, "pokemap_apply", {
      operation: "confirm",
      projectHandle,
      planId: deletePlan.planId,
    });
    const deleteApply = await toolData(client, "pokemap_apply", {
      operation: "apply",
      projectHandle,
      planId: deletePlan.planId,
      operationId: "mcp-rail-delete-operation",
      confirmationToken: confirmation.confirmationToken,
    });
    assert.equal(record(deleteApply.receipt).status, "applied");

    const deleted = await toolData(client, "pokemap_query", {
      projectHandle,
      resourceKind: "railJourney",
      operation: "list",
      view: "detail",
    });
    assert.equal(deleted.totalAvailable, 0);
  } finally {
    await client.close();
    await server.close();
    await authoring.close();
    await rm(root, { recursive: true, force: true });
  }
});

async function writeFixture(root: string): Promise<void> {
  await mkdir(join(root, "maps"), { recursive: true });
  const projectDocument = record(
    JSON.parse(await readFile(scaffold, "utf8")),
  );
  projectDocument.maps = railProjectFields.maps;
  projectDocument.tilesets = railProjectFields.tilesets;
  projectDocument.elementCategories = railProjectFields.elementCategories;
  projectDocument.elements = railProjectFields.elements;
  await writeFile(join(root, "project.json"), JSON.stringify(projectDocument));
  for (const map of mapDocuments) {
    await writeFile(join(root, "maps", `${map.id}.json`), JSON.stringify(map));
  }
}

const railProjectFields = {
  maps: [
    {
      id: "map_origin_station",
      name: "Origin station",
      relativePath: "maps/map_origin_station.json",
    },
    {
      id: "map_destination_station",
      name: "Destination station",
      relativePath: "maps/map_destination_station.json",
    },
    {
      id: "map_train_car",
      name: "Train car",
      relativePath: "maps/map_train_car.json",
      role: "interior",
    },
  ],
  tilesets: [
    { id: "doors", name: "Doors", relativePath: "tilesets/doors.png" },
  ],
  elementCategories: [{ id: "doors", name: "Doors" }],
  elements: [
    element("element_station_west", "Station west door"),
    element("element_station_east", "Station east door"),
    element("element_vehicle_west", "Vehicle west door"),
    element("element_vehicle_east", "Vehicle east door"),
  ],
};

function element(id: string, name: string): JsonRecord {
  return {
    id,
    name,
    tilesetId: "doors",
    categoryId: "doors",
    frames: [
      { source: { x: 0, y: 0 }, durationMs: 120 },
      { source: { x: 1, y: 0 }, durationMs: 120 },
    ],
  };
}

const mapDocuments = [
  mapDocument("map_origin_station", "Origin station", [
    placedDoor("door_origin_west", "element_station_west", 2, 3),
  ]),
  mapDocument("map_destination_station", "Destination station", [
    placedDoor("door_destination_east", "element_station_east", 4, 2),
  ]),
  mapDocument("map_train_car", "Train car", [
    placedDoor("door_vehicle_west", "element_vehicle_west", 1, 4),
    placedDoor("door_vehicle_east", "element_vehicle_east", 6, 4),
  ]),
];

function mapDocument(
  id: string,
  name: string,
  placedElements: JsonRecord[],
): JsonRecord {
  return {
    id,
    name,
    size: { width: 10, height: 10 },
    version: "v6",
    layers: [{ runtimeType: "object", id: "doors", name: "Doors" }],
    placedElements,
  };
}

function placedDoor(
  id: string,
  elementId: string,
  x: number,
  y: number,
): JsonRecord {
  return { id, layerId: "doors", elementId, pos: { x, y } };
}

const railJourney = {
  id: "T1",
  label: "Origin to destination",
  origin: {
    stationMapId: "map_origin_station",
    boardingArea: { pos: { x: 2, y: 3 }, size: { width: 3, height: 2 } },
    trainEntryPos: { x: 1, y: 4 },
    stationArrivalPos: { x: 3, y: 6 },
    doors: [
      {
        side: "west",
        stationPlacedElementId: "door_origin_west",
        vehiclePlacedElementId: "door_vehicle_west",
      },
    ],
  },
  destination: {
    stationMapId: "map_destination_station",
    boardingArea: { pos: { x: 4, y: 2 }, size: { width: 2, height: 3 } },
    trainEntryPos: { x: 6, y: 4 },
    stationArrivalPos: { x: 7, y: 6 },
    doors: [
      {
        side: "east",
        stationPlacedElementId: "door_destination_east",
        vehiclePlacedElementId: "door_vehicle_east",
      },
    ],
  },
  vehicleMapId: "map_train_car",
  vehicleVariant: "regular",
  shellState: "day",
  fare: { policy: "story_free", amount: 0 },
  requirements: {
    completedStoryStepIds: [],
    requiredFactIds: [],
    requiredAnyFactIds: [],
    requiredItemIds: [],
    requiredStampIds: [],
  },
};
