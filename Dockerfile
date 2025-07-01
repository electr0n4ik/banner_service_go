FROM golang:1.24.0-alpine AS builder
WORKDIR /app
COPY . .
RUN go mod
RUN go build -o /banner-app ./cmd

FROM alpine:latest
COPY --from=builder /banner-app /banner-app
# COPY /migrations /migrations
CMD ["app/banner-app"]