# this file contains shared functions used for testing

# if you want info about what failed, set DEBUG=true in the test and get more output.  By
# default, that output is not shown to remain TAP compliant

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

    # matchers
    # what is interesting here is that if the test passes, the debug output
    # is not shown at all.  Not sure how this works, but I like it

    assert_output_matches() {
        local re_pattern=$1
        if [ ! -z "$DEBUG" ]; then
            echo "Expected output to contain pattern"
            echo "Output: ${output}"
            echo "Pattern: ${re_pattern}"
        fi
        [[ "${output}" =~ "${re_pattern}" ]]
    }

    assert_output_does_not_match() {
        local re_pattern=$1
        if [ ! -z "$DEBUG" ]; then
            echo "Expected output to NOT contain pattern"
            echo "Output: ${output}"
            echo "Pattern: ${re_pattern}"
        fi
        [[ ! "${output}" =~ "${re_pattern}" ]]
    }

    assert_no_error() {
        if [ ! -z "$DEBUG" ]; then
            echo "Status is $status, expected 0"
        fi
        [ $status -eq 0 ]
    }

    assert_error() {
        if [ ! -z "$DEBUG" ]; then
            echo "Status is $status, expected great than 0"
        fi
        [ $status -gt 0 ]
    }

fi
