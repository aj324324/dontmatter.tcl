# ################################################
# Declare parameters to initialize the wireless properties
set val(chan)           Channel/WirelessChannel    ;# Type of channel
set val(prop)           Propagation/TwoRayGround   ;# Radio model (propagation)
set val(netif)          Phy/WirelessPhy            ;# NIC (Interface Card)
set val(mac)            Mac/802_11                 ;# Medium Access Control (MAC)
set val(ifq)            Queue/DropTail/PriQueue    ;# Type of queuing interface
set val(ll)             LL                         ;# link layer type
set val(ant)            Antenna/OmniAntenna        ;# Antenna Model
set val(ifqlen)         50                         ;# max packet in interface queue
set val(nn)             4                          ;# number of mobilenodes
set val(rp)             DSDV                       ;# routing protocol
set val(x)        		300
set val(y)        		300
set val(stop)			20

# ################################################
# Make a simulator (scheduler)
  set ns [new Simulator]

# nam sim data
set nf [open wrls.nam w]
$ns namtrace-all-wireless $nf $val(x) $val(y)

# cwnd data
set wf1 [open wrls.tr w]
set wf2 [open wrls_cross.tr w]

## ################################################
# Set up topography object
set topo  [new Topography]
$topo load_flatgrid $val(x) $val(y)

# ################################################
# Create God, GOD Means - General Operations Director
create-god $val(nn)

# ################################################
# Create a channel
set channel1 [new $val(chan)]

# ################################################
# Configure nodes
$ns node-config -adhocRouting $val(rp) \
            -llType $val(ll) \
            -macType $val(mac) \
            -ifqType $val(ifq) \
            -ifqLen $val(ifqlen) \
            -antType $val(ant) \
            -propType $val(prop) \
            -phyType $val(netif) \
            -topoInstance $topo \
            -agentTrace ON \
            -routerTrace ON \
            -macTrace ON \
            -movementTrace OFF \
            -channel $channel1

set n0 [$ns node]
set n1 [$ns node]
set n2 [$ns node]
set n3 [$ns node]

# Disable random motion
$n0 random-motion 0
$n1 random-motion 0

# Set initial node positions
$n0 set X_ 0.0
$n0 set Y_ 0.0
$n0 set Z_ 0.0 

$n1 set X_ 100.0 
$n1 set Y_ 100.0
$n1 set Z_ 0.0

$n2 set X_ 0.0
$n2 set Y_ 100.0
$n2 set Z_ 0.0

$n3 set X_ 100.0
$n3 set Y_ 0.0 
$n3 set Z_ 0.0

$ns initial_node_pos $n1 50
$ns initial_node_pos $n0 50
$ns initial_node_pos $n2 50
$ns initial_node_pos $n3 50

# n0 -> n1
set tcp [new Agent/TCP/Linux]
$tcp set fid_ 1
$tcp set class_ 2
$tcp set window_ 8000
$tcp set packetSize_ 1500
$ns at 0 "$tcp select_ca cubic"
$ns attach-agent $n0 $tcp

set sink [new Agent/TCPSink/Sack1]
$sink set class_ 2
$sink set ts_echo_rfc1323_ true
$ns attach-agent $n1 $sink

$ns connect $tcp $sink

# n2 -> n3
set tcp1 [new Agent/TCP/Linux]
$tcp1 set fid_ 2
$tcp1 set class_ 2
$tcp1 set window_ 8000
$tcp1 set packetSize_ 1500
$ns at 0 "$tcp1 select_ca cubic"
$ns attach-agent $n2 $tcp1

set sink1 [new Agent/TCPSink/Sack1]
$sink1 set class_ 2
$sink1 set ts_echo_rfc1323_ true
$ns attach-agent $n3 $sink1

$ns connect $tcp1 $sink1

set ftp [new Application/FTP]
$ftp attach-agent $tcp
$ftp set type_ FTP
set ftp1 [new Application/FTP]
$ftp1 attach-agent $tcp1
$ftp1 set type_ FTP

# Schedule start/stop times
$ns at 0.4 "$ftp start"
$ns at 0.1 "$ftp1 start"

$ns at $val(stop) "$ns nam-end-wireless $val(stop)"
$ns at $val(stop) "stop"
$ns at 20.5 "puts \"end simulation\" ; $ns halt"

proc stop {} {
	global ns wf1 wf2 nf
	$ns flush-trace
	close $wf1
	close $wf2
	close $nf
	exec nam wrls.nam &
}

# Setup proc for cwnd plotting
proc plotWindow {tcpSource1 tcpSource2 file1 file2} {
   global ns

   set time 0.1
   set now [$ns now]
   set cwnd1 [$tcpSource1 set cwnd_]
   set cwnd2 [$tcpSource2 set cwnd_]

   puts $file1 "$now $cwnd1"
   puts $file2 "$now $cwnd2"
   $ns at [expr $now+$time] "plotWindow $tcpSource1 $tcpSource2 $file1 $file2" 
}

# Setup plotting
$ns at 0.1 "plotWindow $tcp $tcp1 $wf1 $wf2"

# Start simulation
$ns run
