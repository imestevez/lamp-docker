<?php

try {
    $pdo = new PDO(
        'mysql:host=127.0.0.1;dbname=tswdb;charset=utf8mb4',
        'tswuser',
        'tswpass'
    );

    echo 'PHP -> MySQL OK';
} catch (PDOException $e) {
    echo $e->getMessage();
}
