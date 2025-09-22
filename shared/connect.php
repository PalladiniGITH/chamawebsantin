<?php
$host = getenv('DATABASE_HOST') ?: '192.168.8.34';
$port = getenv('DATABASE_PORT') ?: '3306';
$db   = getenv('DATABASE_NAME') ?: 'chamaweb';
$user = getenv('DATABASE_USER') ?: 'app_user';
$pass = getenv('DATABASE_PASSWORD') ?: '08^8nG0E9U@a';
$ca   = getenv('MYSQL_SSL_CA') ?: '';

$dsn = sprintf('mysql:host=%s;port=%s;dbname=%s;charset=utf8mb4', $host, $port, $db);
$options = [
    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
];

if (!empty($ca)) {
    if (file_exists($ca) && defined('PDO::MYSQL_ATTR_SSL_CA')) {
        $options[PDO::MYSQL_ATTR_SSL_CA] = $ca;
    } else {
        error_log('MYSQL_SSL_CA definido, mas arquivo não encontrado ou suporte PDO ausente: ' . $ca);
    }
}

try {
    $pdo = new PDO($dsn, $user, $pass, $options);
} catch (PDOException $e) {
    error_log('DB connection failed: ' . $e->getMessage());
    throw $e;
}
