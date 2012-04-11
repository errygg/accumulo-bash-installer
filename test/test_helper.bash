# this file contains shared functions used for testing

# if you want info about what failed, set DEBUG=true in the test and get more output.  By
# default, that output is not shown to remain TAP compliant

# regex as written here need double quotes to work
shopt -s compat31

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
        local without_line_break=$(echo "${output}" | tr '\n' ';')
        [[ "${without_line_break}" =~ "${re_pattern}" ]]
    }

    assert_output_does_not_match() {
        local re_pattern=$1
        if [ ! -z "$DEBUG" ]; then
            echo "Expected output to NOT contain pattern"
            echo "Output: ${output}"
            echo "Pattern: ${re_pattern}"
        fi
        local without_line_break=$(echo "${output}" | tr '\n' ';')
        [[ ! "${without_line_break}" =~ "${re_pattern}" ]]
    }

    assert_output_equals() {
        local expected=$1
        if [ ! -z "$DEBUG" ]; then
            echo "Expected output to equal string"
            echo "Output: ${output}"
            echo "String: ${expected}"
        fi
        [ "${output}" == "${expected}" ]
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

    assert_directory_exists() {
        DIR=$1
        if [ ! -z "$DEBUG" ]; then
            if [ -d $DIR ]; then
                echo "Directory $DIR exists"
            else
                echo "Expected $DIR to exist but didn't"
            fi
        fi
        [ -d $DIR ]
    }

fi
