import { readFile } from "node:fs/promises";
import { z } from "zod";

import { AveluneMcpError } from "./controller.js";

const sessionSchema = z
  .object({
    apiUrl: z
      .url()
      .refine((value) => new URL(value).hostname === "127.0.0.1"),
    token: z.string().min(1),
    bundleId: z.string().min(1),
    createdAt: z.iso.datetime().optional(),
  })
  .strip();

export type AveluneControlSession = z.infer<typeof sessionSchema>;

export async function readControlSession(
  path: string,
): Promise<AveluneControlSession> {
  try {
    const source = await readFile(path, "utf8");
    return sessionSchema.parse(JSON.parse(source));
  } catch (error) {
    throw new AveluneMcpError(
      "session.unavailable",
      `The Avelune control session at ${path} is unavailable.`,
      true,
      { cause: error instanceof Error ? error.message : String(error) },
    );
  }
}
