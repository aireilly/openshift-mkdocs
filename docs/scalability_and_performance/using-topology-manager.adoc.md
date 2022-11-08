# Using Topology Manager

Topology Manager collects hints from the CPU Manager, Device Manager, and other Hint Providers to align pod resources, such as CPU, SR-IOV VFs, and other device resources, for all Quality of Service (QoS) classes on the same non-uniform memory access (NUMA) node.

Topology Manager uses topology information from collected hints to decide if a pod can be accepted or rejected on a node, based on the configured Topology Manager policy and pod resources requested.

Topology Manager is useful for workloads that use hardware accelerators to support latency-critical execution and high throughput parallel computation.

!!! note
    To use Topology Manager you must use the CPU Manager with the `static` policy. For more information on CPU Manager, see [Using CPU Manager](../scalability_and_performance/using-cpu-manager.xml#using-cpu-manager).

## Topology Manager policies

Topology Manager aligns `Pod` resources of all Quality of Service (QoS) classes by collecting topology hints from Hint Providers, such as CPU Manager and Device Manager, and using the collected hints to align the `Pod` resources.

!!! note
    To align CPU resources with other requested resources in a `Pod` spec, the CPU Manager must be enabled with the `static` CPU Manager policy.

Topology Manager supports four allocation policies, which you assign in the `cpumanager-enabled` custom resource (CR):

`none` policy  
This is the default policy and does not perform any topology alignment.

`best-effort` policy  
For each container in a pod with the `best-effort` topology management policy, kubelet calls each Hint Provider to discover their resource availability. Using this information, the Topology Manager stores the preferred NUMA Node affinity for that container. If the affinity is not preferred, Topology Manager stores this and admits the pod to the node.

`restricted` policy  
For each container in a pod with the `restricted` topology management policy, kubelet calls each Hint Provider to discover their resource availability. Using this information, the Topology Manager stores the preferred NUMA Node affinity for that container. If the affinity is not preferred, Topology Manager rejects this pod from the node, resulting in a pod in a `Terminated` state with a pod admission failure.

`single-numa-node` policy  
For each container in a pod with the `single-numa-node` topology management policy, kubelet calls each Hint Provider to discover their resource availability. Using this information, the Topology Manager determines if a single NUMA Node affinity is possible. If it is, the pod is admitted to the node. If a single NUMA Node affinity is not possible, the Topology Manager rejects the pod from the node. This results in a pod in a Terminated state with a pod admission failure.

## Setting up Topology Manager

To use Topology Manager, you must configure an allocation policy in the `cpumanager-enabled` custom resource (CR). This file might exist if you have set up CPU Manager. If the file does not exist, you can create the file.

-   Configure the CPU Manager policy to be `static`. See the Using CPU Manager in the Scalability and Performance section.

**Procedure**

To activate Topololgy Manager:

1.  Configure the Topology Manager allocation policy in the `cpumanager-enabled` custom resource (CR).

    ``` terminal
    $ oc edit KubeletConfig cpumanager-enabled
    ```

    ``` yaml
    apiVersion: machineconfiguration.openshift.io/v1
    kind: KubeletConfig
    metadata:
      name: cpumanager-enabled
    spec:
      machineConfigPoolSelector:
        matchLabels:
          custom-kubelet: cpumanager-enabled
      kubeletConfig:
         cpuManagerPolicy: static 
         cpuManagerReconcilePeriod: 5s
         topologyManagerPolicy: single-numa-node 
    ```

    -   This parameter must be `static` with a lowercase `s`.

    -   Specify your selected Topology Manager allocation policy. Here, the policy is `single-numa-node`. Acceptable values are: `default`, `best-effort`, `restricted`, `single-numa-node`.

-   For more information on CPU Manager, see [Using CPU Manager](../scalability_and_performance/using-cpu-manager.xml#using-cpu-manager).

## Pod interactions with Topology Manager policies

The example `Pod` specs below help illustrate pod interactions with Topology Manager.

The following pod runs in the `BestEffort` QoS class because no resource requests or limits are specified.

``` yaml
spec:
  containers:
  - name: nginx
    image: nginx
```

The next pod runs in the `Burstable` QoS class because requests are less than limits.

``` yaml
spec:
  containers:
  - name: nginx
    image: nginx
    resources:
      limits:
        memory: "200Mi"
      requests:
        memory: "100Mi"
```

If the selected policy is anything other than `none`, Topology Manager would not consider either of these `Pod` specifications.

The last example pod below runs in the Guaranteed QoS class because requests are equal to limits.

``` yaml
spec:
  containers:
  - name: nginx
    image: nginx
    resources:
      limits:
        memory: "200Mi"
        cpu: "2"
        example.com/device: "1"
      requests:
        memory: "200Mi"
        cpu: "2"
        example.com/device: "1"
```

Topology Manager would consider this pod. The Topology Manager consults the CPU Manager static policy, which returns the topology of available CPUs. Topology Manager also consults Device Manager to discover the topology of available devices for example.com/device.

Topology Manager will use this information to store the best Topology for this container. In the case of this pod, CPU Manager and Device Manager will use this stored information at the resource allocation stage.
