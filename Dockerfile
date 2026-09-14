FROM --platform=linux/amd64 ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
RUN apt update -y && apt install --no-install-recommends -y nodejs npm git curl wget

WORKDIR /Dreamchat
EXPOSE 6080

RUN npm install
CMD ["node", "index.js"]

