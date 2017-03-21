CREATE OR REPLACE FUNCTION streetbase.GEO_Create_Student_Streets(a_city_id INTEGER)
RETURNS VOID AS $$
DECLARE	radius_of_buffer double precision;
BEGIN
	radius_of_buffer := streetbase.GEO_Radius_Of_Buffer();

	DELETE	FROM streetbase.tb_geo_referencia_pto_p4674
	WHERE	city_id = a_city_id;

	DELETE	FROM streetbase.tb_geo_eixos_viarios_projetados_pol_p4674
	WHERE	city_id = a_city_id;

	INSERT	INTO streetbase.tb_geo_referencia_pto_p4674(city_id, st_id,
		st_type, st_title, st_name,
		min_num, max_num, geom, occurrences)
	WITH	tb_points AS (
			SELECT	t.city_id, t.id AS st_id,
				ST_ClosestPoint(t.geom, a.geom) AS geom,
				a.endereco,
				MIN(streetbase.GEO_Parse_Integer(a.num)) AS min_num,
				MAX(streetbase.GEO_Parse_Integer(a.num)) AS max_num,
				COUNT(*) AS occurrences
			FROM	streetbase.tb_geo_eixos_viarios_conectados_pol_p4674 t,
				streetbase.tb_geo_aluno_pto_p4674 a
			WHERE	t.city_id = a_city_id
			AND	(t.st_name IS NULL OR t.min_num IS NULL
				OR streetbase.GEO_Unnamed_Street(t.st_name)) -- RUAS SEM NOME OU SEM NUMERAÇÃO
		--	AND	ST_GeometryType(t.geom) = 'ST_LineString' -- ??
			AND	ST_DWithin(t.geom, a.geom, streetbase.GEO_Radius_Of_Buffer())
			GROUP	BY t.city_id, t.id, t.geom, a.geom, a.endereco ),
		tb_names AS (
			SELECT	endereco, (streetbase.geo_street(endereco)).*
			FROM	tb_points
			GROUP	BY endereco )
	SELECT	city_id, st_id,
		st_type, st_title, st_name,
		min_num, max_num, geom,
		occurrences
	FROM	tb_points t1,
		tb_names t2
	WHERE	t1.endereco = t2.endereco
	AND	t2.st_name IS NOT NULL;

	INSERT	INTO streetbase.tb_geo_eixos_viarios_projetados_pol_p4674(city_id, st_id,
		st_type, st_title, st_name,
		min_num, max_num, geom, occurrences)
	SELECT	city_id, st_id,
		st_type, st_title, st_name,
		min_num, max_num, geom, occurrences
	FROM  (	SELECT	r.city_id, r.st_id,
			r.st_type, r.st_title, r.st_name,
			MIN(r.min_num) AS min_num,
			MAX(r.max_num) AS max_num,
			ST_LineSubstring(t.geom,
				MIN(ST_Line_Locate_Point(t.geom, r.geom)),
				MAX(ST_Line_Locate_Point(t.geom, r.geom))) AS geom,
			SUM(occurrences) AS occurrences
		FROM	streetbase.tb_geo_referencia_pto_p4674 r,
			streetbase.tb_geo_eixos_viarios_conectados_pol_p4674 t
		WHERE	r.city_id = a_city_id
		AND	t.id = r.st_id
		AND	ST_GeometryType(t.geom) = 'ST_LineString' --NOT INTERESTED IN ST_MultiLineString
		GROUP	BY r.city_id, r.st_id,
			r.st_type, r.st_title, r.st_name,
			t.geom ) t
	WHERE	ST_GeometryType(geom) = 'ST_LineString'; --NOT INTERESTED IN ST_Point

	--GEO_Update_Street_Name(a_city_id)

	-- obtém o nome e a numeração da rua a partir dos alunos
	-- atualiza as ruas sem nome ou com nome provisório
	UPDATE	streetbase.tb_geo_eixos_viarios_conectados_pol_p4674 t
	SET	st_type = s.st_type,
		st_title = s.st_title,
		st_name = s.st_name,
		alt_st_name = CASE WHEN streetbase.GEO_Unnamed_Street(t.st_name) THEN t.st_name ELSE NULL END,
		importance = s.importance,
		min_num = s.min_num,
		max_num = s.max_num
	FROM  (	SELECT	t.id, (streetbase.GEO_Student_Street(t.id, t.geom)).*
		FROM  (	SELECT	id, geom
			FROM	streetbase.tb_geo_eixos_viarios_conectados_pol_p4674
			WHERE	city_id = a_city_id
			AND	(st_name IS NULL OR streetbase.GEO_Unnamed_Street(st_name)) ) t ) s
	WHERE	t.id = s.id
	AND	s.st_name IS NOT NULL;

	-- obtém a numeração da rua a partir dos alunos (p/ os trechos do open street map)
	UPDATE	streetbase.tb_geo_eixos_viarios_conectados_pol_p4674 t1
	SET	min_num = t.min_num,
		max_num = t.max_num
	FROM  (	SELECT	id, (streetbase.GEO_Student_Street(id, geom)).*
		FROM	streetbase.tb_geo_eixos_viarios_conectados_pol_p4674
		WHERE	city_id = a_city_id
		AND	st_name IS NOT NULL
		AND	min_num IS NULL
		AND	max_num IS NULL ) t
	WHERE	t1.id = t.id
	AND	t.st_name IS NOT NULL;
END;
$$ LANGUAGE plpgsql VOLATILE;
