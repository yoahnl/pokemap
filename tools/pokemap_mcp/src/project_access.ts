import { createRequire } from "node:module";
import type { PackagedRuntime } from "./packaged_runtime.js";

export interface ProjectAccessGrant {
  root: string;
  bookmark: string;
}
interface NativeProjectAccess {
  grant(root: string, bookmark: string): number;
  revokeAll(): void;
}

export function createProjectAccess(packaged?: PackagedRuntime) {
  const native =
    process.platform === "darwin" && packaged
      ? (createRequire(import.meta.url)(
          packaged.components.get("project-access-node")?.absolutePath ?? "",
        ) as NativeProjectAccess)
      : undefined;
  let grants: ProjectAccessGrant[] = [];
  return {
    replace(next: ProjectAccessGrant[]) {
      native?.revokeAll();
      grants = [];
      try {
        for (const grant of next) {
          const status = native?.grant(grant.root, grant.bookmark) ?? 0;
          if (status !== 0) throw Error(`permission.transfer_failed_${status}`);
        }
        grants = next.map((grant) => ({ ...grant }));
      } catch (error) {
        native?.revokeAll();
        throw error;
      }
    },
    environment(): Record<string, string> {
      const library = packaged?.components.get("project-access-library");
      return library
        ? {
            AVELUNE_PROJECT_ACCESS_LIBRARY: library.absolutePath,
            AVELUNE_PROJECT_ACCESS_GRANTS: JSON.stringify(grants),
            AVELUNE_OWNER_PID: String(process.pid),
          }
        : {};
    },
    close() {
      native?.revokeAll();
      grants = [];
    },
  };
}
