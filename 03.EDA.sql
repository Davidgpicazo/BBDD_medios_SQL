/*
===============================================================================================================================
EDA – Exploratory Data Analysis
Proyecto: Proyecto-2-SQL-Diseño-BBDDs-Relacionales-EDA
Autor: David Gómez Picazo
===============================================================================================================================
ÍNDICE

1. VISION GENERAL DEL SISTEMA
	1.1 Número total de medios
	1.2 Número total de proyectos
	1.3 Número total de registros de uso
	1.4 Número total de medios distintos con algún uso
	1.5 Número total de medios ocupados
	1.6 Distribución de medios por categoría
	1.7 Distribución de medios por centro
	1.8 Distribución de proyectos por centro


2. MEDIOS NO UTILIZADOS Y SU IMPACTO ECONÓMICO
	2.1 Identificación de medios nunca utilizados
	2.2 Coste asociado a medios nunca utilizados
	2.3 Coste total de sobrecompra
	2.4 Porcentaje de sobrecompra sobre el total invertido
	2.5 Desglose de sobrecompra por tipo de adquisición
	2.6 Desglose de sobrecompra por proveedor
	2.7 Top 10 medios no utilizados con mayor impacto económico
	2.8 Clasificación de medios no utilizados por nivel de impacto
	2.9 Distribución de medios no utilizados por nivel de impacto y coste

3. REUTILIZACION Y EFICIENCIA DE LOS MEDIOS
	3.1 Número de usos por medio
	3.2 Listado de proyectos distintos por medio (reutilización)
	3.3 Medios reutilizados vs medios monoproyecto
	3.4 Reutilización de medios por categoría
	3.5 Reutilización de medios vs coste asociado
	3.6 Ranking de medios por grado de reutilización
	3.7 Identificación de medios críticos compartidos

4. ANALISIS TEMPORAL DEL USO DE LOS MEDIOS
	4.1 Duración de cada uso de medio
	4.2 Medios con mayor tiempo acumulado de uso
	
5. ANALISIS DE PROYECTOS Y CONSUMO DE MEDIOS
	5.1 Número de medios utilizados por proyecto
	5.2 Coste total de medios por proyecto
	5.3 Coste medio por uso en cada proyecto
	5.4 Proyectos con medios exclusivos

6. VISTA FINAL DE DECISION
	6.1 Vista medios bloqueantes
	6.2 Vista impacto proveedores

7. FUNCION

8. PRINCIPALES INSIGHTS OBTENIDOS
===============================================================================================================================
*/

/*
===========================================================
1. VISION GENERAL DEL SISTEMA
	1.1 Número total de medios
	1.2 Número total de proyectos
	1.3 Número total de registros de uso
	1.4 Número total de medios distintos con algún uso
	1.5 Número total de medios ocupados
	1.6 Distribución de medios por categoría
	1.7 Distribución de medios por centro
	1.8 Distribución de proyectos por centro

===========================================================
*/

-- 1.1 Número total de medios
	-- 2748 medios de prueba en total
SELECT
	COUNT(medio_id) AS total_medios 				 
FROM medios; 

-- 1.2 Número total de proyectos
	-- 433 proyectos en total
SELECT 
	COUNT(proyecto_id) AS total_proyectos
FROM 
	proyectos; 

-- 1.3 Número total de registros de uso
	-- 694 usos en total
SELECT 
	COUNT(*) AS total_usos
FROM 
	uso_medios; 

-- 1.4 Número total de medios distintos con algún uso
	-- 331 medios usados alguna vez
-- Esto quiere decir que 2748 - 331 = 2417 medios no se han utilizado nunca --> Gran problema de gestión
SELECT
	COUNT(DISTINCT medio_id) AS total
FROM
	uso_medios;

-- 1.5 Número total de medios ocupados
	-- 320 medios están ocupados 
SELECT 
	COUNT(DISTINCT medio_id) AS usos_abiertos -- Como un mismo medio puede usarse varias veces y no es lo que queremos
											  -- utilizamos el "DISTINCT"
FROM 
	uso_medios
WHERE fecha_fin IS NULL; -- Si fecha_fin es nulo significa que todavía están en uso, es decir, ocupados 

