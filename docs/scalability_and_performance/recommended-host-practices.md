# Recommended host practices

This topic provides recommended host practices for OpenShift Container Platform.

!!! important
    These guidelines apply to OpenShift Container Platform with software-defined networking (SDN), not Open Virtual Network (OVN).

## Recommended node host practices

The OpenShift Container Platform node configuration file contains important options. For example, two parameters control the maximum number of pods that can be scheduled to a node: `podsPerCore` and `maxPods`.

When both options are in use, the lower of the two values limits the number of pods on a node. Exceeding these values can result in:

-   Increased CPU utilization.

-   Slow pod scheduling.

-   Potential out-of-memory scenarios, depending on the amount of memory in the node.

-   Exhausting the pool of IP addresses.

-   Resource overcommitting, leading to poor user application performance.

!!! important
    In Kubernetes, a pod that is holding a single container actually uses two containers. The second container is used to set up networking prior to the actual container starting. Therefore, a system running 10 pods will actually have 20 containers running.
!!! note
    Disk IOPS throttling from the cloud provider might have an impact on CRI-O and kubelet. They might get overloaded when there are large number of I/O intensive pods running on the nodes. It is recommended that you monitor the disk I/O on the nodes and use volumes with sufficient throughput for the workload.

`podsPerCore` sets the number of pods the node can run based on the number of processor cores on the node. For example, if `podsPerCore` is set to `10` on a node with 4 processor cores, the maximum number of pods allowed on the node will be `40`.

``` yaml
kubeletConfig:
  podsPerCore: 10
```

Setting `podsPerCore` to `0` disables this limit. The default is `0`. `podsPerCore` cannot exceed `maxPods`.

`maxPods` sets the number of pods the node can run to a fixed value, regardless of the properties of the node.

``` yaml
 kubeletConfig:
    maxPods: 250
```

## Creating a KubeletConfig CRD to edit kubelet parameters

The kubelet configuration is currently serialized as an Ignition configuration, so it can be directly edited. However, there is also a new `kubelet-config-controller` added to the Machine Config Controller (MCC). This lets you use a `KubeletConfig` custom resource (CR) to edit the kubelet parameters.

