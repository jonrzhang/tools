#!/bin/bash
#@author JonZhang jon.r.zhang@gmail.com
#SRIOV create vm script:

GLANCE_IMAGE_FILE=/root/jon/dpdk512.qcow
GLANCE_IMAGE_NAME=dpdk512
FLAVOR_NAME=sriov-flvr
SRIOV_POOLS=("pool_0000_0d_00_1" "pool_0000_05_00_1")


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
    nova flavor-create $FLAVOR_NAME 8 4096 80 4
    nova flavor-key 8 set hw:mem_page_size=1048576
    nova flavor-key 8 set hw:cpu_policy=dedicated
else
    echo "Flavor "$FLAVOR_NAME" already exist"
fi
flavor_id=$(nova flavor-list | awk -F\| '$3~"'$FLAVOR_NAME'" {print $2}' | sed 's/\s//g')
flavor_cmd="--flavor $flavor_id "

# net,subnet and port create if not exist
loop_id=0
base_ip=10
port_cmd=""
for pool in ${SRIOV_POOLS[@]}
do
    loop_id=`expr $loop_id + 1 `
    base_ip=`expr $base_ip + 1 `
    if `!(echo $(neutron net-list) | grep -w sriov_net$loop_id > /dev/null )`
    then
        neutron net-create --provider:physical_network=$pool --provider:network_type=vlan --provider:segmentation_id=0 sriov_net$loop_id
        neutron subnet-create --name sriov_sn$loop_id sriov_net$loop_id 10.10.$base_ip.0/24
        neutron port-create sriov_net$loop_id --name sriov_port$loop_id --vnic-type direct
    else
        echo "Port sriov_port"$loop_id" already exist"
    fi
    port_cmd="$port_cmd""--nic port-id=$(neutron port-list  --field={id,name} | awk -F\| '$3~"'sriov_port${loop_id}'" {print $2}' | sed 's/\s//g') "
done

#echo "$flavor_cmd"
#echo "$image_cmd"
#echo "$port_cmd"
#nova boot --flavor 8 --image sriov --nic port-id=$(neutron port-list  --field={id,name} | awk -F\| '$3~"sriov_port1" {print $2}' | sed 's/\s//g') \
#       --nic port-id=$(neutron port-list  --field={id,name} | awk -F\| '$3~"sriov_port2" {print $2}' | sed 's/\s//g') \
#       --availability-zone nova:compute-0-1.domain.tld \
#       sriov-vm1
vm_name="sriov-vm1"
nova_create_cmd="nova boot "$flavor_cmd$image_cmd$port_cmd"--availability-zone nova:compute-0-4.domain.tld "$vm_name
if `!(echo $(nova list) | grep -w $vm_name > /dev/null )`
then
    echo "$nova_create_cmd"
    eval "$nova_create_cmd"
else
    echo "VM already exist, Nothing to create!"
fi