-- 1.6 Distribución de medios por categoría
	-- RF: 1148 medios
	-- DG: 694
	-- AMP: 481
	-- MJ: 425
SELECT
	cm.descripcion as nombre,
	cm.nombre as categoria,
	COUNT(m.medio_id) as total_medios
FROM
	medios m
LEFT JOIN categorias_medios cm 
	ON m.categoria_id = cm.categoria_id -- Se utiliza LEFT JOIN porque queremos saber la cantidad de medios por categoría y 
							   			-- si hay medios sin categoría asignada. Al no ser fact_table, con JOIN (INNER JOIN) 
							   			-- aparece el mismo resultado
GROUP BY categoria, cm.descripcion
ORDER BY total_medios DESC;

-- 1.7 Distribución de medios por centro
	-- Centro 4000: 223
	-- Centro 3000: 85
	-- Centro 1000: 84
	-- Centro 9000: 80
	-- Centro 2000: 55
	-- Centro 8000: 49
SELECT
	c.nombre AS centro,
	c.ciudad AS ciudad,
	COUNT(DISTINCT u.medio_id) AS total_medios -- "DISTINCT" importante para no repetir varios usos del mismo medio en el mismo centro
FROM
	uso_medios u -- Fact table. Tiene "medios y proyectos"
JOIN proyectos p
	ON u.proyecto_id = p.proyecto_id -- (Puente) Necesario para extraer los proyectos y vincular posteriormente los centros
JOIN centros c
	ON p.centro_id = c.centro_id  -- Necesario para extraer los centros
GROUP BY centro, ciudad
ORDER BY total_medios DESC;

-- 1.8 Distribución de proyectos por centro
	-- Centro 4000: 155
	-- Centro 3000: 52
	-- Centro 1000: 46
	-- Centro 9000: 45
	-- Centro 2000: 31
	-- Centro 8000: 30
SELECT
	c.nombre AS centro,
	c.ciudad AS ciudad,
	COUNT(DISTINCT u.proyecto_id) AS total_proyectos -- "DISTINCT" importante para no repetir los usos de distintos medios en el mismo proyecto
FROM
	uso_medios u -- Fact table. Tiene "medios y proyectos"
JOIN proyectos p
	ON u.proyecto_id = p.proyecto_id -- (Puente) Necesario para extraer los proyectos y vincular posteriormente los centros
JOIN centros c
	ON p.centro_id = c.centro_id  -- Necesario para extraer los centros
GROUP BY centro, ciudad
ORDER BY total_proyectos DESC;


/*
===================================================================
2. MEDIOS NO UTILIZADOS Y SU IMPACTO ECONÓMICO
	2.1 Identificación de medios nunca utilizados
	2.2 Coste asociado a medios nunca utilizados
	2.3 Coste total de sobrecompra
	2.4 Porcentaje de sobrecompra sobre el total invertido
	2.5 Desglose de sobrecompra por tipo de adquisición
	2.6 Desglose de sobrecompra por proveedor
	2.7 Top 100 medios no utilizados con mayor impacto económico
	2.8 Clasificación de medios no utilizados por nivel de impacto
	2.9 Distribución de medios no utilizados por nivel de impacto y coste
==================================================================
*/

-- 2.1 Identificación de medios nunca utilizados
	-- Muestra una lista con el nombre y el ID del medio nunca utilizado
SELECT 
    m.medio_id,
    m.nombre AS medio
FROM 
	medios m
LEFT JOIN uso_medios u -- LEFT porque quiero extraer todos los medios_id. Si no, extraería todos los que sí tienen algún uso.
    ON m.medio_id = u.medio_id
WHERE u.uso_id IS NULL; -- Escojo solo los que no hayan tenido ningún uso en la historia

-- 2.2 Coste asociado a medios nunca utilizados
	-- Mismo que anterior pero en este caso con precios de cada medio
SELECT
	m.medio_id,
	m.nombre AS medio,
	s.precio
FROM 
	medios m
LEFT JOIN uso_medios um
	ON m.medio_id = um.medio_id
