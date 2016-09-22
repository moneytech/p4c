#include <core.p4>
#include <v1model.p4>

header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> ethertype;
}

struct metadata {
}

struct headers {
    @name("ethernet") 
    ethernet_t ethernet;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name("start") state start {
        packet.extract<ethernet_t>(hdr.ethernet);
        transition accept;
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    action NoAction_1() {
    }
    action NoAction_2() {
    }
    @name("c1") counter(32w1024, CounterType.packets) c1_0;
    @name("count_c1_1") action count_c1_1() {
        c1_0.count(32w1);
    }
    @name("count_c1_2") action count_c1_2() {
        c1_0.count(32w2);
    }
    @name("t1") table t1_0() {
        actions = {
            count_c1_1();
            NoAction_1();
        }
        default_action = NoAction_1();
    }
    @name("t2") table t2_0() {
        actions = {
            count_c1_2();
            NoAction_2();
        }
        default_action = NoAction_2();
    }
    apply {
        t1_0.apply();
        t2_0.apply();
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit<ethernet_t>(hdr.ethernet);
    }
}

control verifyChecksum(in headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control computeChecksum(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

V1Switch<headers, metadata>(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;