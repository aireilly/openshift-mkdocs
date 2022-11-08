# Planning your environment according to object maximums

Consider the following tested object maximums when you plan your OpenShift Container Platform cluster.

These guidelines are based on the largest possible cluster. For smaller clusters, the maximums are lower. There are many factors that influence the stated thresholds, including the etcd version or storage data format.

!!! important
    These guidelines apply to OpenShift Container Platform with software-defined networking (SDN), not Open Virtual Network (OVN).

In most cases, exceeding these numbers results in lower overall performance. It does not necessarily mean that the cluster will fail.

## OpenShift Container Platform tested cluster maximums for major releases

Tested Cloud Platforms for OpenShift Container Platform 3.x: Red Hat OpenStack Platform (RHOSP), Amazon Web Services and Microsoft Azure. Tested Cloud Platforms for OpenShift Container Platform 4.x: Amazon Web Services, Microsoft Azure and Google Cloud Platform.

+-------------------------------------------------------+-----------------------------------------------------+------------------------------------------------------------------------+
| Maximum type                                          | 3.x tested maximum                                  | 4.x tested maximum                                                     |
+=======================================================+=====================================================+========================================================================+
| Number of nodes                                       | 2,000                                               | 2,000 <sup>\[1\]</sup>                                                 |
+-------------------------------------------------------+-----------------------------------------------------+------------------------------------------------------------------------+
| Number of pods <sup>\[2\]</sup>                       | 150,000                                             | 150,000                                                                |
+-------------------------------------------------------+-----------------------------------------------------+------------------------------------------------------------------------+
| Number of pods per node                               | 250                                                 | 500 <sup>\[3\]</sup>                                                   |
+-------------------------------------------------------+-----------------------------------------------------+------------------------------------------------------------------------+
| Number of pods per core                               | There is no default value.                          | There is no default value.                                             |
+-------------------------------------------------------+-----------------------------------------------------+------------------------------------------------------------------------+
| Number of namespaces <sup>\[4\]</sup>                 | 10,000                                              | 10,000                                                                 |
+-------------------------------------------------------+-----------------------------------------------------+------------------------------------------------------------------------+
| Number of builds                                      | 10,000 (Default pod RAM 512 Mi) - Pipeline Strategy | 10,000 (Default pod RAM 512 Mi) - Source-to-Image (S2I) build strategy |
+-------------------------------------------------------+-----------------------------------------------------+------------------------------------------------------------------------+
| Number of pods per namespace <sup>\[5\]</sup>         | 25,000                                              | 25,000                                                                 |
+-------------------------------------------------------+-----------------------------------------------------+------------------------------------------------------------------------+
| Number of routes and back ends per Ingress Controller | 2,000 per router                                    | 2,000 per router                                                       |
+-------------------------------------------------------+-----------------------------------------------------+------------------------------------------------------------------------+
| Number of secrets                                     | 80,000                                              | 80,000                                                                 |
+-------------------------------------------------------+-----------------------------------------------------+------------------------------------------------------------------------+
| Number of config maps                                 | 90,000                                              | 90,000                                                                 |
+-------------------------------------------------------+-----------------------------------------------------+------------------------------------------------------------------------+
| Number of services <sup>\[6\]</sup>                   | 10,000                                              | 10,000                                                                 |
+-------------------------------------------------------+-----------------------------------------------------+------------------------------------------------------------------------+
| Number of services per namespace                      | 5,000                                               | 5,000                                                                  |
+-------------------------------------------------------+-----------------------------------------------------+------------------------------------------------------------------------+
| Number of back-ends per service                       | 5,000                                               | 5,000                                                                  |
+-------------------------------------------------------+-----------------------------------------------------+------------------------------------------------------------------------+
| Number of deployments per namespace <sup>\[5\]</sup>  | 2,000                                               | 2,000                                                                  |
+-------------------------------------------------------+-----------------------------------------------------+------------------------------------------------------------------------+
| Number of build configs                               | 12,000                                              | 12,000                                                                 |
+-------------------------------------------------------+-----------------------------------------------------+------------------------------------------------------------------------+
| Number of custom resource definitions (CRD)           | There is no default value.                          | 512 <sup>\[7\]</sup>                                                   |
+-------------------------------------------------------+-----------------------------------------------------+------------------------------------------------------------------------+

**Table 1**

1.  Pause pods were deployed to stress the control plane components of OpenShift Container Platform at 2000 node scale.

2.  The pod count displayed here is the number of test pods. The actual number of pods depends on the application’s memory, CPU, and storage requirements.

