import express from "express";
import { registerHealthRoutes } from "./__HEALTH_IMPORT__.js";
__CORS_IMPORT__
__HELMET_IMPORT__
__MORGAN_IMPORT__

const app = express();
app.use(express.json());
__CORS_USE__
__HELMET_USE__
__MORGAN_USE__
registerHealthRoutes(app);
const port = Number(process.env.PORT || __SERVER_PORT__);
app.listen(port, () => console.log(`__NAME__ listening at http://localhost:${port}`));
