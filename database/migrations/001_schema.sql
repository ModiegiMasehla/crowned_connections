CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS btree_gist;
CREATE EXTENSION IF NOT EXISTS pgcrypto;

DO $$ BEGIN
  CREATE TYPE user_role AS ENUM ('CUSTOMER','SALON_OWNER','ADMIN');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE appointment_status AS ENUM ('PENDING','CONFIRMED','DECLINED','CANCELLED_BY_CUSTOMER','CANCELLED_BY_SALON','RESCHEDULED','COMPLETED','NO_SHOW');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE payment_status AS ENUM ('UNPAID','PENDING','PAID','REFUNDED','FAILED');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

CREATE TABLE IF NOT EXISTS users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email text NOT NULL UNIQUE,
  password_hash text NOT NULL,
  role user_role NOT NULL,
  first_name text NOT NULL,
  last_name text NOT NULL,
  phone text,
  location_consent_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

CREATE TABLE IF NOT EXISTS locations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  point geography(Point,4326) NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS locations_point_gist_idx ON locations USING gist(point);

CREATE TABLE IF NOT EXISTS salon_profiles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_user_id uuid NOT NULL REFERENCES users(id),
  location_id uuid NOT NULL REFERENCES locations(id),
  name text NOT NULL,
  description text,
  phone text NOT NULL,
  address_line text NOT NULL,
  suburb text NOT NULL,
  city text NOT NULL,
  province text NOT NULL,
  postal_code text NOT NULL,
  business_type text NOT NULL CHECK (business_type IN ('SALON','INDEPENDENT_STYLIST','BARBER','HOME_BASED','MOBILE')),
  rating_avg numeric(2,1) NOT NULL DEFAULT 0,
  rating_count int NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);
CREATE INDEX IF NOT EXISTS salon_owner_idx ON salon_profiles(owner_user_id);

CREATE TABLE IF NOT EXISTS services (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text,
  category text NOT NULL DEFAULT 'HAIR',
  duration_minutes int NOT NULL CHECK (duration_minutes BETWEEN 15 AND 480),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);
CREATE INDEX IF NOT EXISTS services_name_idx ON services(lower(name));

CREATE TABLE IF NOT EXISTS salon_services (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  salon_id uuid NOT NULL REFERENCES salon_profiles(id),
  service_id uuid NOT NULL REFERENCES services(id),
  price_cents int NOT NULL CHECK (price_cents >= 0),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  UNIQUE(salon_id,service_id)
);

CREATE TABLE IF NOT EXISTS hairstyles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL UNIQUE,
  category text NOT NULL DEFAULT 'HAIR',
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS salon_staff (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  salon_id uuid NOT NULL REFERENCES salon_profiles(id),
  display_name text NOT NULL,
  timezone text NOT NULL DEFAULT 'Africa/Johannesburg',
  active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS availability (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  stylist_id uuid NOT NULL REFERENCES salon_staff(id),
  weekday int NOT NULL CHECK (weekday BETWEEN 1 AND 7),
  start_local time NOT NULL,
  end_local time NOT NULL,
  active boolean NOT NULL DEFAULT true,
  CHECK (start_local < end_local),
  UNIQUE(stylist_id,weekday,start_local,end_local)
);

CREATE TABLE IF NOT EXISTS blocked_dates (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  salon_id uuid NOT NULL REFERENCES salon_profiles(id),
  blocked_date date NOT NULL,
  reason text,
  UNIQUE(salon_id,blocked_date)
);

CREATE TABLE IF NOT EXISTS appointments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_user_id uuid NOT NULL REFERENCES users(id),
  salon_id uuid NOT NULL REFERENCES salon_profiles(id),
  service_id uuid NOT NULL REFERENCES services(id),
  stylist_id uuid NOT NULL REFERENCES salon_staff(id),
  start_time timestamptz NOT NULL,
  end_time timestamptz NOT NULL,
  status appointment_status NOT NULL DEFAULT 'PENDING',
  amount_cents int NOT NULL DEFAULT 0,
  payment_status payment_status NOT NULL DEFAULT 'UNPAID',
  payment_method text,
  deposit_amount_cents int NOT NULL DEFAULT 0,
  transaction_reference text,
  notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CHECK (end_time > start_time)
);
CREATE INDEX IF NOT EXISTS appointments_customer_idx ON appointments(customer_user_id,start_time);
CREATE INDEX IF NOT EXISTS appointments_salon_idx ON appointments(salon_id,start_time);
CREATE INDEX IF NOT EXISTS appointments_stylist_idx ON appointments(stylist_id,start_time);

ALTER TABLE appointments DROP CONSTRAINT IF EXISTS appointments_stylist_no_overlap;
ALTER TABLE appointments ADD CONSTRAINT appointments_stylist_no_overlap
  EXCLUDE USING gist (
    stylist_id WITH =,
    tstzrange(start_time,end_time,'[)') WITH &&
  )
  WHERE (status IN ('PENDING','CONFIRMED','RESCHEDULED'));

CREATE TABLE IF NOT EXISTS appointment_status_history (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  appointment_id uuid NOT NULL REFERENCES appointments(id),
  old_status appointment_status,
  new_status appointment_status NOT NULL,
  changed_by uuid REFERENCES users(id),
  created_at timestamptz NOT NULL DEFAULT now()
);

-- V1 privacy/audit foundation.
CREATE TABLE IF NOT EXISTS privacy_consents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id),
  consent_type text NOT NULL,
  version text NOT NULL,
  granted_at timestamptz NOT NULL DEFAULT now(),
  withdrawn_at timestamptz
);

-- Future phase tables are intentionally not implemented in V1:
-- messages, reviews, notifications, favourites, reports, admin web.
-- They can be added through later migrations.
