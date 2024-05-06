# Create a simulator
set ns [new Simulator]

# Define flow colors for NAM
$ns color 1 Blue
$ns color 2 Red

# Open NAM trace file
set file2 [open out.nam w]
$ns namtrace-all $file2

# Open window trace files
set wf1 [open WinFile1 w]
set wf2 [open WinFile2 w]

# Define finish procedure
proc finish {} {
    global ns file2
    $ns flush-trace
    close $file2
    exec nam out.nam &
    exit 0
}

# Create the network nodes
set n0 [$ns node]
set n1 [$ns node]
set n2 [$ns node]
set n3 [$ns node]
set n4 [$ns node]
set n5 [$ns node]

# Create network links
$ns duplex-link $n0 $n2 2Mb 10ms DropTail
$ns duplex-link $n1 $n2 2Mb 10ms DropTail
$ns simplex-link $n2 $n3 0.3Mb 200ms DropTail
$ns simplex-link $n3 $n2 0.3Mb 200ms DropTail
$ns duplex-link $n3 $n4 0.5Mb 40ms DropTail
$ns duplex-link $n3 $n5 0.5Mb 30ms DropTail

# Monitor the queue for link n2-n3 (for NAM)
$ns duplex-link-op $n2 $n3 queuePos 0.1

# Set NAM positions for links
$ns duplex-link-op $n0 $n2 orient right-down
$ns duplex-link-op $n1 $n2 orient right-up
$ns simplex-link-op $n2 $n3 orient right
$ns simplex-link-op $n3 $n2 orient left
$ns duplex-link-op $n3 $n4 orient right-up
$ns duplex-link-op $n3 $n5 orient right-down

# Set queue size for n2-n3
$ns queue-limit $n2 $n3 10

# Setup n1 to n4 connection
set tcp0 [new Agent/TCP/Linux]
$tcp0 set fid_ 1
$tcp0 set window_ 8000
$tcp0 set packetSize_ 1500
$ns attach-agent $n1 $tcp0

set sink0 [new Agent/TCPSink/Sack1]
$sink0 set class_ 1
$sink0 set ts_echo_rfc1323_ true
$ns attach-agent $n4 $sink0

set ftp0 [new Application/FTP]
$ftp0 attach-agent $tcp0

$ns connect $tcp0 $sink0

# Setup n0 to n5 connection
set tcp1 [new Agent/TCP/Linux]
$tcp1 set fid_ 2
$tcp1 set window_ 8000
$tcp1 set packetSize_ 5000
$ns attach-agent $n0 $tcp1

set sink1 [new Agent/TCPSink/Sack1]
$sink1 set class_ 2
$sink1 set ts_echo_rfc1323_ true
$ns attach-agent $n5 $sink1

set ftp1 [new Application/FTP]
$ftp1 attach-agent $tcp1

$ns connect $tcp1 $sink1

# Schedule FTP traffic
$ns at 0.1 "$ftp0 start"
$ns at 0.1 "$ftp1 start"

$ns at 100.0 "$ftp0 stop"
$ns at 100.0 "$ftp1 stop"

# Plot congestion window
proc plotWindow {tcpSource file} {
    global ns

    set time 0.1
    set now [$ns now]
    set cwnd [$tcpSource set cwnd_]

    puts $file "$now $cwnd"
    $ns at [expr $now+$time] "plotWindow $tcpSource $file"
}

# Start plotting for both connections
$ns at 0.1 "plotWindow $tcp0 $wf1"
$ns at 0.1 "plotWindow $tcp1 $wf2"

# Set simulation end time
$ns at 125.0 "finish"

# Run simulation
$ns run
