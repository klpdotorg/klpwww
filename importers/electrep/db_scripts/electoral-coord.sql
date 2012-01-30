-- Schema creation script for KLP aggregate DB
-- This DB drives the KLP website
-- Created: Thu, 10 Jun 2010 19:40:38 IST
-- (C) Shivangi Desai <shivangi@klp.org.in>

-- This code is released under the terms of the GNU GPL v3 
-- and is free software



DROP TABLE IF EXISTS "electoral_coord";
CREATE TABLE "electoral_coord" (
  "const_ward_id" integer NOT NULL,
  "const_ward_type" varchar(20) NOT NULL,
  PRIMARY KEY  ("const_ward_id")
);

--SELECT AddGeometryColumn('','electoral_coord','coord','2011','POINT',2);
SELECT AddGeometryColumn('','electoral_coord','coord','-1','POINT',2);
