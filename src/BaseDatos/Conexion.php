<?php
declare(strict_types=1);

/* 'final' indica que la clase NO puede ser heredada porque la clase es diseñada específicamente para gestionar la
conexión, además, evita que alguien modifique el comportamiento de esta mediante herencia  */
final class Conexion
{
    /* 'static' -> propiedad perteneciente a la clase, se accede desde 'Conexion::$instancia', NO mediante '$conexion->instancia'.
    Crea una referencia compartida a la conexión administrada por la clase. */
    private static ?PDO $instancia = null;

    public static function obtenerConexion(): PDO
    {
        /* 'self' hace referencia a la propia clase. Por ello, se relaciona con 'static' porque los miembros estáticos se
        acceden desde la clase ('self::$instancia') porque $instancia es 'static'.
        Si la conexión no existe (es null), la crea una sola vez y la reutiliza durante la petición. */
        if (self::$instancia === null) {
            # Construye DSN usando los valores de configuración del entorno.
            $dsn = sprintf(
                'mysql:host=%s;port=%s;dbname=%s;charset=utf8mb4',
                $_ENV['DB_HOST'],
                $_ENV['DB_PORT'],
                $_ENV['DB_DATABASE']
            );

            /* Crea un objeto PDO configurado para conectarse a la base de datos utilizando las credenciales de entorno
            y las reglas de comportamiento. */
            self::$instancia = new PDO(
                $dsn,
                $_ENV['DB_USERNAME'],
                $_ENV['DB_PASSWORD'],
                [
                    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION, // maneja los errores mediante excepciones
                    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC, // retorna datos de la BD en arrays asociativos
                    PDO::ATTR_EMULATE_PREPARES => false, // Usa consultas preparadas nativas cuando el controlador las soporte.
                ]
            );
        }

        return self::$instancia;
    }
}