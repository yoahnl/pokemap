import { execFileSync } from "node:child_process";
import { existsSync, realpathSync } from "node:fs";
import { dirname, isAbsolute, relative, resolve } from "node:path";
import { fileURLToPath } from "node:url";

import { Client } from "@modelcontextprotocol/client";
import { StdioClientTransport } from "@modelcontextprotocol/client/stdio";

type JsonRecord = Record<string, unknown>;

export interface CheckoutCatalogVerificationInput {
  repositoryRoot: string;
  projectRoot: string;
}

export interface CheckoutCatalogReceipt {
  repositoryRoot: string;
  projectRoot: string;
  commit: string;
  workingTreeClean: boolean;
  serverEntryPoint: string;
  presentationProfileVersion: number;
  presentationPresetVersion: number;
  presentationUpdateTransports: string[];
  cinematicActionIds: string[];
  cinematicResourceKinds: string[];
  legacyCinematicCatalogIds: string[];
}

export interface PersonalizationCatalogCertification {
  presentationProfileVersion: number;
  presentationPresetVersion: number;
  presentationUpdateTransports: string[];
}

export interface CinematicV2CatalogCertification {
  cinematicActionIds: string[];
  cinematicResourceKinds: string[];
  legacyCinematicCatalogIds: string[];
}

const requiredPresentationTransports = [
  "cli",
  "directApi",
  "editor",
  "mcp",
] as const;

export async function verifyCheckoutCatalog(
  input: CheckoutCatalogVerificationInput,
): Promise<CheckoutCatalogReceipt> {
  const repositoryRoot = realpathSync(resolve(input.repositoryRoot));
  const projectRoot = realpathSync(resolve(input.projectRoot));
  const projectRelativePath = relative(repositoryRoot, projectRoot);
  if (
    projectRelativePath === "" ||
    projectRelativePath === ".." ||
    projectRelativePath.startsWith(`..${process.platform === "win32" ? "\\" : "/"}`) ||
    isAbsolute(projectRelativePath)
  ) {
    throw new Error("The verification project must be inside the repository.");
  }

  const packageRoot = resolve(repositoryRoot, "tools/pokemap_mcp");
  const serverEntryPoint = resolve(packageRoot, "dist/src/index.js");
  if (!existsSync(serverEntryPoint)) {
    throw new Error("The checkout MCP server must be built before verification.");
  }

  const transport = new StdioClientTransport({
    command: process.execPath,
    args: [serverEntryPoint, "--root", projectRoot],
    cwd: packageRoot,
    stderr: "pipe",
  });
  const client = new Client({
    name: "pokemap-checkout-catalog-verifier",
    version: "1.0.0",
  });

  try {
    await client.connect(transport);
    const result = await client.callTool({
      name: "pokemap_describe",
      arguments: {},
    });
    if (result.isError) {
      throw new Error("pokemap_describe failed for the checkout server.");
    }
    const envelope = record(result.structuredContent);
    if (envelope.ok !== true) {
      throw new Error("pokemap_describe returned an unsuccessful envelope.");
    }
    const data = record(envelope.data);
    const certification = certifyPersonalizationCatalog(data);
    const cinematicCertification = certifyCinematicV2Catalog(data);

    return {
      repositoryRoot,
      projectRoot,
      commit: git(repositoryRoot, ["rev-parse", "HEAD"]),
      workingTreeClean:
        git(repositoryRoot, ["status", "--porcelain", "--untracked-files=all"]) ===
        "",
      serverEntryPoint,
      ...certification,
      ...cinematicCertification,
    };
  } finally {
    await client.close();
  }
}

