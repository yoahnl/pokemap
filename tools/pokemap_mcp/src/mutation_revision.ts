import assert from "node:assert/strict";
import type { Client } from "@modelcontextprotocol/client";
import type { JsonRecord } from "./authoring_client.js";

export async function mutationRevision(
  client: Client,
  projectHandle: string,
  actionId: string,
  parameters: JsonRecord,
  projectRevision: unknown,
): Promise<{ expectedRevision: string; extensions?: JsonRecord }> {
  const response = await client.callTool({
    name: "pokemap_workshop",
    arguments: { operation: "read", projectHandle, actionId, parameters, includeDocuments: false },
  });
  const envelope = response.structuredContent as JsonRecord | undefined;
  assert.ok(envelope);
  if (response.isError) {
    const error = envelope.error as JsonRecord;
    assert.ok(
      error.domainCode === "project.workshop_scope_required" ||
        error.domainCode === "project.field_traversal_scope_required",
      JSON.stringify(error),
    );
    assert.ok(typeof projectRevision === "string");
    return { expectedRevision: projectRevision };
  }
  assert.equal(envelope.ok, true);
  const workshop = envelope.data as JsonRecord;
  assert.ok(typeof workshop.snapshotRevision === "string");
  return { expectedRevision: workshop.snapshotRevision, extensions: workshop.planExtensions as JsonRecord };
}
