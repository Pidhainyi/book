Copy
# PHP Project with Docker (PHP-FPM, Nginx, PostgreSQL)

## Setup Instructions

1. Clone this repository
2. Make sure you have Docker and Docker Compose installed
3. Create a `.env` file in the project root if you want to override default database credentials:


## How to Use This Setup

1. Clone this structure or create the files manually
2. Run `docker-compose up -d --build` to start all services
3. Access your application at `http://localhost:8080`
4. Use `docker exec -it php-cli bash` to enter the PHP CLI container for running commands like Composer, Artisan, etc.

This setup provides:
- PHP-FPM 8.2 for processing PHP files
- Nginx as the web server
- PostgreSQL as the database
- PHP-CLI container for running commands
- Proper networking between containers
- Persistent storage for PostgreSQL data
- Environment variables for configuration
- Basic error display for development

You can now start adding your PHP application code in the `src/` directory.