!!! note
    As the fields in the `kubeletConfig` object are passed directly to the kubelet from upstream Kubernetes, the kubelet validates those values directly. Invalid values in the `kubeletConfig` object might cause cluster nodes to become unavailable. For valid values, see the [Kubernetes documentation](https://kubernetes.io/docs/reference/config-api/kubelet-config.v1beta1/).

Consider the following guidance:

-   Create one `KubeletConfig` CR for each machine config pool with all the config changes you want for that pool. If you are applying the same content to all of the pools, you need only one `KubeletConfig` CR for all of the pools.

-   Edit an existing `KubeletConfig` CR to modify existing settings or add new settings, instead of creating a CR for each change. It is recommended that you create a CR only to modify a different machine config pool, or for changes that are intended to be temporary, so that you can revert the changes.

-   As needed, create multiple `KubeletConfig` CRs with a limit of 10 per cluster. For the first `KubeletConfig` CR, the Machine Config Operator (MCO) creates a machine config appended with `kubelet`. With each subsequent CR, the controller creates another `kubelet` machine config with a numeric suffix. For example, if you have a `kubelet` machine config with a `-2` suffix, the next `kubelet` machine config is appended with `-3`.

If you want to delete the machine configs, delete them in reverse order to avoid exceeding the limit. For example, you delete the `kubelet-3` machine config before deleting the `kubelet-2` machine config.

!!! note
    If you have a machine config with a `kubelet-9` suffix, and you create another `KubeletConfig` CR, a new machine config is not created, even if there are fewer than 10 `kubelet` machine configs.

**Example `KubeletConfig` CR**

``` terminal
$ oc get kubeletconfig
```

``` terminal
NAME                AGE
set-max-pods        15m
```

**Example showing a `KubeletConfig` machine config**

``` terminal
$ oc get mc | grep kubelet
```

``` terminal
...
99-worker-generated-kubelet-1                  b5c5119de007945b6fe6fb215db3b8e2ceb12511   3.2.0             26m
...
```

The following procedure is an example to show how to configure the maximum number of pods per node on the worker nodes.

**Prerequisites**

1.  Obtain the label associated with the static `MachineConfigPool` CR for the type of node you want to configure. Perform one of the following steps:

    1.  View the machine config pool:

        ``` terminal
        $ oc describe machineconfigpool <name>
        ```

        For example:

        ``` terminal
        $ oc describe machineconfigpool worker
        ```

        **Example output**

        ``` yaml
        apiVersion: machineconfiguration.openshift.io/v1
        kind: MachineConfigPool
        metadata:
          creationTimestamp: 2019-02-08T14:52:39Z
          generation: 1
          labels:
            custom-kubelet: set-max-pods 
        ```

        -   If a label has been added it appears under `labels`.

    2.  If the label is not present, add a key/value pair:

        ``` terminal
        $ oc label machineconfigpool worker custom-kubelet=set-max-pods
        ```

**Procedure**

1.  View the available machine configuration objects that you can select:

    ``` terminal
    $ oc get machineconfig
    ```

    By default, the two kubelet-related configs are `01-master-kubelet` and `01-worker-kubelet`.

2.  Check the current value for the maximum pods per node:

    ``` terminal
    $ oc describe node <node_name>
    ```

    For example:

    ``` terminal
    $ oc describe node ci-ln-5grqprb-f76d1-ncnqq-worker-a-mdv94
    ```

    Look for `value: pods: <value>` in the `Allocatable` stanza:

    **Example output**

    ``` terminal
    Allocatable:
     attachable-volumes-aws-ebs:  25
     cpu:                         3500m
     hugepages-1Gi:               0
     hugepages-2Mi:               0
     memory:                      15341844Ki
     pods:                        250
    ```

3.  Set the maximum pods per node on the worker nodes by creating a custom resource file that contains the kubelet configuration:

    ``` yaml
    apiVersion: machineconfiguration.openshift.io/v1
    kind: KubeletConfig
    metadata:
      name: set-max-pods
    spec:
      machineConfigPoolSelector:
        matchLabels:
          custom-kubelet: set-max-pods 
      kubeletConfig:
        maxPods: 500 
    ```

    -   Enter the label from the machine config pool.

    -   Add the kubelet configuration. In this example, use `maxPods` to set the maximum pods per node.

    !!! note
        The rate at which the kubelet talks to the API server depends on queries per second (QPS) and burst values. The default values, `50` for `kubeAPIQPS` and `100` for `kubeAPIBurst`, are sufficient if there are limited pods running on each node. It is recommended to update the kubelet QPS and burst rates if there are enough CPU and memory resources on the node.
        
        ``` yaml
        apiVersion: machineconfiguration.openshift.io/v1
        kind: KubeletConfig
        metadata:
          name: set-max-pods
        spec:
          machineConfigPoolSelector:
            matchLabels:
              custom-kubelet: set-max-pods
          kubeletConfig:
            maxPods: <pod_count>
            kubeAPIBurst: <burst_rate>
            kubeAPIQPS: <QPS>
        ```

    1.  Update the machine config pool for workers with the label:

        ``` terminal
        $ oc label machineconfigpool worker custom-kubelet=set-max-pods
        ```

    2.  Create the `KubeletConfig` object:

        ``` terminal
        $ oc create -f change-maxPods-cr.yaml
        ```

    3.  Verify that the `KubeletConfig` object is created:

        ``` terminal
        $ oc get kubeletconfig
        ```

        **Example output**

        ``` terminal
        NAME                AGE
        set-max-pods        15m
        ```

        Depending on the number of worker nodes in the cluster, wait for the worker nodes to be rebooted one by one. For a cluster with 3 worker nodes, this could take about 10 to 15 minutes.

4.  Verify that the changes are applied to the node:

    1.  Check on a worker node that the `maxPods` value changed:

        ``` terminal
        $ oc describe node <node_name>
        ```

    2.  Locate the `Allocatable` stanza:

        ``` terminal
         ...
        Allocatable:
          attachable-volumes-gce-pd:  127
          cpu:                        3500m
          ephemeral-storage:          123201474766
          hugepages-1Gi:              0
          hugepages-2Mi:              0
          memory:                     14225400Ki
          pods:                       500 
         ...
        ```

        -   In this example, the `pods` parameter should report the value you set in the `KubeletConfig` object.

5.  Verify the change in the `KubeletConfig` object:

    ``` terminal
    $ oc get kubeletconfigs set-max-pods -o yaml
    ```

    This should show a status of `True` and `type:Success`, as shown in the following example:

    ``` yaml
    spec:
      kubeletConfig:
        maxPods: 500
      machineConfigPoolSelector:
        matchLabels:
          custom-kubelet: set-max-pods
    status:
      conditions:
      - lastTransitionTime: "2021-06-30T17:04:07Z"
        message: Success
        status: "True"
        type: Success
    ```

## Modifying the number of unavailable worker nodes

By default, only one machine is allowed to be unavailable when applying the kubelet-related configuration to the available worker nodes. For a large cluster, it can take a long time for the configuration change to be reflected. At any time, you can adjust the number of machines that are updating to speed up the process.

**Procedure**

1.  Edit the `worker` machine config pool:

    ``` terminal
    $ oc edit machineconfigpool worker
    ```

2.  Add the `maxUnavailable` field and set the value:

    ``` yaml
    spec:
      maxUnavailable: <node_count>
    ```

    !!! important
        When setting the value, consider the number of worker nodes that can be unavailable without affecting the applications running on the cluster.

## Control plane node sizing

The control plane node resource requirements depend on the number and type of nodes and objects in the cluster. The following control plane node size recommendations are based on the results of a control plane density focused testing, or *Cluster-density*. This test creates the following objects across a given number of namespaces:

-   1 image stream

-   1 build

-   5 deployments, with 2 pod replicas in a `sleep` state, mounting 4 secrets, 4 config maps, and 1 downward API volume each

-   5 services, each one pointing to the TCP/8080 and TCP/8443 ports of one of the previous deployments

-   1 route pointing to the first of the previous services

-   10 secrets containing 2048 random string characters

-   10 config maps containing 2048 random string characters

+------------------------+------------------------------+-----------------+-----------------+
| Number of worker nodes | Cluster-density (namespaces) | CPU cores       | Memory (GB)     |
+========================+==============================+=================+=================+
| 27                     | 500                          | 4               | 16              |
+------------------------+------------------------------+-----------------+-----------------+
| 120                    | 1000                         | 8               | 32              |
+------------------------+------------------------------+-----------------+-----------------+
| 252                    | 4000                         | 16              | 64              |
+------------------------+------------------------------+-----------------+-----------------+
| 501                    | 4000                         | 16              | 96              |
+------------------------+------------------------------+-----------------+-----------------+

: **Table 1**

On a large and dense cluster with three masters or control plane nodes, the CPU and memory usage will spike up when one of the nodes is stopped, rebooted or fails. The failures can be due to unexpected issues with power, network or underlying infrastructure in addition to intentional cases where the cluster is restarted after shutting it down to save costs. The remaining two control plane nodes must handle the load in order to be highly available which leads to increase in the resource usage. This is also expected during upgrades because the masters are cordoned, drained, and rebooted serially to apply the operating system updates, as well as the control plane Operators update. To avoid cascading failures, keep the overall CPU and memory resource usage on the control plane nodes to at most 60% of all available capacity to handle the resource usage spikes. Increase the CPU and memory on the control plane nodes accordingly to avoid potential downtime due to lack of resources.

!!! important
    The node sizing varies depending on the number of nodes and object counts in the cluster. It also depends on whether the objects are actively being created on the cluster. During object creation, the control plane is more active in terms of resource usage compared to when the objects are in the `running` phase.

Operator Lifecycle Manager (OLM ) runs on the control plane nodes and it’s memory footprint depends on the number of namespaces and user installed operators that OLM needs to manage on the cluster. Control plane nodes need to be sized accordingly to avoid OOM kills. Following data points are based on the results from cluster maximums testing.

+----------------------+-------------------------------+-------------------------------------------------+
| Number of namespaces | OLM memory at idle state (GB) | OLM memory with 5 user operators installed (GB) |
+======================+===============================+=================================================+
| 500                  | 0.823                         | 1.7                                             |
+----------------------+-------------------------------+-------------------------------------------------+
| 1000                 | 1.2                           | 2.5                                             |
+----------------------+-------------------------------+-------------------------------------------------+
| 1500                 | 1.7                           | 3.2                                             |
+----------------------+-------------------------------+-------------------------------------------------+
| 2000                 | 2                             | 4.4                                             |
+----------------------+-------------------------------+-------------------------------------------------+
| 3000                 | 2.7                           | 5.6                                             |
+----------------------+-------------------------------+-------------------------------------------------+
| 4000                 | 3.8                           | 7.6                                             |
+----------------------+-------------------------------+-------------------------------------------------+
| 5000                 | 4.2                           | 9.02                                            |
+----------------------+-------------------------------+-------------------------------------------------+
| 6000                 | 5.8                           | 11.3                                            |
+----------------------+-------------------------------+-------------------------------------------------+
| 7000                 | 6.6                           | 12.9                                            |
+----------------------+-------------------------------+-------------------------------------------------+
| 8000                 | 6.9                           | 14.8                                            |
+----------------------+-------------------------------+-------------------------------------------------+
| 9000                 | 8                             | 17.7                                            |
+----------------------+-------------------------------+-------------------------------------------------+
| 10,000               | 9.9                           | 21.6                                            |
+----------------------+-------------------------------+-------------------------------------------------+

: **Table 2**

!!! important
    If you used an installer-provisioned infrastructure installation method, you cannot modify the control plane node size in a running OpenShift Container Platform 4.11 cluster. Instead, you must estimate your total node count and use the suggested control plane node size during installation.
!!! important
    The recommendations are based on the data points captured on OpenShift Container Platform clusters with OpenShift SDN as the network plug-in.
!!! note
    In OpenShift Container Platform 4.11, half of a CPU core (500 millicore) is now reserved by the system by default compared to OpenShift Container Platform 3.11 and previous versions. The sizes are determined taking that into consideration.

### Increasing the flavor size of the Amazon Web Services (AWS) master instances

When you have overloaded AWS master nodes in a cluster and the master nodes require more resources, you can increase the flavor size of the master instances.

!!! note
    It is recommended to backup etcd before increasing the flavor size of the AWS master instances.

**Prerequisites**

-   You have an IPI (installer-provisioned infrastructure) or UPI (user-provisioned infrastructure) cluster on AWS.

**Procedure**

1.  Open the AWS console, fetch the master instances.

2.  Stop one master instance.

3.  Select the stopped instance, and click **Actions** → **Instance Settings** → **Change instance type**.

4.  Change the instance to a larger type, ensuring that the type is the same base as the previous selection, and apply changes. For example, you can change `m6i.xlarge` to `m6i.2xlarge` or `m6i.4xlarge`.

5.  Backup the instance, and repeat the steps for the next master instance.

-   [Backing up etcd](../backup_and_restore/control_plane_backup_and_restore/backing-up-etcd/#backing-up-etcd)

## Recommended etcd practices

Because etcd writes data to disk and persists proposals on disk, its performance depends on disk performance. Although etcd is not particularly I/O intensive, it requires a low latency block device for optimal performance and stability. Because etcd’s consensus protocol depends on persistently storing metadata to a log (WAL), etcd is sensitive to disk-write latency. Slow disks and disk activity from other processes can cause long fsync latencies.

Those latencies can cause etcd to miss heartbeats, not commit new proposals to the disk on time, and ultimately experience request timeouts and temporary leader loss. High write latencies also lead to a OpenShift API slowness, which affects cluster performance. Because of these reasons, avoid colocating other workloads on the control-plane nodes.

In terms of latency, run etcd on top of a block device that can write at least 50 IOPS of 8000 bytes long sequentially. That is, with a latency of 20ms, keep in mind that uses fdatasync to synchronize each write in the WAL. For heavy loaded clusters, sequential 500 IOPS of 8000 bytes (2 ms) are recommended. To measure those numbers, you can use a benchmarking tool, such as fio.

To achieve such performance, run etcd on machines that are backed by SSD or NVMe disks with low latency and high throughput. Consider single-level cell (SLC) solid-state drives (SSDs), which provide 1 bit per memory cell, are durable and reliable, and are ideal for write-intensive workloads.

The following hard disk features provide optimal etcd performance:

-   Low latency to support fast read operation.

-   High-bandwidth writes for faster compactions and defragmentation.

-   High-bandwidth reads for faster recovery from failures.

-   Solid state drives as a minimum selection, however NVMe drives are preferred.

-   Server-grade hardware from various manufacturers for increased reliability.

-   RAID 0 technology for increased performance.

-   Dedicated etcd drives. Do not place log files or other heavy workloads on etcd drives.

Avoid NAS or SAN setups and spinning drives. Always benchmark by using utilities such as fio. Continuously monitor the cluster performance as it increases.

!!! note
    Avoid using the Network File System (NFS) protocol or other network based file systems.

Some key metrics to monitor on a deployed OpenShift Container Platform cluster are p99 of etcd disk write ahead log duration and the number of etcd leader changes. Use Prometheus to track these metrics.

!!! note
    The etcd member database sizes can vary in a cluster during normal operations. This difference does not affect cluster upgrades, even if the leader size is different from the other members.

To validate the hardware for etcd before or after you create the OpenShift Container Platform cluster, you can use fio.

**Prerequisites**

-   Container runtimes such as Podman or Docker are installed on the machine that you’re testing.

-   Data is written to the `/var/lib/etcd` path.

**Procedure** \* Run fio and analyze the results:

\+

-   If you use Podman, run this command:

    ``` terminal
    $ sudo podman run --volume /var/lib/etcd:/var/lib/etcd:Z quay.io/openshift-scale/etcd-perf
    ```

-   If you use Docker, run this command:

    ``` terminal
    $ sudo docker run --volume /var/lib/etcd:/var/lib/etcd:Z quay.io/openshift-scale/etcd-perf
    ```

The output reports whether the disk is fast enough to host etcd by comparing the 99th percentile of the fsync metric captured from the run to see if it is less than 20 ms. A few of the most important etcd metrics that might affected by I/O performance are as follow:

-   `etcd_disk_wal_fsync_duration_seconds_bucket` metric reports the etcd’s WAL fsync duration

-   `etcd_disk_backend_commit_duration_seconds_bucket` metric reports the etcd backend commit latency duration

-   `etcd_server_leader_changes_seen_total` metric reports the leader changes

Because etcd replicates the requests among all the members, its performance strongly depends on network input/output (I/O) latency. High network latencies result in etcd heartbeats taking longer than the election timeout, which results in leader elections that are disruptive to the cluster. A key metric to monitor on a deployed OpenShift Container Platform cluster is the 99th percentile of etcd network peer latency on each etcd cluster member. Use Prometheus to track the metric.

The `histogram_quantile(0.99, rate(etcd_network_peer_round_trip_time_seconds_bucket[2m]))` metric reports the round trip time for etcd to finish replicating the client requests between the members. Ensure that it is less than 50 ms.

-   [How to use `fio` to check etcd disk performance in OpenShift Container Platform](https://access.redhat.com/solutions/4885641)

## Defragmenting etcd data

For large and dense clusters, etcd can suffer from poor performance if the keyspace grows too large and exceeds the space quota. Periodically maintain and defragment etcd to free up space in the data store. Monitor Prometheus for etcd metrics and defragment it when required; otherwise, etcd can raise a cluster-wide alarm that puts the cluster into a maintenance mode that accepts only key reads and deletes.

Monitor these key metrics:

-   `etcd_server_quota_backend_bytes`, which is the current quota limit

-   `etcd_mvcc_db_total_size_in_use_in_bytes`, which indicates the actual database usage after a history compaction

-   `etcd_debugging_mvcc_db_total_size_in_bytes`, which shows the database size, including free space waiting for defragmentation

Defragment etcd data to reclaim disk space after events that cause disk fragmentation, such as etcd history compaction.

History compaction is performed automatically every five minutes and leaves gaps in the back-end database. This fragmented space is available for use by etcd, but is not available to the host file system. You must defragment etcd to make this space available to the host file system.

Defragmentation occurs automatically, but you can also trigger it manually.

!!! note
    Automatic defragmentation is good for most cases, because the etcd operator uses cluster information to determine the most efficient operation for the user.

### Automatic defragmentation

The etcd Operator automatically defragments disks. No manual intervention is needed.

Verify that the defragmentation process is successful by viewing one of these logs:

-   etcd logs

-   cluster-etcd-operator pod

-   operator status error log

!!! warning
    Automatic defragmentation can cause leader election failure in various OpenShift core components, such as the Kubernetes controller manager, which triggers a restart of the failing component. The restart is harmless and either triggers failover to the next running instance or the component resumes work again after the restart.

**Example log output for successful defragmentation**

``` terminal
etcd member has been defragmented: <member_name>, memberID: <member_id>
```

**Example log output for unsuccessful defragmentation**

``` terminal
failed defrag on member: <member_name>, memberID: <member_id>: <error_message>
```

### Manual defragmentation

A Prometheus alert indicates when you need to use manual defragmentation. The alert is displayed in two cases:

-   When etcd uses more than 50% of its available space for more than 10 minutes

-   When etcd is actively using less than 50% of its total database size for more than 10 minutes

You can also determine whether defragmentation is needed by checking the etcd database size in MB that will be freed by defragmentation with the PromQL expression: `(etcd_mvcc_db_total_size_in_bytes - etcd_mvcc_db_total_size_in_use_in_bytes)/1024/1024`

!!! warning
    Defragmenting etcd is a blocking action. The etcd member will not respond until defragmentation is complete. For this reason, wait at least one minute between defragmentation actions on each of the pods to allow the cluster to recover.

Follow this procedure to defragment etcd data on each etcd member.

**Prerequisites**

-   You have access to the cluster as a user with the `cluster-admin` role.

**Procedure**

1.  Determine which etcd member is the leader, because the leader should be defragmented last.

    1.  Get the list of etcd pods:

        ``` terminal
        $ oc get pods -n openshift-etcd -o wide | grep -v guard | grep etcd
        ```

        **Example output**

        ``` terminal
        etcd-ip-10-0-159-225.example.redhat.com                3/3     Running     0          175m   10.0.159.225   ip-10-0-159-225.example.redhat.com   <none>           <none>
        etcd-ip-10-0-191-37.example.redhat.com                 3/3     Running     0          173m   10.0.191.37    ip-10-0-191-37.example.redhat.com    <none>           <none>
        etcd-ip-10-0-199-170.example.redhat.com                3/3     Running     0          176m   10.0.199.170   ip-10-0-199-170.example.redhat.com   <none>           <none>
        ```

    2.  Choose a pod and run the following command to determine which etcd member is the leader:

        ``` terminal
        $ oc rsh -n openshift-etcd etcd-ip-10-0-159-225.example.redhat.com etcdctl endpoint status --cluster -w table
        ```

        **Example output**

        ``` terminal
        Defaulting container name to etcdctl.
        Use 'oc describe pod/etcd-ip-10-0-159-225.example.redhat.com -n openshift-etcd' to see all of the containers in this pod.
        +---------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
        |         ENDPOINT          |        ID        | VERSION | DB SIZE | IS LEADER | IS LEARNER | RAFT TERM | RAFT INDEX | RAFT APPLIED INDEX | ERRORS |
        +---------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
        |  https://10.0.191.37:2379 | 251cd44483d811c3 |   3.4.9 |  104 MB |     false |      false |         7 |      91624 |              91624 |        |
        | https://10.0.159.225:2379 | 264c7c58ecbdabee |   3.4.9 |  104 MB |     false |      false |         7 |      91624 |              91624 |        |
        | https://10.0.199.170:2379 | 9ac311f93915cc79 |   3.4.9 |  104 MB |      true |      false |         7 |      91624 |              91624 |        |
        +---------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
        ```

        Based on the `IS LEADER` column of this output, the `https://10.0.199.170:2379` endpoint is the leader. Matching this endpoint with the output of the previous step, the pod name of the leader is `etcd-ip-10-0-199-170.example.redhat.com`.

2.  Defragment an etcd member.

    1.  Connect to the running etcd container, passing in the name of a pod that is *not* the leader:

        ``` terminal
        $ oc rsh -n openshift-etcd etcd-ip-10-0-159-225.example.redhat.com
        ```

    2.  Unset the `ETCDCTL_ENDPOINTS` environment variable:

        ``` terminal
        sh-4.4# unset ETCDCTL_ENDPOINTS
        ```

    3.  Defragment the etcd member:

        ``` terminal
        sh-4.4# etcdctl --command-timeout=30s --endpoints=https://localhost:2379 defrag
        ```

        **Example output**

        ``` terminal
        Finished defragmenting etcd member[https://localhost:2379]
        ```

        If a timeout error occurs, increase the value for `--command-timeout` until the command succeeds.

    4.  Verify that the database size was reduced:

        ``` terminal
        sh-4.4# etcdctl endpoint status -w table --cluster
        ```

        **Example output**

        ``` terminal
        +---------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
        |         ENDPOINT          |        ID        | VERSION | DB SIZE | IS LEADER | IS LEARNER | RAFT TERM | RAFT INDEX | RAFT APPLIED INDEX | ERRORS |
        +---------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
        |  https://10.0.191.37:2379 | 251cd44483d811c3 |   3.4.9 |  104 MB |     false |      false |         7 |      91624 |              91624 |        |
        | https://10.0.159.225:2379 | 264c7c58ecbdabee |   3.4.9 |   41 MB |     false |      false |         7 |      91624 |              91624 |        | 
        | https://10.0.199.170:2379 | 9ac311f93915cc79 |   3.4.9 |  104 MB |      true |      false |         7 |      91624 |              91624 |        |
        +---------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
        ```

        This example shows that the database size for this etcd member is now 41 MB as opposed to the starting size of 104 MB.

    5.  Repeat these steps to connect to each of the other etcd members and defragment them. Always defragment the leader last.

        Wait at least one minute between defragmentation actions to allow the etcd pod to recover. Until the etcd pod recovers, the etcd member will not respond.

3.  If any `NOSPACE` alarms were triggered due to the space quota being exceeded, clear them.

    1.  Check if there are any `NOSPACE` alarms:

        ``` terminal
        sh-4.4# etcdctl alarm list
        ```

        **Example output**

        ``` terminal
        memberID:12345678912345678912 alarm:NOSPACE
        ```

    2.  Clear the alarms:

        ``` terminal
        sh-4.4# etcdctl alarm disarm
        ```

**Next steps**

After defragmentation, if etcd still uses more than 50% of its available space, consider increasing the disk quota for etcd.

## OpenShift Container Platform infrastructure components

The following infrastructure workloads do not incur OpenShift Container Platform worker subscriptions:

-   Kubernetes and OpenShift Container Platform control plane services that run on masters

-   The default router

-   The integrated container image registry

-   The HAProxy-based Ingress Controller

-   The cluster metrics collection, or monitoring service, including components for monitoring user-defined projects

-   Cluster aggregated logging

-   Service brokers

-   Red Hat Quay

-   Red Hat OpenShift Data Foundation

-   Red Hat Advanced Cluster Manager

-   Red Hat Advanced Cluster Security for Kubernetes

-   Red Hat OpenShift GitOps

-   Red Hat OpenShift Pipelines

Any node that runs any other container, pod, or component is a worker node that your subscription must cover.

For information on infrastructure nodes and which components can run on infrastructure nodes, see the "Red Hat OpenShift control plane and infrastructure nodes" section in the [OpenShift sizing and subscription guide for enterprise Kubernetes](https://www.redhat.com/en/resources/openshift-subscription-sizing-guide) document.

## Moving the monitoring solution

The monitoring stack includes multiple components, including Prometheus, Thanos Querier, and Alertmanager. The Cluster Monitoring Operator manages this stack. To redeploy the monitoring stack to infrastructure nodes, you can create and apply a custom config map.

**Procedure**

1.  Edit the `cluster-monitoring-config` config map and change the `nodeSelector` to use the `infra` label:

    ``` terminal
    $ oc edit configmap cluster-monitoring-config -n openshift-monitoring
    ```

    ``` yaml
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: cluster-monitoring-config
      namespace: openshift-monitoring
    data:
      config.yaml: |+
        alertmanagerMain:
          nodeSelector: 
            node-role.kubernetes.io/infra: ""
          tolerations:
          - key: node-role.kubernetes.io/infra
            value: reserved
            effect: NoSchedule
          - key: node-role.kubernetes.io/infra
            value: reserved
            effect: NoExecute
        prometheusK8s:
          nodeSelector:
            node-role.kubernetes.io/infra: ""
          tolerations:
          - key: node-role.kubernetes.io/infra
            value: reserved
            effect: NoSchedule
          - key: node-role.kubernetes.io/infra
            value: reserved
            effect: NoExecute
        prometheusOperator:
          nodeSelector:
            node-role.kubernetes.io/infra: ""
          tolerations:
          - key: node-role.kubernetes.io/infra
            value: reserved
            effect: NoSchedule
          - key: node-role.kubernetes.io/infra
            value: reserved
            effect: NoExecute
        k8sPrometheusAdapter:
          nodeSelector:
            node-role.kubernetes.io/infra: ""
          tolerations:
          - key: node-role.kubernetes.io/infra
            value: reserved
            effect: NoSchedule
          - key: node-role.kubernetes.io/infra
            value: reserved
            effect: NoExecute
        kubeStateMetrics:
          nodeSelector:
            node-role.kubernetes.io/infra: ""
          tolerations:
          - key: node-role.kubernetes.io/infra
            value: reserved
            effect: NoSchedule
          - key: node-role.kubernetes.io/infra
            value: reserved
            effect: NoExecute
        telemeterClient:
          nodeSelector:
            node-role.kubernetes.io/infra: ""
          tolerations:
          - key: node-role.kubernetes.io/infra
            value: reserved
            effect: NoSchedule
          - key: node-role.kubernetes.io/infra
            value: reserved
            effect: NoExecute
        openshiftStateMetrics:
          nodeSelector:
            node-role.kubernetes.io/infra: ""
          tolerations:
          - key: node-role.kubernetes.io/infra
            value: reserved
            effect: NoSchedule
          - key: node-role.kubernetes.io/infra
            value: reserved
            effect: NoExecute
        thanosQuerier:
          nodeSelector:
            node-role.kubernetes.io/infra: ""
          tolerations:
          - key: node-role.kubernetes.io/infra
            value: reserved
            effect: NoSchedule
          - key: node-role.kubernetes.io/infra
            value: reserved
            effect: NoExecute
    ```

    -   Add a `nodeSelector` parameter with the appropriate value to the component you want to move. You can use a `nodeSelector` in the format shown or use `<key>: <value>` pairs, based on the value specified for the node. If you added a taint to the infrasructure node, also add a matching toleration.

2.  Watch the monitoring pods move to the new machines:

    ``` terminal
    $ watch 'oc get pod -n openshift-monitoring -o wide'
    ```

3.  If a component has not moved to the `infra` node, delete the pod with this component:

    ``` terminal
    $ oc delete pod -n openshift-monitoring <pod>
    ```

    The component from the deleted pod is re-created on the `infra` node.

## Moving the default registry

You configure the registry Operator to deploy its pods to different nodes.

**Prerequisites**

-   Configure additional compute machine sets in your OpenShift Container Platform cluster.

**Procedure**

1.  View the `config/instance` object:

    ``` terminal
    $ oc get configs.imageregistry.operator.openshift.io/cluster -o yaml
    ```

    **Example output**

    ``` yaml
    apiVersion: imageregistry.operator.openshift.io/v1
    kind: Config
    metadata:
      creationTimestamp: 2019-02-05T13:52:05Z
      finalizers:
      - imageregistry.operator.openshift.io/finalizer
      generation: 1
      name: cluster
      resourceVersion: "56174"
      selfLink: /apis/imageregistry.operator.openshift.io/v1/configs/cluster
      uid: 36fd3724-294d-11e9-a524-12ffeee2931b
    spec:
      httpSecret: d9a012ccd117b1e6616ceccb2c3bb66a5fed1b5e481623
      logging: 2
      managementState: Managed
      proxy: {}
      replicas: 1
      requests:
        read: {}
        write: {}
      storage:
        s3:
          bucket: image-registry-us-east-1-c92e88cad85b48ec8b312344dff03c82-392c
          region: us-east-1
    status:
    ...
    ```

2.  Edit the `config/instance` object:

    ``` terminal
    $ oc edit configs.imageregistry.operator.openshift.io/cluster
    ```

    ``` yaml
    spec:
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - podAffinityTerm:
              namespaces:
              - openshift-image-registry
              topologyKey: kubernetes.io/hostname
            weight: 100
      logLevel: Normal
      managementState: Managed
      nodeSelector: 
        node-role.kubernetes.io/infra: ""
      tolerations:
      - effect: NoSchedule
        key: node-role.kubernetes.io/infra
        value: reserved
      - effect: NoExecute
        key: node-role.kubernetes.io/infra
        value: reserved
    ```

    -   Add a `nodeSelector` parameter with the appropriate value to the component you want to move. You can use a `nodeSelector` in the format shown or use `<key>: <value>` pairs, based on the value specified for the node. If you added a taint to the infrasructure node, also add a matching toleration.

3.  Verify the registry pod has been moved to the infrastructure node.

    1.  Run the following command to identify the node where the registry pod is located:

        ``` terminal
        $ oc get pods -o wide -n openshift-image-registry
        ```

    2.  Confirm the node has the label you specified:

        ``` terminal
        $ oc describe node <node_name>
        ```

        Review the command output and confirm that `node-role.kubernetes.io/infra` is in the `LABELS` list.

## Moving the router

You can deploy the router pod to a different compute machine set. By default, the pod is deployed to a worker node.

**Prerequisites**

-   Configure additional compute machine sets in your OpenShift Container Platform cluster.

**Procedure**

1.  View the `IngressController` custom resource for the router Operator:

    ``` terminal
    $ oc get ingresscontroller default -n openshift-ingress-operator -o yaml
    ```

    The command output resembles the following text:

    ``` yaml
    apiVersion: operator.openshift.io/v1
    kind: IngressController
    metadata:
      creationTimestamp: 2019-04-18T12:35:39Z
      finalizers:
      - ingresscontroller.operator.openshift.io/finalizer-ingresscontroller
      generation: 1
      name: default
      namespace: openshift-ingress-operator
      resourceVersion: "11341"
      selfLink: /apis/operator.openshift.io/v1/namespaces/openshift-ingress-operator/ingresscontrollers/default
      uid: 79509e05-61d6-11e9-bc55-02ce4781844a
    spec: {}
    status:
      availableReplicas: 2
      conditions:
      - lastTransitionTime: 2019-04-18T12:36:15Z
        status: "True"
        type: Available
      domain: apps.<cluster>.example.com
      endpointPublishingStrategy:
        type: LoadBalancerService
      selector: ingresscontroller.operator.openshift.io/deployment-ingresscontroller=default
    ```

2.  Edit the `ingresscontroller` resource and change the `nodeSelector` to use the `infra` label:

    ``` terminal
    $ oc edit ingresscontroller default -n openshift-ingress-operator
    ```

    ``` yaml
      spec:
        nodePlacement:
          nodeSelector:
            matchLabels:
              node-role.kubernetes.io/infra: ""
        tolerations:
        - effect: NoSchedule
          key: node-role.kubernetes.io/infra
          value: reserved
        - effect: NoExecute
          key: node-role.kubernetes.io/infra
          value: reserved
    ```

    -   Add a `nodeSelector` parameter with the appropriate value to the component you want to move. You can use a `nodeSelector` in the format shown or use `<key>: <value>` pairs, based on the value specified for the node. If you added a taint to the infrasructure node, also add a matching toleration.

3.  Confirm that the router pod is running on the `infra` node.

    1.  View the list of router pods and note the node name of the running pod:

        ``` terminal
        $ oc get pod -n openshift-ingress -o wide
        ```

        **Example output**

        ``` terminal
        NAME                              READY     STATUS        RESTARTS   AGE       IP           NODE                           NOMINATED NODE   READINESS GATES
        router-default-86798b4b5d-bdlvd   1/1      Running       0          28s       10.130.2.4   ip-10-0-217-226.ec2.internal   <none>           <none>
        router-default-955d875f4-255g8    0/1      Terminating   0          19h       10.129.2.4   ip-10-0-148-172.ec2.internal   <none>           <none>
        ```

        In this example, the running pod is on the `ip-10-0-217-226.ec2.internal` node.

    2.  View the node status of the running pod:

        ``` terminal
        $ oc get node <node_name> 
        ```

        -   Specify the `<node_name>` that you obtained from the pod list.

        **Example output**

        ``` terminal
        NAME                          STATUS  ROLES         AGE   VERSION
        ip-10-0-217-226.ec2.internal  Ready   infra,worker  17h   v1.25.0
        ```

        Because the role list includes `infra`, the pod is running on the correct node.

## Infrastructure node sizing

*Infrastructure nodes* are nodes that are labeled to run pieces of the OpenShift Container Platform environment. The infrastructure node resource requirements depend on the cluster age, nodes, and objects in the cluster, as these factors can lead to an increase in the number of metrics or time series in Prometheus. The following infrastructure node size recommendations are based on the results of cluster maximums and control plane density focused testing.

+------------------------+----------------------+-----------------------+
| Number of worker nodes | CPU cores            | Memory (GB)           |
+========================+======================+=======================+
| 25                     | 4                    | 16                    |
+------------------------+----------------------+-----------------------+
| 100                    | 8                    | 32                    |
+------------------------+----------------------+-----------------------+
| 250                    | 16                   | 128                   |
+------------------------+----------------------+-----------------------+
| 500                    | 32                   | 128                   |
+------------------------+----------------------+-----------------------+

: **Table 3**

In general, three infrastructure nodes are recommended per cluster.

!!! important
    These sizing recommendations are based on scale tests, which create a large number of objects across the cluster. These tests include reaching some of the cluster maximums. In the case of 250 and 500 node counts on an OpenShift Container Platform 4.11 cluster, these maximums are 10000 namespaces with 61000 pods, 10000 deployments, 181000 secrets, 400 config maps, and so on. Prometheus is a highly memory intensive application; the resource usage depends on various factors including the number of nodes, objects, the Prometheus metrics scraping interval, metrics or time series, and the age of the cluster. The disk size also depends on the retention period. You must take these factors into consideration and size them accordingly.
    
    These sizing recommendations are only applicable for the Prometheus, Router, and Registry infrastructure components, which are installed during cluster installation. Logging is a day-two operation and is not included in these recommendations.
!!! note
    In OpenShift Container Platform 4.11, half of a CPU core (500 millicore) is now reserved by the system by default compared to OpenShift Container Platform 3.11 and previous versions. This influences the stated sizing recommendations.

## Additional resources

-   [OpenShift Container Platform cluster maximums](../scalability_and_performance/planning-your-environment-according-to-object-maximums/#planning-your-environment-according-to-object-maximums)

-   [Creating infrastructure machine sets](../machine_management/creating-infrastructure-machinesets/#creating-infrastructure-machinesets)
