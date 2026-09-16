const http = require('http');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const busboy = require('busboy');
const path = require('path');
const fs = require('fs');
const crypto = require('crypto');
require('dotenv').config({ path: require('path').resolve(__dirname, '..', '.env') });

const { getDbConnection } = require('./config/database');

// ---- Storage configuration ----
const STORAGE_DIR = path.resolve(__dirname, '..', 'storage', 'fotos');
const MAX_FOTOS_PER_NC = 3;
const ALLOWED_MIME_TYPES = ['image/jpeg', 'image/png'];
const ALLOWED_EXTENSIONS = ['.jpg', '.jpeg', '.png'];

const HOST = process.env.API_HOST || '0.0.0.0';
const PORT = parseInt(process.env.API_PORT || '8000', 10);
const JWT_SECRET = process.env.JWT_SECRET;

const server = http.createServer(async (req, res) => {
  const url = new URL(req.url, `http://${req.headers.host}`);
  const pathname = url.pathname;
  const method = req.method;

  res.setHeader('Content-Type', 'application/json; charset=utf-8');

  // ---- GET /ping ----
  if (pathname === '/ping' && method === 'GET') {
    await handlePing(res);
    return;
  }

  // ---- POST /login ----
  if (pathname === '/login' && method === 'POST') {
    await handleLogin(req, res);
    return;
  }

  // ---- POST /no-conformidades ----
  if (pathname === '/no-conformidades' && method === 'POST') {
    await handleCreateNoConformidad(req, res);
    return;
  }

  // ---- GET /proyectos ----
  if (pathname === '/proyectos' && method === 'GET') {
    await handleGetProyectos(req, res);
    return;
  }

  // ---- POST /proyectos ----
  if (pathname === '/proyectos' && method === 'POST') {
    await handleCreateProyecto(req, res);
    return;
  }

  // ---- PUT /proyectos/:id ----
  const proyectoMatch = pathname.match(/^\/proyectos\/(\d+)$/);
  if (proyectoMatch && method === 'PUT') {
    await handleUpdateProyecto(req, res, proyectoMatch[1]);
    return;
  }

  // ---- GET /localidades ----
  if (pathname === '/localidades' && method === 'GET') {
    await handleGetLocalidades(req, res);
    return;
  }

  // ---- GET /no-conformidades ----
  if (pathname === '/no-conformidades' && method === 'GET') {
    await handleGetNoConformidades(req, res);
    return;
  }

  // ---- PUT /no-conformidades/:id/estado ----
  const ncEstadoMatch = pathname.match(/^\/no-conformidades\/(\d+)\/estado$/);
  if (ncEstadoMatch && method === 'PUT') {
    await handleUpdateNoConformidadEstado(req, res, ncEstadoMatch[1]);
    return;
  }

  // ---- GET /no-conformidades/:id ----
  const ncMatch = pathname.match(/^\/no-conformidades\/(\d+)$/);
  if (ncMatch && method === 'GET') {
    await handleGetNoConformidadById(req, res, ncMatch[1]);
    return;
  }

  // ---- POST /no-conformidades/:id/fotos ----
  const ncFotosPostMatch = pathname.match(/^\/no-conformidades\/(\d+)\/fotos$/);
  if (ncFotosPostMatch && method === 'POST') {
    await handleUploadFotos(req, res, ncFotosPostMatch[1]);
    return;
  }

  // ---- GET /no-conformidades/:id/fotos ----
  const ncFotosGetMatch = pathname.match(/^\/no-conformidades\/(\d+)\/fotos$/);
  if (ncFotosGetMatch && method === 'GET') {
    await handleGetFotos(req, res, ncFotosGetMatch[1]);
    return;
  }

  // ---- GET /storage/fotos/:ncId/:filename (servir archivos estáticos) ----
  const storageMatch = pathname.match(/^\/storage\/fotos\/(\d+)\/(.+)$/);
  if (storageMatch && method === 'GET') {
    const ncId = storageMatch[1];
    const filename = storageMatch[2];
    const filePath = path.join(STORAGE_DIR, ncId, filename);

    // Prevenir acceso fuera de storage/fotos (path traversal)
    const resolved = path.resolve(filePath);
    const allowed = path.resolve(STORAGE_DIR);
    if (!resolved.startsWith(allowed + path.sep) && resolved !== allowed) {
      res.writeHead(403);
      res.end(JSON.stringify({ error: 'Acceso denegado' }));
      return;
    }

    if (!fs.existsSync(filePath) || !fs.statSync(filePath).isFile()) {
      res.writeHead(404);
      res.end(JSON.stringify({ error: 'Archivo no encontrado' }));
      return;
    }

    const ext = path.extname(filePath).toLowerCase();
    const contentType = ext === '.png' ? 'image/png' : 'image/jpeg';
    res.writeHead(200, { 'Content-Type': contentType });
    fs.createReadStream(filePath).pipe(res);
    return;
  }

  // ---- 404 ----
  res.writeHead(404);
  res.end(JSON.stringify({
    error: 'Ruta no encontrada',
    available_endpoints: {
      'GET /ping': 'Verificar que la API está funcionando y conectada a MySQL',
      'POST /login': 'Autenticación de usuario',
      'GET /proyectos': 'Listar proyectos (requiere JWT, admin ve todos, user solo su localidad)',
      'POST /proyectos': 'Crear proyecto (requiere JWT, solo admin)',
      'PUT /proyectos/:id': 'Modificar proyecto (requiere JWT, solo admin)',
      'GET /localidades': 'Listar localidades (requiere JWT, solo admin)',
      'POST /no-conformidades': 'Crear una nueva no conformidad (requiere JWT)',
      'GET /no-conformidades': 'Listar no conformidades (requiere JWT)',
      'GET /no-conformidades/:id': 'Obtener detalle de una no conformidad (requiere JWT)',
      'PUT /no-conformidades/:id/estado': 'Cambiar estado de una no conformidad (requiere JWT)',
      'POST /no-conformidades/:id/fotos': 'Subir fotografías a una no conformidad (requiere JWT, multipart/form-data)',
      'GET /no-conformidades/:id/fotos': 'Obtener fotografías de una no conformidad (requiere JWT)',
      'GET /storage/fotos/:ncId/:filename': 'Servir archivo de fotografía (público)',
    }
  }, null, 2));
});

