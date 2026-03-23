---
name: docker-multiarch-build
description: "Multi-architecture Docker image patterns (amd64/arm64). Activates for: multi-arch build, Docker buildx, cross-platform image, arm64 container, multi-platform. 中文触发：多架构构建、Docker buildx、跨平台镜像、arm64 容器、多平台镜像。"
---

# Docker Multi-Architecture Build

## Purpose

Build production images that run on both amd64 and arm64, using buildx and multi-stage Dockerfiles.

## Deterministic Steps

1. Use multi-stage builds to keep runtime images small.
2. Use build args for platform-specific builds when compiling binaries (Go).
3. Prefer non-root runtime users where possible.
4. Validate the image starts and passes a simple health check per platform.
5. Use `docker compose` (not `docker-compose`) for Compose v2+ compatibility.
6. If using compose, omit the `version` field (Compose v2+ ignores it).

## Minimal Build Commands

```bash
docker buildx create --use --name multiarch || true
docker buildx build --platform linux/amd64,linux/arm64 -t repo/app:tag --push .
```

## Checklist

- Multi-stage Dockerfile
- Runtime image does not include build toolchain
- Non-root user for runtime
- Health check exists (or documented as intentionally omitted)

