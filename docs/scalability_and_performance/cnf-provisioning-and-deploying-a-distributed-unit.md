# Provisioning and installing a distributed unit

!!! note
    The features described in this document are for Developer Preview purposes and are not supported by Red Hat at this time.

## Partitioning management workloads {#cnf-du-partitioning-management-workloads_installing-du}

You can isolate the OpenShift Container Platform services, cluster management workloads, and infrastructure pods to run on a reserved set of CPUs. This is useful for resource-constrained environments, such as such as a single-node cluster, where you want to reserve most of the CPU resources for user workloads and configure OpenShift Container Platform to run on a fixed number of CPUs within the host.

Server resources installed at the edge, such as cores, are expensive and limited. Application workloads require nearly all cores and the resources consumed by infrastructure is a key reason for the selection of a vRAN infrastructure. A hypothetical distributed unit (DU) example is an unusually resource-intensive workload, typically requiring 20 dedicated cores. Partitioning management workloads mitigates much of this activity by separating management tasks from normal workloads.

When you use workload partitioning, the CPU resources used by OpenShift Container Platform for cluster management are isolated to a partitioned set of CPU resources on a single-node cluster with a DU profile applied. This falls broadly into two categories:

-   Isolates cluster management functions to the defined number of CPUs. All cluster management functions operate solely on that `cpuset`.

-   Tunes the cluster configuration (with the applied DU profile) so the actual CPU usage fits within the assigned `cpuset`.

!!! note
    This feature is only available on single-node OpenShift in this release.

The minimum number of reserved CPUs required for the management partition for a single-node cluster is four CPU HTs. Inclusion of Operators or workloads outside of the set of accepted management pods requires additional CPU HTs.

Workload partitioning isolates the workloads away from the non-management workloads using the normal scheduling capabilities of Kubernetes to manage the number of pods that can be placed onto those cores, and avoids mixing cluster management workloads and user workloads.

To fully leverage workload partitioning, you need to install the Performance Addon Operator and apply the performance profile.

The concept of cluster management workloads is flexible and can encompass:

-   All OpenShift Container Platform core components necessary to run the cluster.

-   Any add-on Operators necessary to make up the platform as defined by the customer.

-   Operators or other components from third-party vendors that the customer deems as management rather than operational.

    -   Adding management workloads might require additional CPU resources to be added to the partition.

Workload partitioning introduces a new extended resource of `<workload-type>.workload.openshift.io/cores` for each CPU pool, workload-type, defined in the configuration file. Kubelet advertises these new resources. When workload partitioning is enabled, it represents all of the CPU capacity of the host, not just the CPU pool.

### Configuring workload partitioning {#cnf-du-configuring-workload-partitioning_installing-du}

The following procedure outlines a high level, end to end workflow that installs a cluster with workload partitioning enabled and pods that are correctly scheduled to run on the management CPU partition.

1.  Create a machine config manifest to configure CRI-O to partition management workloads. The cpuset that you specify must match the reserved cpuset that you specified in the performance-addon-operator profile.

2.  Create another machine config manifest to write a configuration file for kubelet to enable the same workload partition. The file is only readable by the kubelet.

3.  Run `openshift-install` to create the standard manifests, adds their extra manifests from steps 1 and 2, then creates the cluster.

4.  For pods and namespaces that are correctly annotated, the CPU request values are zeroed out and converted to `<workload-type>.workload.openshift.io/cores`. This modified resource allows the pods to be constrained to the restricted CPUs.

5.  The single-node cluster starts with management components constrained to a subset of available CPUs.

#### Creating a machine config manifest for workload partitioning {#cnf-du-creating-a-machine-config-manifest-for-workload-partitioning_installing-du}

Part of configuring workload partitioning requires you to provide a `MachineConfig` manifest during installation to configure CRI-O and kubelet for the workload types.

The manifest, without the encoded file content, looks like this:

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
          source: data:text/plain;charset=utf-8;base64,<01-workload-partitioning-content>
        mode: 420
        overwrite: true
        path: /etc/crio/crio.conf.d/01-workload-partitioning
        user:
          name: root
      - contents:
          source: data:text/plain;charset=utf-8;base64,<openshift-workload-pinning content>
        mode: 420
        overwrite: true
        path: /etc/kubernetes/openshift-workload-pinning
        user:
          name: root
```

The contents of `/etc/crio/crio.conf.d/01-workload-partitioning` should look like this.

``` text
[crio.runtime.workloads.management]
activation_annotation = "target.workload.openshift.io/management"
annotation_prefix = "resources.workload.openshift.io"
resources = { "cpushares" = 0, "cpuset" = "0-1,52-53" } 
```

-   The `cpuset` value will vary based on the installation.

If hyperthreading is enabled, specify both threads of each core. The `cpuset` must match the reserved CPU set specified in the performance profile.

This content should be base64 encoded and provided in the `01-workload-partitioning-content` in the manifest above.

The contents of `/etc/kubernetes/openshift-workload-pinning` should look like this:

``` javascript
{
  "management": {
    "cpuset": "0-1,52-53" 
  }
}
```

-   The `cpuset` must match the value in `/etc/crio/crio.conf.d/01-workload-partitioning`.

This content should be base64 encoded and provided in the `openshift-workload-pinning-content` in the preceding manifest.

!!! note
    The `cpuset` specified must match the reserved `cpuset` specified in the Performance Addon Operator profile.
!!! note
    In this release, configuring machines for workload partitioning must be enabled during installation to work correctly. Once enabled, changes to the machine configs that enable the feature are not supported.

### Required annotations for workload partitioning {#cnf-du-required-annotations-for-workload-partitioning_installing-du}

Two annotations must be specified to isolate partitioned workloads from each other. Annotate the containing namespace with `workload.openshift.io/allowed` and the pod with `target.workload.openshift.io`.

Required OpenShift Container Platform pods and namespaces are already annotated. To add extra pods to the partition, such as supported post-installation operators or any user-added catalog sources, annotate both the namespace and pod on creation.

After you add the namespace annotation, you can control which workloads have access to the reserved CPU resources. Only pods in namespaces containing the annotation `workload.openshift.io/allowed: <workload-type> [, <workload-type>]` will be considered. Annotated pods that are contained in an unannotated namespace will fail to admit to the cluster. In this case, an error is raised indicating the pod is forbidden because the namespace does not allow the `workload type <workload-type>`.

To run pods on the reserved CPUs, the pods should be isolated on the partitioned resources and must be annotated with `target.workload.openshift.io/<workload-type>`. In the current release the only supported value for &lt;workload-type&gt; is `management`. Future releases might support multiple values for &lt;workload-type&gt;. The value of the annotation is a JSON struct as shown in the following code block.

The `effect` field controls whether the request is a soft or hard rule. It can contain either `PreferredDuringScheduling` for soft requests or `RequiredDuringScheduling` for hard requests. Only `PreferredDuringScheduling` is supported in this release.

``` yaml
metadata:
  annotations:
    target.workload.openshift.io/management: |
      {"effect": "PreferredDuringScheduling"}