// ---- Helpers ----

async function readRequestBody(req) {
  return new Promise((resolve, reject) => {
    let body = '';
    req.on('data', chunk => { body += chunk; });
    req.on('end', () => resolve(body));
    req.on('error', reject);
  });
}

function sendJson(res, statusCode, data) {
  res.writeHead(statusCode);
  res.end(JSON.stringify(data, null, 2));
}

function verifyToken(req) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return null;
  }
  const token = authHeader.substring(7);
  try {
    return jwt.verify(token, JWT_SECRET);
  } catch (err) {
    return null;
  }
}

// ---- Helpers ----

function isAdmin(user) {
  return user && user.rol === 'admin';
}

async function getNoConformidadLocalidad(conn, ncId) {
  const [rows] = await conn.execute(
    'SELECT localidad_id FROM no_conformidades WHERE id = ?',
    [ncId]
  );
  if (rows.length === 0) return null;
  return rows[0].localidad_id;
}

async function checkLocalidadAccess(req, res, ncId) {
  const user = verifyToken(req);
  if (!user) {
    sendJson(res, 401, {
      error: 'No autorizado',
      message: 'Se requiere un token JWT válido en el encabezado Authorization',
    });
    return null;
  }
  if (isAdmin(user)) return true;

  const conn = await getDbConnection();
  const ncLocalidad = await getNoConformidadLocalidad(conn, ncId);
  await conn.end();

  if (ncLocalidad === null) {
    sendJson(res, 404, {
      error: 'No conformidad no encontrada',
      message: `No existe una no conformidad con id ${ncId}`,
    });
    return null;
  }

  if (ncLocalidad !== user.localidad_id) {
    sendJson(res, 404, {
      error: 'No conformidad no encontrada',
      message: `No existe una no conformidad con id ${ncId}`,
    });
    return null;
  }

  return true;
}

// ---- Handlers ----

async function handlePing(res) {
  const response = {
    status: 'ok',
    message: 'La API está funcionando',
  };

  try {
    const conn = await getDbConnection();
    const [rows] = await conn.query('SELECT 1 AS test');

    response.database = {
      connected: true,
      database: process.env.DB_NAME,
      test_query_result: rows[0].test,
    };

    await conn.end();
  } catch (err) {
    response.database = {
      connected: false,
      error: err.message,
    };
    res.writeHead(503);
  }

  res.end(JSON.stringify(response, null, 2));
}

async function handleLogin(req, res) {
  try {
    const rawBody = await readRequestBody(req);
    const body = JSON.parse(rawBody);

    const { usuario, contrasena } = body;

    // Validar entradas
    if (!usuario || !contrasena) {
      return sendJson(res, 400, {
        error: 'Datos incompletos',
        message: 'Se requieren usuario y contraseña',
      });
    }

    // Buscar usuario en la base de datos con JOIN a localidades
    const conn = await getDbConnection();
    const [rows] = await conn.execute(
      `SELECT u.id, u.nombre, u.usuario, u.contrasena_hash, u.rol, u.localidad_id,
              l.nombre AS localidad_nombre
       FROM usuarios u
       JOIN localidades l ON u.localidad_id = l.id
       WHERE u.usuario = ?`,
      [usuario]
    );
    await conn.end();

    if (rows.length === 0) {
      return sendJson(res, 401, {
        error: 'Credenciales incorrectas',
      });
    }

    const user = rows[0];

    // Verificar contraseña
    const passwordValid = await bcrypt.compare(contrasena, user.contrasena_hash);

    if (!passwordValid) {
      return sendJson(res, 401, {
        error: 'Credenciales incorrectas',
      });
    }

    // Generar token JWT
    const token = jwt.sign(
      { id: user.id, usuario: user.usuario, rol: user.rol, localidad_id: user.localidad_id, localidad_nombre: user.localidad_nombre },
      JWT_SECRET,
      { expiresIn: '24h' }
    );

    // Devolver datos del usuario sin exponer hash ni contraseña
    sendJson(res, 200, {
      id: user.id,
      nombre: user.nombre,
      usuario: user.usuario,
      rol: user.rol,
      localidad_id: user.localidad_id,
      localidad_nombre: user.localidad_nombre,
      token,
    });
  } catch (err) {
    if (err instanceof SyntaxError && err.status === 400) {
      return sendJson(res, 400, {
        error: 'Cuerpo de la solicitud inválido',
        message: 'El cuerpo debe ser JSON válido',
      });
    }
    sendJson(res, 500, {
      error: 'Error interno del servidor',
    });
  }
}

