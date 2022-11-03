# Deploying distributed units at scale in a disconnected environment

Use zero touch provisioning (ZTP) to provision distributed units at new edge sites in a disconnected environment. The workflow starts when the site is connected to the network and ends with the CNF workload deployed and running on the site nodes.

## Provisioning edge sites at scale

Telco edge computing presents extraordinary challenges with managing hundreds to tens of thousands of clusters in hundreds of thousands of locations. These challenges require fully-automated management solutions with, as closely as possible, zero human interaction.

Zero touch provisioning (ZTP) allows you to provision new edge sites with declarative configurations of bare-metal equipment at remote sites. Template or overlay configurations install {product-title} features that are required for CNF workloads. End-to-end functional test suites are used to verify CNF related features. All configurations are declarative in nature.

You start the workflow by creating declarative configurations for ISO images that are delivered to the edge nodes to begin the installation process. The images are used to repeatedly provision large numbers of nodes efficiently and quickly, allowing you keep up with requirements from the field for far edge nodes.

Service providers are deploying a more distributed mobile network architecture allowed by the modular functional framework defined for 5G. This allows service providers to move from appliance-based radio access networks (RAN) to open cloud RAN architecture, gaining flexibility and agility in delivering services to end users.

The following diagram shows how ZTP works within a far edge framework.

![ZTP in a far edge framework](data:image/png;base64,)

## About ZTP and distributed units on OpenShift clusters

You can install a distributed unit (DU) on {product-title} clusters at scale with Red Hat Advanced Cluster Management (RHACM) using the assisted installer (AI) and the policy generator with core-reduction technology enabled. The DU installation is done using zero touch provisioning (ZTP) in a disconnected environment.

RHACM manages clusters in a hub-and-spoke architecture, where a single hub cluster manages many spoke clusters. RHACM applies radio access network (RAN) policies from predefined custom resources (CRs). Hub clusters running ACM provision and deploy the spoke clusters using ZTP and AI. DU installation follows the AI installation of {product-title} on each cluster.

The AI service handles provisioning of {product-title} on single node clusters, three-node clusters, or standard clusters running on bare metal. ACM ships with and deploys the AI when the `MultiClusterHub` custom resource is installed.

With ZTP and AI, you can provision {product-title} clusters to run your DUs at scale. A high-level overview of ZTP for distributed units in a disconnected environment is as follows:

-   A hub cluster running Red Hat Advanced Cluster Management (RHACM) manages a disconnected internal registry that mirrors the {product-title} release images. The internal registry is used to provision the spoke clusters.

-   You manage the bare metal host machines for your DUs in an inventory file that uses YAML for formatting. You store the inventory file in a Git repository.

-   You install the DU bare metal host machines on site, and make the hosts ready for provisioning. To be ready for provisioning, the following is required for each bare metal host:

    -   Network connectivity - including DNS for your network. Hosts should be reachable through the hub and managed spoke clusters. Ensure there is layer 3 connectivity between the hub and the host where you want to install your hub cluster.

    -   Baseboard Management Controller (BMC) details for each host - ZTP uses BMC details to connect the URL and credentials for accessing the BMC. ZTP manages the spoke cluster definition CRs, with the exception of the `BMCSecret` CR, which you create manually. These define the relevant elements for the managed clusters.

## The GitOps approach

ZTP uses the GitOps deployment set of practices for infrastructure deployment that allows developers to perform tasks that would otherwise fall under the purview of IT operations. GitOps achieves these tasks using declarative specifications stored in Git repositories, such as YAML files and other defined patterns, that provide a framework for deploying the infrastructure. The declarative output is leveraged by the Open Cluster Manager (OCM) for multisite deployment.

One of the motivators for a GitOps approach is the requirement for reliability at scale. This is a significant challenge that GitOps helps solve.

GitOps addresses the reliability issue by providing traceability, RBAC, and a single source of truth for the desired state of each site. Scale issues are addressed by GitOps providing structure, tooling, and event driven operations through webhooks.

## Zero touch provisioning building blocks

Red Hat Advanced Cluster Management (RHACM) leverages zero touch provisioning (ZTP) to deploy single-node {product-title} clusters, three-node clusters, and standard clusters. The initial site plan is divided into smaller components and initial configuration data is stored in a Git repository. ZTP uses a declarative GitOps approach to deploy these clusters.

The deployment of the clusters includes:

-   Installing the host operating system (RHCOS) on a blank server.

-   Deploying {product-title}.

-   Creating cluster policies and site subscriptions.

-   Leveraging a GitOps deployment topology for a develop once, deploy anywhere model.

-   Making the necessary network configurations to the server operating system.

-   Deploying profile Operators and performing any needed software-related configuration, such as performance profile, PTP, and SR-IOV.

-   Downloading images needed to run workloads (CNFs).

## How to plan your RAN policies

Zero touch provisioning (ZTP) uses Red Hat Advanced Cluster Management (RHACM) to apply the radio access network (RAN) configuration using a policy-based governance approach to apply the configuration.

The policy generator or `PolicyGen` is a part of the GitOps ZTP tooling that facilitates creating RHACM policies from a set of predefined custom resources. There are three main items: policy categorization, source CR policy, and the `PolicyGenTemplate` CR. `PolicyGen` uses these to generate the policies and their placement bindings and rules.

The following diagram shows how the RAN policy generator interacts with GitOps and RHACM.

![RAN policy generator](data:image/png;base64,)

RAN policies are categorized into three main groups:

Common  
A policy that exists in the `Common` category is applied to all clusters to be represented by the site plan. Cluster types include single node, three-node, and standard clusters.

Groups  
A policy that exists in the `Groups` category is applied to a group of clusters. Every group of clusters could have their own policies that exist under the `Groups` category. For example, `Groups/group1` can have its own policies that are applied to the clusters belonging to `group1`. You can also define a group for each cluster type: single node, three-node, and standard clusters.

Sites  
A policy that exists in the `Sites` category is applied to a specific cluster. Any cluster could have its own policies that exist in the `Sites` category. For example, `Sites/cluster1` has its own policies applied to `cluster1`. You can also define an example site-specific configuration for each cluster type: single node, three-node, and standard clusters.

## Low latency for distributed units (DUs)

Low latency is an integral part of the development of 5G networks. Telecommunications networks require as little signal delay as possible to ensure quality of service in a variety of critical use cases.

Low latency processing is essential for any communication with timing constraints that affect functionality and security. For example, 5G Telco applications require a guaranteed one millisecond one-way latency to meet Internet of Things (IoT) requirements. Low latency is also critical for the future development of autonomous vehicles, smart factories, and online gaming. Networks in these environments require almost a real-time flow of data.

Low latency systems are about guarantees with regards to response and processing times. This includes keeping a communication protocol running smoothly, ensuring device security with fast responses to error conditions, or just making sure a system is not lagging behind when receiving a lot of data. Low latency is key for optimal synchronization of radio transmissions.

{product-title} enables low latency processing for DUs running on COTS hardware by using a number of technologies and specialized hardware devices:

Real-time kernel for RHCOS  
Ensures workloads are handled with a high degree of process determinism.

CPU isolation  
Avoids CPU scheduling delays and ensures CPU capacity is available consistently.

NUMA awareness  
Aligns memory and huge pages with CPU and PCI devices to pin guaranteed container memory and huge pages to the NUMA node. This decreases latency and improves performance of the node.

Huge pages memory management  
Using huge page sizes improves system performance by reducing the amount of system resources required to access page tables.

Precision timing synchronization using PTP  
Allows synchronization between nodes in the network with sub-microsecond accuracy.

## Preparing the disconnected environment

Before you can provision distributed units (DU) at scale, you must install Red Hat Advanced Cluster Management (RHACM), which handles the provisioning of the DUs.

RHACM is deployed as an Operator on the {product-title} hub cluster. It controls clusters and applications from a single console with built-in security policies. RHACM provisions and manage your DU hosts. To install RHACM in a disconnected environment, you create a mirror registry that mirrors the Operator Lifecycle Manager (OLM) catalog that contains the required Operator images. OLM manages, installs, and upgrades Operators and their dependencies in the cluster.

You also use a disconnected mirror host to serve the RHCOS ISO and RootFS disk images that provision the DU bare-metal host operating system.

