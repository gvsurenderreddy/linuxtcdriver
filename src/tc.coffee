util = require 'util'
exec = require('child_process').exec
fs = require('fs')
extend = require('util')._extend
async = require 'async'

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

delLink = (ifname,callback)->
    command = "ip link delete #{ifname}"        
    util.log "executing #{command}..."
    execute command, (result) =>        
        if result instanceof Error
             callback(false) 
        else
            callback(false)

class tcqdisc
    constructor : (ifname,data)->
        @interface = ifname
        @config = extend {}, data   
        @stats = {}
        @stats.tc = {}
        @stats.ifconfig = {}
        @config.bandwidth ?= "100mbit"
        @commands = []
        console.log "tcqdisc object created with " + JSON.stringify @config
        #only bandwidth 
        @commands = []
        if not @config.latency? and not @config.jitter? and not @config.pktloss?
            console.log "HTB case - only bandwidth"
            console.log "HTB0 bandwidth : #{@config.bandwidth} latency: #{@config.latency} jitter: #{@config.jitter}  packetloss : #{@config.pktloss} "
            command = "tc qdisc add dev #{@interface} root tbf rate #{@config.bandwidth} burst 100kb latency 0.001ms"
            @commands.push command
            #execute command,(result)->
            #    console.log "create result ", result
        else
            console.log "Netem case"
            console.log "Netem bandwidth : #{@config.bandwidth} latency: #{@config.latency} jitter: #{@config.jitter}  packetloss : #{@config.pktloss} "
            command = "tc qdisc add dev #{@interface} root handle 1:0 netem delay #{@config.latency} "
            command += " #{@config.jitter}" if @config.jitter?
            command  += " loss #{@config.pktloss} " if @config.pktloss?
            @commands.push command
            cmd1 = "tc qdisc add dev #{@interface} parent 1:1 handle 10: tbf rate  #{@config.bandwidth} buffer 1600 limit 3000"
            @commands.push cmd1
            #execute command,(result)->
            #    console.log "create result ", result
            #    execute cmd1,(result)->
            #        console.log "create result ", result
    run : (cb)->
        async.eachSeries @commands, (command,callback) =>        
            execute command, (result)=>
                console.log "create result ", result
                callback()            
        ,(err) =>
            if err
                console.log "LinkConfig error occured " + JSON.stringify err
                cb(false)
            else
                console.log "LinkConfig  all are processed "
                cb (true)

    #for backward compatibility keeping this
    create: ()->
        @run (cb)->
            return cb

    get : ()->
        interface : @interface
        config : @config
        stats:  @stats
    
    del: ()->
        cmd = "tc qdisc del dev #{@interface} root"
        console.log "del command",cmd
        execute cmd,(result)->
            console.log "delete cmd result ", result

    statistics: (callback)->
        command = "tc -s qdisc show dev #{@interface}"
        exec command, (error, stdout, stderr) =>
            util.log "tcdriver: execute - Error : " + error
            util.log "tcdriver: execute - stdout : " + stdout
            util.log "tcdriver: execute - stderr : " + stderr
            return callback error if error
            result = stdout.toString()
            tmparr = []
            tmparr = result.split("\n")
            return callback new Error "error during stats colletion" unless tmparr[3].search('qdisc tbf') isnt -1
            tmp0 = tmparr[3].split(' ')
            #console.log tmp0
            tmp1 = tmparr[4].split(' ')
            #console.log tmp1  
            @stats.tc.sentbytes = tmp1[2]
            @stats.tc.sentpackets = tmp1[4]
            @stats.tc.droppedpackets = tmp1[7]
            #@stats.time = new Time
            # execute the iplink command
            command = "ip -s link show #{@interface}"
            exec command, (error, stdout, stderr) =>
                util.log "tcdriver: execute - Error : " + error
                util.log "tcdriver: execute - stdout : " + stdout
                util.log "tcdriver: execute - stderr : " + stderr
                return callback error if error
                result = stdout.toString()
                tmparr = []
                tmparr = result.split("\n")

                tmp0 = tmparr[3].split(' ')
                console.log tmp0
                tmp1 = tmparr[5].split(' ')
                console.log tmp1
                @stats.ifconfig.rxbytes = tmp0[1]
                @stats.ifconfig.rxpackets = tmp0[2]
                @stats.ifconfig.rxerrors = tmp0[3]
                @stats.ifconfig.rxdropped = tmp0[4]
                @stats.ifconfig.txbytes = tmp1[1]
                @stats.ifconfig.txpackets = tmp[2]
                @stats.ifconfig.txerrors = tmp1[3]
                @stats.ifconfig.txdropped = tmp1[4]
                callback @stats

module.exports = tcqdisc
module.exports .delLink = delLink

config =
    bandwidth : "1mbit"
    latency : "10ms"
    jitter : "0.1ms"
    pktloss : "0.1%"


###
tcobj = new tcqdisc "virbr0", config
console.log tcobj.commands
tcobj.run (result)->
    console.log "run ",result
    tcobj.statistics (result)->
        console.log "stats",result
#tcobj.del()

###