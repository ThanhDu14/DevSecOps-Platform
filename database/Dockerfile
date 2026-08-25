FROM mongo:latest

COPY sample_posts.json /docker-entrypoint-initdb.d/
COPY init-mongo.sh /docker-entrypoint-initdb.d/

RUN chmod +x /docker-entrypoint-initdb.d/init-mongo.sh
