//----------------------------------------------------------------------------
// Jeferson Santiago da Silva
//----------------------------------------------------------------------------
#include "xilinx.p4"

typedef bit<48>     MacAddress;
typedef bit<32>     IPv4Address;
typedef bit<128>    IPv6Address;


header ethernet_h {
    MacAddress          dst;
    MacAddress          src;
    bit<16>             type;
}

header ipv6_h {
    bit<4>              version;
    bit<8>              tc;
    bit<20>             fl;
    bit<16>             plen;
    bit<8>              nh;
    bit<8>              hl;
    IPv6Address         src;
    IPv6Address         dst;
}

header tcp_h {
    bit<16>             sport;
    bit<16>             dport;
    bit<32>             seq;
    bit<32>             ack;
    bit<4>              dataofs;
    bit<4>              reserved;
    bit<8>              flags;
    bit<16>             window;
    bit<16>             chksum;
    bit<16>             urgptr;
}


struct headers_t {
    ethernet_h          ethernet;
    ipv6_h              ipv6;
    tcp_h               tcp;
}

@Xilinx_MaxPacketRegion(1518*8)  // in bits
parser Parser(packet_in pkt, out headers_t hdr) {

    state start {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.type) {
            0x86DD  : parse_ipv6;
            default : reject;
        }
    }

    state parse_ipv6 {
        pkt.extract(hdr.ipv6);
        transition select(hdr.ipv6.nh) {
            6       : parse_tcp;
            default : reject;
        }
    }

    state parse_tcp {
        pkt.extract(hdr.tcp);
        transition accept;
    }

}

control Forward(inout headers_t hdr, inout switch_metadata_t ctrl) {
    action forwardPacket(bit<8> value) {
        ctrl.egress_port = value[3:0] & value[7:4];
    }
    action dropPacket() {
        ctrl.egress_port = 0xF;
    }

    //@Xilinx_ExternallyConnected
    table forwardIPv6 {
        key             = { hdr.ipv6.dst[63:0] : lpm; }
        actions         = { forwardPacket; dropPacket; }
        size            = 65535;
        default_action  = dropPacket;
    }

    apply {
        if (hdr.ipv6.isValid())
            //forwardIPv6.apply();
            forwardPacket(0x1);
        else
            dropPacket();
    }
}

@Xilinx_MaxPacketRegion(1518*8)  // in bits
control Deparser(in headers_t hdr, packet_out pkt) {
    apply {
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.ipv6);
        pkt.emit(hdr.tcp);
    }
}

XilinxSwitch(Parser(), Forward(), Deparser()) main;

