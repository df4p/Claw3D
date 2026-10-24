const { spawn } = require("node:child_process");
const path = require("node:path");

console.log("[entrypoint] Starting Claw3D services...");

// Check if Hermes adapter should run
// If HERMES_API_URL is configured, auto-start Hermes adapter
if (process.env.HERMES_API_URL) {
  console.log(`[entrypoint] HERMES_API_URL is set (${process.env.HERMES_API_URL}), starting Hermes adapter...`);
  const adapterProcess = spawn("node", ["server/hermes-gateway-adapter.js"], {
    stdio: "inherit",
    env: {
      ...process.env,
      HERMES_ADAPTER_PORT: process.env.HERMES_ADAPTER_PORT || "18789",
    },
  });

  adapterProcess.on("exit", (code, signal) => {
    console.warn(`[entrypoint] Hermes adapter exited with code ${code} (signal ${signal})`);
  });
}

// Start Main Next.js custom server
const mainServer = spawn("node", ["server/index.js"], {
  stdio: "inherit",
  env: process.env,
});

mainServer.on("exit", (code, signal) => {
  console.log(`[entrypoint] Main server exited with code ${code} (signal ${signal})`);
  process.exit(code || 0);
});

// Handle graceful shutdown
const shutdown = (signal) => {
  console.log(`[entrypoint] Received ${signal}, shutting down...`);
  mainServer.kill(signal);
  process.exit(0);
};

process.on("SIGINT", () => shutdown("SIGINT"));
process.on("SIGTERM", () => shutdown("SIGTERM"));
