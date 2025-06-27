FROM golang:1.22-alpine AS builder
WORKDIR /app
COPY . .
RUN go mod download
RUN go build -o /banner-app ./cmd

FROM alpine:latest
COPY --from=builder /banner-app /banner-app
COPY migrations /migrations
CMD ["/banner-app"]