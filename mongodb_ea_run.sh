#!/bin/bash
docker rm -f mongodb-ea 2>/dev/null || true

set -a; source .env; set +a

docker run -d \
  --name mongodb-ea \
  --restart unless-stopped \
  -p 27017:27017 \
  -v mongodb_ea_data:/data/db \
  -v mongodb_ea_keyfile:/keyfile:ro \
  -e MONGODB_INITDB_ROOT_USERNAME="$MONGO_ROOT_USER" \
  -e MONGODB_INITDB_ROOT_PASSWORD="$MONGO_ROOT_PWD" \
  mongodb/mongodb-enterprise-server:8.0-ubi9 \
  mongod --replSet rs0 --bind_ip 0.0.0.0 --keyFile /keyfile/mongodb-keyfile
