#!/bin/bash
export INTROSPECTION=../generated
$TC p4ctrl create roce/table/Main/mark_ecn_table  prefix 32.0.2.3/32 action set_ecn param codepoint 3
