# Create the bridge for the bridged "osnet" Network
sudo ip link add br-os type bridge

# Let br-os and br-os-ext be aware of vlans
sudo ip link add br-os type bridge vlan_filtering 1
sudo ip link add br-os-ext type bridge vlan_filtering 1
sudo ip link set br-os up
sudo ip link set br-os-ext up
