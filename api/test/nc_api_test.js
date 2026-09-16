/**
 * Backend API Tests for No Conformidades
 *
 * Run with: node test/nc_api_test.js
 * Requires the API server to be running on localhost:8080
 */

const http = require('http');

const BASE_URL = 'http://localhost:8080';

let token = null;
let adminToken = null;
let ncId = null;
let passed = 0;
let failed = 0;

function log(msg) {
  console.log(msg);
}

function assert(condition, message) {
  if (condition) {
    log(`  ✅ ${message}`);
    passed++;
  } else {
    log(`  ❌ ${message}`);
    failed++;
  }
}

async function request(method, path, body = null, customToken = null) {
  return new Promise((resolve, reject) => {
    const url = new URL(path, BASE_URL);
    const options = {
      hostname: url.hostname,
      port: url.port,
      path: url.pathname + url.search,
      method,
      headers: {
        'Content-Type': 'application/json',
      },
    };

    const tok = customToken || token;
    if (tok) {
      options.headers['Authorization'] = `Bearer ${tok}`;
    }

    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => { data += chunk; });
      res.on('end', () => {
        try {
          resolve({ statusCode: res.statusCode, body: JSON.parse(data) });
        } catch (e) {
          resolve({ statusCode: res.statusCode, body: data });
        }
      });
    });

    req.on('error', reject);

    if (body) {
      req.write(JSON.stringify(body));
    }

    req.end();
  });
}

async function login(user, pass) {
  const res = await request('POST', '/login', { usuario: user, contrasena: pass });
  assert(res.statusCode === 200, `Login ${user} → ${res.statusCode}`);
  return res.body.token;
}

async function runTests() {
  log('\n=== Backend API Tests for No Conformidades ===\n');

  // Login
  log('--- Authentication ---');
  token = await login('user', 'user123');
  adminToken = await login('admin', 'admin123');

  // Test 1: Crear NC con título → 201
  log('\n--- POST /no-conformidades ---');
  const createRes = await request('POST', '/no-conformidades', {
    titulo: 'EPP faltante en área de producción',
    proyecto_id: 1,
    tipo: 'Condición insegura',
    fecha: '2026-09-16',
    descripcion: 'No se encontraron elementos de protección personal en el área de producción.',
  });
  assert(createRes.statusCode === 201, `Crear NC con título → ${createRes.statusCode} (esperado 201)`);
  assert(createRes.body.no_conformidad && createRes.body.no_conformidad.titulo === 'EPP faltante en área de producción', 'Respuesta incluye titulo');
  ncId = createRes.body.no_conformidad?.id;

  // Test 2: Título vacío → 400
  const emptyTitleRes = await request('POST', '/no-conformidades', {
    titulo: '',
    proyecto_id: 1,
    tipo: 'Condición insegura',
    fecha: '2026-09-16',
    descripcion: 'Test',
  });
  assert(emptyTitleRes.statusCode === 400, `Título vacío → ${emptyTitleRes.statusCode} (esperado 400)`);

  // Test 3: Título >150 caracteres → 400
  const longTitleRes = await request('POST', '/no-conformidades', {
    titulo: 'a'.repeat(151),
    proyecto_id: 1,
    tipo: 'Condición insegura',
    fecha: '2026-09-16',
    descripcion: 'Test',
  });
  assert(longTitleRes.statusCode === 400, `Título >150 chars → ${longTitleRes.statusCode} (esperado 400)`);

  // Test 4: Sin título → 400
  const noTitleRes = await request('POST', '/no-conformidades', {
    proyecto_id: 1,
    tipo: 'Condición insegura',
    fecha: '2026-09-16',
    descripcion: 'Test',
  });
  assert(noTitleRes.statusCode === 400, `Sin título → ${noTitleRes.statusCode} (esperado 400)`);

  // Test 5: GET /no-conformidades con búsqueda por título
  if (ncId) {
    log('\n--- GET /no-conformidades ---');
    const searchTitleRes = await request('GET', `/no-conformidades?q=EPP`);
    assert(searchTitleRes.statusCode === 200, `Búsqueda por título → ${searchTitleRes.statusCode} (esperado 200)`);
    const foundByTitle = searchTitleRes.body.some(nc => nc.titulo && nc.titulo.includes('EPP'));
    assert(foundByTitle, 'Resultado de búsqueda contiene NC con título que incluye "EPP"');
  }

  // Test 6: GET /no-conformidades con búsqueda por número
  if (ncId) {
    const ncNumero = createRes.body.no_conformidad?.numero;
    if (ncNumero) {
      const searchNumRes = await request('GET', `/no-conformidades?q=${ncNumero}`);
      assert(searchNumRes.statusCode === 200, `Búsqueda por número → ${searchNumRes.statusCode} (esperado 200)`);
      const foundByNum = searchNumRes.body.some(nc => nc.numero === ncNumero);
      assert(foundByNum, `Resultado de búsqueda contiene NC ${ncNumero}`);
    }
  }

  // Test 7: GET /no-conformidades con filtro por estado
  log('\n--- Filtro por estado ---');
  const estadoRes = await request('GET', '/no-conformidades?estado_id=1');
  assert(estadoRes.statusCode === 200, `Filtro por estado → ${estadoRes.statusCode} (esperado 200)`);
  const allNueva = estadoRes.body.every(nc => nc.estado === 'NUEVA');
  assert(allNueva, 'Todos los resultados tienen estado NUEVA');

  // Test 8: GET /no-conformidades con búsqueda + estado
  if (ncId) {
    const combinedRes = await request('GET', '/no-conformidades?q=EPP&estado_id=1');
    assert(combinedRes.statusCode === 200, `Búsqueda + estado → ${combinedRes.statusCode} (esperado 200)`);
    const allMatch = combinedRes.body.every(nc => nc.titulo && nc.titulo.includes('EPP') && nc.estado === 'NUEVA');
    assert(allMatch, 'Todos los resultados coinciden con título y estado');
  }

  // Test 9: GET /no-conformidades/:id incluye titulo
  if (ncId) {
    log('\n--- GET /no-conformidades/:id ---');
    const getByIdRes = await request('GET', `/no-conformidades/${ncId}`);
    assert(getByIdRes.statusCode === 200, `GET by id → ${getByIdRes.statusCode} (esperado 200)`);
    assert(getByIdRes.body.titulo === 'EPP faltante en área de producción', 'GET by id incluye titulo');
  }

  // Summary
  log('\n=== Results ===');
  log(`Passed: ${passed}`);
  log(`Failed: ${failed}`);
  log(`Total: ${passed + failed}`);

  process.exit(failed > 0 ? 1 : 0);
}

runTests().catch(err => {
  log(`Error: ${err.message}`);
  process.exit(1);
});
