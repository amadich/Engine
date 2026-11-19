# __NAME__ architecture

Layout: layered.

HTTP and WebSocket packages are suggested under `src/integrations`. Wire their exported functions in `src/index.ts` so the entry point controls the HTTP server lifecycle.
