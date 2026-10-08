import fs from "fs";
import path from "path";
import { pool } from "./db";

async function main() {
  const migrationDir = path.resolve(__dirname, "../../database/migrations");
  const files = fs.readdirSync(migrationDir).filter(f => f.endsWith(".sql")).sort();
  for (const file of files) {
    await pool.query(fs.readFileSync(path.join(migrationDir, file), "utf8"));
  }
  console.log(`Applied ${files.length} SQL migration file(s).`);
  const seedPath = path.resolve(__dirname, "../../database/seed/seed.sql");
  if (fs.existsSync(seedPath)) {
    const marker = await pool.query("SELECT to_regclass('public.seed_marker') AS table_name");
    if (!marker.rows[0].table_name) {
      await pool.query(fs.readFileSync(seedPath, "utf8"));
      console.log("Seed data loaded.");
    }
  }
  await pool.end();
}

main().catch(async e => {
  console.error(e);
  await pool.end();
  process.exit(1);
});
