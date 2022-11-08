# Low latency tuning

## Understanding low latency

The emergence of Edge computing in the area of Telco / 5G plays a key role in reducing latency and congestion problems and improving application performance.

Simply put, latency determines how fast data (packets) moves from the sender to receiver and returns to the sender after processing by the receiver. Maintaining a network architecture with the lowest possible delay of latency speeds is key for meeting the network performance requirements of 5G. Compared to 4G technology, with an average latency of 50 ms, 5G is targeted to reach latency numbers of 1 ms or less. This reduction in latency boosts wireless throughput by a factor of 10.

Many of the deployed applications in the Telco space require low latency that can only tolerate zero packet loss. Tuning for zero packet loss helps mitigate the inherent issues that degrade network performance. For more information, see [Tuning for Zero Packet Loss in Red Hat OpenStack Platform (RHOSP)](https://www.redhat.com/en/blog/tuning-zero-packet-loss-red-hat-openstack-platform-part-1).

The Edge computing initiative also comes in to play for reducing latency rates. Think of it as being on the edge of the cloud and closer to the user. This greatly reduces the distance between the user and distant data centers, resulting in reduced application response times and performance latency.

Administrators must be able to manage their many Edge sites and local services in a centralized way so that all of the deployments can run at the lowest possible management cost. They also need an easy way to deploy and configure certain nodes of their cluster for real-time low latency and high-performance purposes. Low latency nodes are useful for applications such as Cloud-native Network Functions (CNF) and Data Plane Development Kit (DPDK).

OpenShift Container Platform currently provides mechanisms to tune software on an OpenShift Container Platform cluster for real-time running and low latency (around &lt;20 microseconds reaction time). This includes tuning the kernel and OpenShift Container Platform set values, installing a kernel, and reconfiguring the machine. But this method requires setting up four different Operators and performing many configurations that, when done manually, is complex and could be prone to mistakes.

OpenShift Container Platform uses the Node Tuning Operator to implement automatic tuning to achieve low latency performance for OpenShift Container Platform applications. The cluster administrator uses this performance profile configuration that makes it easier to make these changes in a more reliable way. The administrator can specify whether to update the kernel to kernel-rt, reserve CPUs for cluster and operating system housekeeping duties, including pod infra containers, and isolate CPUs for application containers to run the workloads.

OpenShift Container Platform also supports workload hints for the Node Tuning Operator that can tune the `PerformanceProfile` to meet the demands of different industry environments. Workload hints are available for `highPowerConsumption` (very low latency at the cost of increased power consumption) and `realTime` (priority given to optimum latency). A combination of `true/false` settings for these hints can be used to deal with application-specific workload profiles and requirements.

Workload hints simplify the fine-tuning of performance to industry sector settings. Instead of a “one size fits all” approach, workload hints can cater to usage patterns such as placing priority on:

-   Low latency

-   Real-time capability

-   Efficient use of power

In an ideal world, all of those would be prioritized: in real life, some come at the expense of others. The Node Tuning Operator is now aware of the workload expectations and better able to meet the demands of the workload. The cluster admin can now specify into which use case that workload falls. The Node Tuning Operator uses the `PerformanceProfile` to fine tune the performance settings for the workload.

The environment in which an application is operating influences its behavior. For a typical data center with no strict latency requirements, only minimal default tuning is needed that enables CPU partitioning for some high performance workload pods. For data centers and workloads where latency is a higher priority, measures are still taken to optimize power consumption. The most complicated cases are clusters close to latency-sensitive equipment such as manufacturing machinery and software-defined radios. This last class of deployment is often referred to as Far edge. For Far edge deployments, ultra-low latency is the ultimate priority, and is achieved at the expense of power management.

In OpenShift Container Platform version 4.10 and previous versions, the Performance Addon Operator was used to implement automatic tuning to achieve low latency performance. Now this functionality is part of the Node Tuning Operator.

### About hyperthreading for low latency and real-time applications

Hyperthreading is an Intel processor technology that allows a physical CPU processor core to function as two logical cores, executing two independent threads simultaneously. Hyperthreading allows for better system throughput for certain workload types where parallel processing is beneficial. The default OpenShift Container Platform configuration expects hyperthreading to be enabled by default.

For telecommunications applications, it is important to design your application infrastructure to minimize latency as much as possible. Hyperthreading can slow performance times and negatively affect throughput for compute intensive workloads that require low latency. Disabling hyperthreading ensures predictable performance and can decrease processing times for these workloads.

!!! note
    Hyperthreading implementation and configuration differs depending on the hardware you are running OpenShift Container Platform on. Consult the relevant host hardware tuning information for more details of the hyperthreading implementation specific to that hardware. Disabling hyperthreading can increase the cost per core of the cluster.

-   [Configuring hyperthreading for a cluster](../scalability_and_performance/cnf-low-latency-tuning.xml#configuring_hyperthreading_for_a_cluster_cnf-master)

Unresolved directive in cnf-performance-addon-operator-for-low-latency-nodes.adoc - include::modules/cnf-upgrading-performance-addon-operator.adoc\[leveloffset=+1\]

## Provisioning real-time and low latency workloads

Many industries and organizations need extremely high performance computing and might require low and predictable latency, especially in the financial and telecommunications industries. For these industries, with their unique requirements, OpenShift Container Platform provides the Node Tuning Operator to implement automatic tuning to achieve low latency performance and consistent response time for OpenShift Container Platform applications.

The cluster administrator can use this performance profile configuration to make these changes in a more reliable way. The administrator can specify whether to update the kernel to kernel-rt (real-time), reserve CPUs for cluster and operating system housekeeping duties, including pod infra containers, isolate CPUs for application containers to run the workloads, and disable unused CPUs to reduce power consumption.

!!! warning
    The usage of execution probes in conjunction with applications that require guaranteed CPUs can cause latency spikes. It is recommended to use other probes, such as a properly configured set of network probes, as an alternative.
!!! note
    In earlier versions of OpenShift Container Platform, the Performance Addon Operator was used to implement automatic tuning to achieve low latency performance for OpenShift applications. In OpenShift Container Platform 4.11 and later, these functions are part of the Node Tuning Operator.

### Known limitations for real-time

!!! note
    In most deployments, kernel-rt is supported only on worker nodes when you use a standard cluster with three control plane nodes and three worker nodes. There are exceptions for compact and single nodes on OpenShift Container Platform deployments. For installations on a single node, kernel-rt is supported on the single control plane node.

To fully utilize the real-time mode, the containers must run with elevated privileges. See [Set capabilities for a Container](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-capabilities-for-a-container) for information on granting privileges.

OpenShift Container Platform restricts the allowed capabilities, so you might need to create a `SecurityContext` as well.

!!! note
    This procedure is fully supported with bare metal installations using Red Hat Enterprise Linux CoreOS (RHCOS) systems.

Establishing the right performance expectations refers to the fact that the real-time kernel is not a panacea. Its objective is consistent, low-latency determinism offering predictable response times. There is some additional kernel overhead associated with the real-time kernel. This is due primarily to handling hardware interruptions in separately scheduled threads. The increased overhead in some workloads results in some degradation in overall throughput. The exact amount of degradation is very workload dependent, ranging from 0% to 30%. However, it is the cost of determinism.

### Provisioning a worker with real-time capabilities

1.  Optional: Add a node to the OpenShift Container Platform cluster. See [Setting BIOS parameters](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux_for_real_time/8/html-single/tuning_guide/index#Setting_BIOS_parameters).

2.  Add the label `worker-rt` to the worker nodes that require the real-time capability by using the `oc` command.

3.  Create a new machine config pool for real-time nodes:

    ``` yaml
    apiVersion: machineconfiguration.openshift.io/v1
    kind: MachineConfigPool
    metadata:
      name: worker-rt
      labels:
        machineconfiguration.openshift.io/role: worker-rt
    spec:
      machineConfigSelector:
        matchExpressions:
          - {
               key: machineconfiguration.openshift.io/role,
               operator: In,
               values: [worker, worker-rt],
            }
      paused: false
      nodeSelector:
        matchLabels:
          node-role.kubernetes.io/worker-rt: ""
    ```

    Note that a machine config pool worker-rt is created for group of nodes that have the label `worker-rt`.

4.  Add the node to the proper machine config pool by using node role labels.

    !!! note
        You must decide which nodes are configured with real-time workloads. You could configure all of the nodes in the cluster, or a subset of the nodes. The Node Tuning Operator that expects all of the nodes are part of a dedicated machine config pool. If you use all of the nodes, you must point the Node Tuning Operator to the worker node role label. If you use a subset, you must group the nodes into a new machine config pool.

5.  Create the `PerformanceProfile` with the proper set of housekeeping cores and `realTimeKernel: enabled: true`.

6.  You must set `machineConfigPoolSelector` in `PerformanceProfile`:

    ``` yaml
      apiVersion: performance.openshift.io/v2
      kind: PerformanceProfile
      metadata:
       name: example-performanceprofile
      spec:
      ...
        realTimeKernel:
          enabled: true
        nodeSelector:
           node-role.kubernetes.io/worker-rt: ""
        machineConfigPoolSelector:
           machineconfiguration.openshift.io/role: worker-rt
    ```

7.  Verify that a matching machine config pool exists with a label:

    ``` terminal
    $ oc describe mcp/worker-rt
    ```

    **Example output**

    ``` yaml
    Name:         worker-rt
    Namespace:
    Labels:       machineconfiguration.openshift.io/role=worker-rt
    ```

8.  OpenShift Container Platform will start configuring the nodes, which might involve multiple reboots. Wait for the nodes to settle. This can take a long time depending on the specific hardware you use, but 20 minutes per node is expected.

9.  Verify everything is working as expected.

### Verifying the real-time kernel installation

Use this command to verify that the real-time kernel is installed:

``` terminal
$ oc get node -o wide
```

Note the worker with the role `worker-rt` that contains the string `4.18.0-305.30.1.rt7.102.el8_4.x86_64 cri-o://1.25.0-99.rhaos4.10.gitc3131de.el8`:

``` terminal
NAME                                 STATUS   ROLES              AGE     VERSION                     INTERNAL-IP
EXTERNAL-IP   OS-IMAGE                                          KERNEL-VERSION
CONTAINER-RUNTIME
rt-worker-0.example.com           Ready  worker,worker-rt   5d17h   v1.25.0
128.66.135.107   <none>               Red Hat Enterprise Linux CoreOS 46.82.202008252340-0 (Ootpa)
4.18.0-305.30.1.rt7.102.el8_4.x86_64   cri-o://1.25.0-99.rhaos4.10.gitc3131de.el8
[...]
```

### Creating a workload that works in real-time

Use the following procedures for preparing a workload that will use real-time capabilities.

1.  Create a pod with a QoS class of `Guaranteed`.

2.  Optional: Disable CPU load balancing for DPDK.

3.  Assign a proper node selector.

When writing your applications, follow the general recommendations described in [Application tuning and deployment](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux_for_real_time/8/html-single/tuning_guide/index#chap-Application_Tuning_and_Deployment).

### Creating a pod with a QoS class of `Guaranteed`

Keep the following in mind when you create a pod that is given a QoS class of `Guaranteed`:

-   Every container in the pod must have a memory limit and a memory request, and they must be the same.

-   Every container in the pod must have a CPU limit and a CPU request, and they must be the same.

The following example shows the configuration file for a pod that has one container. The container has a memory limit and a memory request, both equal to 200 MiB. The container has a CPU limit and a CPU request, both equal to 1 CPU.

``` yaml
apiVersion: v1
kind: Pod
metadata:
  name: qos-demo
  namespace: qos-example
spec:
  containers:
  - name: qos-demo-ctr
    image: <image-pull-spec>
    resources:
      limits:
        memory: "200Mi"
        cpu: "1"
      requests:
        memory: "200Mi"
        cpu: "1"
```

1.  Create the pod:

    ``` terminal
    $ oc  apply -f qos-pod.yaml --namespace=qos-example
    ```

2.  View detailed information about the pod:

    ``` terminal
    $ oc get pod qos-demo --namespace=qos-example --output=yaml
    ```

    **Example output**

    ``` yaml
    spec:
      containers:
        ...
    status:
      qosClass: Guaranteed
    ```

    !!! note
        If a container specifies its own memory limit, but does not specify a memory request, OpenShift Container Platform automatically assigns a memory request that matches the limit. Similarly, if a container specifies its own CPU limit, but does not specify a CPU request, OpenShift Container Platform automatically assigns a CPU request that matches the limit.

### Optional: Disabling CPU load balancing for DPDK

Functionality to disable or enable CPU load balancing is implemented on the CRI-O level. The code under the CRI-O disables or enables CPU load balancing only when the following requirements are met.

-   The pod must use the `performance-<profile-name>` runtime class. You can get the proper name by looking at the status of the performance profile, as shown here:

    ``` yaml
    apiVersion: performance.openshift.io/v2
    kind: PerformanceProfile
    ...
    status:
      ...
      runtimeClass: performance-manual
    ```

The Node Tuning Operator is responsible for the creation of the high-performance runtime handler config snippet under relevant nodes and for creation of the high-performance runtime class under the cluster. It will have the same content as default runtime handler except it enables the CPU load balancing configuration functionality.

To disable the CPU load balancing for the pod, the `Pod` specification must include the following fields:

``` yaml
apiVersion: v1
kind: Pod
metadata:
  ...
  annotations:
    ...
    cpu-load-balancing.crio.io: "disable"
    ...
  ...
spec:
  ...
  runtimeClassName: performance-<profile_name>
  ...
```

!!! note
    Only disable CPU load balancing when the CPU manager static policy is enabled and for pods with guaranteed QoS that use whole CPUs. Otherwise, disabling CPU load balancing can affect the performance of other containers in the cluster.

### Assigning a proper node selector

The preferred way to assign a pod to nodes is to use the same node selector the performance profile used, as shown here:

``` yaml
apiVersion: v1
kind: Pod
metadata:
  name: example
spec:
  # ...
  nodeSelector:
    node-role.kubernetes.io/worker-rt: ""
```

For more information, see [Placing pods on specific nodes using node selectors](https://access.redhat.com/documentation/en-us/openshift_container_platform/4.5/html-single/nodes/index#nodes-scheduler-node-selectors).

### Scheduling a workload onto a worker with real-time capabilities

Use label selectors that match the nodes attached to the machine config pool that was configured for low latency by the Node Tuning Operator. For more information, see [Assigning pods to nodes](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/).

### Reducing power consumption by taking CPUs offline

You can generally anticipate telecommunication workloads. When not all of the CPU resources are required, the Node Tuning Operator allows you take unused CPUs offline to reduce power consumption by manually updating the performance profile.

To take unused CPUs offline, you must perform the following tasks:

1.  Set the offline CPUs in the performance profile and save the contents of the YAML file:

    **Example performance profile with offlined CPUs**

    ``` yaml
    apiVersion: performance.openshift.io/v2
    kind: PerformanceProfile
    metadata:
      name: performance
    spec:
      additionalKernelArgs:
      - nmi_watchdog=0
      - audit=0
      - mce=off
      - processor.max_cstate=1
      - intel_idle.max_cstate=0
      - idle=poll
      cpu:
        isolated: "2-23,26-47"
        reserved: "0,1,24,25"
        offlined: “48-59” 
      nodeSelector:
        node-role.kubernetes.io/worker-cnf: ""
      numa:
        topologyPolicy: single-numa-node
      realTimeKernel:
        enabled: true
    ```

    -   Optional. You can list CPUs in the `offlined` field to take the specified CPUs offline.

2.  Apply the updated profile by running the following command:

    ``` terminal
    $ oc apply -f my-performance-profile.yaml
    ```

### Optional: Power saving configurations

You can enable power savings for a node that has low priority workloads that are colocated with high priority workloads without impacting the latency or throughput of the high priority workloads. Power saving is possible without modifications to the workloads themselves.

!!! important
    The feature is supported on Intel Ice Lake and later generations of Intel CPUs. The capabilities of the processor might impact the latency and throughput of the high priority workloads.

When you configure a node with a power saving configuration, you must configure high priority workloads with performance configuration at the pod level, which means that the configuration applies to all the cores used by the pod.

By disabling P-states and C-states at the pod level, you can configure high priority workloads for best performance and lowest latency.

+-------------------------------------------+----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| Annotation                                | Description                                                                                                                                                                            |
+===========================================+========================================================================================================================================================================================+
| ``` yaml                                  | Provides the best performance for a pod by disabling C-states and specifying the governor type for CPU scaling. The `performance` governor is recommended for high priority workloads. |
| annotations:                              |                                                                                                                                                                                        |
|   cpu-c-states.crio.io: "enable"          |                                                                                                                                                                                        |
|   cpu-freq-governor.crio.io: "<governor>" |                                                                                                                                                                                        |
| ```                                       |                                                                                                                                                                                        |
+-------------------------------------------+----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+

**Table 1: Power saving configurations**

-   You enabled C-states and OS-controlled P-states in the BIOS

1.  Generate a `PerformanceProfile` with `per-pod-power-management` set to `true`:

    ``` terminal
    $ podman run --entrypoint performance-profile-creator -v \
    /must-gather:/must-gather:z registry.redhat.io/openshift4/performance-addon-rhel8-operator:v4.11 \
    --mcp-name=worker-cnf --reserved-cpu-count=20 --rt-kernel=true \
    --split-reserved-cpus-across-numa=false --topology-manager-policy=single-numa-node \
    --must-gather-dir-path /must-gather -power-consumption-mode=low-latency \ 
    --per-pod-power-management=true > my-performance-profile.yaml
    ```

    -   The `power-consumption-mode` must be `default` or `low-latency` when the `per-pod-power-management` is set to `true`.

    **Example `PerformanceProfile` with `perPodPowerManagement`**

    ``` yaml
    apiVersion: performance.openshift.io/v2
    kind: PerformanceProfile
    metadata:
         name: performance
    spec:
        [.....]
        workloadHints:
            realTime: true
            highPowerConsumption: false
            perPodPowerManagement: true
    ```

2.  Set the default `cpufreq` governor as an additional kernel argument in the `PerformanceProfile` custom resource (CR):

    ``` yaml
    apiVersion: performance.openshift.io/v2
    kind: PerformanceProfile
    metadata:
         name: performance
    spec:
        ...
        additionalKernelArgs:
        - cpufreq.default_governor=schedutil 
    ```

    -   Using the `schedutil` governor is recommended, however, you can use other governors such as the `ondemand` or `powersave` governors.

3.  Set the maximum CPU frequency in the `TunedPerformancePatch` CR:

    ``` yaml
    spec:
      profile:
      - data: |
          [sysfs]
          /sys/devices/system/cpu/intel_pstate/max_perf_pct = <x> 
    ```

    -   The `max_perf_pct` controls the maximum frequency the `cpufreq` driver is allowed to set as a percentage of the maximum supported cpu frequency. This value applies to all CPUs. You can check the maximum supported frequency in `/sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq`.

4.  Add the desired annotations to your pods. The annotations override the `default` settings.

    **Example power saving annotation**

    ``` yaml
    apiVersion: v1
    kind: Pod
    metadata:
      ...
      annotations:
        ...
        cpu-c-states.crio.io: "enable"
        cpu-freq-governor.crio.io: "<governor>"
        ...
      ...
    spec:
      ...
      runtimeClassName: performance-<profile_name>
      ...
    ```

5.  Restart the pods.

### Managing device interrupt processing for guaranteed pod isolated CPUs

The Node Tuning Operator can manage host CPUs by dividing them into reserved CPUs for cluster and operating system housekeeping duties, including pod infra containers, and isolated CPUs for application containers to run the workloads. This allows you to set CPUs for low latency workloads as isolated.

Device interrupts are load balanced between all isolated and reserved CPUs to avoid CPUs being overloaded, with the exception of CPUs where there is a guaranteed pod running. Guaranteed pod CPUs are prevented from processing device interrupts when the relevant annotations are set for the pod.

In the performance profile, `globallyDisableIrqLoadBalancing` is used to manage whether device interrupts are processed or not. For certain workloads, the reserved CPUs are not always sufficient for dealing with device interrupts, and for this reason, device interrupts are not globally disabled on the isolated CPUs. By default, Node Tuning Operator does not disable device interrupts on isolated CPUs.

To achieve low latency for workloads, some (but not all) pods require the CPUs they are running on to not process device interrupts. A pod annotation, `irq-load-balancing.crio.io`, is used to define whether device interrupts are processed or not. When configured, CRI-O disables device interrupts only as long as the pod is running.

#### Disabling CPU CFS quota

To reduce CPU throttling for individual guaranteed pods, create a pod specification with the annotation `cpu-quota.crio.io: "disable"`. This annotation disables the CPU completely fair scheduler (CFS) quota at the pod run time. The following pod specification contains this annotation:

``` yaml
apiVersion: performance.openshift.io/v2
kind: Pod
metadata:
  annotations:
      cpu-quota.crio.io: "disable"
spec:
    runtimeClassName: performance-<profile_name>
...
```

!!! note
    Only disable CPU CFS quota when the CPU manager static policy is enabled and for pods with guaranteed QoS that use whole CPUs. Otherwise, disabling CPU CFS quota can affect the performance of other containers in the cluster.

#### Disabling global device interrupts handling in Node Tuning Operator

To configure Node Tuning Operator to disable global device interrupts for the isolated CPU set, set the `globallyDisableIrqLoadBalancing` field in the performance profile to `true`. When `true`, conflicting pod annotations are ignored. When `false`, IRQ loads are balanced across all CPUs.

A performance profile snippet illustrates this setting:

``` yaml
apiVersion: performance.openshift.io/v2
kind: PerformanceProfile
metadata:
  name: manual
spec:
  globallyDisableIrqLoadBalancing: true
...
```

#### Disabling interrupt processing for individual pods

To disable interrupt processing for individual pods, ensure that `globallyDisableIrqLoadBalancing` is set to `false` in the performance profile. Then, in the pod specification, set the `irq-load-balancing.crio.io` pod annotation to `disable`. The following pod specification contains this annotation:

``` yaml
apiVersion: performance.openshift.io/v2
kind: Pod
metadata:
  annotations:
      irq-load-balancing.crio.io: "disable"
spec:
    runtimeClassName: performance-<profile_name>
...
```

### Upgrading the performance profile to use device interrupt processing

When you upgrade the Node Tuning Operator performance profile custom resource definition (CRD) from v1 or v1alpha1 to v2, `globallyDisableIrqLoadBalancing` is set to `true` on existing profiles.

!!! note
    `globallyDisableIrqLoadBalancing` toggles whether IRQ load balancing will be disabled for the Isolated CPU set. When the option is set to `true` it disables IRQ load balancing for the Isolated CPU set. Setting the option to `false` allows the IRQs to be balanced across all CPUs.

#### Supported API Versions

The Node Tuning Operator supports `v2`, `v1`, and `v1alpha1` for the performance profile `apiVersion` field. The v1 and v1alpha1 APIs are identical. The v2 API includes an optional boolean field `globallyDisableIrqLoadBalancing` with a default value of `false`.

##### Upgrading Node Tuning Operator API from v1alpha1 to v1

When upgrading Node Tuning Operator API version from v1alpha1 to v1, the v1alpha1 performance profiles are converted on-the-fly using a "None" Conversion strategy and served to the Node Tuning Operator with API version v1.

##### Upgrading Node Tuning Operator API from v1alpha1 or v1 to v2

When upgrading from an older Node Tuning Operator API version, the existing v1 and v1alpha1 performance profiles are converted using a conversion webhook that injects the `globallyDisableIrqLoadBalancing` field with a value of `true`.

## Tuning nodes for low latency with the performance profile

The performance profile lets you control latency tuning aspects of nodes that belong to a certain machine config pool. After you specify your settings, the `PerformanceProfile` object is compiled into multiple objects that perform the actual node level tuning:

-   A `MachineConfig` file that manipulates the nodes.

-   A `KubeletConfig` file that configures the Topology Manager, the CPU Manager, and the OpenShift Container Platform nodes.

-   The Tuned profile that configures the Node Tuning Operator.

You can use a performance profile to specify whether to update the kernel to kernel-rt, to allocate huge pages, and to partition the CPUs for performing housekeeping duties or running workloads.

!!! note
    You can manually create the `PerformanceProfile` object or use the Performance Profile Creator (PPC) to generate a performance profile. See the additional resources below for more information on the PPC.

**Sample performance profile**

``` yaml
apiVersion: performance.openshift.io/v2
kind: PerformanceProfile
metadata:
 name: performance
spec:
 cpu:
  isolated: "5-15" 
  reserved: "0-4" 
 hugepages:
  defaultHugepagesSize: "1G"
  pages:
  - size: "1G"
    count: 16
    node: 0
 realTimeKernel:
  enabled: true  
 numa:  
  topologyPolicy: "best-effort"
 nodeSelector:
  node-role.kubernetes.io/worker-cnf: "" 
```

-   Use this field to isolate specific CPUs to use with application containers for workloads.

-   Use this field to reserve specific CPUs to use with infra containers for housekeeping.

-   Use this field to install the real-time kernel on the node. Valid values are `true` or `false`. Setting the `true` value installs the real-time kernel.

-   Use this field to configure the topology manager policy. Valid values are `none` (default), `best-effort`, `restricted`, and `single-numa-node`. For more information, see [Topology Manager Policies](https://kubernetes.io/docs/tasks/administer-cluster/topology-manager/#topology-manager-policies).

-   Use this field to specify a node selector to apply the performance profile to specific nodes.

<!-- -->

-   For information on using the Performance Profile Creator (PPC) to generate a performance profile, see [Creating a performance profile](../scalability_and_performance/cnf-create-performance-profiles.xml#cnf-create-performance-profiles).

### Configuring huge pages

Nodes must pre-allocate huge pages used in an OpenShift Container Platform cluster. Use the Node Tuning Operator to allocate huge pages on a specific node.

OpenShift Container Platform provides a method for creating and allocating huge pages. Node Tuning Operator provides an easier method for doing this using the performance profile.

For example, in the `hugepages` `pages` section of the performance profile, you can specify multiple blocks of `size`, `count`, and, optionally, `node`:

``` yaml
hugepages:
   defaultHugepagesSize: "1G"
   pages:
   - size:  "1G"
     count:  4
     node:  0 
```

-   `node` is the NUMA node in which the huge pages are allocated. If you omit `node`, the pages are evenly spread across all NUMA nodes.

!!! note
    Wait for the relevant machine config pool status that indicates the update is finished.

These are the only configuration steps you need to do to allocate huge pages.

-   To verify the configuration, see the `/proc/meminfo` file on the node:

    ``` terminal
    $ oc debug node/ip-10-0-141-105.ec2.internal
    ```

    ``` terminal
    # grep -i huge /proc/meminfo
    ```

    **Example output**

    ``` terminal
    AnonHugePages:    ###### ##
    ShmemHugePages:        0 kB
    HugePages_Total:       2
    HugePages_Free:        2
    HugePages_Rsvd:        0
    HugePages_Surp:        0
    Hugepagesize:       #### ##
    Hugetlb:            #### ##
    ```

-   Use `oc describe` to report the new size:

    ``` terminal
    $ oc describe node worker-0.ocp4poc.example.com | grep -i huge
    ```

    **Example output**

    ``` terminal
                                       hugepages-1g=true
     hugepages-###:  ###
     hugepages-###:  ###
    ```

### Allocating multiple huge page sizes

You can request huge pages with different sizes under the same container. This allows you to define more complicated pods consisting of containers with different huge page size needs.

For example, you can define sizes `1G` and `2M` and the Node Tuning Operator will configure both sizes on the node, as shown here:

``` yaml
spec:
  hugepages:
    defaultHugepagesSize: 1G
    pages:
    - count: 1024
      node: 0
      size: 2M
    - count: 4
      node: 1
      size: 1G
```

### Configuring a node for IRQ dynamic load balancing

To configure a cluster node to handle IRQ dynamic load balancing, do the following:

1.  Log in to the OpenShift Container Platform cluster as a user with cluster-admin privileges.

2.  Set the performance profile `apiVersion` to use `performance.openshift.io/v2`.

3.  Remove the `globallyDisableIrqLoadBalancing` field or set it to `false`.

4.  Set the appropriate isolated and reserved CPUs. The following snippet illustrates a profile that reserves 2 CPUs. IRQ load-balancing is enabled for pods running on the `isolated` CPU set:

    ``` yaml
    apiVersion: performance.openshift.io/v2
    kind: PerformanceProfile
    metadata:
      name: dynamic-irq-profile
    spec:
      cpu:
        isolated: 2-5
        reserved: 0-1
    ...
    ```

    !!! note
        When you configure reserved and isolated CPUs, the infra containers in pods use the reserved CPUs and the application containers use the isolated CPUs.

5.  Create the pod that uses exclusive CPUs, and set `irq-load-balancing.crio.io` and `cpu-quota.crio.io` annotations to `disable`. For example:

    ``` yaml
    apiVersion: v1
    kind: Pod
    metadata:
      name: dynamic-irq-pod
      annotations:
         irq-load-balancing.crio.io: "disable"
         cpu-quota.crio.io: "disable"
    spec:
      containers:
      - name: dynamic-irq-pod
        image: "registry.redhat.io/openshift4/cnf-tests-rhel8:v4.11"
        command: ["sleep", "10h"]
        resources:
          requests:
            cpu: 2
            memory: "200M"
          limits:
            cpu: 2
            memory: "200M"
      nodeSelector:
        node-role.kubernetes.io/worker-cnf: ""
      runtimeClassName: performance-dynamic-irq-profile
    ...
    ```

6.  Enter the pod `runtimeClassName` in the form performance-&lt;profile\_name&gt;, where &lt;profile\_name&gt; is the `name` from the `PerformanceProfile` YAML, in this example, `performance-dynamic-irq-profile`.

7.  Set the node selector to target a cnf-worker.

8.  Ensure the pod is running correctly. Status should be `running`, and the correct cnf-worker node should be set:

    ``` terminal
    $ oc get pod -o wide
    ```

    **Expected output**

    ``` terminal
    NAME              READY   STATUS    RESTARTS   AGE     IP             NODE          NOMINATED NODE   READINESS GATES
    dynamic-irq-pod   1/1     Running   0          5h33m   <ip-address>   <node-name>   <none>           <none>
    ```

9.  Get the CPUs that the pod configured for IRQ dynamic load balancing runs on:

    ``` terminal
    $ oc exec -it dynamic-irq-pod -- /bin/bash -c "grep Cpus_allowed_list /proc/self/status | awk '{print $2}'"
    ```

    **Expected output**

    ``` terminal
    Cpus_allowed_list:  2-3
    ```

10. Ensure the node configuration is applied correctly. SSH into the node to verify the configuration.

    ``` terminal
    $ oc debug node/<node-name>
    ```

    **Expected output**

    ``` terminal
    Starting pod/<node-name>-debug ...
    To use host binaries, run `chroot /host`

    Pod IP: <ip-address>
    If you don't see a command prompt, try pressing enter.

    sh-4.4#
    ```

11. Verify that you can use the node file system:

    ``` terminal
    sh-4.4# chroot /host
    ```

    **Expected output**

    ``` terminal
    sh-4.4#
    ```

12. Ensure the default system CPU affinity mask does not include the `dynamic-irq-pod` CPUs, for example, CPUs 2 and 3.

    ``` terminal
    $ cat /proc/irq/default_smp_affinity
    ```

    **Example output**

    ``` terminal
    33
    ```

13. Ensure the system IRQs are not configured to run on the `dynamic-irq-pod` CPUs:

    ``` terminal
    find /proc/irq/ -name smp_affinity_list -exec sh -c 'i="$1"; mask=$(cat $i); file=$(echo $i); echo $file: $mask' _ {} \;
    ```

    **Example output**

    ``` terminal
    /proc/irq/0/smp_affinity_list: 0-5
    /proc/irq/1/smp_affinity_list: 5
    /proc/irq/2/smp_affinity_list: 0-5
    /proc/irq/3/smp_affinity_list: 0-5
    /proc/irq/4/smp_affinity_list: 0
    /proc/irq/5/smp_affinity_list: 0-5
    /proc/irq/6/smp_affinity_list: 0-5
    /proc/irq/7/smp_affinity_list: 0-5
    /proc/irq/8/smp_affinity_list: 4
    /proc/irq/9/smp_affinity_list: 4
    /proc/irq/10/smp_affinity_list: 0-5
    /proc/irq/11/smp_affinity_list: 0
    /proc/irq/12/smp_affinity_list: 1
    /proc/irq/13/smp_affinity_list: 0-5
    /proc/irq/14/smp_affinity_list: 1
    /proc/irq/15/smp_affinity_list: 0
    /proc/irq/24/smp_affinity_list: 1
    /proc/irq/25/smp_affinity_list: 1
    /proc/irq/26/smp_affinity_list: 1
    /proc/irq/27/smp_affinity_list: 5
    /proc/irq/28/smp_affinity_list: 1
    /proc/irq/29/smp_affinity_list: 0
    /proc/irq/30/smp_affinity_list: 0-5
    ```

Some IRQ controllers do not support IRQ re-balancing and will always expose all online CPUs as the IRQ mask. These IRQ controllers effectively run on CPU 0. For more information on the host configuration, SSH into the host and run the following, replacing `<irq-num>` with the CPU number that you want to query:

``` terminal
$ cat /proc/irq/<irq-num>/effective_affinity
```

### Configuring hyperthreading for a cluster

To configure hyperthreading for an OpenShift Container Platform cluster, set the CPU threads in the performance profile to the same cores that are configured for the reserved or isolated CPU pools.

!!! note
    If you configure a performance profile, and subsequently change the hyperthreading configuration for the host, ensure that you update the CPU `isolated` and `reserved` fields in the `PerformanceProfile` YAML to match the new configuration.
!!! warning
    Disabling a previously enabled host hyperthreading configuration can cause the CPU core IDs listed in the `PerformanceProfile` YAML to be incorrect. This incorrect configuration can cause the node to become unavailable because the listed CPUs can no longer be found.

-   Access to the cluster as a user with the `cluster-admin` role.

-   Install the OpenShift CLI (oc).

1.  Ascertain which threads are running on what CPUs for the host you want to configure.

    You can view which threads are running on the host CPUs by logging in to the cluster and running the following command:

    ``` terminal
    $ lscpu --all --extended
    ```

    **Example output**

    ``` terminal
    CPU NODE SOCKET CORE L1d:L1i:L2:L3 ONLINE MAXMHZ    MINMHZ
    0   0    0      0    0:0:0:0       yes    4800.0000 400.0000
    1   0    0      1    1:1:1:0       yes    4800.0000 400.0000
    2   0    0      2    2:2:2:0       yes    4800.0000 400.0000
    3   0    0      3    3:3:3:0       yes    4800.0000 400.0000
    4   0    0      0    0:0:0:0       yes    4800.0000 400.0000
    5   0    0      1    1:1:1:0       yes    4800.0000 400.0000
    6   0    0      2    2:2:2:0       yes    4800.0000 400.0000
    7   0    0      3    3:3:3:0       yes    4800.0000 400.0000
    ```

    In this example, there are eight logical CPU cores running on four physical CPU cores. CPU0 and CPU4 are running on physical Core0, CPU1 and CPU5 are running on physical Core 1, and so on.

    Alternatively, to view the threads that are set for a particular physical CPU core (`cpu0` in the example below), open a command prompt and run the following:

    ``` terminal
    $ cat /sys/devices/system/cpu/cpu0/topology/thread_siblings_list
    ```

    **Example output**

    ``` terminal
    0-4
    ```

2.  Apply the isolated and reserved CPUs in the `PerformanceProfile` YAML. For example, you can set logical cores CPU0 and CPU4 as `isolated`, and logical cores CPU1 to CPU3 and CPU5 to CPU7 as `reserved`. When you configure reserved and isolated CPUs, the infra containers in pods use the reserved CPUs and the application containers use the isolated CPUs.

    ``` yaml
    ...
      cpu:
        isolated: 0,4
        reserved: 1-3,5-7
    ...
    ```

    !!! note
        The reserved and isolated CPU pools must not overlap and together must span all available cores in the worker node.

!!! important
    Hyperthreading is enabled by default on most Intel processors. If you enable hyperthreading, all threads processed by a particular core must be isolated or processed on the same core.

#### Disabling hyperthreading for low latency applications

When configuring clusters for low latency processing, consider whether you want to disable hyperthreading before you deploy the cluster. To disable hyperthreading, do the following:

1.  Create a performance profile that is appropriate for your hardware and topology.

2.  Set `nosmt` as an additional kernel argument. The following example performance profile illustrates this setting:

    ``` yaml
    ﻿apiVersion: performance.openshift.io/v2
    kind: PerformanceProfile
    metadata:
      name: example-performanceprofile
    spec:
      additionalKernelArgs:
        - nmi_watchdog=0
        - audit=0
        - mce=off
        - processor.max_cstate=1
        - idle=poll
        - intel_idle.max_cstate=0
        - nosmt
      cpu:
        isolated: 2-3
        reserved: 0-1
      hugepages:
        defaultHugepagesSize: 1G
        pages:
          - count: 2
            node: 0
            size: 1G
      nodeSelector:
        node-role.kubernetes.io/performance: ''
      realTimeKernel:
        enabled: true
    ```

    !!! note
        When you configure reserved and isolated CPUs, the infra containers in pods use the reserved CPUs and the application containers use the isolated CPUs.

### Understanding workload hints

The following table describes how combinations of power consumption and real-time settings impact on latency.

!!! note
    The following workload hints can be configured manually. You can also work with workload hints using the Performance Profile Creator. For more information about the performance profile, see the \"Creating a performance profile\" section.

+-------------------------------------+-----------------------------+------------------------------------------------------+-----------------------------------------------------------------------------------------------------------------+
| Performance Profile creator setting | Hint                        | Environment                                          | Description                                                                                                     |
+=====================================+=============================+======================================================+=================================================================================================================+
| Default                             | ``` terminal                | High throughput cluster without latency requirements | Performance achieved through CPU partitioning only.                                                             |
|                                     | workloadHints:              |                                                      |                                                                                                                 |
|                                     | highPowerConsumption: false |                                                      |                                                                                                                 |
|                                     | realTime: false             |                                                      |                                                                                                                 |
|                                     | ```                         |                                                      |                                                                                                                 |
+-------------------------------------+-----------------------------+------------------------------------------------------+-----------------------------------------------------------------------------------------------------------------+
| Low-latency                         | ``` terminal                | Regional datacenters                                 | Both energy savings and low-latency are desirable: compromise between power management, latency and throughput. |
|                                     | workloadHints:              |                                                      |                                                                                                                 |
|                                     | highPowerConsumption: false |                                                      |                                                                                                                 |
|                                     | realTime: true              |                                                      |                                                                                                                 |
|                                     | ```                         |                                                      |                                                                                                                 |
+-------------------------------------+-----------------------------+------------------------------------------------------+-----------------------------------------------------------------------------------------------------------------+
| Ultra-low-latency                   | ``` terminal                | Far edge clusters, latency critical workloads        | Optimized for absolute minimal latency and maximum determinism at the cost of increased power consumption.      |
|                                     | workloadHints:              |                                                      |                                                                                                                 |
|                                     | highPowerConsumption: true  |                                                      |                                                                                                                 |
|                                     | realTime: true              |                                                      |                                                                                                                 |
|                                     | ```                         |                                                      |                                                                                                                 |
+-------------------------------------+-----------------------------+------------------------------------------------------+-----------------------------------------------------------------------------------------------------------------+
| Per-pod power management            | ``` terminal                | Critical and non-critical workloads                  | Allows for power management per pod.                                                                            |
|                                     | workloadHints:              |                                                      |                                                                                                                 |
|                                     | realTime: true              |                                                      |                                                                                                                 |
|                                     | highPowerConsumption: false |                                                      |                                                                                                                 |
|                                     | perPodPowerManagement: true |                                                      |                                                                                                                 |
|                                     | ```                         |                                                      |                                                                                                                 |
+-------------------------------------+-----------------------------+------------------------------------------------------+-----------------------------------------------------------------------------------------------------------------+

**Table 2**

### Configuring workload hints manually

1.  Create a `PerformanceProfile` appropriate for the environment’s hardware and topology as described in the table in "Understanding workload hints". Adjust the profile to match the expected workload. In this example, we tune for the lowest possible latency.

2.  Add the `highPowerConsumption` and `realTime` workload hints. Both are set to `true` here.

    ``` yaml
        apiVersion: performance.openshift.io/v2
        kind: PerformanceProfile
        metadata:
          name: workload-hints
        spec:
          ...
          workloadHints:
            highPowerConsumption: true 
            realTime: true 
    ```

    -   If `highPowerConsumption` is `true`, the node is tuned for very low latency at the cost of increased power consumption.

    -   Disables some debugging and monitoring features that can affect system latency.

-   For information on using the Performance Profile Creator (PPC) to generate a performance profile, see [Creating a performance profile](../scalability_and_performance/cnf-create-performance-profiles.xml#cnf-create-performance-profiles).

### Restricting CPUs for infra and application containers

Generic housekeeping and workload tasks use CPUs in a way that may impact latency-sensitive processes. By default, the container runtime uses all online CPUs to run all containers together, which can result in context switches and spikes in latency. Partitioning the CPUs prevents noisy processes from interfering with latency-sensitive processes by separating them from each other. The following table describes how processes run on a CPU after you have tuned the node using the Node Tuning Operator:

+-----------------------------------+-------------------------------------------------------------------------------------+
| Process type                      | Details                                                                             |
+===================================+=====================================================================================+
| `Burstable` and `BestEffort` pods | Runs on any CPU except where low latency workload is running                        |
+-----------------------------------+-------------------------------------------------------------------------------------+
| Infrastructure pods               | Runs on any CPU except where low latency workload is running                        |
+-----------------------------------+-------------------------------------------------------------------------------------+
| Interrupts                        | Redirects to reserved CPUs (optional in OpenShift Container Platform 4.7 and later) |
+-----------------------------------+-------------------------------------------------------------------------------------+
| Kernel processes                  | Pins to reserved CPUs                                                               |
+-----------------------------------+-------------------------------------------------------------------------------------+
| Latency-sensitive workload pods   | Pins to a specific set of exclusive CPUs from the isolated pool                     |
+-----------------------------------+-------------------------------------------------------------------------------------+
| OS processes/systemd services     | Pins to reserved CPUs                                                               |
+-----------------------------------+-------------------------------------------------------------------------------------+

**Table 3: Process' CPU assignments**

The allocatable capacity of cores on a node for pods of all QoS process types, `Burstable`, `BestEffort`, or `Guaranteed`, is equal to the capacity of the isolated pool. The capacity of the reserved pool is removed from the node’s total core capacity for use by the cluster and operating system housekeeping duties.

**Example 1**

A node features a capacity of 100 cores. Using a performance profile, the cluster administrator allocates 50 cores to the isolated pool and 50 cores to the reserved pool. The cluster administrator assigns 25 cores to QoS `Guaranteed` pods and 25 cores for `BestEffort` or `Burstable` pods. This matches the capacity of the isolated pool.

**Example 2**

A node features a capacity of 100 cores. Using a performance profile, the cluster administrator allocates 50 cores to the isolated pool and 50 cores to the reserved pool. The cluster administrator assigns 50 cores to QoS `Guaranteed` pods and one core for `BestEffort` or `Burstable` pods. This exceeds the capacity of the isolated pool by one core. Pod scheduling fails because of insufficient CPU capacity.

The exact partitioning pattern to use depends on many factors like hardware, workload characteristics and the expected system load. Some sample use cases are as follows:

-   If the latency-sensitive workload uses specific hardware, such as a network interface controller (NIC), ensure that the CPUs in the isolated pool are as close as possible to this hardware. At a minimum, you should place the workload in the same Non-Uniform Memory Access (NUMA) node.

-   The reserved pool is used for handling all interrupts. When depending on system networking, allocate a sufficiently-sized reserve pool to handle all the incoming packet interrupts. In 4.11 and later versions, workloads can optionally be labeled as sensitive.

The decision regarding which specific CPUs should be used for reserved and isolated partitions requires detailed analysis and measurements. Factors like NUMA affinity of devices and memory play a role. The selection also depends on the workload architecture and the specific use case.

!!! important
    The reserved and isolated CPU pools must not overlap and together must span all available cores in the worker node.

To ensure that housekeeping tasks and workloads do not interfere with each other, specify two groups of CPUs in the `spec` section of the performance profile.

-   `isolated` - Specifies the CPUs for the application container workloads. These CPUs have the lowest latency. Processes in this group have no interruptions and can, for example, reach much higher DPDK zero packet loss bandwidth.

-   `reserved` - Specifies the CPUs for the cluster and operating system housekeeping duties. Threads in the `reserved` group are often busy. Do not run latency-sensitive applications in the `reserved` group. Latency-sensitive applications run in the `isolated` group.

1.  Create a performance profile appropriate for the environment’s hardware and topology.

2.  Add the `reserved` and `isolated` parameters with the CPUs you want reserved and isolated for the infra and application containers:

    ``` yaml
    ﻿apiVersion: performance.openshift.io/v2
    kind: PerformanceProfile
    metadata:
      name: infra-cpus
    spec:
      cpu:
        reserved: "0-4,9" 
        isolated: "5-8" 
      nodeSelector: 
        node-role.kubernetes.io/worker: ""
    ```

    -   Specify which CPUs are for infra containers to perform cluster and operating system housekeeping duties.

    -   Specify which CPUs are for application containers to run workloads.

    -   Optional: Specify a node selector to apply the performance profile to specific nodes.

-   [Managing device interrupt processing for guaranteed pod isolated CPUs](../scalability_and_performance/cnf-low-latency-tuning.xml#managing-device-interrupt-processing-for-guaranteed-pod-isolated-cpus_cnf-master)

-   [Create a pod that gets assigned a QoS class of Guaranteed](https://kubernetes.io/docs/tasks/configure-pod-container/quality-service-pod/#create-a-pod-that-gets-assigned-a-qos-class-of-guaranteed)

Unresolved directive in cnf-performance-addon-operator-for-low-latency-nodes.adoc - include::modules/cnf-reducing-netqueues-using-pao.adoc\[leveloffset=+1\]

### Adjusting the NIC queues with the performance profile

The performance profile lets you adjust the queue count for each network device.

Supported network devices:

-   Non-virtual network devices

-   Network devices that support multiple queues (channels)

Unsupported network devices:

-   Pure software network interfaces

-   Block devices

-   Intel DPDK virtual functions

<!-- -->

-   Access to the cluster as a user with the `cluster-admin` role.

-   Install the OpenShift CLI (`oc`).

1.  Log in to the OpenShift Container Platform cluster running the Node Tuning Operator as a user with `cluster-admin` privileges.

2.  Create and apply a performance profile appropriate for your hardware and topology. For guidance on creating a profile, see the "Creating a performance profile" section.

3.  Edit this created performance profile:

    ``` terminal
    $ oc edit -f <your_profile_name>.yaml
    ```

4.  Populate the `spec` field with the `net` object. The object list can contain two fields:

    -   `userLevelNetworking` is a required field specified as a boolean flag. If `userLevelNetworking` is `true`, the queue count is set to the reserved CPU count for all supported devices. The default is `false`.

    -   `devices` is an optional field specifying a list of devices that will have the queues set to the reserved CPU count. If the device list is empty, the configuration applies to all network devices. The configuration is as follows:

        -   `interfaceName`: This field specifies the interface name, and it supports shell-style wildcards, which can be positive or negative.

            -   Example wildcard syntax is as follows: `<string> .*`

            -   Negative rules are prefixed with an exclamation mark. To apply the net queue changes to all devices other than the excluded list, use `!<device>`, for example, `!eno1`.

        -   `vendorID`: The network device vendor ID represented as a 16-bit hexadecimal number with a `0x` prefix.

        -   `deviceID`: The network device ID (model) represented as a 16-bit hexadecimal number with a `0x` prefix.

            !!! note
                When a `deviceID` is specified, the `vendorID` must also be defined. A device that matches all of the device identifiers specified in a device entry `interfaceName`, `vendorID`, or a pair of `vendorID` plus `deviceID` qualifies as a network device. This network device then has its net queues count set to the reserved CPU count.
                
                When two or more devices are specified, the net queues count is set to any net device that matches one of them.

5.  Set the queue count to the reserved CPU count for all devices by using this example performance profile:

    ``` yaml
    apiVersion: performance.openshift.io/v2
    kind: PerformanceProfile
    metadata:
      name: manual
    spec:
      cpu:
        isolated: 3-51,54-103
        reserved: 0-2,52-54
      net:
        userLevelNetworking: true
      nodeSelector:
        node-role.kubernetes.io/worker-cnf: ""
    ```

6.  Set the queue count to the reserved CPU count for all devices matching any of the defined device identifiers by using this example performance profile:

    ``` yaml
    apiVersion: performance.openshift.io/v2
    kind: PerformanceProfile
    metadata:
      name: manual
    spec:
      cpu:
        isolated: 3-51,54-103
        reserved: 0-2,52-54
      net:
        userLevelNetworking: true
        devices:
        - interfaceName: “eth0”
        - interfaceName: “eth1”
        - vendorID: “0x1af4”
        - deviceID: “0x1000”
      nodeSelector:
        node-role.kubernetes.io/worker-cnf: ""
    ```

7.  Set the queue count to the reserved CPU count for all devices starting with the interface name `eth` by using this example performance profile:

    ``` yaml
    apiVersion: performance.openshift.io/v2
    kind: PerformanceProfile
    metadata:
      name: manual
    spec:
      cpu:
        isolated: 3-51,54-103
        reserved: 0-2,52-54
      net:
        userLevelNetworking: true
        devices:
        - interfaceName: “eth*”
      nodeSelector:
        node-role.kubernetes.io/worker-cnf: ""
    ```

8.  Set the queue count to the reserved CPU count for all devices with an interface named anything other than `eno1` by using this example performance profile:

    ``` yaml
    apiVersion: performance.openshift.io/v2
    kind: PerformanceProfile
    metadata:
      name: manual
    spec:
      cpu:
        isolated: 3-51,54-103
        reserved: 0-2,52-54
      net:
        userLevelNetworking: true
        devices:
        - interfaceName: “!eno1”
      nodeSelector:
        node-role.kubernetes.io/worker-cnf: ""
    ```

9.  Set the queue count to the reserved CPU count for all devices that have an interface name `eth0`, `vendorID` of `0x1af4`, and `deviceID` of `0x1000` by using this example performance profile:

    ``` yaml
    apiVersion: performance.openshift.io/v2
    kind: PerformanceProfile
    metadata:
      name: manual
    spec:
      cpu:
        isolated: 3-51,54-103
        reserved: 0-2,52-54
      net:
        userLevelNetworking: true
        devices:
        - interfaceName: “eth0”
        - vendorID: “0x1af4”
        - deviceID: “0x1000”
      nodeSelector:
        node-role.kubernetes.io/worker-cnf: ""
    ```

10. Apply the updated performance profile:

    ``` terminal
    $ oc apply -f <your_profile_name>.yaml
    ```

-   [Creating a performance profile](../scalability_and_performance/cnf-create-performance-profiles.xml#cnf-create-performance-profiles).

### Verifying the queue status

In this section, a number of examples illustrate different performance profiles and how to verify the changes are applied.

**Example 1**

In this example, the net queue count is set to the reserved CPU count (2) for *all* supported devices.

The relevant section from the performance profile is:

``` yaml
apiVersion: performance.openshift.io/v2
metadata:
  name: performance
spec:
  kind: PerformanceProfile
  spec:
    cpu:
      reserved: 0-1  #total = 2
      isolated: 2-8
    net:
      userLevelNetworking: true
# ...
```

-   Display the status of the queues associated with a device using the following command:

    !!! note
        Run this command on the node where the performance profile was applied.

    ``` terminal
    $ ethtool -l <device>
    ```

-   Verify the queue status before the profile is applied:

    ``` terminal
    $ ethtool -l ens4
    ```

    **Example output**

    ``` terminal
    Channel parameters for ens4:
    Pre-set maximums:
    RX:         0
    TX:         0
    Other:      0
    Combined:   4
    Current hardware settings:
    RX:         0
    TX:         0
    Other:      0
    Combined:   4
    ```

-   Verify the queue status after the profile is applied:

    ``` terminal
    $ ethtool -l ens4
    ```

    **Example output**

    ``` terminal
    Channel parameters for ens4:
    Pre-set maximums:
    RX:         0
    TX:         0
    Other:      0
    Combined:   4
    Current hardware settings:
    RX:         0
    TX:         0
    Other:      0
    Combined:   2 
    ```

<!-- -->

-   The combined channel shows that the total count of reserved CPUs for *all* supported devices is 2. This matches what is configured in the performance profile.

**Example 2**

In this example, the net queue count is set to the reserved CPU count (2) for *all* supported network devices with a specific `vendorID`.

The relevant section from the performance profile is:

``` yaml
apiVersion: performance.openshift.io/v2
metadata:
  name: performance
spec:
  kind: PerformanceProfile
  spec:
    cpu:
      reserved: 0-1  #total = 2
      isolated: 2-8
    net:
      userLevelNetworking: true
      devices:
      - vendorID = 0x1af4
# ...
```

-   Display the status of the queues associated with a device using the following command:

    !!! note
        Run this command on the node where the performance profile was applied.

    ``` terminal
    $ ethtool -l <device>
    ```

-   Verify the queue status after the profile is applied:

    ``` terminal
    $ ethtool -l ens4
    ```

    **Example output**

    ``` terminal
    Channel parameters for ens4:
    Pre-set maximums:
    RX:         0
    TX:         0
    Other:      0
    Combined:   4
    Current hardware settings:
    RX:         0
    TX:         0
    Other:      0
    Combined:   2 
    ```

<!-- -->

-   The total count of reserved CPUs for all supported devices with `vendorID=0x1af4` is 2. For example, if there is another network device `ens2` with `vendorID=0x1af4` it will also have total net queues of 2. This matches what is configured in the performance profile.

**Example 3**

In this example, the net queue count is set to the reserved CPU count (2) for *all* supported network devices that match any of the defined device identifiers.

The command `udevadm info` provides a detailed report on a device. In this example the devices are:

``` terminal
# udevadm info -p /sys/class/net/ens4
...
E: ID_MODEL_ID=0x1000
E: ID_VENDOR_ID=0x1af4
E: INTERFACE=ens4
...
```

``` terminal
# udevadm info -p /sys/class/net/eth0
...
E: ID_MODEL_ID=0x1002
E: ID_VENDOR_ID=0x1001
E: INTERFACE=eth0
...
```

-   Set the net queues to 2 for a device with `interfaceName` equal to `eth0` and any devices that have a `vendorID=0x1af4` with the following performance profile:

    ``` yaml
    apiVersion: performance.openshift.io/v2
    metadata:
      name: performance
    spec:
      kind: PerformanceProfile
        spec:
          cpu:
            reserved: 0-1  #total = 2
            isolated: 2-8
          net:
            userLevelNetworking: true
            devices:
            - interfaceName = eth0
            - vendorID = 0x1af4
    ...
    ```

-   Verify the queue status after the profile is applied:

    ``` terminal
    $ ethtool -l ens4
    ```

    **Example output**

    ``` terminal
    Channel parameters for ens4:
    Pre-set maximums:
    RX:         0
    TX:         0
    Other:      0
    Combined:   4
    Current hardware settings:
    RX:         0
    TX:         0
    Other:      0
    Combined:   2 
    ```

    -   The total count of reserved CPUs for all supported devices with `vendorID=0x1af4` is set to 2. For example, if there is another network device `ens2` with `vendorID=0x1af4`, it will also have the total net queues set to 2. Similarly, a device with `interfaceName` equal to `eth0` will have total net queues set to 2.

### Logging associated with adjusting NIC queues

Log messages detailing the assigned devices are recorded in the respective Tuned daemon logs. The following messages might be recorded to the `/var/log/tuned/tuned.log` file:

-   An `INFO` message is recorded detailing the successfully assigned devices:

    ``` terminal
    INFO tuned.plugins.base: instance net_test (net): assigning devices ens1, ens2, ens3
    ```

-   A `WARNING` message is recorded if none of the devices can be assigned:

    ``` terminal
    WARNING  tuned.plugins.base: instance net_test: no matching devices available
    ```

Unresolved directive in cnf-performance-addon-operator-for-low-latency-nodes.adoc - include::modules/cnf-performing-end-to-end-tests-for-platform-verification.adoc\[leveloffset=+1\]

## Debugging low latency CNF tuning status

The `PerformanceProfile` custom resource (CR) contains status fields for reporting tuning status and debugging latency degradation issues. These fields report on conditions that describe the state of the operator’s reconciliation functionality.

A typical issue can arise when the status of machine config pools that are attached to the performance profile are in a degraded state, causing the `PerformanceProfile` status to degrade. In this case, the machine config pool issues a failure message.

The Node Tuning Operator contains the `performanceProfile.spec.status.Conditions` status field:

``` bash
Status:
  Conditions:
    Last Heartbeat Time:   2020-06-02T10:01:24Z
    Last Transition Time:  2020-06-02T10:01:24Z
    Status:                True
    Type:                  Available
    Last Heartbeat Time:   2020-06-02T10:01:24Z
    Last Transition Time:  2020-06-02T10:01:24Z
    Status:                True
    Type:                  Upgradeable
    Last Heartbeat Time:   2020-06-02T10:01:24Z
    Last Transition Time:  2020-06-02T10:01:24Z
    Status:                False
    Type:                  Progressing
    Last Heartbeat Time:   2020-06-02T10:01:24Z
    Last Transition Time:  2020-06-02T10:01:24Z
    Status:                False
    Type:                  Degraded
```

The `Status` field contains `Conditions` that specify `Type` values that indicate the status of the performance profile:

`Available`  
All machine configs and Tuned profiles have been created successfully and are available for cluster components are responsible to process them (NTO, MCO, Kubelet).

`Upgradeable`  
Indicates whether the resources maintained by the Operator are in a state that is safe to upgrade.

`Progressing`  
Indicates that the deployment process from the performance profile has started.

`Degraded`  
Indicates an error if:

-   Validation of the performance profile has failed.

-   Creation of all relevant components did not complete successfully.

Each of these types contain the following fields:

`Status`  
The state for the specific type (`true` or `false`).

`Timestamp`  
The transaction timestamp.

`Reason string`  
The machine readable reason.

`Message string`  
The human readable reason describing the state and error details, if any.

### Machine config pools

A performance profile and its created products are applied to a node according to an associated machine config pool (MCP). The MCP holds valuable information about the progress of applying the machine configurations created by performance profiles that encompass kernel args, kube config, huge pages allocation, and deployment of rt-kernel. The Performance Profile controller monitors changes in the MCP and updates the performance profile status accordingly.

The only conditions returned by the MCP to the performance profile status is when the MCP is `Degraded`, which leads to `performaceProfile.status.condition.Degraded = true`.

**Example**

The following example is for a performance profile with an associated machine config pool (`worker-cnf`) that was created for it:

1.  The associated machine config pool is in a degraded state:

    ``` terminal
    # oc get mcp
    ```

    **Example output**

    ``` terminal
    NAME         CONFIG                                                 UPDATED   UPDATING   DEGRADED   MACHINECOUNT   READYMACHINECOUNT   UPDATEDMACHINECOUNT   DEGRADEDMACHINECOUNT   AGE
    master       rendered-master-2ee57a93fa6c9181b546ca46e1571d2d       True      False      False      3              3                   3                     0                      2d21h
    worker       rendered-worker-d6b2bdc07d9f5a59a6b68950acf25e5f       True      False      False      2              2                   2                     0                      2d21h
    worker-cnf   rendered-worker-cnf-6c838641b8a08fff08dbd8b02fb63f7c   False     True       True       2              1                   1                     1                      2d20h
    ```

2.  The `describe` section of the MCP shows the reason:

    ``` terminal
    # oc describe mcp worker-cnf
    ```

    **Example output**

    ``` terminal
      Message:               Node node-worker-cnf is reporting: "prepping update:
      machineconfig.machineconfiguration.openshift.io \"rendered-worker-cnf-40b9996919c08e335f3ff230ce1d170\" not
      found"
        Reason:                1 nodes are reporting degraded status on sync
    ```

3.  The degraded state should also appear under the performance profile `status` field marked as `degraded = true`:

    ``` terminal
    # oc describe performanceprofiles performance
    ```

    **Example output**

    ``` terminal
    Message: Machine config pool worker-cnf Degraded Reason: 1 nodes are reporting degraded status on sync.
    Machine config pool worker-cnf Degraded Message: Node yquinn-q8s5v-w-b-z5lqn.c.openshift-gce-devel.internal is
    reporting: "prepping update: machineconfig.machineconfiguration.openshift.io
    \"rendered-worker-cnf-40b9996919c08e335f3ff230ce1d170\" not found".    Reason:  MCPDegraded
       Status:  True
       Type:    Degraded
    ```

## Collecting low latency tuning debugging data for Red Hat Support

When opening a support case, it is helpful to provide debugging information about your cluster to Red Hat Support.

The `must-gather` tool enables you to collect diagnostic information about your OpenShift Container Platform cluster, including node tuning, NUMA topology, and other information needed to debug issues with low latency setup.

For prompt support, supply diagnostic information for both OpenShift Container Platform and low latency tuning.

### About the must-gather tool

The `oc adm must-gather` CLI command collects the information from your cluster that is most likely needed for debugging issues, such as:

-   Resource definitions

-   Audit logs

-   Service logs

You can specify one or more images when you run the command by including the `--image` argument. When you specify an image, the tool collects data related to that feature or product. When you run `oc adm must-gather`, a new pod is created on the cluster. The data is collected on that pod and saved in a new directory that starts with `must-gather.local`. This directory is created in your current working directory.

### About collecting low latency tuning data

Use the `oc adm must-gather` CLI command to collect information about your cluster, including features and objects associated with low latency tuning, including:

-   The Node Tuning Operator namespaces and child objects.

-   `MachineConfigPool` and associated `MachineConfig` objects.

-   The Node Tuning Operator and associated Tuned objects.

-   Linux Kernel command line options.

-   CPU and NUMA topology

-   Basic PCI device information and NUMA locality.

To collect debugging information with `must-gather`, you must specify the Performance Addon Operator `must-gather` image:

``` terminal
--image=registry.redhat.io/openshift4/performance-addon-operator-must-gather-rhel8:v4.11.
```

!!! note
    In earlier versions of OpenShift Container Platform, the Performance Addon Operator provided automatic, low latency performance tuning for applications. In OpenShift Container Platform 4.11, these functions are part of the Node Tuning Operator. However, you must still use the `performance-addon-operator-must-gather` image when running the `must-gather` command.

### Gathering data about specific features

You can gather debugging information about specific features by using the `oc adm must-gather` CLI command with the `--image` or `--image-stream` argument. The `must-gather` tool supports multiple images, so you can gather data about more than one feature by running a single command.

!!! note
    To collect the default `must-gather` data in addition to specific feature data, add the `--image-stream=openshift/must-gather` argument.
!!! note
    In earlier versions of OpenShift Container Platform, the Performance Addon Operator provided automatic, low latency performance tuning for applications. In OpenShift Container Platform 4.11, these functions are part of the Node Tuning Operator. However, you must still use the `performance-addon-operator-must-gather` image when running the `must-gather` command.

-   Access to the cluster as a user with the `cluster-admin` role.

-   The OpenShift Container Platform CLI (oc) installed.

1.  Navigate to the directory where you want to store the `must-gather` data.

2.  Run the `oc adm must-gather` command with one or more `--image` or `--image-stream` arguments. For example, the following command gathers both the default cluster data and information specific to the Node Tuning Operator:

    ``` terminal
    $ oc adm must-gather \
     --image-stream=openshift/must-gather \ 

     --image=registry.redhat.io/openshift4/performance-addon-operator-must-gather-rhel8:v4.11 
    ```

    -   The default OpenShift Container Platform `must-gather` image.

    -   The `must-gather` image for low latency tuning diagnostics.

3.  Create a compressed file from the `must-gather` directory that was created in your working directory. For example, on a computer that uses a Linux operating system, run the following command:

    ``` terminal
     $ tar cvaf must-gather.tar.gz must-gather.local.5421342344627712289/ 
    ```

    -   Replace `must-gather-local.5421342344627712289/` with the actual directory name.

4.  Attach the compressed file to your support case on the [Red Hat Customer Portal](https://access.redhat.com/).

-   For more information about MachineConfig and KubeletConfig, see [Managing nodes](../nodes/nodes/nodes-nodes-managing.xml#nodes-nodes-managing).

-   For more information about the Node Tuning Operator, see [Using the Node Tuning Operator](../scalability_and_performance/using-node-tuning-operator.xml#using-node-tuning-operator).

-   For more information about the PerformanceProfile, see [Configuring huge pages](../scalability_and_performance/what-huge-pages-do-and-how-they-are-consumed-by-apps.xml#configuring-huge-pages_huge-pages).

-   For more information about consuming huge pages from your containers, see [How huge pages are consumed by apps](../scalability_and_performance/what-huge-pages-do-and-how-they-are-consumed-by-apps.xml#how-huge-pages-are-consumed-by-apps_huge-pages).
