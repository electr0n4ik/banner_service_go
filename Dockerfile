FROM golang:1.24.0-alpine AS builder
WORKDIR /app
COPY . .
RUN if [ -f go.mod ]; then \
      echo "✅ go.mod exists! Go module: $(grep '^module' go.mod | awk '{print $2}')"; \
    else \
      echo "❌ go.mod not found! Initializing new module..."; \
      go mod init banner_service_go; \
    fi
FROM alpine:latest
COPY --from=builder /banner-service .
EXPOSE 8080
CMD ["./banner-service"]