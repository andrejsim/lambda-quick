#!/bin/bash

function log {
    echo "> $(date +%T) $*"
}

name="dummy-lambda-quick"
bucket="datafabric-nonprod-lambdas"
lambdafile="lambda_function.py"
workdir=python

#$(mktemp -d ${workdir})
mkdir ${workdir}

log ${workdir}
log ${bucket}
log ${lambdafile}

zipfile="${name}.zip"

touch ${zipfile}

log "creating zipfile: ${zipfile}"

cd ${workdir} || exit

ls -la

zip "${zipfile}" ./*

key=${zipfile}

log "Starting upload to S3"
aws s3 cp "${zipfile}" "s3://${bucket}/${key}"

log "checking if function exists"
if ! aws lambda get-function --function-name "${name}" &> /dev/null; then
    echo "Function doesn\'t exist yet, please create it first"
    echo
    exit 1
fi

log "Updating function code"
result=$(aws lambda update-function-code --function-name "${name}" --s3-bucket "${bucket}" --s3-key "${key}" 2> /dev/null)
if [[ $? -ne 0 ]]; then
    log "Function update failed"
    echo "${result}"
fi

log "Function updated successfully"
