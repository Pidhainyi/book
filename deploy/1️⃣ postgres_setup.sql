-- postgres_setup.sql
-- Скрипт створення бази та користувача PostgreSQL для Symfony

DO
$do$
BEGIN
   IF NOT EXISTS (SELECT FROM pg_catalog.pg_user WHERE usename = 'symfony_user') THEN
      CREATE USER symfony_user WITH PASSWORD 'symfony_pass';
END IF;
END
$do$;

CREATE DATABASE symfony_db OWNER symfony_user;