3.  This was tested on a cluster with 100 worker nodes with 500 pods per worker node. The default `maxPods` is still 250. To get to 500 `maxPods`, the cluster must be created with a `maxPods` set to `500` using a custom kubelet config. If you need 500 user pods, you need a `hostPrefix` of `22` because there are 10-15 system pods already running on the node. The maximum number of pods with attached persistent volume claims (PVC) depends on storage backend from where PVC are allocated. In our tests, only OpenShift Data Foundation v4 (OCS v4) was able to satisfy the number of pods per node discussed in this document.

4.  When there are a large number of active projects, etcd might suffer from poor performance if the keyspace grows excessively large and exceeds the space quota. Periodic maintenance of etcd, including defragmentation, is highly recommended to free etcd storage.

5.  There are a number of control loops in the system that must iterate over all objects in a given namespace as a reaction to some changes in state. Having a large number of objects of a given type in a single namespace can make those loops expensive and slow down processing given state changes. The limit assumes that the system has enough CPU, memory, and disk to satisfy the application requirements.

6.  Each service port and each service back-end has a corresponding entry in iptables. The number of back-ends of a given service impact the size of the endpoints objects, which impacts the size of data that is being sent all over the system.

7.  OpenShift Container Platform has a limit of 512 total custom resource definitions (CRD), including those installed by OpenShift Container Platform, products integrating with OpenShift Container Platform and user created CRDs. If there are more than 512 CRDs created, then there is a possibility that `oc` commands requests may be throttled.

!!! note
    Red Hat does not provide direct guidance on sizing your OpenShift Container Platform cluster. This is because determining whether your cluster is within the supported bounds of OpenShift Container Platform requires careful consideration of all the multidimensional factors that limit the cluster scale.

## OpenShift Container Platform environment and configuration on which the cluster maximums are tested

### AWS cloud platform

+-------------------------------------+-------------+--------+----------+-----------+----------------------+-------------------------------+-----------+
| Node                                | Flavor      | vCPU   | RAM(GiB) | Disk type | Disk size(GiB)/IOS   | Count                         | Region    |
+=====================================+=============+========+==========+===========+======================+===============================+===========+
| Control plane/etcd <sup>\[1\]</sup> | r5.4xlarge  | 16     | 128      | gp3       | 220                  | 3                             | us-west-2 |
+-------------------------------------+-------------+--------+----------+-----------+----------------------+-------------------------------+-----------+
| Infra <sup>\[2\]</sup>              | m5.12xlarge | 48     | 192      | gp3       | 100                  | 3                             | us-west-2 |
+-------------------------------------+-------------+--------+----------+-----------+----------------------+-------------------------------+-----------+
| Workload <sup>\[3\]</sup>           | m5.4xlarge  | 16     | 64       | gp3       | 500 <sup>\[4\]</sup> | 1                             | us-west-2 |
+-------------------------------------+-------------+--------+----------+-----------+----------------------+-------------------------------+-----------+
| Compute                             | m5.2xlarge  | 8      | 32       | gp3       | 100                  | 3/25/250/500 <sup>\[5\]</sup> | us-west-2 |
+-------------------------------------+-------------+--------+----------+-----------+----------------------+-------------------------------+-----------+

**Table 2**

1.  gp3 disks with a baseline performance of 3000 IOPS and 125 MiB per second are used for control plane/etcd nodes because etcd is latency sensitive. gp3 volumes do not use burst performance.

2.  Infra nodes are used to host Monitoring, Ingress, and Registry components to ensure they have enough resources to run at large scale.

3.  Workload node is dedicated to run performance and scalability workload generators.

4.  Larger disk size is used so that there is enough space to store the large amounts of data that is collected during the performance and scalability test run.

5.  Cluster is scaled in iterations and performance and scalability tests are executed at the specified node counts.

### IBM Power platform

+-------------------------------------+----------+----------+-----------+-----------------------+---------------------------+
| Node                                | vCPU     | RAM(GiB) | Disk type | Disk size(GiB)/IOS    | Count                     |
+=====================================+==========+==========+===========+=======================+===========================+
| Control plane/etcd <sup>\[1\]</sup> | 16       | 32       | io1       | 120 / 10 IOPS per GiB | 3                         |
+-------------------------------------+----------+----------+-----------+-----------------------+---------------------------+
| Infra <sup>\[2\]</sup>              | 16       | 64       | gp2       | 120                   | 2                         |
+-------------------------------------+----------+----------+-----------+-----------------------+---------------------------+
| Workload <sup>\[3\]</sup>           | 16       | 256      | gp2       | 120 <sup>\[4\]</sup>  | 1                         |
+-------------------------------------+----------+----------+-----------+-----------------------+---------------------------+
| Compute                             | 16       | 64       | gp2       | 120                   | 2 to 100 <sup>\[5\]</sup> |
+-------------------------------------+----------+----------+-----------+-----------------------+---------------------------+

