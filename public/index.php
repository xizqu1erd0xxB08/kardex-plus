<?php
declare(strict_types=1);

/* Averiguar qué ruta exacta solicitó el cliente. $_SERVER['REQUEST_URI'] trae rutas como "/kardex-plus/public/productos?activo=1".
Lo que hace parse_url con la bandera PHP_URL_PATH, es que solo se queda con la parte de la ruta, sin query string, quedando
así, por ejemplo: "/kardex-plus/public/productos"  */
$rutaSolicitada = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);

/* Averiguar método HTTP usado, PHP lo trae listo con la variable superglobal $_SERVER['REQUEST_METHOD']. */
$metodoSolicitado = $_SERVER['REQUEST_METHOD'];

# Función tipada que decida qué responder según la combinación de ruta + método
function manejarPeticion(string $ruta, string $metodo): array
{
    if ($ruta === '/kardex-plus/public/estado' && $metodo === 'GET') {
        return [
            'estado' => 'ok',
            'mensaje' => 'Kardex+ está vivo bro!'
        ];
    }

    # Si ninguna ruta coincide, es un error 404 real (no encontrado, la URL no existe).
    http_response_code(404);
    return [
        'estado' => 'error',
        'mensaje' => 'ruta no encontrada'
    ];
}

header('Content-Type: application/json; charset=utf-8');
echo json_encode(manejarPeticion($rutaSolicitada, $metodoSolicitado), JSON_UNESCAPED_UNICODE);
/* <?php
 Esto le dice a php que sea estricto con los tipos de datos, para evitar que silenciosamente php convierta datos como
"5" (string) a 5 (int), esto evita bugs y errores en capas más abajo. Línea fundamental en todos los archivos php.
declare(strict_types=1);

Esta línea escribe el encabezado de la respuesta HTTP, le dice al cliente (Postman, un navegador, un frontend en JS)
que el cuerpo de la respuesta está en formato JSON y que usa la codificación UTF-8 para que soporte tildes y la ñ.
Es importante que este header() esté antes de cualquier otro texto del script, como un echo o un espacio en blanco, si
ya salió algo antes, php responderá con error: "headers already sent".
header('Content-Type: application/json; charset=utf-8');

Declara de manera explícita el código de estado que debe devolver la respuesta http. Es una buena práctica hacerlo,
ya que se hace la pregunta: "¿Qué código le corresponde a este resultado?", en cada respuesta que se vaya a armar.
http_response_code(200);

Toma un array asociativo de php y lo convierte en un string con formato json válido, es este string el que finalmente
se envía como cuerpo de la respuesta. Es el "echo" final y único de todo el script.
JSON_UNESCAPED_UNICODE es una bandera para que json_encode escriba caracteres utf-8 tal cual, es decir, escribe: á en vez
de \u00e1. Usar esta bandera es la práctica estándar actual.
echo json_encode([
    'estado' => 'ok',
    'mensaje' => 'Kardex+ está vivo kbrones!',
    'version' => '0.1.0',
], JSON_UNESCAPED_UNICODE);

Con todo esto, ya esta respuesta emite datos estructurados: content-type declarado, respuesta http declarada, cuerpo
declarado con el "echo json_encode...". Ahora, cualquier cliente puede parsearlos (masticar y digerir la información)
de manera confiable. */