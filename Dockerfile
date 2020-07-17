FROM ubuntu:18.04 as build

ARG ZOLA_VERSION=v0.10.2

# Install CURL
RUN apt-get update \
      && apt-get install -y --no-install-recommends ca-certificates openssl curl \
      && rm -rf /var/lib/apt/lists/* \
      && mkdir /app

# Install zola
WORKDIR /app

# Install Zola
RUN curl -L https://github.com/getzola/zola/releases/download/v0.11.0/zola-v0.11.0-x86_64-unknown-linux-gnu.tar.gz > zola.tar.gz \
      && tar -xzf zola.tar.gz

# build
COPY . /app
RUN ./zola build

FROM nginx
COPY --from=build /app/public /usr/share/nginx/html
