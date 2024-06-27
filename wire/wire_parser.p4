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


struct headers_t {
    ethernet_t   ethernet;
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
        transition accept;
    }
}
