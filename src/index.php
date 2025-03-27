<?php

// Test PHP connection
//phpinfo();

// Test PostgreSQL connection (uncomment when you want to test)

try {
    $host = getenv('POSTGRES_HOST');
    $dbname = getenv('POSTGRES_DB');
    $user = getenv('POSTGRES_USER');
    $password = getenv('POSTGRES_PASSWORD');

    $dsn = "pgsql:host=$host;dbname=$dbname";
    $pdo = new PDO($dsn, $user, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    echo "<h2>Connected to PostgreSQL successfully!</h2>";

    // Example query
    $stmt = $pdo->query('SELECT version()');
    $version = $stmt->fetch();
    echo "<p>PostgreSQL version: " . $version[0] . "</p>";
} catch (PDOException $e) {
    echo "<h2>PostgreSQL connection failed:</h2>";
    echo "<p>" . $e->getMessage() . "</p>";
}

