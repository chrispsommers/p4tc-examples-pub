# Infiniband Scapy Contrib Module
This module creates some Scapy Infiniband packet classes and utilities. Its initial focus is to support some RoCEv2 development. Hence it defines headers starting from the BTH (Base Transport Header) on down. It ignores headers above this because those are used for actual Infiniband. RoCEv2 uses IPv4/UDP or IPv6/UDP encapsulation instead of the Infiniband LRH and GRH headers.
# TODOs
Some ideas for enhancements:
* Add more opcodes
* Add more headers (layers), e.g. `MAD`, `DETH`, `AETH`, etc.
* Auto-compute iCRC
# References
* Official Infiniband Architecture Specification (I don't know if it;s the latest): https://www.afs.enea.it/asantoro/V1r1_2_1.Release_12062007.pdf
* Decent Infiniband Architecture book: https://www.mindshare.com/files/ebooks/InfiniBand%20Network%20Architecture.pdf
* Infiniband Annex A16 - RoCE: https://cw.infinibandta.org/document/dl/7148
* Infiniband Annex A17 - RoCEv2: https://cw.infinibandta.org/document/dl/7781
* RoCEv2 CNP Packet: https://community.mellanox.com/s/article/rocev2-cnp-packet-format-example
* Great Scapy How-Tos': https://github.com/jafingerhut/p4-guide/blob/master/README-scapy.md
* RoCE Kernel Driver iCRC calculation: https://github.com/SoftRoCE/rxe-dev/blob/fa5569dba0ff191ad773200399906e30ea7f6a7b/drivers/infiniband/hw/rxe/rxe_icrc.c
* Discussion about SoftRoce/HW compatibility fix: https://lore.kernel.org/linux-rdma/4433c97d-218a-294e-3c03-214e0ef1379f@acm.org/t/
* Online CRC calculator: https://crccalc.com/
* Another online CRC calculator: http://www.sunshine2k.de/coding/javascript/crc/crc_js.html

# Usage
The best way to learn to use this is by example.
## Import into another Python program
Just put this in your Python program:
```
from scapy_contrib.infiniband import *
```
Other typical imports in programs using Scapy:
```
from scapy.packet import Packet,bind_layers,Raw
from scapy.fields import *
from scapy.layers.l2 import Ether
from scapy.layers.inet import IP, UDP, TCP
from scapy.all import *
from scapy.sendrecv import *
```
You can use the interactive examples below to help you write programs.

## Examples in scapy interactive mode
To use it directly, launch Python and make sure the `PYTHONPATH` is set to include the parent directory or this directory, then import it appropriately.

For example, say you start in the parent directory of `scapy_contrib`:
```
chris@chris-VirtualBox:~/roce-road$ PYTHONPATH=. scapy
```
Import the module. Here's one way which avoids having to preface the classes with the full module path:
```
>>> from scapy_contrib.infiniband import *
```
### Construct a default BTH layer and show it
```
In one command:
>>> IB_BTH().show()
```
Or assign it to a variable then show it:
```
bth=IB_BTH()
bth.show()
```
Result:
```
###[ Infiniband BTH ]### 
  opcode= 0
  SE= 0
  MigReq= 0
  PadCnt= 0
  tver= 0
  p_key= 0x0
  Res_var= 0
  dest_qp= 0x0
  ack_req= 0
  Res= 0
  pkt_seq= 0x0
```
### Construct a more interesting BTH layer and show it
Note the op-code is decoded as CNP (Congestion Notification Packet).
```
>>> bth = IB_BTH(p_key=65535,dest_qp=0x0000d2,opcode=129)
>>> bth.show()
###[ Infiniband BTH ]### 
  opcode= RoCEv2-CNP
  SE= 0
  MigReq= 0
  PadCnt= 0
  tver= 0
  p_key= 0xffff
  Res_var= 0
  dest_qp= 0xd2
  ack_req= 0
  Res= 0
  pkt_seq= 0x0
```
Look at the bytes in a header. This utility is actually nice for any Scapy situation. Using the `BTH` layer created above:
```
>>> pkt_to_hexbytes(bth)
'8100ffff000000d200000000'
```
### Make a complete RoCEv2 packet
First, define each layer separately for readability.
```
>>> eth = Ether(src='00:11:22:33:44:55',dst='AA:BB:CC:DD:EE:FF')
>>> udp = UDP(sport=56238,dport=4791)
>>> bth = IB_BTH(p_key=65535,dest_qp=0x0000d2,opcode=129)
>>> cnp=IB_CNP()
>>> icrc=IB_iCRC()
>>> 
>>> # Compose layers and update iCRCs
>>> p_cnp = eth/ip_no_ecn/udp/bth/cnp/icrc
>>> update_icrc(p_cnp)
```
Let's look at the packet:
```
>>> p_cnp.show()
###[ Ethernet ]### 
  dst= AA:BB:CC:DD:EE:FF
  src= 00:11:22:33:44:55
  type= IPv4
###[ IP ]### 
     version= 4
     ihl= 5
     tos= 0x88
     len= None
     id= 39110
     flags= DF
     frag= 0
     ttl= 32
     proto= udp
     chksum= None
     src= 22.22.22.7
     dst= 22.22.22.8
     \options\
###[ UDP ]### 
        sport= 56238
        dport= 4791
        len= None
        chksum= None
###[ Infiniband BTH ]### 
           opcode= RoCEv2-CNP
           SE= 0
           MigReq= 0
           PadCnt= 0
           tver= 0
           p_key= 0xffff
           Res_var= 0
           dest_qp= 0xd2
           ack_req= 0
           Res= 0
           pkt_seq= 0x0
###[ RoCEv2 CNP Payload ]### 
              payload0= 0x0
              payload1= 0x0
              payload2= 0x0
              payload2= 0x0
###[ Infiniband invariant CRC ]### 
                 iCRC= 0xdf025dd3
```
### Examine the iCRC bytes and compare with another calculator
We'll look at the `p_cnp` packet created above and generate the effective byte sequence used to calculate iCRC. Then we'll plug those bytes into an external CRC-32 calculator and compare.

Look at the packet bytes as sent on the wire:
```
>>> pkt_to_hexbytes(p_cnp)
'aabbccddeeff00112233445508004588003c98c64000201169281616160716161608dbae12b7002860ee8100ffff000000d20000000000000000000000000000000000000000d35d02df'
```
Make a prepared packet which is the original packet starting from the IP layer, up to and including the payload layer. "Variant" fields are replaced by all ones per the RoCEv2 spec. Prepend the whole thing with 64 ones (`0xffffffff`).

Observe how the following variant fields are replaced with all ones: IP tos, Ip ttl, IP checksum; UDP checksum; BTH Res_var.
```
>>> prepared=prepare_icrc_packet(p_cnp)
>>> prepared.show()
###[ Raw ]### 
  load= '\xff\xff\xff\xff\xff\xff\xff\xff'
###[ IP ]### 
     version= 4
     ihl= 5
     tos= 0xff
     len= 60
     id= 39110
     flags= DF
     frag= 0
     ttl= 255
     proto= udp
     chksum= 0xffff
     src= 22.22.22.7
     dst= 22.22.22.8
     \options\
###[ UDP ]### 
        sport= 56238
        dport= 4791
        len= 40
        chksum= 0xffff
###[ Infiniband BTH ]### 
           opcode= RoCEv2-CNP
           SE= 0
           MigReq= 0
           PadCnt= 0
           tver= 0
           p_key= 0xffff
           Res_var= 255
           dest_qp= 0xd2
           ack_req= 0
           Res= 0
           pkt_seq= 0x0
###[ RoCEv2 CNP Payload ]### 
              payload0= 0x0
              payload1= 0x0
              payload2= 0x0
              payload2= 0x0
```
Let's look at the byte sequence:
```
>>> pkt_to_hexbytes(prepared)
'ffffffffffffffff45ff003c98c64000ff11ffff1616160716161608dbae12b70028ffff8100ffffff0000d20000000000000000000000000000000000000000'
```
Let's "manually" compute the CRC-32 of the prepared packet. Note `infiniband.py` imports `zlib` for us. The following line of code looks weird, let's break it down. The `str()` function returns bytes from the packet. The `zlib.crc32()` call computes the CRC. The `& 0xffffffff` ensures cross-platform consistency (some platforms or Python 2.X versions returned a signed result, some returned unsigned; this forces it to be unsigned). The `"%08X" %` is just a way to format the output into hexadecimal.
```
>>> "%08X" % (zlib.crc32(str(prepared)) & 0xffffffff)
'DF025DD3'
```
Notice this `DF025DD3` value matches (except the bytes are reversed) the iCRC value `0xdf025dd3` put into the `p_cnp` packet above via this line of code:
```
>>> update_icrc(p_cnp)
```
The difference is we had to store it in the iCRC packet class using `socket.htonl()` so it'll get sent in proper network byte order. This code in `infiniband.py` does it:
```
pkt_in[IB_iCRC].iCRC=socket.htonl(calc_icrc(pkt_in))
```

The `calc_icrc()` function automatically creates a temporary "prepared packet" and calculates CRC-32 on it, returns the computed CRC and discards the temporary prepared packet.

Here are the original packet and the prepared one compared side-by-side, with the modified fields separated with spaces for clarity. You may need to zoom out to see the bytes on one line:
```
aabbccddeeff0011223344550800 45 88 005698c64000 20 11 690e 1616160716161608dbae12b70028 fa3a 8100ffff000000d20000000000000000000000000000000000000000 df025dd3
^^^^^^^^^^^^^^^^^^^^^^^^^^^^                                                                                                                          ^^^^^^^^
Ethernet                                                                                                                                              iCRC

ffffffffffffffff             45 ff 003c98c64000 ff 11 ffff 1616160716161608dbae12b70028 ffff 8100ffffff0000d20000000000000000000000000000000000000000
^^^^^^^^^^^^^^^^                ^^              ^^    ^^^^                              ^^^^ 
Preamble                        tos             ttl   IP chksum                         UDP checksum
```
Let's use an online calculator to run these prepared bytes through CRC-32. Here are two websites:
* https://crccalc.com/
* http://www.sunshine2k.de/coding/javascript/crc/crc_js.html


This [link](https://crccalc.com/?crc=ffffffffffffffff45ff003c98c64000ff11ffff1616160716161608dbae12b70028ffff8100ffffff0000d20000000000000000000000000000000000000000&method=crc32&datatype=hex&outtype=hex) will go to the site and fill in the form with the prepared bytes above and compute CRC-32. You can go to either site and paste in the values yourself.

The calculated result is `0xDF025DD3` which is exactly as yielded by the utility functions and populated into our `p_cnp` packet.
### Read Pcap file and decode RoCEv2 packet
This packet was captured in Wireshark by running SoftRoce between two VMs. It is one of several packets resulting from running the `rping` (RDMA Ping) command:
```
>>> p=rdpcap('test_packets/softroce-send-only.pcap')[0]
>>> p.show()
###[ Ethernet ]### 
  dst= 04:00:00:00:00:01
  src= 02:00:00:00:00:01
  type= IPv4
###[ IP ]### 
     version= 4
     ihl= 5
     tos= 0x0
     len= 60
     id= 39387
     flags= DF
     frag= 0
     ttl= 64
     proto= udp
     chksum= 0x826d
     src= 14.1.1.2
     dst= 14.1.1.101
     \options\
###[ UDP ]### 
        sport= 49152
        dport= 4791
        len= 40
        chksum= 0x0
###[ Infiniband BTH ]### 
           opcode= Send-only
           SE= 0
           MigReq= 0
           PadCnt= 0
           tver= 0
           p_key= 0xffff
           Res_var= 0
           dest_qp= 0x11
           ack_req= 1
           Res= 0
           pkt_seq= 0x3b5589
###[ RoCEv2 Data Payload ]### 
              Word0= 0x561c
              Word1= 0xc9832100
              Word2= 0x4480
              Word3= 0x40
###[ Infiniband invariant CRC ]### 
                 iCRC= 0x81998a24
```
### Generate a Scapy command to regenerate a packet
Generate a scapy command to regenerate the packet above which we originally captured in Wireshark. This lets us regenerate the packet at will programatically, modify it, etc.
```
>>> p.command()
"Ether(src='02:00:00:00:00:01', dst='04:00:00:00:00:01', type=2048)/IP(frag=0, src='14.1.1.2', proto=17, tos=0, dst='14.1.1.101', chksum=33389, len=60, id=39387, version=4, flags=2, ihl=5, ttl=64)/UDP(dport=4791, sport=49152, len=40, chksum=0)/IB_BTH(ack_req=1, PadCnt=0, tver=0, Res=0, dest_qp=17, Res_var=0, pkt_seq=3888521, opcode=4, p_key=65535, MigReq=0, SE=0)/IB_DATA(Word1=3380814080, Word0=22044, Word3=64, Word2=17536)/IB_iCRC(iCRC=2174323236)"
```
You can take the above line and assign it, e.g.
```
p2=Ether(src='02:00:00:00:00:01', dst='04:00:00:00:00:01', type=2048)/IP(frag=0, src='14.1.1.2', proto=17, tos=0, dst='14.1.1.101', chksum=33389, len=60, id=39387, version=4, flags=2, ihl=5, ttl=64)/UDP(dport=4791, sport=49152, len=40, chksum=0)/IB_BTH(ack_req=1, PadCnt=0, tver=0, Res=0, dest_qp=17, Res_var=0, pkt_seq=3888521, opcode=4, p_key=65535, MigReq=0, SE=0)/IB_DATA(Word1=3380814080, Word0=22044, Word3=64, Word2=17536)/IB_iCRC(iCRC=2174323236)
```
Show it (in condensed form):
```
>>> p2
<Ether  dst=04:00:00:00:00:01 src=02:00:00:00:00:01 type=IPv4 |<IP  version=4 ihl=5 tos=0x0 len=60 id=39387 flags=DF frag=0 ttl=64 proto=udp chksum=0x826d src=14.1.1.2 dst=14.1.1.101 |<UDP  sport=49152 dport=4791 len=40 chksum=0x0 |<IB_BTH  opcode=Send-only SE=0 MigReq=0 PadCnt=0 tver=0 p_key=0xffff Res_var=0 dest_qp=0x11 ack_req=1 Res=0 pkt_seq=0x3b5589 |<IB_DATA  Word0=0x561c Word1=0xc9832100 Word2=0x4480 Word3=0x40 |<IB_iCRC  iCRC=0x81998a24 |>>>>>>
```