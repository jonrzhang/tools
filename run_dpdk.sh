#!/bin/bash
#@author JonZhang jon.r.zhang@gmail.com
#DPDK create vm script:

GLANCE_IMAGE_FILE=/root/dpdk512.qcow2
GLANCE_IMAGE_NAME=dpdk512
FLAVOR_NAME=dpdk-flvr
DPDK_NAME=("l2fwd_tx" "l2fwd_rx")
DPDK_VLAN=("1140" "1150")
DPDK_CIDR=("10.11.40.0/24" "10.11.50.0/24")


# image create if not exist
if `!(echo $(glance image-list) | grep -w $GLANCE_IMAGE_NAME > /dev/null )`
then
    glance image-create --name $GLANCE_IMAGE_NAME --disk-format qcow2 --container-format bare --visibility public \
        --progress --file $GLANCE_IMAGE_FILE
else
    echo "Image "$GLANCE_IMAGE_NAME" already exist"
fi
image_id=$(glance image-list | awk -F\| '$3~"'${GLANCE_IMAGE_NAME}'" {print $2}' | sed 's/\s//g')
image_cmd="--image $image_id "

# flavor create if not exist
if `!(echo $(nova flavor-list) | grep -w $FLAVOR_NAME > /dev/null )`
then
    nova flavor-create $FLAVOR_NAME 6 4096 105 4
    nova flavor-key 6 set hw:mem_page_size=1048576
    nova flavor-key 6 set hw:cpu_policy=dedicated
else
    echo "Flavor "$FLAVOR_NAME" already exist"
fi
flavor_id=$(nova flavor-list | awk -F\| '$3~"'$FLAVOR_NAME'" {print $2}' | sed 's/\s//g')
flavor_cmd="--flavor $flavor_id "

# net,subnet and port create if not exist
loop_id=0
port_cmd=""
for name in ${DPDK_NAME[@]}
do
    if `!(echo $(neutron net-list) | grep -w $name > /dev/null )`
    then
        neutron net-create --provider:physical_network=default --provider:network_type=vlan --provider:segmentation_id=${DPDK_VLAN[$loop_id]} $name
        neutron subnet-create --name ${name}_sub $name ${DPDK_CIDR[$loop_id]}
        neutron port-create $name --name ${name}_port
    else
        echo "Port ${name}_port already exist"
    fi
    port_cmd="$port_cmd""--nic port-id=$(neutron port-list  --field={id,name} | awk -F\| '$3~"'${name}_port'" {print $2}' | sed 's/\s//g') "
    loop_id=`expr $loop_id + 1 `
done

#echo "$flavor_cmd"
#echo "$image_cmd"
#echo "$port_cmd"
#nova boot --flavor 8 --image sriov --nic port-id=$(neutron port-list  --field={id,name} | awk -F\| '$3~"sriov_port1" {print $2}' | sed 's/\s//g') \
#       --nic port-id=$(neutron port-list  --field={id,name} | awk -F\| '$3~"sriov_port2" {print $2}' | sed 's/\s//g') \
#       --availability-zone nova:compute-0-1.domain.tld \
#       sriov-vm1
vm_name="dpdk512"
nova_create_cmd="nova boot "$flavor_cmd$image_cmd$port_cmd"--availability-zone nova:compute-0-6.domain.tld "$vm_name
if `!(echo $(nova list) | grep -w $vm_name > /dev/null )`
then
    echo "$nova_create_cmd"
    eval "$nova_create_cmd"
else
    echo "VM already exist, Nothing to create!"
fi