LEFT JOIN suministros_medios s -- Otro LEFT JOIN para no anular el primero
	ON m.medio_id = s.medio_id -- Vincular a m.medio_id porque si vinculo a um.medio_id no me aparece precio (es NULL en el anterior LEFT JOIN)
WHERE um.uso_id IS NULL
GROUP BY m.medio_id, m.nombre, s.precio
ORDER BY s.precio DESC; -- Se ordena de máyor coste a menor coste

-- 2.3 Coste total de sobrecompra
	-- Total: 13.325.470,40€
SELECT
	SUM(s.precio) AS total_sobrecompra
FROM 
	medios m
LEFT JOIN uso_medios um
	ON m.medio_id = um.medio_id
JOIN suministros_medios s -- JOIN y LEFT JOIN hacen lo mismo porque cada medio tiene un suministro 
	ON m.medio_id = s.medio_id -- Vincular a m.medio_id porque si vinculo a um.medio_id no me aparece precio (es NULL en el anterior LEFT JOIN)
WHERE um.uso_id IS NULL;

-- 2.4 Porcentaje de sobrecompra sobre el total invertido
	-- Total: 17.275.560,12€
	-- Sobrecompra: 13.325.470,40€
	-- Porcentaje de sobrecompra: 77,13% 
SELECT
	SUM(s.precio) AS total,
    SUM(CASE 
			WHEN um.uso_id IS NULL THEN s.precio
			ELSE 0 
		END) AS total_sobrecompra,
	ROUND(SUM
			(CASE 
				WHEN um.uso_id IS NULL THEN s.precio 
				ELSE 0 
			  END) 
        / SUM(s.precio) * 100, 2) AS porcentaje_sobrecompra -- Se divide el total_sobrecompra entre la suma total
FROM 
	medios m
LEFT JOIN uso_medios um
	ON m.medio_id = um.medio_id
JOIN suministros_medios s -- LEFT JOIN y JOIN hacen lo mismo
	ON m.medio_id = s.medio_id; -- Vincular a m.medio_id porque si vinculo a um.medio_id no me aparece precio (es NULL en el anterior LEFT JOIN)

-- 2.5 Desglose de sobrecompra por tipo de adquisición
	-- Sobrecompra: 13.213.922,20€ --> 3 opciones: Se intentan revender o se guarda stock y se usan en futuros proyectos. O una mezcla de ambas
	-- Sobrealquiler: 111.548,20€ --> Si no hay cláusula que obligue a mantenerlos, habría que quitar este sobrecoste de alquiler
SELECT
	s.tipo_adquisicion,
	SUM(s.precio) AS total_sobrecompra
FROM 
	medios m
LEFT JOIN uso_medios um
	ON m.medio_id = um.medio_id
LEFT JOIN suministros_medios s 
	ON m.medio_id = s.medio_id 
WHERE 
	um.uso_id IS NULL
GROUP BY s.tipo_adquisicion; -- Solo 2 categorías, no es necesario ordenar

-- 2.6 Desglose de sobrecompra por proveedor
	-- Keysight: 8.791.579,64€
	-- Rohde & Schwarz: 3.889.579,58€
	-- Prolians Metalco: 492.338,22€
	-- Weinschel Associates: 49.016,12€
	-- Mini-circuits: 39.053,09€
	-- BIRD: 36.303,97€
	-- S.M. ELECTRONICS: 27.599,78€
SELECT
	DISTINCT p.nombre,
	SUM(s.precio) AS total_sobrecompra
FROM 
	medios m
LEFT JOIN uso_medios um -- LEFT JOIN porque queremos todos los medios, si no, solo veríamos los que tienen uso
	ON m.medio_id = um.medio_id
JOIN suministros_medios s -- JOIN porque no puede existir un medio sin un suministro asociado (no habría precio)
	ON m.medio_id = s.medio_id
JOIN proveedores p -- JOIN porque no puede haber medio suministrado sin proveedor
	ON s.proveedor_id = p.proveedor_id
WHERE um.uso_id IS NULL
GROUP BY p.nombre
ORDER BY total_sobrecompra DESC;

-- 2.7 Top 10 medios nunca utilizados con mayor impacto económico
	-- Solo revendiendo los 10 medios más caros, el impacto se reduciría en 437.870€ 
