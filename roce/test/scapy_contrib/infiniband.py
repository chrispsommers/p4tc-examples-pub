# scapy packet layer for Infiniband/RoCE/RoCEv2
# scapy.contrib.description = IB
# scapy.contrib.status = loads

# /*******************************************************************************
#  * KEYSIGHT TECHNOLOGIES CONFIDENTIAL & PROPRIETARY
#  *
#  * Copyright (c) 2020-present Keysight Technologies, Inc.
#  *
#  * All Rights Reserved.
#  *
#  * NOTICE: All information contained herein is, and remains the property of
#  * Keysight Technologies, Inc. and its suppliers, if any. The intellectual and
#  * technical concepts contained herein are proprietary to Keysight Technologies, Inc.
#  * and its suppliers and may be covered by U.S. and Foreign Patents, patents in
#  * process, and are protected by trade secret or copyright law.  Dissemination of
#  * this information or reproduction of this material is strictly forbidden unless
#  * prior written permission is obtained from Keysight Technologies, Inc.
#  *
#  * No warranty, explicit or implicit is provided, unless granted under a written
#  * agreement with Keysight Technologies, Inc.
#  *
#  ******************************************************************************/


# For Infiniband and RoCEv2 formats, see:
# https://www.afs.enea.it/asantoro/V1r1_2_1.Release_12062007.pdf
# https://www.mindshare.com/files/ebooks/InfiniBand%20Network%20Architecture.pdf
# https://cw.infinibandta.org/document/dl/7781
# https://community.mellanox.com/s/article/rocev2-cnp-packet-format-example
# https://community.mellanox.com/s/article/how-to-dump-rdma-traffic-using-the-inbox-tcpdump-tool--connectx-4-x
#
# Utils:
# http://www.sunshine2k.de/coding/javascript/crc/crc_js.html
# 

# TODO
# - All opcode definitions and bindings: see https://www.afs.enea.it/asantoro/V1r1_2_1.Release_12062007.pdf table 35 p 238


# from scapy.packet import Packet,bind_layers,Raw
# from scapy.fields import *
# from scapy.layers.l2 import Ether
# from scapy.layers.inet import IP, UDP, TCP
from scapy.all import *
import zlib, socket

class IB_BTH(Packet): 
   name = "Infiniband BTH" 
   fields_desc =  [ ByteEnumField("opcode", 0, {
                     0: "RC_Send_First",
                     4:"RC_Send_Only",
                     10: "RC_RDMA_Write_Only",
                     12:"RC_RDMA_Read_Request",
                     16:"RC_RDMA_Read_Response_Only",
                     17:"RC_Acknowledge",
                     100:"UD_Send_Only",
                     129:"RoCEv2_CNP"
                  }),
                    BitField("SE", 0, 1),       # Solicited Event
                    BitField("MigReq", 0, 1),   # Migration Request
                    BitField("PadCnt", 0, 2),   # Pad Count 
                    BitField("tver", 0, 4),     # Transport Version 
                    XShortField("p_key", 0),    # Partition Key
                    BitField("Res_var", 0, 8),  # Reserved variant (doesn't change iCRC))
                    XBitField("dest_qp", 0, 24),  # Dest Queue pointer
                    BitField("ack_req", 0, 1),  # Acknowledge Request
                    BitField("Res", 0, 7),      # Reserved (does change iCRC))
                    XBitField("pkt_seq", 0, 24),  # Packet Sequnce Number (PSN)
                     ] 

   def mysummary(self):
      return self.sprintf("IB_BTH (opcode=%IB_BTH.opcode%)")

bind_layers(UDP, IB_BTH, dport=4791)
# bind_layers(IB_BTH, Raw)

class IB_iCRC(Packet):
   name = "Infiniband invariant CRC"
   fields_desc =   [ XLEIntField("iCRC", 0)]

class IB_CNP(Packet):
   name = "RoCEv2 CNP Payload"

   # XNBytesField not supported?
   # fields_desc =   [ XNBytesField("payload", 0, 16)]
   fields_desc =   [ XIntField("payload0", 0),
                     XIntField("payload1", 0),
                     XIntField("payload2", 0),
                     XIntField("payload3", 0),
                     ]

   def mysummary(self):
      return self.sprintf("IB_CNP (payload=%IB_CNP.payload%)")

   def mysummary(self):
      return self.sprintf("IB_iCRC (iCRC=%IB_iCRC.iCRC%)")
