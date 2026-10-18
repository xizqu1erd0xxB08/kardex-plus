<?php
declare(strict_types=1);

/* Obliga a que toda respuesta tenga una estructura base fija: código HTTP, cuerpo y encabezados (si no existem, quedan
como array vacío) */
final class Respuesta
{
    public function __construct(
        public readonly int $codigoHttp,
        public readonly array $cuerpo,
        public readonly array $encabezados = [],
    ) {
    }
}