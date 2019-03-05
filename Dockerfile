# build with: podman build -t gottox/voidlinux --no-cache .
#  Set MUSL=1 for musl builds
ARG MUSL=
ARG REPOSITORY=https://alpha.de.repo.voidlinux.org/current

# 1) use alpine to generate a void environment
FROM alpine:3.9 as stage0
COPY 60:ae:0c:d6:f0:95:17:80:bc:93:46:7a:89:af:a3:2d.plist /stage1/var/db/xbps/keys/
RUN apk add ca-certificates && \
  wget -O - https://alpha.de.repo.voidlinux.org/static/xbps-static-latest.$(uname -m)-musl.tar.xz | \
    tar Jx && \
  XBPS_ARCH=$(uname -m)${MUSL:+-musl} xbps-install.static -yMU \
    --repository=$REPOSITORY${MUSL:+/musl} \
    -r /stage1 \
    base-minimal

# 2) using void to generate the final build
FROM scratch as stage1
COPY --from=stage0 /stage1 /
COPY 60:ae:0c:d6:f0:95:17:80:bc:93:46:7a:89:af:a3:2d.plist /stage2/var/db/xbps/keys/
RUN xbps-reconfigure -a && \
  mkdir -p /stage1/var/cache && ln -s /var/cache/xbps /stage1/var/cache/xbps && \
  XBPS_ARCH=$(uname -m)${MUSL:+-musl} xbps-install -yMU \
    --repository=$REPOSITORY${MUSL:+/musl} \
    -r /stage2 \
    base-minimal

# 3) configure and clean up the final image
FROM scratch
COPY --from=stage1 /stage2 /
RUN xbps-reconfigure -a && \
  rm -r /var/cache/xbps
