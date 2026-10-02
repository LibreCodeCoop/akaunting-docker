#!/usr/bin/env php
<?php

declare(strict_types=1);

$connection = getenv('DB_CONNECTION') ?: 'mysql';

if (in_array($connection, ['sqlite', 'sqlite3'], true)) {
    exit(0);
}

$host = getenv('DB_HOST') ?: 'localhost';
$database = getenv('DB_DATABASE') ?: '';
$username = getenv('DB_USERNAME') ?: '';
$password = getenv('DB_PASSWORD') ?: '';
$timeout = max(1, (int) (getenv('DB_WAIT_TIMEOUT') ?: 60));

$defaultPort = $connection === 'pgsql' ? 5432 : 3306;
$port = (int) (getenv('DB_PORT') ?: $defaultPort);

$dsn = match ($connection) {
    'mysql', 'mariadb' => sprintf('mysql:host=%s;port=%d;dbname=%s', $host, $port, $database),
    'pgsql', 'postgres', 'postgresql' => sprintf('pgsql:host=%s;port=%d;dbname=%s', $host, $port, $database),
    default => throw new RuntimeException(sprintf('Unsupported DB_CONNECTION "%s" for database readiness check.', $connection)),
};

$deadline = time() + $timeout;
$lastError = null;

do {
    try {
        new PDO($dsn, $username, $password, [
            PDO::ATTR_TIMEOUT => 3,
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        ]);

        exit(0);
    } catch (Throwable $e) {
        $lastError = $e->getMessage();
        sleep(1);
    }
} while (time() < $deadline);

fwrite(
    STDERR,
    sprintf(
        "Database did not become ready within %d seconds (%s:%d): %s\n",
        $timeout,
        $host,
        $port,
        $lastError ?? 'unknown error'
    )
);

exit(1);
