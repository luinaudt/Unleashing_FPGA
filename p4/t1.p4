//----------------------------------------------------------------------------
// Jeferson Santiago da Silva
// T1 : complex parser
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

header ipv4_h {
        bit<4>  version;
        bit<4>  ihl;
        bit<8>  diffserv;
        bit<16> totalLen;
        bit<16> identification;
        bit<3> flags;
        bit<13> fragOffset;
        bit<8>  ttl;
        bit<8>  protocol;
        bit<16> hdrChecksum;
        bit<32> srcAddr;
        bit<32> dstAddr;
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

header vlan_h {
        bit<3> PCP;
        bit<1> DEI;
        bit<12> VID;
        bit<16> etherType;
}

// UDP header
header udp_h {
        bit<16> srcPort;
        bit<16> dstPort;
        bit<16> hdrLength;
        bit<16> chksum;
}

// ICMP header
header icmp_h {
        bit<8> mtype;
        bit<8> code;
        bit<16> chksum;
        bit<16> body;
}

struct headers_t {
    ethernet_h          ethernet;
    vlan_h              outer_vlan;
    vlan_h              inner_vlan;
    ipv4_h              ipv4;
    ipv6_h              ipv6;
    tcp_h               tcp;
    udp_h               udp;
    icmp_h              icmp;
}

@Xilinx_MaxPacketRegion(1518*8)  // in bits
parser Parser(packet_in pkt, out headers_t hdr) {

    state start {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.type) {
            0x86DD  : parse_ipv6;
            0x8100    : parse_inner_vlan;
            0x9100    : parse_outer_vlan;
            0x86DD    : parse_ipv6;
            0x0800    : parse_ipv4;
            default : reject;
        }
    }

    state parse_outer_vlan {
        pkt.extract(hdr.outer_vlan);
        transition select(hdr.outer_vlan.etherType) {
            0x8100    : parse_inner_vlan;
            default   : reject;
        }
    }

    state parse_inner_vlan {
        pkt.extract(hdr.inner_vlan);
        transition select(hdr.inner_vlan.etherType) {
            0x0800    : parse_ipv4;
            0x86DD    : parse_ipv6;
            default   : reject;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol) {
            0x01      : parse_icmp;
            0x11      : parse_udp;
            6       : parse_tcp;
            default : reject;
        }
    }

    state parse_ipv6 {
        pkt.extract(hdr.ipv6);
        transition select(hdr.ipv6.nh) {
            0x3a      : parse_icmp;
            0x11      : parse_udp;
            6       : parse_tcp;
            default : reject;
        }
    }

    state parse_tcp {
        pkt.extract(hdr.tcp);
        transition accept;
    }

    state parse_udp {
        pkt.extract(hdr.udp);
        transition accept;
    }

    state parse_icmp {
        pkt.extract(hdr.icmp);
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
        if (hdr.ethernet.isValid()) pkt.emit(hdr.ethernet);
        if (hdr.outer_vlan.isValid()) pkt.emit(hdr.outer_vlan);
        if (hdr.inner_vlan.isValid()) pkt.emit(hdr.inner_vlan);
        if (hdr.ipv4.isValid()) pkt.emit(hdr.ipv4);
        if (hdr.ipv6.isValid()) pkt.emit(hdr.ipv6);
        if (hdr.tcp.isValid()) pkt.emit(hdr.tcp);
        if (hdr.udp.isValid()) pkt.emit(hdr.udp);
        if (hdr.icmp.isValid()) pkt.emit(hdr.icmp);
    }
}

XilinxSwitch(Parser(), Forward(), Deparser()) main;

