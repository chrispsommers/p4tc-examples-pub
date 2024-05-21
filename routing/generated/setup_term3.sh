cd /home/vagrant/p4tc-examples-pub/routing/generated
export INTROSPECTION=.
export TC="/usr/sbin/tc"
./routing.template
make -C ..
$TC filter add block 21 ingress protocol all prio 10 p4 pname routing \
action bpf obj routing_parser.o section p4tc/parse \
action bpf obj routing_control_blocks.o section p4tc/main
