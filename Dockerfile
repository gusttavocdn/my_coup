# Coup Online match server: headless Godot running the server scene.
# Build:  docker build -t coup-server .
# Run:    docker run -p 9080:9080 coup-server        (TLS is the reverse proxy's job: deploy/Caddyfile)
# Options are COUP_* environment variables; see docs/running-the-server.md.

FROM debian:12-slim AS engine
ARG GODOT_VERSION=4.7.2
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl unzip \
    && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL -o /tmp/godot.zip \
      "https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip" \
    && unzip /tmp/godot.zip -d /tmp \
    && mv "/tmp/Godot_v${GODOT_VERSION}-stable_linux.x86_64" /usr/local/bin/godot \
    && chmod +x /usr/local/bin/godot

FROM debian:12-slim
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates libfontconfig1 tini \
    && rm -rf /var/lib/apt/lists/* \
    && useradd --create-home --uid 10001 coup \
    && mkdir /app && chown coup:coup /app
COPY --from=engine /usr/local/bin/godot /usr/local/bin/godot
WORKDIR /app
COPY --chown=coup:coup . /app
USER coup
# Import once at build time so the container starts without an editor pass.
RUN godot --headless --path /app --import
ENV COUP_PORT=9080 COUP_BIND=*
EXPOSE 9080
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
    CMD godot --headless --path /app res://scenes/server.tscn -- --health || exit 1
# tini is PID 1: Godot installs no SIGTERM handler, and Linux ignores SIGTERM for a
# PID 1 without one, so without tini `docker stop` waits for its timeout and kills.
ENTRYPOINT ["/usr/bin/tini", "--", "godot", "--headless", "--path", "/app", "res://scenes/server.tscn", "--"]
