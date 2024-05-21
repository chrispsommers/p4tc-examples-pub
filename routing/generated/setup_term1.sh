#!/bin/bash
export TC="/usr/sbin/tc"
cd /home/vagrant/p4tc-examples-pub/routing/generated
export INTROSPECTION=.
$TC mon
