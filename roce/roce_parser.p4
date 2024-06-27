/* -*- P4_16 -*- */

#include <core.p4>      // https://github.com/p4lang/p4c/blob/main/p4include/core.p4
#include <tc/pna.p4>    // https://github.com/p4lang/p4c/blob/main/p4include/tc/pna.p4

typedef bit<48> macaddr_t;

struct metadata_t {}

header ethernet_t {
    @tc_type("macaddr") macaddr_t dstAddr;
    @tc_type("macaddr") macaddr_t srcAddr;
    bit<16> etherType;
}

header ipv4_t {
    bit<4>  version;
    bit<4>  ihl;
    bit<8>  diffserv;
    bit<16> totalLen;
    bit<16> identification;
    bit<3>  flags;
    bit<13> fragOffset;
    bit<8>  ttl;
    bit<8>  protocol;
    bit<16> hdrChecksum;
    @tc_type("ipv4") bit<32> srcAddr;
    @tc_type("ipv4") bit<32> dstAddr;
}

header udp_t
{
    bit<16> srcPort;
    bit<16> dstPort;
    bit<16> length_;
    bit<16> checksum;
}

#define ETHERTYPE_IPV4 0x0800
#define IP_PROTO_UDP 17
#define ROCEV2_PORT_NUM 4791


// Infiniband Base Tranpsort Header (BTH)
// https://community.mellanox.com/s/article/rocev2-cnp-packet-format-example

typedef bit<8> ib_bth_opcode_t;
const ib_bth_opcode_t IB_RC_SEND_FIRST           = 8w0;      // Reliable Connection Send First
const ib_bth_opcode_t IB_RC_SEND_MIDDLE          = 8w1;      // Reliable Connection Send First
const ib_bth_opcode_t IB_RC_SEND_LAST            = 8w2;      // Reliable Connection Send Last
const ib_bth_opcode_t IB_RC_SEND_LAST_IMMED      = 8w3;      // Reliable Connection Send Last with immediate
const ib_bth_opcode_t IB_RC_SEND_ONLY            = 8w4;      // Reliable Connection Send Only
const ib_bth_opcode_t IB_RC_SEND_ONLY_IMMED      = 8w5;      // Reliable Connection Send Only with Immediate
const ib_bth_opcode_t IB_RC_RDMA_WRITE_FIRST     = 8w6;      // Reliable Connection RDMA Write First
const ib_bth_opcode_t IB_RC_RDMA_WRITE_MIDDLE    = 8w7;      // Reliable Connection RDMA Write Middle
const ib_bth_opcode_t IB_RC_RDMA_WRITE_LAST      = 8w8;      // Reliable Connection RDMA Write Last
const ib_bth_opcode_t IB_RC_RDMA_WRITE_LAST_IMMED= 8w9;      // Reliable Connection RDMA Write Last with Immediate
const ib_bth_opcode_t IB_RC_WRITE_ONLY           = 8w10;     // Reliable Connection Write only
const ib_bth_opcode_t IB_RC_WRITE_ONLY_IMMED     = 8w11;     // Reliable Connection Write only with Immediate
const ib_bth_opcode_t IB_RC_READ_REQ             = 8w12;     // Reliable Connection Read Request
const ib_bth_opcode_t IB_RC_READ_RESP_FIRST      = 8w13;     // Reliable Connection Read Response First
const ib_bth_opcode_t IB_RC_READ_RESP_MIDDLE     = 8w14;     // Reliable Connection Read Response Middle
const ib_bth_opcode_t IB_RC_READ_RESP_LAST       = 8w15;     // Reliable Connection Read Response Last
const ib_bth_opcode_t IB_RC_READ_RESP_ONLY       = 8w16;     // Reliable Connection Read Response Only
const ib_bth_opcode_t IB_RC_ACK                  = 8w17;     // Reliable Connection Acknowledge
const ib_bth_opcode_t IB_RC_ATOMIC_ACK           = 8w18;     // Reliable Connection Atomic Acknowledge

const ib_bth_opcode_t IB_UD_SEND_ONLY            = 8w100;    // Unreliable Datagram Send only
const ib_bth_opcode_t IB_CNP                     = 8w128;    // congestion-notification packet

