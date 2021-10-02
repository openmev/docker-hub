FROM golang:1.17-alpine AS builder

RUN apk add --no-cache gcc musl-dev linux-headers git

ADD . /go-ethereum

RUN cd /go-ethereum && go run build/ci.go install ./cmd/geth

# Pull all binaries into a second stage deploy alpine container
FROM alpine:3.14.2

RUN apk add --no-cache bash ca-certificates
COPY --from=builder /go-ethereum/build/bin/* /usr/local/bin/


COPY ./entrypoint.sh /root/entrypoint.sh
RUN chmod 755 /root/entrypoint.sh
ENTRYPOINT ["geth"]

EXPOSE 8545 8546 30303 30303/udp

ARG BUILD_DATE
ARG VCS_REF
LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.name="MEV Go-Ethereum" \
      org.label-schema.description="MEV Go Ethereum Alpine" \
      org.label-schema.url="https://vcs.openmev.org/" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url="https://github.com/openmev/vcs.git" \
      org.label-schema.vendor="OpenMEV" \
      org.label-schema.version=$VERSION \
      org.label-schema.schema-version="1.0"