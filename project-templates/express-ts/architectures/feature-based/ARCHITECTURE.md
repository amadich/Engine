# __NAME__ architecture

Layout: feature-based.

HTTP and WebSocket packages are suggested under `src/features`. Wire their exported functions in `src/index.ts` so the entry point controls the HTTP server lifecycle.
