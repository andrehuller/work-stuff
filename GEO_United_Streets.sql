CREATE OR REPLACE FUNCTION streetbase.GEO_United_Streets(a_city_id integer)
	RETURNS VOID AS $$
DECLARE	cursor_connected CURSOR FOR
		SELECT	id1, id2
		FROM	streetbase.tb_united_streets;
	cursor_separated CURSOR FOR
		SELECT	t.id
		FROM	streetbase.tb_geo_eixos_viarios_conectados_pol_p4674 t
		WHERE	t.city_id = a_city_id
		AND	t.united_id IS NULL
		AND	NOT EXISTS    (	SELECT	1
					FROM	streetbase.tb_united_street t1
					WHERE	t1.id = t.id );
	var_group_id INTEGER := 1;
	var_group_id1 INTEGER;
	var_group_id2 INTEGER;
	var_united_id INTEGER;
BEGIN
	-- Remove os dados anteriores --
	DELETE	FROM streetbase.tb_geo_eixos_viarios_unidos_pol_p4674
	WHERE	city_id = a_city_id;

	UPDATE	streetbase.tb_geo_eixos_viarios_conectados_pol_p4674
	SET	united_id = NULL
	WHERE	city_id = a_city_id
	AND	united_id IS NOT NULL;

	DELETE	FROM streetbase.tb_united_street;
	DELETE	FROM streetbase.tb_united_streets;

	-- Constroi uma lista de adjacência para os trechos conectados --
	INSERT	INTO streetbase.tb_united_streets(id1, id2, edge, geom)
	SELECT	t1.id, t2.id, ARRAY[t1.id, t2.id], ST_Intersection(t1.geom, t2.geom)
	FROM	streetbase.tb_geo_eixos_viarios_conectados_pol_p4674 t1,
		streetbase.tb_geo_eixos_viarios_conectados_pol_p4674 t2
	WHERE	t1.city_id = a_city_id
	AND	t2.city_id = a_city_id
	AND	ST_Touches(t1.geom, t2.geom)
	AND	t1.id < t2.id --IGNORE REPEATED
	AND	t1.st_type IS NOT DISTINCT FROM t2.st_type
	AND	t1.st_title IS NOT DISTINCT FROM t2.st_title
	AND	t1.st_name IS NOT DISTINCT FROM t2.st_name
	AND	t1.alt_st_name IS NOT DISTINCT FROM t2.alt_st_name
	AND	streetbase.GEO_Angle(t1.geom, t2.geom) > radians(155) -- (180 - 25) AVOIDS RETURNS
	AND	ST_GeometryType(ST_Intersection(t1.geom, t2.geom)) = 'ST_Point'; --ST_MultiPoint IN SOME CASES

	-- Remove bifurcações --
	DELETE	FROM streetbase.tb_united_streets t
	WHERE	t.id IN       (	SELECT	t1.id
				FROM	streetbase.tb_united_streets t1,
					streetbase.tb_united_streets t2
				WHERE	ST_Equals(t1.geom, t2.geom)
				AND	t1.edge && t2.edge --A overlaps B but A does not contain B
				AND	NOT t1.edge @> t2.edge );

	-- Coloca cada trecho em um grupo --
	FOR var_record IN cursor_connected LOOP
		SELECT	group_id
		INTO	var_group_id1
		FROM	streetbase.tb_united_street
		WHERE	id = var_record.id1;

		SELECT	group_id
		INTO	var_group_id2
		FROM	streetbase.tb_united_street
		WHERE	id = var_record.id2;

		IF var_group_id1 IS NULL AND var_group_id2 IS NULL THEN
			INSERT	INTO streetbase.tb_united_street(id, group_id)
			VALUES	(var_record.id1, var_group_id),
				(var_record.id2, var_group_id);

			var_group_id := var_group_id + 1;

		ELSIF var_group_id1 IS NOT NULL AND var_group_id2 IS NOT NULL THEN
			UPDATE	streetbase.tb_united_street
			SET	group_id = var_group_id1
			WHERE	group_id = var_group_id2;

		ELSIF var_group_id1 IS NOT NULL THEN
			INSERT	INTO streetbase.tb_united_street(id, group_id)
			VALUES	(var_record.id2, var_group_id1);
		ELSE
			INSERT	INTO streetbase.tb_united_street(id, group_id)
			VALUES	(var_record.id1, var_group_id2);
		END IF;
	END LOOP;

	-- Coloca cada trecho sem conexão alguma em um grupo próprio --
	FOR var_record IN cursor_separated LOOP
		INSERT	INTO streetbase.tb_united_street(id, group_id)
		VALUES	(var_record.id, var_group_id);

		var_group_id := var_group_id + 1;
	END LOOP;

	-- Constroi o id do trecho unido a partir do grupo --
	SELECT	COALESCE(MAX(id), 0) + 1
	INTO	var_united_id
	FROM	streetbase.tb_geo_eixos_viarios_unidos_pol_p4674;

	UPDATE	streetbase.tb_geo_eixos_viarios_conectados_pol_p4674 t
	SET	united_id = var_united_id + t1.group_id
	FROM	streetbase.tb_united_street t1
	WHERE	t.id = t1.id;

	INSERT	INTO streetbase.tb_geo_eixos_viarios_unidos_pol_p4674(city_id, city, id,
		st_type, st_title, st_name, alt_st_name,
		min_num, max_num, geom)
	SELECT	city_id, city, united_id,
		st_type, st_title, st_name, alt_st_name,
		MIN(min_num), MAX(max_num), ST_LineMerge(ST_Union(geom))
	FROM	streetbase.tb_geo_eixos_viarios_conectados_pol_p4674
	WHERE	city_id = a_city_id
	AND	united_id IS NOT NULL
	GROUP	BY city_id, city, united_id,
		st_type, st_title, st_name, alt_st_name;

	DELETE	FROM streetbase.tb_united_street;
	DELETE	FROM streetbase.tb_united_streets;

	--GEO_Update_Osm_Name
	UPDATE	streetbase.tb_geo_eixos_viarios_unidos_pol_p4674
	SET	tokens = (
--		SELECT	array_agg(metaphone(CASE WHEN LENGTH(token) = 1 THEN token ELSE trim(trailing 's' from token) END, 8))
		SELECT	array_agg(CASE WHEN LENGTH(token) = 1 THEN token ELSE trim(trailing 's' from token) END)
		FROM	(SELECT regexp_split_to_table(st_name, E'\\s+') AS token) t
	)
	WHERE	city_id = a_city_id;
