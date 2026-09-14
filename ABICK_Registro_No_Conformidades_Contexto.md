# ABICK -- Registro de No Conformidades

## 1. Propósito del documento

Este documento define el contexto funcional y técnico de la nueva
aplicación móvil de **Registro de No Conformidades** para el
**Departamento de Prevención de Riesgos de ABICK**.

Su objetivo es servir como documento base para Claude durante todo el
desarrollo. Claude debe usarlo como contexto del proyecto y respetar sus
decisiones, alcance y restricciones.

La aplicación será una **aplicación nueva desarrollada en Flutter**,
tomando la APK antigua `Registro_No_Conformidades.apk` únicamente como
referencia funcional y no como código base.

El objetivo NO es replicar visualmente ni técnicamente el sistema
antiguo. Se busca conservar su idea principal, pero crear una aplicación
moderna, simple, mantenible y fácil de utilizar desde un teléfono.

------------------------------------------------------------------------

# 2. Objetivo de la aplicación

La aplicación permitirá al personal autorizado de Prevención de Riesgos:

1.  Iniciar sesión.
2.  Registrar una nueva no conformidad.
3.  Adjuntar fotografías como evidencia.
4.  Consultar las no conformidades registradas.
5.  Ver el detalle de una no conformidad.
6.  Cambiar su estado.
7.  Identificar rápidamente qué registros están nuevos, en proceso o
    cerrados.

La aplicación debe ser deliberadamente sencilla.

No se deben agregar funcionalidades que no hayan sido solicitadas.

------------------------------------------------------------------------

# 3. Referencia: aplicación antigua

La APK proporcionada se llama:

`Registro_No_Conformidades.apk`

La aplicación antigua es un sistema Android antiguo y su estructura
contiene referencias a funcionalidades como:

-   Anotar.
-   Consultar.
-   Actualizar.
-   Borrar.
-   Enviar.
-   Reportar.
-   Fecha.
-   Gráficos.
-   Consulta por proyectos.

También contiene recursos relacionados con `Screen1`, `scrConsultar`,
`scrActualizar` y `scrGrafica`, además de recursos HTML y elementos
asociados a Google Sheets/Google Forms.

### Cómo utilizar esta referencia

La APK antigua se utilizará únicamente para comprender el funcionamiento
general del sistema anterior.

NO se debe intentar convertir la APK en el proyecto Flutter.

NO se debe copiar su arquitectura.

NO se debe mantener su interfaz antigua.

NO se debe intentar reproducir sus limitaciones.

La nueva aplicación debe ser una implementación limpia desde cero.

------------------------------------------------------------------------

# 4. Alcance de la V1

La primera versión tendrá únicamente estas funcionalidades:

## 4.1 Login

El usuario podrá iniciar sesión mediante:

-   Usuario.
-   Contraseña.

La autenticación será gestionada por la API.

La aplicación no debe almacenar contraseñas.

El usuario autenticado quedará identificado para asociar sus registros a
su cuenta.

------------------------------------------------------------------------

## 4.2 Inicio

Después del login se mostrará una pantalla de inicio sencilla.

Debe permitir acceder principalmente a:

-   Nueva No Conformidad.
-   Mis No Conformidades.

Puede mostrar un pequeño resumen de cantidades por estado, pero no debe
convertirse en un dashboard complejo.

Ejemplo:

``` text
Hola, [Usuario]

Nueva No Conformidad

Mis No Conformidades

Resumen
Nueva: 3
En proceso: 5
Cerrada: 12
```

El resumen es opcional para la primera implementación si agrega
complejidad innecesaria.

------------------------------------------------------------------------

# 5. Nueva No Conformidad

Esta será una de las pantallas principales.

El formulario debe ser corto y fácil de completar desde terreno.

Campos propuestos:

### Datos

-   Proyecto / Área.
-   Fecha.
-   Tipo de no conformidad.
-   Descripción.
-   Ubicación.
-   Responsable.

### Evidencia fotográfica

Debe existir la posibilidad de tomar fotografías desde el teléfono o
seleccionar fotografías disponibles en el dispositivo.

La V1 puede limitarse a un máximo de **3 fotografías por registro**.

Las fotografías deben asociarse al registro correspondiente.

### Estado inicial

Toda no conformidad nueva se crea automáticamente con:

`NUEVA`

El usuario no necesita seleccionar el estado al crearla.

### Acción

Botón:

`REGISTRAR NO CONFORMIDAD`

Después de registrar correctamente:

-   Mostrar confirmación.
-   Mostrar el identificador/número de la no conformidad.
-   Volver al listado o permitir volver al inicio.

------------------------------------------------------------------------

# 6. Estados

Los estados son una de las mejoras principales respecto al sistema
antiguo.

