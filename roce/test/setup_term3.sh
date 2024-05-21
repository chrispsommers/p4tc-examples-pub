cd /home/vagrant/p4tc-examples-pub/roce/generated
export INTROSPECTION=../generated
export TC="/usr/sbin/tc"
./roce.template
make -C ..
$TC filter add block 21 ingress protocol all prio 10 p4 pname roce \
action bpf obj roce_parser.o section p4tc/parse \
action bpf obj roce_control_blocks.o section p4tc/main
