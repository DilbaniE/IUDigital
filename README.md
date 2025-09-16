# 📊 Proyecto de Gestión de Proyectos Informáticos

Este proyecto implementa un modelo de base de datos en **MySQL 8** aplicando las tres primeras formas normales.  
Incluye tablas principales, auditoría mediante **triggers**, procedimientos almacenados y funciones para consultas avanzadas.

---

## 🚀 Requisitos

- [Docker](https://www.docker.com/) instalado en tu sistema.
- Cliente MySQL (Workbench, DBeaver o terminal).
- JDK si deseas conectar la base de datos desde una aplicación Java.

---

## 🐳 Levantar MySQL con Docker

Para comprobar si ya tienes un contenedor corriendo:

```cmd
docker ps
Este es el comando para levantar el contenedor de MySQL:
⚠️ Cambia el puerto y el nombre del contenedor si ya tienes otro en uso, para evitar errores.

cmd
Copiar código
docker run -d --name mysql8 \
  -e MYSQL_ROOT_PASSWORD=1234 \
  -e MYSQL_DATABASE=appdb \
  -p 3307:3306 \
  mysql:8.0
Esto levantará MySQL 8 en el puerto 3307 y creará la base de datos inicial appdb.
---

🔑 Conexión JDBC
Si al conectar pide la llave pública 🗝️, agrega los parámetros en la URL de conexión y cambia el nombre de la base de datos a la que estés usando (proyectos_informaticos):

cmd
Copiar código
jdbc:mysql://localhost:3307/proyectos_informaticos?allowPublicKeyRetrieval=true&useSSL=false&serverTimezone=UTC

--- 
📂 Estructura del proyecto
🗄️ Tablas principales
docente → información personal y laboral de los docentes.

proyecto → información de proyectos con restricciones de negocio.

📝 Tablas de auditoría
copia_actualizados_docente → guarda registros cada vez que un docente es actualizado.

copia_eliminados_docente → guarda registros cada vez que un docente es eliminado.

⚙️ Procedimientos almacenados
sp_docente_crear → inserta un nuevo docente.

sp_proyecto_crear → inserta un nuevo proyecto asignado a un docente.

📐 Funciones
fn_promedio_presupuesto_por_docente → calcula el promedio de presupuesto de los proyectos de un docente.

🔔 Triggers
tr_docente_after_update → registra cambios al actualizar un docente.

tr_docente_after_delete → registra cambios al eliminar un docente.

---

📋 Ejemplos de consultas
📌 Listar proyectos y su docente jefe:

sql
Copiar código
SELECT p.proyecto_id, p.nombre AS proyecto, d.nombres AS docente_jefe
FROM proyecto p
JOIN docente d ON d.docente_id = p.docente_id_jefe;
📌 Promedio de presupuesto por docente:

sql
Copiar código
SELECT d.docente_id, d.nombres,
       fn_promedio_presupuesto_por_docente(d.docente_id) AS promedio_presupuesto
FROM docente d;
📌 Ver últimos docentes actualizados:


sql
Copiar código
SELECT * FROM copia_actualizados_docente
ORDER BY auditoria_id DESC
LIMIT 10;
📌 Ver últimos docentes eliminados:

sql
Copiar código
SELECT * FROM copia_eliminados_docente
ORDER BY auditoria_id DESC
LIMIT 10;
