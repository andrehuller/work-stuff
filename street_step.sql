DELETE FROM streetbase.tb_street_step;

INSERT	INTO streetbase.tb_street_step (step, input, next_step, actions)
VALUES	-- 1 - <BEGINNING>
	(1, 'TYPE', 10, '{consume_type}'),
	(1, 'TYPE-QUALIFIER', 10, '{consume_type}'), --perimetral tancredo neves
	(1, 'TITLE', 20, '{consume_title}'),
	(1, 'TITLE-QUALIFIER', 20, '{consume_title}'), --rua vice pref luiz de oliveira
	(1, 'QUALIFIER', 50, '{consume_temp}'), --industrial FIXME
	(1, 'NAME', 30, '{consume_name}'),
	(1, 'NUMERAL', 30, '{consume_name}'), --10 de maio
	(1, 'LOCATION', 40, '{consume_type}'),
	(1, 'PREPOSITION', 1, NULL), --dos anturios
	(1, 'COMPLEMENT', 99, NULL), --quadra dois lote dez
	(1, 'EOF', 99, NULL),
	(1, 'ROAD,TITLE', 80, '{consume_temp}'),

	-- 10 - <TYPE>
	(10, 'TYPE', 10, '{consume_type}'), --rua travessa zumbi
	(10, 'TYPE-QUALIFIER', 1050 , '{consume_temp}'), --estrada principal
	(10, 'TITLE', 20, '{consume_title}'),
	(10, 'TITLE-QUALIFIER', 20, '{consume_title}'), --rua vice prefeito luiz de oliveira
	(10, 'QUALIFIER', 1050, '{consume_temp}'), --av industrial
	(10, 'NAME', 30, '{consume_name}'),
	(10, 'NUMERAL', 30, '{consume_name}'), --rua tres
	(10, 'LOCATION', 30, '{consume_name}'),
	(10, 'PREPOSITION', 1060, '{consume_temp}'), --ignore
	(10, 'COMPLEMENT', 99, '{dump_type}'), --rua quadra 1 lote 4
	(10, 'EOF', 99, '{dump_type}'),
	(10, 'ROAD,TITLE', 1080, '{consume_temp}'),

	-- 1050 - <TYPE> <QUALIFIER>
	(1050, 'TYPE', 10, '{switch_temp_and_type,consume_type}'), --rua marginal estrada
	(1050, 'TYPE-QUALIFIER', 99, NULL), --rua projetada final da av parana
	(1050, 'TITLE', 30, '{consume_token}'), --rua projetada n
	(1050, 'QUALIFIER', 99, NULL),--rua projetada industrial
	(1050, 'NAME', 30, '{switch_temp_and_type,consume_name}'), --rua projetada b
	(1050, 'NUMERAL', 30, '{switch_temp_and_type,consume_name}'),
	(1050, 'LOCATION', 30, '{switch_temp_and_type,consume_name}'), --estrada principal campina diamante
	(1050, 'PREPOSITION', 30, '{switch_temp_and_type}'), --estrada principal do boi perdido
	(1050, 'COMPLEMENT', 99, NULL),
	(1050, 'EOF', 99, '{switch_temp_and_name}'),
	(1050, 'ROAD,TITLE', 1080, '{switch_temp_and_type,consume_temp}'), --via marginal pr 180

	-- 1060 <TYPE> <PREPOSITION>
	(1060, 'TYPE', 30, '{consume_name}'), --rua de acesso
	(1060, 'TYPE-QUALIFIER', 10, '{consume_type}'), --rua de pedestre ...
	(1060, 'TITLE', 1060, '{consume_name}'), --rua do farmaceutico
	(1060, 'QUALIFIER', 30, '{consume_name}'), --rua do industrial
	(1060, 'NAME', 30, '{consume_name}'), --avenida das araucarias
	(1060, 'NUMERAL', 99, '{switch_temp_and_name}'), --rua a 5, rua e 12
	(1060, 'LOCATION', 30, '{consume_name}'), --rua da divisa
	(1060, 'PREPOSITION', 30, '{switch_temp_and_name}'), --rua para de minas
	(1060, 'COMPLEMENT', 99, '{switch_temp_and_name}'), --FIXME: rua a q silva
	(1060, 'EOF', 99, '{switch_temp_and_name}'),
	(1060, 'ROAD,TITLE', 1080, '{consume_temp}'),

	-- 1080 <TYPE> <ROAD,TITLE>
	(1080, 'TYPE', 1080, NULL), --br rodovia 476 km 340
	(1080, 'TITLE', 20, '{switch_temp_and_title,consume_title}'),
	(1080, 'QUALIFIER', 1080, '{consume_type}'), --rod pr estadual
	(1080, 'NAME', 30, '{switch_temp_and_title,consume_name}'),
	(1080, 'NUMERAL', 99, '{consume_road}'),
	(1080, 'LOCATION', 20, '{switch_temp_and_title,consume_title}'), -- rua br rio branco
	(1080, 'PREPOSITION', 30, '{switch_temp_and_title}'), --rua br de santo angelo
	(1080, 'COMPLEMENT', 99, NULL), --rodovia br km 277
	(1080, 'EOF', 99, '{dump_type}'),
	(1080, 'ROAD,TITLE', 1080, '{consume_temp}'), --rod br br 116

	-- 20 <TITLE>
	(20, 'TYPE', 30, '{consume_token}'), --pst r prodoskimski
	(20, 'TYPE-QUALIFIER', 1050, '{dump_title,consume_type}'), --rua dr projetada c
	(20, 'TITLE', 20, '{consume_title}'), --nossa senhora do carmo
	(20, 'TITLE-QUALIFIER', 30, '{consume_name}'), --rua dr agricola fonseca FIXME
	(20, 'QUALIFIER', 20, '{consume_title}'),
	(20, 'NAME', 30, '{consume_name}'),
	(20, 'NUMERAL', 30, '{consume_name}'),
	(20, 'LOCATION', 30, '{consume_name}'), --rua beira rio
	(20, 'PREPOSITION', 2060, '{consume_temp}'), --ignore
	(20, 'COMPLEMENT', 99, NULL), --fazenda nossa senhora km
	(20, 'EOF', 99, '{switch_title_and_name}'), --cardeal {pop_title,push_name}
	(20, 'ROAD,TITLE', 20, NULL), --rua gal br carlos c de menezes

	-- 2060 <TITLE> <PREPOSITION>
	(2060, 'TYPE', 20, '{switch_temp_and_name,consume_token}'), --rua ver a r oliveira
	(2060, 'TITLE', 20, '{consume_title}'), --br de santo angelo
	(2060, 'NAME', 30, '{consume_name}'), --duque de caxias
	(2060, 'NUMERAL', 30, '{consume_name}'), --rua serra dos tres rios
	(2060, 'LOCATION', 30, '{consume_name}'),
	(2060, 'PREPOSITION', 30, '{switch_temp_and_name,consume_name}'), --rua eng a e nadolny
	(2060, 'COMPLEMENT', 99, NULL), --rua d ao lado
	(2060, 'EOF', 99, NULL), --av n senhora dos
	
	-- 30 <NAME>
	(30, 'TYPE', 30, '{consume_token}'), --rua maria r de miranda, rua ernestina duque estrada, 
	(30, 'TYPE-QUALIFIER', 30, '{consume_name}'),
	(30, 'TITLE', 30, '{consume_token}'), --espirito santo, prof marieta s silva
	(30, 'TITLE-QUALIFIER', 30, '{consume_name}'), --patio da estacao ferroviaria
	(30, 'QUALIFIER', 30, '{consume_name}'), --enxovia velha
	(30, 'NAME', 30, '{consume_name}'),
	(30, 'NUMERAL', 30, '{consume_token}'),
	(30, 'LOCATION', 30, '{consume_name}'), --cesar ladeira
	(30, 'PREPOSITION', 30, NULL),
	(30, 'COMPLEMENT', 3070, '{consume_temp}'), --FIXME
	(30, 'EOF', 99, NULL),
	(30, 'ROAD,TITLE', 30, '{consume_name}'), -- rod umuarama mariluz pr 482 FIXME

	-- 3070 <NAME> <COMPLEMENT>
	(3070, 'TYPE', 99, NULL), --rua universitaria esquina rua volochen
	(3070, 'TYPE-QUALIFIER', 99, NULL), --rua gualachos esquina marginal oeste
	(3070, 'TITLE', 99, NULL), --rua cerejeiras esquina com ...
	(3070, 'NAME', 30, '{switch_temp_and_name,consume_name}'),
	(3070, 'NUMERAL', 99, NULL),
	(3070, 'LOCATION', 99, NULL), --cohapar proximo colegio
	(3070, 'PREPOSITION', 99, NULL), --rua rio grande do norte proximo do ...
	(3070, 'COMPLEMENT', 99, NULL), --rua correia de freitas qdb lt 36
	(3070, 'EOF', 99, '{switch_temp_and_name}'), --rua passo fundo

	-- 40 <LOCATION>
	(40, 'TYPE', 30, '{consume_name}'), --campo largo
	(40, 'TYPE-QUALIFIER', 30, '{consume_name}'), --povoado principal, povoado ligacao
	(40, 'TITLE', 20, '{consume_title}'),
	(40, 'TITLE-QUALIFIER', 30, '{consume_name}'), --escola agricola
	(40, 'QUALIFIER', 40, '{consume_type}'), --vila rural sao francisco de assis --FIXME 4050 <LOCATION> <QUALIFIER>
	(40, 'NAME', 30, '{consume_name}'), --colonia esperanca
	(40, 'NUMERAL', 30, '{consume_name}'), --sitio dois irmaos
	(40, 'LOCATION', 30, '{consume_name}'), --colonia pinheiral de cima, linha barra do rio vinte e cinco
	(40, 'PREPOSITION', 4060, '{consume_temp}'), --rio do oeste
	(40, 'COMPLEMENT', 99, NULL),
	(40, 'EOF', 99, '{switch_type_and_name}'),
	(40, 'ROAD,TITLE', 1080, '{consume_temp}'), --povoamento br-373

	-- 4060 <LOCATION> <PREPOSITION>
	(4060, 'TYPE', 30, '{consume_name}'), --alto do trevo
	(4060, 'TITLE', 30, '{consume_name}'), --buraco do padre
	(4060, 'QUALIFIER', 40, '{consume_type}'), --vil a rural ...
	(4060, 'NAME', 30, '{consume_name}'), --alto da gloria
	(4060, 'NUMERAL', 30, '{consume_name}'),
	(4060, 'LOCATION', 30, '{consume_name}'), --localidade de alto das palmeiras
	(4060, 'PREPOSITION', 30, '{switch_temp_and_name}'), --linha e de itapara
	(4060, 'COMPLEMENT', 99, '{switch_temp_and_name}'), --gleba a lote 61
	(4060, 'EOF', 99, '{switch_temp_and_name}'),

	-- 50 <QUALIFIER>
	(50, 'TYPE', 10, '{switch_temp_and_type,consume_type}'), --auto via joao ...
	(50, 'TITLE', 20, '{switch_temp_and_type,consume_title}'), --rural nossa senhora aparecida
	(50, 'NAME', 40, '{switch_temp_and_type,consume_name}'), --industrial valmor antonio alfredo rosa
	(50, 'LOCATION', 10, '{switch_temp_and_type,consume_type}'),
	(50, 'PREPOSITION', 50, NULL), --rural de vila nova
	(50, 'EOF', 99, '{switch_temp_and_name}'), --industrial

	-- 80 <ROAD,TITLE>
	(80, 'TYPE', 80, NULL), --br rodovia 476 km 340
	(80, 'TITLE', 20, '{consume_title}'), --dump_temp, br engenheiro luiz douglas de araujo, pr senador correia
	(80, 'NAME', 30, '{switch_temp_and_title,consume_name}'),
	(80, 'NUMERAL', 99, '{consume_road}'),
	(80, 'LOCATION', 20, '{switch_temp_and_title,consume_title}'), --br cerro azul
	(80, 'PREPOSITION', 2060, '{switch_temp_and_title}'), --br de santo angelo
	(80, 'COMPLEMENT', 99, NULL), --pr proximo a praia
	(80, 'EOF', 99, NULL), --br
	(80, 'ROAD,TITLE', 80, '{consume_temp}') --br rodovia br 373 ...

	--FINISHED (99)
	;
