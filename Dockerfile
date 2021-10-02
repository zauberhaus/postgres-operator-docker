FROM alpine as builder

RUN apk update && apk add binutils ca-certificates upx && rm -rf /var/cache/apk/*

COPY ./build /build
COPY detect.sh /

RUN /detect.sh

FROM alpine

COPY --from=builder /dist/* /usr/local/bin/
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt

ENV KUBECONFIG=/kube.yaml

#USER 2

CMD ["/usr/local/bin/postgres-operator"]
