const mysql = require('mysql2/promise');

/**
 * Conexión a la base de datos MySQL.
 *
 * Las credenciales se leen desde variables de entorno (.env).
 * Ninguna contraseña ni credencial se almacena en el código fuente.
 */

async function getDbConnection() {
  const host = process.env.DB_HOST || 'localhost';
  const port = parseInt(process.env.DB_PORT || '3306', 10);
  const db   = process.env.DB_NAME || 'app_p_riesgos';
  const user = process.env.DB_USER;
  const pass = process.env.DB_PASS;

  if (!user || !pass) {
    throw new Error('DB_USER y DB_PASS deben estar definidos en .env');
  }

  const connection = await mysql.createConnection({
    host,
    port,
    database: db,
    user,
    password: pass,
    charset: 'utf8mb4',
  });

  return connection;
}

module.exports = { getDbConnection };
