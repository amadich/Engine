import { Router } from "express";

// Mount in src/index.ts: app.use("/api/example", exampleRouter);
export const exampleRouter = Router();
exampleRouter.get("/", (_request, response) =>
  response.json({ message: "Created by Jeridi Engine" }));