La V1 tendrá solamente tres estados:

``` text
NUEVA
   ↓
EN PROCESO
   ↓
CERRADA
```

### NUEVA

La no conformidad acaba de ser registrada y todavía no ha sido
gestionada.

### EN PROCESO

La no conformidad está siendo gestionada.

### CERRADA

La situación fue solucionada y el registro se considera terminado.

No agregar más estados salvo que posteriormente exista una necesidad
real.

No implementar workflows complejos.

------------------------------------------------------------------------

# 7. Listado de No Conformidades

La pantalla permitirá consultar los registros.

Cada elemento del listado debe mostrar información resumida:

``` text
NC-00025
Condición insegura
Proyecto: Obra Norte
02/09/2026
EN PROCESO
```

El estado debe ser visualmente fácil de identificar.

Al tocar un registro se abre su detalle.

El listado debe obtener los datos desde la API.

------------------------------------------------------------------------

# 8. Detalle de una No Conformidad

Debe mostrar:

-   Número/ID.
-   Fecha.
-   Proyecto/Área.
-   Tipo.
-   Descripción.
-   Ubicación.
-   Responsable.
-   Usuario que registró.
-   Estado.
-   Fotografías.

También debe existir la posibilidad de actualizar el estado.

Ejemplo:

``` text
NC-00025

Tipo:
Condición insegura

Proyecto:
Obra Norte

Fecha:
02/09/2026

Descripción:
...

Ubicación:
Sector B

Responsable:
...

Estado:
EN PROCESO

Fotografías:
[foto] [foto]

[ CAMBIAR ESTADO ]
```

------------------------------------------------------------------------

# 9. Fotografías

Las fotografías son una mejora explícita de la nueva aplicación.

Objetivo:

Permitir que Prevención de Riesgos registre evidencia visual de la
situación detectada.

Flujo:

``` text
Nueva NC
   ↓
Agregar fotografía
   ↓
Cámara / Galería
   ↓
Vista previa
   ↓
Registrar NC
   ↓
Fotografía asociada al registro
```

La fotografía debe estar asociada a una no conformidad concreta.

No implementar edición avanzada de imágenes.

No implementar reconocimiento de imágenes.

No implementar compresión o procesamiento complejo salvo que sea
necesario técnicamente para reducir el tamaño de los archivos.

------------------------------------------------------------------------

# 10. Arquitectura general

La solución utilizará tres componentes principales:

``` text
                 INTERNET / RED ABICK
                         │
                         ▼
                ┌─────────────────┐
                │   Flutter App   │
                │     Android     │
                └────────┬────────┘
                         │
                       HTTPS
                         │
                         ▼
                ┌─────────────────┐
                │       API       │
                │  Backend ABICK  │
                └────────┬────────┘
                         │
                         ▼
                ┌─────────────────┐
                │      MySQL      │
                │   Base de datos │
                └─────────────────┘
```

La API y MySQL estarán en una máquina virtual dentro del servidor de la
empresa.

------------------------------------------------------------------------

# 11. Base de datos

La base de datos se creará desde cero.

Será independiente del ERP.

La base de datos del ERP NO debe modificarse ni utilizarse directamente
para esta aplicación.

La nueva base de datos tendrá como mínimo entidades para:

-   Usuarios.
-   No conformidades.
-   Estados.
-   Proyectos/áreas.
-   Fotografías.

La estructura exacta debe definirse antes de implementar la API.

------------------------------------------------------------------------

# 12. phpMyAdmin

phpMyAdmin se utilizará como herramienta administrativa para gestionar
MySQL.

La aplicación Flutter NO se conectará directamente a phpMyAdmin.

La aplicación Flutter tampoco debe conectarse directamente a MySQL.

La comunicación será:

``` text
Flutter
   ↓
API
   ↓
MySQL
```

phpMyAdmin solamente será una herramienta de administración:

``` text
Administrador
   ↓
phpMyAdmin
   ↓
MySQL
```

------------------------------------------------------------------------

# 13. API

La API será pequeña y enfocada exclusivamente a las necesidades de la
aplicación.

No crear una arquitectura sobredimensionada.

Endpoints conceptuales iniciales:

``` text
POST /login

GET /no-conformidades

GET /no-conformidades/{id}

POST /no-conformidades

PUT /no-conformidades/{id}/estado

POST /no-conformidades/{id}/fotos
```

Estos endpoints son una referencia conceptual. Claude debe decidir la
implementación concreta según el backend elegido.

La API debe:

-   Validar usuarios.
-   Autenticar solicitudes.
-   Validar datos.
-   Acceder a MySQL.
-   Registrar no conformidades.
-   Consultar registros.
-   Cambiar estados.
-   Gestionar fotografías.
-   Devolver respuestas claras a Flutter.

