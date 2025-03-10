job "gil0mendes-website" {
  datacenters = ["elementarium"]
  type = "service"

  group "website" {
    count = 1

    network {
      mode = "bridge"
    }

    service {
      name = "gil0mendes-website"
      port = "80"

      connect {
        sidecar_service {}
      }

      tags = [
        "traefik.enable=true",
        "traefik.consulcatalog.connect=true",
        "traefik.http.routers.gil0mendes-website.tls.certResolver=elementarium",
        "traefik.http.routers.gil0mendes-website.rule=Host(`gil0mendes.io`)"
      ]
    }

    task "gil0mendes-website" {
      driver = "docker"

      config {
        image = "$CI_IMAGE_TAG"
      }
    }
  }
}
