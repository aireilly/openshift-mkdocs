# Deploying distributed units manually on single-node OpenShift

The procedures in this topic tell you how to manually deploy clusters on a small number of single nodes as a distributed unit (DU) during installation.

The procedures do not describe how to install single-node OpenShift. This can be accomplished through many mechanisms. Rather, they are intended to capture the elements that should be configured as part of the installation process:

-   Networking is needed to enable connectivity to the single-node OpenShift DU when the installation is complete.

-   Workload partitioning, which can only be configured during installation.

-   Additional items that help minimize the potential reboots post installation.

## Configuring the distributed units (DUs)

This section describes a set of configurations for an OpenShift Container Platform cluster so that it meets the feature and performance requirements necessary for running a distributed unit (DU) application. Some of this content must be applied during installation and other configurations can be applied post-install.

After you have installed the single-node OpenShift DU, further configuration is needed to enable the platform to carry a DU workload.

The configurations in this section are applied to the cluster after installation in order to configure the cluster for DU workloads.

### Enabling workload partitioning

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

### Configuring the container mount namespace

To reduce the overall management footprint of the platform, a machine configuration is provided to contain the mount points. No configuration changes are needed. Use the provided settings:

``` yaml
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  labels:
    machineconfiguration.openshift.io/role: master
  name: container-mount-namespace-and-kubelet-conf-master
spec:
  config:
    ignition:
      version: 3.2.0
    storage:
      files:
      - contents:
          source: data:text/plain;charset=utf-8;base64,IyEvYmluL2Jhc2gKCmRlYnVnKCkgewogIGVjaG8gJEAgPiYyCn0KCnVzYWdlKCkgewogIGVjaG8gVXNhZ2U6ICQoYmFzZW5hbWUgJDApIFVOSVQgW2VudmZpbGUgW3Zhcm5hbWVdXQogIGVjaG8KICBlY2hvIEV4dHJhY3QgdGhlIGNvbnRlbnRzIG9mIHRoZSBmaXJzdCBFeGVjU3RhcnQgc3RhbnphIGZyb20gdGhlIGdpdmVuIHN5c3RlbWQgdW5pdCBhbmQgcmV0dXJuIGl0IHRvIHN0ZG91dAogIGVjaG8KICBlY2hvICJJZiAnZW52ZmlsZScgaXMgcHJvdmlkZWQsIHB1dCBpdCBpbiB0aGVyZSBpbnN0ZWFkLCBhcyBhbiBlbnZpcm9ubWVudCB2YXJpYWJsZSBuYW1lZCAndmFybmFtZSciCiAgZWNobyAiRGVmYXVsdCAndmFybmFtZScgaXMgRVhFQ1NUQVJUIGlmIG5vdCBzcGVjaWZpZWQiCiAgZXhpdCAxCn0KClVOSVQ9JDEKRU5WRklMRT0kMgpWQVJOQU1FPSQzCmlmIFtbIC16ICRVTklUIHx8ICRVTklUID09ICItLWhlbHAiIHx8ICRVTklUID09ICItaCIgXV07IHRoZW4KICB1c2FnZQpmaQpkZWJ1ZyAiRXh0cmFjdGluZyBFeGVjU3RhcnQgZnJvbSAkVU5JVCIKRklMRT0kKHN5c3RlbWN0bCBjYXQgJFVOSVQgfCBoZWFkIC1uIDEpCkZJTEU9JHtGSUxFI1wjIH0KaWYgW1sgISAtZiAkRklMRSBdXTsgdGhlbgogIGRlYnVnICJGYWlsZWQgdG8gZmluZCByb290IGZpbGUgZm9yIHVuaXQgJFVOSVQgKCRGSUxFKSIKICBleGl0CmZpCmRlYnVnICJTZXJ2aWNlIGRlZmluaXRpb24gaXMgaW4gJEZJTEUiCkVYRUNTVEFSVD0kKHNlZCAtbiAtZSAnL15FeGVjU3RhcnQ9LipcXCQvLC9bXlxcXSQvIHsgcy9eRXhlY1N0YXJ0PS8vOyBwIH0nIC1lICcvXkV4ZWNTdGFydD0uKlteXFxdJC8geyBzL15FeGVjU3RhcnQ9Ly87IHAgfScgJEZJTEUpCgppZiBbWyAkRU5WRklMRSBdXTsgdGhlbgogIFZBUk5BTUU9JHtWQVJOQU1FOi1FWEVDU1RBUlR9CiAgZWNobyAiJHtWQVJOQU1FfT0ke0VYRUNTVEFSVH0iID4gJEVOVkZJTEUKZWxzZQogIGVjaG8gJEVYRUNTVEFSVApmaQo=
        mode: 493
        path: /usr/local/bin/extractExecStart
      - contents:
          source: data:text/plain;charset=utf-8;base64,IyEvYmluL2Jhc2gKbnNlbnRlciAtLW1vdW50PS9ydW4vY29udGFpbmVyLW1vdW50LW5hbWVzcGFjZS9tbnQgIiRAIgo=
        mode: 493
        path: /usr/local/bin/nsenterCmns
    systemd:
      units:
      - contents: |
          [Unit]
          Description=Manages a mount namespace that both kubelet and crio can use to share their container-specific mounts

          [Service]
          Type=oneshot
          RemainAfterExit=yes
          RuntimeDirectory=container-mount-namespace
          Environment=RUNTIME_DIRECTORY=%t/container-mount-namespace
          Environment=BIND_POINT=%t/container-mount-namespace/mnt
          ExecStartPre=bash -c "findmnt ${RUNTIME_DIRECTORY} || mount --make-unbindable --bind ${RUNTIME_DIRECTORY} ${RUNTIME_DIRECTORY}"
          ExecStartPre=touch ${BIND_POINT}
          ExecStart=unshare --mount=${BIND_POINT} --propagation slave mount --make-rshared /
          ExecStop=umount -R ${RUNTIME_DIRECTORY}
        enabled: true
        name: container-mount-namespace.service
      - dropins:
        - contents: |
            [Unit]
            Wants=container-mount-namespace.service
            After=container-mount-namespace.service

            [Service]
            ExecStartPre=/usr/local/bin/extractExecStart %n /%t/%N-execstart.env ORIG_EXECSTART
            EnvironmentFile=-/%t/%N-execstart.env
            ExecStart=
            ExecStart=bash -c "nsenter --mount=%t/container-mount-namespace/mnt \
                ${ORIG_EXECSTART}"
          name: 90-container-mount-namespace.conf
        name: crio.service
      - dropins:
        - contents: |
            [Unit]
            Wants=container-mount-namespace.service
            After=container-mount-namespace.service

            [Service]
            ExecStartPre=/usr/local/bin/extractExecStart %n /%t/%N-execstart.env ORIG_EXECSTART
            EnvironmentFile=-/%t/%N-execstart.env
            ExecStart=
            ExecStart=bash -c "nsenter --mount=%t/container-mount-namespace/mnt \
                ${ORIG_EXECSTART} --housekeeping-interval=30s"
          name: 90-container-mount-namespace.conf
        - contents: |
            [Service]
            Environment="OPENSHIFT_MAX_HOUSEKEEPING_INTERVAL_DURATION=60s"
            Environment="OPENSHIFT_EVICTION_MONITORING_PERIOD_DURATION=30s"
          name: 30-kubelet-interval-tuning.conf
        name: kubelet.service
```

