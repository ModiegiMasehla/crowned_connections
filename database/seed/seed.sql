CREATE EXTENSION IF NOT EXISTS pgcrypto;

INSERT INTO users(id,email,password_hash,role,first_name,last_name,phone)
VALUES
('00000000-0000-0000-0000-000000000001','customer@example.com',crypt('Password123!',gen_salt('bf',12)),'CUSTOMER','Test','Customer','0710000001'),
('00000000-0000-0000-0000-000000000002','owner@example.com',crypt('Password123!',gen_salt('bf',12)),'SALON_OWNER','Test','Owner','0710000002')
ON CONFLICT(email) DO NOTHING;

-- Pretoria/Johannesburg-area development data plus additional South African cities.
INSERT INTO locations(id,point)
VALUES
('10000000-0000-0000-0000-000000000001',ST_SetSRID(ST_MakePoint(28.2293,-25.7479),4326)::geography),
('10000000-0000-0000-0000-000000000002',ST_SetSRID(ST_MakePoint(28.1881,-25.8600),4326)::geography),
('10000000-0000-0000-0000-000000000003',ST_SetSRID(ST_MakePoint(28.1480,-25.9890),4326)::geography),
('10000000-0000-0000-0000-000000000004',ST_SetSRID(ST_MakePoint(28.0473,-26.2041),4326)::geography),
('10000000-0000-0000-0000-000000000005',ST_SetSRID(ST_MakePoint(28.0120,-26.2485),4326)::geography),
('10000000-0000-0000-0000-000000000006',ST_SetSRID(ST_MakePoint(28.1123,-26.1630),4326)::geography),
('10000000-0000-0000-0000-000000000007',ST_SetSRID(ST_MakePoint(18.4241,-33.9249),4326)::geography),
('10000000-0000-0000-0000-000000000008',ST_SetSRID(ST_MakePoint(18.5060,-33.9360),4326)::geography),
('10000000-0000-0000-0000-000000000009',ST_SetSRID(ST_MakePoint(31.0218,-29.8587),4326)::geography),
('10000000-0000-0000-0000-000000000010',ST_SetSRID(ST_MakePoint(31.0300,-29.8500),4326)::geography)
ON CONFLICT(id) DO NOTHING;

INSERT INTO salon_profiles(id,owner_user_id,location_id,name,description,phone,address_line,suburb,city,province,postal_code,business_type,rating_avg,rating_count)
SELECT '20000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000002','10000000-0000-0000-0000-000000000001','Crowned Beauty Studio','Braids, natural hair and protective styles.','0120000001','1 Example Street','Arcadia','Pretoria','Gauteng','0001','SALON',4.8,126
WHERE NOT EXISTS(SELECT 1 FROM salon_profiles WHERE id='20000000-0000-0000-0000-000000000001');

INSERT INTO salon_profiles(owner_user_id,location_id,name,description,phone,address_line,suburb,city,province,postal_code,business_type,rating_avg,rating_count)
SELECT '00000000-0000-0000-0000-000000000002','10000000-0000-0000-0000-000000000002','Glow Braids Midrand','Protective styles and wigs.','0110000002','2 Example Road','Halfway House','Midrand','Gauteng','1685','INDEPENDENT_STYLIST',4.6,82
WHERE NOT EXISTS(SELECT 1 FROM salon_profiles WHERE name='Glow Braids Midrand');

INSERT INTO salon_profiles(owner_user_id,location_id,name,description,phone,address_line,suburb,city,province,postal_code,business_type,rating_avg,rating_count)
SELECT '00000000-0000-0000-0000-000000000002','10000000-0000-0000-0000-000000000003','Natural Crown Centurion','Natural hair and silk press specialists.','0120000003','3 Example Avenue','Centurion Central','Centurion','Gauteng','0046','SALON',4.7,95
WHERE NOT EXISTS(SELECT 1 FROM salon_profiles WHERE name='Natural Crown Centurion');

INSERT INTO salon_profiles(owner_user_id,location_id,name,description,phone,address_line,suburb,city,province,postal_code,business_type,rating_avg,rating_count)
SELECT '00000000-0000-0000-0000-000000000002','10000000-0000-0000-0000-000000000004','Urban Crown JHB','Modern hair and barber services.','0110000004','4 Example Street','Braamfontein','Johannesburg','Gauteng','2001','SALON',4.5,61
WHERE NOT EXISTS(SELECT 1 FROM salon_profiles WHERE name='Urban Crown JHB');

INSERT INTO salon_profiles(owner_user_id,location_id,name,description,phone,address_line,suburb,city,province,postal_code,business_type,rating_avg,rating_count)
SELECT '00000000-0000-0000-0000-000000000002','10000000-0000-0000-0000-000000000005','Soweto Style House','Community salon with braids and kids styles.','0110000005','5 Example Lane','Orlando','Soweto','Gauteng','1804','SALON',4.4,48
WHERE NOT EXISTS(SELECT 1 FROM salon_profiles WHERE name='Soweto Style House');

INSERT INTO salon_profiles(owner_user_id,location_id,name,description,phone,address_line,suburb,city,province,postal_code,business_type,rating_avg,rating_count)
SELECT '00000000-0000-0000-0000-000000000002','10000000-0000-0000-0000-000000000006','Braids & Beyond','Braids and twists.','0110000006','6 Example Road','Rosebank','Johannesburg','Gauteng','2196','SALON',4.3,39
WHERE NOT EXISTS(SELECT 1 FROM salon_profiles WHERE name='Braids & Beyond');

