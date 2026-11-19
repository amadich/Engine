import { Router } from "express";
import settings from "./settings.json" with { type: "json" };

export const statusRouter = Router();

statusRouter.get(settings.path, (request, response) => {
  response.vary("Origin");
  if (request.headers.origin === settings.allowed_origin)
    response.set("Access-Control-Allow-Origin", settings.allowed_origin);
  response.set("Cache-Control", "no-store");
  response.json({ status: "ok", service: settings.service });
});