### Enabling Stream Control Transmission Protocol (SCTP)

SCTP is a key protocol used in RAN applications. This `MachineConfig` object adds the SCTP kernel module to the node to enable this protocol.

-   No configuration changes are needed. Use the provided settings:

    ``` yaml
    apiVersion: machineconfiguration.openshift.io/v1
    kind: MachineConfig
    metadata:
      labels:
        machineconfiguration.openshift.io/role: master
      name: load-sctp-module
    spec:
      config:
        ignition:
          version: 2.2.0
        storage:
          files:
            - contents:
                source: data:,
                verification: {}
              filesystem: root
                mode: 420
                path: /etc/modprobe.d/sctp-blacklist.conf
            - contents:
                source: data:text/plain;charset=utf-8,sctp
              filesystem: root
                mode: 420
                path: /etc/modules-load.d/sctp-load.conf
    ```

### Creating OperatorGroups for Operators

This configuration is provided to enable addition of the Operators needed to configure the platform post-installation. It adds the `Namespace` and `OperatorGroup` objects for the Local Storage Operator, Logging Operator, PTP Operator, and SR-IOV Network Operator.

-   No configuration changes are needed. Use the provided settings:

    **Local Storage Operator**

    ``` yaml
    apiVersion: v1
    kind: Namespace
    metadata:
      annotations:
        workload.openshift.io/allowed: management
      name: openshift-local-storage
    ---
    apiVersion: operators.coreos.com/v1
    kind: OperatorGroup
    metadata:
      name: openshift-local-storage
      namespace: openshift-local-storage
    spec:
      targetNamespaces:
        - openshift-local-storage
    ```

    **Logging Operator**

    ``` yaml
    apiVersion: v1
    kind: Namespace
    metadata:
      annotations:
        workload.openshift.io/allowed: management
      name: openshift-logging
    ---
    apiVersion: operators.coreos.com/v1
    kind: OperatorGroup
    metadata:
      name: cluster-logging
      namespace: openshift-logging
    spec:
      targetNamespaces:
        - openshift-logging
    ```

    **PTP Operator**

    ``` yaml
    apiVersion: v1
    kind: Namespace
    metadata:
      annotations:
        workload.openshift.io/allowed: management
      labels:
        openshift.io/cluster-monitoring: "true"
      name: openshift-ptp
    ---
    apiVersion: operators.coreos.com/v1
    kind: OperatorGroup
    metadata:
      name: ptp-operators
      namespace: openshift-ptp
    spec:
      targetNamespaces:
        - openshift-ptp
    ```

    **SR-IOV Network Operator**

    ``` yaml
    apiVersion: v1
    kind: Namespace
    metadata:
      annotations:
        workload.openshift.io/allowed: management
        name: openshift-sriov-network-operator
    ---
    apiVersion: operators.coreos.com/v1
    kind: OperatorGroup
    metadata:
      name: sriov-network-operators
      namespace: openshift-sriov-network-operator
    spec:
      targetNamespaces:
        - openshift-sriov-network-operator
    ```