**Table 3**

1.  io1 disks with 120 / 10 IOPS per GiB are used for control plane/etcd nodes as etcd is I/O intensive and latency sensitive.

2.  Infra nodes are used to host Monitoring, Ingress, and Registry components to ensure they have enough resources to run at large scale.

3.  Workload node is dedicated to run performance and scalability workload generators.

4.  Larger disk size is used so that there is enough space to store the large amounts of data that is collected during the performance and scalability test run.

5.  Cluster is scaled in iterations.

### IBM Z platform

+---------------------------------------+-----------------------+--------------------------+-----------+--------------------+-----------------------------------------------+
| Node                                  | vCPU <sup>\[4\]</sup> | RAM(GiB)<sup>\[5\]</sup> | Disk type | Disk size(GiB)/IOS | Count                                         |
+=======================================+=======================+==========================+===========+====================+===============================================+
| Control plane/etcd <sup>\[1,2\]</sup> | 8                     | 32                       | ds8k      | 300 / LCU 1        | 3                                             |
+---------------------------------------+-----------------------+--------------------------+-----------+--------------------+-----------------------------------------------+
| Compute <sup>\[1,3\]</sup>            | 8                     | 32                       | ds8k      | 150 / LCU 2        | 4 nodes (scaled to 100/250/500 pods per node) |
+---------------------------------------+-----------------------+--------------------------+-----------+--------------------+-----------------------------------------------+

**Table 4**

1.  Nodes are distributed between two logical control units (LCUs) to optimize disk I/O load of the control plane/etcd nodes as etcd is I/O intensive and latency sensitive. Etcd I/O demand should not interfere with other workloads.

2.  Four compute nodes are used for the tests running several iterations with 100/250/500 pods at the same time. First, idling pods were used to evaluate if pods can be instanced. Next, a network and CPU demanding client/server workload were used to evaluate the stability of the system under stress. Client and server pods were pairwise deployed and each pair was spread over two compute nodes.

3.  No separate workload node was used. The workload simulates a microservice workload between two compute nodes.

4.  Physical number of processors used is six Integrated Facilities for Linux (IFLs).

5.  Total physical memory used is 512 GiB.

## How to plan your environment according to tested cluster maximums

!!! important
    Oversubscribing the physical resources on a node affects resource guarantees the Kubernetes scheduler makes during pod placement. Learn what measures you can take to avoid memory swapping.
    
    Some of the tested maximums are stretched only in a single dimension. They will vary when many objects are running on the cluster.
    
    The numbers noted in this documentation are based on Red Hat's test methodology, setup, configuration, and tunings. These numbers can vary based on your own individual setup and environments.

While planning your environment, determine how many pods are expected to fit per node:

    required pods per cluster / pods per node = total number of nodes needed

The current maximum number of pods per node is 250. However, the number of pods that fit on a node is dependent on the application itself. Consider the application’s memory, CPU, and storage requirements, as described in *How to plan your environment according to application requirements*.

**Example scenario**

If you want to scope your cluster for 2200 pods per cluster, you would need at least five nodes, assuming that there are 500 maximum pods per node:

    2200 / 500 = 4.4

If you increase the number of nodes to 20, then the pod distribution changes to 110 pods per node:

    2200 / 20 = 110

Where:

    required pods per cluster / total number of nodes = expected pods per node

## How to plan your environment according to application requirements

Consider an example application environment:

+-------------+--------------+-------------+-------------+--------------------+
| Pod type    | Pod quantity | Max memory  | CPU cores   | Persistent storage |
+=============+==============+=============+=============+====================+
| apache      | 100          | 500 MB      | 0.5         | 1 GB               |
+-------------+--------------+-------------+-------------+--------------------+
| node.js     | 200          | 1 GB        | 1           | 1 GB               |
+-------------+--------------+-------------+-------------+--------------------+
| postgresql  | 100          | 1 GB        | 2           | 10 GB              |
+-------------+--------------+-------------+-------------+--------------------+
| JBoss EAP   | 100          | 1 GB        | 1           | 1 GB               |
+-------------+--------------+-------------+-------------+--------------------+

**Table 5**

Extrapolated requirements: 550 CPU cores, 450GB RAM, and 1.4TB storage.

Instance size for nodes can be modulated up or down, depending on your preference. Nodes are often resource overcommitted. In this deployment scenario, you can choose to run additional smaller nodes or fewer larger nodes to provide the same amount of resources. Factors such as operational agility and cost-per-instance should be considered.

