FROM alpine:latest
RUN apk add --no-cache bash iproute2 nftables curl bind-tools
COPY nftables.conf /etc/nftables.conf
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
