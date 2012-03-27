# START apache_downloader.sh

verify_file() {
    local FILE=$1
    local SIG=$2
    local INDENT=$3
    yellow "Verifying the signature of ${FILE}" "${INDENT}"
    gpg --verify "${SIG}" "${FILE}"
    local verified=$?
    if [ "$verified" -gt 0 ]; then
        red "Verification failed" "${INDENT}"
        local loop=0
        local cont=""
        while [ "$loop" -lt 1 ]; do
            cont=$(read_input "Do you want to continue anyway [y/n]" "${INDENT}")
            if [ "${cont}" == "y" ] || [ "${cont}" == "n" ] || [ "${cont}" == "Y" ] || [ "${cont}" == "N" ]; then
                loop=1
            fi
        done
        if [ "${cont}" == "y" ] || [ "${cont}" == "Y" ]; then
            yellow "Ok, installing unverified file" "${INDENT}"
        else
            abort "Review output above for more info on the verification failure.  You may also refer to http://www.apache.org/info/verification.html" "${INDENT}"
        fi
    else
        yellow "Verification passed" "${INDENT}"
    fi
}

download_file() {
    local DEST=$1
    local SRC=$2
    local INDENT=$3
    check_curl
    # get the file
    yellow "Downloading ${SRC} to ${DEST}" "${INDENT}"
    yellow "Please wait..." "${INDENT}"
    if curl -L "${SRC}" -o "${DEST}"; then
        true
    else
        abort "Could not download ${SRC}"
    fi
}

ensure_file() {
    local FILE_DEST=$1
    local FILE_SRC=$2
    local INDENT=$3
    if [ ! -e "${FILE_DEST}" ]; then
        download_file "${FILE_DEST}" "${FILE_SRC}" "${INDENT}"
        if [ ! -e "${FILE_DEST}.asc" ]; then
            download_file "${FILE_DEST}.asc" "${FILE_SRC}.asc" "${INDENT}"
        fi
        yellow "Verifying ${FILE_DEST}"
        verify_file "${FILE_DEST}" "${FILE_DEST}.asc" "${INDENT}"
    else
        yellow "Using existing file ${FILE_DEST}" "${INDENT}"
    fi

}

# END apache_downloader.sh
