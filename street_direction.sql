----------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION streetbase.GEO_Street_Direction(geom geometry)
	RETURNS integer AS $$
DECLARE dx integer; dy integer;
BEGIN
	IF ST_X(ST_StartPoint(geom)) > ST_X(ST_EndPoint(geom)) THEN
		dx := 1;
	ELSIF ST_X(ST_StartPoint(geom)) < ST_X(ST_EndPoint(geom)) THEN
		dx := -1;
	ELSE
		dx := 0;
	END IF;

	IF ST_Y(ST_StartPoint(geom)) > ST_Y(ST_EndPoint(geom)) THEN
		dy := 1;
	ELSIF ST_Y(ST_StartPoint(geom)) < ST_Y(ST_EndPoint(geom)) THEN
		dy := -1;
	ELSE
		dy := 0;
	END IF;

	IF dx = -1 AND dy = 1 THEN
		RETURN 0;
	ELSIF dx = 0 AND dy = 1 THEN
		RETURN 1;
	ELSIF dx = 1 AND dy = 1 THEN
		RETURN 2;
	ELSIF dx = -1 AND dy = 0 THEN
		RETURN 3;
	ELSIF dx = 0 AND dy = 0 THEN
		RETURN 4;
	ELSIF dx = 1 AND dy = 0 THEN
		RETURN 5;
	ELSIF dx = -1 AND dy = -1 THEN
		RETURN 6;
	ELSIF dx = 0 AND dy = -1 THEN
		RETURN 7;
	ELSIF dx = 1 AND dy = -1 THEN
		RETURN 8;
	END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;
----------------------------------------------------------------------------------------------------
