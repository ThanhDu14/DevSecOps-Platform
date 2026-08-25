#!/bin/bash
echo "Executing MongoDB seed script..."
mongoimport --db wanderlust --collection posts --file /docker-entrypoint-initdb.d/sample_posts.json --jsonArray
