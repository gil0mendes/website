FROM --platform=linux/arm64 nginx AS webserver

COPY deploy/nginx.conf /etc/nginx/conf.d/default.conf
COPY ./website /usr/share/nginx/html
