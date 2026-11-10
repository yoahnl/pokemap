import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { test } from "node:test";

import { followerApiSpeciesId, followerSpeciesSelection, readFollowerProjection } from "../src/follower_import_cli.js";

test("matches the API identity by its national Pokedex number", () => {
  assert.equal(followerApiSpeciesId(29, { id: 29, name: "nidoran-f" }), "nidoran-f");
  assert.equal(followerApiSpeciesId(122, { id: 122, name: "mr-mime" }), "mr-mime");
  assert.equal(followerApiSpeciesId(250, { id: 250, name: "ho-oh" }), "ho-oh");
  assert.throws(() => followerApiSpeciesId(29, { id: 32, name: "nidoran-m" }));
  assert.throws(() => followerApiSpeciesId(29, { id: 29, name: "../nidoran" }));
  assert.deepEqual([...followerSpeciesSelection("nidoran_f,nidoran_m")], ["nidoran_f", "nidoran_m"]);
  assert.throws(() => followerSpeciesSelection("nidoran_f,"));
});

test("reads a paged preview and rejects a corrupted projection", async () => {
  const preview = { added: Array.from({ length: 160 }, (_, id) => ({ id })), preserved: [], conflicts: [] };
  const bytes = Buffer.from(JSON.stringify(preview));
  const projection = {
    projectionType: "jsonPayload", payloadRef: "payload-test", byteLength: bytes.length,
    rawSha256: createHash("sha256").update(bytes).digest("hex"),
  };
  const read = async (_ref: string, offset: number) => {
    const chunk = bytes.subarray(offset, offset + 300);
    return { bytesBase64: chunk.toString("base64"), offset,
      nextOffset: offset + chunk.length, totalBytes: bytes.length };
  };
  assert.deepEqual(await readFollowerProjection(projection, read), preview);
  assert.deepEqual(await readFollowerProjection(preview, read), preview);
  await assert.rejects(readFollowerProjection({ ...projection, rawSha256: "0".repeat(64) }, read));
  await assert.rejects(readFollowerProjection(projection, async () => ({
    bytesBase64: "", offset: 0, nextOffset: 0, totalBytes: bytes.length,
  })));
});
