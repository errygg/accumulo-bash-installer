# START apache_downloader.sh

verify_file() {
    local FILE=$1
    local SIG=$2
    check_gpg
    light_blue "Verifying the signature of ${FILE}"
    $GPG --verify "${SIG}" "${FILE}"
    local verified=$?
    if [ "$verified" -gt 0 ]; then
        red "Verification failed"
        local loop=0
        local cont=""
        while [ "$loop" -lt 1 ]; do
            cont=$(read_input "Do you want to continue anyway [y/n]")
            if [ "${cont}" == "y" ] || [ "${cont}" == "n" ] || [ "${cont}" == "Y" ] || [ "${cont}" == "N" ]; then
                loop=1
            fi
        done
        if [ "${cont}" == "y" ] || [ "${cont}" == "Y" ]; then
            light_blue "Ok, installing unverified file"
        else
            abort "Review output above for more info on the verification failure.  You may also refer to http://www.apache.org/info/verification.html" "${INDENT}"
        fi
    else
        light_blue "Verification passed"
    fi
}

download_file() {
    local DEST=$1
    local SRC=$2
    check_curl
    # get the file
    light_blue "Downloading ${SRC} to ${DEST}"
    light_blue "Please wait..."
    if $CURL -L "${SRC}" -o "${DEST}"; then
        true
    else
        abort "Could not download ${SRC}"
    fi
}

ensure_file() {
    local FILE_DEST=$1
    local FILE_SRC=$2
    if [ ! -e "${FILE_DEST}" ]; then
        download_file "${FILE_DEST}" "${FILE_SRC}" "${INDENT}"
        if [ ! -e "${FILE_DEST}.asc" ]; then
            download_file "${FILE_DEST}.asc" "${FILE_SRC}.asc" "${INDENT}"
        fi
        light_blue "Verifying ${FILE_DEST}"
        verify_file "${FILE_DEST}" "${FILE_DEST}.asc"
    else
        light_blue "Using existing file ${FILE_DEST}"
    fi

}

# END apache_downloader.sh
