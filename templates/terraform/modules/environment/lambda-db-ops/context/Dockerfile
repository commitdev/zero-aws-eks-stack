FROM public.ecr.aws/c2m7p9n1/zero-utilities:0.0.4

# bring this into base image
RUN apk add jq

WORKDIR /app
copy . .

RUN chmod -R 755 /app