WITH cte_top AS (
SELECT
	m.medio_id,
	m.nombre,
	s.precio
FROM 
	medios m
LEFT JOIN uso_medios um
	ON m.medio_id = um.medio_id
JOIN suministros_medios s
	ON m.medio_id = s.medio_id 
WHERE um.uso_id IS NULL
GROUP BY m.medio_id, m.nombre, s.precio
ORDER BY s.precio DESC LIMIT 10
)
SELECT
	SUM(precio)
FROM
	cte_top;


-- 2.8 Clasificación de medios no utilizados por nivel de impacto
	-- Esta clasificación es de interés para la siguiente consulta
SELECT
	m.medio_id,
	m.nombre,
	s.precio,
	CASE
        WHEN s.precio >= 40000 THEN 'Muy Alto impacto económico'
        WHEN s.precio >= 30000 THEN 'Alto impacto económico'
		WHEN s.precio >= 10000 THEN 'Moderado impacto económico'
        ELSE 'Bajo impacto económico'
		END AS impacto_economico
FROM 
	medios m
LEFT JOIN uso_medios um
	ON m.medio_id = um.medio_id
JOIN suministros_medios s
	ON m.medio_id = s.medio_id 
WHERE um.uso_id IS NULL
GROUP BY m.medio_id, m.nombre, s.precio
ORDER BY s.precio DESC;

-- 2.9 Distribución de medios no utilizados por nivel de impacto y coste
	-- Bajo impacto económico: 2292 --> 9.543.816,01€
	-- Moderado impacto económico: 65 --> 1.460.636,49€
	-- Alto impacto económico: 33 --> 1.175.797,74€
	-- Muy Alto impacto económico: 27 --> 1.145.220,16€
-- Esta query permite ver cómo si la empresa se centra en desprenderse de los 125 medios que componen las 3 categorías
-- inferiores, podrá ahorrarse aproximadamente un cuarto del total del coste de sobrecompra y después, centrar sus esfuerzos en los
-- de bajo impacto económico
WITH medios_no_utilizados AS (
    SELECT -- Subconsulta a misma que apartado anterior pero sin m.nombre ni m.nombre porque no interesan
        s.precio,
		CASE
        	WHEN s.precio >= 40000 THEN 'Muy Alto impacto económico'
        	WHEN s.precio >= 30000 THEN 'Alto impacto económico'
			WHEN s.precio >= 10000 THEN 'Moderado impacto económico'
        	ELSE 'Bajo impacto económico'
		END AS nivel_impacto
    FROM medios m
    LEFT JOIN uso_medios um
        ON m.medio_id = um.medio_id
    JOIN suministros_medios s
        ON m.medio_id = s.medio_id
    WHERE um.uso_id IS NULL
    GROUP BY m.medio_id, s.precio 
)
SELECT
    nivel_impacto,
	COUNT(*) AS total_medios,
	SUM(precio)
FROM medios_no_utilizados
GROUP BY nivel_impacto
ORDER BY total_medios DESC;

/*
===========================================================
3. REUTILIZACION Y EFICIENCIA DE LOS MEDIOS
	3.1 Número de usos por medio
	3.2 Listado de proyectos distintos por medio (reutilización)
	3.3 Medios reutilizados vs medios monoproyecto
	3.4 Reutilización de medios por categoría
	3.5 Reutilización de medios vs coste asociado
	3.6 Ranking de medios por grado de reutilización
	3.7 Identificación de medios críticos compartidos
===========================================================
*/

-- 3.1 Número de usos por medio
	-- De los 331 medios usados alguna vez, 245 se usan más de una vez --> Buena gestión de reutilización
SELECT
	m.medio_id,
	m.nombre AS medio,
    COUNT(u.uso_id) AS veces_usado
FROM uso_medios u
INNER JOIN medios m 
    ON u.medio_id = m.medio_id
GROUP BY m.medio_id, m.nombre
ORDER BY veces_usado DESC; -- Listado de los medios más utilizados, ordenados de mayor a menor

-- 3.2 Listado de proyectos distintos por medio (reutilización)
	-- De los 331 medios usados alguna vez, 245 se han reutilizado para más de un proyecto --> Todos los usos distintos son por usos en distintos proyectos.
	-- No hay medios con más de un uso dentro de un mismo proyecto
