-- Grants required privilges to the klp user to be able to 
-- manipulate the postgis DB objects
-- Created: Thu, 10 Jun 2010 19:42:07 IST
-- (C) Alok G Singh <alok@klp.org.in>

-- This code is released under the terms of the GNU GPL v3 
-- and is free software

GRANT select,delete,insert on geometry_columns to klp;
GRANT select,delete,insert on spatial_ref_sys to klp;
