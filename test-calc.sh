#!/bin/bash

counter=0
correct=0

function inc {
    counter=$(( $counter + 1 ))
}

function calc {
    output=$(eval "./bin/calc $1 $2 $3")
    if [ "$output" = "$4" ]; then
        echo "TEST $counter: $1 $2 $3 = $4 (correct)"
        correct=$(( $correct + 1 ))
    else
        echo "======>"
        echo "TEST $counter: $1 $2 $3 = $output (INCORRECT)"
        echo "<======"
    fi
    inc
}

calc 1 + 2 3
calc 10 + 20 30
calc 100 + 200 300
calc 1 + 0 1
calc 0.1 + 0.2 0.3
calc 0.01 + 0.02 0.03
calc 0.001 + 0.002 0.003
calc 0.0001 + 0.0002 0.0003
calc -1 + -2 -3
calc 10 x 5 50
calc 2.5 + 2.7 5.2
calc 0 / 2 INVALID_INPUT
calc 0.03 - 0.02534 0.00466
calc 12.3 x 3.4 41.82

output=$(eval "./bin/calc 3 x 5 + 2 - 10 / 2")
if [ "$output" = "12" ]; then
    echo "TEST $counter: 3 x 5 + 2 - 10 / 2 = $output (correct)"
    correct=$(( $correct + 1 ))
else
    echo "======>"
    echo "TEST $counter: 3 x 5 + 2 - 10 / 2 = $output (INCORRECT)"
    echo "<======"
fi
inc
output=$(eval "./bin/calc 3 x 5 - 17 + 3")
if [ "$output" = "1" ]; then
    echo "TEST $counter: 3 x 5 - 17 + 3 = $output (correct)"
    correct=$(( $correct + 1 ))
else
    echo "======>"
    echo "TEST $counter: 3 x 5 - 17 + 3 = $output (INCORRECT)"
    echo "<======"
fi
inc
output=$(eval "./bin/calc 3 x 5 - 17 + 3")
if [ "$output" = "1" ]; then
    echo "TEST $counter: 3 x 5 - 17 + 3 = $output (correct)"
    correct=$(( $correct + 1 ))
else
    echo "======>"
    echo "TEST $counter: 3 x 5 - 17 + 3 = $output (INCORRECT)"
    echo "<======"
fi
inc
output=$(eval "./bin/calc 1 x 2 x 3 x 4 x 5 x 6 x 7 x 8 x 9 x 10")
if [ "$output" = "3628800" ]; then
    echo "TEST $counter: 1 x 2 x 3 x 4 x 5 x 6 x 7 x 8 x 9 x 10 = $output (correct)"
    correct=$(( $correct + 1 ))
else
    echo "======>"
    echo "TEST $counter: 1 x 2 x 3 x 4 x 5 x 6 x 7 x 8 x 9 x 10 = $output (INCORRECT)"
    echo "<======"
fi
inc

echo "--------------------------------------------------"
echo "TEST cases: $correct / $counter correct."
echo "--------------------------------------------------"
