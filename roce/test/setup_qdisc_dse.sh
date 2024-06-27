sudo ip netns exec rocelab-roce-1 tc qdisc add dev eth1 ingress_block 21 clsact
sudo ip netns exec rocelab-roce-2 tc qdisc add dev eth1 ingress_block 21 clsact

