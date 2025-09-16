-- Ajusta el nombre de la BD si usas otro
	use table appdb
	
C-- Limpieza, Se eliminan los tiggers anteriores para evitar errores y su estructura inicia desde cero.
DROP TRIGGER IF EXISTS tr_docente_after_update;

-- Limpieza, Se eliminan las tablas anteriores para evitar errores y su estructura inicia desde cero.
DROP TRIGGER IF EXISTS tr_docente_after_delete;
DROP TABLE IF EXISTS copia_eliminados_docente;
DROP TABLE IF EXISTS copia_actualizados_docente;
DROP TABLE IF EXISTS proyecto;
DROP TABLE IF EXISTS docente;


-- Tablas base, Se crea una tabla llamada docente con una llave primaria que se auto incrementa ademas tiene
-- valores que no pueden ir vacios y los años de experiencia no pueden ser negativo, asi guardando la informacion 
-- personal experiencia laboral y el tipo de docente. 
CREATE TABLE docente (
  docente_id        INT AUTO_INCREMENT PRIMARY KEY,
  numero_documento  VARCHAR(20)  NOT NULL,
  nombres           VARCHAR(120) NOT NULL,
  titulo            VARCHAR(120),
  anios_experiencia INT          NOT NULL DEFAULT 0,
  direccion         VARCHAR(180),
  tipo_docente      VARCHAR(40),
  CONSTRAINT uq_docente_documento UNIQUE (numero_documento),
  CONSTRAINT ck_docente_anios CHECK (anios_experiencia >= 0)
) ENGINE=InnoDB;


