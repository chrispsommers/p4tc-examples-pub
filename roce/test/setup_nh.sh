#!/bin/bash
export INTROSPECTION=../generated
$TC p4ctrl create roce/table/Main/nh_table nh_index 1 \
action set_nh param dmac 13:37:13:37:13:37 param port port1
