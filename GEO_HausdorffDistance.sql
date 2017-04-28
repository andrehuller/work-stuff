CREATE OR REPLACE FUNCTION streetbase.GEO_HausdorffDistance(g1 geometry, g2 geometry)
	RETURNS double precision AS $$
DECLARE	l_g1_s2 double precision; l_g2_s1 double precision;
	l_g1_e2 double precision; l_g2_e1 double precision;
	
	min_g1_g2 double precision; min_g2_g1 double precision;
	max_g1_g2 double precision; max_g2_g1 double precision;
	
	line1 geometry; line2 geometry;
BEGIN
	l_g1_s2 := ST_Line_Locate_Point(g1, ST_ClosestPoint(g1, ST_StartPoint(g2)));
	l_g1_e2 := ST_Line_Locate_Point(g1, ST_ClosestPoint(g1, ST_EndPoint(g2)));

	l_g2_s1 := ST_Line_Locate_Point(g2, ST_ClosestPoint(g2, ST_StartPoint(g1)));
	l_g2_e1 := ST_Line_Locate_Point(g2, ST_ClosestPoint(g2, ST_EndPoint(g1)));

	min_g1_g2 := LEAST(l_g1_s2, l_g1_e2);
	max_g1_g2 := GREATEST(l_g1_s2, l_g1_e2);

	min_g2_g1 := LEAST(l_g2_s1, l_g2_e1);
	max_g2_g1 := GREATEST(l_g2_s1, l_g2_e1);

	line1 := ST_LineSubstring(g1, min_g1_g2, max_g1_g2);
	line2 := ST_LineSubstring(g2, min_g2_g1, max_g2_g1);

	RETURN ST_HausdorffDistance(line1, line2);
END;
$$ LANGUAGE plpgsql IMMUTABLE;
