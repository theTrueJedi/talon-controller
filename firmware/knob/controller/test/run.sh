#!/bin/bash
# Host unit tests for the controller firmware's pure-C++ core (src/).
# Links to a temp file and copies it: on this Mac a binary run straight
# from the linker's output path is sometimes killed (signal 9).
set -e
cd "$(dirname "$0")"
mkdir -p build
clang++ -std=c++17 -Wall -Werror -I../src ../src/*.cpp *.cpp -o build/ctl_tests.link
rm -f build/ctl_tests && cp build/ctl_tests.link build/ctl_tests
build/ctl_tests
