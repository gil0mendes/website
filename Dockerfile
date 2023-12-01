FROM sridca/emanote as build

WORKDIR /data
COPY ./content /data

RUN --mount=type=tmpfs,target=/tmp \ 
  mkdir output && \
  emanote -L "/data" gen /data/output && \
  emanote export > /data/output/export.json

FROM gil0mendes/emanote-sitemap-generator:latest as generator
WORKDIR /data
COPY --from=build /data/output/export.json .
RUN emanote-sitemap-generator

FROM --platform=linux/arm64 nginx as webserver

COPY deploy/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /data/output /usr/share/nginx/html
COPY --from=generator /data/sitemap.xml /usr/share/nginx/html
