#!/usr/bin/env sh
set -e
mkdir -p test_artifacts
jshell test.jshell > test_artifacts/java_reference.txt
lua test.lua > test_artifacts/lua_reference.txt
diff test_artifacts/java_reference.txt test_artifacts/lua_reference.txt
echo "Tests OK"