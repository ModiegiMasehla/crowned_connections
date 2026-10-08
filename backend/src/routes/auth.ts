import { Router } from "express";
import { pool } from "../db";
import { hashPassword, comparePassword, signToken, authenticate } from "../auth";
import { loginSchema, registerSchema } from "../validation";

export const authRouter = Router();

authRouter.post("/register", async (req, res, next) => {
  try {
    const input = registerSchema.parse(req.body);
    const exists = await pool.query("SELECT 1 FROM users WHERE lower(email)=lower($1)", [input.email]);
    if (exists.rowCount) return res.status(409).json({ error: "Email already registered" });
    const hash = await hashPassword(input.password);
    const result = await pool.query(
      `INSERT INTO users (email,password_hash,role,first_name,last_name,phone,location_consent_at)
       VALUES ($1,$2,$3,$4,$5,$6,CASE WHEN $7 THEN now() ELSE NULL END)
       RETURNING id,email,role,first_name,last_name,phone`,
      [input.email, hash, input.role, input.firstName, input.lastName, input.phone ?? null, false]
    );
    const user = result.rows[0];
    const token = signToken({ id: user.id, email: user.email, role: user.role });
    res.status(201).json({ user, token });
  } catch (e) { next(e); }
});

authRouter.post("/login", async (req, res, next) => {
  try {
    const input = loginSchema.parse(req.body);
    const result = await pool.query("SELECT * FROM users WHERE lower(email)=lower($1) AND deleted_at IS NULL", [input.email]);
    const user = result.rows[0];
    if (!user || !(await comparePassword(input.password, user.password_hash))) return res.status(401).json({ error: "Invalid email or password" });
    const token = signToken({ id: user.id, email: user.email, role: user.role });
    res.json({ token, user: { id: user.id, email: user.email, role: user.role, firstName: user.first_name, lastName: user.last_name } });
  } catch (e) { next(e); }
});

authRouter.get("/me", authenticate, async (req, res, next) => {
  try {
    const result = await pool.query("SELECT id,email,role,first_name,last_name,phone FROM users WHERE id=$1 AND deleted_at IS NULL", [req.user!.id]);
    if (!result.rowCount) return res.status(404).json({ error: "User not found" });
    res.json({ user: result.rows[0] });
  } catch (e) { next(e); }
});

authRouter.delete("/me", authenticate, async (req, res, next) => {
  try {
    await pool.query("UPDATE users SET deleted_at=now() WHERE id=$1", [req.user!.id]);
    res.status(204).send();
  } catch (e) { next(e); }
});
