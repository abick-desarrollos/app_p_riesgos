# API — ABICK Registro de No Conformidades (V2)

API mínima en Node.js para conectar la aplicación Flutter con la base de datos MySQL `app_p_riesgos`.

## Cambios V2

- Gestión de proyectos (CRUD) con control de acceso por rol.
- Los proyectos están asociados a una localidad.
- Los usuarios normales solo ven proyectos activos de su propia localidad.
- Los administradores ven y gestionan todos los proyectos.
- Al crear una no conformidad, se valida que el proyecto pertenezca a la localidad del usuario.

## Estructura del proyecto

```
api/
├── .env                  # Variables de entorno (no subir al repositorio)
├── .gitignore            # Excluye .env y archivos sensibles
├── package.json          # Dependencias y scripts
├── src/
│   ├── index.js          # Punto de entrada y router
│   └── config/
│       └── database.js   # Conexión a MySQL usando variables de entorno
└── README.md
```

## Requisitos

- Node.js 18 o superior
- Acceso a la base de datos MySQL `app_p_riesgos` en la VM de ABICK

## Instalación

```bash
cd api
npm install
```

## Configuración

Editar `.env` con las credenciales reales de la VM:

```
DB_HOST=192.168.1.82
DB_PORT=3306
DB_NAME=app_p_riesgos
DB_USER=app_riesgos
DB_PASS=tu_contraseña
JWT_SECRET=un_secreto_aleatorio_seguro
```

Las credenciales **nunca** se almacenan en el código fuente.

## Ejecución

```bash
npm run dev
```

La API quedará disponible en `http://localhost:8080`.

## Endpoints

### `GET /proyectos`

Lista los proyectos disponibles. Requiere autenticación JWT.

- **Admin**: devuelve todos los proyectos (activos e inactivos).
- **User**: devuelve solo los proyectos activos de su propia localidad.

**Headers:**

```
Authorization: Bearer <token>
```

**Ejemplo de respuesta exitosa (200):**

```json
[
  {
    "id": 1,
    "nombre": "Proyecto Prueba",
    "descripcion": "Proyecto temporal para pruebas",
    "localidad_id": 1,
    "activo": 1
  }
]
```

**Error — No autorizado (401):**

```json
{
  "error": "No autorizado",
  "message": "Se requiere un token JWT válido en el encabezado Authorization"
}
```

### `POST /proyectos`

Crea un nuevo proyecto. Requiere autenticación JWT y rol de administrador.

**Headers:**

```
Authorization: Bearer <token>
Content-Type: application/json
```

**Cuerpo de la solicitud:**

```json
{
  "nombre": "Nuevo Proyecto",
  "descripcion": "Descripción del proyecto",
  "localidad_id": 1
}
```

Campos obligatorios: `nombre`, `localidad_id`. `descripcion` es opcional.

**Ejemplo de respuesta exitosa (201):**

```json
{
  "message": "Proyecto creado exitosamente",
  "proyecto": {
    "id": 2,
    "nombre": "Nuevo Proyecto",
    "descripcion": "Descripción del proyecto",
    "localidad_id": 1,
    "activo": 1
  }
}
```

**Error — Prohibido (403):**

```json
{
  "error": "Prohibido",
  "message": "Solo los administradores pueden crear proyectos"
}
```

**Error — Datos incompletos (400):**

```json
{
  "error": "Datos incompletos",
  "message": "Los campos obligatorios son: nombre, localidad_id",
  "missing_fields": ["nombre", "localidad_id"]
}
```

**Error — Localidad no encontrada (404):**

```json
{
  "error": "Localidad no encontrada",
  "message": "No existe una localidad con id 999"
}
```

### `PUT /proyectos/:id`

Modifica un proyecto existente. Requiere autenticación JWT y rol de administrador.

**Headers:**

```
Authorization: Bearer <token>
Content-Type: application/json
```

**Cuerpo de la solicitud (todos los campos opcionales, se debe proporcionar al menos uno):**

```json
{
  "nombre": "Nombre actualizado",
  "descripcion": "Descripción actualizada",
  "localidad_id": 2,
  "activo": 0
}
```

**Ejemplo de respuesta exitosa (200):**

```json
{
  "message": "Proyecto actualizado exitosamente",
  "proyecto": {
    "id": 2,
    "nombre": "Nombre actualizado",
    "descripcion": "Descripción actualizada",
    "localidad_id": 2,
    "activo": 1
  }
}
```

