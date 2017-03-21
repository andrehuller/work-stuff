CREATE OR REPLACE FUNCTION streetbase.GEO_Angle(g1 GEOMETRY, g2 GEOMETRY)
	RETURNS DOUBLE PRECISION AS $$
DECLARE	line1 GEOMETRY;
	line2 GEOMETRY;
	a1 DOUBLE PRECISION;
	a2 DOUBLE PRECISION;
BEGIN
	g1 := ST_LineMerge(g1);
	g2 := ST_LineMerge(g2);
	IF ST_Touches(ST_StartPoint(g1), g2) THEN
		line1 := (SELECT ST_MakeLine(geom) FROM (SELECT (ST_DumpPoints(g1)).* ORDER BY path ASC LIMIT 2) t);
	ELSE
		line1 := (SELECT ST_MakeLine(geom) FROM (SELECT (ST_DumpPoints(g1)).* ORDER BY path DESC LIMIT 2) t);
	END IF;

	IF ST_Touches(ST_StartPoint(g2), g1) THEN
		line2 := (SELECT ST_MakeLine(geom) FROM (SELECT (ST_DumpPoints(g2)).* ORDER BY path ASC LIMIT 2) t);
	ELSE
		line2 := (SELECT ST_MakeLine(geom) FROM (SELECT (ST_DumpPoints(g2)).* ORDER BY path DESC LIMIT 2) t);
	END IF;

	IF ST_Equals(ST_EndPoint(line1), ST_EndPoint(line2)) THEN
		line2 := ST_Reverse(line2);
	ELSIF ST_Equals(ST_StartPoint(line1), ST_StartPoint(line2)) THEN
		line1 := ST_Reverse(line1);
	ELSIF ST_Equals(ST_StartPoint(line1), ST_EndPoint(line2)) THEN
		line1 := ST_Reverse(line1);
		line2 := ST_Reverse(line2);
	END IF;

	a1 := ST_Azimuth(ST_StartPoint(line1), ST_EndPoint(line1));
	a2 := ST_Azimuth(ST_StartPoint(line2), ST_EndPoint(line2));

	RETURN abs(radians(180) - abs(a1 - a2));
END;
$$ LANGUAGE plpgsql IMMUTABLE;
