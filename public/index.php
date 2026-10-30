<?php
// ESTE ARCHIVO SERÁ EL PUNTO DE ENTRADA DE LA APP, LO QUE HARÁ ES RECIBIR LAS PETICIONES DE LOS CLIENTES.
declare(strict_types=1);

use Izquierdo\KardexPlus\Nucleo\Router;
use Izquierdo\KardexPlus\Nucleo\Respuesta;
use Izquierdo\KardexPlus\BaseDatos\Conexion;
require_once dirname(__DIR__, 1) . "/src/ayudantes.php";

// Carga el autoloader de Composer para utilizar las dependencias instaladas.
require_once dirname(__DIR__, 1) . '/vendor/autoload.php';

/* Obtiene un objeto de configuración Dotenv, es decir, crea una instancia/configuración de Dotenv tomando como ubicación
base la raíz del proyecto. */
$dotenv = \Dotenv\Dotenv::createImmutable(dirname(__DIR__, 1));

// Carga las variables definidas en .env
$dotenv->load();

$rutaBase = $_ENV['APP_BASE_PATH'] ?? '';

$router = new Router();

$router
    ->get('/productos', function (): Respuesta {
        return Respuesta::exito('¡Recurso mostrado exitosamente!');
    })
    ->get('/estado', function (): Respuesta {
        try {
            Conexion::obtenerConexion();

            return Respuesta::exito('Conexión exitosa a la base de datos', ['bd' => 'conectada']);
        } catch (PDOException $e) {
            return Respuesta::errorInterno($e->getMessage());
        }
    })
    ->post('/productos', function (): Respuesta {
        return Respuesta::creado('¡Recurso creado exitosamente!');
    });

/* Averiguar qué ruta exacta solicitó el cliente. $_SERVER['REQUEST_URI'] trae rutas como "/kardex-plus/public/productos?activo=1".
Lo que hace parse_url con la bandera PHP_URL_PATH, es que solo se queda con la parte de la ruta, sin query string, quedando
así, por ejemplo: "/kardex-plus/public/productos".  */
$rutaSolicitada = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
$rutaFinal = quitarPrefijoBase($rutaSolicitada, $rutaBase);

// Averiguar método HTTP usado, PHP lo trae listo con la variable superglobal $_SERVER['REQUEST_METHOD'].
$metodoSolicitado = $_SERVER['REQUEST_METHOD'];

$resultado = $router->despachar($metodoSolicitado, $rutaFinal);
enviarRespuestaJson($resultado);