// 54 bytes incl eth-ip-udp
// Infiniband Base Transport Header. References:
// https://www.afs.enea.it/asantoro/V1r1_2_1.Release_12062007.pdf
// https://www.mindshare.com/files/ebooks/InfiniBand%20Network%20Architecture.pdf
// 12 bytes
// CNP format: https://cw.infinibandta.org/document/dl/7781
//             https://community.mellanox.com/s/article/rocev2-cnp-packet-format-example

header ib_bth_h {
    ib_bth_opcode_t opcode;         // op-code 
    bit<1> se;                      // solicitied event
    bit<1> mig_req;                 // MigReq = M = migration request
    bit<2> pad_cnt;                 // Pad Count, how mny bytes added to payload to get 4-byte boundary
    bit<4> tver;                    // transport header version
    bit<16> p_key;                  // partition key
    bit<1> fecn_res1;               // FECN: 0 = FECN not received, 1 = FECN received; RES1: transmitted as 0; ignored on receive; not included in iCRC
    bit<1> becn_res1;               // BECN: 0 not marked as congested, 1 = congested; RES1: transmitted as 0; ignored on receive; not included in iCRC
    bit<6>  res_var;                // addl reserved (variant) bits; not included in iCRC
    bit<24> dest_qp;                // destination queue pair
    bit<1> ack_req;                 // acknowledge request; responder should schedule an acknowledge
    bit<7> res;                     // reserved bits; transmitted as 0; ignored on receive; is included in iCRC
    bit<24> pkt_seq;                // packet sequence number (PSN)
}

// block of 16 bytes in various Infiniband payloads, treat as 32-bit chunks
header ib_16byte_payload_h {
    bit <32> word0;                   // bytes 0-3
    bit <32> word1;                   // bytes 4-7
    bit <32> word2;                   // bytes 8-11
    bit <32> word3;                   // bytes 12-15
}

// AETH - ACK Extended Transport Header, op-code 17
header ib_aeth_h {
    bit <8> syndrome;   // bit-endoded field, see IB spec table 43
    bit<24> msn;        // message sequence number
}
header ib_icrc_h {
    bit <32> iCRC;                  // Invariant CRC checksum
}

struct headers_t {
    ethernet_t   ethernet;
    ipv4_t       ip;
    udp_t        udp;
    ib_bth_h                                       ib_bth;              // infiniband Base Transport Header
    ib_16byte_payload_h                            ib_16byte_payload;   // 16 bytes misc payload data
    ib_aeth_h                                      ib_aeth;             // ACK Extended Transport Header
    ib_icrc_h                                      ib_icrc;             // invariant CRC
}

/***********************  P A R S E R  **************************/
parser Parser(
        packet_in pkt,
        out   headers_t  hdr,
        inout metadata_t meta,
        in    pna_main_parser_input_metadata_t istd)
{
    state start {
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            ETHERTYPE_IPV4: parse_ipv4;
            default: accept;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ip);
        transition select(hdr.ip.protocol) {
            IP_PROTO_UDP: parse_udp;
            default: accept;
        }
    }

    state parse_udp {
        pkt.extract(hdr.udp);
        transition select(hdr.udp.dstPort) {
            ROCEV2_PORT_NUM: parse_rocev2;
            default: accept;
        }
    }

    @name(".parse_rocev2") state parse_rocev2 {
        pkt.extract(hdr.ib_bth);
        transition select(hdr.ib_bth.opcode) {
            IB_CNP: parse_ib_cnp;  // congestion notification
            IB_RC_SEND_ONLY: parse_ib_rc_send_only;  // reliable connection connection
            IB_RC_ACK: parse_ib_aeth;  
            default: accept;
        }
    }

    @name (".parse_ib_cnp") state parse_ib_cnp {
        pkt.extract(hdr.ib_16byte_payload);
        transition parse_ib_icrc;
    }

    @name (".parse_ib_rc_send_only") state parse_ib_rc_send_only {
        pkt.extract(hdr.ib_16byte_payload);
        transition parse_ib_icrc;
    }

    @name (".parse_ib_aeth") state parse_ib_aeth {
        pkt.extract(hdr.ib_aeth);
        transition parse_ib_icrc;
    }

    @name (".parse_ib_cnp") state parse_ib_icrc {
        pkt.extract(hdr.ib_icrc);
        transition accept;
    }
}
