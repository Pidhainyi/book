FROM postgres:15-alpine

# Copy initialization scripts
#COPY init.sql /docker-entrypoint-initdb.d/

# Set environment variables
ENV POSTGRES_USER=app_user
ENV POSTGRES_PASSWORD=secret
ENV POSTGRES_DB=app_db

EXPOSE 5432