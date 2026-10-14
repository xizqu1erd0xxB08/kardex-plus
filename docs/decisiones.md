# Bitácora de deciciones - Kardex+ (Architecture Decision Record)

> ## Arquitectura por capas adoptada en Kardex+ (con el ejemplo de "un cajero quiere crear un producto nuevo": POST /productos)
> - **Cliente**: (Postman) Se recibe una petición HTTP -> POST /kardex-plus/public/productos  { "nombre": "Leche", 
> "precio_venta": 4200, ... }
> - **ROUTER**: indica a dónde debe ir -> Mira: ¿ruta = /productos? ¿Método = POST? → SÍ → llama al ProductoController.
> El Router no sabe nada de qué es un producto, ni de reglas de negocio, ni del SQL. Solo decide a dónde debe ir cada petición.
> **Es el traductor entre una petición HTTP y una acción de la aplicación.**
> - **CONTROLLER** (ProductoController): recibe la petición -> Extrae los datos del cuerpo de la petición (el JSON que 
> mandó el cliente), los valida de forma básica (¿vino 'nombre'? ¿Vino 'precio_venta'?), llama al Servicio pasándole esos 
> datos, y cuando el Servicio responde, arma la respuesta HTTP (código 201, o 400 si algo venía mal) usando enviarRespuestaJson().
> NO decide reglas de negocio, solo **ORQUESTA**. **¿Cómo convierto la petición HTTP en una llamada a la aplicación y cómo 
> devuelvo la respuesta HTTP?** 
> - **SERVICE** (ProductoService): indica qué debe hacer (lógica) -> AQUÍ VIVEN LAS REGLAS DE NEGOCIO DE VERDAD: ¿la categoría 
> que mandaron existe y pertenece a este negocio? ¿El precio es válido? Si todo está bien, le pide al Repositorio que lo guarde.
> El Servicio NO sabe qué es HTTP, ni Postman, ni códigos de estado -- podría llamarse igual desde un script de consola 
> o una tarea programada, sin cambiar una línea. En resumen, se encarga de: **¿Qué debe suceder según las reglas del negocio?**
> - REPOSITORY (ProductoRepository): **se comunica con la base de datos** -> AQUÍ, y SOLO AQUÍ, vive el SQL real: el 
> INSERT INTO productos (...), usando PDO con consultas preparadas. El Repositorio no sabe de reglas de negocio, solo 
> sabe "guardar esto en la tabla productos" y "traer esto de la tabla productos". **Es la única capa que le habla directamente 
> a MariaDB. ¿Cómo guardo o recupero los datos?**

## Multi-tenancy: tablas compartidas + negocio_id
**Decisión:** una sola base de datos, negocio_id en cada tabla del negocio, FK compuestas donde hay más de un "camino" hacia
el negocio en la misma fila (Riesgo A/B).
> El **riesgo A** hace referencia a que en una tabla, **una fila tiene un único camino hacia al tenant** (en este caso, el negocio),
> y basta con sellar esa relación. El **riesgo B**, por otro lado, tiene **múltiples caminos distintos hacia el tenant**, por ejemplo:
> lotes (pertenecen a un tenant específico), productos (pertenecen a un tenant específico), categorías (pertenecen a un
> tenant específico). En este caso, **sellar una relación no va a proteger a las demás, por lo tanto, es necesario sellarlas
> todas**. Cada uno necesita sus propias FK compuestas.

**Por qué:** se toma esta decisión debido a que el propósito principal del proyecto es ser usado por múltiples negocios usando
únicamente una sola base de datos, mejorando la mantenibilidad y haciendo el proyecto escalable para todos los usuarios.


## Administrador supremo
**Decisión:** columna generada + UNIQUE + triggers BEFORE INSERT/UPDATE

**Por qué:** es importante que exista un administrador con un rango superior al de los demás, con el fin permitir que haya
un administrador con la capacidad de poner orden sobre los demás usuarios que tengan el rol de administrador también.
Además de permitir que este administrador supremo sea el que tenga la última palabra, la capacidad y la responsabilidad 
de tomar decisiones ante hechos reales que puedan pasar en el día a día en el negocio.

## Front Controller + mod_rewrite
**Decisión:** todo pasa por public/index.php vía .htaccess
**Por qué:** centraliza TODA petición en un **único punto de control**, sin importar la URL. Esto permite aplicar lógica común 
(enrutamiento, y más adelante autenticación, logging) en un solo lugar en vez de repetirla en cada archivo. Como efecto 
secundario, también **impide que alguien acceda directamente a un archivo interno sin pasar por esa validación central**.

## Próximos pasos
- Extraer el Router de index.php a su propia clase
- Construir ProductoRepository

> **La información que se devuelve de un recurso depende del caso de uso. Por ejemplo, para productos:** 
> - CU01: Listado general de productos. (id, nombre, categoría, unidad, precio, IVA, activo).
> - CU02: Detalle de un producto. (id, nombre, descripción, negocio, categoría, unidad de medida, IVA, precio, código de
> barras, fechas)-
> - CU03: Pantalla de venta de un producto (nombre, precio, IVA, cantidad vendida).

# Proceso a seguir al momento de realizar funcionalidades nuevas:

REQUISITO

↓

¿Qué quiere hacer el usuario?

↓

¿Qué datos necesita?

↓

¿Qué entidades participan?

↓

¿Qué reglas existen?

↓

¿Qué puede salir mal?

↓

¿Qué operaciones de BD necesitamos?

↓

¿Hay varias operaciones que deban ser atómicas?

↓

¿Qué responsabilidad tiene cada capa?

↓

¿Qué clases necesitamos?

↓

Implementación

↓

Prueba

↓

Reflexión: "¿Cómo habría llegado yo a esto solo?"

## Enrutamiento centralizado

**Decisión:** utilizar una clase Router para registrar y resolver
las rutas HTTP de la aplicación.

**Por qué:** separar la responsabilidad de enrutamiento del
Front Controller (`public/index.php`), evitando que este acumule
la lógica de resolución de rutas y facilitando la evolución de
la aplicación hacia Controller → Service → Repository.

> **Router.php:** es la clase que implementa el mecanismo de enrutamiento. Sabe cómo registrar y resolver rutas. No tiene
> lógica de negocio.
> **rutas.php:** es la cnfiguración de las rutas de la app, es decir, el archivo que define qué rutas existen.
> **index.php:** recibe/prepara la petición http y pone en marcha la app.