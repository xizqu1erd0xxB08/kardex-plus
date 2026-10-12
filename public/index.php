<?php
/*
ESTE ARCHIVO SERÁ EL PUNTO DE ENTRADA DE LA APP, LO QUE HARÁ ES RECIBIR LAS PETICIONES DE LOS CLIENTES, POR EJEMPLO:
Petición: GET /kardex-plus/public/estado
Pasos a seguir:
    1. Preparar entorno.
    2. Cargar dependencias.
    3. Cargar configuración.
    4. Determinar rutas.
    5. Ejecutar lógica.
    6. Devolver respuesta.
*/
declare(strict_types=1);

// Cargar el autoloader de Composer para poder utilizar las dependencias instaladas.
require_once dirname(__DIR__, 1) . '/vendor/autoload.php';

/* Llamar al método estático Dotenv::createImmutable() para obtener un objeto de configuración Dotenv, es decir, crea una
instancia/configuración de Dotenv tomando como ubicación base la raíz del proyecto. */
$dotenv = \Dotenv\Dotenv::createImmutable(dirname(__DIR__, 1));

// Carga las variables definidas en .env
$dotenv->load();

// Cargar la clase Conexion creada en /src/baseDatos/Conexion.php
require_once dirname(__DIR__, 1) . '/src/baseDatos/Conexion.php';

require_once dirname(__DIR__, 1) . '/src/ayudantes.php';

require_once dirname(__DIR__, 1) . '/src/Nucleo/Router.php';

$router = new Router();

$router
    ->get('/productos', function (): array {
        return [
            'codigoHttp' => 200,
            'cuerpo' => [
                'estado' => 'ok',
                'mensaje' => 'Los productos se mostrarán aquí, esto es solo un ejemplo de éxito.',
            ],
        ];
    })
    ->get('/estado', function (): array {
        try {
            Conexion::obtenerConexion();

            return [
                'codigoHttp' => 200,
                'cuerpo' => [
                    'estado' => 'ok',
                    'mensaje' => 'Kardex+ está vivo bro!',
                    'bd' => 'conectada',
                ],
            ];
        } catch (PDOException $e) {
            return [
                'codigoHttp' => 500,
                'cuerpo' => [
                    'estado' => 'error',
                    'mensaje' => 'Kardex+ está vivo, pero no se pudo conectar a la base de datos',
                    'bd' => 'error: ' . $e->getMessage()
                ],
            ];
        }
    })
    ->post('/productos', function (): array {
        return [
            'codigoHttp' => 201,
            'cuerpo' => [
                'estado' => 'ok',
                'mensaje' => 'Esto crea un producto, es un ejemplo de éxito: Producto Creado Exitosamente!',
            ],
        ];
    });

/* Averiguar qué ruta exacta solicitó el cliente. $_SERVER['REQUEST_URI'] trae rutas como "/kardex-plus/public/productos?activo=1".
Lo que hace parse_url con la bandera PHP_URL_PATH, es que solo se queda con la parte de la ruta, sin query string, quedando
así, por ejemplo: "/kardex-plus/public/productos".  */
$rutaSolicitada = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);

/* Averiguar método HTTP usado, PHP lo trae listo con la variable superglobal $_SERVER['REQUEST_METHOD']. */
$metodoSolicitado = $_SERVER['REQUEST_METHOD'];

// Función tipada que decida qué responder según la combinación de ruta + método.
/*function manejarPeticion(string $ruta, string $metodo): array
{
    if ($ruta === '/kardex-plus/public/estado' && $metodo === 'GET') {
        try {
            Conexion::obtenerConexion();

            return [
                'codigoHttp' => 200,
                'cuerpo' => [
                    'estado' => 'ok',
                    'mensaje' => 'Kardex+ está vivo bro!',
                    'bd' => 'conectada',
                ],
            ];
        } catch (PDOException $e) {
            return [
                'codigoHttp' => 500,
                'cuerpo' => [
                    'estado' => 'error',
                    'mensaje' => 'Kardex+ está vivo, pero no se pudo conectar a la base de datos',
                    'bd' => 'error: ' . $e->getMessage()
                ],
            ];
        }
    }

    if ($ruta === '/kardex-plus/public/productos' && $metodo === 'GET') {
        return [
            'codigoHttp' => 200,
            'cuerpo' => [
                'estado' => 'ok',
                'mensaje' => 'Los productos se mostrarán aquí, esto es solo un ejemplo de éxito.',
            ],
        ];
    }

    if ($ruta === '/kardex-plus/public/productos' && $metodo === 'POST') {
        return [
            'codigoHttp' => 201,
            'cuerpo' => [
                'estado' => 'ok',
                'mensaje' => 'Esto crea un producto, es un ejemplo de éxito: Producto Creado Exitosamente!',
            ],
        ];
    }

    // Si ninguna ruta coincide, es un error 404 real (no encontrado, la URL no existe).
    return [
        'codigoHttp' => 404,
        'cuerpo' => [
            'estado' => 'error',
            'mensaje' => 'ruta no encontrada',
        ],
    ];
}
*/

// $resultado = manejarPeticion($rutaSolicitada, $metodoSolicitado);
$resultado = $router->despachar('GET', '/estado');
$resultado2 = $router->despachar('GET', '/productos');
$resultado3 = $router->despachar('POST', '/estado');
$resultado4 = $router->despachar($metodoSolicitado, $rutaSolicitada);

//enviarRespuestaJson($resultado['cuerpo'], $resultado['codigoHttp']);
//enviarRespuestaJson($resultado2['cuerpo'], $resultado2['codigoHttp']);
//enviarRespuestaJson($resultado3['cuerpo'], $resultado3['codigoHttp']);
// enviarRespuestaJson($resultado4['cuerpo'], $resultado4['codigoHttp']);

//var_dump($metodoSolicitado, $rutaSolicitada);
//var_dump(array_keys($router->mostrarRutas()['GET']));
//die();