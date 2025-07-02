#!/bin/bash
set -e

# Realiza una consulta para crear la base de datos de Evolution
# La variable de entorno POSTGRES_USER es proporcionada por la imagen de postgres
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
    CREATE DATABASE evolution;
EOSQL
