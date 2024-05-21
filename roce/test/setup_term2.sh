#!/bin/bash
DEV=port0
tcpdump -n -i $DEV -e