------------------------------------------------------------------------

# 14. Seguridad

Principios mínimos:

-   Flutter nunca debe contener credenciales de MySQL.
-   MySQL no debe quedar expuesto innecesariamente a Internet.
-   La API debe ser el único intermediario entre Flutter y MySQL.
-   Las contraseñas deben almacenarse usando hash seguro.
-   Las solicitudes autenticadas deben utilizar un mecanismo de
    sesión/token apropiado.
-   No guardar contraseñas en texto plano.
-   No incluir secretos reales dentro del repositorio Flutter.
-   No exponer credenciales en código fuente.

La seguridad debe ser suficiente para una aplicación interna
empresarial, pero sin crear una arquitectura innecesariamente compleja.

------------------------------------------------------------------------

# 15. Flujo completo del usuario

## Inicio

``` text
Abrir aplicación
      ↓
Login
      ↓
Inicio
```

## Registrar

``` text
Inicio
  ↓
Nueva No Conformidad
  ↓
Completar formulario
  ↓
Agregar fotografías
  ↓
Registrar
  ↓
Confirmación
```

## Consultar

``` text
Inicio
  ↓
Mis No Conformidades
  ↓
Listado
  ↓
Seleccionar registro
  ↓
Detalle
```

## Gestionar

``` text
Detalle
  ↓
Cambiar estado
  ↓
EN PROCESO
  ↓
CERRADA
```

------------------------------------------------------------------------

# 16. Navegación

Mantener la navegación simple.

No utilizar una gran cantidad de menús.

Estructura recomendada:

``` text
Login
  │
  └── Inicio
       ├── Nueva No Conformidad
       └── Mis No Conformidades
              └── Detalle
```

Puede existir una acción de cerrar sesión desde Inicio.

------------------------------------------------------------------------

# 17. Diseño visual

El diseño debe ser:

-   Profesional.
-   Limpio.
-   Moderno.
-   Simple.
-   Fácil de utilizar en teléfono.
-   Adecuado para Prevención de Riesgos.

No copiar los colores ni la apariencia de la APK antigua salvo que
posteriormente ABICK defina una identidad visual específica.

Prioridad:

1.  Legibilidad.
2.  Facilidad de uso.
3.  Formularios rápidos.
4.  Botones claros.
5.  Estados fáciles de distinguir.
6.  Fotografías fáciles de agregar.

Evitar:

-   Pantallas saturadas.
-   Animaciones innecesarias.
-   Menús complicados.
-   Información redundante.
-   Funciones que no formen parte del alcance.

------------------------------------------------------------------------

# 18. Funcionalidades que NO estarán en V1

No implementar inicialmente:

-   Geolocalización/GPS.
-   Firma digital.
-   Chat.
-   Notificaciones push.
-   Generación de PDF.
-   Reportes avanzados.
-   Gráficos avanzados.
-   Integración con ERP.
-   Integración con Google Sheets.
-   Integración con Google Forms.
-   Roles administrativos complejos.
-   Flujos de aprobación.
-   Múltiples niveles de estados.
-   Reconocimiento automático de fotografías.
-   Funciones que no hayan sido solicitadas.

Si durante el desarrollo Claude considera necesario agregar algo,
primero debe explicarlo y justificarlo antes de implementarlo.

------------------------------------------------------------------------

# 19. Principios de desarrollo

## 19.1 Simplicidad

La aplicación debe resolver un problema concreto.

No sobreingenierizar.

## 19.2 Separación

Mantener separadas:

``` text
Flutter
API
Base de datos
ERP
```

El ERP es externo y no debe modificarse.

## 19.3 Desarrollo incremental

No construir toda la aplicación de una sola vez.

Orden recomendado:

``` text
1. Preparar estructura del proyecto
2. Diseñar base de datos
3. Crear API
4. Probar API
5. Crear login Flutter
6. Crear inicio
7. Crear registro de NC
8. Crear listado
9. Crear detalle
10. Implementar estados
11. Implementar fotografías
12. Integrar todo
13. Pruebas
14. Generar APK
```

------------------------------------------------------------------------

# 20. Rol de Claude

Claude será utilizado como principal asistente de implementación.

Sin embargo, Claude debe trabajar bajo este documento como contexto
funcional.

Antes de realizar cambios importantes debe:

1.  Analizar el código actual.
2.  Explicar brevemente qué encontró.
3.  Proponer el cambio.
4.  Implementar solamente lo solicitado.
5.  Indicar qué archivos modificó.
6.  Indicar cómo probarlo.
7.  No modificar componentes no relacionados.

No debe asumir funcionalidades adicionales.

------------------------------------------------------------------------

