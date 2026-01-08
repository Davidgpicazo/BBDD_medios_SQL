# BBDD_medios_SQL

Este proyecto recoge el diseño, implementación y análisis de una base de datos relacional orientada al estudio del uso de medios en proyectos y centros.

No se trata únicamente de crear tablas y cargar datos, sino de construir un modelo coherente, normalizado y preparado para análisis, aplicando criterios propios de ingeniería de datos y analítica. El proyecto parte de datos reales en Excel, que han sido depurados y adaptados para su explotación en SQL.

## Enfoque del proyecto

He abordado este proyecto como lo haría en un entorno real:

- Primero, entendiendo el **dominio del problema**.
- Después, diseñando un **modelo relacional sólido**.
- Finalmente, validando el modelo mediante **análisis exploratorio de datos (EDA)**.

El objetivo no es solo que la base de datos funcione, sino que **permita responder preguntas relevantes** de forma consistente y escalable.


## Estructura del repositorio
├── 01.schema.sql # Definición del esquema relacional y restricciones
├── 02.data.sql # Inserción de datos (simulados a partir de datos reales)
├── 03.EDA.sql # Consultas de análisis exploratorio
├── ERD.png # Diagrama Entidad–Relación
└── README.md # Documentación del proyecto


## Modelo de datos
El modelo se basa en una separación clara entre:


### Tablas descriptivas (dimensiones)
- `medios`
- `proyectos`
- `centros`
- `suministros_medios`
- `proveedores`
- `medio_atributos`
- `categorias_medios`

Estas tablas almacenan información estable y contextual.

### Tabla de eventos (fact table)
- `uso_medios`

La tabla `uso_medios` registra cada evento de uso de un medio en un proyecto durante un intervalo temporal. Desde ella se puede analizar:

- Frecuencia de uso
- Duración
- Distribución por centro o ciudad
- Relación entre proyectos y recursos utilizados

Este enfoque evita duplicidades, mantiene una semántica clara y permite escalar el sistema añadiendo nuevas dimensiones sin necesidad de rediseñar el modelo.

El diagrama completo puede consultarse en `ERD.png`.


## Decisiones de diseño

Algunas decisiones relevantes tomadas durante el desarrollo:

- Uso de **claves artificiales** para simplificar relaciones y evitar dependencias externas.
- Definición explícita de **claves foráneas** para asegurar integridad referencial.
- Restricciones `CHECK` para evitar incoherencias temporales (por ejemplo, fechas de fin anteriores a fechas de inicio).
- Separación estricta entre entidades descriptivas y eventos medibles.
- Modelo pensado para **análisis temporal y agregaciones**, no solo para almacenamiento.

Estas decisiones priorizan la robustez del modelo y su utilidad analítica frente a soluciones más simples pero menos mantenibles.


## Análisis Exploratorio de Datos (EDA)

El archivo `03.EDA.sql` contiene consultas orientadas a validar el modelo y extraer primeros insights, como:

- Uso de medios por centro y ciudad.
- Proyectos con mayor consumo de recursos.
- Duración media y distribución temporal de los usos.
- Detección de posibles incoherencias o patrones anómalos.

El EDA se utiliza aquí como una herramienta de validación: si el modelo permite responder bien a estas preguntas, el diseño es correcto.


## Posibles extensiones

El proyecto está preparado para crecer. Algunas extensiones naturales serían:

- Automatizar la carga de datos desde Excel o CSV mediante Python.
- Crear vistas analíticas o materializadas.
- Integrar el modelo con herramientas de BI.
- Añadir auditoría de cambios o control de históricos.
- Incorporar nuevas dimensiones sin modificar la tabla de hechos.


## Tecnologías utilizadas

- SQL (compatible con PostgreSQL)
- Modelado de bases de datos relacionales
- Análisis Exploratorio de Datos (EDA)


## Autor

David Gómez Picazo  

Proyecto desarrollado como parte de un trabajo académico y como base para portfolio técnico en SQL y análisis de datos.