SELECT
    m.medio_id, -- Al tener varios nombres iguales, sirve para visualizar el medio en concreto al que se refiere
    m.nombre,
    COUNT(u.proyecto_id) AS total_proyectos -- Queremos saber el total de los proyectos por medio
FROM medios m
LEFT JOIN uso_medios u 
	ON m.medio_id = u.medio_id
WHERE u.proyecto_id > 0 -- Selecciona los medios que tienen algún proyecto asignado
GROUP BY m.medio_id, m.nombre
ORDER BY total_proyectos DESC;


-- 	3.3 Medios reutilizados en varios proyectos vs medios monoproyecto
-- Mismo que consulta anteriores pero separado por categorías --> Mejor entendimiento
	-- Monoproyecto: 86 medios
	-- Reutilizados: 245 medios
WITH reutilizados_monoproyectos AS ( -- Subconsulta tabla anterior sin m.nombre
	SELECT
	    m.medio_id,
	    COUNT(u.proyecto_id) AS total_proyectos
	FROM medios m
	LEFT JOIN uso_medios u 
		ON m.medio_id = u.medio_id
	WHERE u.proyecto_id > 0
	GROUP BY m.medio_id, m.nombre
)
SELECT
	CASE
		WHEN total_proyectos >=2 THEN 'Reutilizado'
		ELSE 'Monoproyecto'
	END AS reutilizacion,
	COUNT(medio_id) AS numero_medios
FROM reutilizados_monoproyectos
GROUP BY reutilizacion;

--	3.4 Reutilización de medios por categoría
	-- Con esta categorización, podremos ver qué medios son los más críticos (medios con más proyectos, más crítico)
SELECT
    DISTINCT m.medio_id,
    m.nombre,
    COUNT(u.proyecto_id) AS total_usos,
    CASE
        WHEN COUNT(u.proyecto_id) >= 3 THEN 'Alta reutilización'
        WHEN COUNT(u.proyecto_id) >= 2 THEN 'Media reutilización'
        ELSE 'Baja reutilización'
    END AS nivel_reutilizacion
FROM medios m
JOIN uso_medios u -- Queremos todos los medios que tienen uso
	ON m.medio_id = u.medio_id
GROUP BY m.medio_id, m.nombre
ORDER BY total_usos DESC;

--	3.5 Reutilización de medios vs coste asociado
	-- Coste total de los 127 medios con "Media reutilización": 728.970,04€
		-- Coste por medio/uso: 2.869,96 €
	-- Coste total de los 118 medios con "Alta reutilización": 691.186,97€
		-- Coste por medio/uso: 1.952,51€
	-- Coste total de los 86 medios con "Baja reutilización": 418.588,73€
		-- Coste por medio/uso: 4.867,31€
		
-- Los medios con baja reutilización son los que más coste generan por uso, ya que cada uso es equivalente al valor del medio.  
WITH cte_coste_reutilizacion AS (
SELECT
    DISTINCT m.medio_id,
    m.nombre,
    COUNT(u.proyecto_id) AS total_usos,
    CASE
        WHEN COUNT(u.proyecto_id) >= 3 THEN 'Alta reutilización'
        WHEN COUNT(u.proyecto_id) >= 2 THEN 'Media reutilización'
        ELSE 'Baja reutilización'
    END AS nivel_reutilizacion
FROM medios m
JOIN uso_medios u -- Queremos todos los medios que tienen uso
	ON m.medio_id = u.medio_id
GROUP BY m.medio_id, m.nombre
)
SELECT
	nivel_reutilizacion,
	COUNT(c.medio_id) AS cantidad_medios,
	SUM(s.precio) AS precio,
	ROUND(SUM(s.precio)/COUNT(c.medio_id),2) AS precio_por_medio, -- Coste total entre número de medios
	ROUND(CASE
				WHEN nivel_reutilizacion = 'Alta reutilización' THEN SUM(s.precio)/COUNT(c.medio_id)/3
				WHEN nivel_reutilizacion = 'Media reutilización' THEN SUM(s.precio)/COUNT(c.medio_id)/2
				ELSE SUM(s.precio)/COUNT(c.medio_id)
		  END,2) AS coste_uso
