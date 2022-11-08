# Workload partitioning on single-node OpenShift

In resource-constrained environments, such as single-node OpenShift deployments, it is advantageous to reserve most of the CPU resources for your own workloads and configure OpenShift Container Platform to run on a fixed number of CPUs within the host. In these environments, management workloads, including the control plane, need to be configured to use fewer resources than they might by default in normal clusters. You can isolate the OpenShift Container Platform services, cluster management workloads, and infrastructure pods to run on a reserved set of CPUs.

When you use workload partitioning, the CPU resources used by OpenShift Container Platform for cluster management are isolated to a partitioned set of CPU resources on a single-node cluster. This partitioning isolates cluster management functions to the defined number of CPUs. All cluster management functions operate solely on that `cpuset` configuration.

The minimum number of reserved CPUs required for the management partition for a single-node cluster is four CPU Hyper threads (HTs). The set of pods that make up the baseline OpenShift Container Platform installation and a set of typical add-on Operators are annotated for inclusion in the management workload partition. These pods operate normally within the minimum size `cpuset` configuration. Inclusion of Operators or workloads outside of the set of accepted management pods requires additional CPU HTs to be added to that partition.

Workload partitioning isolates the user workloads away from the platform workloads using the normal scheduling capabilities of Kubernetes to manage the number of pods that can be placed onto those cores, and avoids mixing cluster management workloads and user workloads.

When applying workload partitioning, use the Node Tuning Operator to implement the performance profile:

-   Workload partitioning pins the OpenShift Container Platform infrastructure pods to a defined `cpuset` configuration.

-   The performance profile pins the systemd services to a defined `cpuset` configuration.

-   This `cpuset` configuration must match.

Workload partitioning introduces a new extended resource of `<workload-type>.workload.openshift.io/cores` for each defined CPU pool, or workload-type. Kubelet advertises these new resources and CPU requests by pods allocated to the pool are accounted for within the corresponding resource rather than the typical `cpu` resource. When workload partitioning is enabled, the `<workload-type>.workload.openshift.io/cores` resource allows access to the CPU capacity of the host, not just the default CPU pool.

## Enabling workload partitioning

A key feature to enable as part of a single-node OpenShift installation is workload partitioning. This limits the cores allowed to run platform services, maximizing the CPU core for application payloads. You must configure workload partitioning at cluster installation time.

!!! note
    You can enable workload partitioning during the cluster installation process only. You cannot disable workload partitioning post-installation. However, you can reconfigure workload partitioning by updating the `cpu` value that you define in the `performanceprofile`, and in the MachineConfig CR in the following procedure.

-   The base64-encoded content below contains the CPU set that the management workloads are constrained to. This content must be adjusted to match the set specified in the `performanceprofile` and must be accurate for the number of cores on the cluster.

    ``` yaml
    apiVersion: machineconfiguration.openshift.io/v1
    kind: MachineConfig
    metadata:
      labels:
        machineconfiguration.openshift.io/role: master
      name: 02-master-workload-partitioning
    spec:
      config:
        ignition:
          version: 3.2.0
        storage:
          files:
          - contents:
              source: data:text/plain;charset=utf-8;base64,W2NyaW8ucnVudGltZS53b3JrbG9hZHMubWFuYWdlbWVudF0KYWN0aXZhdGlvbl9hbm5vdGF0aW9uID0gInRhcmdldC53b3JrbG9hZC5vcGVuc2hpZnQuaW8vbWFuYWdlbWVudCIKYW5ub3RhdGlvbl9wcmVmaXggPSAicmVzb3VyY2VzLndvcmtsb2FkLm9wZW5zaGlmdC5pbyIKW2NyaW8ucnVudGltZS53b3JrbG9hZHMubWFuYWdlbWVudC5yZXNvdXJjZXNdCmNwdXNoYXJlcyA9IDAKQ1BVcyA9ICIwLTEsIDUyLTUzIgo=
            mode: 420
            overwrite: true
            path: /etc/crio/crio.conf.d/01-workload-partitioning
            user:
              name: root
          - contents:
              source: data:text/plain;charset=utf-8;base64,ewogICJtYW5hZ2VtZW50IjogewogICAgImNwdXNldCI6ICIwLTEsNTItNTMiCiAgfQp9Cg==
            mode: 420
            overwrite: true
            path: /etc/kubernetes/openshift-workload-pinning
            user:
              name: root
    ```

-   The contents of `/etc/crio/crio.conf.d/01-workload-partitioning` should look like this:

    ``` text
    [crio.runtime.workloads.management]
    activation_annotation = "target.workload.openshift.io/management"
    annotation_prefix = "resources.workload.openshift.io"
    [crio.runtime.workloads.management.resources]
    cpushares = 0
    CPUs = "0-1, 52-53" 
    ```

    -   The `CPUs` value varies based on the installation.

If Hyper-Threading is enabled, specify both threads of each core. The `CPUs` value must match the reserved CPU set specified in the performance profile.

This content should be base64 encoded and provided in the `01-workload-partitioning-content` in the manifest above.

-   The contents of `/etc/kubernetes/openshift-workload-pinning` should look like this:

    ``` javascript
    {
      "management": {
        "cpuset": "0-1,52-53" 
      }
    }
    ```

    -   The `cpuset` must match the `CPUs` value in `/etc/crio/crio.conf.d/01-workload-partitioning`.

This content should be base64 encoded and provided in the `openshift-workload-pinning-content` in the preceding manifest.
