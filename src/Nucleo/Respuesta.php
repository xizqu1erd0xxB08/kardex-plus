<?php
declare(strict_types=1);

final class Respuesta
{
    /**
     * Obliga a que toda respuesta tenga una estructura base fija: código HTTP, cuerpo y encabezados (si no existen, quedan
     * como array vacío)
     *
     * @param array<string, mixed> $cuerpo
     * @param array<string, string> $encabezados
     */
    public function __construct(
        public readonly int $codigoHttp,
        public readonly array $cuerpo,
        public readonly array $encabezados = [],
    ) {
    }

    public static function noEncontrada(string $mensaje = 'ruta no encontrada'): self
    {
        return new self(
            codigoHttp: 404,
            cuerpo: [
                'estado' => 'error',
                'mensaje' => $mensaje,
            ],
        );
    }

    /**
     * @param string[] $metodosPermitidos
     */
    public static function metodoNoPermitido(array $metodosPermitidos): self
    {
        return new self(
            codigoHttp: 405,
            cuerpo: [
                'estado' => 'error',
                'mensaje' => 'método no válido para esta ruta',
            ],
            encabezados: [
                'Allow' => implode(', ', $metodosPermitidos),
            ],
        );
    }
}