FROM 
	cte_coste_reutilizacion c
JOIN suministros_medios s
	ON c.medio_id = s.medio_id
GROUP BY nivel_reutilizacion
ORDER BY SUM(s.precio) DESC;


--	3.6 Ranking de medios por grado de reutilización
	-- Vemos que hay medios muy económicos y con muy buena reutilización. Sin embargo, hay otros muy caros pero con poca o nula reutilización
SELECT
    m.medio_id,
    m.nombre AS medio,
    COUNT(DISTINCT u.proyecto_id) AS proyectos_distintos,
	s.precio,
    RANK() OVER(ORDER BY COUNT(DISTINCT u.proyecto_id) DESC, s.precio ASC) AS ranking_reutilizacion
		-- Cuanto más reutilización (DESC) tenga y menor precio (ASC) tenga, mejor.
FROM medios m
JOIN uso_medios u
    ON m.medio_id = u.medio_id -- Nos quedamos solo con medios que sí se han usado
LEFT JOIN suministros_medios s
	ON u.medio_id = s.medio_id
GROUP BY m.medio_id, m.nombre, s.precio
ORDER BY ranking_reutilizacion ASC;

-- 3.6.1 Número de los medios por encima de 10.000€ y coste total asociado
	-- Esta consulta se ha realizado para ver el dinero estimado por los medios con más de 10.000€ (a partir de un impacto económico "moderado").
		-- Coste total de medios con baja reutilización: 418.588,73€ --> por encima de 10.000€: 62.412,03 --> 3 medios
		-- Coste total de medios con media reutilización: 728.970,04€ --> por encima de 10.000€: 238.839,27€ --> 9 medios
		-- Coste total de medios con alta reutilización: 691.186,97 --> por encima de 10.000€: 196.368,79€ --> 6 medios
		
-- Los medios por encima de 10.000€ de alta y media reutilización suponen 1/3 del coste total de esas categorías.
WITH cte_rank AS ( -- consulta anterior
SELECT
    m.medio_id,
    m.nombre AS medio,
    COUNT(DISTINCT u.proyecto_id) AS proyectos_distintos,
	s.precio
FROM medios m
JOIN uso_medios u
    ON m.medio_id = u.medio_id
LEFT JOIN suministros_medios s
	ON u.medio_id = s.medio_id
GROUP BY m.medio_id, m.nombre, s.precio
)
SELECT
	DISTINCT proyectos_distintos,
	COUNT(*) AS numero_medios,
	SUM(c.precio) AS coste
FROM 
	cte_rank c
WHERE c.precio > 10000
GROUP BY proyectos_distintos;


--	3.7 Identificación de medios críticos compartidos
	-- Medios 195, 341 y 312 son los más críticos, ya que son en los que más proyectos se utilizan y mayor precio tienen
		-- Habra que minimizar el riesgo de fallo en estos equipos. Por ejemplo, asegurando su correcto mantenimiento. 
SELECT
    m.medio_id,
    m.nombre AS medio,
    COUNT(DISTINCT u.proyecto_id) AS proyectos_distintos,
	s.precio,
    RANK() OVER(ORDER BY COUNT(DISTINCT u.proyecto_id) DESC, s.precio DESC) AS ranking_criticos
		-- Cuanto más reutilización (DESC) tenga y mayor precio (DESC) tenga, más crítico.
FROM medios m
JOIN uso_medios u
    ON m.medio_id = u.medio_id -- Nos quedamos solo con medios que sí se han usado
LEFT JOIN suministros_medios s
	ON u.medio_id = s.medio_id
GROUP BY m.medio_id, m.nombre, s.precio
ORDER BY ranking_criticos ASC;

/*
===========================================================
4. ANALISIS TEMPORAL DEL USO DE LOS MEDIOS
	4.1 Duración de cada uso de medio
	4.2 Medios con mayor tiempo acumulado de uso
===========================================================
*/

-- 	4.1 Duración de cada uso de medio
	-- Nos ayuda a ver cuánto tiempo de uso ha estado cada medio, para hacernos una idea de ocupación en futuros usos
