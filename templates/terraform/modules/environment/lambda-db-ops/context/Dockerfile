# Image containing mysql postgresql client to execute commands on Database
FROM commitdev/zero-k8s-utilities:0.0.4

# TODO: bring this into base image
RUN apk add jq

WORKDIR /app
copy . .

RUN chmod -R 755 /app
