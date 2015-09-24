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
        @config.latency ?= "0ms"
        @config.jitter ?= "0ms"
        @config.pktloss ?= "0%"

        console.log "tcqdisc object created with " + JSON.stringify @config

    create : ()->
        if @config.latency is "0ms" and @config.jitter is "0ms" and @config.pktloss is "0%"
            #no netem only bandwidth
            #tc qdisc add dev eth0 root tbf rate 1mbit burst 10kb latency 0.0001ms
            command = "tc qdisc add dev #{@interface} root tbf rate #{@config.bandwidth} burst 100kb latency 0.001ms"
            console.log "command is ", command
            execute command,(result)->
                console.log "create result ", result

        else 
            #netem params included 
            cmd = ""
            cmd += "tc qdisc add dev #{@interface} root handle 1:0 netem delay #{@config.latency} " if @config.latency isnt "0ms"
            cmd += " #{@config.jitter} " if @config.jtter isnt "0ms"
            cmd += " loss #{@config.pktloss} " if @config.pktloss isnt "0%"
            console.log "command is ", cmd

            cmd1 = "tc qdisc add dev #{@interface} parent 1:1 handle 10: tbf rate  #{@config.bandwidth} buffer 1600 limit 3000"
            

            execute cmd,(result)->
                console.log "create cmd result ", result
                console.log "command1 is ", cmd1
                execute cmd1,(result)->
                    console.log "create cmd1 result ", result

    get : ()->
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
    jitter : "0.1ms"
    pktloss : "0.1%"



tcobj = new tcqdisc "eth0", config
tcobj.create()
console.log tcobj.get()

