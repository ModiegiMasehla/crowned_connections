import { Router } from "express";
import { pool } from "../db";
import { searchSchema } from "../validation";

export const searchRouter = Router();

searchRouter.get("/", async (req,res,next)=>{
  try{
    const input=searchSchema.parse(req.query);
    const hasLocation=input.lat !== undefined && input.lng !== undefined;
    if(!hasLocation && (input.lat !== undefined || input.lng !== undefined))
      return res.status(400).json({error:"lat and lng must be supplied together"});
    const q=input.q?.trim() || null;
    const params:any[]=[q,input.minPriceCents??null,input.maxPriceCents??null,input.minRating??null];
    let idx=5;
    let distanceSelect="NULL::double precision AS distance_km";
    let distanceWhere="";
    let distanceOrder="";
    if(hasLocation){
      params.push(input.lng,input.lat,input.radiusKm*1000);
      distanceSelect=`ST_Distance(l.point,ST_SetSRID(ST_MakePoint($${idx},$${idx+1}),4326)::geography)/1000 AS distance_km`;
      distanceWhere=`AND ST_DWithin(l.point,ST_SetSRID(ST_MakePoint($${idx},$${idx+1}),4326)::geography,$${idx+2})`;
      distanceOrder="distance_km ASC,";
      idx+=3;
    }
    const sql=`
      SELECT DISTINCT ON (s.id)
        s.id,s.name,s.description,s.city,s.province,s.suburb,s.business_type,s.rating_avg,s.rating_count,
        ss.id AS salon_service_id,sv.id AS service_id,sv.name AS service_name,ss.price_cents,sv.duration_minutes,
        ${distanceSelect},
        CASE WHEN $1::text IS NULL THEN 0 ELSE
          ts_rank(to_tsvector('simple',coalesce(s.name,'')||' '||coalesce(s.description,'')), plainto_tsquery('simple',$1))
          + ts_rank(to_tsvector('simple',coalesce(sv.name,'')), plainto_tsquery('simple',$1))
        END AS relevance
      FROM salon_profiles s
      JOIN locations l ON l.id=s.location_id
      JOIN salon_services ss ON ss.salon_id=s.id AND ss.deleted_at IS NULL
      JOIN services sv ON sv.id=ss.service_id AND sv.deleted_at IS NULL
      WHERE s.deleted_at IS NULL
        AND ($1::text IS NULL OR to_tsvector('simple',coalesce(s.name,'')||' '||coalesce(s.description,'')) @@ plainto_tsquery('simple',$1)
             OR to_tsvector('simple',coalesce(sv.name,'')) @@ plainto_tsquery('simple',$1)
             OR lower(sv.name) LIKE lower('%'||$1||'%'))
        AND ($2::int IS NULL OR ss.price_cents >= $2)
        AND ($3::int IS NULL OR ss.price_cents <= $3)
        AND ($4::numeric IS NULL OR s.rating_avg >= $4)
        ${distanceWhere}
      ORDER BY s.id, relevance DESC, ss.price_cents ASC
    `;
    const wrapped=`SELECT * FROM (${sql}) x ORDER BY relevance DESC, ${distanceOrder} rating_avg DESC NULLS LAST, name LIMIT 100`;
    const r=await pool.query(wrapped,params);
    res.json({results:r.rows});
  }catch(e){next(e);}
});
