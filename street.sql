CREATE OR REPLACE FUNCTION streetbase.GEO_Street(a_name TEXT,
	OUT st_type text, OUT st_title text, OUT st_name text, OUT completed boolean)
AS $$
DECLARE	curs1 CURSOR FOR
	WITH split_string AS (
		SELECT *
		FROM (SELECT regexp_split_to_table(regexp_replace(lower(unaccent(trim(a_name || ' eof'))), '[\.,\,,\:,-]', ' ', 'g'), E'\\s+') AS token) t
		LEFT JOIN streetbase.tb_street_dict ON token = name OR ARRAY[token] && tokens
	)
	SELECT	token AS token,
		CASE WHEN type IS NOT NULL THEN name ELSE token END AS name,
		CASE WHEN type IS NOT NULL THEN type
			WHEN streetbase.GEO_Parse_Integer(token) IS NOT NULL THEN 'NUMERAL'
			ELSE 'NAME' END AS type,
		alt_name
	FROM	split_string;
	var_record RECORD;
	var_step INTEGER;
	st_temp text;
	st_alt_name text;
	var_actions text[];
BEGIN
--	RAISE INFO '%', a_name;

	var_step := 1;
	st_type := NULL;
	st_title := NULL;
	st_name := NULL;
	FOR var_record IN curs1 LOOP
		SELECT	next_step, actions
		INTO	var_step, var_actions
		FROM	streetbase.tb_street_step
		WHERE	step = var_step
		AND	input = var_record.type;

		IF var_actions IS NOT NULL THEN
			FOR i in 1 .. array_length(var_actions, 1) LOOP
				IF var_actions[i] = 'dump_all' THEN
					st_type := NULL;
					st_title := NULL;
					st_name := NULL;
					st_temp := NULL;
				ELSIF var_actions[i] = 'dump_type' THEN
					st_type := NULL;
				ELSIF var_actions[i] = 'dump_title' THEN
					st_title := NULL;
				ELSIF var_actions[i] = 'dump_name' THEN
					st_name := NULL;
				ELSIF var_actions[i] = 'dump_temp' THEN
					st_temp := NULL;
				ELSIF var_actions[i] = 'consume_type' THEN
					IF st_type IS NULL THEN
						st_type := var_record.name;
					ELSIF st_type NOT LIKE '%' || var_record.name || '%' THEN
						st_type := st_type || ' ' || var_record.name;
					END IF;
				ELSIF var_actions[i] = 'consume_title' THEN
					st_title := CASE WHEN st_title IS NULL THEN var_record.name ELSE st_title || ' ' || var_record.name END;
				ELSIF var_actions[i] = 'consume_name' THEN
					st_name := CASE WHEN st_name IS NULL THEN var_record.name ELSE st_name || ' ' || var_record.name END;
				ELSIF var_actions[i] = 'consume_temp' THEN
					st_temp := var_record.name;
					st_alt_name := var_record.alt_name;
				ELSIF var_actions[i] = 'consume_token' THEN
					st_name := CASE WHEN st_name IS NULL THEN var_record.token ELSE st_name || ' ' || var_record.token END;
				ELSIF var_actions[i] = 'consume_road' THEN
					st_name := st_temp || '-' || var_record.name;
					st_temp := NULL;
					st_alt_name := NULL;
				ELSIF var_actions[i] = 'switch_type_and_name' THEN
					st_name := st_type;
					st_type := NULL;
				ELSIF var_actions[i] = 'switch_title_and_name' THEN
					st_name := st_title;
					st_title := NULL;
				ELSIF var_actions[i] = 'switch_temp_and_type' THEN
					st_type := CASE WHEN st_type IS NULL THEN COALESCE(st_alt_name, st_temp)
						ELSE st_type || ' ' || COALESCE(st_alt_name, st_temp) END;
					st_temp := NULL;
					st_alt_name := NULL;
				ELSIF var_actions[i] = 'switch_temp_and_title' THEN
					st_title := CASE WHEN st_title IS NULL THEN COALESCE(st_alt_name, st_temp)
						ELSE st_title || ' ' || COALESCE(st_alt_name, st_temp) END;
					st_temp := NULL;
					st_alt_name := NULL;
				ELSIF var_actions[i] = 'switch_temp_and_name' THEN
					st_name := CASE WHEN st_name IS NULL THEN st_temp ELSE st_name || ' ' || st_temp END;
					st_temp := NULL;
					st_alt_name := NULL;
				END IF;
			END LOOP;
		END IF;
		EXIT WHEN var_step IS NULL OR var_step = 99;
	END LOOP;

	IF st_name IS NULL THEN
		st_type := NULL;
		st_title := NULL;
	END IF;

	completed := var_step IS NOT NULL AND var_step = 99;
END;
$$ LANGUAGE plpgsql IMMUTABLE;
