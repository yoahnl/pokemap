export const MCP_SERVER_NAME = "pokemap-authoring";
export const MCP_SERVER_VERSION = "0.1.0";

export const PREFERRED_PROTOCOL_VERSION = "2026-07-28";
export const FALLBACK_PROTOCOL_VERSION = "2025-11-25";
export const SUPPORTED_PROTOCOL_VERSIONS = [
  PREFERRED_PROTOCOL_VERSION,
  FALLBACK_PROTOCOL_VERSION,
] as const;

export const MCP_COMPATIBILITY = {
  sdk: {
    server: "@modelcontextprotocol/server@2.0.0",
    client: "@modelcontextprotocol/client@2.0.0",
    core: "@modelcontextprotocol/core@2.0.0",
  },
  node: ">=20",
  transports: {
    selected: ["stdio"],
    deferred: ["streamable-http"],
  },
  protocol: {
    preferred: PREFERRED_PROTOCOL_VERSION,
    fallback: FALLBACK_PROTOCOL_VERSION,
    supported: SUPPORTED_PROTOCOL_VERSIONS,
  },
  jobs: {
    mode: "pokemap_job",
    reason:
      "The official TypeScript v2 server exposes no stable 2026-07-28 Tasks extension registration API.",
  },
} as const;

export type McpCompatibility = typeof MCP_COMPATIBILITY;
