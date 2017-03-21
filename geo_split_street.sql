CREATE OR REPLACE FUNCTION streetbase.GEO_Split_Street(a_geom geometry)
	RETURNS TABLE (split_geom geometry)
AS $$
DECLARE	points geometry[];
	a_indexes integer[] := '{}';
	line1 geometry; line2 geometry;
	sum double precision;
	i integer; a integer; b integer;
BEGIN
	SELECT	array_agg(geom)
	INTO	points
	FROM 	(SELECT	(ST_DumpPoints(a_geom)).*) t;

	sum := 0;
	FOR i in 1 .. array_length(points, 1) - 2 LOOP
		line1 := ST_MakeLine(points[i], points[i + 1]);
		line2 := ST_MakeLine(points[i + 1], points[i + 2]);

		sum := sum + (radians(180) - streetbase.GEO_Angle(line1, line2));

		IF sum > radians(45) THEN
			a_indexes := array_append(a_indexes, i + 1);
			sum := 0;
		END IF;
	END LOOP;

	IF array_length(a_indexes, 1) IS NOT NULL THEN --ARRAY IS NOT EMPTY
		a := 1;
		b := a_indexes[1];
		split_geom := ST_MakeLine(points[a:b]);
		RETURN NEXT;

		FOR i IN 1 .. array_length(a_indexes, 1) - 1 LOOP
			a := a_indexes[i];
			b := a_indexes[i + 1];
			split_geom := ST_MakeLine(points[a:b]);
			RETURN NEXT;
		END LOOP;

		a := a_indexes[array_length(a_indexes, 1)];
		b := array_length(points, 1);
		split_geom := ST_MakeLine(points[a:b]);
		RETURN NEXT;
	ELSE
		a := 1;
		b := array_length(points, 1);
		split_geom := ST_MakeLine(points[a:b]);
		RETURN NEXT;
	END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;
