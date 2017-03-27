CREATE OR REPLACE FUNCTION streetbase.GEO_Connect_Streets(a_city_id INTEGER)
	RETURNS VOID AS $$
DECLARE	cursor_connected CURSOR FOR
		SELECT	id1, id2
		FROM	streetbase.tb_connected_streets;
	cursor_separated CURSOR FOR
		SELECT	id
		FROM	streetbase.tb_geo_eixos_viarios_separados_pol_p4674
		WHERE	city_id = a_city_id
		AND	connected_id IS NULL;
	var_group_id INTEGER := 1;
	var_group_id1 INTEGER;
	var_group_id2 INTEGER;
	var_connected_id INTEGER;
BEGIN
	DELETE	FROM streetbase.tb_geo_eixos_viarios_conectados_pol_p4674
	WHERE	city_id = a_city_id;

	UPDATE	streetbase.tb_geo_eixos_viarios_separados_pol_p4674
	SET	connected_id = NULL
	WHERE	city_id = a_city_id
	AND	connected_id IS NOT NULL;

	DELETE	FROM streetbase.tb_connected_street;

	DELETE	FROM streetbase.tb_connected_streets;

	--INSERE NA LISTA DE ADJACÊNCIA
	INSERT	INTO streetbase.tb_connected_streets(id1, id2, edge, geom)
	SELECT	t1.id, t2.id, ARRAY[t1.id, t2.id], ST_Intersection(t1.geom, t2.geom)
	FROM	streetbase.tb_geo_eixos_viarios_separados_pol_p4674 t1,
		streetbase.tb_geo_eixos_viarios_separados_pol_p4674 t2
	WHERE	t1.city_id = a_city_id
	AND	t2.city_id = a_city_id
	AND	ST_Touches(t1.geom, t2.geom)
	AND	t1.id < t2.id --IGNORE REPEATED
	AND	t1.st_type IS NOT DISTINCT FROM t2.st_type
	AND	t1.st_title IS NOT DISTINCT FROM t2.st_title
	AND	t1.st_name IS NOT DISTINCT FROM t2.st_name
	AND	t1.alt_st_name IS NOT DISTINCT FROM t2.alt_st_name
	AND	t1.zip_code IS NOT DISTINCT FROM t2.zip_code
	AND	t1.oneway IS NOT DISTINCT FROM t2.oneway
	AND	streetbase.GEO_Angle(t1.geom, t2.geom) > radians(155) -- (180 - 25) AVOIDS RETURNS
	AND	ST_GeometryType(ST_Intersection(t1.geom, t2.geom)) = 'ST_Point'; --ST_MultiPoint IN SOME CASES

	--REMOVE BIFURCAÇÕES
	DELETE	FROM streetbase.tb_connected_streets t
	WHERE	t.id IN       (	SELECT	t1.id
				FROM	streetbase.tb_connected_streets t1,
					streetbase.tb_connected_streets t2
				WHERE	ST_Equals(t1.geom, t2.geom)
				AND	t1.edge && t2.edge --A OVERLAPS B BUT A DOES NOT CONTAIN B
				AND	NOT t1.edge @> t2.edge );

	FOR var_record IN cursor_connected LOOP
		SELECT	group_id
		INTO	var_group_id1
		FROM	streetbase.tb_connected_street
		WHERE	id = var_record.id1;

		SELECT	group_id
		INTO	var_group_id2
		FROM	streetbase.tb_connected_street
		WHERE	id = var_record.id2;

		IF var_group_id1 IS NULL AND var_group_id2 IS NULL THEN
			INSERT	INTO streetbase.tb_connected_street(id, group_id)
			VALUES	(var_record.id1, var_group_id),
				(var_record.id2, var_group_id);

			var_group_id := var_group_id + 1;

		ELSIF var_group_id1 IS NOT NULL AND var_group_id2 IS NOT NULL THEN
			UPDATE	streetbase.tb_connected_street
			SET	group_id = var_group_id1
			WHERE	group_id = var_group_id2;

		ELSIF var_group_id1 IS NOT NULL THEN
			INSERT	INTO streetbase.tb_connected_street(id, group_id)
			VALUES	(var_record.id2, var_group_id1);

		ELSE --var_group_id2 IS NOT NULL THEN
			INSERT	INTO streetbase.tb_connected_street(id, group_id)
			VALUES	(var_record.id1, var_group_id2);
		END IF;
	END LOOP;

	SELECT	COALESCE(MAX(id), 0) + 1
	INTO	var_connected_id
	FROM	streetbase.tb_geo_eixos_viarios_conectados_pol_p4674;

	UPDATE	streetbase.tb_geo_eixos_viarios_separados_pol_p4674 t
	SET	connected_id = var_connected_id + t1.group_id
	FROM	streetbase.tb_connected_street t1
	WHERE	t.id = t1.id;

	INSERT	INTO streetbase.tb_geo_eixos_viarios_conectados_pol_p4674(city_id, city, id,
		zip_code, st_type, st_title, st_name,
		oneway,
		min_num, max_num, geom)
	SELECT	city_id, city, connected_id,
		zip_code, st_type, st_title, st_name,
		oneway,
		MIN(LEAST(from_l, to_l, from_r, to_r)),
		MAX(GREATEST(from_l, to_l, from_r, to_r)),
		ST_LineMerge(ST_Union(geom))
	FROM	streetbase.tb_geo_eixos_viarios_separados_pol_p4674
	WHERE	city_id = a_city_id
	AND	connected_id IS NOT NULL
	GROUP	BY city_id, city, connected_id,
		zip_code, st_type, st_title, st_name,
		oneway;

	SELECT	COALESCE(MAX(id), 0) + 1
	INTO	var_connected_id
	FROM	streetbase.tb_geo_eixos_viarios_conectados_pol_p4674;

	FOR var_record IN cursor_separated LOOP
		INSERT	INTO streetbase.tb_geo_eixos_viarios_conectados_pol_p4674(city_id, city, id,
			zip_code, st_type, st_title, st_name,
			oneway,
			min_num, max_num, geom)
		SELECT	city_id, city, var_connected_id,
			zip_code, st_type, st_title, st_name,
			oneway,
			LEAST(from_l, to_l, from_r, to_r),
			GREATEST(from_l, to_l, from_r, to_r),
			geom
		FROM	streetbase.tb_geo_eixos_viarios_separados_pol_p4674
		WHERE	id = var_record.id;

		var_connected_id := var_connected_id + 1;
	END LOOP;

	DELETE	FROM streetbase.tb_connected_street;

	DELETE	FROM streetbase.tb_connected_streets;

	UPDATE	streetbase.tb_geo_eixos_viarios_conectados_pol_p4674 t1
	SET	st_type = t.st_type,
		st_title = t.st_title,
		st_name = t.st_name
	FROM  (	SELECT	id, (streetbase.geo_street(streetbase.geo_osm_street_name(geom))).*
		FROM	streetbase.tb_geo_eixos_viarios_conectados_pol_p4674
		WHERE	city_id = a_city_id
		AND	st_name IS NULL ) t
--		AND	NOT streetbase.GEO_Unnamed_Street(st_name) ) t
	WHERE	t1.id = t.id
	AND	t.st_name IS NOT NULL;

	--ATUALIZA O NOME DAS RUAS COM NOMES PROVISÓRIOS
	UPDATE	streetbase.tb_geo_eixos_viarios_conectados_pol_p4674 t1
	SET	alt_st_name = t1.st_name,
		st_type = t.st_type,
		st_title = t.st_title,
		st_name = t.st_name
	FROM  (	SELECT	id, (streetbase.geo_street(streetbase.geo_osm_street_name(geom))).*
		FROM	streetbase.tb_geo_eixos_viarios_conectados_pol_p4674
		WHERE	city_id = a_city_id
		AND	streetbase.GEO_Unnamed_Street(st_name) ) t
	WHERE	t1.id = t.id
	AND	t.st_name IS NOT NULL -- street found in openstreetmap has no name
	AND	NOT streetbase.GEO_Unnamed_Street(t.st_name); --street found is a provisory name
END;
$$ LANGUAGE plpgsql VOLATILE;
