
-- Crear la Base de Datos
DROP DATABASE IF EXISTS IngenieriaProcesosDB;
CREATE DATABASE IngenieriaProcesosDB;

 /* ======================
		BORRAR TABLAS
	====================== */

-- Borrar tablas si ya existen, para que el código no genere error
DROP TABLE IF EXISTS uso_medios CASCADE;
DROP TABLE IF EXISTS suministros_medios CASCADE;
DROP TABLE IF EXISTS medios CASCADE;
DROP TABLE IF EXISTS medio_atributos CASCADE;
DROP TABLE IF EXISTS categorias_medios CASCADE;
DROP TABLE IF EXISTS proveedores CASCADE;
DROP TABLE IF EXISTS proyectos CASCADE;
DROP TABLE IF EXISTS centros CASCADE;
DROP VIEW IF EXISTS vista_medios_bloqueantes CASCADE;
DROP VIEW IF EXISTS vista_impacto_proveedores CASCADE;
-- Con "CASCADE" si eliminas una tabla padre, las tablas hijas dependientes (con "FOREIGN KEY"), también se borrarán

 /* ======================
		CREAR TABLAS
	====================== */

-- Crear tabla "centros"
	-- Tabla donde se incluyen los centros de producción
CREATE TABLE centros (
	centro_id SERIAL PRIMARY KEY,
	nombre VARCHAR(50) NOT NULL,
	ciudad VARCHAR(50),
	pais VARCHAR(50),
	activo BOOLEAN DEFAULT TRUE -- Si actualmente está activo o no. Puede que en un futuro se paralice la producción y más adelante se vuelva a activar de nuevo
);

-- Crear tabla "proyectos"
CREATE TABLE proyectos (
	proyecto_id SERIAL PRIMARY KEY,
	nombre VARCHAR(100) NOT NULL,
	codigo VARCHAR(50) NOT NULL,
	centro_id INT NOT NULL,
	fecha_inicio DATE NOT NULL,
	fecha_fin_prevista DATE NOT NULL,
	fecha_fin_real DATE,
	FOREIGN KEY (centro_id) REFERENCES centros (centro_id)
);

-- Crear tabla "proveedores"
CREATE TABLE proveedores (
	proveedor_id SERIAL PRIMARY KEY,
	nombre VARCHAR(100) NOT NULL,
	pais VARCHAR(50),
	email VARCHAR(100) UNIQUE,
	telefono VARCHAR(30),
	url VARCHAR(300),
	fecha_alta DATE DEFAULT CURRENT_DATE	
);

-- Crear tabla "categorias_medios"
CREATE TABLE categorias_medios (
	categoria_id SERIAL PRIMARY KEY,
	nombre VARCHAR(50) NOT NULL UNIQUE,
	descripcion TEXT
);

-- Crear tabla "medios"
CREATE TABLE medios (
	medio_id SERIAL PRIMARY KEY,
	nombre VARCHAR(100) NOT NULL,
	codigo VARCHAR(50),
	categoria_id INT NOT NULL,
	activo BOOLEAN DEFAULT TRUE, -- Si un medio se ha mandado a reparar o pasar mantenimiento, deberá aparecer como inactivo hasta volver a recibirlo
	fecha_adquisicion DATE,
	fecha_ultimo_mantenimiento DATE,
	fecha_proximo_mantenimiento DATE,
	FOREIGN KEY (categoria_id) REFERENCES categorias_medios(categoria_id)
);
	
-- Crear tabla "medios_atributos"
CREATE TABLE medio_atributos (
    atributo_id SERIAL PRIMARY KEY,
    medio_id INT NOT NULL,
    atributo VARCHAR(100) NOT NULL,
    valor VARCHAR(100),
    unidad VARCHAR(50),
	FOREIGN KEY (medio_id) REFERENCES medios (medio_id)
);

-- Crear tabla "suministros_medios"
CREATE TABLE suministros_medios (
	suministro_id SERIAL PRIMARY KEY,
	medio_id INT NOT NULL,
	proveedor_id INT NOT NULL,
	precio NUMERIC(12,2) NOT NULL,
	moneda VARCHAR(10) DEFAULT 'EUR',
	entrega_semanas INT
		CHECK (entrega_semanas>0),
	tipo_adquisicion VARCHAR(20)
		CHECK(tipo_adquisicion IN ('compra', 'alquiler')),
	part_number VARCHAR(100),
	FOREIGN KEY (medio_id) REFERENCES medios (medio_id),
	FOREIGN KEY (proveedor_id) REFERENCES proveedores (proveedor_id)
);

