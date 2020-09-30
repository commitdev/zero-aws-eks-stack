#!/usr/bin/env bash

PROGNAME=$(basename "$0")

function usage() {
    echo "Usage: ${PROGNAME} [ -h | --help ] ID FILE"
    echo
    echo "Imports the specified CF Keypair data into AWS SecretsManager."
    echo
    echo "ID: CloudFront Keypair ID (Access Key ID)"
    echo "FILE: CloudFront Keypair private key file"
    echo
    echo "See: https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/private-content-trusted-signers.html#private-content-creating-cloudfront-key-pairs"
}

PARSED_ARGUMENTS=$(getopt -n ${PROGNAME} -o h --long help -- "$@")

while : ; do
    case "$1" in
        -h | --help)
            shift
            usage
            exit 0
            ;;
        --)
            shift
            break
            ;;
        *)
            break
            ;;
    esac
done

if [ "$#" -ne 2 ]; then
    usage
    exit 1
fi

ID=$1
SECRET=$(tr -d '\r' < $2 | awk '{printf "%s\\n", $0}')

aws secretsmanager \
    create-secret \
    --name <% .Name %>_cf_keypair \
    --region <% index .Params `region` %> \
    --tags '[{"Key":"cf_keypair","Value":"<% .Name %>"}]' \
    --secret-string "{\"keypair_id\":\"${ID}\",\"private_key\":\"${SECRET}\"}"
