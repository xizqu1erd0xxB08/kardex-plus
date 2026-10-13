<?php
/*
Esta clase se encargará de:
    - registrar rutas;
    - buscar una ruta;
    - comprobar el método HTTP;
    - ejecutar la acción correspondiente;
    - responder con 404 si no existe.
*/
declare(strict_types=1);

// Crear clase Router para representar el componente encargado del enrutamiento
final class Router
{
    /**
     * Crear libreta de rutas para que el Router las identifique y ejecute las acciones según corresponda
     *
     * @var array<string, array<string, callable>>
     */
    private array $rutas = [];

    /* Esta función crea una sección (si no existe) de métodos http (GET, POST, PUT, PATCH o DELETE) y le asigna la ruta
    específica con su función callable correspondiente a la ruta.*/
    private function agregarRuta(string $metodo, string $ruta, callable $accion): void
    {
        $this->rutas[$metodo][$ruta] = $accion;
    }

    // Registra una ruta GET y devuelve el mismo Router (self), para poder encadenar llamadas
    public function get(string $ruta, callable $accion): self
    {
        $this->agregarRuta('GET', $ruta, $accion);
        return $this;
    }

    public function post(string $ruta, callable $accion): self
    {
        $this->agregarRuta('POST', $ruta, $accion);
        return $this;
    }

    // Busca la acción registrada para cada método + ruta y la ejecuta. Devuelve el array de respuesta
    public function despachar(string $metodo, string $ruta): array
    {
        // Si no hay nada registrado para esta combinación, responder 405 o 404 y salir
        if (!isset($this->rutas[$metodo][$ruta])) {
            $metodosPermitidos = [];

            foreach ($this->rutas as $metodoRegistrado => $rutasDeEseMetodo) {
                if (isset($rutasDeEseMetodo[$ruta])) {
                    $metodosPermitidos[] = $metodoRegistrado;
                }
            }

            if ($metodosPermitidos !== []) {
                return [
                    'codigoHttp' => 405,
                    'cuerpo' => [
                        'estado' => 'error',
                        'mensaje' => 'método no válido para esta ruta',
                        'metodosPermitidos' => implode(', ', $metodosPermitidos),
                    ],
                ];
            }

            return [
                'codigoHttp' => 404,
                'cuerpo' => [
                    'estado' => 'error',
                    'mensaje' => 'ruta no encontrada',
                ],
            ];
        }

        // Llegar aquí indica que la combinación de método + ruta sí existe
        $accion = $this->rutas[$metodo][$ruta]; // Sacar la función del array (aún no se ejecuta)

        return $accion(); // Ejecutar la función del array, su resultado es el valor de despachar()
    }

    public function mostrarRutas(): array
    {
        return $this->rutas;
    }
}