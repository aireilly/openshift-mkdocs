# Scaling the Cluster Monitoring Operator

OpenShift Container Platform exposes metrics that the Cluster Monitoring Operator collects and stores in the Prometheus-based monitoring stack. As an administrator, you can view dashboards for system resources, containers, and components metrics in the OpenShift Container Platform web console by navigating to **Observe** → **Dashboards**.

## Prometheus database storage requirements {#prometheus-database-storage-requirements_cluster-monitoring-operator}

Red Hat performed various tests for different scale sizes.

!!! note
    The Prometheus storage requirements below are not prescriptive. Higher resource consumption might be observed in your cluster depending on workload activity and resource use.

+-----------------+----------------+-----------------------------------+---------------------------------------+----------------------------+--------------------------+
| Number of Nodes | Number of pods | Prometheus storage growth per day | Prometheus storage growth per 15 days | RAM Space (per scale size) | Network (per tsdb chunk) |
+=================+================+===================================+=======================================+============================+==========================+
| 50              | 1800           | 6.3 GB                            | 94 GB                                 | 6 GB                       | 16 MB                    |
+-----------------+----------------+-----------------------------------+---------------------------------------+----------------------------+--------------------------+
| 100             | 3600           | 13 GB                             | 195 GB                                | 10 GB                      | 26 MB                    |
+-----------------+----------------+-----------------------------------+---------------------------------------+----------------------------+--------------------------+
| 150             | 5400           | 19 GB                             | 283 GB                                | 12 GB                      | 36 MB                    |
+-----------------+----------------+-----------------------------------+---------------------------------------+----------------------------+--------------------------+
| 200             | 7200           | 25 GB                             | 375 GB                                | 14 GB                      | 46 MB                    |
+-----------------+----------------+-----------------------------------+---------------------------------------+----------------------------+--------------------------+

: **Table 1: Prometheus Database storage requirements based on number of nodes/pods in the cluster**

Approximately 20 percent of the expected size was added as overhead to ensure that the storage requirements do not exceed the calculated value.

The above calculation is for the default OpenShift Container Platform Cluster Monitoring Operator.

!!! note
    CPU utilization has minor impact. The ratio is approximately 1 core out of 40 per 50 nodes and 1800 pods.

**Recommendations for OpenShift Container Platform**

-   Use at least three infrastructure (infra) nodes.

-   Use at least three **openshift-container-storage** nodes with non-volatile memory express (NVMe) drives.

## Configuring cluster monitoring {#configuring-cluster-monitoring_cluster-monitoring-operator}

You can increase the storage capacity for the Prometheus component in the cluster monitoring stack.

**Procedure**

To increase the storage capacity for Prometheus:

1.  Create a YAML configuration file, `cluster-monitoring-config.yaml`. For example:

    ``` yaml
    apiVersion: v1
    kind: ConfigMap
    data:
      config.yaml: |
        prometheusK8s:
          retention: {{PROMETHEUS_RETENTION_PERIOD}} 
          nodeSelector:
            node-role.kubernetes.io/infra: ""
          volumeClaimTemplate:
            spec:
              storageClassName: {{STORAGE_CLASS}} 
              resources:
                requests:
                  storage: {{PROMETHEUS_STORAGE_SIZE}} 
        alertmanagerMain:
          nodeSelector:
            node-role.kubernetes.io/infra: ""
          volumeClaimTemplate:
            spec:
              storageClassName: {{STORAGE_CLASS}} 
              resources:
                requests:
                  storage: {{ALERTMANAGER_STORAGE_SIZE}} 
    metadata:
      name: cluster-monitoring-config
      namespace: openshift-monitoring
    ```

    -   A typical value is `PROMETHEUS_RETENTION_PERIOD=15d`. Units are measured in time using one of these suffixes: s, m, h, d.

    -   The storage class for your cluster.

    -   A typical value is `PROMETHEUS_STORAGE_SIZE=2000Gi`. Storage values can be a plain integer or as a fixed-point integer using one of these suffixes: E, P, T, G, M, K. You can also use the power-of-two equivalents: Ei, Pi, Ti, Gi, Mi, Ki.

    -   A typical value is `ALERTMANAGER_STORAGE_SIZE=20Gi`. Storage values can be a plain integer or as a fixed-point integer using one of these suffixes: E, P, T, G, M, K. You can also use the power-of-two equivalents: Ei, Pi, Ti, Gi, Mi, Ki.

2.  Add values for the retention period, storage class, and storage sizes.

3.  Save the file.

4.  Apply the changes by running:

    ``` terminal
    $ oc create -f cluster-monitoring-config.yaml
    ```
