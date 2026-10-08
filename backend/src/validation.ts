import { z } from "zod";

export const registerSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
  role: z.enum(["CUSTOMER", "SALON_OWNER"]).default("CUSTOMER"),
  firstName: z.string().min(1).max(80),
  lastName: z.string().min(1).max(80),
  phone: z.string().max(30).optional()
});

export const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(1)
});

export const salonSchema = z.object({
  name: z.string().min(2).max(160),
  description: z.string().max(2000).optional(),
  phone: z.string().max(30),
  addressLine: z.string().min(2).max(250),
  suburb: z.string().max(100),
  city: z.string().min(2).max(100),
  province: z.string().min(2).max(100),
  postalCode: z.string().max(20),
  latitude: z.number().gte(-90).lte(90),
  longitude: z.number().gte(-180).lte(180),
  businessType: z.enum(["SALON", "INDEPENDENT_STYLIST", "BARBER", "HOME_BASED", "MOBILE"]).default("SALON")
});

export const serviceSchema = z.object({
  name: z.string().min(2).max(160),
  description: z.string().max(1000).optional(),
  durationMinutes: z.number().int().min(15).max(480),
  priceCents: z.number().int().min(0)
});

export const searchSchema = z.object({
  q: z.string().max(120).optional(),
  lat: z.coerce.number().gte(-90).lte(90).optional(),
  lng: z.coerce.number().gte(-180).lte(180).optional(),
  radiusKm: z.coerce.number().min(1).max(100).default(10),
  minPriceCents: z.coerce.number().int().min(0).optional(),
  maxPriceCents: z.coerce.number().int().min(0).optional(),
  minRating: z.coerce.number().min(0).max(5).optional()
});

export const appointmentSchema = z.object({
  salonId: z.string().uuid(),
  serviceId: z.string().uuid(),
  stylistId: z.string().uuid().optional(),
  startTime: z.string().datetime({ offset: true })
});
