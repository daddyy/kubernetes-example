<?php
require_once(__DIR__ . DIRECTORY_SEPARATOR . 'boostrap.php');

use app\Helpers\Util;

header('Content-Type: application/json; charset=utf-8');
echo json_encode(app(), JSON_PRETTY_PRINT);

/**
 * @return array<string|int|PDO>
 */

function app(): array
{
    return [
        'date' => date('c'),
        'php' => phpversion(),
        'my_addr' => Util::getRemoteIp(),
        'db' => connection(
            (string) getenv('MYSQL_HOST'),
            (string) getenv('MYSQL_DATABASE'),
            getenv('MYSQL_USER'),
            getenv('MYSQL_PASSWORD')
        ),
        'remote_addr' => $_SERVER['REMOTE_ADDR'],
        'server_addr' => $_SERVER['SERVER_ADDR'],
        'app_mode' => $_ENV['APP_MODE'],
        'app_image_version' => $_ENV['APP_IMAGE_VERSION'],
        'nginx_image_version' => $_ENV['NGINX_IMAGE_VERSION'],
        'test_file' => @file_get_contents(FILE_TESTING_LOOP)
    ];
}

function connection(string $mysqlHost, string $tableName, ?string $user, ?string $password): PDO
{
    ini_set('mysql.connect_timeout', '3');
    return new PDO("mysql:dbname=" . $tableName . ";host=" . $mysqlHost, $user, $password);
}

function checkConnection(string $ip, int $port, int $timeout = 1): bool
{
    $connection = @fsockopen($ip, $port, $errno, $errstr, $timeout);

    if (!$connection) {
        return false;
    }

    fclose($connection);
    return true;
}