#!/bin/bash

output=$(eval "./bin/calc 1 + 2")
if [ "$output" = "3" ]; then
    echo "TEST 1: 1 + 2 = $output (correct)"
else
    echo "======>"
    echo "TEST 1: 1 + 2 = $output (INCORRECT)"
    echo "<======"
fi
output=$(eval "./bin/calc 3 x 5 + 2 - 10 / 2")
if [ "$output" = "12" ]; then
    echo "TEST 2: 3 x 5 + 2 - 10 / 2 = $output (correct)"
else
    echo "======>"
    echo "TEST 2: 3 x 5 + 2 - 10 / 2 = $output (INCORRECT)"
    echo "<======"
fi
output=$(eval "./bin/calc 1 x 2 x 3 x 4 x 5 x 6 x 7 x 8 x 9 x 10")
if [ "$output" = "3628800" ]; then
    echo "TEST 3: 1 x 2 x 3 x 4 x 5 x 6 x 7 x 8 x 9 x 10 = $output (correct)"
else
    echo "======>"
    echo "TEST 3: 1 x 2 x 3 x 4 x 5 x 6 x 7 x 8 x 9 x 10 = $output (INCORRECT)"
    echo "<======"
fi
output=$(eval "./bin/calc 1 + 0")
if [ "$output" = "1" ]; then
    echo "TEST 4: 1 + 0 = $output (correct)"
else
    echo "======>"
    echo "TEST 4: 1 + 0 = $output (INCORRECT)"
    echo "<======"
fi
output=$(eval "./bin/calc 3 x 5 - 17 + 3")
if [ "$output" = "1" ]; then
    echo "TEST 5: 3 x 5 - 17 + 3 = $output (correct)"
else
    echo "======>"
    echo "TEST 5: 3 x 5 - 17 + 3 = $output (INCORRECT)"
    echo "<======"
fi
