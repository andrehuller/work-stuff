----------------------------------------------------------------------------------------------------
--DETERMINA SE O NOME DA RUA É PROVISÓRIO
----------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION streetbase.GEO_Unnamed_Street(a_name text)
	RETURNS BOOLEAN AS $$
BEGIN
	RETURN a_name LIKE 'rua projetada %' OR a_name IN ('um', 'dois', 'tres', 'quatro',
		'cinco', 'seis', 'sete', 'oito', 'nove',
		'dez', 'onze', 'doze', 'treze', 'quatorze',
		'quinze', 'dezesseis', 'dezessete', 'dezoito', 'dezenove'
		'vinte', 'vinte um', 'vinte dois', 'vinte tres', 'vinte quatro',
		'vinte cinco', 'vinte seis', 'vinte sete', 'vinte oito', 'vinte nove',
		'trinta', 'trinta um', '01', '02', '03', '04', '05', '06', '07', '08', '09', '10',
		'11', '12', '13', '14', '15', '16', '17', '18', '19', '20',
		'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l',
		'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z');
END;
$$ LANGUAGE plpgsql IMMUTABLE;
----------------------------------------------------------------------------------------------------