-- Tablas proyecto, Se crea una tabla llamada proyecto con una llave primaria que se auto incrementa ademas tiene
-- unas relas de negocio como hora y presupuesto no deben ser negativos, tambien tiene un condicional en la fecha,
-- cada proyecto debe tener un jefe asignado y cuando se elimina un docente no se permite eliminar al proyecto donde estuvo asignado.
CREATE TABLE proyecto (
  proyecto_id      INT AUTO_INCREMENT PRIMARY KEY,
  nombre           VARCHAR(120) NOT NULL,
  descripcion      VARCHAR(400),
  fecha_inicial    DATE NOT NULL,
  fecha_final      DATE,
  presupuesto      DECIMAL(12,2) NOT NULL DEFAULT 0,
  horas            INT           NOT NULL DEFAULT 0,
  docente_id_jefe  INT NOT NULL,
  CONSTRAINT ck_proyecto_horas CHECK (horas >= 0),
  CONSTRAINT ck_proyecto_pres CHECK (presupuesto >= 0),
  CONSTRAINT ck_proyecto_fechas CHECK (fecha_final IS NULL OR fecha_final >= fecha_inicial),
  CONSTRAINT fk_proyecto_docente FOREIGN KEY (docente_id_jefe) REFERENCES docente(docente_id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- Tabla copia_actualizados_docente, Se crea una tabla llamada copia_actualizados_docente con una llave primaria que se auto incrementa cada vez que se actualiza un docente,
CREATE TABLE copia_actualizados_docente (
  auditoria_id       INT AUTO_INCREMENT PRIMARY KEY,
  docente_id         INT NOT NULL,
  numero_documento   VARCHAR(20)  NOT NULL,
  nombres            VARCHAR(120) NOT NULL,
  titulo             VARCHAR(120),
  anios_experiencia  INT          NOT NULL,
  direccion          VARCHAR(180),
  tipo_docente       VARCHAR(40),
  accion_fecha       DATETIME     NOT NULL DEFAULT (UTC_TIMESTAMP()),
  usuario_sql        VARCHAR(128) NOT NULL DEFAULT (CURRENT_USER())
) ENGINE=InnoDB;

-- Tabla copia_eliminados_docente, Se crea una tabla llamada copia_eliminados_docente con una llave primaria que se auto incrementa cada vez que se elimine un docentes.
CREATE TABLE copia_eliminados_docente (
  auditoria_id       INT AUTO_INCREMENT PRIMARY KEY,
  docente_id         INT NOT NULL,
  numero_documento   VARCHAR(20)  NOT NULL,
  nombres            VARCHAR(120) NOT NULL,
  titulo             VARCHAR(120),
  anios_experiencia  INT          NOT NULL,
  direccion          VARCHAR(180),
  tipo_docente       VARCHAR(40),
  accion_fecha       DATETIME     NOT NULL DEFAULT (UTC_TIMESTAMP()),
  usuario_sql        VARCHAR(128) NOT NULL DEFAULT (CURRENT_USER())
) ENGINE=InnoDB;

-- -- Limpieza, Se eliminan los procedure anteriores para evitar errores y su estructura inicia desde cero.
DROP PROCEDURE IF EXISTS sp_docente_crear;
DROP PROCEDURE IF EXISTS sp_docente_leer;
DROP PROCEDURE IF EXISTS sp_docente_actualizar;
DROP PROCEDURE IF EXISTS sp_docente_eliminar;


-- Permite instalar un nuevo docente y recibe datos basicos y retorna la llave primaria.
DELIMITER $$
CREATE PROCEDURE sp_docente_crear(
  IN p_numero_documento VARCHAR(20),
  IN p_nombres          VARCHAR(120),
  IN p_titulo           VARCHAR(120),
  IN p_anios_experiencia INT,
  IN p_direccion        VARCHAR(180),
  IN p_tipo_docente     VARCHAR(40)
)
BEGIN
  INSERT INTO docente (numero_documento, nombres, titulo, anios_experiencia, direccion, tipo_docente)
  VALUES (p_numero_documento, p_nombres, p_titulo, IFNULL(p_anios_experiencia,0), p_direccion, p_tipo_docente);
  SELECT LAST_INSERT_ID() AS docente_id_creado;
END$$

-- Permite consultar un docente espesifico por su llave primaria.
CREATE PROCEDURE sp_docente_leer(IN p_docente_id INT)
BEGIN
  SELECT * FROM docente WHERE docente_id = p_docente_id;
END$$

-- Actualiza  la informacion de un docente ya existente usando su llave primaria, modificando los datos requeridos y retornando el registro 
-- actualizado.
CREATE PROCEDURE sp_docente_actualizar(
  IN p_docente_id       INT,
  IN p_numero_documento VARCHAR(20),
  IN p_nombres          VARCHAR(120),
  IN p_titulo           VARCHAR(120),
  IN p_anios_experiencia INT,
  IN p_direccion        VARCHAR(180),
  IN p_tipo_docente     VARCHAR(40)
)
BEGIN
  UPDATE docente
     SET numero_documento = p_numero_documento,
         nombres = p_nombres,
         titulo = p_titulo,
         anios_experiencia = IFNULL(p_anios_experiencia,0),
         direccion = p_direccion,
         tipo_docente = p_tipo_docente
   WHERE docente_id = p_docente_id;
  SELECT * FROM docente WHERE docente_id = p_docente_id;
END$$

-- Elimina un docente de la tabla mediante su llave primaria.
CREATE PROCEDURE sp_docente_eliminar(IN p_docente_id INT)
BEGIN
  DELETE FROM docente WHERE docente_id = p_docente_id;
END$$


-- Limpieza, Se eliminan los procedure anteriores para evitar errores y su estructura inicia desde cero.
DROP PROCEDURE IF EXISTS sp_proyecto_crear;
DROP PROCEDURE IF EXISTS sp_proyecto_leer;
DROP PROCEDURE IF EXISTS sp_proyecto_actualizar;
DROP PROCEDURE IF EXISTS sp_proyecto_eliminar;


-- Inserta un nuevo proyecto relacionado con el docente jefe con los datos correspondientes de la tabla.
CREATE PROCEDURE sp_proyecto_crear(
  IN p_nombre           VARCHAR(120),
  IN p_descripcion      VARCHAR(400),
  IN p_fecha_inicial    DATE,
  IN p_fecha_final      DATE,
  IN p_presupuesto      DECIMAL(12,2),
  IN p_horas            INT,
  IN p_docente_id_jefe  INT
)
BEGIN
  INSERT INTO proyecto (nombre, descripcion, fecha_inicial, fecha_final, presupuesto, horas, docente_id_jefe)
  VALUES (p_nombre, p_descripcion, p_fecha_inicial, p_fecha_final, IFNULL(p_presupuesto,0), IFNULL(p_horas,0), p_docente_id_jefe);
  SELECT LAST_INSERT_ID() AS proyecto_id_creado;
END$$

-- Consulta la informacion de un proyecto por su llave primaria y retorna los datos del proyecto y el nombre del docente jefe.
CREATE PROCEDURE sp_proyecto_leer(IN p_proyecto_id INT)
BEGIN
  SELECT p.*, d.nombres AS nombre_docente_jefe
  FROM proyecto p
  JOIN docente d ON d.docente_id = p.docente_id_jefe
  WHERE p.proyecto_id = p_proyecto_id;
END$$

-- Permite actualizar los datos de un proyecto existente mediante su llave primaria ademas retorna los datos ya actualizados con datos 
-- del docente asociado al proyecto.
CREATE PROCEDURE sp_proyecto_actualizar(
  IN p_proyecto_id      INT,
  IN p_nombre           VARCHAR(120),
  IN p_descripcion      VARCHAR(400),
  IN p_fecha_inicial    DATE,
  IN p_fecha_final      DATE,
  IN p_presupuesto      DECIMAL(12,2),
  IN p_horas            INT,
  IN p_docente_id_jefe  INT
)
BEGIN
  UPDATE proyecto
     SET nombre = p_nombre,
         descripcion = p_descripcion,
         fecha_inicial = p_fecha_inicial,
         fecha_final = p_fecha_final,
         presupuesto = IFNULL(p_presupuesto,0),
         horas = IFNULL(p_horas,0),
         docente_id_jefe = p_docente_id_jefe
   WHERE proyecto_id = p_proyecto_id;
  CALL sp_proyecto_leer(p_proyecto_id);
END$$

-- Elimina un proyecto de la tabla usando su llave primaria.
CREATE PROCEDURE sp_proyecto_eliminar(IN p_proyecto_id INT)
BEGIN
  DELETE FROM proyecto WHERE proyecto_id = p_proyecto_id;
END$$


-- Calcula el promedio del presupuesto de todos los proyectos en que un docente es jefe de proyecto, si no tiene proyectos asignados queda en 0.
DROP FUNCTION IF EXISTS fn_promedio_presupuesto_por_docente;
CREATE FUNCTION fn_promedio_presupuesto_por_docente(p_docente_id INT)
RETURNS DECIMAL(12,2)
DETERMINISTIC
READS SQL DATA
BEGIN
  DECLARE v_prom DECIMAL(12,2);
  SELECT IFNULL(AVG(presupuesto),0) INTO v_prom
  FROM proyecto
  WHERE docente_id_jefe = p_docente_id;
  RETURN IFNULL(v_prom,0);
END$$

-- Triggers, Cada vez que se actualiza un docente se insertara una copia del nuevo registro en la tabla copia_actualizados_docente con los datos
-- mas recientes y con fecha de cambio.
CREATE TRIGGER tr_docente_after_update
AFTER UPDATE ON docente
FOR EACH ROW
BEGIN
  INSERT INTO copia_actualizados_docente
    (docente_id, numero_documento, nombres, titulo, anios_experiencia, direccion, tipo_docente)
  VALUES
    (NEW.docente_id, NEW.numero_documento, NEW.nombres, NEW.titulo, NEW.anios_experiencia, NEW.direccion, NEW.tipo_docente);
END$$

CREATE TRIGGER tr_docente_after_delete
AFTER DELETE ON docente
FOR EACH ROW
BEGIN
  INSERT INTO copia_eliminados_docente
    (docente_id, numero_documento, nombres, titulo, anios_experiencia, direccion, tipo_docente)
  VALUES
    (OLD.docente_id, OLD.numero_documento, OLD.nombres, OLD.titulo, OLD.anios_experiencia, OLD.direccion, OLD.tipo_docente);
END$$

DELIMITER ;

-- Índices, Se crea un indice sobre la columna docente_id_jefe en la tabla proyecto para optimizar las búsquedas y uniones entre proyectos y docentes.
CREATE INDEX ix_proyecto_docente ON proyecto(docente_id_jefe);

-- Índices, Se crea un indice sobre la columna numero_documento en la tabla docente para optimizar las búsquedas por documento.

CREATE INDEX ix_docente_documento ON docente(numero_documento);



------------------ Datos -------------------

-- Docentes (CREATE), Inserción de docentes usando procedimientos, se crean dos docentes con sus datos iniciales.
CALL sp_docente_crear('CC1001', 'Ana Gómez', 'MSc. Ing. Sistemas', 6, 'Cra 10 # 5-55', 'Tiempo completo');
CALL sp_docente_crear('CC1002', 'Carlos Ruiz', 'Ing. Informático', 3, 'Cll 20 # 4-10', 'Cátedra');

-- Obtener IDs, Se guardan en variables los IDs autogenerados de los docentes creados.
SET @id_ana    := (SELECT docente_id FROM docente WHERE numero_documento='CC1001');
SET @id_carlos := (SELECT docente_id FROM docente WHERE numero_documento='CC1002');

-- Proyectos (CREATE), Inserción de proyectos asociados a los docentes, cada proyecto queda vinculado a un docente jefe.
CALL sp_proyecto_crear('Plataforma Académica', 'Módulos de matrícula', '2025-01-01', NULL, 25000000, 800, @id_ana);
CALL sp_proyecto_crear('Chat Soporte TI', 'Chat universitario', '2025-02-01', '2025-06-30', 12000000, 450, @id_carlos);

-- UPDATE para disparar trigger de ACTUALIZADOS, Se modifica el nombre, título y años de experiencia de Carlos Ruiz,
-- activando el trigger de auditoría en copia_actualizados_docente.
CALL sp_docente_actualizar(@id_carlos, 'CC1002', 'Carlos A. Ruiz', 'Esp. Base de Datos', 4, 'Cll 20 # 4-10', 'Cátedra');

-- Eliminar la docente Ana: primero sus proyectos (por FK), luego docente (dispara DELETE), Primero se eliminan sus proyectos 
-- (por restricciones de llave foránea), luego se elimina a Ana Gómez, lo que activa el trigger de auditoría en copia_eliminados_docente.
DELETE FROM proyecto WHERE docente_id_jefe = @id_ana;
CALL sp_docente_eliminar(@id_ana);

-- Se crean 50 docentes para realizar pruebas.
INSERT INTO docente (numero_documento, nombres, titulo, anios_experiencia, direccion, tipo_docente) VALUES
('CC3001','Ana Pérez','MSc. Sistemas',1,'Calle 10 #1-10','Planta'),
('CC3002','Luis Gómez','Ing. Sistemas',4,'Cra 11 #2-11','Catedra'),
('CC3003','Carla Ríos','PhD. Computación',7,'Calle 12 #3-12','Planta'),
('CC3004','Juan Toro','MSc. Datos',10,'Cra 13 #4-13','Catedra'),
('CC3005','Marta López','Lic. Matemáticas',13,'Calle 14 #5-14','Planta'),
('CC3006','Pedro Ramírez','MSc. Software',16,'Cra 15 #6-15','Catedra'),
('CC3007','Lucía Hernández','PhD. Educación',19,'Calle 16 #7-16','Planta'),
('CC3008','Sergio Martínez','Esp. Analítica',22,'Cra 17 #8-17','Catedra'),
('CC3009','Elena Vargas','MSc. Estadística',25,'Calle 18 #9-18','Planta'),
('CC3010','Andrés Castro','Ing. Electrónica',3,'Cra 19 #10-19','Catedra'),
('CC3011','Paula Suárez','MSc. Sistemas',6,'Calle 20 #1-20','Planta'),
('CC3012','Diego Moreno','Ing. Sistemas',9,'Cra 21 #2-21','Catedra'),
('CC3013','Sofía Santos','PhD. Computación',12,'Calle 22 #3-22','Planta'),
('CC3014','Javier León','MSc. Datos',15,'Cra 23 #4-23','Catedra'),
('CC3015','Valeria Rodríguez','Lic. Matemáticas',18,'Calle 24 #5-24','Planta'),
('CC3016','Camilo Salazar','MSc. Software',21,'Cra 25 #6-25','Catedra'),
('CC3017','Daniela Acosta','PhD. Educación',24,'Calle 26 #7-26','Planta'),
('CC3018','Héctor Rojas','Esp. Analítica',2,'Cra 27 #8-27','Catedra'),
('CC3019','Nadia Navarro','MSc. Estadística',5,'Calle 28 #9-28','Planta'),
('CC3020','Felipe Campos','Ing. Electrónica',8,'Cra 29 #10-29','Catedra'),
('CC3021','Laura Méndez','MSc. Sistemas',11,'Calle 30 #1-30','Planta'),
('CC3022','Miguel Guerrero','Ing. Sistemas',14,'Cra 31 #2-31','Catedra'),
('CC3023','Carolina Vega','PhD. Computación',17,'Calle 32 #3-32','Planta'),
('CC3024','Tomás Lara','MSc. Datos',20,'Cra 33 #4-33','Catedra'),
('CC3025','Gabriela Romero','Lic. Matemáticas',23,'Calle 34 #5-34','Planta'),
('CC3026','Ricardo Ibarra','MSc. Software',1,'Cra 35 #6-35','Catedra'),
('CC3027','Sara Patiño','PhD. Educación',4,'Calle 36 #7-36','Planta'),
('CC3028','Mauricio Nieto','Esp. Analítica',7,'Cra 37 #8-37','Catedra'),
('CC3029','Isabel Cano','MSc. Estadística',10,'Calle 38 #9-38','Planta'),
('CC3030','Oscar Fuentes','Ing. Electrónica',13,'Cra 39 #10-39','Catedra'),
('CC3031','Verónica Pineda','MSc. Sistemas',16,'Calle 40 #1-40','Planta'),
('CC3032','Esteban Quintero','Ing. Sistemas',19,'Cra 41 #2-41','Catedra'),
('CC3033','Patricia Mejía','PhD. Computación',22,'Calle 42 #3-42','Planta'),
('CC3034','Gustavo Gutiérrez','MSc. Datos',25,'Cra 43 #4-43','Catedra'),
('CC3035','Mariana Serrano','Lic. Matemáticas',3,'Calle 44 #5-44','Planta'),
('CC3036','Roberto Ortega','MSc. Software',6,'Cra 45 #6-45','Catedra'),
('CC3037','Natalia Paz','PhD. Educación',9,'Calle 46 #7-46','Planta'),
('CC3038','Iván Barrios','Esp. Analítica',12,'Cra 47 #8-47','Catedra'),
('CC3039','Claudia Miranda','MSc. Estadística',15,'Calle 48 #9-48','Planta'),
('CC3040','Edgar Valdez','Ing. Electrónica',18,'Cra 49 #10-49','Catedra'),
('CC3041','Gloria Delgado','MSc. Sistemas',21,'Calle 50 #1-50','Planta'),
('CC3042','Víctor Aguilar','Ing. Sistemas',24,'Cra 51 #2-51','Catedra'),
('CC3043','Diana Córdoba','PhD. Computación',2,'Calle 52 #3-52','Planta'),
('CC3044','César Fajardo','MSc. Datos',5,'Cra 53 #4-53','Catedra'),
('CC3045','Rocío Forero','Lic. Matemáticas',8,'Calle 54 #5-54','Planta'),
('CC3046','Julio Cárdenas','MSc. Software',11,'Cra 55 #6-55','Catedra'),
('CC3047','Noelia Blanco','PhD. Educación',14,'Calle 56 #7-56','Planta'),
('CC3048','Emilio Bravo','Esp. Analítica',17,'Cra 57 #8-57','Catedra'),
('CC3049','Fabián Cortés','MSc. Estadística',20,'Calle 58 #9-58','Planta'),
('CC3050','Pilar Mora','Ing. Electrónica',23,'Cra 59 #10-59','Catedra');


-- Se crean 1 a 20 proyectos, cada uno asignado a un docente distinto.
INSERT INTO proyecto (nombre, descripcion, fecha_inicial, fecha_final, presupuesto, horas, docente_id_jefe) VALUES
('Actualización Curricular de Ingeniería 01','Revisión y modernización de sílabos con enfoque por competencias','2023-01-15',NULL,28000.00,120,1),
('Laboratorio de Robótica Educativa 02','Implementación de kits y guías para prácticas en robótica móvil','2023-01-29','2023-09-10',32000.00,140,2),
('Semillero de Investigación en IA 03','Formación de estudiantes en proyectos de IA aplicada a la educación','2023-02-12',NULL,36000.00,160,3),
('Acreditación de Programa 04','Preparación de evidencias y informes para acreditación nacional','2023-02-26','2023-11-20',41000.00,180,4),
('Talleres de Pensamiento Computacional 05','Ciclo de talleres para escuela y pregrado con evaluación de impacto','2023-03-12',NULL,45000.00,150,5),
('Repositorio de Recursos Abiertos 06','Diseño de un OER institucional con licencias abiertas','2023-03-26','2023-10-30',38000.00,140,6),
('Clínica de Datos 07','Acompañamiento metodológico a proyectos de investigación estudiantil','2023-04-09',NULL,52000.00,200,7),
('Evaluación de Aprendizajes 08','Diseño de rúbricas y bancos de ítems para cursos troncales','2023-04-23','2023-12-05',33000.00,120,8),
('Diplomado en Analítica Educativa 09','Programa de extensión con enfoque en tablero de indicadores','2023-05-07',NULL,59000.00,220,9),
('Vinculación con el Medio 10','Alianzas con colegios para proyectos de aula con tutorías','2023-05-21','2023-12-15',30000.00,110,10),
('Centro de Escritura Académica 11','Creación de tutorías y materiales para redactar artículos científicos','2023-06-04',NULL,64000.00,230,11),
('Aula Híbrida Piloto 12','Implementación de tecnologías para enseñanza síncrona/asincrónica','2023-06-18','2024-01-20',70000.00,260,12),
('Club de Ciberseguridad 13','Formación extracurricular con retos de captura la bandera','2023-07-02',NULL,42000.00,160,13),
('MOOC de Introducción a la Programación 14','Producción de curso masivo abierto con evaluación automática','2023-07-16','2024-02-15',88000.00,300,14),
('Biblioteca de Casos 15','Colección de estudios de caso locales para cursos de proyectos','2023-07-30',NULL,41000.00,150,15),
('Observatorio de Empleabilidad 16','Levantamiento y análisis de datos de egresados','2023-08-13','2024-03-01',62000.00,210,16),
('Seminario Permanente de Investigación 17','Ciclo de charlas con investigadores invitados','2023-08-27',NULL,35000.00,140,17),
('Certificación Docente Interna 18','Ruta de microcredenciales para docencia universitaria','2023-09-10','2024-03-20',54000.00,190,18),
('Feria de Proyectos Integradores 19','Evento anual de exposición y evaluación por pares','2023-09-24',NULL,37000.00,130,19),
('Rediseño de Laboratorios de Redes 20','Actualización de equipos y guías de prácticas','2023-10-08','2024-04-18',96000.00,320,20);

-- Se crean 21 a 40 proyectos, cada uno asignado a un docente distinto.
INSERT INTO proyecto (nombre, descripcion, fecha_inicial, fecha_final, presupuesto, horas, docente_id_jefe) VALUES
('Programa de Mentorías 21','Mentoría entre egresados y estudiantes de últimos semestres','2023-10-22',NULL,42000.00,150,21),
('Currículo STEM Escolar 22','Diseño de mallas curriculares STEM para colegios aliados','2023-11-05','2024-05-25',78000.00,260,22),
('Archivo de Datos Abiertos 23','Publicación y catalogación de datasets académicos','2023-11-19',NULL,47000.00,170,23),
('Aula Inclusiva y Accesibilidad 24','Adaptaciones de contenidos y evaluación accesible','2023-12-03','2024-06-10',52000.00,180,24),
('Líneas de Investigación Institucional 25','Definición y planificación de líneas prioritarias','2023-12-17',NULL,40000.00,140,25),
('Laboratorio de IoT Educativo 26','Montaje de sensores y pasarelas para proyectos de aula','2023-12-31','2024-07-05',99000.00,340,26),
('Competencias Digitales Docentes 27','Capacitaciones en herramientas y buenas prácticas','2024-01-14',NULL,36000.00,130,27),
('Hackatón Académica 28','Maratón de soluciones con desafíos interdisciplinarios','2024-01-28','2024-08-08',45000.00,160,28),
('Semillero de Ciencia de Datos 29','Proyectos guiados con datasets institucionales','2024-02-11',NULL,68000.00,220,29),
('Plan Lector Académico 30','Clubes de lectura científica y reseñas críticas','2024-02-25','2024-09-12',26000.00,100,30),
('Diplomado en Docencia Universitaria 31','Formación por competencias y evaluación auténtica','2024-03-10',NULL,75000.00,240,31),
('Mapa de Procesos Académicos 32','Modelado BPM de procesos de docencia e investigación','2024-03-24','2024-10-05',52000.00,180,32),
('Laboratorio de Innovación Social 33','Proyectos con comunidades para transferencia de conocimiento','2024-04-07',NULL,70000.00,230,33),
('Simulador de Redes 34','Desarrollo de entorno de prácticas virtuales','2024-04-21','2024-11-02',83000.00,270,34),
('Titulación por Proyectos 35','Implementación de modalidad de grado basada en proyectos','2024-05-05',NULL,62000.00,210,35),
('Revista Estudiantil Arbitrada 36','Lanzamiento y gestión editorial de revista indexada','2024-05-19','2024-12-03',91000.00,300,36),
('Aula de Realidad Aumentada 37','Diseño de objetos de aprendizaje inmersivos','2024-06-02',NULL,84000.00,280,37),
('Programa de Servicio Social 38','Prácticas académicas con impacto en la comunidad','2024-06-16','2025-01-12',56000.00,190,38),
('Seminario de Ética en Investigación 39','Formación en integridad científica y buenas prácticas','2024-06-30',NULL,30000.00,110,39),
('Centro de Tutorías en Cálculo 40','Apoyo intensivo para cursos de ciencias básicas','2024-07-14','2025-02-10',48000.00,170,40);

-- Se crean 41 a 60 proyectos, cada uno asignado a un docente distinto.
INSERT INTO proyecto (nombre, descripcion, fecha_inicial, fecha_final, presupuesto, horas, docente_id_jefe) VALUES
('Alfabetización de Datos 41','Curso institucional de cultura y visualización de datos','2024-07-28',NULL,52000.00,180,41),
('Programa de Movilidad Estudiantil 42','Convenios y becas para intercambios académicos','2024-08-11','2025-03-08',105000.00,340,42),
('Observatorio de Calidad 43','Indicadores para seguimiento de resultados de aprendizaje','2024-08-25',NULL,64000.00,220,43),
('Semillero de Cómputo Científico 44','Proyectos HPC para simulación y análisis numérico','2024-09-08','2025-04-05',115000.00,360,44),
('Red de Laboratorios Remotos 45','Acceso remoto a equipos para prácticas de laboratorio','2024-09-22',NULL,98000.00,300,45),
('Certificaciones Profesionales 46','Ruta Cisco/AWS/Oracle alineada al currículo','2024-10-06','2025-05-03',94000.00,280,46),
('Observatorio de Deserción 47','Modelos predictivos y acciones de retención estudiantil','2024-10-20',NULL,72000.00,240,47),
('Fondo de Semilleros 48','Financiación de proyectos estudiantiles competitivos','2024-11-03','2025-05-31',88000.00,290,48),
('Ecosistema de Mentoría Femenina 49','Impulso a vocaciones STEM en mujeres','2024-11-17',NULL,46000.00,160,49),
('Programa de Internacionalización 50','Estrategia de dobles titulaciones y publicaciones conjuntas','2024-12-01','2025-06-19',132000.00,380,50),
('Clúster de Computación 51','Adquisición y puesta a punto de clúster académico','2025-01-12',NULL,200000.00,520,10),
('Iniciativa de Aprendizaje Servicio 52','Integración de proyectos con necesidades del entorno','2025-01-26',NULL,57000.00,190,5),
('Cátedra de Emprendimiento 53','Ecosistema de innovación y prototipado rápido','2025-02-09','2025-08-25',76000.00,250,18),
('Laboratorio de Fabricación Digital 54','Implementación de impresoras 3D y corte láser','2025-02-23',NULL,112000.00,340,22),
('Aula Verde 55','Proyectos de sostenibilidad y eficiencia energética','2025-03-09','2025-09-30',68000.00,220,31),
('Programa de Bilingüismo Académico 56','Fortalecimiento de lectura y escritura en inglés técnico','2025-03-23',NULL,49000.00,170,7),
('Repositorio de Tesis y Datos 57','Plataforma de preservación y citación de investigaciones','2025-04-06','2025-10-28',74000.00,240,14),
('Ciclo de Seminarios de Frontera 58','Invitados internacionales en áreas emergentes','2025-04-20',NULL,53000.00,180,28),
('Aula de Computación en la Nube 59','Laboratorios con cuentas educativas y sandbox seguro','2025-05-04','2025-11-16',99000.00,300,33),
('Centro de Innovación Pedagógica 60','I+D en metodologías activas y evaluación auténtica','2025-05-18',NULL,120000.00,320,40);



-- Q0: Se crea y usa la base de datos si no existe, no devuelve ningun resultado visible.
CREATE DATABASE IF NOT EXISTS proyectos_informaticos;
USE proyectos_informaticos;

-- Q1: Se enlista el proyectos y su docente jefe con un innner join devolviendo cada proyecto junto con el docente
-- esto facilita ver quien esta en cada proyecto.
SELECT p.proyecto_id, p.nombre AS proyecto, d.nombres AS docente_jefe
FROM proyecto p
JOIN docente d ON d.docente_id = p.docente_id_jefe;

-- Q2: Promedio de presupuesto por docente (UDF), Para cada docente llama a esta funcion y muestra el promedio del presupuesto de los proyectos.
-- Si la funcion devuelve 0 el docente  no esta vinculado a ningun proyecto.
SELECT d.docente_id, d.nombres,
       fn_promedio_presupuesto_por_docente(d.docente_id) AS promedio_presupuesto
FROM docente d;

-- Q3: Verificar trigger UPDATE (auditoría), Muestra las 10 entradas mas recientes de la tabla de auditoria que registra las actualizaciones del docente
SELECT * FROM copia_actualizados_docente
ORDER BY auditoria_id DESC
LIMIT 10;

-- Q4: Verificar trigger DELETE (auditoría), Muestra las 10 entradas mas recientes que registran eliminaciones de los docentes, devolviendo las mismas columnas 
-- tipo auditorias que la tabla actualizados.
SELECT * FROM copia_eliminados_docente
ORDER BY auditoria_id DESC
LIMIT 10;

-- Q5: Validar CHECKs, Devuelve los rpoyectos que cumplen las reglas basicas ( fecha finasl valida), presupuesto y horas, pasan solo los que cumplem
-- con las validaciones.
SELECT proyecto_id, nombre, fecha_inicial, fecha_final, presupuesto, horas
FROM proyecto
WHERE (fecha_final IS NULL OR fecha_final >= fecha_inicial)
  AND presupuesto >= 0
  AND horas >= 0;

-- Q6: Docentes con sus proyectos, Lista cada docentes y si tiene cada proyecto que lidera, usa left join para incluir docentes sin proyecto,
 -- devolviendo una fila por cada proyecto que tenga el docente, si no tienen proyectos aparecen las columnas como null.
SELECT d.docente_id, d.nombres, p.proyecto_id, p.nombre
FROM docente d
LEFT JOIN proyecto p ON d.docente_id = p.docente_id_jefe
ORDER BY d.docente_id;

-- Q7: Total de horas por docente, suma las horas de los proyectos por cada docente con un left join asegurando incluir docentes sin proyectos,
-- devolviendo el total de horas asignadas a cada docentes tambien puede devolver un null a los docentes que no tienen proyecto. 
SELECT d.docente_id, d.nombres, SUM(p.horas) AS total_horas
FROM docente d
LEFT JOIN proyecto p ON d.docente_id = p.docente_id_jefe
GROUP BY d.docente_id, d.nombres;

-- Q8: Inserciones vía procedimientos, Crea docentes usando los procedimientos y luego usa las llaves primarias para crear proyectos 
-- asignados a cada docente.
CALL sp_docente_crear('CC1001', 'Ana Gómez', 'MSc. Ing. Sistemas', 6, 'Cra 10 # 5-55', 'Tiempo completo');
CALL sp_docente_crear('CC1002', 'Carlos Ruiz', 'Ing. Informático', 3, 'Cll 20 # 4-10', 'Cátedra');
SET @id_ana    := (SELECT docente_id FROM docente WHERE numero_documento='CC1001');
SET @id_carlos := (SELECT docente_id FROM docente WHERE numero_documento='CC1002');
CALL sp_proyecto_crear('Plataforma Académica', 'Módulos de matrícula', '2025-01-01', NULL, 25000000, 800, @id_ana);
CALL sp_proyecto_crear('Chat Soporte TI', 'Chat universitario', '2025-02-01', '2025-06-30', 12000000, 450, @id_carlos);

-- Q9: Inserciones directas (opcional), Inserta directamente un docente y luego un proyecto usando select para obtener el docente por su llave primaria, 
-- los inser no devuelven filas, pero añaden registos, simpre confirmar que el docente exista.
INSERT INTO docente (numero_documento, nombres, titulo, anios_experiencia, direccion, tipo_docente)
VALUES ('CC2001','María López','Esp. Gestión de Proyectos',7,'Av. Siempre Viva 742','Cátedra');
INSERT INTO proyecto (nombre, descripcion, fecha_inicial, fecha_final, presupuesto, horas, docente_id_jefe)
VALUES ('App Biblioteca','App móvil de préstamos','2025-03-01',NULL, 9000000, 320,
        (SELECT docente_id FROM docente WHERE numero_documento='CC2001'));
