sudo ip link add veth0-br type veth peer name veth0-app
sudo ip link set veth0-br up
sudo ip link set veth0-app up

sudo ip link add link veth0-app name veth0-app.50 type vlan id 50

sudo brctl addif br-os-ext veth0-br
sudo bridge vlan add vid 50 dev veth0-br

sudo ip link set veth0-br up
sudo ip link set veth0-app up
sudo ip link set veth0-app.50 up

sudo ip addr del 10.202.254.1/24 dev br-os-ext
sudo ip addr add 10.202.254.1/24 dev veth0-app.50

for a in $(sudo ip a | awk '/vnet.* br-os-ext / { print gensub(":","","g",$2) }'); do
  sudo bridge vlan add vid 50 dev "$a"
done
sudo bridge vlan add vid 50 dev veth0-br
