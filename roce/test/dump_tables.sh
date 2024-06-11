#!/bin/bash
$TC p4ctrl get roce/table/Main/nh_table
$TC p4ctrl get roce/table/Main/fib_table
$TC p4ctrl get roce/table/Main/drop_n_table
$TC p4ctrl get roce/table/Main/roce_table
$TC p4ctrl get roce/table/Main/mark_ecn_table