INSERT INTO salon_profiles(owner_user_id,location_id,name,description,phone,address_line,suburb,city,province,postal_code,business_type,rating_avg,rating_count)
SELECT '00000000-0000-0000-0000-000000000002','10000000-0000-0000-0000-000000000007','Cape Crown Studio','Cape Town hair studio.','0210000007','7 Example Street','City Bowl','Cape Town','Western Cape','8001','SALON',4.9,201
WHERE NOT EXISTS(SELECT 1 FROM salon_profiles WHERE name='Cape Crown Studio');

INSERT INTO salon_profiles(owner_user_id,location_id,name,description,phone,address_line,suburb,city,province,postal_code,business_type,rating_avg,rating_count)
SELECT '00000000-0000-0000-0000-000000000002','10000000-0000-0000-0000-000000000008','Boho Beauty Cape Town','Boho braids and installs.','0210000008','8 Example Road','Woodstock','Cape Town','Western Cape','7915','INDEPENDENT_STYLIST',4.6,73
WHERE NOT EXISTS(SELECT 1 FROM salon_profiles WHERE name='Boho Beauty Cape Town');

INSERT INTO salon_profiles(owner_user_id,location_id,name,description,phone,address_line,suburb,city,province,postal_code,business_type,rating_avg,rating_count)
SELECT '00000000-0000-0000-0000-000000000002','10000000-0000-0000-0000-000000000009','Durban Crown Collective','Protective styles and bridal hair.','0310000009','9 Example Street','Berea','Durban','KwaZulu-Natal','4001','SALON',4.8,143
WHERE NOT EXISTS(SELECT 1 FROM salon_profiles WHERE name='Durban Crown Collective');

INSERT INTO salon_profiles(owner_user_id,location_id,name,description,phone,address_line,suburb,city,province,postal_code,business_type,rating_avg,rating_count)
SELECT '00000000-0000-0000-0000-000000000002','10000000-0000-0000-0000-000000000010','KZN Hair Lab','Haircuts and natural styles.','0310000010','10 Example Road','Morningside','Durban','KwaZulu-Natal','4001','SALON',4.2,34
WHERE NOT EXISTS(SELECT 1 FROM salon_profiles WHERE name='KZN Hair Lab');

INSERT INTO services(name,description,category,duration_minutes)
VALUES
('Knotless Braids','Protective knotless braid style','HAIR',180),
('Box Braids','Classic box braids','HAIR',180),
('Boho Braids','Boho-inspired braids','HAIR',210),
('Cornrows','Traditional cornrow styling','HAIR',120),
('Fulani Braids','Fulani-inspired braids','HAIR',210),
('Passion Twists','Protective passion twists','HAIR',180),
('Wig Installation','Professional wig installation','HAIR',90),
('Silk Press','Natural hair silk press','HAIR',120),
('Natural Hair Styling','Wash, treatment and styling','HAIR',120),
('Hair Colour','Professional colouring service','HAIR',150),
('Barber Cut','Classic haircut','BARBER',60),
('Kids Hairstyle','Child-friendly protective styling','HAIR',120),
('Bridal Hairstyle','Event and bridal styling','HAIR',150),
('Updo','Formal updo styling','HAIR',90),
('Ponytail','Sleek ponytail styling','HAIR',90),
('Faux Locs','Protective faux loc installation','HAIR',240),
('Dreadlock Styling','Loc maintenance and styling','HAIR',120),
('Relaxer','Professional relaxer service','HAIR',120),
('Wash and Blow','Wash and blow dry','HAIR',60),
('Wig Styling','Wig cut and styling','HAIR',90),
('Passion Twist Touch-up','Touch-up service','HAIR',90),
('Bridal Trial','Bridal hairstyle trial','HAIR',90)
ON CONFLICT DO NOTHING;

INSERT INTO hairstyles(name,category)
SELECT name,category FROM services ON CONFLICT(name) DO NOTHING;

INSERT INTO salon_staff(salon_id,display_name)
SELECT id,'Lead Stylist' FROM salon_profiles WHERE NOT EXISTS(SELECT 1 FROM salon_staff ss WHERE ss.salon_id=salon_profiles.id);

INSERT INTO availability(stylist_id,weekday,start_local,end_local)
SELECT id,wd,'08:00','17:00' FROM salon_staff CROSS JOIN generate_series(1,6) wd
ON CONFLICT DO NOTHING;

INSERT INTO salon_services(salon_id,service_id,price_cents)
SELECT s.id,sv.id,
 CASE sv.name
 WHEN 'Knotless Braids' THEN 65000
 WHEN 'Box Braids' THEN 55000
 WHEN 'Boho Braids' THEN 75000
 WHEN 'Cornrows' THEN 40000
 WHEN 'Fulani Braids' THEN 70000
 WHEN 'Passion Twists' THEN 65000
 WHEN 'Wig Installation' THEN 45000
 WHEN 'Silk Press' THEN 30000
 WHEN 'Natural Hair Styling' THEN 35000
 WHEN 'Hair Colour' THEN 80000
 WHEN 'Barber Cut' THEN 18000
 WHEN 'Kids Hairstyle' THEN 30000
 WHEN 'Bridal Hairstyle' THEN 90000
 WHEN 'Updo' THEN 50000
 WHEN 'Ponytail' THEN 40000
 WHEN 'Faux Locs' THEN 90000
 WHEN 'Dreadlock Styling' THEN 45000
 WHEN 'Relaxer' THEN 35000
 WHEN 'Wash and Blow' THEN 25000
 WHEN 'Wig Styling' THEN 30000
 WHEN 'Passion Twist Touch-up' THEN 25000
 ELSE 60000 END
FROM salon_profiles s CROSS JOIN services sv
ON CONFLICT(salon_id,service_id) DO NOTHING;

--INSERT INTO seed_marker(id) VALUES(1) ON CONFLICT(id) DO NOTHING;