/*
	UPDATE	streetbase.tb_geo_eixos_viarios_unidos_pol_p4674 t1
	SET	osm_name = t.st_name
	FROM  (	SELECT	id, (streetbase.geo_street(streetbase.geo_osm_street_name(geom))).*
		FROM	streetbase.tb_geo_eixos_viarios_unidos_pol_p4674
		WHERE	city_id = a_city_id ) t
	WHERE	t1.id = t.id
	AND	t1.st_name <> t.st_name;

	UPDATE	streetbase.tb_geo_eixos_viarios_unidos_pol_p4674
	SET	osm_tokens = (
		SELECT	array_agg(metaphone(CASE WHEN LENGTH(token) = 1 THEN token ELSE trim(trailing 's' from token) END, 8))
		FROM	(SELECT regexp_split_to_table(osm_name, E'\\s+') AS token) t
	)
	WHERE	city_id = a_city_id
	AND	osm_name IS NOT NULL;
*/
	--ATUALIZA O NOME DOS TRECHOS SEPARADOS
	UPDATE	streetbase.tb_geo_eixos_viarios_separados_pol_p4674 t
	SET	st_type = t1.st_type,
		st_title = t1.st_title,
		st_name = t1.st_name,
		alt_st_name = t1.alt_st_name
	FROM	streetbase.tb_geo_eixos_viarios_unidos_pol_p4674 t1
	WHERE	t.city_id = a_city_id
	AND	ST_Contains(t1.geom, t.geom)
	AND	t.st_name IS NULL;

	--GEO_Update_Street_Reversed
	UPDATE	streetbase.tb_geo_eixos_viarios_unidos_pol_p4674
	SET	geom = ST_Reverse(geom)
	WHERE	city_id = a_city_id
	AND	streetbase.GEO_Street_Reversed(geom, st_name);

	UPDATE	streetbase.tb_geo_eixos_viarios_conectados_pol_p4674 t1
	SET	geom = ST_Reverse(t1.geom)
	FROM  (	SELECT	id, (ST_Dump(geom)).geom
		FROM	streetbase.tb_geo_eixos_viarios_unidos_pol_p4674
		WHERE	city_id = a_city_id ) t2
	WHERE	t1.united_id = t2.id
	AND	ST_Line_Locate_Point(t2.geom, ST_StartPoint(t1.geom)) > ST_Line_Locate_Point(t2.geom, ST_EndPoint(t1.geom));

	UPDATE	streetbase.tb_geo_eixos_viarios_separados_pol_p4674 t1
	SET	geom = ST_Reverse(t1.geom)
	FROM  (	SELECT	id, (ST_Dump(geom)).geom
		FROM	streetbase.tb_geo_eixos_viarios_conectados_pol_p4674
		WHERE	city_id = a_city_id ) t2
	WHERE	t1.connected_id = t2.id
	AND	ST_Line_Locate_Point(t2.geom, ST_StartPoint(t1.geom)) > ST_Line_Locate_Point(t2.geom, ST_EndPoint(t1.geom));

	--GEO_Update_Street_Numeration
	--Atualiza a numeração dos trechos separados
	WITH tb_street_number AS (
		SELECT	ts.id, 
			round(ST_LineLocatePoint(tc.geom, ST_StartPoint(ts.geom)) * (tc.max_num - tc.min_num) + tc.min_num) AS from_l,
			round(ST_LineLocatePoint(tc.geom, ST_EndPoint(ts.geom)) * (tc.max_num - tc.min_num) + tc.min_num)
				- (CASE WHEN NOT ST_Equals(ST_EndPoint(ts.geom), ST_EndPoint(tc.geom)) THEN 1 ELSE 0 END) AS to_l
		FROM	streetbase.tb_geo_eixos_viarios_conectados_pol_p4674 tc,
			streetbase.tb_geo_eixos_viarios_separados_pol_p4674 ts
		WHERE	tc.city_id = a_city_id
		AND	tc.min_num IS NOT NULL
		AND	tc.max_num IS NOT NULL
		AND	tc.min_num <> tc.max_num
		AND	ts.city_id = a_city_id --not necessary, but with it postgresql becomes wise about choosing indexes
		AND	ts.connected_id = tc.id
		AND	LEAST(ts.from_l, ts.from_r) IS NULL
		AND	GREATEST(ts.to_l, ts.to_r) IS NULL
	)
	UPDATE	streetbase.tb_geo_eixos_viarios_separados_pol_p4674 ts
	SET	from_l = st_number.from_l,
		to_l = st_number.to_l
	FROM	tb_street_number st_number
	WHERE	st_number.from_l <= st_number.to_l --in case there are less numbers than street segments.
	AND	ts.id = st_number.id;
END;
$$ LANGUAGE plpgsql VOLATILE;