SELECT
	u.medio_id,
	m.nombre AS medio,
	p.nombre AS proyecto,
	CASE -- Cuenta los días de los proyectos finalizados, y los que no, los días que lleva hasta día de hoy
		WHEN u.fecha_fin IS NOT NULL THEN u.fecha_fin - u.fecha_inicio
		ELSE CURRENT_DATE - u.fecha_inicio
	END AS dias_duracion
FROM uso_medios u
JOIN medios m
	ON u.medio_id = m.medio_id
JOIN proyectos p
	ON u.proyecto_id = p.proyecto_id
ORDER BY dias_duracion DESC; -- No se usa GROUP BY porque se quieren los días de cada uso por proyecto, da igual que haya medios repetidos

--	4.2 Medios con mayor tiempo acumulado de uso
	-- Nos ayuda a ver los medios que más tiempo de uso han tenido
SELECT
	DISTINCT m.medio_id,
	m.nombre,
	MIN(u.fecha_inicio) AS fecha_inicio,
	CASE
		WHEN MAX(u.fecha_fin) IS NOT NULL THEN MAX(u.fecha_fin)
		ELSE CURRENT_DATE
	END AS fecha_ultima,
	COUNT(u.uso_id) AS numero_usos,
    CASE
        WHEN MAX(u.fecha_fin) IS NOT NULL THEN MAX(u.fecha_fin) - MIN(u.fecha_inicio)
        ELSE CURRENT_DATE - MIN(u.fecha_inicio)
    END AS duracion_suma_dias
FROM uso_medios u
JOIN medios m
	ON u.medio_id = m.medio_id
GROUP BY m.medio_id, m.nombre
ORDER BY duracion_suma_dias DESC;

/*
===========================================================
5. ANALISIS DE PROYECTOS Y CONSUMO DE MEDIOS
	5.1 Número de medios distintos utilizados por proyecto
	5.2 Coste total de medios por proyecto
	5.3 Coste medio por uso en cada proyecto
	5.4 Proyectos con medios exclusivos
===========================================================
*/

--	5.1 Número de medios distintos utilizados por proyecto
	-- Aquí, he sacado la cantidad de medios distintos por proyecto para estimar la complejidad del mismo.
	-- Considerando que a mayor número de medios distintos, mayor complejidad.
SELECT
	p.proyecto_id,
	p.nombre AS proyecto,
	COUNT (DISTINCT medio_id) AS numero_medios_distintos
FROM uso_medios u
JOIN proyectos p
	ON u.proyecto_id = p.proyecto_id
GROUP BY p.proyecto_id, proyecto
ORDER BY numero_medios_distintos DESC;

--	5.2 Coste total de medios por proyecto
	-- Aquí podremos identificar los proyectos con mayor coste por medios. En este caso, los proyectos con id 186, 406 y 123.
SELECT
	p.proyecto_id,
	p.nombre AS proyecto,
	COUNT(DISTINCT u.medio_id) AS numero_medios_distintos,
	SUM(s.precio) AS coste_total_medios
FROM uso_medios u
JOIN proyectos p
	ON u.proyecto_id = p.proyecto_id
JOIN suministros_medios s
	ON u.medio_id = s.medio_id
GROUP BY p.proyecto_id, proyecto
ORDER BY coste_total_medios DESC;

--	5.3 Coste medio por uso en cada proyecto
	-- En este punto he querido ver cuánto cuesta, de media, cada medio que se utiliza en un proyecto. 
	-- La idea es no quedarme solo con el coste total, sino entender si un proyecto usa muchos medios baratos o pocos medios 
	-- pero muy caros. Esto me ayuda a diferenciar proyectos más “simples” de otros que trabajan con equipamiento más específico 
	-- o de mayor nivel, y complementa la información del apartado anterior.
SELECT
    p.proyecto_id,
    p.nombre AS proyecto,
    COUNT(DISTINCT u.medio_id) AS medios_distintos,
	SUM(s.precio) AS coste_total_medios, 
    ROUND (AVG(s.precio),2) AS coste_medio_por_medio -- La media se calculará en función de la cantidad de medios
FROM uso_medios u
JOIN proyectos p
    ON u.proyecto_id = p.proyecto_id
