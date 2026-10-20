<?php
declare(strict_types=1);

require_once dirname(__DIR__, 1) . "/src/Nucleo/Respuesta.php";

/**
 * Envía una respuesta HTTP en formato JSON y termina la ejecución.
 *
 * @param array<string, mixed> $datos Datos a enviar con claves string y valores de cualquier tipo
 * @param array<string, string> $encabezados Cabeceras a enviar tendrán formato: nombre => valor
 */
function enviarRespuestaJson(array $datos, int $codigoHttp, array $encabezados = []): void
{
    // Indica encabezado de la respuesta HTTP
    header('Content-Type: application/json; charset=utf-8');

    // Indica encabezados extra de la respuesta HTTP
    foreach ($encabezados as $nombre => $valor) {
        header($nombre . ': '. implode(', ', $valor));
    }

    http_response_code($codigoHttp);

    /* Envía respuesta HTTP en formato JSON con banderas útiles para mejorar la legibilidad y depuración.
    - JSON_UNESCAPED_UNICODE: desactiva el escapar caracteres especiales (como á) en formato unicode, con el fin de que
    se vean claramente textos como 'Hola ángel' en vez de 'Hola \u00e1ngel'.
    - JSON_THROW_ON_ERROR: en caso de un error, en vez de retornar 'false', obtiene una excepción real (JsonException)
    que puede capturar y manejar explícitamente.
    - JSON_UNESCAPED_SLASHES: por defecto, json_encode() escapa las barras / como \/ (así que 'https://miweb.com' se
    volvería 'https:\/\/miweb.com'. Esta bandera evita el escape innecesario de las barras /, haciendo más legibles
    las URL dentro del JSON.
    El '|', activa simultáneamente estas tres opciones. */
    echo json_encode($datos, JSON_UNESCAPED_UNICODE | JSON_THROW_ON_ERROR | JSON_UNESCAPED_SLASHES);
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