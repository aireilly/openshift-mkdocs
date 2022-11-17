# Validating cluster tuning for vDU application workloads

Before you can deploy virtualized distributed unit (vDU) applications, you need to tune and configure the cluster host BIOS and various other cluster configuration settings. Use the following information to validate the cluster configuration to support vDU workloads.

-   For a complete reference to configuring single-node OpenShift clusters tuned for vDU application deployments, see [Deploying distributed units manually on single-node OpenShift](../scalability_and_performance/ztp-configuring-single-node-cluster-deployment-during-installation/#sno-du-deploying-distributed-units-manually-on-single-node-openshift).

## Recommended BIOS configuration for vDU cluster hosts

Use the following table as the basis to configure the cluster host BIOS for vDU applications running on OpenShift Container Platform 4.11.

!!! note
    The following table is a general recommendation for vDU cluster host BIOS configuration. Exact BIOS settings will depend on your requirements and specific hardware platform. Automatic setting of BIOS is not handled by the zero touch provisioning pipeline.

+----------------------------------+---------------------+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| BIOS setting                     | Configuration       | Description                                                                                                                                                                                                                  |
+==================================+=====================+==============================================================================================================================================================================================================================+
| HyperTransport (HT)              | Enabled             | HyperTransport (HT) bus is a bus technology developed by AMD. HT provides a high-speed link between the components in the host memory and other system peripherals.                                                          |
+----------------------------------+---------------------+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| UEFI                             | Enabled             | Enable booting from UEFI for the vDU host.                                                                                                                                                                                   |
+----------------------------------+---------------------+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| CPU Power and Performance Policy | Performance         | Set CPU Power and Performance Policy to optimize the system for performance over energy efficiency.                                                                                                                          |
+----------------------------------+---------------------+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| Uncore Frequency Scaling         | Disabled            | Disable Uncore Frequency Scaling to prevent the voltage and frequency of non-core parts of the CPU from being set independently.                                                                                             |
+----------------------------------+---------------------+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| Uncore Frequency                 | Maximum             | Sets the non-core parts of the CPU such as cache and memory controller to their maximum possible frequency of operation.                                                                                                     |
+----------------------------------+---------------------+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| Performance P-limit              | Disabled            | Disable Performance P-limit to prevent the Uncore frequency coordination of processors.                                                                                                                                      |
+----------------------------------+---------------------+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| Enhanced Intel® SpeedStep Tech   | Enabled             | Enable Enhanced Intel SpeedStep to allow the system to dynamically adjust processor voltage and core frequency that decreases power consumption and heat production in the host.                                             |
+----------------------------------+---------------------+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| Intel® Turbo Boost Technology    | Enabled             | Enable Turbo Boost Technology for Intel-based CPUs to automatically allow processor cores to run faster than the rated operating frequency if they are operating below power, current, and temperature specification limits. |
+----------------------------------+---------------------+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| Intel Configurable TDP           | Enabled             | Enables Thermal Design Power (TDP) for the CPU.                                                                                                                                                                              |
+----------------------------------+---------------------+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| Configurable TDP Level           | Level 2             | TDP level sets the CPU power consumption required for a particular performance rating. TDP level 2 sets the CPU to the most stable performance level at the cost of power consumption.                                       |
+----------------------------------+---------------------+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| Energy Efficient Turbo           | Disabled            | Disable Energy Efficient Turbo to prevent the processor from using an energy-efficiency based policy.                                                                                                                        |
+----------------------------------+---------------------+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| Hardware P-States                | Enabled or Disabled | Enable OS-controlled P-States to allow power saving configurations. Disable `P-states` (performance states) to optimize the operating system and CPU for performance over power consumption.                                 |
+----------------------------------+---------------------+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| Package C-State                  | C0/C1 state         | Use C0 or C1 states to set the processor to a fully active state (C0) or to stop CPU internal clocks running in software (C1).                                                                                               |
+----------------------------------+---------------------+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| C1E                              | Disabled            | CPU Enhanced Halt (C1E) is a power saving feature in Intel chips. Disabling C1E prevents the operating system from sending a halt command to the CPU when inactive.                                                          |
+----------------------------------+---------------------+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| Processor C6                     | Disabled            | C6 power-saving is a CPU feature that automatically disables idle CPU cores and cache. Disabling C6 improves system performance.                                                                                             |
+----------------------------------+---------------------+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| Sub-NUMA Clustering              | Disabled            | Sub-NUMA clustering divides the processor cores, cache, and memory into multiple NUMA domains. Disabling this option can increase performance for latency-sensitive workloads.                                               |
+----------------------------------+---------------------+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+

: **Table 1: Recommended cluster host BIOS settings**

!!! note
    Enable global SR-IOV and VT-d settings in the BIOS for the host. These settings are relevant to bare-metal environments.
!!! note
    Enable both `C-states` and OS-controlled `P-States` to allow per pod power management.

## Recommended cluster configurations to run vDU applications

Clusters running virtualized distributed unit (vDU) applications require a highly tuned and optimized configuration. The following information describes the various elements that you require to support vDU workloads in OpenShift Container Platform 4.11 clusters.

### Recommended cluster MachineConfig CRs

The following `MachineConfig` CRs configure the cluster host:

+------------------------------------------------+--------------------------------------------------------------------------------------------------------------------------------+
| CR filename                                    | Description                                                                                                                    |
+================================================+================================================================================================================================+
| `02-workload-partitioning.yaml`                | Configures workload partitioning for the cluster. Apply this `MachineConfig` CR when you install the cluster.                  |
+------------------------------------------------+--------------------------------------------------------------------------------------------------------------------------------+
| `MachineConfigSctp.yaml`                       | Loads the SCTP kernel module. This `MachineConfig` CR is optional and can be omitted if you do not require this kernel module. |
+------------------------------------------------+--------------------------------------------------------------------------------------------------------------------------------+
| `MachineConfigContainerMountNS.yaml`           | Configures the container mount namespace and kubelet conf.                                                                     |
+------------------------------------------------+--------------------------------------------------------------------------------------------------------------------------------+
| `MachineConfigAcceleratedStartup.yaml`         | Configures accelerated startup for the cluster.                                                                                |
+------------------------------------------------+--------------------------------------------------------------------------------------------------------------------------------+
| `06-kdump-master.yaml`, `06-kdump-worker.yaml` | Configures `kdump` for the cluster.                                                                                            |
+------------------------------------------------+--------------------------------------------------------------------------------------------------------------------------------+

: **Table 2: Recommended MachineConfig CRs**

### Recommended cluster Operators

The following Operators are required for clusters running vDU applications and are a part of the baseline reference configuration:

-   Node Tuning Operator (NTO). NTO packages functionality that was previously delivered with the Performance Addon Operator, which is now a part of NTO.

-   PTP Operator

-   SR-IOV Network Operator

-   Red Hat OpenShift Logging Operator

-   Local Storage Operator

### Recommended cluster kernel configuration

Always use the latest supported realtime kernel version in your cluster. You should also ensure that the following configurations are applied in the cluster:

1.  Ensure the following `additionalKernelArgs` are set in the cluster performance profile:

    ``` yaml
    spec:
      additionalKernelArgs:
      - "idle=poll"
      - "rcupdate.rcu_normal_after_boot=0"
      - "efi=runtime"
    ```

2.  Ensure that the `performance-patch` profile in the `Tuned` CR configures the correct CPU isolation set that matches the `isolated` CPU set in the related `PerformanceProfile` CR, for example:

    ``` yaml
    spec:
      profile:
        - name: performance-patch
          # The 'include' line must match the associated PerformanceProfile name
          # And the cmdline_crash CPU set must match the 'isolated' set in the associated PerformanceProfile
          data: |
            [main]
            summary=Configuration changes profile inherited from performance created tuned
            include=openshift-node-performance-openshift-node-performance-profile
            [bootloader]
            cmdline_crash=nohz_full=2-51,54-103 
            [sysctl]
            kernel.timer_migration=1
            [scheduler]
            group.ice-ptp=0:f:10:*:ice-ptp.*
            [service]
            service.stalld=start,enable
            service.chronyd=stop,disable
    ```

    -   Listed CPUs depend on the host hardware configuration, specifically the number of available CPUs in the system and the CPU topology.

### Checking the realtime kernel version

Always use the latest version of the realtime kernel in your OpenShift Container Platform clusters. If you are unsure about the kernel version that is in use in the cluster, you can compare the current realtime kernel version to the release version with the following procedure.

**Prerequisites**

-   You have installed the OpenShift CLI (`oc`).

-   You are logged in as a user with `cluster-admin` privileges.

-   You have installed `podman`.

**Procedure**

1.  Run the following command to get the cluster version:

    ``` terminal
    $ OCP_VERSION=$(oc get clusterversion version -o jsonpath='{.status.desired.version}{"\n"}')
    ```

2.  Get the release image SHA number:

    ``` terminal
    $ DTK_IMAGE=$(oc adm release info --image-for=driver-toolkit quay.io/openshift-release-dev/ocp-release:$OCP_VERSION-x86_64)
    ```

3.  Run the release image container and extract the kernel version that is packaged with cluster’s current release:

    ``` terminal
    $ podman run --rm $DTK_IMAGE rpm -qa | grep 'kernel-rt-core-' | sed 's#kernel-rt-core-##'
    ```

    **Example output**

    ``` terminal
    4.18.0-305.49.1.rt7.121.el8_4.x86_64
    ```

    This is the default realtime kernel version that ships with the release.

    !!! note
        The realtime kernel is denoted by the string `.rt` in the kernel version.

**Verification**

Check that the kernel version listed for the cluster’s current release matches actual realtime kernel that is running in the cluster. Run the following commands to check the running realtime kernel version:

1.  Open a remote shell connection to the cluster node:

    ``` terminal
    $ oc debug node/<node_name>
    ```

2.  Check the realtime kernel version:

    ``` terminal
    sh-4.4# uname -r
    ```

    **Example output**

    ``` terminal
    4.18.0-305.49.1.rt7.121.el8_4.x86_64
    ```

## Checking that the recommended cluster configurations are applied

You can check that clusters are running the correct configuration. The following procedure describes how to check the various configurations that you require to deploy a DU application in OpenShift Container Platform 4.11 clusters.

**Prerequisites**

-   You have deployed a cluster and tuned it for vDU workloads.

-   You have installed the OpenShift CLI (`oc`).

-   You have logged in as a user with `cluster-admin` privileges.

**Procedure**

1.  Check that the default Operator Hub sources are disabled. Run the following command:

    ``` terminal
    $ oc get operatorhub cluster -o yaml
    ```

    **Example output**

    ``` yaml
    spec:
        disableAllDefaultSources: true
    ```

2.  Check that all required `CatalogSource` resources are annotated for workload partitioning (`PreferredDuringScheduling`) by running the following command:

    ``` terminal
    $ oc get catalogsource -A -o jsonpath='{range .items[*]}{.metadata.name}{" -- "}{.metadata.annotations.target\.workload\.openshift\.io/management}{"\n"}{end}'
    ```

    **Example output**

    ``` terminal
    certified-operators -- {"effect": "PreferredDuringScheduling"}
    community-operators -- {"effect": "PreferredDuringScheduling"}
    ran-operators 
    redhat-marketplace -- {"effect": "PreferredDuringScheduling"}
    redhat-operators -- {"effect": "PreferredDuringScheduling"}
    ```

    -   `CatalogSource` resources that are not annotated are also returned. In this example, the `ran-operators` `CatalogSource` resource is not annotated and does not have the `PreferredDuringScheduling` annotation.

    !!! note
        In a properly configured vDU cluster, only a single annotated catalog source is listed.

3.  Check that all applicable OpenShift Container Platform Operator namespaces are annotated for workload partitioning. This includes all Operators installed with core OpenShift Container Platform and the set of additional Operators included in the reference DU tuning configuration. Run the following command:

    ``` terminal
    $ oc get namespaces -A -o jsonpath='{range .items[*]}{.metadata.name}{" -- "}{.metadata.annotations.workload\.openshift\.io/allowed}{"\n"}{end}'
    ```

    **Example output**

    ``` terminal
    default --
    openshift-apiserver -- management
    openshift-apiserver-operator -- management
    openshift-authentication -- management
    openshift-authentication-operator -- management
    ```

    !!! important
        Additional Operators must not be annotated for workload partitioning. In the output from the previous command, additional Operators should be listed without any value on the right-hand side of the `--` separator.

4.  Check that the `ClusterLogging` configuration is correct. Run the following commands:

    1.  Validate that the appropriate input and output logs are configured:

        ``` terminal
        $ oc get -n openshift-logging ClusterLogForwarder instance -o yaml
        ```

        **Example output**

        ``` yaml
        apiVersion: logging.openshift.io/v1
        kind: ClusterLogForwarder
        metadata:
          creationTimestamp: "2022-07-19T21:51:41Z"
          generation: 1
          name: instance
          namespace: openshift-logging
          resourceVersion: "1030342"
          uid: 8c1a842d-80c5-447a-9150-40350bdf40f0
        spec:
          inputs:
          - infrastructure: {}
            name: infra-logs
          outputs:
          - name: kafka-open
            type: kafka
            url: tcp://10.46.55.190:9092/test
          pipelines:
          - inputRefs:
            - audit
            name: audit-logs
            outputRefs:
            - kafka-open
          - inputRefs:
            - infrastructure
            name: infrastructure-logs
            outputRefs:
            - kafka-open
        ...
        ```

    2.  Check that the curation schedule is appropriate for your application:

        ``` terminal
        $ oc get -n openshift-logging clusterloggings.logging.openshift.io instance -o yaml
        ```

        **Example output**

        ``` yaml
        apiVersion: logging.openshift.io/v1
        kind: ClusterLogging
        metadata:
          creationTimestamp: "2022-07-07T18:22:56Z"
          generation: 1
          name: instance
          namespace: openshift-logging
          resourceVersion: "235796"
          uid: ef67b9b8-0e65-4a10-88ff-ec06922ea796
        spec:
          collection:
            logs:
              fluentd: {}
              type: fluentd
          curation:
            curator:
              schedule: 30 3 * * *
            type: curator
          managementState: Managed
        ...
        ```

5.  Check that the web console is disabled (`managementState: Removed`) by running the following command:

    ``` terminal
    $ oc get consoles.operator.openshift.io cluster -o jsonpath="{ .spec.managementState }"
    ```

    **Example output**

    ``` terminal
    Removed
    ```

6.  Check that `chronyd` is disabled on the cluster node by running the following commands:

    ``` terminal
    $ oc debug node/<node_name>
    ```

    Check the status of `chronyd` on the node:

    ``` terminal
    sh-4.4# chroot /host
    ```

    ``` terminal
    sh-4.4# systemctl status chronyd
    ```

    **Example output**

    ``` terminal
    ● chronyd.service - NTP client/server
        Loaded: loaded (/usr/lib/systemd/system/chronyd.service; disabled; vendor preset: enabled)
        Active: inactive (dead)
          Docs: man:chronyd(8)
                man:chrony.conf(5)
    ```

7.  Check that the PTP interface is successfully synchronized to the primary clock using a remote shell connection to the `linuxptp-daemon` container and the PTP Management Client (`pmc`) tool:

    1.  Set the `$PTP_POD_NAME` variable with the name of the `linuxptp-daemon` pod by running the following command:

        ``` terminal
        $ PTP_POD_NAME=$(oc get pods -n openshift-ptp -l app=linuxptp-daemon -o name)
        ```

    2.  Run the following command to check the sync status of the PTP device:

        ``` terminal
        $ oc -n openshift-ptp rsh -c linuxptp-daemon-container ${PTP_POD_NAME} pmc -u -f /var/run/ptp4l.0.config -b 0 'GET PORT_DATA_SET'
        ```

        **Example output**

        ``` terminal
        sending: GET PORT_DATA_SET
          3cecef.fffe.7a7020-1 seq 0 RESPONSE MANAGEMENT PORT_DATA_SET
            portIdentity            3cecef.fffe.7a7020-1
            portState               SLAVE
            logMinDelayReqInterval  -4
            peerMeanPathDelay       0
            logAnnounceInterval     1
            announceReceiptTimeout  3
            logSyncInterval         0
            delayMechanism          1
            logMinPdelayReqInterval 0
            versionNumber           2
          3cecef.fffe.7a7020-2 seq 0 RESPONSE MANAGEMENT PORT_DATA_SET
            portIdentity            3cecef.fffe.7a7020-2
            portState               LISTENING
            logMinDelayReqInterval  0
            peerMeanPathDelay       0
            logAnnounceInterval     1
            announceReceiptTimeout  3
            logSyncInterval         0
            delayMechanism          1
            logMinPdelayReqInterval 0
            versionNumber           2
        ```

    3.  Run the following `pmc` command to check the PTP clock status:

        ``` terminal
        $ oc -n openshift-ptp rsh -c linuxptp-daemon-container ${PTP_POD_NAME} pmc -u -f /var/run/ptp4l.0.config -b 0 'GET TIME_STATUS_NP'
        ```

        **Example output**

        ``` terminal
        sending: GET TIME_STATUS_NP
          3cecef.fffe.7a7020-0 seq 0 RESPONSE MANAGEMENT TIME_STATUS_NP
            master_offset              10 
            ingress_time               1657275432697400530
            cumulativeScaledRateOffset +0.000000000
            scaledLastGmPhaseChange    0
            gmTimeBaseIndicator        0
            lastGmPhaseChange          0x0000'0000000000000000.0000
            gmPresent                  true 
            gmIdentity                 3c2c30.ffff.670e00
        ```

        -   `master_offset` should be between -100 and 100 ns.

        -   Indicates that the PTP clock is synchronized to a master, and the local clock is not the grandmaster clock.

    4.  Check that the expected `master offset` value corresponding to the value in `/var/run/ptp4l.0.config` is found in the `linuxptp-daemon-container` log:

        ``` terminal
        $ oc logs $PTP_POD_NAME -n openshift-ptp -c linuxptp-daemon-container
        ```

        **Example output**

        ``` terminal
        phc2sys[56020.341]: [ptp4l.1.config] CLOCK_REALTIME phc offset  -1731092 s2 freq -1546242 delay    497
        ptp4l[56020.390]: [ptp4l.1.config] master offset         -2 s2 freq   -5863 path delay       541
        ptp4l[56020.390]: [ptp4l.0.config] master offset         -8 s2 freq  -10699 path delay       533
        ```

8.  Check that the SR-IOV configuration is correct by running the following commands:

    1.  Check that the `disableDrain` value in the `SriovOperatorConfig` resource is set to `true`:

        ``` terminal
        $ oc get sriovoperatorconfig -n openshift-sriov-network-operator default -o jsonpath="{.spec.disableDrain}{'\n'}"
        ```

        **Example output**

        ``` terminal
        true
        ```

    2.  Check that the `SriovNetworkNodeState` sync status is `Succeeded` by running the following command:

        ``` terminal
        $ oc get SriovNetworkNodeStates -n openshift-sriov-network-operator -o jsonpath="{.items[*].status.syncStatus}{'\n'}"
        ```

        **Example output**

        ``` terminal
        Succeeded
        ```

    3.  Verify that the expected number and configuration of virtual functions (`Vfs`) under each interface configured for SR-IOV is present and correct in the `.status.interfaces` field. For example:

        ``` terminal
        $ oc get SriovNetworkNodeStates -n openshift-sriov-network-operator -o yaml
        ```

        **Example output**

        ``` yaml
        apiVersion: v1
        items:
        - apiVersion: sriovnetwork.openshift.io/v1
          kind: SriovNetworkNodeState
        ...
          status:
            interfaces:
            ...
            - Vfs:
              - deviceID: 154c
                driver: vfio-pci
                pciAddress: 0000:3b:0a.0
                vendor: "8086"
                vfID: 0
              - deviceID: 154c
                driver: vfio-pci
                pciAddress: 0000:3b:0a.1
                vendor: "8086"
                vfID: 1
              - deviceID: 154c
                driver: vfio-pci
                pciAddress: 0000:3b:0a.2
                vendor: "8086"
                vfID: 2
              - deviceID: 154c
                driver: vfio-pci
                pciAddress: 0000:3b:0a.3
                vendor: "8086"
                vfID: 3
              - deviceID: 154c
                driver: vfio-pci
                pciAddress: 0000:3b:0a.4
                vendor: "8086"
                vfID: 4
              - deviceID: 154c
                driver: vfio-pci
                pciAddress: 0000:3b:0a.5
                vendor: "8086"
                vfID: 5
              - deviceID: 154c
                driver: vfio-pci
                pciAddress: 0000:3b:0a.6
                vendor: "8086"
                vfID: 6
              - deviceID: 154c
                driver: vfio-pci
                pciAddress: 0000:3b:0a.7
                vendor: "8086"
                vfID: 7
        ```

9.  Check that the cluster performance profile is correct. The `cpu` and `hugepages` sections will vary depending on your hardware configuration. Run the following command:

    ``` terminal
    $ oc get PerformanceProfile openshift-node-performance-profile -o yaml
    ```

    **Example output**

    ``` yaml
    apiVersion: performance.openshift.io/v2
    kind: PerformanceProfile
    metadata:
      creationTimestamp: "2022-07-19T21:51:31Z"
      finalizers:
      - foreground-deletion
      generation: 1
      name: openshift-node-performance-profile
      resourceVersion: "33558"
      uid: 217958c0-9122-4c62-9d4d-fdc27c31118c
    spec:
      additionalKernelArgs:
      - idle=poll
      - rcupdate.rcu_normal_after_boot=0
      - efi=runtime
      cpu:
        isolated: 2-51,54-103
        reserved: 0-1,52-53
      hugepages:
        defaultHugepagesSize: 1G
        pages:
        - count: 32
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
    status:
      conditions:
      - lastHeartbeatTime: "2022-07-19T21:51:31Z"
        lastTransitionTime: "2022-07-19T21:51:31Z"
        status: "True"
        type: Available
      - lastHeartbeatTime: "2022-07-19T21:51:31Z"
        lastTransitionTime: "2022-07-19T21:51:31Z"
        status: "True"
        type: Upgradeable
      - lastHeartbeatTime: "2022-07-19T21:51:31Z"
        lastTransitionTime: "2022-07-19T21:51:31Z"
        status: "False"
        type: Progressing
      - lastHeartbeatTime: "2022-07-19T21:51:31Z"
        lastTransitionTime: "2022-07-19T21:51:31Z"
        status: "False"
        type: Degraded
      runtimeClass: performance-openshift-node-performance-profile
      tuned: openshift-cluster-node-tuning-operator/openshift-node-performance-openshift-node-performance-profile
    ```

    !!! note
        CPU settings are dependent on the number of cores available on the server and should align with workload partitioning settings. `hugepages` configuration is server and application dependent.

10. Check that the `PerformanceProfile` was successfully applied to the cluster by running the following command:

    ``` terminal
    $ oc get performanceprofile openshift-node-performance-profile -o jsonpath="{range .status.conditions[*]}{ @.type }{' -- '}{@.status}{'\n'}{end}"
    ```

    **Example output**

    ``` terminal
    Available -- True
    Upgradeable -- True
    Progressing -- False
    Degraded -- False
    ```

11. Check the `Tuned` performance patch settings by running the following command:

    ``` terminal
    $ oc get tuneds.tuned.openshift.io -n openshift-cluster-node-tuning-operator performance-patch -o yaml
    ```

    **Example output**

    ``` yaml
    apiVersion: tuned.openshift.io/v1
    kind: Tuned
    metadata:
      creationTimestamp: "2022-07-18T10:33:52Z"
      generation: 1
      name: performance-patch
      namespace: openshift-cluster-node-tuning-operator
      resourceVersion: "34024"
      uid: f9799811-f744-4179-bf00-32d4436c08fd
    spec:
      profile:
      - data: |
          [main]
          summary=Configuration changes profile inherited from performance created tuned
          include=openshift-node-performance-openshift-node-performance-profile
          [bootloader]
          cmdline_crash=nohz_full=2-23,26-47 
          [sysctl]
          kernel.timer_migration=1
          [scheduler]
          group.ice-ptp=0:f:10:*:ice-ptp.*
          [service]
          service.stalld=start,enable
          service.chronyd=stop,disable
        name: performance-patch
      recommend:
      - machineConfigLabels:
          machineconfiguration.openshift.io/role: master
        priority: 19
        profile: performance-patch
    ```

    -   The cpu list in `cmdline=nohz_full=` will vary based on your hardware configuration.

12. Check that cluster networking diagnostics are disabled by running the following command:

    ``` terminal
    $ oc get networks.operator.openshift.io cluster -o jsonpath='{.spec.disableNetworkDiagnostics}'
    ```

    **Example output**

    ``` terminal
    true
    ```

13. Check that the `Kubelet` housekeeping interval is tuned to slower rate. This is set in the `containerMountNS` machine config. Run the following command:

    ``` terminal
    $ oc describe machineconfig container-mount-namespace-and-kubelet-conf-master | grep OPENSHIFT_MAX_HOUSEKEEPING_INTERVAL_DURATION
    ```

    **Example output**

    ``` terminal
    Environment="OPENSHIFT_MAX_HOUSEKEEPING_INTERVAL_DURATION=60s"
    ```

14. Check that Grafana and `alertManagerMain` are disabled and that the Prometheus retention period is set to 24h by running the following command:

    ``` terminal
    $ oc get configmap cluster-monitoring-config -n openshift-monitoring -o jsonpath="{ .data.config\.yaml }"
    ```

    **Example output**

    ``` terminal
    grafana:
      enabled: false
    alertmanagerMain:
      enabled: false
    prometheusK8s:
       retention: 24h
    ```

    1.  Use the following commands to verify that Grafana and `alertManagerMain` routes are not found in the cluster:

        ``` terminal
        $ oc get route -n openshift-monitoring alertmanager-main
        ```

        ``` terminal
        $ oc get route -n openshift-monitoring grafana
        ```

        Both queries should return `Error from server (NotFound)` messages.

15. Check that there is a minimum of 4 CPUs allocated as `reserved` for each of the `PerformanceProfile`, `Tuned` performance-patch, workload partitioning, and kernel command line arguments by running the following command:

    ``` terminal
    $ oc get performanceprofile -o jsonpath="{ .items[0].spec.cpu.reserved }"
    ```

    **Example output**

    ``` terminal
    0-1,52-53
    ```

    !!! note
        Depending on your workload requirements, you might require additional reserved CPUs to be allocated.
