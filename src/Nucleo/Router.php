<?php
declare(strict_types=1);

namespace Izquierdo\KardexPlus\Nucleo;

// Crea clase Router para representar el componente encargado del enrutamiento
final class Router
{
    /**
     * Crea libreta de rutas para que el Router las identifique y ejecute las acciones según corresponda
     *
     * @var array<string, array<string, callable>>
     */
    private array $rutas = [];

    // Registra una ruta GET y devuelve el mismo Router (self), para encadenar llamadas
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

    // Busca la acción registrada para cada método + ruta y la ejecuta. Devuelve el paquete de Respuesta
    public function despachar(string $metodo, string $ruta): Respuesta
    {
        // Si no existe, pregunta qué métodos permiten esta ruta; si hay alguno, 405; si no, 404.
        if (!isset($this->rutas[$metodo][$ruta])) {
            $metodosPermitidos = $this->metodosPermitidosPara($ruta);

            if ($metodosPermitidos !== []) {
                return Respuesta::metodoNoPermitido($metodosPermitidos);
            }

            return Respuesta::noEncontrada();
        }

        // Llegar aquí indica que la combinación de método + ruta sí existe
        $accion = $this->rutas[$metodo][$ruta]; // Sacar la función (aún no se ejecuta)

        return $accion(); // Ejecuta la función, su resultado es el valor de despachar()
    }

    public function mostrarRutas(): array
    {
        return $this->rutas;
    }

    /* Crea una sección (si no existe) de métodos http (GET, POST, PUT, PATCH o DELETE) y le asigna la ruta
    específica con su función callable correspondiente a la ruta. */
    private function agregarRuta(string $metodo, string $ruta, callable $accion): void
    {
        $this->rutas[$metodo][$ruta] = $accion;
    }

    /**
     * Devuelve los métodos HTTP bajo los que la ruta está registrada
     *
     * @return string[]
     */
    private function metodosPermitidosPara(string $ruta): array
    {
        $metodosPermitidos = [];

        foreach ($this->rutas as $metodoRegistrado => $rutasDeEseMetodo) {
            if (isset($rutasDeEseMetodo[$ruta])) {
                $metodosPermitidos[] = $metodoRegistrado;
            }
        }

        return $metodosPermitidos;
    }
}