#!/usr/bin/python3
from scapy.all import *
p=Ether(src="02:03:04:05:06:01",dst="00:90:fb:65:d6:fe")/IP(src="11.0.0.1",dst="10.11.12.13")/UDP(sport=1234,dport=4321)
sendp(p,iface="p4port0")