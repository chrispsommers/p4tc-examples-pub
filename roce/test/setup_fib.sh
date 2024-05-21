#!/bin/bash
export INTROSPECTION=../generated
$TC p4ctrl create roce/table/Main/fib_table  prefix 10.0.0.0/8 \
action set_nhid param index 1
