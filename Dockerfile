FROM golang:1.24.0-alpine AS builder
WORKDIR /app
COPY . .
RUN if [ -f go.mod ]; then \
      echo "✅ go.mod exists! Go module: $(grep '^module' go.mod | awk '{print $2}')"; \
    else \
      echo "❌ go.mod not found! Initializing new module..."; \
      go mod init banner_service_go; \
    fi
RUN go build -o /banner-app ./cmd

FROM alpine:latest
COPY --from=builder /banner-app /banner-app
# COPY /migrations /migrations
CMD ["app/banner-app"]