bind_layers(IB_BTH, IB_CNP, opcode=129)
bind_layers(IB_CNP, IB_iCRC)

class IB_DATA_16(Packet):
   name = "RoCEv2 Data; Fixed 16-byte Payload"

   fields_desc =   [ XIntField("Word0", 0),
                     XIntField("Word1", 0),
                     XIntField("Word2", 0),
                     XIntField("Word3", 0)
                     ]

   def mysummary(self):
      return self.sprintf("IB_DATA_16")

bind_layers(IB_BTH, IB_DATA_16, opcode=4)
bind_layers(IB_DATA_16, IB_iCRC)

class IB_PAYLOAD(Raw):
   name = "RoCEv2 Variable Payload"

   # Update len
   # TODO should be in post_dissect()?
   # Doesn't seem to be called anyway..
   def post_build(self, p, pay):
      
      if pay is None:
         return Raw(bytes(p)[:-4])/IB_iCRC(bytes(p)[-4:])
    
bind_layers(IB_PAYLOAD, IB_iCRC)

class IB_RETH(Packet):
   name = "RDMA Extended Transport Header"

   fields_desc =   [ XLongField("Virtual_Address", 0),
                     IntField("Remote_Key", 0),
                     IntField("DMA_Length", 0)
                     ]
bind_layers(IB_BTH, IB_RETH, opcode=10)
bind_layers(IB_RETH, IB_PAYLOAD)


class IB_CRC_PREAMBLE(Packet):
   name = "RoCEv2 Preamble For iCRC Calculation"

   # XNBytesField not supported?
   fields_desc =   [ XIntField("Word0", 0xffffffff),
                     XIntField("Word1", 0xffffffff)
                     ]

   def mysummary(self):
      return self.sprintf("IB_CRC_PREAMBLE")



def prepare_icrc_packet(pkt_in):
   """
   For an input packet, prepare it to have CRC32 run on it.
   Returns modified copy of packet.
   """
   try:
      p=pkt_in[IP].copy()
   except Exception as e:
      raise Exception("Bad/missing IP layer?" + e)
   # Start CRC at IP layer

   # Strip iCRC field if exists
   # TODO - add more tests as we define more Infiniband layers
   if p.haslayer(IB_DATA_16):
      p[IB_DATA_16].remove_payload()
   elif p.haslayer(IB_CNP):
      p[IB_CNP].remove_payload()
   else:
      print ("!!! Didn't strip IB_iCRC from pkt:\n", p.show(dump=True))

   # Prepend 64 1's:
   p='\xff\xff\xff\xff\xff\xff\xff\xff'/p

   # Replace variant fields with all ones
   p[IP].tos=0xff
   p[IP].ttl=0xff
   p[IP].chksum=0xffff
   p[UDP].chksum=0xffff
   p[IB_BTH].Res_var = 0xff
   # Restore IP, UDP len to make up for chopped off iCRC
   p[IP].len = len(pkt_in[IP])
   p[UDP].len = len(pkt_in[UDP])

   return p

def calc_icrc(pkt_in):
   """
   Calculate the Infiniband iCRC in the input packet
   Does not modify the input packet. Works on a copy to perform iCRC modifications.
   """
   p=prepare_icrc_packet(pkt_in)
   # return zlib.crc32(str(p)) & 0xffffffff # ensure unsigned result
   return zlib.crc32(bytes(p)) & 0xffffffff # ensure unsigned result

   
def update_icrc(pkt_in):
   """
   Calculate the Infiniband iCRC in the input packet and update the iCRC
   using network byte order
   See https://pythontic.com/modules/socket/byteordering-coversion-functions
   """
   pkt_in[IB_iCRC].iCRC=socket.htonl(calc_icrc(pkt_in))
   pkt_in[IB_iCRC].iCRC=calc_icrc(pkt_in)

def pkt_to_hexbytes(pkt_in):
   """
   Convert a packet into a packed list of kex bytes, e.g.:
   pkt_to_hexbytes(Ether()) = 'ffffffffffff0800275431819000'
   """
   return ''.join(["%02x" % ord(x) for x in bytes(pkt_in)])