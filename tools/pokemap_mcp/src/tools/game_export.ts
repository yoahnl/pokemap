import { isAbsolute } from "node:path";

import { type McpServer } from "@modelcontextprotocol/server";
import { z } from "zod";

import {
  type AuthoringGateway,
  type ProjectRootResolver,
} from "../authoring_client.js";
import { authoringResult, toolEnvelopeSchema } from "./result.js";

export function registerGameExportTool(
  server: McpServer,
  authoring: AuthoringGateway,
  projectRoots: ProjectRootResolver | undefined,
): void {
  const profileSchema = z.object({
    schemaVersion: z.literal(1), gameId: z.string().min(1),
    gameVersion: z.string().min(1), title: z.string().min(1),
    description: z.string().optional(),
    author: z.object({ name: z.string().min(1), url: z.string().optional() }).strict(),
    publisher: z.object({ name: z.string().min(1), url: z.string().optional() }).strict().optional(),
    locales: z.object({ default: z.string().min(1), supported: z.array(z.string().min(1)).min(1) }).strict(),
    requiredCapabilities: z.array(z.string()),
    branding: z.object({ iconPath: z.string().optional(), coverPath: z.string().optional(),
      heroPath: z.string().optional(), titleMusicPath: z.string().optional(),
      accentColor: z.string().optional(), layoutVariant: z.string().optional() }).strict(),
    legal: z.object({ licensePath: z.string().optional(), creditsPath: z.string().optional() }).strict(),
  }).strict();
  const profileRoot = (projectHandle: string): string => {
    if (!projectRoots) throw new Error("Project-root resolution is unavailable.");
    return projectRoots.resolveProjectRoot(projectHandle);
  };
  server.registerTool("pokemap_game_export_profile_read", {
    title: "Read the persisted game export profile",
    description: "Reads the exact project-local export profile and opaque profile/context revisions. Context covers project.json, the enabled new-game start map and the declared profile assets; it is not a global project revision.",
    inputSchema: z.object({ projectHandle: z.string().min(1) }).strict(),
    outputSchema: toolEnvelopeSchema,
    annotations: { readOnlyHint: true, destructiveHint: false, idempotentHint: true, openWorldHint: false },
  }, async ({ projectHandle }) => authoringResult(() => authoring.request("game_export_profile_read", { projectRoot: profileRoot(projectHandle) })));
  server.registerTool("pokemap_game_export_profile_validate", {
    title: "Validate a proposed game export profile",
    description: "Validates typed profile metadata and safe existing project-relative references without writing. Returns revisions bound to this proposed profile's context for a later save.",
    inputSchema: z.object({ projectHandle: z.string().min(1), profile: profileSchema }).strict(),
    outputSchema: toolEnvelopeSchema,
    annotations: { readOnlyHint: true, destructiveHint: false, idempotentHint: true, openWorldHint: false },
  }, async ({ projectHandle, profile }) => authoringResult(() => authoring.request("game_export_profile_validate", { projectRoot: profileRoot(projectHandle), profile })));
  server.registerTool("pokemap_game_export_profile_save", {
    title: "Save the validated game export profile",
    description: "Saves only .pokemap/export-profile-v1.json through canonical locked atomic persistence. Requires the profile and context revisions returned by validation. Strict CAS serializes profile writers; context is checked freshly before rename without multi-file atomicity. Stale revisions or unsafe references are rejected. Subsequent game export uses this persisted profile.",
    inputSchema: z.object({ projectHandle: z.string().min(1), profile: profileSchema,
      expectedProfileRevision: z.string().min(1), expectedContextRevision: z.string().min(1) }).strict(),
    outputSchema: toolEnvelopeSchema,
    annotations: { readOnlyHint: false, destructiveHint: false, idempotentHint: false, openWorldHint: false },
  }, async ({ projectHandle, profile, expectedProfileRevision, expectedContextRevision }) => authoringResult(() => authoring.request("game_export_profile_save", {
    projectRoot: profileRoot(projectHandle), profile, expectedProfileRevision, expectedContextRevision,
  })));
  server.registerTool(
    "pokemap_game_export",
    {
      title: "Export an Avelune game package",
      description:
        "Builds and writes one .avelunegame file into a configured export root. Publication requires a certified complete story; localTest retains story warnings and validates runtime data, including 3D exploration projects with static character NPCs and text dialogues. The distinct map3d.gameplay@1 localTest profile supports typed Event V2 and Scenes, Facts, presence WorldRules, existing battles and shops/healing/PC. The additional map3d.story@1 capability qualifies model interactions, inspected model clip commands, and spatial cinematics with wait, camera, actor movement, facing and marker beats. Active cinematic media, other unsupported commands, legacy scripts and 3D publication are rejected.",
      inputSchema: z
        .object({
          projectHandle: z.string().min(1),
          mode: z.enum(["publication", "localTest"]).optional(),
          outputPath: z
            .string()
            .min(1)
            .refine(isAbsolute, "outputPath must be absolute"),
        })
        .strict(),
      outputSchema: toolEnvelopeSchema,
      annotations: {
        readOnlyHint: false,
        destructiveHint: false,
        idempotentHint: false,
        openWorldHint: false,
      },
    },
    async ({ projectHandle, outputPath, mode }) =>
      authoringResult(async () => {
        if (!projectRoots) {
          throw new Error("Project-root resolution is unavailable.");
        }
        return authoring.request("game_export", {
          projectRoot: projectRoots.resolveProjectRoot(projectHandle),
          outputPath,
          ...(mode === undefined ? {} : { mode }),
        });
      }),
  );
}
