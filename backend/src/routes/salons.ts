import { Router } from "express";
import { pool } from "../db";
import { authenticate, requireRole } from "../auth";
import { salonSchema } from "../validation";

export const salonRouter = Router();

salonRouter.get("/", async (_req, res, next) => {
  try {
    const result = await pool.query(`
      SELECT s.id,s.name,s.description,s.phone,s.address_line,s.suburb,s.city,s.province,s.postal_code,
             s.business_type, s.rating_avg, s.rating_count,
             ST_Y(l.point::geometry) AS latitude, ST_X(l.point::geometry) AS longitude
      FROM salon_profiles s JOIN locations l ON l.id=s.location_id
      WHERE s.deleted_at IS NULL ORDER BY s.name
    `);
    res.json({ salons: result.rows });
  } catch(e) { next(e); }
});

salonRouter.get("/:id", async (req,res,next) => {
  try {
    const salon = await pool.query(`
      SELECT s.id,s.name,s.description,s.phone,s.address_line,s.suburb,s.city,s.province,s.postal_code,
             s.business_type,s.rating_avg,s.rating_count,
             ST_Y(l.point::geometry) AS latitude, ST_X(l.point::geometry) AS longitude
      FROM salon_profiles s JOIN locations l ON l.id=s.location_id
      WHERE s.id=$1 AND s.deleted_at IS NULL`, [req.params.id]);
    if (!salon.rowCount) return res.status(404).json({error:"Salon not found"});
    const services = await pool.query(`
      SELECT ss.id,sv.name,sv.description,sv.duration_minutes,ss.price_cents
      FROM salon_services ss JOIN services sv ON sv.id=ss.service_id
      WHERE ss.salon_id=$1 AND ss.deleted_at IS NULL AND sv.deleted_at IS NULL
      ORDER BY sv.name`, [req.params.id]);
    const staff = await pool.query(`SELECT id,display_name FROM salon_staff WHERE salon_id=$1 AND active=true ORDER BY display_name`, [req.params.id]);
    res.json({ salon: salon.rows[0], services: services.rows, staff: staff.rows });
  } catch(e){next(e);}
});

salonRouter.post("/", authenticate, requireRole("SALON_OWNER"), async (req,res,next)=>{
  try {
    const input=salonSchema.parse(req.body);
    const result=await pool.query(`
      WITH loc AS (
        INSERT INTO locations(point) VALUES (ST_SetSRID(ST_MakePoint($1,$2),4326)::geography)
        RETURNING id
      )
      INSERT INTO salon_profiles(owner_user_id,name,description,phone,address_line,suburb,city,province,postal_code,business_type,location_id)
      SELECT $3,$4,$5,$6,$7,$8,$9,$10,$11,$12,id FROM loc
      RETURNING id,name`,
      [input.longitude,input.latitude,req.user!.id,input.name,input.description??null,input.phone,input.addressLine,input.suburb,input.city,input.province,input.postalCode,input.businessType]);
    res.status(201).json({salon:result.rows[0]});
  }catch(e){next(e);}
});

salonRouter.put("/:id", authenticate, requireRole("SALON_OWNER"), async (req,res,next)=>{
  try{
    const input=salonSchema.parse(req.body);
    const result=await pool.query(`
      UPDATE salon_profiles s SET name=$1,description=$2,phone=$3,address_line=$4,suburb=$5,city=$6,province=$7,postal_code=$8,business_type=$9,updated_at=now()
      WHERE id=$10 AND owner_user_id=$11 RETURNING id,name`,
      [input.name,input.description??null,input.phone,input.addressLine,input.suburb,input.city,input.province,input.postalCode,input.businessType,req.params.id,req.user!.id]);
    if(!result.rowCount)return res.status(404).json({error:"Salon not found or not owned by you"});
    await pool.query(`UPDATE locations SET point=ST_SetSRID(ST_MakePoint($1,$2),4326)::geography,updated_at=now()
      WHERE id=(SELECT location_id FROM salon_profiles WHERE id=$3)`,[input.longitude,input.latitude,req.params.id]);
    res.json({salon:result.rows[0]});
  }catch(e){next(e);}
});
