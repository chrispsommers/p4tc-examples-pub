#!/bin/bash
export TC=/usr/sbin/tc
$TC -s filter ls block 21 ingress
