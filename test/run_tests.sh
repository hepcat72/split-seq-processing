#!/usr/bin/env bash

#test numbers or 'all'
tests_nums_to_regenerate=("$@")
num_saves=$#

TEST_DATA=test_data
TEST_OUTPUT=test_output
rm -rf "${TEST_OUTPUT}"
mkdir -p "${TEST_OUTPUT}"
TEST_PREFIX="test_"

EXIT_STATUS=0

function check_test_results() {
    REGEN=0
    if [ $num_saves -gt 0 ]; then
      for n in "${tests_nums_to_regenerate[@]}"
        do
          if [ "$n" == "all" ] || [ $n -eq $TESTN ]; then
            REGEN=1
          fi
        done
    fi

    if [ $EXIT_CODE -ne $EXPECTED_EXIT_CODE ];then
        EXIT_STATUS=1
        echo "${TEST} EXIT($EXIT_CODE) != EXPECTED($EXPECTED_EXIT_CODE) FAILED"'!'
    else
        echo "${TEST} EXIT($EXIT_CODE) PASSED"
    fi
    for NOT_OUTPUT in $NOT_OUTPUTS; do
        if [ -f "$NOT_OUTPUT" ]
        then
            EXIT_STATUS=1
            echo "${TEST}_${NOT_OUTPUT} FAILED"'!'
        else
            echo "${TEST}_${NOT_OUTPUT} PASSED"
        fi
    done

    if [ $REGEN -eq 1 ] && [ $EXIT_STATUS -eq 0 ]; then
        for OUTPUT in $OUTPUTS; do
            cp "${TEST_OUTPUT}/${TEST}_${OUTPUT}" "${TEST_DATA}/${TEST}_${OUTPUT}" 2>/dev/null || :
            if [ $? -ne 0 ]; then
                EXIT_STATUS=1
                echo "${TEST}_${OUTPUT} COPY FAILED"'!'
            else
                echo "${TEST}_${OUTPUT} COPIED"
            fi
        done
    elif [  ]; then
        echo "Unable to regenerate test files due to failure"
    elif [ $REGEN -eq 0 ]; then
        for OUTPUT in $OUTPUTS; do
            filename=$(basename "$OUTPUT")
            extension="${filename##*.}"
            if [[ $extension == 'gz' ]]; then
                diff <(gzip -dc "$TEST_OUTPUT/${TEST}_${OUTPUT}") <(gzip -dc "${TEST_DATA}/${TEST}_${OUTPUT}")
            else
                diff "${TEST_OUTPUT}/${TEST}_${OUTPUT}" "${TEST_DATA}/${TEST}_${OUTPUT}"
            fi
            if [ $? -ne 0 ]; then
                EXIT_STATUS=1
                echo "${TEST}_${OUTPUT} FAILED"'!'
            else
                echo "${TEST}_${OUTPUT} PASSED"
            fi
        done
    fi
}

NOT_OUTPUTS=""

# Test sparse2dense.pl basic output
TESTN=1
TEST="${TEST_PREFIX}${TESTN}"
rm -f ${TEST_OUTPUT}/${TEST}_* 2> /dev/null
OUTPUTS="DGE1.tsv stdout.txt stderr.txt"
NOT_OUTPUTS=""
../src/sparse2dense.pl -i "${TEST_DATA}/DGE1.mtx" --outdir "${TEST_OUTPUT}" -o ${TEST}_DGE1.tsv 2> "${TEST_OUTPUT}/${TEST}_stderr.txt" 1> "${TEST_OUTPUT}/${TEST}_stdout.txt"
EXIT_CODE=$?
EXPECTED_EXIT_CODE=0
check_test_results

# Test sparse2dense.pl basic row name output
TESTN=2
TEST="${TEST_PREFIX}${TESTN}"
rm -f ${TEST_OUTPUT}/${TEST}_* 2> /dev/null
OUTPUTS="DGE1.tsv stdout.txt stderr.txt"
NOT_OUTPUTS=""
../src/sparse2dense.pl -i "${TEST_DATA}/DGE1.mtx" -g "${TEST_DATA}/genes1.csv" --outdir "${TEST_OUTPUT}" -o "${TEST}_DGE1.tsv" 2> "${TEST_OUTPUT}/${TEST}_stderr.txt" 1> "${TEST_OUTPUT}/${TEST}_stdout.txt"
EXIT_CODE=$?
EXPECTED_EXIT_CODE=0
check_test_results

# Test sparse2dense.pl col name output
TESTN=3
TEST="${TEST_PREFIX}${TESTN}"
rm -f ${TEST_OUTPUT}/${TEST}_* 2> /dev/null
OUTPUTS="DGE1.tsv stdout.txt stderr.txt"
NOT_OUTPUTS=""
../src/sparse2dense.pl -i "${TEST_DATA}/DGE1.mtx" -c "${TEST_DATA}/cell_metadata1.csv" --outdir "${TEST_OUTPUT}" -o "${TEST}_DGE1.tsv" 2> "${TEST_OUTPUT}/${TEST}_stderr.txt" 1> "${TEST_OUTPUT}/${TEST}_stdout.txt"
EXIT_CODE=$?
EXPECTED_EXIT_CODE=0
check_test_results

# Test sparse2dense.pl full output
TESTN=4
TEST="${TEST_PREFIX}${TESTN}"
rm -f ${TEST_OUTPUT}/${TEST}_* 2> /dev/null
OUTPUTS="DGE1.tsv stdout.txt stderr.txt"
NOT_OUTPUTS=""
../src/sparse2dense.pl -i "${TEST_DATA}/DGE1.mtx" --excel -g "${TEST_DATA}/genes1.csv" -a "${TEST_DATA}/genes1.gtf" -c "${TEST_DATA}/cell_metadata1.csv" --outdir "${TEST_OUTPUT}" -o "${TEST}_DGE1.tsv" 2> "${TEST_OUTPUT}/${TEST}_stderr.txt" 1> "${TEST_OUTPUT}/${TEST}_stdout.txt"
EXIT_CODE=$?
EXPECTED_EXIT_CODE=0
check_test_results


exit $EXIT_STATUS