**Error — Prohibido (403):**

```json
{
  "error": "Prohibido",
  "message": "Solo los administradores pueden modificar proyectos"
}
```

**Error — Proyecto no encontrado (404):**

```json
{
  "error": "Proyecto no encontrado",
  "message": "No existe un proyecto con id 999"
}
```

**Error — Localidad no encontrada (404):**

```json
{
  "error": "Localidad no encontrada",
  "message": "No existe una localidad con id 999"
}
```

### `POST /no-conformidades/:id/fotos`

Sube fotografías asociadas a una no conformidad. Requiere autenticación JWT.

**Headers:**

```
Authorization: Bearer <token>
Content-Type: multipart/form-data
```

**Body:**

Campo `foto` con el archivo de imagen (máximo 3 fotografías por NC).

**Tipos de archivo permitidos:** JPG, JPEG, PNG.

**Ejemplo de respuesta exitosa (201):**

```json
{
    "message": "Fotografía subida exitosamente",
    "fotografias": [
        "storage/fotos/1/550e8400-e29b-41d4-a716-446655440000.jpg"
    ]
}
```

**Error — No autorizado (401):**

```json
{
    "error": "No autorizado",
    "message": "Se requiere un token JWT válido en el encabezado Authorization"
}
```

**Error — No conformidad no encontrada (404):**

```json
{
    "error": "No conformidad no encontrada",
    "message": "No existe una no conformidad con id 999"
}
```

**Error — Sin archivo (400):**

```json
{
    "error": "Sin archivo",
    "message": "Se debe adjuntar al menos una fotografía en formato multipart/form-data"
}
```

**Error — Tipo de archivo no permitido (400):**

```json
{
    "error": "Tipo de archivo no permitido",
    "message": "El archivo \"foto.bmp\" tiene tipo MIME \"image/bmp\" no autorizado. Solo se permiten JPG, JPEG y PNG.",
    "tipo_archivo": "image/bmp",
    "tipos_permitidos": ["image/jpeg", "image/png"]
}
```

**Error — Extensión no permitida (400):**

```json
{
    "error": "Extensión de archivo no permitida",
    "message": "La extensión \".bmp\" del archivo \"foto.bmp\" no es válida. Solo se permiten .jpg, .jpeg y .png.",
    "extension": ".bmp",
    "extensiones_permitidas": [".jpg", ".jpeg", ".png"]
}
```

**Error — Límite de fotografías excedido (400):**

```json
{
    "error": "Límite de fotografías excedido",
    "message": "Máximo 3 fotografías por no conformidad. Ya tiene 3 y se intentaron agregar 1.",
    "limite": 3,
    "actuales": 3,
    "solicitadas": 1
}
```

### `GET /no-conformidades/:id/fotos`

Obtiene las fotografías asociadas a una no conformidad. Requiere autenticación JWT.

**Headers:**

```
Authorization: Bearer <token>
```

**Ejemplo de respuesta exitosa (200):**

```json
{
    "no_conformidad_id": 1,
    "total": 2,
    "fotografias": [
        {
            "id": 1,
            "no_conformidad_id": 1,
            "archivo_path": "storage/fotos/1/550e8400-e29b-41d4-a716-446655440000.jpg",
            "created_at": "2026-09-08T10:00:00.000Z"
        },
        {
            "id": 2,
            "no_conformidad_id": 1,
            "archivo_path": "storage/fotos/1/6ba7b810-9dad-11d1-80b4-00c04fd430c8.png",
            "created_at": "2026-09-08T10:05:00.000Z"
        }
    ]
}
```

**Error — No autorizado (401):**

```json
{
    "error": "No autorizado",
    "message": "Se requiere un token JWT válido en el encabezado Authorization"
}
```

**Error — No conformidad no encontrada (404):**

```json
{
    "error": "No conformidad no encontrada",
    "message": "No existe una no conformidad con id 999"
}
```

### `POST /no-conformidades`

Crea una nueva no conformidad. Requiere autenticación JWT.

**Headers:**

```
Authorization: Bearer <token>
Content-Type: application/json
```

**Cuerpo de la solicitud:**

