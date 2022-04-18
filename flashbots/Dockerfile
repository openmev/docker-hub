# syntaxdocker/dockerfile-upstream:master-experimental
FROM golang:1.17-alpine AS builder

RUN apk add --no-cache gcc musl-dev linux-headers git

ADD . /go-ethereum
WORKDIR /go-ethereum

RUN go run build/ci.go install ./cmd/geth

# Pull all binaries into a second stage deploy alpine container
FROM alpine:3.15

RUN apk update && apk upgrade \
    && apk add --no-cache bash jq ca-certificates \
    && rm -rf /var/cache/*/* \
    && echo "" > /root/.ash_history

# change default shell from ash to bash
RUN sed -i -e "s/bin\/ash/bin\/bash/" /etc/passwd
ENV LC_ALL=en_US.UTF-8
WORKDIR /root

COPY --from=builder /go-ethereum/build/bin/* /usr/local/bin/

COPY --chmod=0755 ./entrypoint.sh /root/entrypoint.sh
#RUN chmod 755 /root/entrypoint.sh


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
