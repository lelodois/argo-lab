# Multi-stage: compila dentro do build (sem toolchain no host).
FROM mirror.gcr.io/library/golang:1.23-alpine AS build
WORKDIR /src
COPY main.go .
RUN go mod init billing-lab && CGO_ENABLED=0 go build -o /billing-lab .

FROM mirror.gcr.io/library/alpine:3.20
COPY --from=build /billing-lab /billing-lab
ENTRYPOINT ["/billing-lab"]
