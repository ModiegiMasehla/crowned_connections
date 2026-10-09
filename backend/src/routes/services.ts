import { Router } from "express";
import { pool } from "../db";
import { authenticate, requireRole } from "../auth";
import { serviceSchema } from "../validation";

export const serviceRouter = Router();

serviceRouter.get("/", async (_req,res,next)=>{
  try {
    const r=await pool.query(`SELECT id,name,description,category FROM services WHERE deleted_at IS NULL ORDER BY name`);
    res.json({services:r.rows});
  }catch(e){next(e);}
});

serviceRouter.post("/", authenticate, requireRole("SALON_OWNER"), async (req,res,next)=>{
  try{
    const input=serviceSchema.parse(req.body);
    const owner=await pool.query("SELECT id FROM salon_profiles WHERE owner_user_id=$1 AND deleted_at IS NULL LIMIT 1",[req.user!.id]);
    if(!owner.rowCount)return res.status(400).json({error:"Create your salon first"});
    const service=await pool.query(`INSERT INTO services(name,description,duration_minutes) VALUES($1,$2,$3) RETURNING id,name,description,duration_minutes`,
      [input.name,input.description??null,input.durationMinutes]);
    await pool.query(`INSERT INTO salon_services(salon_id,service_id,price_cents) VALUES($1,$2,$3)`,
      [owner.rows[0].id,service.rows[0].id,input.priceCents]);
    res.status(201).json({service:service.rows[0],priceCents:input.priceCents});
  }catch(e){next(e);}
});
