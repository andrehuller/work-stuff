CREATE OR REPLACE FUNCTION streetbase.GEO_Angle_Between_Extremities(g1 GEOMETRY, g2 GEOMETRY)
	RETURNS DOUBLE PRECISION AS $$
DECLARE	line1 GEOMETRY;
	line2 GEOMETRY;
	a1 DOUBLE PRECISION;
	a2 DOUBLE PRECISION;
BEGIN
	IF ST_Touches(ST_StartPoint(g1), g2) THEN
		line1 := ( SELECT ST_MakeLine(geom) FROM ( SELECT (ST_DumpPoints(g1)).* ORDER BY path DESC LIMIT 2 ) t );
	ELSE
		line1 := ( SELECT ST_MakeLine(geom) FROM ( SELECT (ST_DumpPoints(g1)).* ORDER BY path ASC LIMIT 2 ) t );
	END IF;

	IF ST_Touches(ST_StartPoint(g2), g1) THEN
		line2 := ( SELECT ST_MakeLine(geom) FROM ( SELECT (ST_DumpPoints(g2)).* ORDER BY path DESC LIMIT 2 ) t );
	ELSE
		line2 := ( SELECT ST_MakeLine(geom) FROM ( SELECT (ST_DumpPoints(g2)).* ORDER BY path ASC LIMIT 2 ) t );
	END IF;

	a1 :=	CASE WHEN ST_X(ST_StartPoint(line1)) < ST_X(ST_EndPoint(line1))
		THEN ST_Azimuth(ST_StartPoint(line1), ST_EndPoint(line1))
		ELSE ST_Azimuth(ST_EndPoint(line1), ST_StartPoint(line1))
		END;

	a2 :=	CASE WHEN ST_X(ST_StartPoint(line2)) < ST_X(ST_EndPoint(line2))
		THEN ST_Azimuth(ST_StartPoint(line2), ST_EndPoint(line2))
		ELSE ST_Azimuth(ST_EndPoint(line2), ST_StartPoint(line2))
		END;

	RETURN CASE WHEN a1 > a2 THEN a1 - a2 ELSE a2 - a1 END;
END;
$$ LANGUAGE plpgsql IMMUTABLE;
