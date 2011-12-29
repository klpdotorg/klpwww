-- Schema creation script for KLP aggregate DB
-- This DB drives the KLP website
-- Created: Thu, 10 Jun 2010 19:40:38 IST
-- (C) Shivangi Desai <shivangi@klp.org.in>

-- This code is released under the terms of the GNU GPL v3 
-- and is free software


DROP TABLE IF EXISTS "inst_coord";
CREATE TABLE "inst_coord" (
  "instid" integer NOT NULL,
  PRIMARY KEY  ("instid")
);

SELECT AddGeometryColumn('','inst_coord','coord','-1','POINT',2);

DROP TABLE IF EXISTS "boundary_coord";
CREATE TABLE "boundary_coord" (
  "id_bndry" integer NOT NULL,
  "type" varchar(20) NOT NULL,
  PRIMARY KEY  ("id_bndry")
);

SELECT AddGeometryColumn('','boundary_coord','coord','4326','POINT',2);
