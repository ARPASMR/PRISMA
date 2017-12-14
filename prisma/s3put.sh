#!/bin/bash

S3KEY="I5AWJSQHMN7NECRN68CM"
S3SECRET="7sCAIzhlxySqZDLL7YD3uJD7u/CgUwacGIHhSjd3"
S3HOST=10.10.99.136:9000

putS3() {
  path=$1
  file=$2
  aws_path=$3
  bucket=$4
  date=$(date -R)
  acl="x-amz-acl:public-read"
  content_type='application/x-compressed-tar'
  string="PUT\n\n$content_type\n$date\n$acl\n/$bucket/$aws_path$file"
  signature=$(echo -en "${string}" | openssl sha1 -hmac "${S3SECRET}" -binary | base64)
  curl -X PUT -T "$path/$file" \
    --progress-bar \
    -H "Host: $S3HOST" \
    -H "Date: $date" \
    -H "Content-Type: $content_type" \
    -H "$acl" \
    -H "Authorization: AWS ${S3KEY}:$signature" \
    "http://$S3HOST/$bucket/$aws_path$file"
}
