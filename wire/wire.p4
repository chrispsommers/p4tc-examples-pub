#include "wire_parser.p4"


/*********************  D E P A R S E R  ************************/
control Deparser(
    packet_out pkt,
    inout    headers_t hdr,
    in    metadata_t meta,
    in    pna_main_output_metadata_t ostd)
{

    apply {
        pkt.emit(hdr.ethernet);

    }
}

control Main(
    inout headers_t  hdr,
    inout metadata_t meta,
    in    pna_main_input_metadata_t  istd,
    inout pna_main_output_metadata_t ostd
) {
   apply {}
}

/************ F I N A L   P A C K A G E ******************************/
PNA_NIC(
    Parser(),
    Main(),
    Deparser()
) main;
