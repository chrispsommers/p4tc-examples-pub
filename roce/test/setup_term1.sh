#!/bin/bash
export TC="/usr/sbin/tc"
cd /home/vagrant/p4tc-examples-pub/roce/generated
export INTROSPECTION=../generated
$TC mon
