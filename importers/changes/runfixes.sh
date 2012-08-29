psql -U klp -d klpwww_ver2 -f fixwww.sql
echo 'Fixes on klpwww done'
psql -U klp -d klpsys -f fixsys.sql
echo 'Fixes on klpsys done'
psql -U klp -d klp-coord -f fixcoords.sql
echo 'Fixes on klpcoord done'
