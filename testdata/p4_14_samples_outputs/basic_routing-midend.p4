#include <core.p4>
#include <v1model.p4>

struct ingress_metadata_t {
    bit<12> vrf;
    bit<16> bd;
    bit<16> nexthop_index;
}

header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
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
    bit<32> srcAddr;
    bit<32> dstAddr;
}

struct metadata {
    @name("ingress_metadata") 
    ingress_metadata_t ingress_metadata;
}

struct headers {
    @name("ethernet") 
    ethernet_t ethernet;
    @name("ipv4") 
    ipv4_t     ipv4;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name("parse_ethernet") state parse_ethernet {
        packet.extract<ethernet_t>(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            16w0x800: parse_ipv4;
            default: accept;
        }
    }
    @name("parse_ipv4") state parse_ipv4 {
        packet.extract<ipv4_t>(hdr.ipv4);
        transition accept;
    }
    @name("start") state start {
        transition parse_ethernet;
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    action NoAction_2() {
    }
    @name("on_miss") action on_miss() {
    }
    @name("rewrite_src_dst_mac") action rewrite_src_dst_mac(bit<48> smac, bit<48> dmac) {
        hdr.ethernet.srcAddr = smac;
        hdr.ethernet.dstAddr = dmac;
    }
    @name("rewrite_mac") table rewrite_mac_0() {
        actions = {
            on_miss();
            rewrite_src_dst_mac();
            NoAction_2();
        }
        key = {
            meta.ingress_metadata.nexthop_index: exact;
        }
        size = 32768;
        default_action = NoAction_2();
    }
    apply {
        rewrite_mac_0.apply();
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    action NoAction_3() {
    }
    action NoAction_4() {
    }
    action NoAction_5() {
    }
    action NoAction_6() {
    }
    action NoAction_7() {
    }
    @name("set_vrf") action set_vrf(bit<12> vrf) {
        meta.ingress_metadata.vrf = vrf;
    }
    @name("on_miss") action on_miss_2() {
    }
    @name("on_miss") action on_miss_3() {
    }
    @name("on_miss") action on_miss_4() {
    }
    @name("fib_hit_nexthop") action fib_hit_nexthop(bit<16> nexthop_index) {
        meta.ingress_metadata.nexthop_index = nexthop_index;
        hdr.ipv4.ttl = hdr.ipv4.ttl + 8w255;
    }
    @name("fib_hit_nexthop") action fib_hit_nexthop_1(bit<16> nexthop_index) {
        meta.ingress_metadata.nexthop_index = nexthop_index;
        hdr.ipv4.ttl = hdr.ipv4.ttl + 8w255;
    }
    @name("set_egress_details") action set_egress_details(bit<9> egress_spec) {
        standard_metadata.egress_spec = egress_spec;
    }
    @name("set_bd") action set_bd(bit<16> bd) {
        meta.ingress_metadata.bd = bd;
    }
    @name("bd") table bd_0() {
        actions = {
            set_vrf();
            NoAction_3();
        }
        key = {
            meta.ingress_metadata.bd: exact;
        }
        size = 65536;
        default_action = NoAction_3();
    }
    @name("ipv4_fib") table ipv4_fib_0() {
        actions = {
            on_miss_2();
            fib_hit_nexthop();
            NoAction_4();
        }
        key = {
            meta.ingress_metadata.vrf: exact;
            hdr.ipv4.dstAddr         : exact;
        }
        size = 131072;
        default_action = NoAction_4();
    }
    @name("ipv4_fib_lpm") table ipv4_fib_lpm_0() {
        actions = {
            on_miss_3();
            fib_hit_nexthop_1();
            NoAction_5();
        }
        key = {
            meta.ingress_metadata.vrf: exact;
            hdr.ipv4.dstAddr         : lpm;
        }
        size = 16384;
        default_action = NoAction_5();
    }
    @name("nexthop") table nexthop_0() {
        actions = {
            on_miss_4();
            set_egress_details();
            NoAction_6();
        }
        key = {
            meta.ingress_metadata.nexthop_index: exact;
        }
        size = 32768;
        default_action = NoAction_6();
    }
    @name("port_mapping") table port_mapping_0() {
        actions = {
            set_bd();
            NoAction_7();
        }
        key = {
            standard_metadata.ingress_port: exact;
        }
        size = 32768;
        default_action = NoAction_7();
    }
    apply {
        if (hdr.ipv4.isValid()) {
            port_mapping_0.apply();
            bd_0.apply();
            switch (ipv4_fib_0.apply().action_run) {
                on_miss_2: {
                    ipv4_fib_lpm_0.apply();
                }
            }

            nexthop_0.apply();
        }
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit<ethernet_t>(hdr.ethernet);
        packet.emit<ipv4_t>(hdr.ipv4);
    }
}

struct struct_0 {
    bit<4>  field;
    bit<4>  field_0;
    bit<8>  field_1;
    bit<16> field_2;
    bit<16> field_3;
    bit<3>  field_4;
    bit<13> field_5;
    bit<8>  field_6;
    bit<8>  field_7;
    bit<32> field_8;
    bit<32> field_9;
}

control verifyChecksum(in headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    bit<16> tmp;
    @name("ipv4_checksum") Checksum16() ipv4_checksum_0;
    action act() {
        mark_to_drop();
    }
    action act_0() {
        tmp = ipv4_checksum_0.get<struct_0>({ hdr.ipv4.version, hdr.ipv4.ihl, hdr.ipv4.diffserv, hdr.ipv4.totalLen, hdr.ipv4.identification, hdr.ipv4.flags, hdr.ipv4.fragOffset, hdr.ipv4.ttl, hdr.ipv4.protocol, hdr.ipv4.srcAddr, hdr.ipv4.dstAddr });
    }
    table tbl_act() {
        actions = {
            act_0();
        }
        const default_action = act_0();
    }
    table tbl_act_0() {
        actions = {
            act();
        }
        const default_action = act();
    }
    apply {
        tbl_act.apply();
        if (hdr.ipv4.hdrChecksum == tmp) 
            tbl_act_0.apply();
    }
}

struct struct_1 {
    bit<4>  field_10;
    bit<4>  field_11;
    bit<8>  field_12;
    bit<16> field_13;
    bit<16> field_14;
    bit<3>  field_15;
    bit<13> field_16;
    bit<8>  field_17;
    bit<8>  field_18;
    bit<32> field_19;
    bit<32> field_20;
}

control computeChecksum(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name("ipv4_checksum") Checksum16() ipv4_checksum_1;
    action act_1() {
        hdr.ipv4.hdrChecksum = ipv4_checksum_1.get<struct_1>({ hdr.ipv4.version, hdr.ipv4.ihl, hdr.ipv4.diffserv, hdr.ipv4.totalLen, hdr.ipv4.identification, hdr.ipv4.flags, hdr.ipv4.fragOffset, hdr.ipv4.ttl, hdr.ipv4.protocol, hdr.ipv4.srcAddr, hdr.ipv4.dstAddr });
    }
    table tbl_act_1() {
        actions = {
            act_1();
        }
        const default_action = act_1();
    }
    apply {
        tbl_act_1.apply();
    }
}

V1Switch<headers, metadata>(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;