### Subscribing to the Operators

The subscription provides the location to download the Operators needed for platform configuration.

-   Use the following example to configure the subscription:

    ``` yaml
    apiVersion: operators.coreos.com/v1alpha1
    kind: Subscription
    metadata:
      name: cluster-logging
      namespace: openshift-logging
    spec:
      channel: "stable" 
      name: cluster-logging
      source: redhat-operators
      sourceNamespace: openshift-marketplace
      installPlanApproval: Manual 
    ---
    apiVersion: operators.coreos.com/v1alpha1
    kind: Subscription
    metadata:
      name: local-storage-operator
      namespace: openshift-local-storage
    spec:
      channel: "stable" 
      installPlanApproval: Automatic
      name: local-storage-operator
      source: redhat-operators
      sourceNamespace: openshift-marketplace
      installPlanApproval: Manual
    ---
    apiVersion: operators.coreos.com/v1alpha1
    kind: Subscription
    metadata:
        name: ptp-operator-subscription
        namespace: openshift-ptp
    spec:
      channel: "stable" 
      name: ptp-operator
      source: redhat-operators
      sourceNamespace: openshift-marketplace
      installPlanApproval: Manual
    ---
    apiVersion: operators.coreos.com/v1alpha1
    kind: Subscription
    metadata:
      name: sriov-network-operator-subscription
      namespace: openshift-sriov-network-operator
    spec:
      channel: "stable" 
      name: sriov-network-operator
      source: redhat-operators
      sourceNamespace: openshift-marketplace
      installPlanApproval: Manual
    ```

    -   Specify the channel to get the `cluster-logging` Operator.

    -   Specify `Manual` or `Automatic`. In `Automatic` mode, the Operator automatically updates to the latest versions in the channel as they become available in the registry. In `Manual` mode, new Operator versions are installed only after they are explicitly approved.

    -   Specify the channel to get the `local-storage-operator` Operator.

    -   Specify the channel to get the `ptp-operator` Operator.

    -   Specify the channel to get the `sriov-network-operator` Operator.

