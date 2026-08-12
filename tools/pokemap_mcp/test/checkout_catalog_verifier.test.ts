import assert from "node:assert/strict";
import { resolve } from "node:path";
import { test } from "node:test";

import {
  certifyPersonalizationCatalog,
  verifyCheckoutCatalog,
} from "../src/checkout_catalog_verifier.js";

const repositoryRoot = resolve(process.cwd(), "../..");
const projectRoot = resolve(
  repositoryRoot,
  "examples/playable_runtime_host/golden_personalization_v3",
);

test("checkout verifier certifies the packaged server from the requested repository", async () => {
  const receipt = await verifyCheckoutCatalog({ repositoryRoot, projectRoot });

  assert.equal(receipt.repositoryRoot, repositoryRoot);
  assert.match(receipt.commit, /^[0-9a-f]{40}$/);
  assert.equal(receipt.serverEntryPoint, resolve(process.cwd(), "dist/src/index.js"));
  assert.equal(receipt.presentationProfileVersion, 10);
  assert.equal(receipt.presentationPresetVersion, 2);
  assert.deepEqual(receipt.presentationUpdateTransports, [
    "cli",
    "directApi",
    "editor",
    "mcp",
  ]);
});

test("checkout verifier rejects a project outside the requested repository", async () => {
  await assert.rejects(
    verifyCheckoutCatalog({
      repositoryRoot,
      projectRoot: resolve(repositoryRoot, ".."),
    }),
    /inside the repository/i,
  );
});

test("checkout verifier fails closed on stale presentation catalog evidence", () => {
  assert.throws(
    () =>
      certifyPersonalizationCatalog({
        resourceKinds: [
          { id: "projectPresentationProfile", version: 9 },
          { id: "projectPresentationPreset", version: 2 },
        ],
        fullParity: {
          mutationActions: [
            {
              actionId: "presentation.update",
              endToEndVerifiedTransports: ["cli", "directApi", "editor"],
            },
          ],
        },
      }),
    /presentation profile resource version 10/i,
  );
});