# 21. Rol del Code Reviewer

ChatGPT actuará como **Code Reviewer y guía técnica del proyecto**.

El flujo será:

``` text
Usuario
   ↓
Solicita siguiente tarea
   ↓
ChatGPT prepara prompt corto
   ↓
Usuario pega prompt en Claude
   ↓
Claude implementa
   ↓
Usuario trae respuesta/código
   ↓
ChatGPT revisa
   ↓
ChatGPT indica correcciones o siguiente paso
```

Los prompts destinados a Claude deben ser:

-   Concisos.
-   Directos.
-   Específicos.
-   Listos para copiar y pegar.
-   Sin explicaciones innecesarias.

No se debe entregar a Claude una tarea gigantesca si puede dividirse en
pasos pequeños.

------------------------------------------------------------------------

# 22. Regla fundamental sobre el ERP

La aplicación tendrá una base de datos propia.

**NO modificar el ERP.**

**NO modificar la base de datos del ERP.**

**NO ejecutar cambios sobre tablas del ERP.**

**NO reutilizar directamente la BD del ERP.**

La nueva aplicación debe ser independiente.

Si en el futuro se requiere integración con el ERP, se analizará como
una etapa separada.

------------------------------------------------------------------------

# 23. Resultado esperado de V1

Al finalizar la primera versión debe ser posible:

``` text
Usuario abre la aplicación
        ↓
Inicia sesión
        ↓
Ve Inicio
        ↓
Crea una No Conformidad
        ↓
Completa los datos
        ↓
Toma/agrega fotografías
        ↓
Guarda el registro
        ↓
El registro queda como NUEVA
        ↓
Puede consultarlo
        ↓
Puede cambiarlo a EN PROCESO
        ↓
Puede cambiarlo a CERRADA
```

Eso es suficiente para considerar funcional la primera versión.

------------------------------------------------------------------------

# 24. Criterio de éxito

La aplicación será considerada exitosa si un trabajador de Prevención de
Riesgos puede:

> **Registrar una situación detectada en terreno rápidamente, agregar
> evidencia fotográfica y posteriormente consultar y actualizar su
> estado sin necesitar conocimientos técnicos.**

La prioridad no es tener muchas funciones.

La prioridad es que las pocas funciones existentes funcionen bien.

------------------------------------------------------------------------

# 25. Decisión tecnológica inicial

Frontend:

**Flutter / Dart**

Backend:

**API HTTP/HTTPS**

Base de datos:

**MySQL**

Administración de BD:

**phpMyAdmin**

Servidor:

**Máquina virtual dentro de la infraestructura de ABICK**

Cliente principal:

**Android**

La tecnología concreta del backend puede ser definida durante la fase
inicial, priorizando simplicidad, facilidad de mantenimiento y
compatibilidad con el servidor de ABICK.

------------------------------------------------------------------------

# 26. Estado del proyecto

Actualmente:

-   La APK antigua existe y fue analizada.
-   Se decidió NO replicarla.
-   Se decidió crear una aplicación nueva en Flutter.
-   La nueva aplicación será para Prevención de Riesgos de ABICK.
-   La BD todavía no existe.
-   La BD se creará desde cero.
-   La BD estará en una máquina virtual del servidor de ABICK.
-   Se utilizará MySQL.
-   phpMyAdmin será utilizado para administrar MySQL.
-   Se utilizará una API entre Flutter y MySQL.
-   El ERP permanecerá completamente separado.
-   La V1 tendrá login, no conformidades, estados y fotografías.
-   No se desean funcionalidades adicionales en esta etapa.

------------------------------------------------------------------------

# 27. Resumen ejecutivo para Claude

Estamos creando desde cero una aplicación Flutter para el Departamento
de Prevención de Riesgos de ABICK.

La aplicación reemplazará funcionalmente a un sistema Android antiguo de
registro de no conformidades. La APK antigua solo se utilizará como
referencia para entender el concepto; no se debe intentar replicar ni
convertir.

La V1 debe ser simple y contener:

-   Login.
-   Inicio.
-   Crear no conformidad.
-   Listar no conformidades.
-   Ver detalle.
-   Estados: Nueva, En proceso y Cerrada.
-   Fotografías.

La arquitectura será:

``` text
Flutter → API → MySQL
```

MySQL estará en una máquina virtual del servidor de ABICK y será
administrado mediante phpMyAdmin.

El ERP y su base de datos son completamente independientes y NO deben
modificarse.

No agregar funcionalidades no solicitadas.

Priorizar simplicidad, seguridad, mantenibilidad y desarrollo
incremental.

ChatGPT actuará como code reviewer y entregará a Claude instrucciones
cortas y concretas para cada etapa.