-   For more information about creating the disconnected mirror registry, see [Creating a mirror registry](../installing/disconnected_install/installing-mirroring-creating-registry.xml#installing-mirroring-creating-registry).

-   For more information about mirroring OpenShift Platform image to the disconnected registry, see [Mirroring images for a disconnected installation](../installing/disconnected_install/installing-mirroring-installation-images.html#installing-mirroring-installation-images).

### Adding RHCOS ISO and RootFS images to the disconnected mirror host

Before you install a cluster on infrastructure that you provision, you must create Red Hat Enterprise Linux CoreOS (RHCOS) machines for it to use. Use a disconnected mirror to host the RHCOS images you require to provision your distributed unit (DU) bare-metal hosts.

-   Deploy and configure an HTTP server to host the RHCOS image resources on the network. You must be able to access the HTTP server from your computer, and from the machines that you create.

!!! important
    The RHCOS images might not change with every release of {product-title}. You must download images with the highest version that is less than or equal to the {product-title} version that you install. Use the image versions that match your {product-title} version if they are available. You require ISO and RootFS images to install RHCOS on the DU hosts. RHCOS qcow2 images are not supported for this installation type.

The RHCOS images might not change with every release of {product-title}. You must download images with the highest version that is less than or equal to the {product-title} version that you install. Use the image versions that match your {product-title} version if they are available. You require ISO and RootFS images to install RHCOS on the DU hosts. RHCOS qcow2 images are not supported for this installation type.

1.  Log in to the mirror host.

2.  Obtain the RHCOS ISO and RootFS images from [mirror.openshift.com](https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/pre-release/), for example:

    1.  Export the required image names and {product-title} version as environment variables:

        ``` terminal
        $ export ISO_IMAGE_NAME=<iso_image_name> 
        ```

        ``` terminal
        $ export ROOTFS_IMAGE_NAME=<rootfs_image_name> 
        ```

        ``` terminal
        $ export OCP_VERSION=<ocp_version> 
        ```

        -   ISO image name, for example, `rhcos-4.11.0-fc.1-x86_64-live.x86_64.iso`

        -   RootFS image name, for example, `rhcos-4.11.0-fc.1-x86_64-live-rootfs.x86_64.img`

        -   {product-title} version, for example, `latest-4.11`

    2.  Download the required images:

        ``` terminal
        $ sudo wget https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/pre-release/${OCP_VERSION}/${ISO_IMAGE_NAME} -O /var/www/html/${ISO_IMAGE_NAME}
        ```

        ``` terminal
        $ sudo wget https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/pre-release/${OCP_VERSION}/${ROOTFS_IMAGE_NAME} -O /var/www/html/${ROOTFS_IMAGE_NAME}
        ```

-   Verify that the images downloaded successfully and are being served on the disconnected mirror host, for example:

    ``` terminal
    $ wget http://$(hostname)/${ISO_IMAGE_NAME}
    ```

    **Expected output**

    ``` terminal
    ...
    Saving to: rhcos-4.11.0-fc.1-x86_64-live.x86_64.iso
    rhcos-4.11.0-fc.1-x86_64-  11%[====>    ]  10.01M  4.71MB/s
    ...
    ```

## Installing Red Hat Advanced Cluster Management in a disconnected environment

You use Red Hat Advanced Cluster Management (RHACM) on a hub cluster in the disconnected environment to manage the deployment of distributed unit (DU) profiles on multiple managed spoke clusters.

-   Install the {product-title} CLI (`oc`).

-   Log in as a user with `cluster-admin` privileges.

-   Configure a disconnected mirror registry for use in the cluster.

    !!! note
        If you want to deploy Operators to the spoke clusters, you must also add them to this registry. See Mirroring an Operator catalog for more information.
    If you want to deploy Operators to the spoke clusters, you must also add them to this registry. See [Mirroring an Operator catalog](https://docs.openshift.com/container-platform/4.9/operators/admin/olm-restricted-networks.html#olm-mirror-catalog_olm-restricted-networks) for more information.

<!-- -->

-   Install RHACM on the hub cluster in the disconnected environment. See [Installing RHACM in a disconnected environment](https://access.redhat.com/documentation/en-us/red_hat_advanced_cluster_management_for_kubernetes/2.4/html/install/installing#install-on-disconnected-networks).

## Enabling assisted installer service on bare metal

The Assisted Installer Service (AIS) deploys {product-title} clusters. Red Hat Advanced Cluster Management (RHACM) ships with AIS. AIS is deployed when you enable the MultiClusterHub Operator on the RHACM hub cluster.

For distributed units (DUs), RHACM supports {product-title} deployments that run on a single bare-metal host, three-node clusters, or standard clusters. In the case of single node clusters or three-node clusters, all nodes act as both control plane and worker nodes.

-   Install {product-title} {product-version} on a hub cluster.

-   Install RHACM and create the `MultiClusterHub` resource.

-   Create persistent volume custom resources (CR) for database and file system storage.

-   You have installed the OpenShift CLI (`oc`).

!!! important
    Create a persistent volume resource for image storage. Failure to specify persistent volume storage for images can affect cluster performance.

Create a persistent volume resource for image storage. Failure to specify persistent volume storage for images can affect cluster performance.

1.  Modify the `Provisioning` resource to allow the Bare Metal Operator to watch all namespaces:

    ``` terminal
     $ oc patch provisioning provisioning-configuration --type merge -p '{"spec":{"watchAllNamespaces": true }}'
    ```

2.  Create the `AgentServiceConfig` CR.

    1.  Save the following YAML in the `agent_service_config.yaml` file:

        ``` yaml
        apiVersion: agent-install.openshift.io/v1beta1
        kind: AgentServiceConfig
        metadata:
         name: agent
        spec:
          databaseStorage:
            accessModes:
            - ReadWriteOnce
            resources:
              requests:
                storage: <database_volume_size> 
          filesystemStorage:
            accessModes:
            - ReadWriteOnce
            resources:
              requests:
                storage: <file_storage_volume_size> 
          imageStorage:
            accessModes:
            - ReadWriteOnce
            resources:
              requests:
                storage: <image_storage_volume_size> 
          osImages: 
            - openshiftVersion: "<ocp_version>" 
              version: "<ocp_release_version>" 
              url: "<iso_url>" 
              cpuArchitecture: "x86_64"
        ```

        -   Volume size for the `databaseStorage` field, for example `10Gi`.

        -   Volume size for the `filesystemStorage` field, for example `20Gi`.

        -   Volume size for the `imageStorage` field, for example `2Gi`.

        -   List of OS image details, for example a single {product-title} OS version.

        -   {product-title} version to install, in either "x.y" (major.minor) or "x.y.z" (major.minor.patch) formats.

        -   Specific install version, for example, `47.83.202103251640-0`.

        -   ISO url, for example, `https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/4.7/4.7.7/rhcos-4.7.7-x86_64-live.x86_64.iso`.

    2.  Create the `AgentServiceConfig` CR by running the following command:

        ``` terminal
        $ oc create -f agent_service_config.yaml
        ```

        **Example output**

        ``` terminal
        agentserviceconfig.agent-install.openshift.io/agent created
        ```

## ZTP custom resources

Zero touch provisioning (ZTP) uses custom resource (CR) objects to extend the Kubernetes API or introduce your own API into a project or a cluster. These CRs contain the site-specific data required to install and configure a cluster for RAN applications.

A custom resource definition (CRD) file defines your own object kinds. Deploying a CRD into the managed cluster causes the Kubernetes API server to begin serving the specified CR for the entire lifecycle.

For each CR in the `<site>.yaml` file on the managed cluster, ZTP uses the data to create installation CRs in a directory named for the cluster.

ZTP provides two ways for defining and installing CRs on managed clusters: a manual approach when you are provisioning a single cluster and an automated approach when provisioning multiple clusters.

Manual CR creation for single clusters  
Use this method when you are creating CRs for a single cluster. This is a good way to test your CRs before deploying on a larger scale.

Automated CR creation for multiple managed clusters  
Use the automated SiteConfig method when you are installing multiple managed clusters, for example, in batches of up to 100 clusters. SiteConfig uses ArgoCD as the engine for the GitOps method of site deployment. After completing a site plan that contains all of the required parameters for deployment, a policy generator creates the manifests and applies them to the hub cluster.

Both methods create the CRs shown in the following table. On the cluster site, an automated Discovery image ISO file creates a directory with the site name and a file with the cluster name. Every cluster has its own namespace, and all of the CRs are under that namespace. The namespace and the CR names match the cluster name.

<table><colgroup><col style="width: 33%" /><col style="width: 33%" /><col style="width: 33%" /></colgroup><thead><tr class="header"><th style="text-align: left;">Resource</th><th style="text-align: left;">Description</th><th style="text-align: left;">Usage</th></tr></thead><tbody><tr class="odd"><td style="text-align: left;"><p><code>BareMetalHost</code></p></td><td style="text-align: left;"><p>Contains the connection information for the Baseboard Management Controller (BMC) of the target bare-metal host.</p></td><td style="text-align: left;"><p>Provides access to the BMC to load and boot the discovery image on the target server by using the Redfish protocol. ZTP supports iPXE and virtual media network booting.</p></td></tr><tr class="even"><td style="text-align: left;"><p><code>InfraEnv</code></p></td><td style="text-align: left;"><p>Contains information for pulling {product-title} onto the target bare-metal host.</p></td><td style="text-align: left;"><p>Used with ClusterDeployment to generate the Discovery ISO for the managed cluster.</p></td></tr><tr class="odd"><td style="text-align: left;"><p><code>AgentClusterInstall</code></p></td><td style="text-align: left;"><p>Specifies the managed cluster’s configuration such as networking and the number of supervisor (control plane) nodes. Shows the <code>kubeconfig</code> and credentials when the installation is complete.</p></td><td style="text-align: left;"><p>Specifies the managed cluster configuration information and provides status during the installation of the cluster.</p></td></tr><tr class="even"><td style="text-align: left;"><p><code>ClusterDeployment</code></p></td><td style="text-align: left;"><p>References the <code>AgentClusterInstall</code> to use.</p></td><td style="text-align: left;"><p>Used with <code>InfraEnv</code> to generate the Discovery ISO for the managed cluster.</p></td></tr><tr class="odd"><td style="text-align: left;"><p><code>NMStateConfig</code></p></td><td style="text-align: left;"><p>Provides network configuration information such as <code>MAC</code> to <code>IP</code> mapping, DNS server, default route, and other network settings. This is not needed if DHCP is used.</p></td><td style="text-align: left;"><p>Sets up a static IP address for the managed cluster’s Kube API server.</p></td></tr><tr class="even"><td style="text-align: left;"><p><code>Agent</code></p></td><td style="text-align: left;"><p>Contains hardware information about the target bare-metal host.</p></td><td style="text-align: left;"><p>Created automatically on the hub when the target machine’s discovery image boots.</p></td></tr><tr class="odd"><td style="text-align: left;"><p><code>ManagedCluster</code></p></td><td style="text-align: left;"><p>When a cluster is managed by the hub, it must be imported and known. This Kubernetes object provides that interface.</p></td><td style="text-align: left;"><p>The hub uses this resource to manage and show the status of managed clusters.</p></td></tr><tr class="even"><td style="text-align: left;"><p><code>KlusterletAddonConfig</code></p></td><td style="text-align: left;"><p>Contains the list of services provided by the hub to be deployed to a <code>ManagedCluster</code>.</p></td><td style="text-align: left;"><p>Tells the hub which addon services to deploy to a <code>ManagedCluster</code>.</p></td></tr><tr class="odd"><td style="text-align: left;"><p><code>Namespace</code></p></td><td style="text-align: left;"><p>Logical space for <code>ManagedCluster</code> resources existing on the hub. Unique per site.</p></td><td style="text-align: left;"><p>Propagates resources to the <code>ManagedCluster</code>.</p></td></tr><tr class="even"><td style="text-align: left;"><p><code>Secret</code><br />
</p></td><td style="text-align: left;"><p>Two custom resources are created: <code>BMC Secret</code> and <code>Image Pull Secret</code>.</p></td><td style="text-align: left;"><ul><li><p><code>BMC Secret</code> authenticates into the target bare-metal host using its username and password.</p></li><li><p><code>Image Pull Secret</code> contains authentication information for the {product-title} image installed on the target bare-metal host.</p></li></ul></td></tr><tr class="odd"><td style="text-align: left;"><p><code>ClusterImageSet</code></p></td><td style="text-align: left;"><p>Contains {product-title} image information such as the repository and image name.</p></td><td style="text-align: left;"><p>Passed into resources to provide {product-title} images.</p></td></tr></tbody></table>

ZTP support for single node clusters, three-node clusters, and standard clusters requires updates to these CRs, including multiple instantiations of some.

ZTP provides support for deploying single node clusters, three-node clusters, and standard OpenShift clusters. This includes the installation of OpenShift and deployment of the distributed units (DUs) at scale.

The overall flow is identical to the ZTP support for single node clusters, with some differences in configuration depending on the type of cluster:

`SiteConfig` file:

-   For single node clusters, the `SiteConfig` file must have exactly one entry in the `nodes` section.

-   For three-node clusters, the `SiteConfig` file must have exactly three entries defined in the `nodes` section.

-   For standard clusters, the `SiteConfig` file must have exactly three entries in the `nodes` section with `role: master` and one or more additional entries with `role: worker`.

`PolicyGenTemplate` file:

-   The example common `PolicyGenTemplate` file is common across all types of clusters.

-   There are example group `PolicyGenTemplate` files for single node, three-node, and standard clusters.

-   Site-specific `PolicyGenTemplate` files are still specific to each site.

## PolicyGenTemplate CRs for RAN deployments

You use `PolicyGenTemplate` custom resources (CRs) to customize the configuration applied to the cluster using the GitOps zero touoch provisioning (ZTP) pipeline. The baseline configuration, obtained from the GitOps ZTP container, is designed to provide a set of critical features and node tuning settings that ensure the cluster can support the stringent performance and resource utilization constraints typical of RAN Distributed Unit (DU) applications. Changes or omissions from the baseline configuration can affect feature availability, performance, and resource utilization. Use `PolicyGenTemplate` CRs as the basis to create a hierarchy of configuration files tailored to your specific site requirements.

The baseline `PolicyGenTemplate` CRs that are defined for RAN DU cluster configuration can be extracted from the GitOps ZTP `ztp-site-generate`. See "Preparing the ZTP Git repository" for further details.

The `PolicyGenTemplate` CRs can be found in the `./out/argocd/example/policygentemplates` folder. The reference architecture has common, group, and site-specific configuration CRs. Each `PolicyGenTemplate` CR refers to other CRs that can be found in the `./out/source-crs` folder.

The `PolicyGenTemplate` CRs relevant to RAN cluster configuration are described below. Variants are provided for the group `PolicyGenTemplate` CRs to account for differences in single-node, three-node compact, and standard cluster configurations. Similarly, site-specific configuration variants are provided for single-node clusters and multi-node (compact or standard) clusters. Use the group and site-specific configuration variants that are relevant for your deployment.

<table><caption>PolicyGenTemplate CRs for RAN deployments</caption><colgroup><col style="width: 50%" /><col style="width: 50%" /></colgroup><thead><tr class="header"><th style="text-align: left;">PolicyGenTemplate CR</th><th style="text-align: left;">Description</th></tr></thead><tbody><tr class="odd"><td style="text-align: left;"><p><code>common-ranGen.yaml</code></p></td><td style="text-align: left;"><p>Contains a set of common RAN CRs that get applied to all clusters. These CRs subscribe to a set of operators providing cluster features typical for RAN as well as baseline cluster tuning.</p></td></tr><tr class="even"><td style="text-align: left;"><p><code>group-du-3node-ranGen.yaml</code></p></td><td style="text-align: left;"><p>Contains the RAN policies for three-node clusters only.</p></td></tr><tr class="odd"><td style="text-align: left;"><p><code>group-du-sno-ranGen.yaml</code></p></td><td style="text-align: left;"><p>Contains the RAN policies for single-node clusters only.</p></td></tr><tr class="even"><td style="text-align: left;"><p><code>group-du-standard-ranGen.yaml</code></p></td><td style="text-align: left;"><p>Contains the RAN policies for standard three control-plane clusters.</p></td></tr></tbody></table>

PolicyGenTemplate CRs for RAN deployments

-   For more information about extracting the `/argocd` directory from the `ztp-site-generate` container image, see [Preparing the ZTP Git repository](../scalability_and_performance/ztp-deploying-disconnected.xml#ztp-policygentemplates-for-ran_ztp-deploying-disconnected).

## About the PolicyGenTemplate

The `PolicyGenTemplate.yaml` file is a custom resource definition (CRD) that tells the `PolicyGen` policy generator what CRs to include in the configuration, how to categorize the CRs into the generated policies, and what items in those CRs need to be updated with overlay content.

The following example shows a `PolicyGenTemplate.yaml` file:

``` yaml
---
apiVersion: ran.openshift.io/v1
kind: PolicyGenTemplate
metadata:
  name: "group-du-sno"
  namespace: "group-du-sno-policies"
spec:
  bindingRules:
    group-du-sno: ""
  mcp: "master"
  sourceFiles:
    - fileName: ConsoleOperatorDisable.yaml
      policyName: "console-policy"
    - fileName: ClusterLogForwarder.yaml
      policyName: "log-forwarder-policy"
      spec:
        outputs:
          - type: "kafka"
            name: kafka-open
            # below url is an example
            url: tcp://10.46.55.190:9092/test
        pipelines:
          - name: audit-logs
            inputRefs:
             - audit
            outputRefs:
             - kafka-open
          - name: infrastructure-logs
            inputRefs:
             - infrastructure
            outputRefs:
             - kafka-open
    - fileName: ClusterLogging.yaml
      policyName: "log-policy"
      spec:
        curation:
          curator:
            schedule: "30 3 * * *"
        collection:
          logs:
            type: "fluentd"
            fluentd: {}
    - fileName: MachineConfigSctp.yaml
      policyName: "mc-sctp-policy"
      metadata:
        labels:
          machineconfiguration.openshift.io/role: master
    - fileName: PtpConfigSlave.yaml
      policyName: "ptp-config-policy"
      metadata:
        name: "du-ptp-slave"
      spec:
        profile:
        - name: "slave"
          interface: "ens5f0"
          ptp4lOpts: "-2 -s --summary_interval -4"
          phc2sysOpts: "-a -r -n 24"
    - fileName: SriovOperatorConfig.yaml
      policyName: "sriov-operconfig-policy"
      spec:
        disableDrain: true
    - fileName: MachineConfigAcceleratedStartup.yaml
      policyName: "mc-accelerated-policy"
      metadata:
        name: 04-accelerated-container-startup-master
        labels:
          machineconfiguration.openshift.io/role: master
    - fileName: DisableSnoNetworkDiag.yaml
      policyName: "disable-network-diag"
      metadata:
        labels:
          machineconfiguration.openshift.io/role: master
```

The `group-du-ranGen.yaml` file defines a group of policies under a group named `group-du`. A Red Hat Advanced Cluster Management (RHACM) policy is generated for every source file that exists in `sourceFiles`. And, a single placement binding and placement rule is generated to apply the cluster selection rule for `group-du` policies.

Using the source file `PtpConfigSlave.yaml` as an example, the `PtpConfigSlave` has a definition of a `PtpConfig` custom resource (CR). The generated policy for the `PtpConfigSlave` example is named `group-du-ptp-config-policy`. The `PtpConfig` CR defined in the generated `group-du-ptp-config-policy` is named `du-ptp-slave`. The `spec` defined in `PtpConfigSlave.yaml` is placed under `du-ptp-slave` along with the other `spec` items defined under the source file.

The following example shows the `group-du-ptp-config-policy`:

``` yaml
apiVersion: policy.open-cluster-management.io/v1
kind: Policy
metadata:
  name: group-du-ptp-config-policy
  namespace: groups-sub
  annotations:
    policy.open-cluster-management.io/categories: CM Configuration Management
    policy.open-cluster-management.io/controls: CM-2 Baseline Configuration
    policy.open-cluster-management.io/standards: NIST SP 800-53
spec:
    remediationAction: enforce
    disabled: false
    policy-templates:
        - objectDefinition:
            apiVersion: policy.open-cluster-management.io/v1
            kind: ConfigurationPolicy
            metadata:
                name: group-du-ptp-config-policy-config
            spec:
                remediationAction: enforce
                severity: low
                namespaceselector:
                    exclude:
                        - kube-*
                    include:
                        - '*'
                object-templates:
                    - complianceType: musthave
                      objectDefinition:
                        apiVersion: ptp.openshift.io/v1
                        kind: PtpConfig
                        metadata:
                            name: slave
                            namespace: openshift-ptp
                        spec:
                            recommend:
                                - match:
                                - nodeLabel: node-role.kubernetes.io/worker-du
                                  priority: 4
                                  profile: slave
                            profile:
                                - interface: ens5f0
                                  name: slave
                                  phc2sysOpts: -a -r -n 24
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
                                    .....
```

## Best practices when customizing PolicyGenTemplate CRs

Consider the following best practices when customizing site configuration `PolicyGenTemplate` CRs:

-   Use as few policies as necessary. Using fewer policies means using less resources. Each additional policy creates overhead for the hub cluster and the deployed spoke cluster. CRs are combined into policies based on the `policyName` field in the `PolicyGenTemplate` CR. CRs in the same `PolicyGenTemplate` which have the same value for `policyName` are managed under a single policy.

-   Use a single catalog source for all Operators. In disconnected environments, configure the registry as a single index containing all Operators. Each additional `CatalogSource` on the spoke clusters increases CPU usage.

-   `MachineConfig` CRs should be included as `extraManifests` in the `SiteConfig` CR so that they are applied during installation. This can reduce the overall time taken until the cluster is ready to deploy applications.

-   `PolicyGenTemplates` should override the channel field to explicitly identify the desired version. This ensures that changes in the source CR during upgrades does not update the generated subscription.

<!-- -->

-   For details about best practice for scaling clusters with Red Hat Advanced Cluster Management (RHACM), see [ACM performance and scalability considerations](https://access.redhat.com/documentation/en-us/red_hat_advanced_cluster_management_for_kubernetes/2.6/html/install/installing#performance-and-scalability).

!!! note
    Scaling the hub cluster to managing large numbers of spoke clusters is affected by the number of policies created on the hub cluster. Grouping multiple configuration CRs into a single or limited number of policies is one way to reduce the overall number of policies on the hub cluster. When using the common/group/site hierarchy of policies for managing site configuration, it is especially important to combine site-specific configuration into a single policy.

Scaling the hub cluster to managing large numbers of spoke clusters is affected by the number of policies created on the hub cluster. Grouping multiple configuration CRs into a single or limited number of policies is one way to reduce the overall number of policies on the hub cluster. When using the common/group/site hierarchy of policies for managing site configuration, it is especially important to combine site-specific configuration into a single policy.

## Creating the PolicyGenTemplate CR

Use this procedure to create the `PolicyGenTemplate` custom resource (CR) for your site in your local clone of the Git repository.

**Prerequisites**

Ensure that policy namespaces meets the following requirements:

-   Namespace names must be prefixed with `ztp`. For example:

    ``` yaml
    apiVersion: v1
    kind: Namespace
    metadata:
      name: ztp-common
    ```

-   Namespaces must not match the namespace of a pre-existing cluster.

1.  Choose an appropriate example from `out/argocd/example/policygentemplates`. This directory demonstrates a three-level policy framework that represents a well-supported low-latency profile tuned for the needs of 5G Telco DU deployments:

    -   A single `common-ranGen.yaml` file that applies to all types of sites.

    -   A set of shared `group-du-*-ranGen.yaml` files that are common between similar clusters.

    -   An example `example-*-site.yaml` file that you can copy and update for each individual site.

2.  Ensure that the labels defined in your `PolicyGenTemplate` `bindingRules` section correspond to the labels that are defined in the `SiteConfig` files of the clusters you are managing.

3.  Ensure that the content of the overlaid spec files matches your desired end state. As a reference, the `out/source-crs` directory contains the full list of `source-crs` available to be included and overlaid by your `PolicyGenTemplate` templates.

    !!! note
        Depending on the specific requirements of your clusters, you might need more than a single group policy per cluster type, especially considering that the example group policies each have a single PerformancePolicy.yaml file that can only be shared across a set of clusters if those clusters consist of identical hardware configurations.
    Depending on the specific requirements of your clusters, you might need more than a single group policy per cluster type, especially considering that the example group policies each have a single `PerformancePolicy.yaml` file that can only be shared across a set of clusters if those clusters consist of identical hardware configurations.

4.  Define all the policy namespaces in a YAML file similar to the example `out/argocd/example/policygentemplates/ns.yaml` file.

    !!! important
        Ensure that policy namespaces begin with ztp and are unique.
    Ensure that policy namespaces begin with `ztp` and are unique.

5.  Add all the `PolicyGenTemplate` files and `ns.yaml` file to the `kustomization.yaml` file, similar to the example `out/argocd/example/policygentemplates/kustomization.yaml` file.

6.  Commit the `PolicyGenTemplate` CRs, `ns.yaml` file, and the associated `kustomization.yaml` file in the Git repository.

## Configuring policy compliance evaluation timeouts for PolicyGenTemplate CRs

Use Red Hat Advanced Cluster Management (RHACM) installed on a hub cluster to monitor and report on whether your managed clusters are compliant with applied policies. RHACM uses policy templates to apply predefined policy controllers and policies. Policy controllers are Kubernetes custom resource definition (CRD) instances.

You can override the default policy evaluation intervals with `PolicyGenTemplate` custom resources (CRs). You configure duration settings that define how long a `ConfigurationPolicy` CR can be in a state of policy compliance or non-compliance before RHACM re-evaluates the applied cluster policies.

The zero touch provisioning (ZTP) policy generator generates `ConfigurationPolicy` CR policies with pre-defined policy evaluation intervals. The default value for the `noncompliant` state is 10 seconds. The default value for the `compliant` state is 10 minutes. To disable the evaluation interval, set the value to `never`.

-   You have installed the OpenShift CLI (`oc`).

-   You have logged in to the hub cluster as a user with `cluster-admin` privileges.

-   You have created a Git repository where you manage your custom site configuration data.

1.  To configure the evaluation interval for all policies in a `PolicyGenTemplate` CR, add `evaluationInterval` to the `spec` field, and then set the appropriate `compliant` and `noncompliant` values. For example:

    ``` yaml
    spec:
      evaluationInterval:
        compliant: 30m
        noncompliant: 20s
    ```

2.  To configure the evaluation interval for the `spec.sourceFiles` object in a `PolicyGenTemplate` CR, add `evaluationInterval` to the `sourceFiles` field, for example:

    ``` yaml
    spec:
      sourceFiles:
       - fileName: SriovSubscription.yaml
         policyName: "sriov-sub-policy"
         evaluationInterval:
           compliant: never
           noncompliant: 10s
    ```

3.  Commit the `PolicyGenTemplate` CRs files in the Git repository and push your changes.

**Verification**

Check that the managed spoke cluster policies are monitored at the expected intervals.

1.  Log in as a user with `cluster-admin` privileges on the managed cluster.

2.  Get the pods that are running in the `open-cluster-management-agent-addon` namespace. Run the following command:

    ``` terminal
    $ oc get pods -n open-cluster-management-agent-addon
    ```

    **Example output**

    ``` terminal
    NAME                                         READY   STATUS    RESTARTS        AGE
    config-policy-controller-858b894c68-v4xdb    1/1     Running   22 (5d8h ago)   10d
    ```

3.  Check the applied policies are being evaluated at the expected interval in the logs for the `config-policy-controller` pod:

    ``` terminal
    $ oc logs -n open-cluster-management-agent-addon config-policy-controller-858b894c68-v4xdb
    ```

    **Example output**

    ``` terminal
    2022-05-10T15:10:25.280Z       info   configuration-policy-controller controllers/configurationpolicy_controller.go:166      Skipping the policy evaluation due to the policy not reaching the evaluation interval  {"policy": "compute-1-config-policy-config"}
    2022-05-10T15:10:25.280Z       info   configuration-policy-controller controllers/configurationpolicy_controller.go:166      Skipping the policy evaluation due to the policy not reaching the evaluation interval  {"policy": "compute-1-common-compute-1-catalog-policy-config"}
    ```

## Creating ZTP custom resources for multiple managed clusters

If you are installing multiple managed clusters, zero touch provisioning (ZTP) uses ArgoCD and `SiteConfig` files to manage the processes that create the CRs and generate and apply the policies for multiple clusters, in batches of no more than 100, using the GitOps approach.

Installing and deploying the clusters is a two stage process, as shown here:

![GitOps approach for Installing and deploying the clusters](data:image/png;base64,)

### Using PolicyGenTemplate CRs to override source CRs content

`PolicyGenTemplate` CRs allow you to overlay additional configuration details on top of the base source CRs provided in the `ztp-site-generate` container. You can think of `PolicyGenTemplate` CRs as a logical merge or patch to the base CR. Use `PolicyGenTemplate` CRs to update a single field of the base CR, or overlay the entire contents of the base CR. You can update values and insert fields that are not in the base CR.

The following example procedure describes how to update fields in the generated `PerformanceProfile` CR for the reference configuration based on the `PolicyGenTemplate` CR in the `group-du-sno-ranGen.yaml` file. Use the procedure as a basis for modifying other parts of the `PolicyGenTemplate` based on your requirements.

-   Create a Git repository where you manage your custom site configuration data. The repository must be accessible from the hub cluster and be defined as a source repository for Argo CD.

1.  Review the baseline source CR for existing content. You can review the source CRs listed in the reference `PolicyGenTemplate` CRs by extracting them from the zero touch provisioning (ZTP) container.

    1.  Create an `/out` folder:

        ``` terminal
        $ mkdir -p ./out
        ```

    2.  Extract the source CRs:

        ``` terminal
        $ podman run --log-driver=none --rm registry.redhat.io/openshift4/ztp-site-generate-rhel8:v{product-version} extract /home/ztp --tar | tar x -C ./out
        ```

2.  Review the baseline `PerformanceProfile` CR in `./out/source-crs/PerformanceProfile.yaml`:

    ``` yaml
    apiVersion: performance.openshift.io/v2
    kind: PerformanceProfile
    metadata:
      name: $name
      annotations:
        ran.openshift.io/ztp-deploy-wave: "10"
    spec:
      additionalKernelArgs:
      - "idle=poll"
      - "rcupdate.rcu_normal_after_boot=0"
      cpu:
        isolated: $isolated
        reserved: $reserved
      hugepages:
        defaultHugepagesSize: $defaultHugepagesSize
        pages:
          - size: $size
            count: $count
            node: $node
      machineConfigPoolSelector:
        pools.operator.machineconfiguration.openshift.io/$mcp: ""
      net:
        userLevelNetworking: true
      nodeSelector:
        node-role.kubernetes.io/$mcp: ''
      numa:
        topologyPolicy: "restricted"
      realTimeKernel:
        enabled: true
    ```

    !!! note
        Any fields in the source CR which contain $…​ are removed from the generated CR if they are not provided in the PolicyGenTemplate CR.
    Any fields in the source CR which contain `$…​` are removed from the generated CR if they are not provided in the `PolicyGenTemplate` CR.

3.  Update the `PolicyGenTemplate` entry for `PerformanceProfile` in the `group-du-sno-ranGen.yaml` reference file. The following example `PolicyGenTemplate` CR stanza supplies appropriate CPU specifications, sets the `hugepages` configuration, and adds a new field that sets `globallyDisableIrqLoadBalancing` to false.

    ``` yaml
    - fileName: PerformanceProfile.yaml
      policyName: "config-policy"
      metadata:
        name: openshift-node-performance-profile
      spec:
        cpu:
          # These must be tailored for the specific hardware platform
          isolated: "2-19,22-39"
          reserved: "0-1,20-21"
        hugepages:
          defaultHugepagesSize: 1G
          pages:
            - size: 1G
              count: 10
        globallyDisableIrqLoadBalancing: false
    ```

4.  Commit the `PolicyGenTemplate` change in Git, and then push to the Git repository being monitored by the GitOps ZTP argo CD application.

**Example output**

The ZTP application generates an ACM policy that contains the generated `PerformanceProfile` CR. The contents of that CR are derived by merging the `metadata` and `spec` contents from the `PerformanceProfile` entry in the `PolicyGenTemplate` onto the source CR. The resulting CR has the following content:

``` yaml
---
apiVersion: performance.openshift.io/v2
kind: PerformanceProfile
metadata:
    name: openshift-node-performance-profile
spec:
    additionalKernelArgs:
        - idle=poll
        - rcupdate.rcu_normal_after_boot=0
    cpu:
        isolated: 2-19,22-39
        reserved: 0-1,20-21
    globallyDisableIrqLoadBalancing: false
    hugepages:
        defaultHugepagesSize: 1G
        pages:
            - count: 10
              size: 1G
    machineConfigPoolSelector:
        pools.operator.machineconfiguration.openshift.io/master: ""
    net:
        userLevelNetworking: true
    nodeSelector:
        node-role.kubernetes.io/master: ""
    numa:
        topologyPolicy: restricted
    realTimeKernel:
        enabled: true
```

!!! note
    In the /source-crs folder that you extract from the ztp-site-generate container, the $ syntax is not used for template substitution as implied by the syntax. Rather, if the policyGen tool sees the $ prefix for a string and you do not specify a value for that field in the related PolicyGenTemplate CR, the field is omitted from the output CR entirely.An exception to this is the $mcp variable in /source-crs YAML files that is substituted with the specified value for mcp from the PolicyGenTemplate CR. For example, in example/policygentemplates/group-du-standard-ranGen.yaml, the value for mcp is worker:The policyGen tool replace instances of $mcp with worker in the output CRs.

In the `/source-crs` folder that you extract from the `ztp-site-generate` container, the `$` syntax is not used for template substitution as implied by the syntax. Rather, if the `policyGen` tool sees the `$` prefix for a string and you do not specify a value for that field in the related `PolicyGenTemplate` CR, the field is omitted from the output CR entirely.

An exception to this is the `$mcp` variable in `/source-crs` YAML files that is substituted with the specified value for `mcp` from the `PolicyGenTemplate` CR. For example, in `example/policygentemplates/group-du-standard-ranGen.yaml`, the value for `mcp` is `worker`:

``` yaml
spec:
  bindingRules:
    group-du-standard: ""
  mcp: "worker"
```

The `policyGen` tool replace instances of `$mcp` with `worker` in the output CRs.

### Filtering custom resources using SiteConfig filters

By using filters, you can easily customize `SiteConfig` custom resources (CRs) to include or exclude other CRs for use in the installation phase of the zero touch provisioning (ZTP) GitOps pipeline.

You can specify an `inclusionDefault` value of `include` or `exclude` for the `SiteConfig` CR, along with a list of the specific `extraManifest` RAN CRs that you want to include or exclude. Setting `inclusionDefault` to `include` makes the ZTP pipeline apply all the files in `/source-crs/extra-manifest` during installation. Setting `inclusionDefault` to `exclude` does the opposite.

You can exclude individual CRs from the `/source-crs/extra-manifest` folder that are otherwise included by default. The following example configures a custom single-node OpenShift `SiteConfig` CR to exclude the `/source-crs/extra-manifest/03-sctp-machine-config-worker.yaml` CR at installation time.

Some additional optional filtering scenarios are also described.

-   You configured the hub cluster for generating the required installation and policy CRs.

-   You created a Git repository where you manage your custom site configuration data. The repository must be accessible from the hub cluster and be defined as a source repository for the Argo CD application.

1.  To prevent the ZTP pipeline from applying the `03-sctp-machine-config-worker.yaml` CR file, apply the following YAML in the `SiteConfig` CR:

    ``` yaml
    apiVersion: ran.openshift.io/v1
    kind: SiteConfig
    metadata:
      name: "site1-sno-du"
      namespace: "site1-sno-du"
    spec:
      baseDomain: "example.com"
      pullSecretRef:
        name: "assisted-deployment-pull-secret"
      clusterImageSetNameRef: "openshift-{product-version}"
      sshPublicKey: "<ssh_public_key>"
      clusters:
    - clusterName: "site1-sno-du"
      extraManifests:
        filter:
          exclude:
            - 03-sctp-machine-config-worker.yaml
    ```

    The ZTP pipeline skips the `03-sctp-machine-config-worker.yaml` CR during installation. All other CRs in `/source-crs/extra-manifest` are applied.

2.  Save the `SiteConfig` CR and push the changes to the site configuration repository.

    The ZTP pipeline monitors and adjusts what CRs it applies based on the `SiteConfig` filter instructions.

3.  Optional: To prevent the ZTP pipeline from applying all the `/source-crs/extra-manifest` CRs during cluster installation, apply the following YAML in the `SiteConfig` CR:

    ``` yaml
    - clusterName: "site1-sno-du"
      extraManifests:
        filter:
          inclusionDefault: exclude
    ```

4.  Optional: To exclude all the `/source-crs/extra-manifest` RAN CRs and instead include a custom CR file during installation, edit the custom `SiteConfig` CR to set the custom manifests folder and the `include` file, for example:

    ``` yaml
    clusters:
    - clusterName: "site1-sno-du"
      extraManifestPath: "<custom_manifest_folder>" 
      extraManifests:
        filter:
          inclusionDefault: exclude  
          include:
            - custom-sctp-machine-config-worker.yaml
    ```

    -   Replace `<custom_manifest_folder>` with the name of the folder that contains the custom installation CRs, for example, `user-custom-manifest/`.

    -   Set `inclusionDefault` to `exclude` to prevent the ZTP pipeline from applying the files in `/source-crs/extra-manifest` during installation.

    The following example illustrates the custom folder structure:

    ``` text
    siteconfig
      ├── site1-sno-du.yaml
      └── user-custom-manifest
            └── custom-sctp-machine-config-worker.yaml
    ```

### Configuring PTP fast events using PolicyGenTemplate CRs

You can configure PTP fast events for vRAN clusters that are deployed using the GitOps Zero Touch Provisioning (ZTP) pipeline. Use `PolicyGenTemplate` custom resources (CRs) as the basis to create a hierarchy of configuration files tailored to your specific site requirements.

-   Create a Git repository where you manage your custom site configuration data.

1.  Add the following YAML into `.spec.sourceFiles` in the `common-ranGen.yaml` file to configure the AMQP Operator:

    ``` yaml
    #AMQ interconnect operator for fast events
    - fileName: AmqSubscriptionNS.yaml
      policyName: "subscriptions-policy"
    - fileName: AmqSubscriptionOperGroup.yaml
      policyName: "subscriptions-policy"
    - fileName: AmqSubscription.yaml
      policyName: "subscriptions-policy"
    ```

2.  Apply the following `PolicyGenTemplate` changes to `group-du-3node-ranGen.yaml`, `group-du-sno-ranGen.yaml`, or `group-du-standard-ranGen.yaml` files according to your requirements:

    1.  In `.sourceFiles`, add the `PtpOperatorConfig` CR file that configures the AMQ transport host to the `config-policy`:

        ``` yaml
        - fileName: PtpOperatorConfigForEvent.yaml
          policyName: "config-policy"
        ```

    2.  Configure the `linuxptp` and `phc2sys` for the PTP clock type and interface. For example, add the following stanza into `.sourceFiles`:

        ``` yaml
        - fileName: PtpConfigSlave.yaml 
          policyName: "config-policy"
          metadata:
            name: "du-ptp-slave"
          spec:
            profile:
            - name: "slave"
              interface: "ens5f1" 
              ptp4lOpts: "-2 -s --summary_interval -4" 
              phc2sysOpts: "-a -r -m -n 24 -N 8 -R 16" 
            ptpClockThreshold: 
              holdOverTimeout: 30 #secs
              maxOffsetThreshold: 100  #nano secs
              minOffsetThreshold: -100 #nano secs
        ```

        -   Can be one `PtpConfigMaster.yaml`, `PtpConfigSlave.yaml`, or `PtpConfigSlaveCvl.yaml` depending on your requirements. `PtpConfigSlaveCvl.yaml` configures `linuxptp` services for an Intel E810 Columbiaville NIC. For configurations based on `group-du-sno-ranGen.yaml` or `group-du-3node-ranGen.yaml`, use `PtpConfigSlave.yaml`.

        -   Device specific interface name.

        -   You must append the `--summary_interval -4` value to `ptp4lOpts` in `.spec.sourceFiles.spec.profile` to enable PTP fast events.

        -   Required `phc2sysOpts` values. `-m` prints messages to `stdout`. The `linuxptp-daemon` `DaemonSet` parses the logs and generates Prometheus metrics.

        -   Optional. If the `ptpClockThreshold` stanza is not present, default values are used for the `ptpClockThreshold` fields. The stanza shows default `ptpClockThreshold` values. The `ptpClockThreshold` values configure how long after the PTP master clock is disconnected before PTP events are triggered. `holdOverTimeout` is the time value in seconds before the PTP clock event state changes to `FREERUN` when the PTP master clock is disconnected. The `maxOffsetThreshold` and `minOffsetThreshold` settings configure offset values in nanoseconds that compare against the values for `CLOCK_REALTIME` (`phc2sys`) or master offset (`ptp4l`). When the `ptp4l` or `phc2sys` offset value is outside this range, the PTP clock state is set to `FREERUN`. When the offset value is within this range, the PTP clock state is set to `LOCKED`.

3.  Apply the following `PolicyGenTemplate` changes to your specific site YAML files, for example, `example-sno-site.yaml`:

    1.  In `.sourceFiles`, add the `Interconnect` CR file that configures the AMQ router to the `config-policy`:

        ``` yaml
        - fileName: AmqInstance.yaml
          policyName: "config-policy"
        ```

4.  Merge any other required changes and files with your custom site repository.

5.  Push the changes to your site configuration repository to deploy PTP fast events to new sites using GitOps ZTP.

### Configuring UEFI secure boot for clusters using PolicyGenTemplate CRs

You can configure UEFI secure boot for vRAN clusters that are deployed using the GitOps zero touch provisioning (ZTP) pipeline.

-   Create a Git repository where you manage your custom site configuration data.

1.  Create the following `MachineConfig` resource and save it in the `uefi-secure-boot.yaml` file:

    ``` yaml
    apiVersion: machineconfiguration.openshift.io/v1
    kind: MachineConfig
    metadata:
      labels:
        machineconfiguration.openshift.io/role: master
      name: uefi-secure-boot
    spec:
      config:
        ignition:
          version: 3.1.0
      kernelArguments:
        - efi=runtime
    ```

2.  In your Git repository custom `/siteconfig` directory, create a `/sno-extra-manifest` folder and add the `uefi-secure-boot.yaml` file, for example:

    ``` text
    siteconfig
    ├── site1-sno-du.yaml
    ├── site2-standard-du.yaml
    └── sno-extra-manifest
        └── uefi-secure-boot.yaml
    ```

3.  In your cluster `SiteConfig` CR, specify the required values for `extraManifestPath` and `bootMode`:

    1.  Enter the directory name in the `.spec.clusters.extraManifestPath` field, for example:

        ``` yaml
        clusters:
          - clusterName: "example-cluster"
            extraManifestPath: sno-extra-manifest/
        ```

    2.  Set the value for `.spec.clusters.nodes.bootMode` to `UEFISecureBoot`, for example:

        ``` yaml
        nodes:
          - hostName: "ran.example.lab"
            bootMode: "UEFISecureBoot"
        ```

4.  Deploy the cluster using the GitOps ZTP pipeline.

<!-- -->

1.  Open a remote shell to the deployed cluster, for example:

    ``` terminal
    $ oc debug node/node-1.example.com
    ```

2.  Verify that the `SecureBoot` feature is enabled:

    ``` terminal
    sh-4.4# mokutil --sb-state
    ```

    **Example output**

    ``` terminal
    SecureBoot enabled
    ```

### Configuring bare-metal event monitoring using PolicyGenTemplate CRs

You can configure bare-metal hardware events for vRAN clusters that are deployed using the GitOps Zero Touch Provisioning (ZTP) pipeline.

-   Install the OpenShift CLI (`oc`).

-   Log in as a user with `cluster-admin` privileges.

-   Create a Git repository where you manage your custom site configuration data.

!!! note
    Multiple HardwareEvent resources are not permitted.

Multiple `HardwareEvent` resources are not permitted.

1.  To configure the AMQ Interconnect Operator and the Bare Metal Event Relay Operator, add the following YAML to `spec.sourceFiles` in the `common-ranGen.yaml` file:

    ``` yaml
    # AMQ interconnect operator for fast events
    - fileName: AmqSubscriptionNS.yaml
      policyName: "subscriptions-policy"
    - fileName: AmqSubscriptionOperGroup.yaml
      policyName: "subscriptions-policy"
    - fileName: AmqSubscription.yaml
      policyName: "subscriptions-policy"
    # Bare Metal Event Rely operator
    - fileName: BareMetalEventRelaySubscriptionNS.yaml
      policyName: "subscriptions-policy"
    - fileName: BareMetalEventRelaySubscriptionOperGroup.yaml
      policyName: "subscriptions-policy"
    - fileName: BareMetalEventRelaySubscription.yaml
      policyName: "subscriptions-policy"
    ```

2.  Add the `Interconnect` CR to `.spec.sourceFiles` in the site configuration file, for example, the `example-sno-site.yaml` file:

    ``` yaml
    - fileName: AmqInstance.yaml
      policyName: "config-policy"
    ```

3.  Add the `HardwareEvent` CR to `spec.sourceFiles` in your specific group configuration file, for example, in the `group-du-sno-ranGen.yaml` file:

    ``` yaml
    - fileName: HardwareEvent.yaml
      policyName: "config-policy"
      spec:
        nodeSelector: {}
        transportHost: "amqp://<amq_interconnect_name>.<amq_interconnect_namespace>.svc.cluster.local" 
        logLevel: "info"
    ```

    -   The `transportHost` URL is composed of the existing AMQ Interconnect CR `name` and `namespace`. For example, in `transportHost: "amqp://amq-router.amq-router.svc.cluster.local"`, the AMQ Interconnect `name` and `namespace` are both set to `amq-router`.

4.  Commit the `PolicyGenTemplate` change in Git, and then push the changes to your site configuration repository to deploy bare-metal events monitoring to new sites using GitOps ZTP.

5.  Create the Redfish Secret by running the following command:

    ``` terminal
    $ oc -n openshift-bare-metal-events create secret generic redfish-basic-auth \
    --from-literal=username=<bmc_username> --from-literal=password=<bmc_password> \
    --from-literal=hostaddr="<bmc_host_ip_addr>"
    ```

-   For more information about how to install the Bare Metal Event Relay, see [Installing the Bare Metal Event Relay using the CLI](../monitoring/using-rfhe.xml#nw-rfhe-installing-operator-cli_using-rfhe).

-   For more information about how to install the AMQ Interconnect Operator, see [Installing the AMQ messaging bus](../monitoring/using-rfhe.html#hw-installing-amq-interconnect-messaging-bus_using-rfhe).

-   For more information about how to create the username, password, and the host IP address for the secret, see [Creating the bare-metal event and Secret CRs](../monitoring/using-rfhe.html#nw-rfhe-creating-hardware-event_using-rfhe).

## Installing the GitOps ZTP pipeline

The procedures in this section tell you how to complete the following tasks:

-   Prepare the Git repository you need to host site configuration data.

-   Configure the hub cluster for generating the required installation and policy custom resources (CR).

-   Deploy the managed clusters using zero touch provisioning (ZTP).

### Preparing the ZTP Git repository

Create a Git repository for hosting site configuration data. The zero touch provisioning (ZTP) pipeline requires read access to this repository.

1.  Create a directory structure with separate paths for the `SiteConfig` and `PolicyGenTemplate` custom resources (CR).

2.  Export the `argocd` directory from the `ztp-site-generate` container image using the following commands:

    ``` terminal
    $ podman pull registry.redhat.io/openshift4/ztp-site-generate-rhel8:v{product-version}
    ```

    ``` terminal
    $ mkdir -p ./out
    ```

    ``` terminal
    $ podman run --log-driver=none --rm registry.redhat.io/openshift4/ztp-site-generate-rhel8:v{product-version} extract /home/ztp --tar | tar x -C ./out
    ```

3.  Check that the `out` directory contains the following subdirectories:

    -   `out/extra-manifest` contains the source CR files that `SiteConfig` uses to generate extra manifest `configMap`.

    -   `out/source-crs` contains the source CR files that `PolicyGenTemplate` uses to generate the Red Hat Advanced Cluster Management (RHACM) policies.

    -   `out/argocd/deployment` contains patches and YAML files to apply on the hub cluster for use in the next step of this procedure.

    -   `out/argocd/example` contains the examples for `SiteConfig` and `PolicyGenTemplate` files that represent the recommended configuration.

The directory structure under `out/argocd/example` serves as a reference for the structure and content of your Git repository. The example includes `SiteConfig` and `PolicyGenTemplate` reference CRs for single-node, three-node, and standard clusters. Remove references to cluster types that you are not using. The following example describes a set of CRs for a network of single-node clusters:

``` terminal
example/
├── policygentemplates
│   ├── common-ranGen.yaml
│   ├── example-sno-site.yaml
│   ├── group-du-sno-ranGen.yaml
│   ├── group-du-sno-validator-ranGen.yaml
│   ├── kustomization.yaml
│   └── ns.yaml
└── siteconfig
    ├── example-sno.yaml
    ├── KlusterletAddonConfigOverride.yaml
    └── kustomization.yaml
```

Keep `SiteConfig` and `PolicyGenTemplate` CRs in separate directories. Both the `SiteConfig` and `PolicyGenTemplate` directories must contain a `kustomization.yaml` file that explicitly includes the files in that directory.

This directory structure and the `kustomization.yaml` files must be committed and pushed to your Git repository. The initial push to Git should include the `kustomization.yaml` files. The `SiteConfig` (`example-sno.yaml`) and `PolicyGenTemplate` (`common-ranGen.yaml`, `group-du-sno*.yaml`, and `example-sno-site.yaml`) files can be omitted and pushed at a later time as required when deploying a site.

The `KlusterletAddonConfigOverride.yaml` file is only required if one or more `SiteConfig` CRs which make reference to it are committed and pushed to Git. See `example-sno.yaml` for an example of how this is used.

### Preparing the hub cluster for ZTP

You can configure your hub cluster with a set of ArgoCD applications that generate the required installation and policy custom resources (CR) for each site based on a zero touch provisioning (ZTP) GitOps flow.

-   Openshift Cluster 4.11 as the hub cluster

-   Red Hat Advanced Cluster Management (RHACM) Operator 2.5 installed on the hub cluster

-   Red Hat OpenShift GitOps Operator 1.5 on the hub cluster

1.  Install the Topology Aware Lifecycle Manager (TALM), which coordinates with any new sites added by ZTP and manages application of the `PolicyGenTemplate`-generated policies.

2.  Prepare the ArgoCD pipeline configuration:

    1.  Create a Git repository with the directory structure similar to the example directory. For more information, see "Preparing the ZTP Git repository".

    2.  Configure access to the repository using the ArgoCD UI. Under **Settings** configure the following:

        -   **Repositories** - Add the connection information. The URL must end in `.git`, for example, `https://repo.example.com/repo.git` and credentials.

        -   **Certificates** - Add the public certificate for the repository, if needed.

    3.  Modify the two ArgoCD Applications, `out/argocd/deployment/clusters-app.yaml` and `out/argocd/deployment/policies-app.yaml`, based on your Git repository:

        -   Update the URL to point to the Git repository. The URL must end with `.git`, for example, `https://repo.example.com/repo.git`.

        -   The `targetRevision` must indicate which Git repository branch to monitor.

        -   The path should specify the path to the `SiteConfig` or `PolicyGenTemplate` CRs, respectively.

3.  To patch the ArgoCD instance in the hub cluster by using the patch file previously extracted into the `out/argocd/deployment/` directory, enter the following command:

    ``` terminal
    $ oc patch argocd openshift-gitops \
    -n openshift-gitops --type=merge \
    --patch-file out/argocd/deployment/argocd-openshift-gitops-patch.json
    ```

4.  Apply the pipeline configuration to your hub cluster by using the following command:

    ``` terminal
    $ oc apply -k out/argocd/deployment
    ```

### Deploying additional changes to clusters

Custom resources (CRs) that are deployed through the GitOps zero touch provisioning (ZTP) pipeline support two goals:

1.  Deploying additional Operators to spoke clusters that are required by typical RAN DU applications running at the network far-edge.

2.  Customizing the {product-title} installation to provide a high performance platform capable of meeting the strict timing requirements in a minimal CPU budget.

If you require cluster configuration changes outside of the base GitOps ZTP pipeline configuration, there are three options:

Apply the additional configuration after the ZTP pipeline is complete  
When the GitOps ZTP pipeline deployment is complete, the deployed cluster is ready for application workloads. At this point, you can install additional Operators and apply configurations specific to your requirements. Ensure that additional configurations do not negatively affect the performance of the platform or allocated CPU budget.

Add content to the ZTP library  
The base source CRs that you deploy with the GitOps ZTP pipeline can be augmented with custom content as required.

Create extra manifests for the cluster installation  
Extra manifests are applied during installation and makes the installation process more efficient.

!!! important
    Providing additional source CRs or modifying existing source CRs can significantly impact the performance or CPU profile of {product-title}.

Providing additional source CRs or modifying existing source CRs can significantly impact the performance or CPU profile of {product-title}.

-   See [Adding new content to the GitOps ZTP pipeline](../scalability_and_performance/ztp-deploying-disconnected.xml#ztp-adding-new-content-to-gitops-ztp_ztp-deploying-disconnected) for more information about adding or modifying existing source CRs in the `ztp-site-generate` container.

-   See [Customizing the ZTP GitOps pipeline with extra manifests](../scalability_and_performance/ztp-deploying-disconnected.xml#ztp-customizing-the-install-extra-manifests_ztp-deploying-disconnected) for more information on adding extra manifests.

## Adding new content to the GitOps ZTP pipeline

The source CRs in the GitOps ZTP site generator container provide a set of critical features and node tuning settings for RAN Distributed Unit (DU) applications. These are applied to the clusters that you deploy with ZTP. To add or modify existing source CRs in the `ztp-site-generate` container, rebuild the `ztp-site-generate` container and make it available to the hub cluster, typically from the disconnected registry associated with the hub cluster. Any valid {product-title} CR can be added.

Perform the following procedure to add new content to the ZTP pipeline.

1.  Create a directory containing a Containerfile and the source CR YAML files that you want to include in the updated `ztp-site-generate` container, for example:

    ``` text
    ztp-update/
    ├── example-cr1.yaml
    ├── example-cr2.yaml
    └── ztp-update.in
    ```

2.  Add the following content to the `ztp-update.in` Containerfile:

    ``` text
    FROM registry.redhat.io/openshift4/ztp-site-generate-rhel8:v{product-version}

    ADD example-cr2.yaml /kustomize/plugin/ran.openshift.io/v1/policygentemplate/source-crs/
    ADD example-cr1.yaml /kustomize/plugin/ran.openshift.io/v1/policygentemplate/source-crs/
    ```

3.  Open a terminal at the `ztp-update/` folder and rebuild the container:

    ``` terminal
    $ podman build -t ztp-site-generate-rhel8-custom:v{product-version}-custom-1
    ```

4.  Push the built container image to your disconnected registry, for example:

    ``` terminal
    $ podman push localhost/ztp-site-generate-rhel8-custom:v{product-version}-custom-1 registry.example.com:5000/ztp-site-generate-rhel8-custom:v{product-version}-custom-1
    ```

5.  Patch the Argo CD instance on the hub cluster to point to the newly built container image:

    ``` terminal
    $ oc patch -n openshift-gitops argocd openshift-gitops --type=json -p '[{"op": "replace", "path":"/spec/repo/initContainers/0/image", "value": "registry.example.com:5000/ztp-site-generate-rhel8-custom:v{product-version}-custom-1"} ]'
    ```

    When the Argo CD instance is patched, the `openshift-gitops-repo-server` pod automatically restarts.

<!-- -->

1.  Verify that the new `openshift-gitops-repo-server` pod has completed initialization and that the previous repo pod is terminated:

    ``` terminal
    $ oc get pods -n openshift-gitops | grep openshift-gitops-repo-server
    ```

    **Example output**

    ``` terminal
    openshift-gitops-server-7df86f9774-db682          1/1     Running         1          28s
    ```

    You must wait until the new `openshift-gitops-repo-server` pod has completed initialization and the previous pod is terminated before the newly added container image content is available.

-   Alternatively, you can patch the Argo CD instance as described in [Preparing the hub cluster for ZTP](../scalability_and_performance/ztp-deploying-disconnected.xml#ztp-preparing-the-hub-cluster-for-ztp_ztp-deploying-disconnected) by modifying `argocd-openshift-gitops-patch.json` with an updated `initContainer` image before applying the patch file.

## Customizing extra installation manifests in the ZTP GitOps pipeline

You can define a set of extra manifests for inclusion in the installation phase of the zero touch provisioning (ZTP) GitOps pipeline. These manifests are linked to the `SiteConfig` custom resources (CRs) and are applied to the cluster during installation. Including `MachineConfig` CRs at install time makes the installation process more efficient.

-   Create a Git repository where you manage your custom site configuration data. The repository must be accessible from the hub cluster and be defined as a source repository for the Argo CD application.

1.  Create a set of extra manifest CRs that the ZTP pipeline uses to customize the cluster installs.

2.  In your custom `/siteconfig` directory, create an `/extra-manifest` folder for your extra manifests. The following example illustrates a sample `/siteconfig` with `/extra-manifest` folder:

    ``` text
    siteconfig
    ├── site1-sno-du.yaml
    ├── site2-standard-du.yaml
    └── extra-manifest
        └── 01-example-machine-config.yaml
    ```

3.  Add your custom extra manifest CRs to the `siteconfig/extra-manifest` directory.

4.  In your `SiteConfig` CR, enter the directory name in the `extraManifestPath` field, for example:

    ``` yaml
    clusters:
    - clusterName: "example-sno"
      networkType: "OVNKubernetes"
      extraManifestPath: extra-manifest
    ```

5.  Save the `SiteConfig` CRs and `/extra-manifest` CRs and push them to the site configuration repo.

The ZTP pipeline appends the CRs in the `/extra-manifest` directory to the default set of extra manifests during cluster provisioning.

## Deploying a site

Use the following procedure to prepare the hub cluster for site deployment and initiate zero touch provisioning (ZTP) by pushing custom resources (CRs) to your Git repository.

1.  Create the required secrets for the site. These resources must be in a namespace with a name matching the cluster name. In `out/argocd/example/siteconfig/example-sno.yaml`, the cluster name and namespace is `example-sno`.

    Create the namespace for the cluster using the following commands:

    ``` terminal
    $ export CLUSTERNS=example-sno
    ```

    ``` terminal
    $ oc create namespace $CLUSTERNS
    ```

2.  Create a pull secret for the cluster. The pull secret must contain all the credentials necessary for installing {product-title} and all required Operators. In all of the example `SiteConfig` CRs, the pull secret is named `assisted-deployment-pull-secret`, as shown below:

    ``` terminal
    $ oc apply -f - <<EOF
    apiVersion: v1
    kind: Secret
    metadata:
      name: assisted-deployment-pull-secret
      namespace: $CLUSTERNS
    type: kubernetes.io/dockerconfigjson
    data:
      .dockerconfigjson: $(base64 <pull-secret.json)
    EOF
    ```

3.  Create a BMC authentication secret for each host you are deploying:

    ``` yaml
    $ oc apply -f - <<EOF
    apiVersion: v1
    kind: Secret
    metadata:
      name: $(read -p 'Hostname: ' tmp; printf $tmp)-bmc-secret
      namespace: $CLUSTERNS
    type: Opaque
    data:
      username: $(read -p 'Username: ' tmp; printf $tmp | base64)
      password: $(read -s -p 'Password: ' tmp; printf $tmp | base64)
    EOF
    ```

    !!! note
        The secrets are referenced from the SiteConfig custom resource (CR) by name. The namespace must match the SiteConfig namespace.
    The secrets are referenced from the `SiteConfig` custom resource (CR) by name. The namespace must match the `SiteConfig` namespace.

4.  Create a `SiteConfig` CR for your cluster in your local clone of the Git repository:

    1.  Choose the appropriate example for your CR from the `out/argocd/example/siteconfig/` folder. The folder includes example files for single node, three-node, and standard clusters:

        -   `example-sno.yaml`

        -   `example-3node.yaml`

        -   `example-standard.yaml`

    2.  Change the cluster and host details in the example file to match the type of cluster you want. The following file is a composite of the three files that explains the configuration of each cluster type:

        ``` yaml
        # example-node1-bmh-secret & assisted-deployment-pull-secret need to be created under same namespace example-sno
        ---
        apiVersion: ran.openshift.io/v1
        kind: SiteConfig
        metadata:
          name: "example-sno"
          namespace: "example-sno"
        spec:
          baseDomain: "example.com"
          pullSecretRef:
            name: "assisted-deployment-pull-secret"
          clusterImageSetNameRef: "openshift-{product-version}" 
          sshPublicKey: "ssh-rsa AAAA..."
          clusters:
          - clusterName: "example-sno"
            networkType: "OVNKubernetes"
            clusterLabels: 
              # These example cluster labels correspond to the bindingRules in the PolicyGenTemplate examples in ../policygentemplates:
              # ../policygentemplates/common-ranGen.yaml will apply to all clusters with 'common: true'
              common: true
              # ../policygentemplates/group-du-sno-ranGen.yaml will apply to all clusters with 'group-du-sno: ""'
              group-du-sno: ""
              # ../policygentemplates/example-sno-site.yaml will apply to all clusters with 'sites: "example-sno"'
              # Normally this should match or contain the cluster name so it only applies to a single cluster
              sites : "example-sno"
            clusterNetwork:
              - cidr: 1001:1::/48
                hostPrefix: 64
            machineNetwork: 
              - cidr: 1111:2222:3333:4444::/64
              # For 3-node and standard clusters with static IPs, the API and Ingress IPs must be configured here
            apiVIP: 1111:2222:3333:4444::1:1 
            ingressVIP: 1111:2222:3333:4444::1:2 

            serviceNetwork:
              - 1001:2::/112
            additionalNTPSources:
              - 1111:2222:3333:4444::2
            nodes:
              - hostName: "example-node1.example.com" 
                role: "master"
                bmcAddress: idrac-virtualmedia://<out_of_band_ip>/<system_id>/ 
                bmcCredentialsName:
                  name: "example-node1-bmh-secret" 
                bootMACAddress: "AA:BB:CC:DD:EE:11"
                bootMode: "UEFI"
                rootDeviceHints:
                  hctl: '0:1:0'
                cpuset: "0-1,52-53"
                nodeNetwork: 
                  interfaces:
                    - name: eno1
                      macAddress: "AA:BB:CC:DD:EE:11"
                  config:
                    interfaces:
                      - name: eno1
                        type: ethernet
                        state: up
                        macAddress: "AA:BB:CC:DD:EE:11"
                        ipv4:
                          enabled: false
                        ipv6:
                          enabled: true
                          address:
                          - ip: 1111:2222:3333:4444::1:1
                            prefix-length: 64
                    dns-resolver:
                      config:
                        search:
                        - example.com
                        server:
                        - 1111:2222:3333:4444::2
                    routes:
                      config:
                      - destination: ::/0
                        next-hop-interface: eno1
                        next-hop-address: 1111:2222:3333:4444::1
                        table-id: 254
        ```

        -   Applies to all cluster types. The value must match an image set available on the hub cluster. To see the list of supported versions on your hub, run `oc get clusterimagesets`.

        -   Applies to all cluster types. These values must correspond to the `PolicyGenTemplate` labels that you define in a later step.

        -   Applies to single node clusters. The value defines the cluster network sections for a single node deployment.

        -   Applies to three-node and standard clusters. The value defines the cluster network sections.

        -   Applies to three-node and standard clusters. The value defines the cluster network sections.

        -   Applies to all cluster types. For single node deployments, define one host. For three-node deployments, define three hosts. For standard deployments, define three hosts with `role: master` and two or more hosts defined with `role: worker`.

        -   Applies to all cluster types. Specifies the BMC address. ZTP supports iPXE and virtual media booting by using Redfish or IPMI protocols. For more information about BMC addressing, see the *Additional resources* section.

        -   Applies to all cluster types. Specifies the BMC credentials.

        -   Applies to all cluster types. Specifies the network settings for the node.

    3.  You can inspect the default set of extra-manifest `MachineConfig` CRs in `out/argocd/extra-manifest`. It is automatically applied to the cluster when it is installed.

        Optional: To provision additional install-time manifests on the provisioned cluster, create a directory in your Git repository, for example, `sno-extra-manifest/`, and add your custom manifest CRs to this directory. If your `SiteConfig.yaml` refers to this directory in the `extraManifestPath` field, any CRs in this referenced directory are appended to the default set of extra manifests.

5.  Add the `SiteConfig` CR to the `kustomization.yaml` file in the `generators` section, similar to the example shown in `out/argocd/example/siteconfig/kustomization.yaml`.

6.  Commit your `SiteConfig` CR and associated `kustomization.yaml` in your Git repository.

7.  Push your changes to the Git repository. The ArgoCD pipeline detects the changes and begins the site deployment. You can push the changes to the `SiteConfig` CR and the `PolicyGenTemplate` CR simultaneously.

    The `SiteConfig` CR creates the following CRs on the hub cluster:

    -   `Namespace` - Unique per site

    -   `AgentClusterInstall`

    -   `BareMetalHost` - One per node

    -   `ClusterDeployment`

    -   `InfraEnv`

    -   `NMStateConfig` - One per node

    -   `ExtraManifestsConfigMap` - Extra manifests. The extra manifests include workload partitioning, mountpoint hiding, sctp enablement, and more. To automatically merge the extra manifests into a single manifest per each `MachineConfigPool` role, which is named as `predefined-extra-manifests-<role>`, set the `.spec.clusters.mergeDefaultMachineConfigs` to `true` in the `SiteConfig.yaml` file.

    -   `ManagedCluster`

    -   `KlusterletAddonConfig`

-   [BMC addressing](../installing/installing_bare_metal_ipi/ipi-install-installation-workflow.xml#bmc-addressing_ipi-install-installation-workflow)

## GitOps ZTP and Topology Aware Lifecycle Manager

GitOps zero touch provisioning (ZTP) generates installation and configuration CRs from manifests stored in Git. These artifacts are applied to a centralized hub cluster where Red Hat Advanced Cluster Management (RHACM), assisted installer service, and the Topology Aware Lifecycle Manager (TALM) use the CRs to install and configure the spoke cluster. The configuration phase of the ZTP pipeline uses the TALM to orchestrate the application of the configuration CRs to the cluster. There are several key integration points between GitOps ZTP and the TALM.

Inform policies  
By default, GitOps ZTP creates all policies with a remediation action of `inform`. These policies cause RHACM to report on compliance status of clusters relevant to the policies but does not apply the desired configuration. During the ZTP installation, the TALM steps through the created `inform` policies, creates a copy for the target spoke cluster(s) and changes the remediation action of the copy to `enforce`. This pushes the configuration to the spoke cluster. Outside of the ZTP phase of the cluster lifecycle, this setup allows changes to be made to policies without the risk of immediately rolling those changes out to all affected spoke clusters in the network. You can control the timing and the set of clusters that are remediated using TALM.

Automatic creation of ClusterGroupUpgrade CRs  
The TALM monitors the state of all `ManagedCluster` CRs on the hub cluster. Any `ManagedCluster` CR which does not have a `ztp-done` label applied, including newly created `ManagedCluster` CRs, causes the TALM to automatically create a `ClusterGroupUpgrade` CR with the following characteristics:

-   The `ClusterGroupUpgrade` CR is created and enabled in the `ztp-install` namespace.

-   `ClusterGroupUpgrade` CR has the same name as the `ManagedCluster` CR.

-   The cluster selector includes only the cluster associated with that `ManagedCluster` CR.

-   The set of managed policies includes all policies that RHACM has bound to the cluster at the time the `ClusterGroupUpgrade` is created.

-   Pre-caching is disabled.

-   Timeout set to 4 hours (240 minutes).

    The automatic creation of an enabled `ClusterGroupUpgrade` ensures that initial zero-touch deployment of clusters proceeds without the need for user intervention. Additionally, the automatic creation of a `ClusterGroupUpgrade` CR for any `ManagedCluster` without the `ztp-done` label allows a failed ZTP installation to be restarted by simply deleting the `ClusterGroupUpgrade` CR for the cluster.

Waves  
Each policy generated from a `PolicyGenTemplate` CR includes a `ztp-deploy-wave` annotation. This annotation is based on the same annotation from each CR which is included in that policy. The wave annotation is used to order the policies in the auto-generated `ClusterGroupUpgrade` CR.

!!! note
    All CRs in the same policy must have the same setting for the ztp-deploy-wave annotation. The default value of this annotation for each CR can be overridden in the PolicyGenTemplate. The wave annotation in the source CR is used for determining and setting the policy wave annotation. This annotation is removed from each built CR which is included in the generated policy at runtime.
All CRs in the same policy must have the same setting for the `ztp-deploy-wave` annotation. The default value of this annotation for each CR can be overridden in the `PolicyGenTemplate`. The wave annotation in the source CR is used for determining and setting the policy wave annotation. This annotation is removed from each built CR which is included in the generated policy at runtime.

The TALM applies the configuration policies in the order specified by the wave annotations. The TALM waits for each policy to be compliant before moving to the next policy. It is important to ensure that the wave annotation for each CR takes into account any prerequisites for those CRs to be applied to the cluster. For example, an Operator must be installed before or concurrently with the configuration for the Operator. Similarly, the `CatalogSource` for an Operator must be installed in a wave before or concurrently with the Operator Subscription. The default wave value for each CR takes these prerequisites into account.

Multiple CRs and policies can share the same wave number. Having fewer policies can result in faster deployments and lower CPU usage. It is a best practice to group many CRs into relatively few waves.

To check the default wave value in each source CR, run the following command against the `out/source-crs` directory that is extracted from the `ztp-site-generate` container image:

``` terminal
$ grep -r "ztp-deploy-wave" out/source-crs
```

Phase labels  
The `ClusterGroupUpgrade` CR is automatically created and includes directives to annotate the `ManagedCluster` CR with labels at the start and end of the ZTP process.

When ZTP configuration post-installation commences, the `ManagedCluster` has the `ztp-running` label applied. When all policies are remediated to the cluster and are fully compliant, these directives cause the TALM to remove the `ztp-running` label and apply the `ztp-done` label.

For deployments which make use of the `informDuValidator` policy, the `ztp-done` label is applied when the cluster is fully ready for deployment of applications. This includes all reconciliation and resulting effects of the ZTP applied configuration CRs.

Linked CRs  
The automatically created `ClusterGroupUpgrade` CR has the owner reference set as the `ManagedCluster` from which it was derived. This reference ensures that deleting the `ManagedCluster` CR causes the instance of the `ClusterGroupUpgrade` to be deleted along with any supporting resources.

## Monitoring deployment progress

The ArgoCD pipeline uses the `SiteConfig` and `PolicyGenTemplate` CRs in Git to generate the cluster configuration CRs and RHACM policies and then sync them to the hub. You can monitor the progress of this synchronization can be monitored in the ArgoCD dashboard.

**Procedure**

When the synchronization is complete, the installation generally proceeds as follows:

1.  The Assisted Service Operator installs {product-title} on the cluster. You can monitor the progress of cluster installation from the RHACM dashboard or from the command line:

    ``` terminal
    $ export CLUSTER=<clusterName>
    ```

    ``` terminal
    $ oc get agentclusterinstall -n $CLUSTER $CLUSTER -o jsonpath='{.status.conditions[?(@.type=="Completed")]}' | jq
    ```

    ``` terminal
    $ curl -sk $(oc get agentclusterinstall -n $CLUSTER $CLUSTER -o jsonpath='{.status.debugInfo.eventsURL}')  | jq '.[-2,-1]'
    ```

2.  The Topology Aware Lifecycle Manager (TALM) applies the configuration policies that are bound to the cluster.

    After the cluster installation is complete and the cluster becomes `Ready`, a `ClusterGroupUpgrade` CR corresponding to this cluster, with a list of ordered policies defined by the `ran.openshift.io/ztp-deploy-wave annotations`, is automatically created by the TALM. The cluster’s policies are applied in the order listed in `ClusterGroupUpgrade` CR. You can monitor the high-level progress of configuration policy reconciliation using the following commands:

    ``` terminal
    $ export CLUSTER=<clusterName>
    ```

    ``` terminal
    $ oc get clustergroupupgrades -n ztp-install $CLUSTER -o jsonpath='{.status.conditions[?(@.type=="Ready")]}'
    ```

3.  You can monitor the detailed policy compliant status using the RHACM dashboard or the command line:

    ``` terminal
    $ oc get policies -n $CLUSTER
    ```

The final policy that becomes compliant is the one defined in the `*-du-validator-policy` policies. This policy, when compliant on a cluster, ensures that all cluster configuration, Operator installation, and Operator configuration is complete.

After all policies become complaint, the `ztp-done` label is added to the cluster, indicating the entire ZTP pipeline is complete for the cluster.

## Indication of done for ZTP installations

Zero touch provisioning (ZTP) simplifies the process of checking the ZTP installation status for a cluster. The ZTP status moves through three phases: cluster installation, cluster configuration, and ZTP done.

Cluster installation phase  
The cluster installation phase is shown by the `ManagedCluster` CR `ManagedClusterJoined` condition. If the `ManagedCluster` CR does not have this condition, or the condition is set to `False`, the cluster is still in the installation phase. Additional details about installation are available from the `AgentClusterInstall` and `ClusterDeployment` CRs. For more information, see "Troubleshooting GitOps ZTP".

Cluster configuration phase  
The cluster configuration phase is shown by a `ztp-running` label applied the `ManagedCluster` CR for the cluster.

ZTP done  
Cluster installation and configuration is complete in the ZTP done phase. This is shown by the removal of the `ztp-running` label and addition of the `ztp-done` label to the `ManagedCluster` CR. The `ztp-done` label shows that the configuration has been applied and the baseline DU configuration has completed cluster tuning.

The transition to the ZTP done state is conditional on the compliant state of a Red Hat Advanced Cluster Management (RHACM) static validator inform policy. This policy captures the existing criteria for a completed installation and validates that it moves to a compliant state only when ZTP provisioning of the spoke cluster is complete.

The validator inform policy ensures the configuration of the distributed unit (DU) cluster is fully applied and Operators have completed their initialization. The policy validates the following:

-   The target `MachineConfigPool` contains the expected entries and has finished updating. All nodes are available and not degraded.

-   The SR-IOV Operator has completed initialization as indicated by at least one `SriovNetworkNodeState` with `syncStatus: Succeeded`.

-   The PTP Operator daemon set exists.

    The policy captures the existing criteria for a completed installation and validates that it moves to a compliant state only when ZTP provisioning of the spoke cluster is complete.

    The validator inform policy is included in the reference group `PolicyGenTemplate` CRs. For reliable indication of the ZTP done state, this validator inform policy must be included in the ZTP pipeline.

### Creating a validator inform policy

Use the following procedure to create a validator inform policy that provides an indication of when the zero touch provisioning (ZTP) installation and configuration of the deployed cluster is complete. This policy can be used for deployments of single node clusters, three-node clusters, and standard clusters.

1.  Create a stand-alone `PolicyGenTemplate` custom resource (CR) that contains the source file `validatorCRs/informDuValidator.yaml`. You only need one stand-alone `PolicyGenTemplate` CR for each cluster type.

    **Single node clusters**

    ``` yaml
    group-du-sno-validator-ranGen.yaml
    apiVersion: ran.openshift.io/v1
    kind: PolicyGenTemplate
    metadata:
      name: "group-du-sno-validator" 
      namespace: "ztp-group" 
    spec:
      bindingRules:
        group-du-sno: "" 
      bindingExcludedRules:
        ztp-done: "" 
      mcp: "master" 
      sourceFiles:
        - fileName: validatorCRs/informDuValidator.yaml
          remediationAction: inform 
          policyName: "du-policy" 
    ```

    **Three-node clusters**

    ``` yaml
    group-du-3node-validator-ranGen.yaml
    apiVersion: ran.openshift.io/v1
    kind: PolicyGenTemplate
    metadata:
      name: "group-du-3node-validator" 
      namespace: "ztp-group" 
    spec:
      bindingRules:
        group-du-3node: "" 
      bindingExcludedRules:
        ztp-done: "" 
      mcp: "master" 
      sourceFiles:
        - fileName: validatorCRs/informDuValidator.yaml
          remediationAction: inform 
          policyName: "du-policy" 
    ```

    **Standard clusters**

    ``` yaml
    group-du-standard-validator-ranGen.yaml
    apiVersion: ran.openshift.io/v1
    kind: PolicyGenTemplate
    metadata:
      name: "group-du-standard-validator" 
      namespace: "ztp-group" 
    spec:
      bindingRules:
        group-du-standard: "" 
      bindingExcludedRules:
        ztp-done: "" 
      mcp: "worker" 
      sourceFiles:
        - fileName: validatorCRs/informDuValidator.yaml
          remediationAction: inform 
          policyName: "du-policy" 
    ```

    -   The name of `PolicyGenTemplates` object. This name is also used as part of the names for the `placementBinding`, `placementRule`, and `policy` that are created in the requested `namespace`.

    -   This value should match the `namespace` used in the group `PolicyGenTemplates`.

    -   The `group-du-*` label defined in `bindingRules` must exist in the `SiteConfig` files.

    -   The label defined in `bindingExcludedRules` must be\`ztp-done:\`. The `ztp-done` label is used in coordination with the Topology Aware Lifecycle Manager.

    -   `mcp` defines the `MachineConfigPool` object that is used in the source file `validatorCRs/informDuValidator.yaml`. It should be `master` for single node and three-node cluster deployments and `worker` for standard cluster deployments.

    -   Optional. The default value is `inform`.

    -   This value is used as part of the name for the generated RHACM policy. The generated validator policy for the single node example is named `group-du-sno-validator-du-policy`.

2.  Push the files to the ZTP Git repository.

### Querying the policy compliance status for each cluster

After you have created the validator inform policies for your clusters and pushed them to the zero touch provisioning (ZTP) Git repository, you can check the status of each cluster for policy compliance.

1.  To query the status of the spoke clusters, use either the Red Hat Advanced Cluster Management (RHACM) web console or the CLI:

    -   To query status from the RHACM web console, perform the following actions:

        1.  Click **Governance** → **Find policies**.

        2.  Search for **du-validator-policy**.

        3.  Click into the policy.

    -   To query status using the CLI, run the following command:

        ``` terminal
        $ oc get policies du-validator-policy -n <namespace_for_common> -o jsonpath={'.status.status'} | jq
        ```

        When all of the policies including the validator inform policy applied to the cluster become compliant, ZTP installation and configuration for this cluster is complete.

2.  To query the cluster violation/compliant status from the ACM web console, click **Governance** → **Cluster violations**.

3.  Check the validator policy compliant status for a cluster using the following commands:

    1.  Export the cluster name:

        ``` terminal
        $ export CLUSTER=<cluster_name>
        ```

    2.  Get the policy:

        ``` terminal
        $ oc get policies -n $CLUSTER | grep <validator_policy_name>
        ```

    Alternatively, you can use the following command:

    ``` terminal
    $ oc get policies -n <namespace-for-group> <validatorPolicyName> -o jsonpath="{.status.status[?(@.clustername=='$CLUSTER')]}" | jq
    ```

    After the `*-validator-du-policy` RHACM policy becomes compliant for the cluster, the validator policy is unbound for this cluster and the `ztp-done` label is added to the cluster. This acts as a persistent indicator that the whole ZTP pipeline has completed for the cluster.

### Node Tuning Operator

The Node Tuning Operator provides the ability to enable advanced node performance tunings on a set of nodes.

{product-title} provides a Node Tuning Operator to implement automatic tuning to achieve low latency performance for {product-title} applications. The cluster administrator uses this performance profile configuration that makes it easier to make these changes in a more reliable way.

The administrator can specify updating the kernel to `rt-kernel`, reserving CPUs for management workloads, and using CPUs for running the workloads.

!!! note
    In earlier versions of {product-title}, the Performance Addon Operator was used to implement automatic tuning to achieve low latency performance for OpenShift applications. In {product-title} 4.11, these functions are part of the Node Tuning Operator.

In earlier versions of {product-title}, the Performance Addon Operator was used to implement automatic tuning to achieve low latency performance for OpenShift applications. In {product-title} 4.11, these functions are part of the Node Tuning Operator.

## Troubleshooting GitOps ZTP

The ArgoCD pipeline uses the `SiteConfig` and `PolicyGenTemplate` custom resources (CRs) from Git to generate the cluster configuration CRs and Red Hat Advanced Cluster Management (RHACM) policies. Use the following steps to troubleshoot issues that might occur during this process.

file// Module included in the following assemblies:

### Validating the generation of installation CRs

The GitOps zero touch provisioning (ZTP) infrastructure generates a set of installation CRs on the hub cluster in response to a `SiteConfig` CR pushed to your Git repository. You can check that the installation CRs were created by using the following command:

``` terminal
$ oc get AgentClusterInstall -n <cluster_name>
```

If no object is returned, use the following procedure to troubleshoot the ArgoCD pipeline flow from `SiteConfig` files to the installation CRs.

1.  Verify that the `SiteConfig→ManagedCluster` was generated to the hub cluster:

    ``` terminal
    $ oc get managedcluster
    ```

2.  If the `SiteConfig` `ManagedCluster` is missing, see if the `clusters` application failed to synchronize the files from the Git repository to the hub:

    ``` terminal
    $ oc describe -n openshift-gitops application clusters
    ```

3.  Check for `Status: Conditions:` to view the error logs. For example, setting an invalid value for `extraManifestPath:` in the `siteConfig` file raises an error as shown below:

    ``` text
    Status:
      Conditions:
        Last Transition Time:  2021-11-26T17:21:39Z
        Message:               rpc error: code = Unknown desc = `kustomize build /tmp/https___git.com/ran-sites/siteconfigs/ --enable-alpha-plugins` failed exit status 1: 2021/11/26 17:21:40 Error could not create extra-manifest ranSite1.extra-manifest3 stat extra-manifest3: no such file or directory
    2021/11/26 17:21:40 Error: could not build the entire SiteConfig defined by /tmp/kust-plugin-config-913473579: stat extra-manifest3: no such file or directory
    Error: failure in plugin configured via /tmp/kust-plugin-config-913473579; exit status 1: exit status 1
        Type:  ComparisonError
    ```

4.  Check for `Status: Sync:`. If there are log errors, `Status: Sync:` could indicate an `Unknown` error:

    ``` text
    Status:
      Sync:
        Compared To:
          Destination:
            Namespace:  clusters-sub
            Server:     https://kubernetes.default.svc
          Source:
            Path:             sites-config
            Repo URL:         https://git.com/ran-sites/siteconfigs/.git
            Target Revision:  master
        Status:               Unknown
    ```

### Validating the generation of configuration policy CRs

Policy custom resources (CRs) are generated in the same namespace as the `PolicyGenTemplate` from which they are created. The same troubleshooting flow applies to all policy CRs generated from a `PolicyGenTemplate` regardless of whether they are `ztp-common`, `ztp-group`, or `ztp-site` based, as shown using the following commands:

``` terminal
$ export NS=<namespace>
```

``` terminal
$ oc get policy -n $NS
```

The expected set of policy-wrapped CRs should be displayed.

If the policies failed synchronization, use the following troubleshooting steps.

1.  To display detailed information about the policies, run the following command:

    ``` terminal
    $ oc describe -n openshift-gitops application policies
    ```

2.  Check for `Status: Conditions:` to show the error logs. For example, setting an invalid `sourceFile→fileName:` generates the error shown below:

    ``` text
    Status:
      Conditions:
        Last Transition Time:  2021-11-26T17:21:39Z
        Message:               rpc error: code = Unknown desc = `kustomize build /tmp/https___git.com/ran-sites/policies/ --enable-alpha-plugins` failed exit status 1: 2021/11/26 17:21:40 Error could not find test.yaml under source-crs/: no such file or directory
    Error: failure in plugin configured via /tmp/kust-plugin-config-52463179; exit status 1: exit status 1
        Type:  ComparisonError
    ```

3.  Check for `Status: Sync:`. If there are log errors at `Status: Conditions:`, the `Status: Sync:` shows `Unknown` or `Error`:

    ``` text
    Status:
      Sync:
        Compared To:
          Destination:
            Namespace:  policies-sub
            Server:     https://kubernetes.default.svc
          Source:
            Path:             policies
            Repo URL:         https://git.com/ran-sites/policies/.git
            Target Revision:  master
        Status:               Error
    ```

4.  When Red Hat Advanced Cluster Management (RHACM) recognizes that policies apply to a `ManagedCluster` object, the policy CR objects are applied to the cluster namespace. Check to see if the policies were copied to the cluster namespace:

    ``` terminal
    $ oc get policy -n $CLUSTER
    ```

    **Example output:**

    ``` terminal
    NAME                                         REMEDIATION ACTION   COMPLIANCE STATE   AGE
    ztp-common.common-config-policy              inform               Compliant          13d
    ztp-common.common-subscriptions-policy       inform               Compliant          13d
    ztp-group.group-du-sno-config-policy         inform               Compliant          13d
    Ztp-group.group-du-sno-validator-du-policy   inform               Compliant          13d
    ztp-site.example-sno-config-policy           inform               Compliant          13d
    ```

    RHACM copies all applicable policies into the cluster namespace. The copied policy names have the format: `<policyGenTemplate.Namespace>.<policyGenTemplate.Name>-<policyName>`.

5.  Check the placement rule for any policies not copied to the cluster namespace. The `matchSelector` in the `PlacementRule` for those policies should match labels on the `ManagedCluster` object:

    ``` terminal
    $ oc get placementrule -n $NS
    ```

6.  Note the `PlacementRule` name appropriate for the missing policy, common, group, or site, using the following command:

    ``` terminal
    $ oc get placementrule -n $NS <placementRuleName> -o yaml
    ```

    -   The status-decisions should include your cluster name.

    -   The key-value pair of the `matchSelector` in the spec must match the labels on your managed cluster.

7.  Check the labels on the `ManagedCluster` object using the following command:

    ``` terminal
    $ oc get ManagedCluster $CLUSTER -o jsonpath='{.metadata.labels}' | jq
    ```

8.  Check to see which policies are compliant using the following command:

    ``` terminal
    $ oc get policy -n $CLUSTER
    ```

    If the `Namespace`, `OperatorGroup`, and `Subscription` policies are compliant but the Operator configuration policies are not, it is likely that the Operators did not install on the spoke cluster. This causes the Operator configuration policies to fail to apply because the CRD is not yet applied to the spoke.

### Restarting policies reconciliation

Use the following procedure to restart policies reconciliation in the event of unexpected compliance issues. This procedure is required when the `ClusterGroupUpgrade` CR has timed out.

1.  A `ClusterGroupUpgrade` CR is generated in the namespace `ztp-install` by the Topology Aware Lifecycle Manager after the managed spoke cluster becomes `Ready`:

    ``` terminal
    $ export CLUSTER=<clusterName>
    ```

    ``` terminal
    $ oc get clustergroupupgrades -n ztp-install $CLUSTER
    ```

2.  If there are unexpected issues and the policies fail to become complaint within the configured timeout (the default is 4 hours), the status of the `ClusterGroupUpgrade` CR shows `UpgradeTimedOut`:

    ``` terminal
    $ oc get clustergroupupgrades -n ztp-install $CLUSTER -o jsonpath='{.status.conditions[?(@.type=="Ready")]}'
    ```

3.  A `ClusterGroupUpgrade` CR in the `UpgradeTimedOut` state automatically restarts its policy reconciliation every hour. If you have changed your policies, you can start a retry immediately by deleting the existing `ClusterGroupUpgrade` CR. This triggers the automatic creation of a new `ClusterGroupUpgrade` CR that begins reconciling the policies immediately:

    ``` terminal
    $ oc delete clustergroupupgrades -n ztp-install $CLUSTER
    ```

Note that when the `ClusterGroupUpgrade` CR completes with status `UpgradeCompleted` and the managed spoke cluster has the label `ztp-done` applied, you can make additional configuration changes using `PolicyGenTemplate`. Deleting the existing `ClusterGroupUpgrade` CR will not make the TALM generate a new CR.

At this point, ZTP has completed its interaction with the cluster and any further interactions should be treated as an upgrade.

-   For information about using TALM to construct your own `ClusterGroupUpgrade` CR, see [About the ClusterGroupUpgrade CR](../scalability_and_performance/cnf-talm-for-cluster-upgrades.xml#talo-about-cgu-crs_cnf-topology-aware-lifecycle-manager).

## Site cleanup

Remove a site and the associated installation and configuration policy CRs by removing the `SiteConfig` and `PolicyGenTemplate` file names from the `kustomization.yaml` file. When you run the ZTP pipeline again, the generated CRs are removed. If you want to permanently remove a site, you should also remove the `SiteConfig` and site-specific `PolicyGenTemplate` files from the Git repository. If you want to remove a site temporarily, for example when redeploying a site, you can leave the `SiteConfig` and site-specific `PolicyGenTemplate` CRs in the Git repository.

!!! note
    After removing the SiteConfig file, if the corresponding clusters remain in the detach process, check Red Hat Advanced Cluster Management (RHACM) for information about cleaning up the detached managed cluster.

After removing the `SiteConfig` file, if the corresponding clusters remain in the detach process, check Red Hat Advanced Cluster Management (RHACM) for information about cleaning up the detached managed cluster.

-   For information about removing a cluster, see [Removing a cluster from management](https://access.redhat.com/documentation/en-us/red_hat_advanced_cluster_management_for_kubernetes/2.4/html/clusters/managing-your-clusters#remove-managed-cluster).

### Removing obsolete content

If a change to the `PolicyGenTemplate` file configuration results in obsolete policies, for example, policies are renamed, use the following procedure to remove those policies in an automated way.

1.  Remove the affected `PolicyGenTemplate` files from the Git repository, commit and push to the remote repository.

2.  Wait for the changes to synchronize through the application and the affected policies to be removed from the hub cluster.

3.  Add the updated `PolicyGenTemplate` files back to the Git repository, and then commit and push to the remote repository.

Note that removing the zero touch provisioning (ZTP) distributed unit (DU) profile policies from the Git repository, and as a result also removing them from the hub cluster, does not affect any configuration of the managed spoke clusters. Removing a policy from the hub cluster does not delete it from the spoke cluster and the CRs managed by that policy.

As an alternative, after making changes to `PolicyGenTemplate` files that result in obsolete policies, you can remove these policies from the hub cluster manually. You can delete policies from the RHACM console using the **Governance** tab or by using the following command:

``` terminal
$ oc delete policy -n <namespace> <policyName>
```

### Tearing down the pipeline

If you need to remove the ArgoCD pipeline and all generated artifacts follow this procedure:

1.  Detach all clusters from RHACM.

2.  Delete the `kustomization.yaml` file in the `deployment` directory using the following command:

    ``` terminal
    $ oc delete -k out/argocd/deployment
    ```

## Upgrading GitOps ZTP

You can upgrade the Gitops zero touch provisioning (ZTP) infrastructure independently from the underlying cluster, Red Hat Advanced Cluster Management (RHACM), and {product-title} version running on the spoke clusters. This procedure guides you through the upgrade process to avoid impact on the spoke clusters. However, any changes to the content or settings of policies, including adding recommended content, results in changes that must be rolled out and reconciled to the spoke clusters.

-   This procedure assumes that you have a fully operational hub cluster running the earlier version of the GitOps ZTP infrastructure.

**Procedure**

At a high level, the strategy for upgrading the GitOps ZTP infrastructure is:

1.  Label all existing clusters with the `ztp-done` label.

2.  Stop the ArgoCD applications.

3.  Install the new tooling.

4.  Update required content and optional changes in the Git repository.

5.  Update and restart the application configuration.

### Preparing for the upgrade

Use the following procedure to prepare your site for the GitOps zero touch provisioning (ZTP) upgrade.

1.  Obtain the latest version of the GitOps ZTP container from which you can extract a set of custom resources (CRs) used to configure the GitOps operator on the hub cluster for use in the GitOps ZTP solution.

2.  Extract the `argocd/deployment` directory using the following commands:

    ``` terminal
    $ mkdir -p ./out
    ```

    ``` terminal
    $ podman run --log-driver=none --rm registry.redhat.io/openshift4/ztp-site-generate-rhel8:v{product-version} extract /home/ztp --tar | tar x -C ./out
    ```

    The `/out` directory contains the following subdirectories:

    -   `out/extra-manifest`: contains the source CR files that the `SiteConfig` CR uses to generate the extra manifest `configMap`.

    -   `out/source-crs`: contains the source CR files that the `PolicyGenTemplate` CR uses to generate the Red Hat Advanced Cluster Management (RHACM) policies.

    -   `out/argocd/deployment`: contains patches and YAML files to apply on the hub cluster for use in the next step of this procedure.

    -   `out/argocd/example`: contains example `SiteConfig` and `PolicyGenTemplate` files that represent the recommended configuration.

3.  Update the `clusters-app.yaml` and `policies-app.yaml` files to reflect the name of your applications and the URL, branch, and path for your Git repository.

If the upgrade includes changes to policies that may result in obsolete policies, these policies should be removed prior to performing the upgrade.

### Labeling the existing clusters

To ensure that existing clusters remain untouched by the tooling updates, all existing managed clusters must be labeled with the `ztp-done` label.

1.  Find a label selector that lists the managed clusters that were deployed with zero touch provisioning (ZTP), such as `local-cluster!=true`:

    ``` terminal
    $ oc get managedcluster -l 'local-cluster!=true'
    ```

2.  Ensure that the resulting list contains all the managed clusters that were deployed with ZTP, and then use that selector to add the `ztp-done` label:

    ``` terminal
    $ oc label managedcluster -l 'local-cluster!=true' ztp-done=
    ```

### Stopping the existing GitOps ZTP applications

Removing the existing applications ensures that any changes to existing content in the Git repository are not rolled out until the new version of the tooling is available.

Use the application files from the `deployment` directory. If you used custom names for the applications, update the names in these files first.

1.  Perform a non-cascaded delete on the `clusters` application to leave all generated resources in place:

    ``` terminal
    $ oc delete -f out/argocd/deployment/clusters-app.yaml
    ```

2.  Perform a cascaded delete on the `policies` application to remove all previous policies:

    ``` terminal
    $ oc patch -f policies-app.yaml -p '{"metadata": {"finalizers": ["resources-finalizer.argocd.argoproj.io"]}}' --type merge
    ```

    ``` terminal
    $ oc delete -f out/argocd/deployment/policies-app.yaml
    ```

### Topology Aware Lifecycle Manager

Install the Topology Aware Lifecycle Manager (TALM) on the hub cluster.

-   For information about the Topology Aware Lifecycle Manager (TALM), see [About the Topology Aware Lifecycle Manager configuration](../scalability_and_performance/cnf-talm-for-cluster-upgrades.xml#cnf-about-topology-aware-lifecycle-manager-config_cnf-topology-aware-lifecycle-manager).

### Required changes to the Git repository

When upgrading the `ztp-site-generate` container from an earlier release to the 4.10 version, additional requirements are placed on the contents of the Git repository. Existing content in the repository must be updated to reflect these changes.

-   Changes to `PolicyGenTemplate` files:

    All `PolicyGenTemplate` files must be created in a `Namespace` prefixed with `ztp`. This ensures that the GitOps zero touch provisioning (ZTP) application is able to manage the policy CRs generated by GitOps ZTP without conflicting with the way Red Hat Advanced Cluster Management (RHACM) manages the policies internally.

-   Remove the `pre-sync.yaml` and `post-sync.yaml` files:

    This step is optional but recommended. When the `kustomization.yaml` files are added, the `pre-sync.yaml` and `post-sync.yaml` files are no longer used. They must be removed to avoid confusion and can potentially cause errors if kustomization files are inadvertantly removed. Note that there is a set of `pre-sync.yaml` and `post-sync.yaml` files under both the `SiteConfig` and `PolicyGenTemplate` trees.

-   Add the `kustomization.yaml` file to the repository:

    All `SiteConfig` and `PolicyGenTemplate` CRs must be included in a `kustomization.yaml` file under their respective directory trees. For example:

    ``` terminal
    ├── policygentemplates
    │   ├── site1-ns.yaml
    │   ├── site1.yaml
    │   ├── site2-ns.yaml
    │   ├── site2.yaml
    │   ├── common-ns.yaml
    │   ├── common-ranGen.yaml
    │   ├── group-du-sno-ranGen-ns.yaml
    │   ├── group-du-sno-ranGen.yaml
    │   └── kustomization.yaml
    └── siteconfig
        ├── site1.yaml
        ├── site2.yaml
        └── kustomization.yaml
    ```

    !!! note
        The files listed in the generator sections must contain either SiteConfig or PolicyGenTemplate CRs only. If your existing YAML files contain other CRs, for example, Namespace, these other CRs must be pulled out into separate files and listed in the resources section.
    The files listed in the `generator` sections must contain either `SiteConfig` or `PolicyGenTemplate` CRs only. If your existing YAML files contain other CRs, for example, `Namespace`, these other CRs must be pulled out into separate files and listed in the `resources` section.

    The `PolicyGenTemplate` kustomization file must contain all `PolicyGenTemplate` YAML files in the `generator` section and `Namespace` CRs in the `resources` section. For example:

    ``` yaml
    apiVersion: kustomize.config.k8s.io/v1beta1
    kind: Kustomization

    generators:
    - common-ranGen.yaml
    - group-du-sno-ranGen.yaml
    - site1.yaml
    - site2.yaml

    resources:
    - common-ns.yaml
    - group-du-sno-ranGen-ns.yaml
    - site1-ns.yaml
    - site2-ns.yaml
    ```

    The `SiteConfig` kustomization file must contain all `SiteConfig` YAML files in the `generator` section and any other CRs in the resources:

    ``` terminal
    apiVersion: kustomize.config.k8s.io/v1beta1
    kind: Kustomization

    generators:
    - site1.yaml
    - site2.yaml
    ```

-   Review and incorporate recommended changes

    Each release may include additional recommended changes to the configuration applied to deployed clusters. Typically these changes result in lower CPU use by the OpenShift platform, additional features, or improved tuning of the platform.

    Review the reference `SiteConfig` and `PolicyGenTemplate` CRs applicable to the types of cluster in your network. These examples can be found in the `argocd/example` directory extracted from the GitOps ZTP container.

### Installing the new GitOps ZTP applications

Using the extracted `argocd/deployment` directory, and after ensuring that the applications point to your Git repository, apply the full contents of the deployment directory. Applying the full contents of the directory ensures that all necessary resources for the applications are correctly configured.

1.  To patch the ArgoCD instance in the hub cluster by using the patch file previously extracted into the `out/argocd/deployment/` directory, enter the following command:

    ``` terminal
    $ oc patch argocd openshift-gitops \
    -n openshift-gitops --type=merge \
    --patch-file out/argocd/deployment/argocd-openshift-gitops-patch.json
    ```

2.  To apply the contents of the `argocd/deployment` directory, enter the following command:

    ``` terminal
    $ oc apply -k out/argocd/deployment
    ```

### Roll out the configuration changes

If any configuration changes were included in the upgrade due to implementing recommended changes, the upgrade process results in a set of policy CRs on the hub cluster in the `Non-Compliant` state. As of the {product-title} 4.10 version of the `ztp-site-generate` container, these policies are set to `inform` mode and are not pushed to the spoke clusters without an additional step by the user. This ensures that potentially disruptive changes to the clusters can be managed in terms of when the changes are made, for example, during a maintenance window, and how many clusters are updated concurrently.

To roll out the changes, create one or more `ClusterGroupUpgrade` CRs as detailed in the TALM documentation. The CR must contain the list of `Non-Compliant` policies that you want to push out to the spoke clusters as well as a list or selector of which clusters should be included in the update.

-   For information about creating `ClusterGroupUpgrade` CRs, see [About the auto-created ClusterGroupUpgrade CR for ZTP](../scalability_and_performance/ztp-deploying-disconnected.xml#talo-precache-autocreated-cgu-for-ztp_ztp-deploying-disconnected).

## Manually install a single managed cluster

This procedure tells you how to manually create and deploy a single managed cluster. If you are creating multiple clusters, perhaps hundreds, use the `SiteConfig` method described in “Creating ZTP custom resources for multiple managed clusters”.

-   Enable the Assisted Installer service.

-   Ensure network connectivity:

    -   The container within the hub must be able to reach the Baseboard Management Controller (BMC) address of the target bare-metal host.

    -   The managed cluster must be able to resolve and reach the hub’s API `hostname` and `*.app` hostname. Here is an example of the hub’s API and `*.app` hostname:

        ``` terminal
        console-openshift-console.apps.hub-cluster.internal.domain.com
        api.hub-cluster.internal.domain.com
        ```

    -   The hub must be able to resolve and reach the API and `*.app` hostname of the managed cluster. Here is an example of the managed cluster’s API and `*.app` hostname:

        ``` terminal
        console-openshift-console.apps.sno-managed-cluster-1.internal.domain.com
        api.sno-managed-cluster-1.internal.domain.com
        ```

    -   A DNS server that is IP reachable from the target bare-metal host.

-   A target bare-metal host for the managed cluster with the following hardware minimums:

    -   4 CPU or 8 vCPU

    -   32 GiB RAM

    -   120 GiB disk for root file system

-   When working in a disconnected environment, the release image must be mirrored. Use this command to mirror the release image:

    ``` terminal
    $ oc adm release mirror -a <pull_secret.json>
    --from=quay.io/openshift-release-dev/ocp-release:{{ mirror_version_spoke_release }}
    --to={{ provisioner_cluster_registry }}/ocp4 --to-release-image={{
    provisioner_cluster_registry }}/ocp4:{{ mirror_version_spoke_release }}
    ```

-   You mirrored the ISO and `rootfs` used to generate the spoke cluster ISO to an HTTP server and configured the settings to pull images from there.

    The images must match the version of the `ClusterImageSet`. For example, to deploy a {product-version}.0 version, the `rootfs` and ISO must be set to `{product-version}.0`.

1.  Create a `ClusterImageSet` for each specific cluster version that needs to be deployed. A `ClusterImageSet` has the following format:

    ``` yaml
    apiVersion: hive.openshift.io/v1
    kind: ClusterImageSet
    metadata:
      name: openshift-{product-version}.0 
    spec:
       releaseImage: quay.io/openshift-release-dev/ocp-release:{product-version}.0-x86_64 
    ```

    -   The descriptive version that you want to deploy.

    -   Specifies the `releaseImage` to deploy and determines the OS Image version. The discovery ISO is based on an OS image version as the `releaseImage`, or latest if the exact version is unavailable.

2.  Create the `Namespace` definition for the managed cluster:

    ``` yaml
    apiVersion: v1
    kind: Namespace
    metadata:
         name: <cluster_name> 
         labels:
            name: <cluster_name> 
    ```

    -   The name of the managed cluster to provision.

3.  Create the `BMC Secret` custom resource:

    ``` yaml
    apiVersion: v1
    data:
      password: <bmc_password> 
      username: <bmc_username> 
    kind: Secret
    metadata:
      name: <cluster_name>-bmc-secret
      namespace: <cluster_name>
    type: Opaque
    ```

    -   The password to the target bare-metal host. Must be base-64 encoded.

    -   The username to the target bare-metal host. Must be base-64 encoded.

4.  Create the `Image Pull Secret` custom resource:

    ``` yaml
    apiVersion: v1
    data:
      .dockerconfigjson: <pull_secret> 
    kind: Secret
    metadata:
      name: assisted-deployment-pull-secret
      namespace: <cluster_name>
    type: kubernetes.io/dockerconfigjson
    ```

    -   The {product-title} pull secret. Must be base-64 encoded.

5.  Create the `AgentClusterInstall` custom resource:

    ``` yaml
    apiVersion: extensions.hive.openshift.io/v1beta1
    kind: AgentClusterInstall
    metadata:
      # Only include the annotation if using OVN, otherwise omit the annotation
      annotations:
        agent-install.openshift.io/install-config-overrides: '{"networking":{"networkType":"OVNKubernetes"}}'
      name: <cluster_name>
      namespace: <cluster_name>
    spec:
      clusterDeploymentRef:
        name: <cluster_name>
      imageSetRef:
        name: <cluster_image_set> 
      networking:
        clusterNetwork:
        - cidr: <cluster_network_cidr> 
          hostPrefix: 23
        machineNetwork:
        - cidr: <machine_network_cidr> 
        serviceNetwork:
        - <service_network_cidr> 
      provisionRequirements:
        controlPlaneAgents: 1
        workerAgents: 0
      sshPublicKey: <public_key> 
    ```

    -   The name of the `ClusterImageSet` custom resource used to install {product-title} on the bare-metal host.

    -   A block of IPv4 or IPv6 addresses in CIDR notation used for communication among cluster nodes.

    -   A block of IPv4 or IPv6 addresses in CIDR notation used for the target bare-metal host external communication. Also used to determine the API and Ingress VIP addresses when provisioning DU single-node clusters.

    -   A block of IPv4 or IPv6 addresses in CIDR notation used for cluster services internal communication.

    -   A plain text string. You can use the public key to SSH into the node after it has finished installing.

    !!! note
        If you want to configure a static IP address for the managed cluster at this point, see the procedure in this document for configuring static IP addresses for managed clusters.
    If you want to configure a static IP address for the managed cluster at this point, see the procedure in this document for configuring static IP addresses for managed clusters.

6.  Create the `ClusterDeployment` custom resource:

    ``` yaml
    apiVersion: hive.openshift.io/v1
    kind: ClusterDeployment
    metadata:
      name: <cluster_name>
      namespace: <cluster_name>
    spec:
      baseDomain: <base_domain> 
      clusterInstallRef:
        group: extensions.hive.openshift.io
        kind: AgentClusterInstall
        name: <cluster_name>
        version: v1beta1
      clusterName: <cluster_name>
      platform:
        agentBareMetal:
          agentSelector:
            matchLabels:
              cluster-name: <cluster_name>
      pullSecretRef:
        name: assisted-deployment-pull-secret
    ```

    -   The managed cluster’s base domain.

7.  Create the `KlusterletAddonConfig` custom resource:

    ``` yaml
    apiVersion: agent.open-cluster-management.io/v1
    kind: KlusterletAddonConfig
    metadata:
      name: <cluster_name>
      namespace: <cluster_name>
    spec:
      clusterName: <cluster_name>
      clusterNamespace: <cluster_name>
      clusterLabels:
        cloud: auto-detect
        vendor: auto-detect
      applicationManager:
        enabled: true
      certPolicyController:
        enabled: false
      iamPolicyController:
        enabled: false
      policyController:
        enabled: true
      searchCollector:
        enabled: false 
    ```

    -   Keep `searchCollector` disabled. Set to `true` to enable the `KlusterletAddonConfig` CR or `false` to disable the `KlusterletAddonConfig` CR.

8.  Create the `ManagedCluster` custom resource:

    ``` yaml
    apiVersion: cluster.open-cluster-management.io/v1
    kind: ManagedCluster
    metadata:
      name: <cluster_name>
    spec:
      hubAcceptsClient: true
    ```

9.  Create the `InfraEnv` custom resource:

    ``` yaml
    apiVersion: agent-install.openshift.io/v1beta1
    kind: InfraEnv
    metadata:
      name: <cluster_name>
      namespace: <cluster_name>
    spec:
      clusterRef:
        name: <cluster_name>
        namespace: <cluster_name>
      sshAuthorizedKey: <public_key> 
      agentLabelSelector:
        matchLabels:
          cluster-name: <cluster_name>
      pullSecretRef:
        name: assisted-deployment-pull-secret
    ```

    -   Entered as plain text. You can use the public key to SSH into the target bare-metal host when it boots from the ISO.

10. Create the `BareMetalHost` custom resource:

    ``` yaml
    apiVersion: metal3.io/v1alpha1
    kind: BareMetalHost
    metadata:
      name: <cluster_name>
      namespace: <cluster_name>
      annotations:
        inspect.metal3.io: disabled
      labels:
        infraenvs.agent-install.openshift.io: "<cluster_name>"
    spec:
      bootMode: "UEFI"
      bmc:
        address: <bmc_address> 
        disableCertificateVerification: true
        credentialsName: <cluster_name>-bmc-secret
      bootMACAddress: <mac_address> 
      automatedCleaningMode: disabled
      online: true
    ```

    -   The baseboard management console (BMC) address on the target bare-metal host. ZTP supports iPXE and virtual media booting by using Redfish or IPMI protocols. For more information about BMC addressing, see the *Additional resources* section.

    -   The MAC address of the target bare-metal host.

    Optionally, you can add `bmac.agent-install.openshift.io/hostname: <host-name>` as an annotation to set the managed cluster’s hostname. If you don’t add the annotation, the hostname will default to either a hostname from the DHCP server or local host.

11. After you have created the custom resources, push the entire directory of generated custom resources to the Git repository you created for storing the custom resources.

**Next steps**

To provision additional clusters, repeat this procedure for each cluster.

-   [BMC addressing](../installing/installing_bare_metal_ipi/ipi-install-installation-workflow.xml#bmc-addressing_ipi-install-installation-workflow)

### Configuring BIOS for distributed unit bare-metal hosts

Distributed unit (DU) hosts require the BIOS to be configured before the host can be provisioned. The BIOS configuration is dependent on the specific hardware that runs your DUs and the particular requirements of your installation.

1.  Set the **UEFI/BIOS Boot Mode** to `UEFI`.

2.  In the host boot sequence order, set **Hard drive first**.

3.  Apply the specific BIOS configuration for your hardware. The following table describes a representative BIOS configuration for an Intel Xeon Skylake or Intel Cascade Lake server, based on the Intel FlexRAN 4G and 5G baseband PHY reference design.

    !!! important
        The exact BIOS configuration depends on your specific hardware and network requirements. The following sample configuration is for illustrative purposes only.
    The exact BIOS configuration depends on your specific hardware and network requirements. The following sample configuration is for illustrative purposes only.

    <table style="width:90%;"><caption>Sample BIOS configuration for an Intel Xeon Skylake or Cascade Lake server</caption><colgroup><col style="width: 45%" /><col style="width: 45%" /></colgroup><thead><tr class="header"><th style="text-align: left;">BIOS Setting</th><th style="text-align: left;">Configuration</th></tr></thead><tbody><tr class="odd"><td style="text-align: left;"><p>CPU Power and Performance Policy</p></td><td style="text-align: left;"><p>Performance</p></td></tr><tr class="even"><td style="text-align: left;"><p>Uncore Frequency Scaling</p></td><td style="text-align: left;"><p>Disabled</p></td></tr><tr class="odd"><td style="text-align: left;"><p>Performance P-limit</p></td><td style="text-align: left;"><p>Disabled</p></td></tr><tr class="even"><td style="text-align: left;"><p>Enhanced Intel SpeedStep ® Tech</p></td><td style="text-align: left;"><p>Enabled</p></td></tr><tr class="odd"><td style="text-align: left;"><p>Intel Configurable TDP</p></td><td style="text-align: left;"><p>Enabled</p></td></tr><tr class="even"><td style="text-align: left;"><p>Configurable TDP Level</p></td><td style="text-align: left;"><p>Level 2</p></td></tr><tr class="odd"><td style="text-align: left;"><p>Intel® Turbo Boost Technology</p></td><td style="text-align: left;"><p>Enabled</p></td></tr><tr class="even"><td style="text-align: left;"><p>Energy Efficient Turbo</p></td><td style="text-align: left;"><p>Disabled</p></td></tr><tr class="odd"><td style="text-align: left;"><p>Hardware P-States</p></td><td style="text-align: left;"><p>Disabled</p></td></tr><tr class="even"><td style="text-align: left;"><p>Package C-State</p></td><td style="text-align: left;"><p>C0/C1 state</p></td></tr><tr class="odd"><td style="text-align: left;"><p>C1E</p></td><td style="text-align: left;"><p>Disabled</p></td></tr><tr class="even"><td style="text-align: left;"><p>Processor C6</p></td><td style="text-align: left;"><p>Disabled</p></td></tr></tbody></table>

    Sample BIOS configuration for an Intel Xeon Skylake or Cascade Lake server

!!! note
    Enable global SR-IOV and VT-d settings in the BIOS for the host. These settings are relevant to bare-metal environments.

Enable global SR-IOV and VT-d settings in the BIOS for the host. These settings are relevant to bare-metal environments.

### Configuring static IP addresses for managed clusters

Optionally, after creating the `AgentClusterInstall` custom resource, you can configure static IP addresses for the managed clusters.

!!! note
    You must create this custom resource before creating the ClusterDeployment custom resource.

You must create this custom resource before creating the `ClusterDeployment` custom resource.

-   Deploy and configure the `AgentClusterInstall` custom resource.

1.  Create a `NMStateConfig` custom resource:

    ``` yaml
    apiVersion: agent-install.openshift.io/v1beta1
    kind: NMStateConfig
    metadata:
     name: <cluster_name>
     namespace: <cluster_name>
     labels:
       sno-cluster-<cluster-name>: <cluster_name>
    spec:
     config:
       interfaces:
         - name: eth0
           type: ethernet
           state: up
           ipv4:
             enabled: true
             address:
               - ip: <ip_address> 
                 prefix-length: <public_network_prefix> 
             dhcp: false
       dns-resolver:
         config:
           server:
             - <dns_resolver> 
       routes:
         config:
           - destination: 0.0.0.0/0
             next-hop-address: <gateway> 
             next-hop-interface: eth0
             table-id: 254
     interfaces:
       - name: "eth0" 
         macAddress: <mac_address> 
    ```

    -   The static IP address of the target bare-metal host.

    -   The static IP address’s subnet prefix for the target bare-metal host.

    -   The DNS server for the target bare-metal host.

    -   The gateway for the target bare-metal host.

    -   Must match the name specified in the `interfaces` section.

    -   The mac address of the interface.

2.  When creating the `BareMetalHost` custom resource, ensure that one of its mac addresses matches a mac address in the `NMStateConfig` target bare-metal host.

3.  When creating the `InfraEnv` custom resource, reference the label from the `NMStateConfig` custom resource in the `InfraEnv` custom resource:

    ``` yaml
    apiVersion: agent-install.openshift.io/v1beta1
    kind: InfraEnv
    metadata:
      name: <cluster_name>
      namespace: <cluster_name>
    spec:
      clusterRef:
        name: <cluster_name>
        namespace: <cluster_name>
      sshAuthorizedKey: <public_key>
      agentLabelSelector:
        matchLabels:
          cluster-name: <cluster_name>
      pullSecretRef:
        name: assisted-deployment-pull-secret
      nmStateConfigLabelSelector:
        matchLabels:
          sno-cluster-<cluster-name>: <cluster_name> # Match this label
    ```

### Automated Discovery image ISO process for provisioning clusters

After you create the custom resources, the following actions happen automatically:

1.  A Discovery image ISO file is generated and booted on the target machine.

2.  When the ISO file successfully boots on the target machine it reports the hardware information of the target machine.

3.  After all hosts are discovered, {product-title} is installed.

4.  When {product-title} finishes installing, the hub installs the `klusterlet` service on the target cluster.

5.  The requested add-on services are installed on the target cluster.

The Discovery image ISO process finishes when the `Agent` custom resource is created on the hub for the managed cluster.

### Checking the managed cluster status

Ensure that cluster provisioning was successful by checking the cluster status.

-   All of the custom resources have been configured and provisioned, and the `Agent` custom resource is created on the hub for the managed cluster.

1.  Check the status of the managed cluster:

    ``` terminal
    $ oc get managedcluster
    ```

    `True` indicates the managed cluster is ready.

2.  Check the agent status:

    ``` terminal
    $ oc get agent -n <cluster_name>
    ```

3.  Use the `describe` command to provide an in-depth description of the agent’s condition. Statuses to be aware of include `BackendError`, `InputError`, `ValidationsFailing`, `InstallationFailed`, and `AgentIsConnected`. These statuses are relevant to the `Agent` and `AgentClusterInstall` custom resources.

    ``` terminal
    $ oc describe agent -n <cluster_name>
    ```

4.  Check the cluster provisioning status:

    ``` terminal
    $ oc get agentclusterinstall -n <cluster_name>
    ```

5.  Use the `describe` command to provide an in-depth description of the cluster provisioning status:

    ``` terminal
    $ oc describe agentclusterinstall -n <cluster_name>
    ```

6.  Check the status of the managed cluster’s add-on services:

    ``` terminal
    $ oc get managedclusteraddon -n <cluster_name>
    ```

7.  Retrieve the authentication information of the `kubeconfig` file for the managed cluster:

    ``` terminal
    $ oc get secret -n <cluster_name> <cluster_name>-admin-kubeconfig -o jsonpath={.data.kubeconfig} | base64 -d > <directory>/<cluster_name>-kubeconfig
    ```

### Configuring a managed cluster for a disconnected environment

After you have completed the preceding procedure, follow these steps to configure the managed cluster for a disconnected environment.

-   A disconnected installation of Red Hat Advanced Cluster Management (RHACM) 2.3.

-   Host the `rootfs` and `iso` images on an HTTPD server.

!!! warning
    If you enable TLS for the HTTPD server, you must confirm the root certificate is signed by an authority trusted by the client and verify the trusted certificate chain between your {product-title} hub and spoke clusters and the HTTPD server. Using a server configured with an untrusted certificate prevents the images from being downloaded to the image creation service. Using untrusted HTTPS servers is not supported.

If you enable TLS for the HTTPD server, you must confirm the root certificate is signed by an authority trusted by the client and verify the trusted certificate chain between your {product-title} hub and spoke clusters and the HTTPD server. Using a server configured with an untrusted certificate prevents the images from being downloaded to the image creation service. Using untrusted HTTPS servers is not supported.

1.  Create a `ConfigMap` containing the mirror registry config:

    ``` yaml
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: assisted-installer-mirror-config
      namespace: assisted-installer
      labels:
        app: assisted-service
    data:
      ca-bundle.crt: <certificate> 
      registries.conf: |  
        unqualified-search-registries = ["registry.access.redhat.com", "docker.io"]

        [[registry]]
          location = <mirror_registry_url>  
          insecure = false
          mirror-by-digest-only = true
    ```

    -   The mirror registry’s certificate used when creating the mirror registry.

    -   The configuration for the mirror registry.

    -   The URL of the mirror registry.

    This updates `mirrorRegistryRef` in the `AgentServiceConfig` custom resource, as shown below:

    **Example output**

    ``` yaml
    apiVersion: agent-install.openshift.io/v1beta1
    kind: AgentServiceConfig
    metadata:
      name: agent
      namespace: assisted-installer
    spec:
      databaseStorage:
        volumeName: <db_pv_name>
        accessModes:
        - ReadWriteOnce
        resources:
          requests:
            storage: <db_storage_size>
      filesystemStorage:
        volumeName: <fs_pv_name>
        accessModes:
        - ReadWriteOnce
        resources:
          requests:
            storage: <fs_storage_size>
      mirrorRegistryRef:
        name: 'assisted-installer-mirror-config'
      osImages:
        - openshiftVersion: <ocp_version>
          rootfs: <rootfs_url> 
          url: <iso_url> 
    ```

    -   Must match the URLs of the HTTPD server.

!!! important
    A valid NTP server is required during cluster installation. Ensure that a suitable NTP server is available and can be reached from the installed clusters through the disconnected network.

A valid NTP server is required during cluster installation. Ensure that a suitable NTP server is available and can be reached from the installed clusters through the disconnected network.

### Configuring IPv6 addresses for a disconnected environment

Optionally, when you are creating the `AgentClusterInstall` custom resource, you can configure IPv6 addresses for the managed clusters.

1.  In the `AgentClusterInstall` custom resource, modify the IP addresses in `clusterNetwork` and `serviceNetwork` for IPv6 addresses:

    ``` yaml
    apiVersion: extensions.hive.openshift.io/v1beta1
    kind: AgentClusterInstall
    metadata:
      # Only include the annotation if using OVN, otherwise omit the annotation
      annotations:
        agent-install.openshift.io/install-config-overrides: '{"networking":{"networkType":"OVNKubernetes"}}'
      name: <cluster_name>
      namespace: <cluster_name>
    spec:
      clusterDeploymentRef:
        name: <cluster_name>
      imageSetRef:
        name: <cluster_image_set>
      networking:
        clusterNetwork:
        - cidr: "fd01::/48"
          hostPrefix: 64
        machineNetwork:
        - cidr: <machine_network_cidr>
        serviceNetwork:
        - "fd02::/112"
      provisionRequirements:
        controlPlaneAgents: 1
        workerAgents: 0
      sshPublicKey: <public_key>
    ```

2.  Update the `NMStateConfig` custom resource with the IPv6 addresses you defined.

## Generating RAN policies

-   Install Kustomize

-   Install the [Kustomize Policy Generator plug-in](https://github.com/stolostron/policy-generator-plugin)

1.  Configure the `kustomization.yaml` file to reference the `policyGenerator.yaml` file. The following example shows the PolicyGenerator definition:

    ``` yaml
    apiVersion: policyGenerator/v1
    kind: PolicyGenerator
    metadata:
      name: acm-policy
      namespace: acm-policy-generator
    # The arguments should be given and defined as below with same order --policyGenTempPath= --sourcePath= --outPath= --stdout --customResources
    argsOneLiner: ./ranPolicyGenTempExamples ./sourcePolicies ./out true false
    ```

    Where:

    -   `policyGenTempPath` is the path to the `policyGenTemp` files.

    -   `sourcePath`: is the path to the source policies.

    -   `outPath`: is the path to save the generated ACM policies.

    -   `stdout`: If `true`, prints the generated policies to the console.

    -   `customResources`: If `true` generates the CRs from the `sourcePolicies` files without ACM policies.

2.  Test PolicyGen by running the following commands:

    ``` terminal
    $ cd cnf-features-deploy/ztp/ztp-policy-generator/
    ```

    ``` terminal
    $ XDG_CONFIG_HOME=./ kustomize build --enable-alpha-plugins
    ```

    An `out` directory is created with the expected policies, as shown in this example:

    ``` terminal
    out
    ├── common
    │   ├── common-log-sub-ns-policy.yaml
    │   ├── common-log-sub-oper-policy.yaml
    │   ├── common-log-sub-policy.yaml
    │   ├── common-nto-sub-catalog-policy.yaml
    │   ├── common-nto-sub-ns-policy.yaml
    │   ├── common-nto-sub-oper-policy.yaml
    │   ├── common-nto-sub-policy.yaml
    │   ├── common-policies-placementbinding.yaml
    │   ├── common-policies-placementrule.yaml
    │   ├── common-ptp-sub-ns-policy.yaml
    │   ├── common-ptp-sub-oper-policy.yaml
    │   ├── common-ptp-sub-policy.yaml
    │   ├── common-sriov-sub-ns-policy.yaml
    │   ├── common-sriov-sub-oper-policy.yaml
    │   └── common-sriov-sub-policy.yaml
    ├── groups
    │   ├── group-du
    │   │   ├── group-du-mc-mount-ns-policy.yaml
    │   │   ├── group-du-mcp-du-policy.yaml
    │   │   ├── group-du-mc-sctp-policy.yaml
    │   │   ├── group-du-policies-placementbinding.yaml
    │   │   ├── group-du-policies-placementrule.yaml
    │   │   ├── group-du-ptp-config-policy.yaml
    │   │   └── group-du-sriov-operconfig-policy.yaml
    │   └── group-sno-du
    │       ├── group-du-sno-policies-placementbinding.yaml
    │       ├── group-du-sno-policies-placementrule.yaml
    │       ├── group-sno-du-console-policy.yaml
    │       ├── group-sno-du-log-forwarder-policy.yaml
    │       └── group-sno-du-log-policy.yaml
    └── sites
        └── site-du-sno-1
            ├── site-du-sno-1-policies-placementbinding.yaml
            ├── site-du-sno-1-policies-placementrule.yaml
            ├── site-du-sno-1-sriov-nn-fh-policy.yaml
            ├── site-du-sno-1-sriov-nnp-mh-policy.yaml
            ├── site-du-sno-1-sriov-nw-fh-policy.yaml
            ├── site-du-sno-1-sriov-nw-mh-policy.yaml
            └── site-du-sno-1-.yaml
    ```

    The common policies are flat because they will be applied to all clusters. However, the groups and sites have subdirectories for each group and site as they will be applied to different clusters.

### Troubleshooting the managed cluster

Use this procedure to diagnose any installation issues that might occur with the managed clusters.

1.  Check the status of the managed cluster:

    ``` terminal
    $ oc get managedcluster
    ```

    **Example output**

    ``` terminal
    NAME            HUB ACCEPTED   MANAGED CLUSTER URLS   JOINED   AVAILABLE   AGE
    SNO-cluster     true                                   True     True      2d19h
    ```

    If the status in the `AVAILABLE` column is `True`, the managed cluster is being managed by the hub.

    If the status in the `AVAILABLE` column is `Unknown`, the managed cluster is not being managed by the hub. Use the following steps to continue checking to get more information.

2.  Check the `AgentClusterInstall` install status:

    ``` terminal
    $ oc get clusterdeployment -n <cluster_name>
    ```

    **Example output**

    ``` terminal
    NAME        PLATFORM            REGION   CLUSTERTYPE   INSTALLED    INFRAID    VERSION  POWERSTATE AGE
    Sno0026    agent-baremetal                               false                          Initialized
    2d14h
    ```

    If the status in the `INSTALLED` column is `false`, the installation was unsuccessful.

3.  If the installation failed, enter the following command to review the status of the `AgentClusterInstall` resource:

    ``` terminal
    $ oc describe agentclusterinstall -n <cluster_name> <cluster_name>
    ```

4.  Resolve the errors and reset the cluster:

    1.  Remove the cluster’s managed cluster resource:

        ``` terminal
        $ oc delete managedcluster <cluster_name>
        ```

    2.  Remove the cluster’s namespace:

        ``` terminal
        $ oc delete namespace <cluster_name>
        ```

        This deletes all of the namespace-scoped custom resources created for this cluster. You must wait for the `ManagedCluster` CR deletion to complete before proceeding.

    3.  Recreate the custom resources for the managed cluster.

## Updating managed policies with the Topology Aware Lifecycle Manager

You can use the Topology Aware Lifecycle Manager (TALM) to manage the software lifecycle of multiple OpenShift clusters. TALM uses Red Hat Advanced Cluster Management (RHACM) policies to perform changes on the target clusters.

!!! important
    The Topology Aware Lifecycle Manager is a Technology Preview feature only. Technology Preview features are not supported with Red Hat production service level agreements (SLAs) and might not be functionally complete. Red Hat does not recommend using them in production. These features provide early access to upcoming product features, enabling customers to test functionality and provide feedback during the development process.For more information about the support scope of Red Hat Technology Preview features, see https://access.redhat.com/support/offerings/techpreview/.

The Topology Aware Lifecycle Manager is a Technology Preview feature only. Technology Preview features are not supported with Red Hat production service level agreements (SLAs) and might not be functionally complete. Red Hat does not recommend using them in production. These features provide early access to upcoming product features, enabling customers to test functionality and provide feedback during the development process.

For more information about the support scope of Red Hat Technology Preview features, see <https://access.redhat.com/support/offerings/techpreview/>.

-   For more information about the Topology Aware Lifecycle Manager, see [About the Topology Aware Lifecycle Manager](../scalability_and_performance/cnf-talm-for-cluster-upgrades.xml#cnf-about-topology-aware-lifecycle-manager-config_cnf-topology-aware-lifecycle-manager).

### About the auto-created ClusterGroupUpgrade CR for ZTP

TALM has a controller called `ManagedClusterForCGU` that monitors the `Ready` state of the `ManagedCluster` CRs on the hub cluster and creates the `ClusterGroupUpgrade` CRs for ZTP (zero touch provisioning).

For any managed cluster in the `Ready` state without a "ztp-done" label applied, the `ManagedClusterForCGU` controller automatically creates a `ClusterGroupUpgrade` CR in the `ztp-install` namespace with its associated RHACM policies that are created during the ZTP process. TALM then remediates the set of configuration policies that are listed in the auto-created `ClusterGroupUpgrade` CR to push the configuration CRs to the managed cluster.

!!! note
    If the managed cluster has no bound policies when the cluster becomes Ready, no ClusterGroupUpgrade CR is created.

If the managed cluster has no bound policies when the cluster becomes `Ready`, no `ClusterGroupUpgrade` CR is created.

**Example of an auto-created `ClusterGroupUpgrade` CR for ZTP**

``` yaml
apiVersion: ran.openshift.io/v1alpha1
kind: ClusterGroupUpgrade
metadata:
  generation: 1
  name: spoke1
  namespace: ztp-install
  ownerReferences:
  - apiVersion: cluster.open-cluster-management.io/v1
    blockOwnerDeletion: true
    controller: true
    kind: ManagedCluster
    name: spoke1
    uid: 98fdb9b2-51ee-4ee7-8f57-a84f7f35b9d5
  resourceVersion: "46666836"
  uid: b8be9cd2-764f-4a62-87d6-6b767852c7da
spec:
  actions:
    afterCompletion:
      addClusterLabels:
        ztp-done: "" 
      deleteClusterLabels:
        ztp-running: ""
      deleteObjects: true
    beforeEnable:
      addClusterLabels:
        ztp-running: "" 
  clusters:
  - spoke1
  enable: true
  managedPolicies:
  - common-spoke1-config-policy
  - common-spoke1-subscriptions-policy
  - group-spoke1-config-policy
  - spoke1-config-policy
  - group-spoke1-validator-du-policy
  preCaching: false
  remediationStrategy:
    maxConcurrency: 1
    timeout: 240
```

-   Applied to the managed cluster when TALM completes the cluster configuration.

-   Applied to the managed cluster when TALM starts deploying the configuration policies.

## End-to-end procedures for updating clusters in a disconnected environment

If you have deployed spoke clusters with distributed unit (DU) profiles using the GitOps ZTP with the Topology Aware Lifecycle Manager (TALM) pipeline described in "Deploying distributed units at scale in a disconnected environment", this procedure describes how to upgrade your spoke clusters and Operators.

### Preparing for the updates

This procedure makes use of the Topology Aware Lifecycle Manager (TALM) which requires the 4.10 version or later of the ZTP container for compatibility.

### Setting up the environment

TALM can perform both platform and Operator updates.

You must mirror both the platform image and Operator images that you want to update to in your mirror registry before you can use TALM to update your disconnected clusters. Complete the following steps to mirror the images:

-   For platform updates, you must perform the following steps:

    1.  Mirror the desired {product-title} image repository. Ensure that the desired platform image is mirrored by following the "Mirroring the {product-title} image repository" procedure linked in the Additional Resources. Save the contents of the `imageContentSources` section in the `imageContentSources.yaml` file:

        **Example output**

        ``` yaml
        imageContentSources:
         - mirrors:
           - mirror-ocp-registry.ibmcloud.io.cpak:5000/openshift-release-dev/openshift4
           source: quay.io/openshift-release-dev/ocp-release
         - mirrors:
           - mirror-ocp-registry.ibmcloud.io.cpak:5000/openshift-release-dev/openshift4
           source: quay.io/openshift-release-dev/ocp-v4.0-art-dev
        ```

    2.  Save the image signature of the desired platform image that was mirrored. You must add the image signature to the `PolicyGenTemplate` CR for platform updates. To get the image signature, perform the following steps:

        1.  Specify the desired {product-title} tag by running the following command:

            ``` terminal
            $ OCP_RELEASE_NUMBER=<release_version>
            ```

        2.  Specify the architecture of the server by running the following command:

            ``` terminal
            $ ARCHITECTURE=<server_architecture>
            ```

        3.  Get the release image digest from Quay by running the following command

            ``` terminal
            $ DIGEST="$(oc adm release info quay.io/openshift-release-dev/ocp-release:${OCP_RELEASE_NUMBER}-${ARCHITECTURE} | sed -n 's/Pull From: .*@//p')"
            ```

        4.  Set the digest algorithm by running the following command:

            ``` terminal
            $ DIGEST_ALGO="${DIGEST%%:*}"
            ```

        5.  Set the digest signature by running the following command:

            ``` terminal
            $ DIGEST_ENCODED="${DIGEST#*:}"
            ```

        6.  Get the image signature from the [mirror.openshift.com](https://mirror.openshift.com/pub/openshift-v4/signatures/openshift/release/) website by running the following command:

            ``` terminal
            $ SIGNATURE_BASE64=$(curl -s "https://mirror.openshift.com/pub/openshift-v4/signatures/openshift/release/${DIGEST_ALGO}=${DIGEST_ENCODED}/signature-1" | base64 -w0 && echo)
            ```

        7.  Save the image signature to the `checksum-<OCP_RELEASE_NUMBER>.yaml` file by running the following commands:

            ``` terminal
            $ cat >checksum-${OCP_RELEASE_NUMBER}.yaml <<EOF
            ${DIGEST_ALGO}-${DIGEST_ENCODED}: ${SIGNATURE_BASE64}
            EOF
            ```

    3.  Prepare the update graph. You have two options to prepare the update graph:

        1.  Use the OpenShift Update Service.

            For more information about how to set up the graph on the hub cluster, see [Deploy the operator for OpenShift Update Service](https://access.redhat.com/documentation/en-us/red_hat_advanced_cluster_management_for_kubernetes/2.4/html/clusters/managing-your-clusters#deploy-the-operator-for-cincinnati) and [Build the graph data init container](https://access.redhat.com/documentation/en-us/red_hat_advanced_cluster_management_for_kubernetes/2.4/html/clusters/managing-your-clusters#build-the-graph-data-init-container).

        2.  Make a local copy of the upstream graph. Host the update graph on an `http` or `https` server in the disconnected environment that has access to the spoke cluster. To download the update graph, use the following command:

            ``` terminal
            $ curl -s https://api.openshift.com/api/upgrades_info/v1/graph?channel=stable-{product-version} -o ~/upgrade-graph_stable-{product-version}
            ```

-   For Operator updates, you must perform the following task:

    -   Mirror the Operator catalogs. Ensure that the desired operator images are mirrored by following the procedure in the "Mirroring Operator catalogs for use with disconnected clusters" section.

<!-- -->

-   For more information about how to update ZTP, see [Upgrading GitOps ZTP](../scalability_and_performance/ztp-deploying-disconnected.xml#ztp-upgrading-gitops-ztp_ztp-deploying-disconnected).

-   For more information about how to mirror an {product-title} image repository, see [Mirroring the {product-title} image repository](../installing/disconnected_install/installing-mirroring-installation-images.xml#installation-mirror-repository_installing-mirroring-installation-images).

-   For more information about how to mirror Operator catalogs for disconnected clusters, see [Mirroring Operator catalogs for use with disconnected clusters](../installing/disconnected_install/installing-mirroring-installation-images.xml#olm-mirror-catalog_installing-mirroring-installation-images).

-   For more information about how to prepare the disconnected environment and mirroring the desired image repository, see [Preparing the disconnected environment](../scalability_and_performance/ztp-deploying-disconnected.xml#ztp-acm-preparing-to-install-disconnected-acm_ztp-deploying-disconnected).

-   For more information about update channels and releases, see [Understanding upgrade channels and releases](../updating/understanding-upgrade-channels-release.xml).

### Performing a platform update

You can perform a platform update with the TALM.

-   Install the Topology Aware Lifecycle Manager (TALM).

-   Update ZTP to the latest version.

-   Provision one or more managed clusters with ZTP.

-   Mirror the desired image repository.

-   Log in as a user with `cluster-admin` privileges.

-   Create RHACM policies in the hub cluster.

1.  Create a `PolicyGenTemplate` CR for the platform update:

    1.  Save the following contents of the `PolicyGenTemplate` CR in the `du-upgrade.yaml` file.

        **Example of `PolicyGenTemplate` for platform update**

        ``` yaml
        apiVersion: ran.openshift.io/v1
        kind: PolicyGenTemplate
        metadata:
          name: "du-upgrade"
          namespace: "ztp-group-du-sno"
        spec:
          bindingRules:
            group-du-sno: ""
          mcp: "master"
          remediationAction: inform
          sourceFiles:
            - fileName: ImageSignature.yaml 
              policyName: "platform-upgrade-prep"
              binaryData:
                ${DIGEST_ALGO}-${DIGEST_ENCODED}: ${SIGNATURE_BASE64} 
            - fileName: DisconnectedICSP.yaml
              policyName: "platform-upgrade-prep"
              metadata:
                name: disconnected-internal-icsp-for-ocp
              spec:
                repositoryDigestMirrors: 
                  - mirrors:
                    - quay-intern.example.com/ocp4/openshift-release-dev
                    source: quay.io/openshift-release-dev/ocp-release
                  - mirrors:
                    - quay-intern.example.com/ocp4/openshift-release-dev
                    source: quay.io/openshift-release-dev/ocp-v4.0-art-dev
            - fileName: ClusterVersion.yaml 
              policyName: "platform-upgrade-prep"
              metadata:
                name: version
                annotations:
                  ran.openshift.io/ztp-deploy-wave: "1"
              spec:
                channel: "stable-{product-version}"
                upstream: http://upgrade.example.com/images/upgrade-graph_stable-{product-version}
            - fileName: ClusterVersion.yaml 
              policyName: "platform-upgrade"
              metadata:
                name: version
              spec:
                channel: "stable-{product-version}"
                upstream: http://upgrade.example.com/images/upgrade-graph_stable-{product-version}
                desiredUpdate:
                  version: {product-version}.4
              status:
                history:
                  - version: {product-version}.4
                    state: "Completed"
        ```

        -   The `ConfigMap` CR contains the signature of the desired release image to update to.

        -   Shows the image signature of the desired {product-title} release. Get the signature from the `checksum-${OCP_RELASE_NUMBER}.yaml` file you saved when following the procedures in the "Setting up the environment" section.

        -   Shows the mirror repository that contains the desired {product-title} image. Get the mirrors from the `imageContentSources.yaml` file that you saved when following the procedures in the "Setting up the environment" section.

        -   Shows the `ClusterVersion` CR to update upstream.

        -   Shows the `ClusterVersion` CR to trigger the update. The `channel`, `upstream`, and `desiredVersion` fields are all required for image pre-caching.

        The `PolicyGenTemplate` CR generates two policies:

        -   The `du-upgrade-platform-upgrade-prep` policy does the preparation work for the platform update. It creates the `ConfigMap` CR for the desired release image signature, creates the image content source of the mirrored release image repository, and updates the cluster version with the desired update channel and the update graph reachable by the spoke cluster in the disconnected environment.

        -   The `du-upgrade-platform-upgrade` policy is used to perform platform upgrade.

    2.  Add the `du-upgrade.yaml` file contents to the `kustomization.yaml` file located in the ZTP Git repository for the `PolicyGenTemplate` CRs and push the changes to the Git repository.

        ArgoCD pulls the changes from the Git repository and generates the policies on the hub cluster.

    3.  Check the created policies by running the following command:

        ``` terminal
        $ oc get policies -A | grep platform-upgrade
        ```

2.  Apply the required update resources before starting the platform update with the TALM.

    1.  Save the content of the `platform-upgrade-prep` `ClusterUpgradeGroup` CR with the `du-upgrade-platform-upgrade-prep` policy and the target spoke clusters to the `cgu-platform-upgrade-prep.yml` file, as shown in the following example:

        ``` yaml
        apiVersion: ran.openshift.io/v1alpha1
        kind: ClusterGroupUpgrade
        metadata:
          name: cgu-platform-upgrade-prep
          namespace: default
        spec:
          managedPolicies:
          - du-upgrade-platform-upgrade-prep
          clusters:
          - spoke1
          remediationStrategy:
            maxConcurrency: 1
          enable: true
        ```

    2.  Apply the policy to the hub cluster by running the following command:

        ``` terminal
        $ oc apply -f cgu-platform-upgrade-prep.yml
        ```

    3.  Monitor the update process. Upon completion, ensure that the policy is compliant by running the following command:

        ``` terminal
        $ oc get policies --all-namespaces
        ```

3.  Create the `ClusterGroupUpdate` CR for the platform update with the `spec.enable` field set to `false`.

    1.  Save the content of the platform update `ClusterGroupUpdate` CR with the `du-upgrade-platform-upgrade` policy and the target clusters to the `cgu-platform-upgrade.yml` file, as shown in the following example:

        ``` yaml
        apiVersion: ran.openshift.io/v1alpha1
        kind: ClusterGroupUpgrade
        metadata:
          name: cgu-platform-upgrade
          namespace: default
        spec:
          managedPolicies:
          - du-upgrade-platform-upgrade
          preCaching: false
          clusters:
          - spoke1
          remediationStrategy:
            maxConcurrency: 1
          enable: false
        ```

    2.  Apply the `ClusterGroupUpdate` CR to the hub cluster by running the following command:

        ``` terminal
        $ oc apply -f cgu-platform-upgrade.yml
        ```

4.  Optional: Pre-cache the images for the platform update.

    1.  Enable pre-caching in the `ClusterGroupUpdate` CR by running the following command:

        ``` terminal
        $ oc --namespace=default patch clustergroupupgrade.ran.openshift.io/cgu-platform-upgrade \
        --patch '{"spec":{"preCaching": true}}' --type=merge
        ```

    2.  Monitor the update process and wait for the pre-caching to complete. Check the status of pre-caching by running the following command on the hub cluster:

        ``` terminal
        $ oc get cgu cgu-platform-upgrade -o jsonpath='{.status.precaching.status}'
        ```

5.  Start the platform update:

    1.  Enable the `cgu-platform-upgrade` policy and disable pre-caching by running the following command:

        ``` terminal
        $ oc --namespace=default patch clustergroupupgrade.ran.openshift.io/cgu-platform-upgrade \
        --patch '{"spec":{"enable":true, "preCaching": false}}' --type=merge
        ```

    2.  Monitor the process. Upon completion, ensure that the policy is compliant by running the following command:

        ``` terminal
        $ oc get policies --all-namespaces
        ```

-   For more information about mirroring the images in a disconnected environment, [Preparing the disconnected environment](../scalability_and_performance/ztp-deploying-disconnected.xml#ztp-acm-preparing-to-install-disconnected-acm_ztp-deploying-disconnected)

### Performing an Operator update

You can perform an Operator update with the TALM.

-   Install the Topology Aware Lifecycle Manager (TALM).

-   Update ZTP to the latest version.

-   Provision one or more managed clusters with ZTP.

-   Mirror the desired index image, bundle images, and all Operator images referenced in the bundle images.

-   Log in as a user with `cluster-admin` privileges.

-   Create RHACM policies in the hub cluster.

1.  Update the `PolicyGenTemplate` CR for the Operator update.

    1.  Update the `du-upgrade` `PolicyGenTemplate` CR with the following additional contents in the `du-upgrade.yaml` file:

        ``` yaml
        apiVersion: ran.openshift.io/v1
        kind: PolicyGenTemplate
        metadata:
          name: "du-upgrade"
          namespace: "ztp-group-du-sno"
        spec:
          bindingRules:
            group-du-sno: ""
          mcp: "master"
          remediationAction: inform
          sourceFiles:
            - fileName: DefaultCatsrc.yaml
              remediationAction: inform
              policyName: "operator-catsrc-policy"
              metadata:
                name: redhat-operators
              spec:
                displayName: Red Hat Operators Catalog
                image: registry.example.com:5000/olm/redhat-operators:v{product-version} 
                updateStrategy: 
                  registryPoll:
                    interval: 1h
        ```

        -   The index image URL contains the desired Operator images. If the index images are always pushed to the same image name and tag, this change is not needed.

        -   Set how frequently the Operator Lifecycle Manager (OLM) polls the index image for new Operator versions with the `registryPoll.interval` field. This change is not needed if a new index image tag is always pushed for y-stream and z-stream Operator updates. The `registryPoll.interval` field can be set to a shorter interval to expedite the update, however shorter intervals increase computational load. To counteract this, you can restore `registryPoll.interval` to the default value once the update is complete.

    2.  This update generates one policy, `du-upgrade-operator-catsrc-policy`, to update the `redhat-operators` catalog source with the new index images that contain the desired Operators images.

        !!! note
            If you want to use the image pre-caching for Operators and there are Operators from a different catalog source other than redhat-operators, you must perform the following tasks:Prepare a separate catalog source policy with the new index image or registry poll interval update for the different catalog source.Prepare a separate subscription policy for the desired Operators that are from the different catalog source.
        If you want to use the image pre-caching for Operators and there are Operators from a different catalog source other than `redhat-operators`, you must perform the following tasks:

        -   Prepare a separate catalog source policy with the new index image or registry poll interval update for the different catalog source.

        -   Prepare a separate subscription policy for the desired Operators that are from the different catalog source.

        For example, the desired SRIOV-FEC Operator is available in the `certified-operators` catalog source. To update the catalog source and the Operator subscription, add the following contents to generate two policies, `du-upgrade-fec-catsrc-policy` and `du-upgrade-subscriptions-fec-policy`:

        ``` yaml
        apiVersion: ran.openshift.io/v1
        kind: PolicyGenTemplate
        metadata:
          name: "du-upgrade"
          namespace: "ztp-group-du-sno"
        spec:
          bindingRules:
            group-du-sno: ""
          mcp: "master"
          remediationAction: inform
          sourceFiles:
               …
            - fileName: DefaultCatsrc.yaml
              remediationAction: inform
              policyName: "fec-catsrc-policy"
              metadata:
                name: certified-operators
              spec:
                displayName: Intel SRIOV-FEC Operator
                image: registry.example.com:5000/olm/far-edge-sriov-fec:v4.10
                updateStrategy:
                  registryPoll:
                    interval: 10m
            - fileName: AcceleratorsSubscription.yaml
              policyName: "subscriptions-fec-policy"
              spec:
                channel: "stable"
                source: certified-operators
        ```

    3.  Remove the specified subscriptions channels in the common `PolicyGenTemplate` CR, if they exist. The default subscriptions channels from the ZTP image are used for the update.

        !!! note
            The default channel for the Operators applied through ZTP {product-version} is stable, except for the performance-addon-operator. As of {product-title} 4.11, the performance-addon-operator functionality was moved to the node-tuning-operator. For the 4.10 release, the default channel for PAO is v4.10. You can also specify the default channels in the common PolicyGenTemplate CR.
        The default channel for the Operators applied through ZTP {product-version} is `stable`, except for the `performance-addon-operator`. As of {product-title} 4.11, the `performance-addon-operator` functionality was moved to the `node-tuning-operator`. For the 4.10 release, the default channel for PAO is `v4.10`. You can also specify the default channels in the common `PolicyGenTemplate` CR.

    4.  Push the `PolicyGenTemplate` CRs updates to the ZTP Git repository.

        ArgoCD pulls the changes from the Git repository and generates the policies on the hub cluster.

    5.  Check the created policies by running the following command:

        ``` terminal
        $ oc get policies -A | grep -E "catsrc-policy|subscription"
        ```

2.  Apply the required catalog source updates before starting the Operator update.

    1.  Save the content of the `ClusterGroupUpgrade` CR named `operator-upgrade-prep` with the catalog source policies and the target spoke clusters to the `cgu-operator-upgrade-prep.yml` file:

        ``` yaml
        apiVersion: ran.openshift.io/v1alpha1
        kind: ClusterGroupUpgrade
        metadata:
          name: cgu-operator-upgrade-prep
          namespace: default
        spec:
          clusters:
          - spoke1
          enable: true
          managedPolicies:
          - du-upgrade-operator-catsrc-policy
          remediationStrategy:
            maxConcurrency: 1
        ```

    2.  Apply the policy to the hub cluster by running the following command:

        ``` terminal
        $ oc apply -f cgu-operator-upgrade-prep.yml
        ```

    3.  Monitor the update process. Upon completion, ensure that the policy is compliant by running the following command:

        ``` terminal
        $ oc get policies -A | grep -E "catsrc-policy"
        ```

3.  Create the `ClusterGroupUpgrade` CR for the Operator update with the `spec.enable` field set to `false`.

    1.  Save the content of the Operator update `ClusterGroupUpgrade` CR with the `du-upgrade-operator-catsrc-policy` policy and the subscription policies created from the common `PolicyGenTemplate` and the target clusters to the `cgu-operator-upgrade.yml` file, as shown in the following example:

        ``` yaml
        apiVersion: ran.openshift.io/v1alpha1
        kind: ClusterGroupUpgrade
        metadata:
          name: cgu-operator-upgrade
          namespace: default
        spec:
          managedPolicies:
          - du-upgrade-operator-catsrc-policy 
          - common-subscriptions-policy 
          preCaching: false
          clusters:
          - spoke1
          remediationStrategy:
            maxConcurrency: 1
          enable: false
        ```

        -   The policy is needed by the image pre-caching feature to retrieve the operator images from the catalog source.

        -   The policy contains Operator subscriptions. If you have followed the structure and content of the reference `PolicyGenTemplates`, all Operator subscriptions are grouped into the `common-subscriptions-policy` policy.

        !!! note
            One ClusterGroupUpgrade CR can only pre-cache the images of the desired Operators defined in the subscription policy from one catalog source included in the ClusterGroupUpgrade CR. If the desired Operators are from different catalog sources, such as in the example of the SRIOV-FEC Operator, another ClusterGroupUpgrade CR must be created with du-upgrade-fec-catsrc-policy and du-upgrade-subscriptions-fec-policy policies for the SRIOV-FEC Operator images pre-caching and update.
        One `ClusterGroupUpgrade` CR can only pre-cache the images of the desired Operators defined in the subscription policy from one catalog source included in the `ClusterGroupUpgrade` CR. If the desired Operators are from different catalog sources, such as in the example of the SRIOV-FEC Operator, another `ClusterGroupUpgrade` CR must be created with `du-upgrade-fec-catsrc-policy` and `du-upgrade-subscriptions-fec-policy` policies for the SRIOV-FEC Operator images pre-caching and update.

    2.  Apply the `ClusterGroupUpgrade` CR to the hub cluster by running the following command:

        ``` terminal
        $ oc apply -f cgu-operator-upgrade.yml
        ```

4.  Optional: Pre-cache the images for the Operator update.

    1.  Before starting image pre-caching, verify the subscription policy is `NonCompliant` at this point by running the following command:

        ``` terminal
        $ oc get policy common-subscriptions-policy -n <policy_namespace>
        ```

        **Example output**

        ``` terminal
        NAME                          REMEDIATION ACTION   COMPLIANCE STATE     AGE
        common-subscriptions-policy   inform               NonCompliant         27d
        ```

    2.  Enable pre-caching in the `ClusterGroupUpgrade` CR by running the following command:

        ``` terminal
        $ oc --namespace=default patch clustergroupupgrade.ran.openshift.io/cgu-operator-upgrade \
        --patch '{"spec":{"preCaching": true}}' --type=merge
        ```

    3.  Monitor the process and wait for the pre-caching to complete. Check the status of pre-caching by running the following command on the spoke cluster:

        ``` terminal
        $ oc get cgu cgu-operator-upgrade -o jsonpath='{.status.precaching.status}'
        ```

    4.  Check if the pre-caching is completed before starting the update by running the following command:

        ``` terminal
        $ oc get cgu -n default cgu-operator-upgrade -ojsonpath='{.status.conditions}' | jq
        ```

        **Example output**

        ``` json
        [
            {
              "lastTransitionTime": "2022-03-08T20:49:08.000Z",
              "message": "The ClusterGroupUpgrade CR is not enabled",
              "reason": "UpgradeNotStarted",
              "status": "False",
              "type": "Ready"
            },
            {
              "lastTransitionTime": "2022-03-08T20:55:30.000Z",
              "message": "Precaching is completed",
              "reason": "PrecachingCompleted",
              "status": "True",
              "type": "PrecachingDone"
            }
        ]
        ```

5.  Start the Operator update.

    1.  Enable the `cgu-operator-upgrade` `ClusterGroupUpgrade` CR and disable pre-caching to start the Operator update by running the following command:

        ``` terminal
        $ oc --namespace=default patch clustergroupupgrade.ran.openshift.io/cgu-operator-upgrade \
        --patch '{"spec":{"enable":true, "preCaching": false}}' --type=merge
        ```

    2.  Monitor the process. Upon completion, ensure that the policy is compliant by running the following command:

        ``` terminal
        $ oc get policies --all-namespaces
        ```

-   For more information about updating GitOps ZTP, see [Upgrading GitOps ZTP](../scalability_and_performance/ztp-deploying-disconnected.xml#ztp-upgrading-gitops-ztp_ztp-deploying-disconnected).

### Performing a platform and an Operator update together

You can perform a platform and an Operator update at the same time.

-   Install the Topology Aware Lifecycle Manager (TALM).

-   Update ZTP to the latest version.

-   Provision one or more managed clusters with ZTP.

-   Log in as a user with `cluster-admin` privileges.

-   Create RHACM policies in the hub cluster.

1.  Create the `PolicyGenTemplate` CR for the updates by following the steps described in the "Performing a platform update" and "Performing an Operator update" sections.

2.  Apply the prep work for the platform and the Operator update.

    1.  Save the content of the `ClusterGroupUpgrade` CR with the policies for platform update preparation work, catalog source updates, and target clusters to the `cgu-platform-operator-upgrade-prep.yml` file, for example:

        ``` yaml
        apiVersion: ran.openshift.io/v1alpha1
        kind: ClusterGroupUpgrade
        metadata:
          name: cgu-platform-operator-upgrade-prep
          namespace: default
        spec:
          managedPolicies:
          - du-upgrade-platform-upgrade-prep
          - du-upgrade-operator-catsrc-policy
          clusterSelector:
          - group-du-sno
          remediationStrategy:
            maxConcurrency: 10
          enable: true
        ```

    2.  Apply the `cgu-platform-operator-upgrade-prep.yml` file to the hub cluster by running the following command:

        ``` terminal
        $ oc apply -f cgu-platform-operator-upgrade-prep.yml
        ```

    3.  Monitor the process. Upon completion, ensure that the policy is compliant by running the following command:

        ``` terminal
        $ oc get policies --all-namespaces
        ```

3.  Create the `ClusterGroupUpdate` CR for the platform and the Operator update with the `spec.enable` field set to `false`.

    1.  Save the contents of the platform and Operator update `ClusterGroupUpdate` CR with the policies and the target clusters to the `cgu-platform-operator-upgrade.yml` file, as shown in the following example:

        ``` yaml
        apiVersion: ran.openshift.io/v1alpha1
        kind: ClusterGroupUpgrade
        metadata:
          name: cgu-du-upgrade
          namespace: default
        spec:
          managedPolicies:
          - du-upgrade-platform-upgrade 
          - du-upgrade-operator-catsrc-policy 
          - common-subscriptions-policy 
          preCaching: true
          clusterSelector:
          - group-du-sno
          remediationStrategy:
            maxConcurrency: 1
          enable: false
        ```

        -   This is the platform update policy.

        -   This is the policy containing the catalog source information for the Operators to be updated. It is needed for the pre-caching feature to determine which Operator images to download to the spoke cluster.

        -   This is the policy to update the Operators.

    2.  Apply the `cgu-platform-operator-upgrade.yml` file to the hub cluster by running the following command:

        ``` terminal
        $ oc apply -f cgu-platform-operator-upgrade.yml
        ```

4.  Optional: Pre-cache the images for the platform and the Operator update.

    1.  Enable pre-caching in the `ClusterGroupUpgrade` CR by running the following command:

        ``` terminal
        $ oc --namespace=default patch clustergroupupgrade.ran.openshift.io/cgu-du-upgrade \
        --patch '{"spec":{"preCaching": true}}' --type=merge
        ```

    2.  Monitor the update process and wait for the pre-caching to complete. Check the status of pre-caching by running the following command on the spoke cluster:

        ``` terminal
        $ oc get jobs,pods -n openshift-talm-pre-cache
        ```

    3.  Check if the pre-caching is completed before starting the update by running the following command:

        ``` terminal
        $ oc get cgu cgu-du-upgrade -ojsonpath='{.status.conditions}'
        ```

5.  Start the platform and Operator update.

    1.  Enable the `cgu-du-upgrade` `ClusterGroupUpgrade` CR to start the platform and the Operator update by running the following command:

        ``` terminal
        $ oc --namespace=default patch clustergroupupgrade.ran.openshift.io/cgu-du-upgrade \
        --patch '{"spec":{"enable":true, "preCaching": false}}' --type=merge
        ```

    2.  Monitor the process. Upon completion, ensure that the policy is compliant by running the following command:

        ``` terminal
        $ oc get policies --all-namespaces
        ```

        !!! note
            The CRs for the platform and Operator updates can be created from the beginning by configuring the setting to spec.enable: true. In this case, the update starts immediately after pre-caching completes and there is no need to manually enable the CR.Both pre-caching and the update create extra resources, such as policies, placement bindings, placement rules, managed cluster actions, and managed cluster view, to help complete the procedures. Setting the afterCompletion.deleteObjects field to true deletes all these resources after the updates complete.
        The CRs for the platform and Operator updates can be created from the beginning by configuring the setting to `spec.enable: true`. In this case, the update starts immediately after pre-caching completes and there is no need to manually enable the CR.

        Both pre-caching and the update create extra resources, such as policies, placement bindings, placement rules, managed cluster actions, and managed cluster view, to help complete the procedures. Setting the `afterCompletion.deleteObjects` field to `true` deletes all these resources after the updates complete.

## Removing Performance Addon Operator subscriptions from deployed clusters

In earlier versions of {product-title}, the Performance Addon Operator provided automatic, low latency performance tuning for applications. In {product-title} 4.11 or later, these functions are part of the Node Tuning Operator.

Do not install the Performance Addon Operator on clusters running {product-title} 4.11 or later. If you upgrade to {product-title} 4.11 or later, the Node Tuning Operator automatically removes the Performance Addon Operator. However, you need to manually remove any policies that create Performance Addon Operator subscriptions to prevent a reinstallation of the Operator. The reference DU profile includes the Performance Addon Operator in the `common-ranGen.yaml` `PolicyGenTemplate`. To remove the subscription from deployed spoke clusters, you must update `common-ranGen.yaml`.

!!! note
    If you install Performance Addon Operator 4.10.3-5 or later on {product-title} 4.11 or later, the Performance Addon Operator detects the cluster version and automatically hibernates to avoid interfering with the Node Tuning Operator functions. However, to ensure best performance, remove the Performance Addon Operator from your {product-title} 4.11 clusters.

If you install Performance Addon Operator 4.10.3-5 or later on {product-title} 4.11 or later, the Performance Addon Operator detects the cluster version and automatically hibernates to avoid interfering with the Node Tuning Operator functions. However, to ensure best performance, remove the Performance Addon Operator from your {product-title} 4.11 clusters.

-   Create a Git repository where you manage your custom site configuration data. The repository must be accessible from the hub cluster and be defined as a source repository for Argo CD.

-   Update to {product-title} 4.11 or later.

-   Log in as a user with `cluster-admin` privileges.

1.  Change the `complianceType` to `mustnothave` for the Performance Addon Operator namespace, Operator group, and subscription in the `common-ranGen.yaml` file.

    ``` yaml
     -  fileName: PaoSubscriptionNS.yaml
        policyName: "subscriptions-policy"
        complianceType: mustnothave
     -  fileName: PaoSubscriptionOperGroup.yaml
        policyName: "subscriptions-policy"
        complianceType: mustnothave
     -  fileName: PaoSubscription.yaml
        policyName: "subscriptions-policy"
        complianceType: mustnothave
    ```

2.  Merge the changes with your custom site repository and wait for the ArgoCD application to synchronize the change to the hub cluster. The status of the `common-subscriptions-policy` policy changes to `Non-Compliant`.

3.  Apply the change to your target clusters by using the Topology Aware Lifecycle Manager. For more information about rolling out configuration changes, see the *Additional resources* section.

4.  Monitor the process. When the status of the `common-subscriptions-policy` policy for a target cluster is `Compliant`, the Performance Addon Operator has been removed from the cluster. Get the status of the `common-subscriptions-policy` by running the following command:

    ``` terminal
    $ oc get policy -n common-subscriptions-policy
    ```

5.  Delete the Performance Addon Operator namespace, Operator group and subscription CRs from `.spec.sourceFiles` in the `common-ranGen.yaml` file.

6.  Merge the changes with your custom site repository and wait for the ArgoCD application to synchronize the change to the hub cluster. The policy remains compliant.

-   [Upgrading GitOps ZTP](../scalability_and_performance/ztp-deploying-disconnected.xml#ztp-roll-out-the-configuration-changes_ztp-deploying-disconnected)
