# BBDD_medios_SQL

Este proyecto recoge el diseño, implementación y análisis de una base de datos relacional orientada al estudio del uso de medios en proyectos y centros.

El trabajo cubre **todo el flujo de datos**, desde su origen en ficheros Excel, pasando por una fase de extracción y preparación mediante Python (Jupyter Notebook), hasta la carga, modelado y análisis en SQL. El objetivo no es únicamente almacenar datos, sino construir un modelo coherente, normalizado y preparado para análisis reales.


## Enfoque del proyecto
He abordado el proyecto como un pipeline sencillo pero realista, similar al que podría encontrarse en un entorno profesional:

1. **Datos de origen en Excel**, con estructura heterogénea.
2. **Extracción y preparación en Python**, utilizando un Jupyter Notebook.
3. **Generación de ficheros `.txt` con sentencias SQL** para una carga controlada.
4. **Modelado relacional y análisis exploratorio** directamente en base de datos.

Este enfoque permite desacoplar las distintas fases, controlar la calidad del dato y repetir el proceso de carga de forma consistente.


## Estructura del repositorio
├── 01.schema.sql # Definición del esquema relacional y restricciones
├── 02.data.sql # Inserción de datos (simulados a partir de datos reales)
├── 03.EDA.sql # Consultas de análisis exploratorio
├── ERD.png # Diagrama Entidad–Relación
├── data # incluye el jupyter, txt y excel 
└── README.md # Documentación del proyecto


## Origen y preparación de los datos
### Excel como fuente de datos
Los datos originales de medios proceden de ficheros Excel. Como ocurre habitualmente en este tipo de fuentes, los datos presentan inconsistencias de formato, valores nulos y relaciones implícitas que no son directamente cargables en una base de datos relacional.
Por este motivo, el Excel se utiliza únicamente como **fuente de entrada**, no como origen directo de carga.

### Extracción y transformación con Python
La preparación de los datos se realiza en el notebook `Extraccion datos.ipynb`, donde:

- Se leen los ficheros Excel.
- Se depuran y normalizan los datos.
- Se separa la información según las entidades del modelo.
- Se generan distintos ficheros `.txt` con sentencias `INSERT`.

Estos `.txt` actúan como **puente controlado** entre Excel y SQL, permitiendo revisar los datos antes de su carga y repetir el proceso sin intervención manual.


## Modelo de datos
El modelo se ha diseñado siguiendo una separación clara entre entidades descriptivas y eventos.
### Tablas descriptivas

- `centros`
- `proveedores`
- `categorias_medios`
- `suministros_medios`
- `medios`
- `proyectos`

Estas tablas contienen información relativamente estable y evitan duplicidades mediante relaciones bien definidas.

### Tabla de hechos

- `uso_medios`

La tabla `uso_medios` actúa como **tabla de hechos**, registrando cada evento de uso de un medio en un proyecto dentro de un intervalo temporal (`fecha_inicio` y `fecha_fin`).  
Desde esta tabla se pueden realizar análisis temporales, agregaciones y cruces entre centros, proyectos y medios sin redundancia de información.

El diagrama Entidad–Relación completo se incluye en el archivo `ERD.png`.


## Decisiones de diseño
Durante el desarrollo se han tomado decisiones orientadas a la coherencia y mantenibilidad del modelo:

- Uso de **claves artificiales** (`SERIAL`) como identificadores primarios.
- Definición explícita de **claves foráneas** para garantizar integridad referencial.
- Uso de **restricciones `CHECK`** para evitar incoherencias temporales (por ejemplo, fechas de fin anteriores a fechas de inicio).
- Separación estricta entre datos descriptivos y eventos medibles.
- Uso de Python como capa intermedia en lugar de cargas directas desde Excel.

Estas decisiones priorizan la claridad del modelo y su utilidad analítica frente a soluciones más simples pero menos robustas.

## Análisis Exploratorio de Datos (EDA)

El archivo `03.EDA.sql` contiene consultas de análisis exploratorio orientadas a:

- Analizar el uso de medios por centro y ciudad.
- Identificar proyectos con mayor consumo de recursos.
- Estudiar la duración y frecuencia de los usos.
- Validar la coherencia del modelo mediante agregaciones y cruces de tablas.

El EDA se utiliza como una herramienta de validación del diseño: si el modelo permite responder a estas preguntas de forma clara, el diseño es correcto.

## Posibles extensiones

El proyecto está preparado para evolucionar hacia:

- Automatización completa de la carga de datos desde Excel.
- Sustitución de los `.txt` por cargas directas vía scripts.
- Creación de vistas analíticas o materializadas.
- Integración con herramientas de Business Intelligence.
- Incorporación de históricos y auditoría de cambios.


## Tecnologías utilizadas

- SQL (PostgreSQL compatible)
- Python (Jupyter Notebook)
- Excel como fuente de datos
- Modelado de bases de datos relacionales
- Análisis Exploratorio de Datos (EDA)
