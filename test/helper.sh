# this file contains shared functions used for testing

if [ "${HELPER_LOADED}" != true ]; then
    # lets only load this if it hasn't been loaded

    HELPER_LOADED=true

# overwrite functions name in first arg, having it echo the second arg
# so we can inspect the output.  If the third option is present, then the
# stubbed function will exit
    stub_function() {
        local fname=$1
        local msg=$2
        local exitnow=$3
        if [ "x${exitnow}" != "x" ]; then
            eval "function ${fname}() {
            echo \"${msg}\"
            exit 0;
        }"
        else
            eval "function ${fname}() {
             echo \"${msg}\"
        }"
        fi
    }

# assert re_pattern match the given text
    assert_re_match() {
        local text=$1
        local re_pattern=$2
        if [[ ! "${text}" =~ "${re_pattern}" ]]; then
            echo ""
            echo "Expected '${re_pattern}' to be in the following"
            echo "${text}"
            fail
        fi
    }

# assert re_pattern does not match given text
    assert_no_re_match() {
        local text=$1
        local re_pattern=$2
        if [[ "${text}" =~ "${re_pattern}" ]]; then
            echo ""
            echo "Expected '${re_pattern}' to NOT be in the following"
            echo "${text}"
            fail
        fi
    }

fi