async function handleCreateNoConformidad(req, res) {
  try {
    const user = verifyToken(req);

    if (!user) {
      return sendJson(res, 401, {
        error: 'No autorizado',
        message: 'Se requiere un token JWT válido en el encabezado Authorization',
      });
    }

    const rawBody = await readRequestBody(req);
    const body = JSON.parse(rawBody);

    const { titulo, proyecto_id, tipo, fecha, ubicacion, responsable, descripcion } = body;

    // Validar campos obligatorios
    const missingFields = [];
    if (!titulo) missingFields.push('titulo');
    if (proyecto_id == null) missingFields.push('proyecto_id');
    if (!tipo) missingFields.push('tipo');
    if (!fecha) missingFields.push('fecha');
    if (!descripcion) missingFields.push('descripcion');

    if (missingFields.length > 0) {
      return sendJson(res, 400, {
        error: 'Datos incompletos',
        message: `Los campos obligatorios son: ${missingFields.join(', ')}`,
        missing_fields: missingFields,
      });
    }

    if (titulo.length > 150) {
      return sendJson(res, 400, {
        error: 'Título demasiado largo',
        message: 'El título no puede superar los 150 caracteres',
      });
    }

    const conn = await getDbConnection();

    try {
      await conn.beginTransaction();

      // Verificar que el proyecto existe
      const [projectRows] = await conn.execute(
        'SELECT id, localidad_id, activo FROM proyectos WHERE id = ?',
        [proyecto_id]
      );

      if (projectRows.length === 0) {
        await conn.rollback();
        await conn.end();
        return sendJson(res, 404, {
          error: 'Proyecto no encontrado',
          message: `No existe un proyecto con id ${proyecto_id}`,
        });
      }

      // Validar que el proyecto pertenece a la localidad del usuario
      const proyectoLocalidadId = projectRows[0].localidad_id;

      if (!isAdmin(user) && proyectoLocalidadId !== user.localidad_id) {
        await conn.rollback();
        await conn.end();
        return sendJson(res, 404, {
          error: 'Proyecto no encontrado',
          message: `No existe un proyecto con id ${proyecto_id}`,
        });
      }

      // Validar que el proyecto está activo
      if (!projectRows[0].activo) {
        await conn.rollback();
        await conn.end();
        return sendJson(res, 400, {
          error: 'Proyecto inactivo',
          message: `No se puede crear una no conformidad en un proyecto inactivo`,
        });
      }

      // Obtener el id del estado NUEVA
      const [estadoRows] = await conn.execute(
        'SELECT id FROM estados WHERE nombre = ?',
        ['NUEVA']
      );

      if (estadoRows.length === 0) {
        await conn.rollback();
        await conn.end();
        return sendJson(res, 500, {
          error: 'Estado NUEVA no configurado',
          message: 'No se encontró el estado NUEVA en la tabla estados',
        });
      }

      const estadoId = estadoRows[0].id;

      // Insertar la NC con numero = NULL (el número se genera después del INSERT, usando el AUTO_INCREMENT id)
      const [result] = await conn.execute(
        `INSERT INTO no_conformidades
          (numero, titulo, proyecto_id, tipo, fecha, ubicacion, responsable, descripcion, estado_id, usuario_registro_id, localidad_id)
         VALUES (NULL, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        [titulo, proyecto_id, tipo, fecha, ubicacion || null, responsable || null, descripcion, estadoId, user.id, user.localidad_id]
      );

      // Generar el número NC-XXXXX a partir del id auto-generado
      const numero = `NC-${String(result.insertId).padStart(5, '0')}`;

      // Actualizar la fila con el número generado
      await conn.execute(
        'UPDATE no_conformidades SET numero = ? WHERE id = ?',
        [numero, result.insertId]
      );

      // Devolver la NC creada con JOIN a estados
      const [createdRows] = await conn.execute(
        `SELECT nc.id, nc.numero, nc.titulo, nc.estado_id, e.nombre AS estado,
                nc.proyecto_id, nc.tipo, nc.fecha, nc.ubicacion,
                nc.responsable, nc.descripcion, nc.usuario_registro_id,
                nc.localidad_id, nc.created_at, nc.updated_at
         FROM no_conformidades nc
         JOIN estados e ON nc.estado_id = e.id
         WHERE nc.id = ?`,
        [result.insertId]
      );

      await conn.commit();
      await conn.end();

      sendJson(res, 201, {
        message: 'No conformidad creada exitosamente',
        no_conformidad: createdRows[0],
      });
    } catch (err) {
      try { await conn.rollback(); } catch (_) {}
      try { await conn.end(); } catch (_) {}
      throw err;
    }
  } catch (err) {
    if (err instanceof SyntaxError) {
      return sendJson(res, 400, {
        error: 'Cuerpo de la solicitud inválido',
        message: 'El cuerpo debe ser JSON válido',
      });
    }
    sendJson(res, 500, {
      error: 'Error interno del servidor',
      message: err.message,
    });
  }
}

async function handleGetProyectos(req, res) {
  const user = verifyToken(req);

  if (!user) {
    return sendJson(res, 401, {
      error: 'No autorizado',
      message: 'Se requiere un token JWT válido en el encabezado Authorization',
    });
  }

  try {
    const conn = await getDbConnection();

    if (isAdmin(user)) {
      const [rows] = await conn.execute(
        'SELECT id, nombre, descripcion, localidad_id, activo FROM proyectos ORDER BY nombre ASC'
      );
      await conn.end();
      return sendJson(res, 200, rows);
    }

    const [rows] = await conn.execute(
      'SELECT id, nombre, descripcion, localidad_id, activo FROM proyectos WHERE activo = 1 AND localidad_id = ? ORDER BY nombre ASC',
      [user.localidad_id]
    );
    await conn.end();

    sendJson(res, 200, rows);
  } catch (err) {
    sendJson(res, 500, {
      error: 'Error interno del servidor',
      message: err.message,
    });
  }
}

async function handleCreateProyecto(req, res) {
  const user = verifyToken(req);

  if (!user) {
    return sendJson(res, 401, {
      error: 'No autorizado',
      message: 'Se requiere un token JWT válido en el encabezado Authorization',
    });
  }

  if (!isAdmin(user)) {
    return sendJson(res, 403, {
      error: 'Prohibido',
      message: 'Solo los administradores pueden crear proyectos',
    });
  }

  try {
    const rawBody = await readRequestBody(req);
    const body = JSON.parse(rawBody);

    const { nombre, descripcion, localidad_id } = body;

    const missingFields = [];
    if (!nombre) missingFields.push('nombre');
    if (localidad_id == null) missingFields.push('localidad_id');

    if (missingFields.length > 0) {
      return sendJson(res, 400, {
        error: 'Datos incompletos',
        message: `Los campos obligatorios son: ${missingFields.join(', ')}`,
        missing_fields: missingFields,
      });
    }

    const conn = await getDbConnection();

    try {
      // Validate that the localidad exists
      const [locRows] = await conn.execute(
        'SELECT id FROM localidades WHERE id = ?',
        [localidad_id]
      );

      if (locRows.length === 0) {
        await conn.end();
        return sendJson(res, 404, {
          error: 'Localidad no encontrada',
          message: `No existe una localidad con id ${localidad_id}`,
        });
      }

      // Create the project with activo=1
      const [result] = await conn.execute(
        'INSERT INTO proyectos (nombre, descripcion, localidad_id, activo) VALUES (?, ?, ?, 1)',
        [nombre, descripcion || null, localidad_id]
      );

      // Return the created project
      const [rows] = await conn.execute(
        'SELECT id, nombre, descripcion, localidad_id, activo FROM proyectos WHERE id = ?',
        [result.insertId]
      );

      await conn.end();

      sendJson(res, 201, {
        message: 'Proyecto creado exitosamente',
        proyecto: rows[0],
      });
    } catch (err) {
      try { await conn.end(); } catch (_) {}
      throw err;
    }
  } catch (err) {
    if (err instanceof SyntaxError) {
      return sendJson(res, 400, {
        error: 'Cuerpo de la solicitud inválido',
        message: 'El cuerpo debe ser JSON válido',
      });
    }
    sendJson(res, 500, {
      error: 'Error interno del servidor',
      message: err.message,
    });
  }
}

async function handleUpdateProyecto(req, res, id) {
  const user = verifyToken(req);

  if (!user) {
    return sendJson(res, 401, {
      error: 'No autorizado',
      message: 'Se requiere un token JWT válido en el encabezado Authorization',
    });
  }

  if (!isAdmin(user)) {
    return sendJson(res, 403, {
      error: 'Prohibido',
      message: 'Solo los administradores pueden modificar proyectos',
    });
  }

  try {
    const rawBody = await readRequestBody(req);
    const body = JSON.parse(rawBody);

    const { nombre, descripcion, localidad_id, activo } = body;

    // At least one field must be provided
    if (nombre === undefined && descripcion === undefined && localidad_id === undefined && activo === undefined) {
      return sendJson(res, 400, {
        error: 'Datos incompletos',
        message: 'Se debe proporcionar al menos un campo para modificar: nombre, descripcion, localidad_id o activo',
      });
    }

    const conn = await getDbConnection();

    try {
      // Verify the project exists
      const [projRows] = await conn.execute(
        'SELECT id FROM proyectos WHERE id = ?',
        [id]
      );

      if (projRows.length === 0) {
        await conn.end();
        return sendJson(res, 404, {
          error: 'Proyecto no encontrado',
          message: `No existe un proyecto con id ${id}`,
        });
      }

      // If localidad_id is being changed, validate it exists
      if (localidad_id !== undefined) {
        const [locRows] = await conn.execute(
          'SELECT id FROM localidades WHERE id = ?',
          [localidad_id]
        );

        if (locRows.length === 0) {
          await conn.end();
          return sendJson(res, 404, {
            error: 'Localidad no encontrada',
            message: `No existe una localidad con id ${localidad_id}`,
          });
        }
      }

      // Build the update dynamically
      const updates = [];
      const params = [];

      if (nombre !== undefined) {
        updates.push('nombre = ?');
        params.push(nombre);
      }
      if (descripcion !== undefined) {
        updates.push('descripcion = ?');
        params.push(descripcion);
      }
      if (localidad_id !== undefined) {
        updates.push('localidad_id = ?');
        params.push(localidad_id);
      }
      if (activo !== undefined) {
        updates.push('activo = ?');
        params.push(activo);
      }

      params.push(id);

      await conn.execute(
        `UPDATE proyectos SET ${updates.join(', ')} WHERE id = ?`,
        params
      );

      // Return the updated project
      const [rows] = await conn.execute(
        'SELECT id, nombre, descripcion, localidad_id, activo FROM proyectos WHERE id = ?',
        [id]
      );

      await conn.end();

      sendJson(res, 200, {
        message: 'Proyecto actualizado exitosamente',
        proyecto: rows[0],
      });
    } catch (err) {
      try { await conn.end(); } catch (_) {}
      throw err;
    }
  } catch (err) {
    if (err instanceof SyntaxError) {
      return sendJson(res, 400, {
        error: 'Cuerpo de la solicitud inválido',
        message: 'El cuerpo debe ser JSON válido',
      });
    }
    sendJson(res, 500, {
      error: 'Error interno del servidor',
      message: err.message,
    });
  }
}

async function handleGetNoConformidades(req, res) {
  const user = verifyToken(req);

  if (!user) {
    return sendJson(res, 401, {
      error: 'No autorizado',
      message: 'Se requiere un token JWT válido en el encabezado Authorization',
    });
  }

  try {
    const conn = await getDbConnection();

    const url = new URL(req.url, `http://${req.headers.host}`);
    const q = url.searchParams.get('q') || null;
    const estadoIdRaw = url.searchParams.get('estado_id');
    const estadoIdParam = estadoIdRaw !== null ? parseInt(estadoIdRaw, 10) : null;

    let query, params;

    const baseSelect = `SELECT nc.id, nc.numero, nc.titulo, nc.proyecto_id, p.nombre AS proyecto_nombre,
                      nc.tipo, nc.fecha, nc.ubicacion, nc.responsable, nc.descripcion,
                      nc.estado_id, e.nombre AS estado, nc.usuario_registro_id,
                      nc.localidad_id, l.nombre AS localidad_nombre,
                      nc.created_at, nc.updated_at
               FROM no_conformidades nc
               JOIN proyectos p ON nc.proyecto_id = p.id
               JOIN estados e ON nc.estado_id = e.id
               JOIN localidades l ON nc.localidad_id = l.id`;

    const conditions = [];

    if (!isAdmin(user)) {
      conditions.push('nc.localidad_id = ?');
    }

    if (q) {
      conditions.push('(nc.titulo LIKE ? OR nc.numero LIKE ?)');
    }

    if (estadoIdParam) {
      conditions.push('nc.estado_id = ?');
    }

    let whereClause = '';
    if (conditions.length > 0) {
      whereClause = ' WHERE ' + conditions.join(' AND ');
    }

    query = baseSelect + whereClause + ' ORDER BY nc.created_at DESC';

    params = [];
    if (!isAdmin(user)) {
      params.push(user.localidad_id);
    }
    if (q) {
      const likeParam = `%${q}%`;
      params.push(likeParam, likeParam);
    }
    if (estadoIdParam) {
      params.push(estadoIdParam);
    }

    const [rows] = await conn.execute(query, params);
    await conn.end();

    sendJson(res, 200, rows);
  } catch (err) {
    sendJson(res, 500, {
      error: 'Error interno del servidor',
      message: err.message,
    });
  }
}

async function handleUpdateNoConformidadEstado(req, res, id) {
  const user = verifyToken(req);

  if (!user) {
    return sendJson(res, 401, {
      error: 'No autorizado',
      message: 'Se requiere un token JWT válido en el encabezado Authorization',
    });
  }

  try {
    const rawBody = await readRequestBody(req);
    const body = JSON.parse(rawBody);

    const { estado_id } = body;

    if (estado_id == null) {
      return sendJson(res, 400, {
        error: 'Datos incompletos',
        message: 'Se requiere estado_id',
      });
    }

    const conn = await getDbConnection();

    try {
      // Verificar que la NC existe y pertenece a la localidad del usuario
      const [ncRows] = await conn.execute(
        'SELECT id, estado_id, localidad_id FROM no_conformidades WHERE id = ?',
        [id]
      );

      if (ncRows.length === 0) {
        await conn.end();
        return sendJson(res, 404, {
          error: 'No conformidad no encontrada',
          message: `No existe una no conformidad con id ${id}`,
        });
      }

      if (!isAdmin(user) && ncRows[0].localidad_id !== user.localidad_id) {
        await conn.end();
        return sendJson(res, 404, {
          error: 'No conformidad no encontrada',
          message: `No existe una no conformidad con id ${id}`,
        });
      }

      const currentEstadoId = ncRows[0].estado_id;

      // Verificar que el nuevo estado existe y es uno de los 3 permitidos
      const [estadoRows] = await conn.execute(
        'SELECT id, nombre FROM estados WHERE id = ? AND nombre IN (?, ?, ?)',
        [estado_id, 'NUEVA', 'EN PROCESO', 'CERRADA']
      );

      if (estadoRows.length === 0) {
        await conn.end();
        return sendJson(res, 400, {
          error: 'Estado no válido',
          message: 'El estado_id proporcionado no existe o no es uno de los estados permitidos (NUEVA, EN PROCESO, CERRADA)',
        });
      }

      const nuevoEstadoNombre = estadoRows[0].nombre;

      // Validar transición
      const transicionesPermitidas = {
        1: [2],       // NUEVA (1) -> EN PROCESO (2)
        2: [3],       // EN PROCESO (2) -> CERRADA (3)
      };

      const estadosPermitidos = {
        1: 'NUEVA',
        2: 'EN PROCESO',
        3: 'CERRADA',
      };

      const estadosPermitidosFromCurrent = transicionesPermitidas[currentEstadoId] || [];

      if (!estadosPermitidosFromCurrent.includes(estado_id)) {
        await conn.end();
        const currentNombre = estadosPermitidos[currentEstadoId] || 'desconocido';
        return sendJson(res, 400, {
          error: 'Transición no permitida',
          message: `No se puede cambiar de ${currentNombre} a ${nuevoEstadoNombre}`,
        });
      }

      // Actualizar el estado con consulta preparada
      await conn.execute(
        'UPDATE no_conformidades SET estado_id = ?, updated_at = NOW() WHERE id = ?',
        [estado_id, id]
      );

      // Devolver la NC actualizada con JOIN a estados
      const [updatedRows] = await conn.execute(
        `SELECT nc.id, nc.numero, nc.titulo, nc.estado_id, e.nombre AS estado,
                nc.proyecto_id, nc.tipo, nc.fecha, nc.ubicacion,
                nc.responsable, nc.descripcion, nc.usuario_registro_id,
                nc.localidad_id, nc.created_at, nc.updated_at
         FROM no_conformidades nc
         JOIN estados e ON nc.estado_id = e.id
         WHERE nc.id = ?`,
        [id]
      );

      await conn.end();

      sendJson(res, 200, {
        message: 'Estado actualizado correctamente',
        no_conformidad: updatedRows[0],
      });
    } catch (err) {
      try { await conn.end(); } catch (_) {}
      throw err;
    }
  } catch (err) {
    if (err instanceof SyntaxError) {
      return sendJson(res, 400, {
        error: 'Cuerpo de la solicitud inválido',
        message: 'El cuerpo debe ser JSON válido',
      });
    }
    sendJson(res, 500, {
      error: 'Error interno del servidor',
      message: err.message,
    });
  }
}

async function handleGetNoConformidadById(req, res, id) {
  const user = verifyToken(req);

  if (!user) {
    return sendJson(res, 401, {
      error: 'No autorizado',
      message: 'Se requiere un token JWT válido en el encabezado Authorization',
    });
  }

  try {
    const conn = await getDbConnection();

    // Verificar que la NC existe y pertenece a la localidad del usuario
    const [ncRows] = await conn.execute(
      'SELECT localidad_id FROM no_conformidades WHERE id = ?',
      [id]
    );

    if (ncRows.length === 0) {
      await conn.end();
      return sendJson(res, 404, {
        error: 'No conformidad no encontrada',
        message: `No existe una no conformidad con id ${id}`,
      });
    }

    if (!isAdmin(user) && ncRows[0].localidad_id !== user.localidad_id) {
      await conn.end();
      return sendJson(res, 404, {
        error: 'No conformidad no encontrada',
        message: `No existe una no conformidad con id ${id}`,
      });
    }

    const [rows] = await conn.execute(
      `SELECT nc.id, nc.numero, nc.titulo, nc.proyecto_id, p.nombre AS proyecto_nombre,
              nc.tipo, nc.fecha, nc.ubicacion, nc.responsable, nc.descripcion,
              nc.estado_id, e.nombre AS estado, nc.usuario_registro_id,
              nc.localidad_id, nc.created_at, nc.updated_at
       FROM no_conformidades nc
       JOIN proyectos p ON nc.proyecto_id = p.id
       JOIN estados e ON nc.estado_id = e.id
       WHERE nc.id = ?`,
      [id]
    );
    await conn.end();

    sendJson(res, 200, rows[0]);
  } catch (err) {
    sendJson(res, 500, {
      error: 'Error interno del servidor',
      message: err.message,
    });
  }
}

// ---- Helpers for photos ----

function getExtensionFromMimeType(mimeType) {
  const map = {
    'image/jpeg': '.jpg',
    'image/png': '.png',
  };
  return map[mimeType] || null;
}

function generateUniqueFilename(ext) {
  return `${crypto.randomUUID()}${ext}`;
}

async function ensureStorageDir() {
  if (!fs.existsSync(STORAGE_DIR)) {
    fs.mkdirSync(STORAGE_DIR, { recursive: true });
  }
}

async function saveUploadedFile(buffer, mimeType, ncId) {
  const ext = getExtensionFromMimeType(mimeType);
  if (!ext) {
    throw new Error('Tipo de archivo no permitido');
  }

  await ensureStorageDir();

  const ncDir = path.join(STORAGE_DIR, String(ncId));
  if (!fs.existsSync(ncDir)) {
    fs.mkdirSync(ncDir, { recursive: true });
  }

  const filename = generateUniqueFilename(ext);
  const filePath = path.join(ncDir, filename);
  const relativePath = `storage/fotos/${ncId}/${filename}`;

  await fs.promises.writeFile(filePath, buffer);

  return relativePath;
}

async function parseMultipart(req) {
  return new Promise((resolve, reject) => {
    const bb = busboy({ headers: req.headers });
    const fields = {};
    const files = [];

    bb.on('field', (name, value) => {
      fields[name] = value;
    });

    bb.on('file', (name, fileStream, info) => {
      const { filename, encoding, mimeType } = info;
      const chunks = [];
      fileStream.on('data', chunk => chunks.push(chunk));
      fileStream.on('end', () => {
        files.push({ name, filename, encoding, mimeType, buffer: Buffer.concat(chunks) });
      });
      fileStream.on('error', reject);
    });

    bb.on('close', () => resolve({ fields, files }));
    bb.on('error', reject);

    req.pipe(bb);
  });
}

// ---- Photo Handlers ----

async function handleUploadFotos(req, res, ncId) {
  const user = verifyToken(req);

  if (!user) {
    return sendJson(res, 401, {
      error: 'No autorizado',
      message: 'Se requiere un token JWT válido en el encabezado Authorization',
    });
  }

  // Verify NC exists and belongs to user's localidad
  try {
    const conn = await getDbConnection();
    const [ncRows] = await conn.execute(
      'SELECT id, localidad_id FROM no_conformidades WHERE id = ?',
      [ncId]
    );
    await conn.end();

    if (ncRows.length === 0) {
      return sendJson(res, 404, {
        error: 'No conformidad no encontrada',
        message: `No existe una no conformidad con id ${ncId}`,
      });
    }

    if (!isAdmin(user) && ncRows[0].localidad_id !== user.localidad_id) {
      return sendJson(res, 404, {
        error: 'No conformidad no encontrada',
        message: `No existe una no conformidad con id ${ncId}`,
      });
    }
  } catch (err) {
    return sendJson(res, 500, {
      error: 'Error interno del servidor',
      message: err.message,
    });
  }

  // Parse multipart form data
  let parsed;
  try {
    parsed = await parseMultipart(req);
  } catch (err) {
    return sendJson(res, 400, {
      error: 'Error al procesar la solicitud',
      message: 'No se pudo procesar el formulario multipart',
    });
  }

  const { files } = parsed;

  if (!files || files.length === 0) {
    return sendJson(res, 400, {
      error: 'Sin archivo',
      message: 'Se debe adjuntar al menos una fotografía en formato multipart/form-data',
    });
  }

  // Check max limit
  try {
    const conn = await getDbConnection();
    const [existingRows] = await conn.execute(
      'SELECT COUNT(*) AS total FROM fotografias WHERE no_conformidad_id = ?',
      [ncId]
    );
    const currentCount = existingRows[0].total;

    if (currentCount + files.length > MAX_FOTOS_PER_NC) {
      await conn.end();
      return sendJson(res, 400, {
        error: 'Límite de fotografías excedido',
        message: `Máximo ${MAX_FOTOS_PER_NC} fotografías por no conformidad. Ya tiene ${currentCount} y se intentaron agregar ${files.length}.`,
        limite: MAX_FOTOS_PER_NC,
        actuales: currentCount,
        solicitadas: files.length,
      });
    }

    // Process each file
    const savedPaths = [];

    for (const file of files) {
      // Validate MIME type
      if (!ALLOWED_MIME_TYPES.includes(file.mimeType)) {
        // Clean up already saved files before returning error
        for (const savedPath of savedPaths) {
          try {
            await fs.promises.unlink(path.resolve(__dirname, '..', savedPath));
          } catch (_) {}
        }
        await conn.end();
        return sendJson(res, 400, {
          error: 'Tipo de archivo no permitido',
          message: `El archivo "${file.filename}" tiene tipo MIME "${file.mimeType}" no autorizado. Solo se permiten JPG, JPEG y PNG.`,
          tipo_archivo: file.mimeType,
          tipos_permitidos: ALLOWED_MIME_TYPES,
        });
      }

      // Validate extension
      const fileExt = path.extname(file.filename).toLowerCase();
      if (!ALLOWED_EXTENSIONS.includes(fileExt)) {
        for (const savedPath of savedPaths) {
          try {
            await fs.promises.unlink(path.resolve(__dirname, '..', savedPath));
          } catch (_) {}
        }
        await conn.end();
        return sendJson(res, 400, {
          error: 'Extensión de archivo no permitida',
          message: `La extensión "${fileExt}" del archivo "${file.filename}" no es válida. Solo se permiten .jpg, .jpeg y .png.`,
          extension: fileExt,
          extensiones_permitidas: ALLOWED_EXTENSIONS,
        });
      }

      // Save file
      const relativePath = await saveUploadedFile(file.buffer, file.mimeType, ncId);
      savedPaths.push(relativePath);

      // Store in database
      await conn.execute(
        'INSERT INTO fotografias (no_conformidad_id, archivo_path) VALUES (?, ?)',
        [ncId, relativePath]
      );
    }

    await conn.end();

    sendJson(res, 201, {
      message: `Fotografía${files.length > 1 ? 's' : ''} subida${files.length > 1 ? 's' : ''} exitosamente`,
      fotografias: savedPaths,
    });
  } catch (err) {
    return sendJson(res, 500, {
      error: 'Error interno del servidor',
      message: err.message,
    });
  }
}

async function handleGetFotos(req, res, ncId) {
  const user = verifyToken(req);

  if (!user) {
    return sendJson(res, 401, {
      error: 'No autorizado',
      message: 'Se requiere un token JWT válido en el encabezado Authorization',
    });
  }

  try {
    const conn = await getDbConnection();

    // Verify NC exists and belongs to user's localidad
    const [ncRows] = await conn.execute(
      'SELECT id, localidad_id FROM no_conformidades WHERE id = ?',
      [ncId]
    );

    if (ncRows.length === 0) {
      await conn.end();
      return sendJson(res, 404, {
        error: 'No conformidad no encontrada',
        message: `No existe una no conformidad con id ${ncId}`,
      });
    }

    if (!isAdmin(user) && ncRows[0].localidad_id !== user.localidad_id) {
      await conn.end();
      return sendJson(res, 404, {
        error: 'No conformidad no encontrada',
        message: `No existe una no conformidad con id ${ncId}`,
      });
    }

    // Get photos
    const [fotos] = await conn.execute(
      'SELECT id, no_conformidad_id, archivo_path, created_at FROM fotografias WHERE no_conformidad_id = ? ORDER BY created_at ASC',
      [ncId]
    );

    await conn.end();

    sendJson(res, 200, {
      no_conformidad_id: ncId,
      total: fotos.length,
      fotografias: fotos,
    });
  } catch (err) {
    sendJson(res, 500, {
      error: 'Error interno del servidor',
      message: err.message,
    });
  }
}

// ---- Localidades Handler ----

async function handleGetLocalidades(req, res) {
  const user = verifyToken(req);

  if (!user) {
    return sendJson(res, 401, {
      error: 'No autorizado',
      message: 'Se requiere un token JWT válido en el encabezado Authorization',
    });
  }

  if (!isAdmin(user)) {
    return sendJson(res, 403, {
      error: 'Prohibido',
      message: 'Solo los administradores pueden consultar localidades',
    });
  }

  try {
    const conn = await getDbConnection();
    const [rows] = await conn.execute(
      'SELECT id, nombre, created_at, updated_at FROM localidades ORDER BY nombre ASC'
    );
    await conn.end();

    sendJson(res, 200, rows);
  } catch (err) {
    sendJson(res, 500, {
      error: 'Error interno del servidor',
      message: err.message,
    });
  }
}

server.listen(PORT, HOST, () => {
  console.log(`API ABICK NC escuchando en http://${HOST}:${PORT}`);
  console.log(`Endpoint de prueba: GET /ping`);
  console.log(`Autenticación: POST /login`);
});
