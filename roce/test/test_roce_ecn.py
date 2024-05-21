#!/usr/bin/python3

# from scapy.packet import Packet,bind_layers,Raw
# from scapy.fields import *
# from scapy.layers.l2 import Ether
# from scapy.layers.inet import IP, UDP, TCP
# from scapy.sendrecv import *
from scapy.all import *
from scapy_contrib.infiniband import *

eth = Ether(src='00:11:22:33:44:55',dst='AA:BB:CC:DD:EE:FF')
ip_no_ecn = IP(src='22.22.22.7',dst='10.11.12.13', tos=(4*34), ihl=5, ttl=32, flags=2,frag=0, id=0x98c6)
ip_with_ecn = ip_no_ecn.copy()
ip_with_ecn.tos |=3

udp = UDP(sport=56238,dport=4791)
bth = IB_BTH(p_key=65535,dest_qp=0x0000d2,opcode=129)
cnp=IB_CNP()
icrc=IB_iCRC()

# Compose layers and update iCRCs
p_cnp = eth/ip_no_ecn/udp/bth/cnp/icrc
update_icrc(p_cnp)

raw = Raw("The quick brown fox jumped over the lazy dawg!")
p_no_ecn = eth/ip_no_ecn/udp/bth/raw/icrc
print("\nPkt w/ ECN marking (len=%d):" % len(p_no_ecn))
p_no_ecn.show()
sendp(p_no_ecn, iface='p4port0')
# update_icrc(p_no_ecn)

p_with_ecn = eth/ip_with_ecn/udp/bth/raw/icrc
# update_icrc(p_with_ecn)
# print("\nPkt w/o ECN marking:")
# p_with_ecn.show()