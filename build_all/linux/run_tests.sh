#! /bin/bash

# Copyright (c) Microsoft. All rights reserved.
# Licensed under the MIT license. See LICENSE file in the project root for full license information.

set -o errexit # Exit if command failed.
set -o pipefail # Exit if pipe failed.

usage() {
    echo "${0} OR ${0} [run_valgrind]" 1>&2
    exit 1
}

RUN_VALGRIND=${1:-""}

if [[ "$RUN_VALGRIND" == "run_valgrind" ]]; then
  echo "Using doctored openSSL to work with valgrind"
elif [[ "$RUN_VALGRIND" != "" ]]; then
  usage
fi

# Only for testing E2E behaviour !!! 
TEST_CORES=16

# Refresh dynamic libs to link to
sudo ldconfig

if [[ "$RUN_VALGRIND" == "run_valgrind" ]] ;
then
  # Use doctored openssl
  export LD_LIBRARY_PATH=/usr/local/ssl/lib

  # Run unit tests
  ctest -j $TEST_CORES --output-on-failure --schedule-random -R "_ut"
  
  # E2E tests are divided up between the basic and all the valgrind options
  # Having them together risks multiple versions of the same test being run at
  # the same time and causing false negatives.

  # Run basic e2e tests
  ctest -j $TEST_CORES --output-on-failure --schedule-random -E "_valgrind|_helgrind|_drd|_ut"
  
  # Run valgrind e2e tests
  ctest -j $TEST_CORES --output-on-failure --schedule-random -R valgrind -E "_ut"
  
  # Run helgrind e2e tests
  ctest -j $TEST_CORES --output-on-failure --schedule-random -R helgrind -E "_ut"
  
  # Run drd e2e tests
  ctest -j $TEST_CORES --output-on-failure --schedule-random -R drd -E "_ut"
  export LD_LIBRARY_PATH=
else
  ctest -j $TEST_CORES -C "Debug" --output-on-failure --schedule-random
fi

