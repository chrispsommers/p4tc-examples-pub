#!/bin/bash
export INTROSPECTION=../generated
$TC p4ctrl del roce/table/Main/mark_ecn_table  prio 1 prefix 32.0.2.3/32