### Configuring logging locally and forwarding

To be able to debug a single node distributed unit (DU), logs need to be stored for further analysis.

-   Edit the `ClusterLogging` custom resource (CR) in the `openshift-logging` project:

    ``` yaml
    apiVersion: logging.openshift.io/v1
    kind: ClusterLogging 
     metadata:
      name: instance
      namespace: openshift-logging
    spec:
      collection:
        logs:
          fluentd: {}
          type: fluentd
      curation:
        type: "curator"
        curator:
          schedule: "30 3 * * *"
        managementState: Managed
    ---
    apiVersion: logging.openshift.io/v1
    kind: ClusterLogForwarder 
    metadata:
      name: instance
      namespace: openshift-logging
    spec:
      inputs:
        - infrastructure: {}
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
    ```

    -   Updates the existing instance or creates the instance if it does not exist.

    -   Updates the existing instance or creates the instance if it does not exist.

    -   Specifies the destination of the kafka server.

### Configuring the Node Tuning Operator

This is a key configuration for the single node distributed unit (DU). Many of the real-time capabilities and service assurance are configured here.

-   Configure the performance profile using the following example:

    ``` yaml
    apiVersion: performance.openshift.io/v2
    kind: PerformanceProfile
    metadata:
      name: perfprofile-policy
    spec:
      additionalKernelArgs:
        - idle=poll
        - rcupdate.rcu_normal_after_boot=0
      cpu:
        isolated: 2-19,22-39 
        reserved: 0-1,20-21 
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
    ```

<!-- -->

-   Set the isolated CPUs. Ensure all of the HT pairs match.

-   Set the reserved CPUs. In this case, a hyperthreaded pair is allocated on NUMA 0 and a pair on NUMA 1.

-   Set the huge page size.

-   Set the huge page number.

-   Set to `true` to isolate the CPUs from networking interrupts.

-   Set to `true` to install the real-time Linux kernel.

### Configuring Precision Time Protocol (PTP)

In the far edge, the RAN uses PTP to synchronize the systems.

-   Configure PTP using the following example:

    ``` yaml
    apiVersion: ptp.openshift.io/v1
    kind: PtpConfig
    metadata:
      name: du-ptp-slave
      namespace: openshift-ptp
    spec:
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
            tx_timestamp_timeout 50
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
            step_threshold 2.0
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
            network_transport L2
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
          ptp4lOpts: -2 -s --summary_interval -4
    recommend:
      - match:
          - nodeLabel: node-role.kubernetes.io/master
        priority: 4
        profile: slave
    ```

<!-- -->

-   Sets the interface used for PTP.

### Disabling Network Time Protocol (NTP)

After the system is configured for Precision Time Protocol (PTP), you need to remove NTP to prevent it from impacting the system clock.

-   No configuration changes are needed. Use the provided settings:

    ``` yaml
    apiVersion: machineconfiguration.openshift.io/v1
    kind: MachineConfig
    metadata:
      labels:
        machineconfiguration.openshift.io/role: master
      name: disable-chronyd
    spec:
      config:
        systemd:
          units:
            - contents: |
                [Unit]
                Description=NTP client/server
                Documentation=man:chronyd(8) man:chrony.conf(5)
                After=ntpdate.service sntp.service ntpd.service
                Conflicts=ntpd.service systemd-timesyncd.service
                ConditionCapability=CAP_SYS_TIME
                [Service]
                Type=forking
                PIDFile=/run/chrony/chronyd.pid
                EnvironmentFile=-/etc/sysconfig/chronyd
                ExecStart=/usr/sbin/chronyd $OPTIONS
                ExecStartPost=/usr/libexec/chrony-helper update-daemon
                PrivateTmp=yes
                ProtectHome=yes
                ProtectSystem=full
                [Install]
                WantedBy=multi-user.target
              enabled: false
              name: chronyd.service
        ignition:
          version: 2.2.0
    ```

### Configuring single root I/O virtualization (SR-IOV)

SR-IOV is commonly used to enable the fronthaul and the midhaul networks.

