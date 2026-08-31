<?php

try {
    // MySQL runs in this same container, so the application connects locally.
    $pdo = new PDO(
        'mysql:host=127.0.0.1;dbname=tswdb;charset=utf8mb4',
        'tswuser',
        'tswpass'
    );

    echo 'PHP -> MySQL OK';
} catch (PDOException $e) {
    // Keep connection details in the container logs instead of the HTTP response.
    error_log($e->getMessage());
    http_response_code(500);
    echo 'PHP -> MySQL ERROR';
}