JOIN suministros_medios s
    ON u.medio_id = s.medio_id
GROUP BY p.proyecto_id, p.nombre
ORDER BY coste_medio_por_medio DESC;

--	5.4 Proyectos con medios exclusivos
	-- En este apartado he buscado qué proyectos tienen medios exclusivos. 
	-- Permitiendo identificar proyectos que dependen de equipamiento específico y que, por tanto, presentan menor capacidad de reutilización y mayor rigidez en términos de recursos.
SELECT
    p.proyecto_id,
    p.nombre AS proyecto,
    COUNT(DISTINCT u.medio_id) AS medios_exclusivos
FROM uso_medios u
JOIN proyectos p
    ON u.proyecto_id = p.proyecto_id
WHERE u.medio_id IN (
    SELECT medio_id
    FROM uso_medios
    GROUP BY medio_id
    HAVING COUNT(DISTINCT proyecto_id) = 1
) -- Se hace una subconsulta, agrupando por medios que solo tengan un proyecto_id asociado, ni más ni menos (HAVING)
GROUP BY p.proyecto_id, p.nombre
ORDER BY medios_exclusivos DESC;

/*
===========================================================
6. VISTA FINAL DE DECISION
	-- 6.1 Vista medios bloqueantes
	-- 6.2 Vista impacto proveedores
===========================================================
*/

-- 6.1 Vista medios bloqueantes
	-- Esta vista incluye, para cada medio bloqueante (con más nº de usos), si sigue en uso o no y los días faltantes para su próximo mantenimiento.
	-- Se puede observar cómo existen medios que actualmente se utilizan en proyectos pero que el mantenimiento no se le ha pasado en la fecha esperada.
	-- Habrá que pasar el mantenimiento lo antes posible para evitar fallos peores.
SELECT * FROM vista_medios_bloqueantes;

-- 6.2 Vista impacto proveedores
	-- Esta vista incluye, para cada proveedor, la cantidad de medios que se le han comprado, el coste total gastado y el número de semanas promedio de entrega.
	-- Así, en caso de necesitar la compra de un equipo, se podrá ver qué proveedor es el que menos tiempo de entrega suele necesitar y el que posiblemente sea más barato

SELECT * FROM vista_impacto_proveedores;

/*
===========================================================
7. FUNCION
===========================================================
*/
-- Esta función permite ver el coste total en medios que tiene asociado un proyecto concreto, en base a su "proyecto_id"
SELECT coste_total_proyecto(27);


/*
===========================================================
8. PRINCIPALES INSIGHTS OBTENIDOS
===========================================================
*/

/*
En primer lugar, se ha visto que existe una gran cantidad de medios que nunca han sido utilizados, que suponen un coste de más del 77% del coste total.
Por lo que habrá que revisar la manera en la que la empresa puede reducir este sobrecoste --> Deshaciéndose de los medios más con maoyr coste + los de alquiler,
la empresa puede reducir este sobrecoste en aproximadamente 1/4 del total, equivalente a casi 4 millones de euros.

En segundo lugar, se ha viso cómo hay medios que se reutilizan para distintos proyectos, y de los que, en caso de fallar, afectaría a más proyectos, los hemos considerado bloqueantes.
Pero también hay otros que son exclusivos y que suponen un coste por uso muy elevado. Esto puede deberse a un problema de gestión/planificación inicial.

Por otro lado, se han identificado los días de uso que suele tener un medio, permitiendo saber cuándo se prevee que un medio se desbloquee y pueda ser usado para otro proyecto
(en caso de estar saturado)

Por último, se han visualizado los proyectos con mayor coste y número de medios, permitiendo identificar qué proyectos son más simples o más complejos.
Esto nos ayudará a prestar más atención a los proyectos más complejos y a evitar más sobrecostes en los proyectos menos económicos.
*/

/*
En los últimos apartados se ha añadido:
- Una función que permite identificar el coste de un proyecto en base a su "id"
- Una vista que muestra los medios bloqueantes y su fecha de mantenimiento
- Una vista que muestra el coste medio por equipo, según cada proveedor y las semanas que tarda en realizar la entrega.
*/