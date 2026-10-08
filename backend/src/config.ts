import "dotenv/config";

export const config = {
  port: Number(process.env.PORT ?? 5000),
  databaseUrl: process.env.DATABASE_URL ?? "postgresql://crowned:crowned@localhost:5432/crowned_connections",
  jwtSecret: process.env.JWT_SECRET ?? "dev-only-change-me",
  jwtExpiresIn: process.env.JWT_EXPIRES_IN ?? "1d",
  corsOrigin: process.env.CORS_ORIGIN ?? "*",
  timezone: "Africa/Johannesburg"
};
