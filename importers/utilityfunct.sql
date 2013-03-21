CREATE OR REPLACE FUNCTION isdigit(text) RETURNS BOOLEAN AS '
select $1 ~ ''^(-)?[0-9]+$'' as result
' LANGUAGE SQL;

create or replace function getmonth(value text) returns text as $$
declare
	month integer;
	mon text;
begin	
	month:=case when isdigit(value) then cast(value as int) else 0 end;
	mon:=case when month>=1 and month<=12 then cast(to_char(to_timestamp(to_char(month, '999'), 'MM'),'Mon') as text) else null end;
	return mon;
end;$$
language plpgsql;