```

!!! note
    For this implementation, pods with multiple annotations are rejected. Future versions might allow multiple workload types with different priorities to support clusters with different types of configurations.

### Workload partitioning and pod mutation {#cnf-du-workload-partitioning-pod-mutation_installing-du}

The workload partitioning feature modifies pods that are annotated with `target.workload.openshift.io/<workload-type>` that are in a namespace that contains the `workload.openshift.io/allowed: <workload-type>` annotation.

For example, a pod with the following CPU request specified would be mutated:

``` yaml
requests:
  cpu:
    400m
```

The requested CPU resource is replaced with a management cores resource:

``` yaml
requests:
  management.workload.openshift.io/cores: 400
```

The value of `resources.workload.openshift.io/{container-name}` is calculated as:

    shares == (request_in_millis * 1024) /1000

This results in a value of 409 in this example.

An annotation is added with the same value:

``` yaml
annotations:
  resources.workload.openshift.io/{container-name}: {"cpushares": 409}
```

The new request value and annotation value are scaled up by 1000 from the original CPU request input because opaque resources do not support units or fractional values. Note in the previous annotation example the request is in milli-cores (409m) and the modified value is unitless.

Pods are not changed in a way that changes their Quality of Service (QoS) class. For example, the feature does not remove CPU requests unless the pod also has memory requests, because if we mutate the pod so that it has no CPU or memory requests the Quality of Service class of the pod would be changed automatically. In this case, the `workload.openshift.io/warning` annotation includes a message explaining that the partitioning instructions were ignored. Any pod that is already `BestEffort` is annotated using `2` as the value so that CRI-O has an indicator to configure the CPU shares as `BestEffort`.

Pods with QoS of `Guaranteed` are not mutated.

!!! note
    The API server will remove any `resources.workload.openshift.io/` or `target.workload.openshift.io/` annotations from pods when they are scheduled. These annotations might only be set by the workload partitioning logic.
!!! note
    Only pods with correct annotations on both the pod and namespace when the pod is created will take advantage of this feature. Workload partitioning annotations added after the pod is created will not have any impact. This has particular impact on post-installation Operators where the administrator must annotate the namespace prior to Operator installation.

### CRI-O configuration for workload partitioning {#cnf-du-crio-configuration-for-workload-partitioning_installing-du}

In support of workload partitioning, CRI-O supports new configuration settings. The configuration file is delivered to a host as part of a machine config.

``` terminal
[crio.runtime.workloads.{workload-type}]
  activation_annotation = "target.workload.openshift.io/<workload-type>" 
  annotation_prefix = "resources.workload.openshift.io" 
  resources = { "cpushares" = 0, "cpuset" = "0-1,52-53" } 
```

-   Use the `activation_annotation` field to match pods that should be treated as having the workload type. The annotation key on the pod is compared for an exact match against the value specified in the configuration file. In this release, the only supported workload-type is `management`.

-   The `annotation_prefix` is the start of the annotation key that passes settings from the admission hook down to CRI-O.

-   The `resources` map associates annotation suffixes with default values. CRI-O defines a well-known set of resources and other values are not allowed. The `cpuset` value must match the kubelet configuration file and the reserved `cpuset` in the applied PerformanceProfile.

In the management workload case, it is configured as follows:

``` terminal
[crio.runtime.workloads.management]
  activation_annotation = "target.workload.openshift.io/management"
  annotation_prefix = "resources.workload.openshift.io"
  resources = { "cpushares" = 0, "cpuset" = "0-1,52-53" }
