import express from "express";
import { registerHealthRoutes } from "./__HEALTH_IMPORT__.js";
__CORS_IMPORT__

const app = express();
app.use(express.json());
__CORS_USE__
registerHealthRoutes(app);
const port = Number(process.env.PORT || 3000);
app.listen(port, () => console.log(`__NAME__ listening at http://localhost:${port}`));
