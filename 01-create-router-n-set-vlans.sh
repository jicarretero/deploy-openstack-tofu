# Create the bridge for the bridged "osnet" Network
sudo ip link add br-os type bridge

# Let br-os and br-os-ext be aware of vlans
sudo ip link add br-os type bridge vlan_filtering 1
sudo ip link add br-os-ext type bridge vlan_filtering 1
sudo ip link set br-os up
sudo ip link set br-os-ext up

# Start the networks (if they are not started) --
virsh net-start osnet
virsh net-start os-external

sudo ip route add 172.27.30.0/24 via 192.168.122.246
