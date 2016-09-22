#include <core.p4>

control c(inout bit<32> arg) {
    bit<32> x_0;
    @name("a") action a() {
    }
    @name("t") table t_0() {
        key = {
            x_0: exact;
        }
        actions = {
            a();
        }
        default_action = a();
    }
    action act() {
        x_0 = arg;
    }
    action act_0() {
        x_0 = arg;
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
        if (t_0.apply().hit) {
            tbl_act_0.apply();
            t_0.apply();
        }
    }
}

control proto(inout bit<32> arg);
package top(proto p);
top(c()) main;