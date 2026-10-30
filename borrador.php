<?php
declare(strict_types=1);

// El autoload de composer es quien se encarga de cargar los archivos
require_once dirname(__DIR__, 1) . "/kardex-plus/vendor/autoload.php";

// Se escribe el nombre completo de la clase para después poder usar el nombre corto (en este caso, Respuesta)
use Izquierdo\KardexPlus\Nucleo\Respuesta;

new Respuesta(999, []);
Respuesta::exito('Hola bro');