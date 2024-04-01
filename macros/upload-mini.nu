# TODO based on bellow base snippet
# #!/usr/bin/env bash
# set -e
# # printer settings
# PRINTER_HOST="192.168.1.123"
# API_KEY="ToEn8eDlR7kWIiUpVPJg"
# FILENAME=myfile.gcode
# # capture command stdout - http status code will be written to stdout
# # progress bar on stderr
# # http response (json) stored in /tmp/.upload-response
# CURL_HTTP_STATUS=$(curl \
#     --header "X-Api-Key: ${API_KEY}" \
#     -F "file=@${FILENAME}" \
#     -F "path=" \
#     -X POST \
#     -o /tmp/.upload-response \
#     --write-out "%{http_code}" \
#     http://${PRINTER_HOST}/api/files/local
# )
# # get result
# CURL_EXITCODE=$?
# CURL_RESPONSE=$(cat /tmp/.upload-response)
# # success ?
# if [ ${CURL_EXITCODE} -ne 0 ] || [ "${CURL_HTTP_STATUS}" -ne "201" ]; then
#     echo "error: upload failed (${CURL_HTTP_STATUS})"
# else
#     echo "upload succeed"
# fi
