# Optimizing networking

The [OpenShift SDN](../networking/openshift_sdn/about-openshift-sdn/#about-openshift-sdn) uses OpenvSwitch, virtual extensible LAN (VXLAN) tunnels, OpenFlow rules, and iptables. This network can be tuned by using jumbo frames, network interface controllers (NIC) offloads, multi-queue, and ethtool settings.

[OVN-Kubernetes](../networking/ovn_kubernetes_network_provider/about-ovn-kubernetes/#about-ovn-kubernetes) uses Geneve (Generic Network Virtualization Encapsulation) instead of VXLAN as the tunnel protocol.

VXLAN provides benefits over VLANs, such as an increase in networks from 4096 to over 16 million, and layer 2 connectivity across physical networks. This allows for all pods behind a service to communicate with each other, even if they are running on different systems.

VXLAN encapsulates all tunneled traffic in user datagram protocol (UDP) packets. However, this leads to increased CPU utilization. Both these outer- and inner-packets are subject to normal checksumming rules to guarantee data is not corrupted during transit. Depending on CPU performance, this additional processing overhead can cause a reduction in throughput and increased latency when compared to traditional, non-overlay networks.

Cloud, VM, and bare metal CPU performance can be capable of handling much more than one Gbps network throughput. When using higher bandwidth links such as 10 or 40 Gbps, reduced performance can occur. This is a known issue in VXLAN-based environments and is not specific to containers or OpenShift Container Platform. Any network that relies on VXLAN tunnels will perform similarly because of the VXLAN implementation.

If you are looking to push beyond one Gbps, you can:

-   Evaluate network plug-ins that implement different routing techniques, such as border gateway protocol (BGP).

-   Use VXLAN-offload capable network adapters. VXLAN-offload moves the packet checksum calculation and associated CPU overhead off of the system CPU and onto dedicated hardware on the network adapter. This frees up CPU cycles for use by pods and applications, and allows users to utilize the full bandwidth of their network infrastructure.

VXLAN-offload does not reduce latency. However, CPU utilization is reduced even in latency tests.

## Optimizing the MTU for your network {#optimizing-mtu_optimizing-networking}

There are two important maximum transmission units (MTUs): the network interface controller (NIC) MTU and the cluster network MTU.

The NIC MTU is only configured at the time of OpenShift Container Platform installation. The MTU must be less than or equal to the maximum supported value of the NIC of your network. If you are optimizing for throughput, choose the largest possible value. If you are optimizing for lowest latency, choose a lower value.

The SDN overlay’s MTU must be less than the NIC MTU by 50 bytes at a minimum. This accounts for the SDN overlay header. So, on a normal ethernet network, set this to `1450`. On a jumbo frame ethernet network, set this to `8950`.

For OVN and Geneve, the MTU must be less than the NIC MTU by 100 bytes at a minimum.

!!! note
    This 50 byte overlay header is relevant to the OpenShift SDN. Other SDN solutions might require the value to be more or less.

## Recommended practices for installing large scale clusters {#recommended-install-practices_optimizing-networking}

When installing large clusters or scaling the cluster to larger node counts, set the cluster network `cidr` accordingly in your `install-config.yaml` file before you install the cluster:

``` yaml
networking:
  clusterNetwork:
  - cidr: 10.128.0.0/14
    hostPrefix: 23
  machineNetwork:
  - cidr: 10.0.0.0/16
  networkType: OpenShiftSDN
  serviceNetwork:
  - 172.30.0.0/16
```

The default cluster network `cidr` `10.128.0.0/14` cannot be used if the cluster size is more than 500 nodes. It must be set to `10.128.0.0/12` or `10.128.0.0/10` to get to larger node counts beyond 500 nodes.

## Impact of IPsec {#ipsec-impact_optimizing-networking}

Because encrypting and decrypting node hosts uses CPU power, performance is affected both in throughput and CPU usage on the nodes when encryption is enabled, regardless of the IP security system being used.

IPSec encrypts traffic at the IP payload level, before it hits the NIC, protecting fields that would otherwise be used for NIC offloading. This means that some NIC acceleration features might not be usable when IPSec is enabled and will lead to decreased throughput and increased CPU usage.

## Additional resources {#optimizing-networking-additional-resources}

-   [Modifying advanced network configuration parameters](../installing/installing_aws/installing-aws-network-customizations/#modifying-nwoperator-config-startup_installing-aws-network-customizations)

-   [Configuration parameters for the OVN-Kubernetes default CNI network provider](../networking/cluster-network-operator/#nw-operator-configuration-parameters-for-ovn-sdn_cluster-network-operator)

-   [Configuration parameters for the OpenShift SDN default CNI network provider](../networking/cluster-network-operator/#nw-operator-configuration-parameters-for-openshift-sdn_cluster-network-operator)

-   [Improving cluster stability in high latency environments using worker latency profiles](../scaling-worker-latency-profiles/#scaling-worker-latency-profiles)
