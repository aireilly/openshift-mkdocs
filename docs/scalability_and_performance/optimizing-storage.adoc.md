# Optimizing storage

Optimizing storage helps to minimize storage use across all resources. By optimizing storage, administrators help ensure that existing storage resources are working in an efficient manner.

## Available persistent storage options

Understand your persistent storage options so that you can optimize your OpenShift Container Platform environment.

+--------------+------------------------------------------------------------------------------------------------------------------------------------------------+--------------------------------------------------------------------------------------------------------------------------+
| Storage type | Description                                                                                                                                    | Examples                                                                                                                 |
+==============+================================================================================================================================================+==========================================================================================================================+
| Block        | -   Presented to the operating system (OS) as a block device                                                                                   | AWS EBS and VMware vSphere support dynamic persistent volume (PV) provisioning natively in OpenShift Container Platform. |
|              |                                                                                                                                                |                                                                                                                          |
|              | -   Suitable for applications that need full control of storage and operate at a low level on files bypassing the file system                  |                                                                                                                          |
|              |                                                                                                                                                |                                                                                                                          |
|              | -   Also referred to as a Storage Area Network (SAN)                                                                                           |                                                                                                                          |
|              |                                                                                                                                                |                                                                                                                          |
|              | -   Non-shareable, which means that only one client at a time can mount an endpoint of this type                                               |                                                                                                                          |
+--------------+------------------------------------------------------------------------------------------------------------------------------------------------+--------------------------------------------------------------------------------------------------------------------------+
| File         | -   Presented to the OS as a file system export to be mounted                                                                                  | RHEL NFS, NetApp NFS <sup>\[1\]</sup>, and Vendor NFS                                                                    |
|              |                                                                                                                                                |                                                                                                                          |
|              | -   Also referred to as Network Attached Storage (NAS)                                                                                         |                                                                                                                          |
|              |                                                                                                                                                |                                                                                                                          |
|              | -   Concurrency, latency, file locking mechanisms, and other capabilities vary widely between protocols, implementations, vendors, and scales. |                                                                                                                          |
+--------------+------------------------------------------------------------------------------------------------------------------------------------------------+--------------------------------------------------------------------------------------------------------------------------+
| Object       | -   Accessible through a REST API endpoint                                                                                                     | AWS S3                                                                                                                   |
|              |                                                                                                                                                |                                                                                                                          |
|              | -   Configurable for use in the OpenShift Container Platform Registry                                                                          |                                                                                                                          |
|              |                                                                                                                                                |                                                                                                                          |
|              | -   Applications must build their drivers into the application and/or container.                                                               |                                                                                                                          |
+--------------+------------------------------------------------------------------------------------------------------------------------------------------------+--------------------------------------------------------------------------------------------------------------------------+

**Table 1: Available storage options**

1.  NetApp NFS supports dynamic PV provisioning when using the Trident plug-in.

!!! important
    Currently, CNS is not supported in OpenShift Container Platform 4.11.

## Recommended configurable storage technology

The following table summarizes the recommended and configurable storage technologies for the given OpenShift Container Platform cluster application.

+--------------+-----------------+-----------------+--------------+------------------+--------------------------+--------------------------+------------------------------+
| Storage type | ROX<sup>1</sup> | RWX<sup>2</sup> | Registry     | Scaled registry  | Metrics<sup>3</sup>      | Logging                  | Apps                         |
+==============+=================+=================+==============+==================+==========================+==========================+==============================+
| Block        | Yes<sup>4</sup> | No              | Configurable | Not configurable | Recommended              | Recommended              | Recommended                  |
+--------------+-----------------+-----------------+--------------+------------------+--------------------------+--------------------------+------------------------------+
| File         | Yes<sup>4</sup> | Yes             | Configurable | Configurable     | Configurable<sup>5</sup> | Configurable<sup>6</sup> | Recommended                  |
+--------------+-----------------+-----------------+--------------+------------------+--------------------------+--------------------------+------------------------------+
| Object       | Yes             | Yes             | Recommended  | Recommended      | Not configurable         | Not configurable         | Not configurable<sup>7</sup> |
+--------------+-----------------+-----------------+--------------+------------------+--------------------------+--------------------------+------------------------------+

**Table 2: Recommended and configurable storage technology**

!!! note
    A scaled registry is an OpenShift Container Platform registry where two or more pod replicas are running.

### Specific application storage recommendations

!!! important
    Testing shows issues with using the NFS server on Red Hat Enterprise Linux (RHEL) as storage backend for core services. This includes the OpenShift Container Registry and Quay, Prometheus for monitoring storage, and Elasticsearch for logging storage. Therefore, using RHEL NFS to back PVs used by core services is not recommended.
    
    Other NFS implementations on the marketplace might not have these issues. Contact the individual NFS implementation vendor for more information on any testing that was possibly completed against these OpenShift Container Platform core components.

