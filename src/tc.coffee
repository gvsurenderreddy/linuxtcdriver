util = require 'util'
exec = require('child_process').exec
fs = require('fs')
extend = require('util')._extend


Schema =
    name: "tcqdisc"
    type: "object"
    required: true
    properties:   
        bandwidth:  {"type":"string", "required":false}
        latency:  {"type":"string", "required":false}
        jitter:  {"type":"string", "required":false}
        pktloss:  {"type":"string", "required":false}

execute = (command, callback) ->
    callback false unless command?
    util.log "executing #{command}..."        
    exec command, (error, stdout, stderr) =>
        util.log "tcdriver: execute - Error : " + error
        util.log "tcdriver: execute - stdout : " + stdout
        util.log "tcdriver: execute - stderr : " + stderr
        if error
            callback error
        else
            callback true    

class tcqdisc
    constructor : (ifname,data)->
        @interface = ifname
        @config = extend {}, data   
        @config.bandwidth ?= "100mbit"
        #@config.latency ?= "0ms"
        #@config.jitter ?= "0ms"
        #@config.pktloss ?= "0%"

        console.log "tcqdisc object created with " + JSON.stringify @config

    create: ()->
        # identify htb+netem to be used or only htb
        #only bandwidth 
        if not @config.latency? and not @config.jitter? and not @config.pktloss?
            console.log "HTB case - only bandwidth"
            console.log "HTB0 bandwidth : #{@config.bandwidth} latency: #{@config.latency} jitter: #{@config.jitter}  packetloss : #{@config.pktloss} "
            command = "tc qdisc add dev #{@interface} root tbf rate #{@config.bandwidth} burst 100kb latency 0.001ms"
            execute command,(result)->
                console.log "create result ", result
                ###
        else if @config.latency? and not @config.jitter? and not @config.pktloss?
            console.log "HTB Case bandwidth and delay"
            console.log "HTB1 bandwidth : #{@config.bandwidth} latency: #{@config.latency} jitter: #{@config.jitter}  packetloss : #{@config.pktloss} "
            command = "tc qdisc add dev #{@interface} root tbf rate #{@config.bandwidth} burst 100kb latency #{@config.latency}"
            execute command,(result)->
                console.log "create result ", result
        ###
        else
            console.log "Netem case"
            console.log "Netem bandwidth : #{@config.bandwidth} latency: #{@config.latency} jitter: #{@config.jitter}  packetloss : #{@config.pktloss} "
            command = "tc qdisc add dev #{@interface} root handle 1:0 netem delay #{@config.latency} "
            cmd1 = "tc qdisc add dev #{@interface} parent 1:1 handle 10: tbf rate  #{@config.bandwidth} buffer 1600 limit 3000"
            cmd1 += " #{@config.jitter}" if @config.jitter?
            cmd1  += " loss #{@config.pktloss} " if @config.pktloss?
            execute command,(result)->
                console.log "create result ", result
                execute cmd1,(result)->
                    console.log "create result ", result

    get : ()->
        interface : @interface
        config : @config
        stats:  null
    
    del: ()->
        cmd = "tc qdisc del dev #{@interface} root"
        console.log "del command",cmd
        execute cmd,(result)->
            console.log "delete cmd result ", result

    stats: ()->



config =
    bandwidth : "1mbit"
    latency : "10ms"
    #jitter : "0.1ms"
    #pktloss : "0.1%"



tcobj = new tcqdisc "virbr0", config
tcobj.create()
#console.log tcobj.get()

