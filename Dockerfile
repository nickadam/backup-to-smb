FROM alpine:3.10

RUN apk add samba-client dumb-init

COPY docker-entrypoint.sh /

COPY backup.sh /

ENTRYPOINT ["dumb-init", "/docker-entrypoint.sh"]
