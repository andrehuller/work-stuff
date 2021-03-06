CREATE OR REPLACE FUNCTION streetbase.GEO_Student_Street(
	a_connected_id integer,
	a_geom geometry,
	OUT st_type TEXT,
	OUT st_title TEXT,
	OUT st_name TEXT,
	OUT importance DOUBLE PRECISION,
	OUT min_num INTEGER,
	OUT max_num INTEGER
)
AS $$
BEGIN
	SELECT	t.st_type, t.st_title, t.st_name,
		ST_Length(t.geom) / ST_Length(a_geom),
		t.min_num, t.max_num
	INTO	st_type, st_title, st_name,
		importance, min_num, max_num
	FROM	streetbase.tb_geo_eixos_viarios_projetados_pol_p4674 t
	WHERE	t.connected_id = a_connected_id
	AND	ST_Length(t.geom) / ST_Length(a_geom) > 0.05
	ORDER	BY ST_Length(t.geom) / ST_Length(a_geom) DESC,
		t.occurrences DESC
	LIMIT	1;
END;
$$ LANGUAGE plpgsql IMMUTABLE;
