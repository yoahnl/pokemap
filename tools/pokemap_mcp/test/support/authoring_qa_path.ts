import { homedir, tmpdir } from "node:os";
import { join } from "node:path";

export function authoringQaPath(relativePath: string): string {
  const fallback = process.platform === "darwin"
    ? join(homedir(), "Library", "Caches", "AveluneQA")
    : join(tmpdir(), "AveluneQA");
  return join(process.env.AVELUNE_QA_ROOT ?? fallback, relativePath);
}
