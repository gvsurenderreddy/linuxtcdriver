# linuxtcdriver
Simple Linux TC Wrapper utility to configure Bandwidth, Jitter, Packetloss, Latency in the Virtual or Physical Ethernet link.

This driver is using, Linux TC (Traffic Control) utility with netem configuration to simulate this.



The TC input paramter format is used for bandwidth, latency, jitter, pktloss.


#Example
Note:  This is just a indicative program. 

    ifname = "veth1"
    config =
        bandwidth : "128Kbit"
        latency : "100ms"
        jitter : "10ms"
        pktloss : "1%"

    netem = require('linuxtcdriver')
    Netem =  new netem(ifname,config)
    Netem.create()



This driver is used in Kaanalnet application to configure the link characteristics, https://github.com/sureshkvl/kaanalnet/blob/master/src/builder/switchCtrl.coffee
