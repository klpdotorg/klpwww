DROP TABLE IF EXISTS "tb_libinfra" cascade;
CREATE TABLE "tb_libinfra" (
  "sid" integer NOT NULL,
  "libstatus" varchar(300) NOT NULL,
  "handoveryear" integer,
  "libtype" varchar(300),
  "numbooks" integer,
  "numracks" integer,
  "numtables" integer,
  "numchairs" integer,
  "numcomputers" integer,
  "numups" integer,
  PRIMARY KEY  ("sid")
);