```json
{
    "proyecto_id": 1,
    "tipo": "Condición insegura",
    "fecha": "2026-09-07",
    "ubicacion": "Sector B",
    "responsable": "Carlos Pérez",
    "descripcion": "Descripción de la no conformidad"
}
```

Campos obligatorios: `proyecto_id`, `tipo`, `fecha`, `descripcion`. `ubicacion` y `responsable` son opcionales.

**Ejemplo de respuesta exitosa (201):**

```json
{
    "message": "No conformidad creada exitosamente",
    "no_conformidad": {
        "id": 1,
        "numero": "NC-00001",
        "estado_id": 1,
        "estado": "NUEVA",
        "proyecto_id": 1,
        "tipo": "Condición insegura",
        "fecha": "2026-09-07",
        "ubicacion": "Sector B",
        "responsable": "Carlos Pérez",
        "descripcion": "Descripción de la no conformidad",
        "usuario_registro_id": 1,
        "created_at": "2026-09-07T10:00:00.000Z",
        "updated_at": "2026-09-07T10:00:00.000Z"
    }
}
```

**Error — No autorizado (401):**

```json
{
    "error": "No autorizado",
    "message": "Se requiere un token JWT válido en el encabezado Authorization"
}
```

**Error — Datos incompletos (400):**

```json
{
    "error": "Datos incompletos",
    "message": "Los campos obligatorios son: proyecto_id, tipo",
    "missing_fields": ["proyecto_id", "tipo"]
}
```

**Error — Proyecto no encontrado (404):**

```json
{
    "error": "Proyecto no encontrado",
    "message": "No existe un proyecto con id 999"
}
```

### `GET /ping`

Verifica que la API está funcionando y que puede conectarse a MySQL.

**Ejemplo de respuesta exitosa:**

```json
{
    "status": "ok",
    "message": "La API está funcionando",
    "database": {
        "connected": true,
        "database": "app_p_riesgos",
        "test_query_result": 1
    }
}
```

### `POST /login`

Autentica a un usuario y devuelve un token JWT.

**Cuerpo de la solicitud:**

```json
{
    "usuario": "nombre_de_usuario",
    "contrasena": "la_contraseña"
}
```

**Ejemplo de respuesta exitosa (200):**

```json
{
    "id": 1,
    "nombre": "Carlos Pérez",
    "usuario": "cperez",
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Ejemplo de respuesta con credenciales incorrectas (401):**

```json
{
    "error": "Credenciales incorrectas"
}
```

**Ejemplo de respuesta con datos incompletos (400):**

```json
{
    "error": "Datos incompletos",
    "message": "Se requieren usuario y contraseña"
}
```

## Cómo probar los endpoints

### Desde el navegador

```
http://localhost:8080/ping
```

### Desde Postman

**GET /ping:**
- Método: `GET`
- URL: `http://localhost:8080/ping`

**POST /login:**
- Método: `POST`
- URL: `http://localhost:8080/login`
- Headers: `Content-Type: application/json`
- Body (raw JSON):
  ```json
  {
      "usuario": "cperez",
      "contrasena": "la_contraseña"
  }
  ```

### Prerrequisito SQL

Antes de probar `POST /no-conformidades`, ejecutar en phpMyAdmin:

```sql
ALTER TABLE no_conformidades MODIFY COLUMN numero VARCHAR(20) NULL;
```

### Desde curl

```bash
# Ping
curl http://localhost:8080/ping

# Login (obtener token)
TOKEN=$(curl -s -X POST http://localhost:8080/login \
  -H "Content-Type: application/json" \
  -d '{"usuario":"cperez","contrasena":"la_contraseña"}' | jq -r '.token')

# Crear no conformidad (campos obligatorios: proyecto_id, tipo, fecha, descripcion)
curl -X POST http://localhost:8080/no-conformidades \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "proyecto_id": 1,
    "tipo": "Condición insegura",
    "fecha": "2026-09-07",
    "descripcion": "Descripción de la no conformidad"
  }'

# Subir fotografía a una no conformidad (máximo 3 por NC)
curl -X POST http://localhost:8080/no-conformidades/1/fotos \
  -H "Authorization: Bearer $TOKEN" \
  -F "foto=@/ruta/a/fotografia.jpg"

# Listar fotografías de una no conformidad
curl -H "Authorization: Bearer $TOKEN" http://localhost:8080/no-conformidades/1/fotos
```
