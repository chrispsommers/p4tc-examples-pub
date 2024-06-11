#!/bin/bash
export INTROSPECTION=../generated
$TC p4ctrl create roce/table/Main/drop_n_table  prefix 10.11.12.13/32 action drop_conditional param index 0
