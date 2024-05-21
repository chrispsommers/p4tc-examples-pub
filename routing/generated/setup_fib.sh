#!/bin/bash
$TC p4ctrl create routing/table/Main/fib_table  prefix 10.0.0.0/8 \
action set_nhid param index 1