#### Registry

In a non-scaled/high-availability (HA) OpenShift Container Platform registry cluster deployment:

-   The storage technology does not have to support RWX access mode.

-   The storage technology must ensure read-after-write consistency.

-   The preferred storage technology is object storage followed by block storage.

-   File storage is not recommended for OpenShift Container Platform registry cluster deployment with production workloads.

#### Scaled registry

In a scaled/HA OpenShift Container Platform registry cluster deployment:

-   The storage technology must support RWX access mode.

-   The storage technology must ensure read-after-write consistency.

-   The preferred storage technology is object storage.

-   Amazon Simple Storage Service (Amazon S3), Google Cloud Storage (GCS), Microsoft Azure Blob Storage, and OpenStack Swift are supported.

-   Object storage should be S3 or Swift compliant.

-   For non-cloud platforms, such as vSphere and bare metal installations, the only configurable technology is file storage.

-   Block storage is not configurable.

#### Metrics

In an OpenShift Container Platform hosted metrics cluster deployment:

-   The preferred storage technology is block storage.

-   Object storage is not configurable.

!!! important
    It is not recommended to use file storage for a hosted metrics cluster deployment with production workloads.

#### Logging

In an OpenShift Container Platform hosted logging cluster deployment:

-   The preferred storage technology is block storage.

-   Object storage is not configurable.

#### Applications

Application use cases vary from application to application, as described in the following examples:

-   Storage technologies that support dynamic PV provisioning have low mount time latencies, and are not tied to nodes to support a healthy cluster.

-   Application developers are responsible for knowing and understanding the storage requirements for their application, and how it works with the provided storage to ensure that issues do not occur when an application scales or interacts with the storage layer.

### Other specific application storage recommendations

!!! important
    It is not recommended to use RAID configurations on `Write` intensive workloads, such as `etcd`. If you are running `etcd` with a RAID configuration, you might be at risk of encountering performance issues with your workloads.

-   Red Hat OpenStack Platform (RHOSP) Cinder: RHOSP Cinder tends to be adept in ROX access mode use cases.

-   Databases: Databases (RDBMSs, NoSQL DBs, etc.) tend to perform best with dedicated block storage.

-   The etcd database must have enough storage and adequate performance capacity to enable a large cluster. Information about monitoring and benchmarking tools to establish ample storage and a high-performance environment is described in *Recommended etcd practices*.

## Data storage management

The following table summarizes the main directories that OpenShift Container Platform components write data to.

+---------------------------+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+-------------------------------------------------------------------------------------------------------------------------+--------------------------------------------------------------------------------------------------------------------+
| Directory                 | Notes                                                                                                                                                                                                            | Sizing                                                                                                                  | Expected growth                                                                                                    |
+===========================+==================================================================================================================================================================================================================+=========================================================================================================================+====================================================================================================================+
| ***/var/lib/etcd***       | Used for etcd storage when storing the database.                                                                                                                                                                 | Less than 20 GB.                                                                                                        | Will grow slowly with the environment. Only storing metadata.                                                      |
|                           |                                                                                                                                                                                                                  |                                                                                                                         |                                                                                                                    |
|                           |                                                                                                                                                                                                                  | Database can grow up to 8 GB.                                                                                           | Additional 20-25 GB for every additional 8 GB of memory.                                                           |
+---------------------------+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+-------------------------------------------------------------------------------------------------------------------------+--------------------------------------------------------------------------------------------------------------------+
| ***/var/lib/containers*** | This is the mount point for the CRI-O runtime. Storage used for active container runtimes, including pods, and storage of local images. Not used for registry storage.                                           | 50 GB for a node with 16 GB memory. Note that this sizing should not be used to determine minimum cluster requirements. | Growth is limited by capacity for running containers.                                                              |
|                           |                                                                                                                                                                                                                  |                                                                                                                         |                                                                                                                    |
|                           |                                                                                                                                                                                                                  | Additional 20-25 GB for every additional 8 GB of memory.                                                                |                                                                                                                    |
+---------------------------+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+-------------------------------------------------------------------------------------------------------------------------+--------------------------------------------------------------------------------------------------------------------+
| ***/var/lib/kubelet***    | Ephemeral volume storage for pods. This includes anything external that is mounted into a container at runtime. Includes environment variables, kube secrets, and data volumes not backed by persistent volumes. | Varies                                                                                                                  | Minimal if pods requiring storage are using persistent volumes. If using ephemeral storage, this can grow quickly. |
+---------------------------+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+-------------------------------------------------------------------------------------------------------------------------+--------------------------------------------------------------------------------------------------------------------+

**Table 3: Main directories for storing OpenShift Container Platform data**