```

Pods that have the `target.workload.openshift.io/management` annotation will have their `cpuset` configured to the value from the appropriate workload configuration. The CPU shares for each container in the pod are configured according to the `management.workload.openshift.io/cores` resource limit, which ensures the pod’s CPU shares are enforced.

### Configuring a performance profile to support workload partitioning {#cnf-du-configuring-a-performance-profile-to-support-workload-partitioning.adoc_installing-du}

After you have configured workload partitioning, you need to ensure that the Performance Addon Operator has been installed and that you configured a performance profile.

The reserved CPU IDs in the performance profile must match the workload partitioning CPU IDs.

-   [Low latency tuning](../cnf-low-latency-tuning.xml)

### Cluster Management pods {#cnf-du-management-pods.adoc_installing-du}

For the purposes of achieving 2-core (4 HT CPU) installation of single-node clusters, the set of pods that are considered *management* are limited to:

-   Core Operators

-   Day 2 Operators

-   ACM pods

The following tables identify the namespaces and pods that can be restricted to a subset of the CPUs on a node by configuring workload partitioning.

#### Core Operators {#_core_operators}

+--------------------------------------------------+----------------------------------------+
| Namespace                                        | Pod                                    |
+==================================================+========================================+
| openshift-apiserver-operator                     | openshift-apiserver-operator           |
+--------------------------------------------------+----------------------------------------+
| openshift-apiserver                              | apiserver                              |
+--------------------------------------------------+----------------------------------------+
| openshift-authentication-operator                | authentication-operator                |
+--------------------------------------------------+----------------------------------------+
| openshift-authentication                         | oauth-openshift                        |
+--------------------------------------------------+----------------------------------------+
| openshift-cloud-controller-manager-operator      | cluster-cloud-controller-manager       |
+--------------------------------------------------+----------------------------------------+
| openshift-cloud-credential-operator              | cloud-credential-operator              |
+--------------------------------------------------+----------------------------------------+
| openshift-cluster-machine-approver               | machine-approver                       |
+--------------------------------------------------+----------------------------------------+
| openshift-cluster-node-tuning-operator           | cluster-node-tuning-operator           |
+--------------------------------------------------+----------------------------------------+
| openshift-cluster-node-tuning-operator           | tuned                                  |
+--------------------------------------------------+----------------------------------------+
| openshift-cluster-samples-operator               | cluster-samples-operator               |
+--------------------------------------------------+----------------------------------------+
| openshift-cluster-storage-operator               | cluster-storage-operator               |
+--------------------------------------------------+----------------------------------------+
| openshift-cluster-storage-operator               | csi-snapshot-controller                |
+--------------------------------------------------+----------------------------------------+
| openshift-cluster-storage-operator               | csi-snapshot-controller-operator       |
+--------------------------------------------------+----------------------------------------+
| openshift-cluster-storage-operator               | csi-snapshot-webhook                   |
+--------------------------------------------------+----------------------------------------+
| openshift-cluster-version                        | cluster-version-operator               |
+--------------------------------------------------+----------------------------------------+
| openshift-config-operator                        | openshift-config-operator              |
+--------------------------------------------------+----------------------------------------+
| openshift-console-operator                       | console-operator                       |
+--------------------------------------------------+----------------------------------------+
| openshift-console                                | console                                |
+--------------------------------------------------+----------------------------------------+
| openshift-console                                | downloads                              |
+--------------------------------------------------+----------------------------------------+
| openshift-controller-manager-operator            | openshift-controller-manager-operator  |
+--------------------------------------------------+----------------------------------------+
| openshift-controller-manager                     | controller-manager                     |
+--------------------------------------------------+----------------------------------------+
| openshift-dns-operator                           | dns-operator                           |
+--------------------------------------------------+----------------------------------------+
| openshift-dns                                    | dns-default                            |
+--------------------------------------------------+----------------------------------------+
| openshift-dns                                    | node-resolver                          |
+--------------------------------------------------+----------------------------------------+
| openshift-etcd-operator                          | etcd-operator                          |
+--------------------------------------------------+----------------------------------------+
| openshift-etcd                                   | etcd                                   |
+--------------------------------------------------+----------------------------------------+
| openshift-image-registry                         | cluster-image-registry-operator        |
+--------------------------------------------------+----------------------------------------+
| openshift-image-registry                         | image-pruner                           |
+--------------------------------------------------+----------------------------------------+
| openshift-image-registry                         | node-ca                                |
+--------------------------------------------------+----------------------------------------+
| openshift-ingress-canary                         | ingress-canary                         |
+--------------------------------------------------+----------------------------------------+
| openshift-ingress-operator                       | ingress-operator                       |
+--------------------------------------------------+----------------------------------------+
| openshift-ingress                                | router-default                         |
+--------------------------------------------------+----------------------------------------+
| openshift-insights                               | insights-operator                      |
+--------------------------------------------------+----------------------------------------+
| openshift-kube-apiserver-operator                | kube-apiserver-operator                |
+--------------------------------------------------+----------------------------------------+
| openshift-kube-apiserver                         | kube-apiserver                         |
+--------------------------------------------------+----------------------------------------+
| openshift-kube-controller-manager-operator       | kube-controller-manager-operator       |
+--------------------------------------------------+----------------------------------------+
| openshift-kube-controller-manager                | kube-controller-manager                |
+--------------------------------------------------+----------------------------------------+
| openshift-kube-scheduler-operator                | openshift-kube-scheduler-operator      |
+--------------------------------------------------+----------------------------------------+
| openshift-kube-scheduler                         | openshift-kube-scheduler               |
+--------------------------------------------------+----------------------------------------+
| openshift-kube-storage-version-migrator-operator | kube-storage-version-migrator-operator |
+--------------------------------------------------+----------------------------------------+
| openshift-kube-storage-version-migrator          | migrator                               |
+--------------------------------------------------+----------------------------------------+
| openshift-machine-api                            | cluster-autoscaler-operator            |
+--------------------------------------------------+----------------------------------------+
| openshift-machine-api                            | cluster-baremetal-operator             |
+--------------------------------------------------+----------------------------------------+
| openshift-machine-api                            | machine-api-operator                   |
+--------------------------------------------------+----------------------------------------+
| openshift-machine-config-operator                | machine-config-controller              |
+--------------------------------------------------+----------------------------------------+
| openshift-machine-config-operator                | machine-config-daemon                  |
+--------------------------------------------------+----------------------------------------+
| openshift-marketplace                            | certified-operators                    |
+--------------------------------------------------+----------------------------------------+
| openshift-machine-config-operator                | machine-config-operator                |
+--------------------------------------------------+----------------------------------------+
| openshift-machine-config-operator                | machine-config-server                  |
+--------------------------------------------------+----------------------------------------+
| openshift-marketplace                            | community-operators                    |
+--------------------------------------------------+----------------------------------------+
| openshift-marketplace                            | marketplace-operator                   |
+--------------------------------------------------+----------------------------------------+
| openshift-marketplace                            | redhat-marketplace                     |
+--------------------------------------------------+----------------------------------------+
| openshift-marketplace                            | redhat-operators                       |
+--------------------------------------------------+----------------------------------------+
| openshift-monitoring                             | alertmanager-main                      |
+--------------------------------------------------+----------------------------------------+
| openshift-monitoring                             | cluster-monitoring-operator            |
+--------------------------------------------------+----------------------------------------+
| openshift-monitoring                             | grafana                                |
+--------------------------------------------------+----------------------------------------+
| openshift-monitoring                             | kube-state-metrics                     |
+--------------------------------------------------+----------------------------------------+
| openshift-monitoring                             | node-exporter                          |
+--------------------------------------------------+----------------------------------------+
| openshift-monitoring                             | openshift-state-metrics                |
+--------------------------------------------------+----------------------------------------+
| openshift-monitoring                             | prometheus-adapter                     |
+--------------------------------------------------+----------------------------------------+
| openshift-monitoring                             | prometheus-adapter                     |
+--------------------------------------------------+----------------------------------------+
| openshift-monitoring                             | prometheus-k8s                         |
+--------------------------------------------------+----------------------------------------+
| openshift-monitoring                             | prometheus-operator                    |
+--------------------------------------------------+----------------------------------------+
| openshift-monitoring                             | telemeter-client                       |
+--------------------------------------------------+----------------------------------------+
| openshift-monitoring                             | thanos-querier                         |
+--------------------------------------------------+----------------------------------------+
| openshift-multus                                 | multus-admission-controller            |
+--------------------------------------------------+----------------------------------------+
| openshift-multus                                 | multus                                 |
+--------------------------------------------------+----------------------------------------+
| openshift-multus                                 | network-metrics-daemon                 |
+--------------------------------------------------+----------------------------------------+
| openshift-multus                                 | multus-additional-cni-plugins          |
+--------------------------------------------------+----------------------------------------+
| openshift-network-diagnostics                    | network-check-source                   |
+--------------------------------------------------+----------------------------------------+
| openshift-network-diagnostics                    | network-check-target                   |
+--------------------------------------------------+----------------------------------------+
| openshift-network-operator                       | network-operator                       |
+--------------------------------------------------+----------------------------------------+
| openshift-oauth-apiserver                        | apiserver                              |
+--------------------------------------------------+----------------------------------------+
| openshift-operator-lifecycle-manager             | catalog-operator                       |
+--------------------------------------------------+----------------------------------------+
| openshift-operator-lifecycle-manager             | olm-operator                           |
+--------------------------------------------------+----------------------------------------+
| openshift-operator-lifecycle-manager             | packageserver                          |
+--------------------------------------------------+----------------------------------------+
| openshift-operator-lifecycle-manager             | packageserver                          |
+--------------------------------------------------+----------------------------------------+
| openshift-ovn-kubernetes                         | ovnkube-master                         |
+--------------------------------------------------+----------------------------------------+
| openshift-ovn-kubernetes                         | ovnkube-node                           |
+--------------------------------------------------+----------------------------------------+
| openshift-ovn-kubernetes                         | ovs-node                               |
+--------------------------------------------------+----------------------------------------+
| openshift-service-ca-operator                    | service-ca-operator                    |
+--------------------------------------------------+----------------------------------------+
| openshift-service-ca                             | service-ca                             |
+--------------------------------------------------+----------------------------------------+

: **Table 1**

#### Day 2 Operators {#_day_2_operators}

+--------------------------------------+-----------------------------------+
| Namespace                            | Pod                               |
+======================================+===================================+
| openshift-ptp                        | ptp-operator                      |
+--------------------------------------+-----------------------------------+
| openshift-ptp                        | linuxptp-daemon                   |
+--------------------------------------+-----------------------------------+
| openshift-performance-addon-operator | performance-operator              |
+--------------------------------------+-----------------------------------+
| openshift-sriov-network-operator     | network-resources-injector        |
+--------------------------------------+-----------------------------------+
| openshift-sriov-network-operator     | operator-webhook                  |
+--------------------------------------+-----------------------------------+
| openshift-sriov-network-operator     | sriov-cni                         |
+--------------------------------------+-----------------------------------+
| openshift-sriov-network-operator     | sriov-device-plugin               |
+--------------------------------------+-----------------------------------+
| openshift-sriov-network-operator     | sriov-network-config-daemon       |
+--------------------------------------+-----------------------------------+
| openshift-sriov-network-operator     | sriov-network-operator            |
+--------------------------------------+-----------------------------------+
| local-storage                        | local-disks-local-diskmaker       |
+--------------------------------------+-----------------------------------+
| local-storage                        | local-disks-local-provisioner     |
+--------------------------------------+-----------------------------------+
| local-storage                        | local-storage-operator            |
+--------------------------------------+-----------------------------------+
| openshift-logging                    | cluster-logging-operator          |
+--------------------------------------+-----------------------------------+
| openshift-logging                    | fluentd                           |
+--------------------------------------+-----------------------------------+

: **Table 2**

#### ACM pods {#_acm_pods}

+-------------------------------------+-------------------------------------------+
| Namespace                           | Pod                                       |
+=====================================+===========================================+
| open-cluster-management-agent-addon | klusterlet-addon-appmgr                   |
+-------------------------------------+-------------------------------------------+
| open-cluster-management-agent-addon | klusterlet-addon-certpolicyctrl           |
+-------------------------------------+-------------------------------------------+
| open-cluster-management-agent-addon | klusterlet-addon-iampolicyctrl            |
+-------------------------------------+-------------------------------------------+
| open-cluster-management-agent-addon | klusterlet-addon-operator                 |
+-------------------------------------+-------------------------------------------+
| open-cluster-management-agent-addon | klusterlet-addon-policyctrl-config-policy |
+-------------------------------------+-------------------------------------------+
| open-cluster-management-agent-addon | klusterlet-addon-policyctrl-framework     |
+-------------------------------------+-------------------------------------------+
| open-cluster-management-agent-addon | klusterlet-addon-search                   |
+-------------------------------------+-------------------------------------------+
| open-cluster-management-agent-addon | klusterlet-addon-workmgr                  |
+-------------------------------------+-------------------------------------------+
| open-cluster-management-agent       | klusterlet                                |
+-------------------------------------+-------------------------------------------+
| open-cluster-management-agent       | klusterlet-registration-agent             |
+-------------------------------------+-------------------------------------------+
| open-cluster-management-agent       | klusterlet-work-agent                     |
+-------------------------------------+-------------------------------------------+

: **Table 3**

## Provisioning and deploying a distributed unit (DU) manually {#cnf-provisioning-deploying-a-distributed-unit-manually_installing-du}

Radio access network (RAN) is composed of central units (CU), distributed units (DU), and radio units (RU). RAN from the telecommunications standard perspective is shown below:

![High level RAN overview](data:image/svg+xml;base64,PHN2ZyBpZD0iYmI2YjhhNjQtOGY1MS00MDI1LWJkMjMtYTk4N2NjNzE1ZDUyIiBkYXRhLW5hbWU9ImFydHdvcmsiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyIgd2lkdGg9Ijc2MCIgaGVpZ2h0PSIyMTcuMTM2Ij48ZGVmcz48c3R5bGU+LmE2NjFmOTY0LTk3ZmUtNDJhOC1hZjMzLWQ0OWFlNDkxYWZmNSwuYjAzMGY2ZjktN2ZmNy00Y2ZmLWE2MGYtOGE2NzhkMmNiNDg1e2ZpbGw6IzE1MTUxNX0uYjZiOWFjMmUtNGEzZi00YzVjLWI1ZTktNjZmY2FkYzRiZTMxe2ZpbGw6I2ZmZn0uYTY2MWY5NjQtOTdmZS00MmE4LWFmMzMtZDQ5YWU0OTFhZmY1e2ZvbnQtc2l6ZToxMXB4O2ZvbnQtZmFtaWx5OlJlZEhhdFRleHQsJnF1b3Q7UmVkIEhhdCBUZXh0JnF1b3Q7LE92ZXJwYXNzLCZxdW90O0hlbHZldGljYSBOZXVlJnF1b3Q7LEFyaWFsLHNhbnMtc2VyaWY7Zm9udC13ZWlnaHQ6NTAwfS5hZjk2YmFjYi00MmMyLTRmYjUtOTJjMy0yMDkwNTczZTI1OWN7ZmlsbDpub25lO3N0cm9rZTojMTUxNTE1O3N0cm9rZS1saW5lY2FwOnJvdW5kO3N0cm9rZS1saW5lam9pbjpyb3VuZH08L3N0eWxlPjwvZGVmcz48cGF0aCBmaWxsPSIjZThlOGU4IiBkPSJNMCAyMGg2MjB2MTgwSDB6Ii8+PHRleHQgdHJhbnNmb3JtPSJ0cmFuc2xhdGUoMjUgNTYuNzg4KSIgZmlsbD0iIzE1MTUxNSIgZm9udC1zaXplPSIxNCIgZm9udC1mYW1pbHk9IlJlZEhhdFRleHQsJnF1b3Q7UmVkIEhhdCBUZXh0JnF1b3Q7LE92ZXJwYXNzLCZxdW90O0hlbHZldGljYSBOZXVlJnF1b3Q7LEFyaWFsLHNhbnMtc2VyaWYiIGZvbnQtd2VpZ2h0PSI3MDAiPlJBTiBib3VuZGFyeTwvdGV4dD48cGF0aCBjbGFzcz0iYjZiOWFjMmUtNGEzZi00YzVjLWI1ZTktNjZmY2FkYzRiZTMxIiB0cmFuc2Zvcm09InJvdGF0ZSgtMTgwIDUwNSA3NSkiIGQ9Ik00MTUgNDVoMTgwdjYwSDQxNXoiLz48dGV4dCBjbGFzcz0iYTY2MWY5NjQtOTdmZS00MmE4LWFmMzMtZDQ5YWU0OTFhZmY1IiB0cmFuc2Zvcm09InRyYW5zbGF0ZSg0NTkuMzk1IDcyLjA0NykiPkNlbnRyYWwgdW5pdCAoQ1UpLDx0c3BhbiB4PSIxMS43NjQiIHk9IjEyIj5jb250cm9sIHBsYW5lPC90c3Bhbj48L3RleHQ+PHBhdGggY2xhc3M9ImI2YjlhYzJlLTRhM2YtNGM1Yy1iNWU5LTY2ZmNhZGM0YmUzMSIgdHJhbnNmb3JtPSJyb3RhdGUoLTE4MCA1MDUgMTQ1KSIgZD0iTTQxNSAxMTVoMTgwdjYwSDQxNXoiLz48dGV4dCBjbGFzcz0iYTY2MWY5NjQtOTdmZS00MmE4LWFmMzMtZDQ5YWU0OTFhZmY1IiB0cmFuc2Zvcm09InRyYW5zbGF0ZSg0NTkuMzk1IDE0Mi4wNDcpIj5DZW50cmFsIHVuaXQgKENVKSw8dHNwYW4geD0iMTcuODU4IiB5PSIxMiI+dXNlciBwbGFuZTwvdHNwYW4+PC90ZXh0Pjx0ZXh0IHRyYW5zZm9ybT0idHJhbnNsYXRlKDY3MS41MzEgMjAwLjE1MykiIGZvbnQtc2l6ZT0iMTAiIGZpbGw9IiNmM2YzZjMiIGZvbnQtZmFtaWx5PSJSZWRIYXRUZXh0LCZxdW90O1JlZCBIYXQgVGV4dCZxdW90OyxPdmVycGFzcywmcXVvdDtIZWx2ZXRpY2EgTmV1ZSZxdW90OyxBcmlhbCxzYW5zLXNlcmlmIj4xMzVfT3BlblNoaWZ0XzAxMjE8L3RleHQ+PHBhdGggZmlsbD0ibm9uZSIgZD0iTTAgMTc3LjEzNmg3NjB2NDBIMHoiLz48cGF0aCBjbGFzcz0iYWY5NmJhY2ItNDJjMi00ZmI1LTkyYzMtMjA5MDU3M2UyNTljIiBkPSJNNDA1LjMyNCA3NUgzOTB2MjcuNWgtMTcuODI0Ii8+PHBhdGggY2xhc3M9ImIwMzBmNmY5LTdmZjctNGNmZi1hNjBmLThhNjc4ZDJjYjQ4NSIgZD0iTTQwMy44NjUgNzAuMDE0TDQxMi41IDc1bC04LjYzNSA0Ljk4NnYtOS45NzJ6TTM3My42MzUgOTcuNTE0TDM2NSAxMDIuNWw4LjYzNSA0Ljk4NnYtOS45NzJ6Ii8+PHBhdGggY2xhc3M9ImFmOTZiYWNiLTQyYzItNGZiNS05MmMzLTIwOTA1NzNlMjU5YyIgZD0iTTQwNS4zMjQgMTQ1SDM5MHYtMjcuNWgtMTcuODI0Ii8+PHBhdGggY2xhc3M9ImIwMzBmNmY5LTdmZjctNGNmZi1hNjBmLThhNjc4ZDJjYjQ4NSIgZD0iTTQwMy44NjUgMTQwLjAxNEw0MTIuNSAxNDVsLTguNjM1IDQuOTg2di05Ljk3MnpNMzczLjYzNSAxMTIuNTE0TDM2NSAxMTcuNWw4LjYzNSA0Ljk4NnYtOS45NzJ6Ii8+PGc+PHBhdGggY2xhc3M9ImFmOTZiYWNiLTQyYzItNGZiNS05MmMzLTIwOTA1NzNlMjU5YyIgZD0iTTIwMi44MzcgMTEwaC0xOC4xNDgiLz48cGF0aCBjbGFzcz0iYjAzMGY2ZjktN2ZmNy00Y2ZmLWE2MGYtOGE2NzhkMmNiNDg1IiBkPSJNMjAxLjM3OCAxMDUuMDE0bDguNjM1IDQuOTg2LTguNjM1IDQuOTg2di05Ljk3MnpNMTg2LjE0OCAxMDUuMDE0TDE3Ny41MTMgMTEwbDguNjM1IDQuOTg2di05Ljk3MnoiLz48L2c+PHBhdGggY2xhc3M9ImI2YjlhYzJlLTRhM2YtNGM1Yy1iNWU5LTY2ZmNhZGM0YmUzMSIgdHJhbnNmb3JtPSJyb3RhdGUoLTE4MCAyODcuNSAxMTApIiBkPSJNMjEyLjUgODBoMTUwdjYwaC0xNTB6Ii8+PHRleHQgY2xhc3M9ImE2NjFmOTY0LTk3ZmUtNDJhOC1hZjMzLWQ0OWFlNDkxYWZmNSIgdHJhbnNmb3JtPSJ0cmFuc2xhdGUoMjMzLjA0NiAxMTIuNTQ3KSI+RGlzdHJpYnV0ZWQgdW5pdCAoRFUpPC90ZXh0PjxwYXRoIGNsYXNzPSJiNmI5YWMyZS00YTNmLTRjNWMtYjVlOS02NmZjYWRjNGJlMzEiIHRyYW5zZm9ybT0icm90YXRlKC0xODAgMTAwIDExMCkiIGQ9Ik0yNSA4MGgxNTB2NjBIMjV6Ii8+PHRleHQgY2xhc3M9ImE2NjFmOTY0LTk3ZmUtNDJhOC1hZjMzLWQ0OWFlNDkxYWZmNSIgdHJhbnNmb3JtPSJ0cmFuc2xhdGUoNjAuNDUgMTEyLjU0NykiPlJhZGlvIHVuaXQgKFJVKTwvdGV4dD48L3N2Zz4=)

From the three components composing RAN, the CU and DU can be virtualized and implemented as cloud-native functions.

The CU and DU split architecture is driven by real-time computing and networking requirements. A DU can be seen as a real-time part of a telecommunication baseband unit. One distributed unit may aggregate several cells. A CU can be seen as a non-realtime part of a baseband unit, aggregating traffic from one or more distributed units.

A cell in the context of a DU can be seen as a real-time application performing intensive digital signal processing, data transfer, and algorithmic tasks. Cells often use hardware acceleration (FPGA, GPU, eASIC) for DSP processing offload, but there are also software-only implementations (FlexRAN), based on AVX-512 instructions.

Running cell application on COTS hardware requires the following features to be enabled:

-   Real-time kernel

-   CPU isolation

-   NUMA awareness

-   Huge pages memory management

-   Precision timing synchronization using PTP

-   AVX-512 instruction set (for Flexran and / or FPGA implementation)

-   Additional features depending on the RAN Operator requirements

Accessing hardware acceleration devices and high throughput network interface controllers by virtualized software applications requires use of SR-IOV and Passthrough PCI device virtualization.

In addition to the compute and acceleration requirements, DUs operate on multiple internal and external networks.

### The manifest structure {#cnf-manifest-structure_installing-du}

The profile is built from one cluster specific folder and one or more site-specific folders. This is done to address a deployment that includes remote worker nodes, with several sites belonging to the same cluster.

The \[`cluster-config`\](ran-profile/cluster-config) directory contains performance and PTP customizations based upon Operator deployments in \[`deploy`\](../feature-configs/deploy) folder.

The \[`site.1.fqdn`\](site.1.fqdn) folder contains site-specific network customizations.

### Prerequisites {#cnf-du-prerequisites_installing-du}

Before installing the Operators and deploying the DU, perform the following steps.

1.  Create a machine config pool for the RAN worker nodes. For example:

    ``` terminal
    cat <<EOF | oc apply -f -
    apiVersion: machineconfiguration.openshift.io/v1
    kind: MachineConfigPool
    metadata:
      name: worker-cnf
      labels:
        machineconfiguration.openshift.io/role: worker-cnf
    spec:
      machineConfigSelector:
        matchExpressions:
          - {
              key: machineconfiguration.openshift.io/role,
              operator: In,
              values: [worker-cnf, worker],
            }
      paused: false
      nodeSelector:
        matchLabels:
          node-role.kubernetes.io/worker-cnf: ""

    EOF
    ```

2.  Include the worker node in the above machine config pool by labeling it with the `node-role.kubernetes.io/worker-cnf` label:

    ``` terminal
    $ oc label --overwrite node/<your node name> node-role.kubernetes.io/worker-cnf=""
    ```

3.  Label the node as PTP slave (DU only):

    ``` terminal
    $ oc label --overwrite node/<your node name> ptp/slave=""
    ```

### SR-IOV configuration notes {#cnf-du-configuration-notes_installing-du}

The `SriovNetworkNodePolicy` object must be configured differently for different NIC models and placements.

+----------------------+-----------------------+-----------------------+
| **Manufacturer**     | **deviceType**        | **isRdma**            |
+----------------------+-----------------------+-----------------------+
| Intel                | vfio-pci or netdevice | false                 |
+----------------------+-----------------------+-----------------------+
| Mellanox             | netdevice             | structure             |
+----------------------+-----------------------+-----------------------+

: **Table 4**

In addition, when configuring the `nicSelector`, the `pfNames` value must match the intended interface name on the specific host.

If there is a mixed cluster where some of the nodes are deployed with Intel NICs and some with Mellanox, several SR-IOV configurations can be created with the same `resourceName`. The device plug-in will discover only the available ones and will put the capacity on the node accordingly.

## Installing the Operators {#cnf-installing-the-operators_installing-du}

### Installing the Performance Addon Operator {#cnf-installing-the-performnce-addon-operator_installing-du}

Install the Performance Addon Operator using the OpenShift Container Platform CLI.

**Procedure**

1.  Create the Performance Addon Operator namespace:

    ``` terminal
    cat <<EOF | oc apply -f -
    apiVersion: v1
    kind: Namespace
    metadata:
      labels:
        openshift.io/cluster-monitoring: "true"
      name: openshift-performance-addon-operator
      annotations:
        workload.openshift.io/allowed: management
    spec: {}

    EOF
    ```

2.  Apply the Operator group:

    ``` terminal
    cat <<EOF | oc apply -f -
    apiVersion: operators.coreos.com/v1
    kind: OperatorGroup
    metadata:
      name: performance-addon-operator
      namespace: openshift-performance-addon-operator

    EOF
    ```

3.  Run the following command to get the `channel` value required for the next step.

    ``` terminal
    $ oc get packagemanifest performance-addon-operator -n openshift-marketplace -o jsonpath='{.status.defaultChannel}'
    ```

    **Example output**

        4.6

4.  Apply the Subscription CR:

    **Example subscription**

    ``` terminal
    cat <<EOF | oc apply -f -
    apiVersion: operators.coreos.com/v1alpha1
    kind: Subscription
    metadata:
      name: openshift-performance-addon-operator-subscription
      namespace: openshift-performance-addon-operator
    spec:
      channel: "<channel>" 
      name: performance-addon-operator
      source: redhat-operators 
      sourceNamespace: openshift-marketplace
    EOF
    ```

    -   Specify the value you obtained in the previous step for the `status.defaultChannel` parameter.

    -   You must specify the `redhat-operators` value.

### Installing the Precision Time Protocol (PTP) Operator {#cnf-installing-the-precision-time-protocol-operator_installing-du}

Install the PTP Operator using the OpenShift Container Platform CLI or the web console.

**Procedure**

1.  Apply the Operator namespace:

    ``` terminal
    cat <<EOF | oc apply -f -
    apiVersion: v1
    kind: Namespace
    metadata:
      name: openshift-ptp
      annotations:
        workload.openshift.io/allowed: management
      labels:
        openshift.io/cluster-monitoring: "true"
    EOF
    ```

2.  Apply the Operator group:

    ``` terminal
    cat <<EOF | oc apply -f -
    apiVersion: operators.coreos.com/v1
    kind: OperatorGroup
    metadata:
      name: ptp-operators
      namespace: openshift-ptp
    spec:
      targetNamespaces:
        - openshift-ptp

    EOF
    ```

3.  Apply the subscription:

    ``` terminal
    cat <<EOF | oc apply -f -
    apiVersion: operators.coreos.com/v1alpha1
    kind: Subscription
    metadata:
      name: ptp-operator-subscription
      namespace: openshift-ptp
    spec:
      channel: "${OC_VERSION}"
      name: ptp-operator
      source: "redhat-operators"
      sourceNamespace: openshift-marketplace
    EOF
    ```

### Applying the Stream Control Transmission Protocol (SCTP) patch {#cnf-applying-the-stream-control-transmission-protocol-patch_installing-du}

Load and enable the SCTP kernel module on worker nodes in your cluster.

**Procedure**

1.  Apply the SCTP machine config patch:

    ``` terminal
    cat <<EOF | oc apply -f -
    apiVersion: machineconfiguration.openshift.io/v1
    kind: MachineConfig
    metadata:
      name: load-sctp-module
      labels:
        machineconfiguration.openshift.io/role: worker-cnf
    spec:
      config:
        ignition:
          version: 3.2.0
        storage:
          files:
            - path: /etc/modprobe.d/sctp-blacklist.conf
              mode: 0644
              overwrite: true
              contents:
                source: data:,
            - path: /etc/modules-load.d/sctp-load.conf
              mode: 0644
              overwrite: true
              contents:
                source: data:,sctp
    EOF
    ```

### Installing the SR-IOV Network Operator {#cnf-installing-the-sriov-network-operator_installing-du}

Install the SR-IOV Network Operator by using the OpenShift Container Platform CLI or the web console.

1.  Apply the SR-IOV Operator namespace:

    ``` terminal
    cat <<EOF | oc apply -f -
    apiVersion: v1
    kind: Namespace
    metadata:
      name: openshift-sriov-network-operator
      annotations:
        workload.openshift.io/allowed: management
    EOF
    ```

2.  Apply the SR-IOV Operator group:

    ``` terminal
    cat <<EOF | oc apply -f -
    apiVersion: operators.coreos.com/v1
    kind: OperatorGroup
    metadata:
      name: sriov-network-operators
      namespace: openshift-sriov-network-operator
    spec:
      targetNamespaces:
      - openshift-sriov-network-operator
    EOF
    ```

3.  Apply the SR-IOV Operator subscription:

    ``` terminal
    cat <<EOF | oc apply -f -
    apiVersion: operators.coreos.com/v1alpha1
    kind: Subscription
    metadata:
      name: sriov-network-operator-subscription
      namespace: openshift-sriov-network-operator
    spec:
      channel: "${OC_VERSION}"
      name: sriov-network-operator
      source: redhat-operators
      sourceNamespace: openshift-marketplace
    EOF
    ```

### Verifying your changes {#cnf-installing-the-operators-verifying-your-changes_installing-du}

Use the following command to verify the changes have been applied to the cluster:

``` terminal
$ oc wait mcp/worker-cnf --for condition="updated"
```

## Deploying the DU infrastructure profile {#cnf-deploying-the-du-infrastructure-profile_installing-du}

### Creating the Performance Addon Operator and DU performance profile {#cnf-creating-the-performance-addon-operator-and-du-performance-profile_installing-du}

1.  Create and apply the performance profile, for example:

    ``` terminal
    cat <<EOF |  oc apply -f -
    apiVersion: performance.openshift.io/v1
    kind: PerformanceProfile
    metadata:
    # This profile is for typical lab DELL R640 with 2 x 26 pcores
      name: perf-example
    spec:
      additionalKernelArgs:
      - nosmt
      cpu:
        # Temp. workaround for RT kernel bugs that consume too much
        # CPU power: add more isolated cores
        isolated: "1,3,5,7,9-51"  
        reserved: "0,2,4,6,8"     
      hugepages:
        defaultHugepagesSize: 1G
        pages:
        - count: 16   
          size: 1G
          node: 0
      nodeSelector:
        # Pay attention to the node label, create MCP accordingly
        node-role.kubernetes.io/worker-cnf: ""
      numa:
        topologyPolicy: "restricted"
      realTimeKernel:
        # For CU should be false
        enabled: true

    EOF
    ```

    -   Configure this line based upon the customer CPU hardware selected to run the DU.

    -   Configure this line based upon the customer CPU hardware selected to run the DU.

    -   Configure this line based upon the customer memory configuration selected to run the DU.

2.  Use the following command to verify the changes have been applied to the cluster:

    ``` terminal
    $ oc wait mcp/worker-cnf --for condition="updated"
    ```

### Creating the PTP Operator and slave profile {#cnf-creating-the-ptp-operator-and-slave-profile_installing-du}

1.  Apply the PTP configuration, for example:

    ``` terminal
    cat <<EOF | oc apply -f -
    apiVersion: ptp.openshift.io/v1
    kind: PtpConfig
    metadata:
      name: slave
      namespace: openshift-ptp
    spec:
      profile:
      - name: "slave"
    # The interface name is hardware-specific
        interface: "eno1" 
        ptp4lOpts: "-2 -s --summary_interval -4" 
        phc2sysOpts: "-a -r -n 24" 
        ptp4lConf: |
          [global]
          #
          # Default Data Set
          #
          twoStepFlag 1
          slaveOnly 0
          priority1 128
          priority2 128
          domainNumber 24 
          #utc_offset 37
          clockClass 248
          clockAccuracy 0xFE
          offsetScaledLogVariance 0xFFFF
          free_running 0
          freq_est_interval 1
          dscp_event 0
          dscp_general 0
          dataset_comparison ieee1588
          G.8275.defaultDS.localPriority 128
          #
          # Port Data Set
          #
          logAnnounceInterval -3 
          logSyncInterval -4 
          logMinDelayReqInterval -4 
          logMinPdelayReqInterval -4 
          announceReceiptTimeout 3 
          syncReceiptTimeout 0
          delayAsymmetry 0
          fault_reset_interval 4
          neighborPropDelayThresh 20000000
          masterOnly 0
          G.8275.portDS.localPriority 128
          #
          # Run time options
          #
          assume_two_step 0
          logging_level 6
          path_trace_enabled 0
          follow_up_info 0
          hybrid_e2e 0
          inhibit_multicast_service 0
          net_sync_monitor 0
          tc_spanning_tree 0
          tx_timestamp_timeout 1
          unicast_listen 0
          unicast_master_table 0
          unicast_req_duration 3600
          use_syslog 1
          verbose 0
          summary_interval 0
          kernel_leap 1
          check_fup_sync 0
          #
          # Servo Options
          #
          pi_proportional_const 0.0
          pi_integral_const 0.0
          pi_proportional_scale 0.0
          pi_proportional_exponent -0.3
          pi_proportional_norm_max 0.7
          pi_integral_scale 0.0
          pi_integral_exponent 0.4
          pi_integral_norm_max 0.3
          step_threshold 0.0
          first_step_threshold 0.00002
          max_frequency 900000000
          clock_servo pi
          sanity_freq_limit 200000000
          ntpshm_segment 0
          #
          # Transport options
          #
          transportSpecific 0x0
          ptp_dst_mac 01:1B:19:00:00:00
          p2p_dst_mac 01:80:C2:00:00:0E
          udp_ttl 1
          udp6_scope 0x0E
          uds_address /var/run/ptp4l
          #
          # Default interface options
          #
          clock_type OC
          network_transport UDPv4
          delay_mechanism E2E
          time_stamping hardware
          tsproc_mode filter
          delay_filter moving_median
          delay_filter_length 10
          egressLatency 0
          ingressLatency 0
          boundary_clock_jbod 0
          #
          # Clock description
          #
          productDescription ;;
          revisionData ;;
          manufacturerIdentity 00:00:00
          userDescription ;
          timeSource 0xA0
      recommend:
      - profile: "slave"
        priority: 4
        match:
        - nodeLabel: "ptp/slave"

    EOF
    ```

    -   The interface selected needs to match the Linux interface name.

    -   `-2` configures Ethernet encapsulation of PTP. `--summary_interval -4` sets the logging interval. This is currently set to match `logSyncInterval -4`.

    -   `-n 24` must match the `domainNumber 24`.

    -   `domainNumber 24` must match the `-n 24`.

    -   These variables are set to enable the G.8275.1 profile for PTP.

### Creating the SR-IOV Operator and associated profiles {#cnf-creating-the-sriov-operator-and-associated-profiles_installing-du}

1.  Apply the SR-IOV network node policy, for example:

    ``` terminal
    cat <<EOF |  oc apply -f -
    apiVersion: sriovnetwork.openshift.io/v1
    kind: SriovNetworkNodePolicy
    metadata:
      name: policy-mh-dpdk-site-1-fqdn-worker1
      namespace: openshift-sriov-network-operator
    spec:
    # This works for Intel based NICs. 
    # For Mellanox please change to:
    #     deviceType: netdevice
    #     isRdma: true
      deviceType: vfio-pci
      isRdma: false
      nicSelector:
    # The exact physical function name must match the hardware used
        pfNames: ["ens1f1"] 
      nodeSelector:
        node-role.kubernetes.io/worker-cnf: ""
        feature.node.kubernetes.io/network-sriov.capable: "true"
      numVfs: 4
      priority: 10
      resourceName: mh_u_site_1_fqdn_worker1

    EOF
    ```

    -   This file works for Intel and must change for Mellanox, as described in *SR-IOV configuration notes*.

    -   Must be updated with the specific device on the server.

2.  Create the SR-IOV network, for example:

    ``` terminal
    cat <<EOF | oc apply -f -
    apiVersion: sriovnetwork.openshift.io/v1
    kind: SriovNetwork
    metadata:
      name: mh-net-u-site-1-fqdn-worker1
      namespace: openshift-sriov-network-operator
    spec:
      ipam:  |
        {
        }
      networkNamespace: mh-net-ns-site-1-fqdn-worker1
      resourceName: mh_u_site_1_fqdn_worker1
      vlan: 100  
    ---
    apiVersion: v1
    kind: Namespace
    metadata:
        name: mh-net-ns-site-1-fqdn-worker1

    EOF
    ```

    -   Modify this line to match the DU’s networking.

## Modifying and applying the default profile {#cnf-modifying-and-applying-the-default-profile_installing-du}

You can apply the profile manually or with the toolset of your choice, such as ArgoCD.

!!! note
    This procedure applies the DU profile step-by-step. If the profile is pulled together into a single project and applied in one step, issues will occur between the MCO and the SRIOV operators if an Intel NIC is used for networking traffic. To avoid a race condition between the MCO and the SRIOV Operators, it is recommended that the DU application be applied in three steps:
    
    1.  Apply the profile without SRIOV.
    
    2.  Wait for the cluster to settle.
    
    3.  Apply the SRIOV portion.