export function certifyCinematicV2Catalog(
  data: JsonRecord,
): CinematicV2CatalogCertification {
  const actionIds = records(data.mutationActions).map((action) =>
    string(action.id),
  );
  const resourceKinds = records(data.resourceKinds).map((resource) =>
    string(resource.id),
  );
  const cinematicActionIds = actionIds.filter(
    (id) =>
      id.startsWith("cinematic.") ||
      id.startsWith("cinematicLibrary") ||
      id.startsWith("presentationCinematic"),
  );
  const cinematicResourceKinds = resourceKinds.filter(
    (id) =>
      id.startsWith("cinematicLibrary") ||
      id.startsWith("presentationCinematic"),
  );
  const legacyCinematicCatalogIds = [
    ...actionIds.filter(
      (id) => id.startsWith("scenario.") || /^cutscene[.:]/i.test(id),
    ),
    ...resourceKinds.filter(
      (id) => id === "scenario" || /^cutscene/i.test(id),
    ),
  ];

  if (legacyCinematicCatalogIds.length > 0) {
    throw new Error(
      `Legacy cinematic catalog entries remain: ${legacyCinematicCatalogIds.join(", ")}.`,
    );
  }
  if (
    !cinematicActionIds.includes("cinematic.upsert") ||
    !cinematicActionIds.includes("presentationCinematic.create") ||
    !cinematicResourceKinds.includes("presentationCinematic")
  ) {
    throw new Error("Expected both canonical cinematic families in the catalog.");
  }

  return {
    cinematicActionIds,
    cinematicResourceKinds,
    legacyCinematicCatalogIds,
  };
}

export function certifyPersonalizationCatalog(
  data: JsonRecord,
): PersonalizationCatalogCertification {
  const resourceKinds = records(data.resourceKinds);
  const profile = resourceKinds.find(
    (resource) => resource.id === "projectPresentationProfile",
  );
  const preset = resourceKinds.find(
    (resource) => resource.id === "projectPresentationPreset",
  );
  const parity = record(data.fullParity);
  const presentationUpdate = records(parity.mutationActions).find(
    (action) => action.actionId === "presentation.update",
  );
  const presentationProfileVersion = number(profile?.version);
  const presentationPresetVersion = number(preset?.version);
  const presentationUpdateTransports = strings(
    presentationUpdate?.endToEndVerifiedTransports,
  );

  if (presentationProfileVersion !== 10) {
    throw new Error("Expected presentation profile resource version 10.");
  }
  if (presentationPresetVersion !== 2) {
    throw new Error("Expected presentation preset resource version 2.");
  }
  if (
    presentationUpdateTransports.length !==
      requiredPresentationTransports.length ||
    requiredPresentationTransports.some(
      (transport, index) => presentationUpdateTransports[index] !== transport,
    )
  ) {
    throw new Error(
      "Expected presentation.update parity for cli, directApi, editor, and mcp.",
    );
  }

  return {
    presentationProfileVersion,
    presentationPresetVersion,
    presentationUpdateTransports,
  };
}

function record(value: unknown): JsonRecord {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    throw new Error("Expected a JSON object from pokemap_describe.");
  }
  return value as JsonRecord;
}

function records(value: unknown): JsonRecord[] {
  if (!Array.isArray(value)) {
    throw new Error("Expected a JSON object array from pokemap_describe.");
  }
  return value.map(record);
}

function strings(value: unknown): string[] {
  if (!Array.isArray(value) || value.some((item) => typeof item !== "string")) {
    throw new Error("Expected a string array from pokemap_describe.");
  }
  return value as string[];
}

function number(value: unknown): number {
  if (typeof value !== "number") {
    throw new Error("Expected a numeric resource version from pokemap_describe.");
  }
  return value;
}

function string(value: unknown): string {
  if (typeof value !== "string") {
    throw new Error("Expected a string identifier from pokemap_describe.");
  }
  return value;
}

function git(repositoryRoot: string, args: string[]): string {
  return execFileSync("git", ["-C", repositoryRoot, ...args], {
    encoding: "utf8",
  }).trim();
}

async function main(): Promise<void> {
  const moduleDirectory = dirname(fileURLToPath(import.meta.url));
  const repositoryRoot = resolve(moduleDirectory, "../../../..");
  const projectRoot = resolve(
    repositoryRoot,
    "examples/playable_runtime_host/golden_personalization_v3",
  );
  const receipt = await verifyCheckoutCatalog({ repositoryRoot, projectRoot });
  process.stdout.write(`${JSON.stringify(receipt, null, 2)}\n`);
  if (!receipt.workingTreeClean) {
    process.exitCode = 1;
  }
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  void main();
}
