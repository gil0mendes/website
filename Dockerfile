FROM sridca/emanote as build

WORKDIR /data
COPY ./content /data

RUN --mount=type=tmpfs,target=/tmp \ 
  mkdir output && \
  emanote -L "/data" gen /data/output

FROM nginx as webserver

COPY deploy/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /data/output /usr/share/nginx/html
