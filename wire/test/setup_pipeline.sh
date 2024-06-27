cd /home/vagrant/p4tc-examples-pub/wire/generated
export INTROSPECTION=../generated
export TC="/usr/sbin/tc"
./wire.template
make -C ..
$TC filter add block 21 ingress protocol all prio 10 p4 pname wire \
action bpf obj wire_parser.o section p4tc/parse \
action bpf obj wire_control_blocks.o section p4tc/main


