import { McpServer } from "@modelcontextprotocol/server";
import { z } from "zod";

import {
  MCP_COMPATIBILITY,
  MCP_SERVER_NAME,
  MCP_SERVER_VERSION,
  SUPPORTED_PROTOCOL_VERSIONS,
} from "./protocol.js";

const probeOutputSchema = z.object({
  server: z.literal(MCP_SERVER_NAME),
  preferredProtocol: z.string(),
  fallbackProtocol: z.string(),
  selectedTransports: z.array(z.string()),
  jobMode: z.literal("pokemap_job"),
});

export function createCompatibilityServer(): McpServer {
  const server = new McpServer(
    {
      name: MCP_SERVER_NAME,
      version: MCP_SERVER_VERSION,
    },
    {
      supportedProtocolVersions: [...SUPPORTED_PROTOCOL_VERSIONS],
      instructions:
        "PokeMap exposes project authoring contracts. Use only declared tools and resource URIs; arbitrary filesystem access is forbidden.",
    },
  );

  server.registerTool(
    "pokemap_protocol_probe",
    {
      title: "Inspect PokeMap MCP compatibility",
      description:
        "Returns the protocol, transport, and asynchronous job policy selected for this server.",
      inputSchema: z.object({}).strict(),
      outputSchema: probeOutputSchema,
      annotations: {
        readOnlyHint: true,
        destructiveHint: false,
        idempotentHint: true,
        openWorldHint: false,
      },
    },
    async () => {
      const output = {
        server: MCP_SERVER_NAME,
        preferredProtocol: MCP_COMPATIBILITY.protocol.preferred,
        fallbackProtocol: MCP_COMPATIBILITY.protocol.fallback,
        selectedTransports: [...MCP_COMPATIBILITY.transports.selected],
        jobMode: MCP_COMPATIBILITY.jobs.mode,
      } as const;

      return {
        content: [{ type: "text", text: JSON.stringify(output) }],
        structuredContent: output,
      };
    },
  );

  server.registerResource(
    "pokemap-compatibility",
    "pokemap://compatibility",
    {
      title: "PokeMap MCP compatibility",
      description: "Pinned SDK, protocol, transport, and job fallback policy.",
      mimeType: "application/json",
    },
    async (uri) => ({
      contents: [
        {
          uri: uri.href,
          mimeType: "application/json",
          text: JSON.stringify(MCP_COMPATIBILITY),
        },
      ],
    }),
  );

  return server;
}