+------------------+-----------------+-----------------+-----------------+
| Node type        | Quantity        | CPUs            | RAM (GB)        |
+==================+=================+=================+=================+
| Nodes (option 1) | 100             | 4               | 16              |
+------------------+-----------------+-----------------+-----------------+
| Nodes (option 2) | 50              | 8               | 32              |
+------------------+-----------------+-----------------+-----------------+
| Nodes (option 3) | 25              | 16              | 64              |
+------------------+-----------------+-----------------+-----------------+

**Table 6**

Some applications lend themselves well to overcommitted environments, and some do not. Most Java applications and applications that use huge pages are examples of applications that would not allow for overcommitment. That memory can not be used for other applications. In the example above, the environment would be roughly 30 percent overcommitted, a common ratio.

The application pods can access a service either by using environment variables or DNS. If using environment variables, for each active service the variables are injected by the kubelet when a pod is run on a node. A cluster-aware DNS server watches the Kubernetes API for new services and creates a set of DNS records for each one. If DNS is enabled throughout your cluster, then all pods should automatically be able to resolve services by their DNS name. Service discovery using DNS can be used in case you must go beyond 5000 services. When using environment variables for service discovery, the argument list exceeds the allowed length after 5000 services in a namespace, then the pods and deployments will start failing. Disable the service links in the deployment’s service specification file to overcome this:

``` yaml
---
apiVersion: template.openshift.io/v1
kind: Template
metadata:
  name: deployment-config-template
  creationTimestamp:
  annotations:
    description: This template will create a deploymentConfig with 1 replica, 4 env vars and a service.
    tags: ''
objects:
- apiVersion: apps.openshift.io/v1
  kind: DeploymentConfig
  metadata:
    name: deploymentconfig${IDENTIFIER}
  spec:
    template:
      metadata:
        labels:
          name: replicationcontroller${IDENTIFIER}
      spec:
        enableServiceLinks: false
        containers:
        - name: pause${IDENTIFIER}
          image: "${IMAGE}"
          ports:
          - containerPort: 8080
            protocol: TCP
          env:
          - name: ENVVAR1_${IDENTIFIER}
            value: "${ENV_VALUE}"
          - name: ENVVAR2_${IDENTIFIER}
            value: "${ENV_VALUE}"
          - name: ENVVAR3_${IDENTIFIER}
            value: "${ENV_VALUE}"
          - name: ENVVAR4_${IDENTIFIER}
            value: "${ENV_VALUE}"
          resources: {}
          imagePullPolicy: IfNotPresent
          capabilities: {}
          securityContext:
            capabilities: {}
            privileged: false
        restartPolicy: Always
        serviceAccount: ''
    replicas: 1
    selector:
      name: replicationcontroller${IDENTIFIER}
    triggers:
    - type: ConfigChange
    strategy:
      type: Rolling
- apiVersion: v1
  kind: Service
  metadata:
    name: service${IDENTIFIER}
  spec:
    selector:
      name: replicationcontroller${IDENTIFIER}
    ports:
    - name: serviceport${IDENTIFIER}
      protocol: TCP
      port: 80
      targetPort: 8080
    portalIP: ''
    type: ClusterIP
    sessionAffinity: None
  status:
    loadBalancer: {}
parameters:
- name: IDENTIFIER
  description: Number to append to the name of resources
  value: '1'
  required: true
- name: IMAGE
  description: Image to use for deploymentConfig
  value: gcr.io/google-containers/pause-amd64:3.0
  required: false
- name: ENV_VALUE
  description: Value to use for environment variables
  generate: expression
  from: "[A-Za-z0-9]{255}"
  required: false
labels:
  template: deployment-config-template
```

The number of application pods that can run in a namespace is dependent on the number of services and the length of the service name when the environment variables are used for service discovery. `ARG_MAX` on the system defines the maximum argument length for a new process and it is set to `2097152 KiB` by default. The Kubelet injects environment variables in to each pod scheduled to run in the namespace including:

-   `<SERVICE_NAME>_SERVICE_HOST=<IP>`

-   `<SERVICE_NAME>_SERVICE_PORT=<PORT>`

-   `<SERVICE_NAME>_PORT=tcp://<IP>:<PORT>`

-   `<SERVICE_NAME>_PORT_<PORT>_TCP=tcp://<IP>:<PORT>`

-   `<SERVICE_NAME>_PORT_<PORT>_TCP_PROTO=tcp`

-   `<SERVICE_NAME>_PORT_<PORT>_TCP_PORT=<PORT>`

-   `<SERVICE_NAME>_PORT_<PORT>_TCP_ADDR=<ADDR>`

The pods in the namespace will start to fail if the argument length exceeds the allowed value and the number of characters in a service name impacts it. For example, in a namespace with 5000 services, the limit on the service name is 33 characters, which enables you to run 5000 pods in the namespace.
