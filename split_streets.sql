CREATE OR REPLACE FUNCTION streetbase.GEO_Split_Streets(a_city_id INTEGER)
	RETURNS VOID AS	$$
BEGIN
	DELETE	FROM streetbase.tb_geo_eixos_viarios_separados_pol_p4674
	WHERE	city_id = a_city_id;

	IF EXISTS     (	SELECT	1
			FROM	streetbase.tb_geo_street_pol_p4674_a2016_v4
			WHERE	city_id = a_city_id::TEXT )
	THEN
		INSERT	INTO streetbase.tb_geo_eixos_viarios_separados_pol_p4674(city_id, city, geom,
			oneway, max_speed, avg_speed)
		SELECT	city_id::INTEGER, city, streetbase.GEO_Split_Street(ST_Simplify(geom, 0.000044965)),
			oneway, max_speed, avg_speed
		FROM	streetbase.tb_geo_street_pol_p4674_a2016_v4
		WHERE	city_id = a_city_id::TEXT
		AND	st_no = 'Sem Nome';

		--INSERE OS TRECHOS COM NOME
		INSERT	INTO streetbase.tb_geo_eixos_viarios_separados_pol_p4674(city_id, city, geom,
			st_type, st_title, st_name,
			from_l, to_l, from_r, to_r,
			zip_code, oneway, max_speed, avg_speed)
		SELECT	city_id::INTEGER, city, ST_Simplify(geom, 0.000044965),
			st_type, st_title, st_name,
			LEAST(from_l, to_l), GREATEST(from_l, to_l),
			LEAST(from_r, to_r), GREATEST(from_r, to_r),
			zip_code, oneway, max_speed, avg_speed
		FROM  (	SELECT	city_id, city, geom,
				(streetbase.geo_street(COALESCE(st_type, '') || ' ' || COALESCE(st_no, ''))).*,
				streetbase.GEO_Parse_Integer(from_l) AS "from_l",
				streetbase.GEO_Parse_Integer(to_l) AS "to_l",
				streetbase.GEO_Parse_Integer(from_r) AS "from_r",
				streetbase.GEO_Parse_Integer(to_r) AS "to_r",
				zip_l::INTEGER AS "zip_code",
				oneway, max_speed, avg_speed
			FROM	streetbase.tb_geo_street_pol_p4674_a2016_v4
			WHERE	city_id = a_city_id::TEXT
			AND	st_no <> 'Sem Nome' ) t;
	ELSE
		INSERT	INTO streetbase.tb_geo_eixos_viarios_separados_pol_p4674(city_id, city, geom,
			oneway, max_speed, avg_speed)
		SELECT	city_id::INTEGER, city, streetbase.GEO_Split_Street(ST_Simplify(geom, 0.000044965)),
			oneway, max_speed, avg_speed
		FROM	streetbase.tb_geo_street_pol_p4674_a2015_v4
		WHERE	city_id = a_city_id::TEXT
		AND	st_no = 'Sem Nome';

		INSERT	INTO streetbase.tb_geo_eixos_viarios_separados_pol_p4674(city_id, city, geom,
			st_type, st_title, st_name,
			from_l, to_l, from_r, to_r,
			zip_code, oneway, max_speed, avg_speed)
		SELECT	city_id::INTEGER, city, ST_Simplify(geom, 0.000044965),
			st_type, st_title, st_name,
			LEAST(from_l, to_l), GREATEST(from_l, to_l),
			LEAST(from_r, to_r), GREATEST(from_r, to_r),
			zip_code, oneway, max_speed, avg_speed
		FROM  (	SELECT	city_id, city, geom,
				(streetbase.geo_street(COALESCE(st_type, '') || ' ' || COALESCE(st_no, ''))).*,
				streetbase.GEO_Parse_Integer(from_l) AS "from_l",
				streetbase.GEO_Parse_Integer(to_l) AS "to_l",
				streetbase.GEO_Parse_Integer(from_r) AS "from_r",
				streetbase.GEO_Parse_Integer(to_r) AS "to_r",
				zip_l::INTEGER AS "zip_code",
				oneway, max_speed, avg_speed
			FROM	streetbase.tb_geo_street_pol_p4674_a2015_v4
			WHERE	city_id = a_city_id::TEXT
			AND	st_no <> 'Sem Nome' ) t;
	END IF;

	--REMOVE CEP QUE NÃO É LOGRADOURO
	UPDATE	streetbase.tb_geo_eixos_viarios_separados_pol_p4674
	SET	zip_code = NULL
	WHERE	zip_code IN   (	SELECT	cep::INTEGER
				FROM	streetbase.tb_localidade
				WHERE	uf = 'PR'
				AND	tipo_localidade = 'M'
				AND	cep IS NOT NULL );
END;
$$ LANGUAGE plpgsql VOLATILE;
