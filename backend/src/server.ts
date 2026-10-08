import express from "express";
import cors from "cors";
import rateLimit from "express-rate-limit";
import { config } from "./config";
import { authRouter } from "./routes/auth";
import { salonRouter } from "./routes/salons";
import { serviceRouter } from "./routes/services";
import { searchRouter } from "./routes/search";
import { availabilityRouter } from "./routes/availability";
import { appointmentRouter } from "./routes/appointments";

const app = express();
app.use(cors({ origin: config.corsOrigin === "*" ? true : config.corsOrigin }));
app.use(express.json({ limit: "1mb" }));
app.use(rateLimit({ windowMs: 60_000, limit: 120, standardHeaders: true, legacyHeaders: false }));

app.get("/health", (_req, res) => res.json({ status: "ok", service: "crowned-connections-api" }));
app.get("/api/docs", (_req, res) => res.json({
  name: "Crowned Connections API",
  version: "1.0.0",
  endpoints: [
    "POST /api/auth/register", "POST /api/auth/login", "GET /api/auth/me",
    "GET /api/salons", "GET /api/salons/:id", "POST /api/salons", "PUT /api/salons/:id",
    "GET /api/services", "POST /api/services",
    "GET /api/search",
    "GET /api/availability",
    "GET /api/appointments", "POST /api/appointments", "POST /api/appointments/:id/decision"
  ]
}));

app.use("/api/auth", authRouter);
app.use("/api/salons", salonRouter);
app.use("/api/services", serviceRouter);
app.use("/api/search", searchRouter);
app.use("/api/availability", availabilityRouter);
app.use("/api/appointments", appointmentRouter);

app.use((err: any, _req: express.Request, res: express.Response, _next: express.NextFunction) => {
  console.error(err);
  res.status(500).json({ error: "Internal server error" });
});

app.listen(config.port, () => console.log(`Crowned Connections API listening on :${config.port}`));
