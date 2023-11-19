FROM golang:1.21.4

RUN go install go.uber.org/nilaway/cmd/nilaway@latest
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