-- Crear la tabla "uso_medios" --> Fact table
CREATE TABLE uso_medios (
	uso_id SERIAL PRIMARY KEY,
	medio_id INT NOT NULL,
	proyecto_id INT NOT NULL,
	fecha_inicio DATE NOT NULL,
	fecha_fin DATE
		CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_inicio),
    FOREIGN KEY (medio_id) REFERENCES medios (medio_id),
    FOREIGN KEY (proyecto_id) REFERENCES proyectos (proyecto_id)
);

 /* ======================
	       ÍNDICE
	====================== */
	
-- Crea el índice "idx_uso_medios_proyectos" para mejorar el rendimiento de las consultas por proyecto
	-- Encuentra la fila del "uso_medios" más rápido. En lugar de ir fila a fila, va directo a la fila correcta.
	-- En este caso, se ha creado para proyecto_id para ayudar a la búsqueda de la función "coste_total_proyecto"
CREATE INDEX idx_uso_medios_proyecto
ON uso_medios (proyecto_id);


 /* ======================
	      FUNCIONES
	====================== */

-- Crear función "coste_total_proyecto"
-- Esta función sirve para saber cuánto dinero en medios tiene asociado un proyecto concreto
CREATE OR REPLACE FUNCTION coste_total_proyecto(p_proyecto_id INT) -- Crear función coste_total_proyecto(entrada de funcion)
RETURNS NUMERIC -- Devuelve algo numerico, en este caso, el precio
LANGUAGE plpgsql -- La función está escrita en el lenguaje de funciones de PostgreSQL
AS 
$$ -- Cuerpo de la función
DECLARE
    total_coste NUMERIC; -- Declara variable para luego utilizar
BEGIN
    SELECT SUM(s.precio) INTO total_coste -- Selecciona la suma del precio e inserta esa suma en variable declarada
    FROM uso_medios u
    JOIN suministros_medios s
        ON u.medio_id = s.medio_id -- Une uso_medios con suministros_medios para poder extraer el precio
    WHERE u.proyecto_id = p_proyecto_id; -- u.proyecto_id = entrada de función
-- No se necesita el "GROUP BY" porque se agrupa al meter la entrada en la función
    RETURN total_coste; -- Devuelve variable declarada con lo que se ha insertado en su interior. En este caso, la suma del precio de los
						-- medios utilizados por cada proyecto	
END;
$$; -- Final del cuerpo de la función


 /* ======================
	       VISTAS
	====================== */
-- Crear vista "vista_medios_bloqueantes"
	-- Esta vista permite ver rápidamente qué medios bloqueantes necesitan mantenimiento o necesitarán pronto un mantenimiento
CREATE VIEW vista_medios_bloqueantes AS
SELECT
    m.medio_id,
    m.nombre AS medio,
    COUNT(DISTINCT u.proyecto_id) AS proyectos_afectados,
    MIN(u.fecha_inicio) AS fecha_inicio_global, -- se estima la fecha inicial del proyecto que antes ha comenzado
    CASE
        WHEN MAX(u.fecha_fin) IS NOT NULL THEN MAX(u.fecha_fin) -- Se estima la fecha fin del proyecto al que el medio está asociado y que más tarde termina
        ELSE CURRENT_DATE -- Si no tiene fecha_fin, que aparezca la fecha de hoy
    END AS fecha_fin_global, 
	m.fecha_proximo_mantenimiento AS fecha_mantenimiento,
	m.fecha_proximo_mantenimiento - CURRENT_DATE AS dias_mantenimiento
FROM uso_medios u
JOIN medios m
    ON u.medio_id = m.medio_id
GROUP BY m.medio_id, m.nombre
HAVING COUNT(DISTINCT u.proyecto_id) >= 3 AND (CASE
        											WHEN MAX(u.fecha_fin) IS NOT NULL THEN MAX(u.fecha_fin)
        											ELSE CURRENT_DATE
    											END) >= CURRENT_DATE -- Todos los proyectos que no hayan acabado todavía. Fecha fin es mayor o igual al día de hoy
ORDER BY dias_mantenimiento ASC; -- Los medios que más número de proyectos tienen

-- Crear vista "vista_impacto_proveedores"
	-- En esta vista se muestran el coste total gastado en cada proveedor y el coste medio por proveedor.
CREATE VIEW vista_impacto_proveedores AS
SELECT
    p.proveedor_id,
    p.nombre AS proveedor,
    COUNT(DISTINCT s.medio_id) AS numero_medios,
    SUM(s.precio) AS coste_total,
	ROUND(AVG(s.precio),2) AS coste_medio_proveedor,
	ROUND(AVG(s.entrega_semanas)) AS promedio_entrega_semanas
FROM suministros_medios s
JOIN proveedores p
    ON s.proveedor_id = p.proveedor_id
GROUP BY p.proveedor_id, p.nombre
ORDER BY coste_medio_proveedor DESC;







