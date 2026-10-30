<?php
declare(strict_types=1);

use Izquierdo\KardexPlus\Nucleo\Respuesta;

// Envía una respuesta HTTP en formato JSON y termina la ejecución.
function enviarRespuestaJson(Respuesta $respuesta): void
{
    // Indica encabezado de la respuesta HTTP
    header('Content-Type: application/json; charset=utf-8');

    // Indica encabezados extra de la respuesta HTTP
    foreach ($respuesta->encabezados as $nombreEncabezado => $valorEncabezado) {
        header($nombreEncabezado . ': ' . $valorEncabezado);
    }

    http_response_code($respuesta->codigoHttp);

    echo json_encode($respuesta->cuerpo, JSON_UNESCAPED_UNICODE | JSON_THROW_ON_ERROR | JSON_UNESCAPED_SLASHES);
    exit();
}

/* Devuelve la ruta sin el prefijo para que las rutas queden limpias, entendibles y legibles, ej.: 'GET /productos'
se entiende mejor que 'GET /kardex-plus/public/productos'. Además, permite una separación de responsabilidades clara,
ya que saber dónde está instalada la app es un dato de configuración, no de enrutamiento. */
function quitarPrefijoBase(string $ruta, string $prefijo): string
{
    // Devuelve la $ruta tal cual si NO empieza por $prefijo.
    if (!str_starts_with($ruta, $prefijo)) {
        return $ruta;
    }

    return substr($ruta, strlen($prefijo));
}