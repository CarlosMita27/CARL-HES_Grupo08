<?php
/**
 * Conexión nativa con MySQL mediante la extensión mysqli de PHP.
 *
 * No se usa ningún framework ni ORM: la clase abre la conexión con los datos
 * de config/config.php y ejecuta los procedimientos almacenados con CALL,
 * enviando los parámetros en una sentencia preparada.
 */
final class Conexion
{
    private static ?mysqli $enlace = null;
    private static ?mysqli_sql_exception $falla = null;

    /** Datos de conexión del archivo de configuración. */
    public static function configuracion(): array
    {
        return require __DIR__ . '/../config/config.php';
    }

    /**
     * Abre una conexión nueva con los datos indicados.
     * Si falla, MySQL devuelve un código de error y se lanza mysqli_sql_exception.
     */
    public static function abrir(string $servidor, int $puerto, string $base, string $usuario, string $clave): mysqli
    {
        mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);
        $cn = new mysqli($servidor, $usuario, $clave, $base, $puerto);
        $cn->set_charset('utf8mb4');
        return $cn;
    }

    /** Devuelve la conexión del aplicativo; se abre una sola vez por página. */
    public static function obtener(): mysqli
    {
        if (self::$falla !== null) {
            throw self::$falla;
        }
        if (self::$enlace === null) {
            $c = self::configuracion();
            try {
                self::$enlace = self::abrir($c['servidor'], (int) $c['puerto'], $c['base'], $c['usuario'], $c['clave']);
            } catch (mysqli_sql_exception $e) {
                self::$falla = $e;
                throw $e;
            }
        }
        return self::$enlace;
    }

    /** Indica si la conexión del aplicativo está disponible, sin lanzar errores. */
    public static function disponible(): bool
    {
        try {
            self::obtener();
            return true;
        } catch (mysqli_sql_exception $e) {
            return false;
        }
    }

    /**
     * Ejecuta un procedimiento almacenado con la conexión del aplicativo
     * y devuelve las filas de su resultado.
     */
    public static function llamar(string $procedimiento, array $parametros = []): array
    {
        return self::llamarCon(self::obtener(), $procedimiento, $parametros);
    }

    /**
     * Ejecuta CALL procedimiento(?, ?, ...) sobre una conexión dada.
     * Devuelve el primer conjunto de resultados como arreglo asociativo.
     */
    public static function llamarCon(mysqli $cn, string $procedimiento, array $parametros = []): array
    {
        if (!preg_match('/^sp_[a-z0-9_]+$/', $procedimiento)) {
            throw new InvalidArgumentException('Nombre de procedimiento no válido: ' . $procedimiento);
        }
        $marcas = implode(', ', array_fill(0, count($parametros), '?'));
        $sentencia = $cn->prepare("CALL {$procedimiento}({$marcas})");
        if ($parametros) {
            $valores = array_values($parametros);
            $sentencia->bind_param(str_repeat('s', count($valores)), ...$valores);
        }
        $sentencia->execute();

        $filas = [];
        $resultado = $sentencia->get_result();
        if ($resultado instanceof mysqli_result) {
            $filas = $resultado->fetch_all(MYSQLI_ASSOC);
            $resultado->free();
        }
        while ($sentencia->more_results() && $sentencia->next_result()) {
            $adicional = $sentencia->get_result();
            if ($adicional instanceof mysqli_result) {
                $adicional->free();
            }
        }
        $sentencia->close();
        return $filas;
    }

    /** Ejecuta un procedimiento que devuelve una sola fila. */
    public static function llamarFila(string $procedimiento, array $parametros = []): ?array
    {
        $filas = self::llamar($procedimiento, $parametros);
        return $filas[0] ?? null;
    }
}