-   Use the following configuration to configure SRIOV on a single node distributed unit (DU). Note that the first custom resource (CR) is required. The following CRs are examples.

    ``` yaml
    apiVersion: sriovnetwork.openshift.io/v1
    kind: SriovOperatorConfig
    metadata:
      name: default
      namespace: openshift-sriov-network-operator
    spec:
      configDaemonNodeSelector:
        node-role.kubernetes.io/master: ""
      disableDrain: true
      enableInjector: true
      enableOperatorWebhook: true
    ---
    apiVersion: sriovnetwork.openshift.io/v1
    kind: SriovNetwork
    metadata:
      name: sriov-nw-du-mh
      namespace: openshift-sriov-network-operator
    spec:
      networkNamespace: openshift-sriov-network-operator
      resourceName: du_mh
      vlan: 150 
    ---
    apiVersion: sriovnetwork.openshift.io/v1
    kind: SriovNetworkNodePolicy
    metadata:
      name: sriov-nnp-du-mh
      namespace: openshift-sriov-network-operator
    spec:
      deviceType: vfio-pci 
      isRdma: false
      nicSelector:
        pfNames:
          - ens7f0 
      nodeSelector:
        node-role.kubernetes.io/master: ""
      numVfs: 8 
      priority: 10
      resourceName: du_mh
    ---
    apiVersion: sriovnetwork.openshift.io/v1
    kind: SriovNetwork
    metadata:
      name: sriov-nw-du-fh
      namespace: openshift-sriov-network-operator
    spec:
      networkNamespace: openshift-sriov-network-operator
      resourceName: du_fh
      vlan: 140 
    ---
    apiVersion: sriovnetwork.openshift.io/v1
    kind: SriovNetworkNodePolicy
    metadata:
      name: sriov-nnp-du-fh
      namespace: openshift-sriov-network-operator
    spec:
      deviceType: netdevice 
      isRdma: true
      nicSelector:
        pfNames:
          - ens5f0 
      nodeSelector:
        node-role.kubernetes.io/master: ""
      numVfs: 8 
      priority: 10
      resourceName: du_fh
    ```

<!-- -->

-   Specifies the VLAN for the midhaul network.

-   Select either `vfio-pci` or `netdevice`, as needed.

-   Specifies the interface connected to the midhaul network.

-   Specifies the number of VFs for the midhaul network.

-   The VLAN for the fronthaul network.

-   Select either `vfio-pci` or `netdevice`, as needed.

-   Specifies the interface connected to the fronthaul network.

-   Specifies the number of VFs for the fronthaul network.

### Disabling the console Operator

The console-operator installs and maintains the web console on a cluster. When the node is centrally managed the Operator is not needed and makes space for application workloads.

-   You can disable the Operator using the following configuration file. No configuration changes are needed. Use the provided settings:

    ``` yaml
    apiVersion: operator.openshift.io/v1
    kind: Console
    metadata:
      annotations:
        include.release.openshift.io/ibm-cloud-managed: "false"
        include.release.openshift.io/self-managed-high-availability: "false"
        include.release.openshift.io/single-node-developer: "false"
        release.openshift.io/create-only: "true"
      name: cluster
    spec:
      logLevel: Normal
      managementState: Removed
      operatorLogLevel: Normal
    ```

## Applying the distributed unit (DU) configuration to a single-node OpenShift cluster

Perform the following tasks to configure a single-node cluster for a DU:

-   Apply the required extra installation manifests at installation time.

-   Apply the post-install configuration custom resources (CRs).

### Applying the extra installation manifests

To apply the distributed unit (DU) configuration to the single-node cluster, the following extra installation manifests need to be included during installation:

-   Enable workload partitioning.

-   Other `MachineConfig` objects – There is a set of `MachineConfig` custom resources (CRs) included by default. You can choose to include these additional `MachineConfig` CRs that are unique to their environment. It is recommended, but not required, to apply these CRs during installation in order to minimize the number of reboots that can occur during post-install configuration.

### Applying the post-install configuration custom resources (CRs)

-   After OpenShift Container Platform is installed on the cluster, use the following command to apply the CRs you configured for the distributed units (DUs):

``` terminal
$ oc apply -f <file_name>.yaml
```
