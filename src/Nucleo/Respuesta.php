<?php
declare(strict_types=1);

namespace Izquierdo\KardexPlus\Nucleo;

use InvalidArgumentException;

final class Respuesta
{
    /**
     * Obliga a que toda respuesta tenga una estructura base fija: código HTTP, cuerpo y encabezados (si no existen, quedan
     * como array vacío)
     *
     * @param array<string, mixed> $cuerpo
     * @param array<string, string> $encabezados
     * @throws InvalidArgumentException Si el valor del código HTTP no está entre 100 y 599
     */
    public function __construct(
        public readonly int $codigoHttp,
        public readonly array $cuerpo,
        public readonly array $encabezados = [],
    ) {
        if ($codigoHttp < 100 || $codigoHttp > 599) {
            throw new InvalidArgumentException(
                sprintf('El código HTTP debe estar entre 100 y 599, se recibió: %d', $codigoHttp)
            );
        }
    }

    /**
     * Da la forma base a la respuesta de éxito con código 200, quien llame la función aportará los datos para el caso
     * de éxito específico
     *
     * @param array<string, mixed> $datos
     */
    public static function exito(string $mensaje, array $datos = []): self
    {
        return new self(
            codigoHttp: 200,
            cuerpo: self::obtenerCuerpoExito($mensaje, $datos),
        );
    }

    /**
     * Da la forma base a la respuesta de éxito para un recurso creado (código 201), quien llame a la función se encarga
     * de pasar los datos específicos según el caso.
     *
     * @param array<string, mixed> $datos
     */
    public static function creado(string $mensaje, array $datos = []): self
    {
        return new self(
            codigoHttp: 201,
            cuerpo: self::obtenerCuerpoExito($mensaje, $datos),
        );
    }

    public static function noEncontrada(): self
    {
        return new self(
            codigoHttp: 404,
            cuerpo: self::obtenerCuerpoError('ruta no encontrada'),
        );
    }

    /**
     * @param string[] $metodosPermitidos
     */
    public static function metodoNoPermitido(array $metodosPermitidos): self
    {
        return new self(
            codigoHttp: 405,
            cuerpo: self::obtenerCuerpoError('método no válido para esta ruta'),
            encabezados: [
                'Allow' => implode(', ', $metodosPermitidos),
            ],
        );
    }

    public static function errorInterno(string $errorEspecifico): self
    {
        return new self(
            codigoHttp: 500,
            cuerpo: self::obtenerCuerpoError('error interno del servidor: ' . $errorEspecifico),
        );
    }

    /**
     * Retorna el cuerpo de la respuesta HTTP, si no existen datos, retorna null, si existen, los retorna junto al cuerpo
     *
     * @param array<string, mixed> $datos
     * @return array<string, mixed>
     */
    private static function obtenerCuerpoExito(string $mensaje, array $datos): array
    {
        // Si los datos no están vacíos, pero el array es una lista (lo cual indica formato incorrecto), lanza excepción
        if ($datos !== [] && array_is_list($datos)) {
            throw new InvalidArgumentException(
                'Los datos deben tener formato de objeto ["key" => "valor"], una lista ["x", "y"] ha sido recibida.'
            );
        }

        return [
            'estado' => 'ok',
            'mensaje' => $mensaje,
            'datos' => ($datos === []) ? null : $datos,
        ];
    }

    /**
     * Retorna el cuerpo de la respuesta HTTP en casos donde haya un error
     *
     * @return array<string, ?string>
     */
    private static function obtenerCuerpoError(string $mensaje): array
    {
        return [
            'estado' => 'error',
            'mensaje' => $mensaje,
            'datos' => null,
        ];
    }
}