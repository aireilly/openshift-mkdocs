# Improving cluster stability in high latency environments using worker latency profiles

All nodes send heartbeats to the Kubernetes Controller Manager Operator (kube controller) in the OpenShift Container Platform cluster every 10 seconds, by default. If the cluster does not receive heartbeats from a node, OpenShift Container Platform responds using several default mechanisms.

For example, if the Kubernetes Controller Manager Operator loses contact with a node after a configured period:

1.  The node controller on the control plane updates the node health to `Unhealthy` and marks the node `Ready` condition as `Unknown`.

2.  In response, the scheduler stops scheduling pods to that node.

3.  The on-premise node controller adds a `node.kubernetes.io/unreachable` taint with a `NoExecute` effect to the node and schedules any pods on the node for eviction after five minutes, by default.

This behavior can cause problems if your network is prone to latency issues, especially if you have nodes at the network edge. In some cases, the Kubernetes Controller Manager Operator might not receive an update from a healthy node due to network latency. The Kubernetes Controller Manager Operator would then evict pods from the node even though the node is healthy. To avoid this problem, you can use *worker latency profiles* to adjust the frequency that the kubelet and the Kubernetes Controller Manager Operator wait for status updates before taking action. These adjustments help to ensure that your cluster runs properly in the event that network latency between the control plane and the worker nodes is not optimal.

These worker latency profiles are three sets of parameters that are pre-defined with carefully tuned values that let you control the reaction of the cluster to latency issues without needing to determine the best values manually.

These worker latency profiles are three sets of parameters that are pre-defined with carefully tuned values that control the reaction of the cluster to latency issues without your needing to determine the best values manually.

You can configure worker latency profiles when installing a cluster or at any time you notice increased latency in your cluster network.

## Understanding worker latency profiles {#nodes-cluster-worker-latency-profiles-about_scaling-worker-latency-profiles}

Worker latency profiles are multiple sets of carefully-tuned values for the `node-status-update-frequency`, `node-monitor-grace-period`, `default-not-ready-toleration-seconds` and `default-unreachable-toleration-seconds` parameters. These parameters let you control the reaction of the cluster to latency issues without needing to determine the best values manually.

All worker latency profiles configure the following parameters:

-   `node-status-update-frequency`. Specifies the amount of time in seconds that a kubelet updates its status to the Kubernetes Controller Manager Operator.

-   `node-monitor-grace-period`. Specifies the amount of time in seconds that the Kubernetes Controller Manager Operator waits for an update from a kubelet before marking the node unhealthy and adding the `node.kubernetes.io/not-ready` or `node.kubernetes.io/unreachable` taint to the node.

-   `default-not-ready-toleration-seconds`. Specifies the amount of time in seconds after marking a node unhealthy that the Kubernetes Controller Manager Operator waits before evicting pods from that node.

-   `default-unreachable-toleration-seconds`. Specifies the amount of time in seconds after marking a node unreachable that the Kubernetes Controller Manager Operator waits before evicting pods from that node.

!!! important
    Manually modifying the `node-monitor-grace-period` parameter is not supported.

While the default configuration works in most cases, OpenShift Container Platform offers two other worker latency profiles for situations where the network is experiencing higher latency than usual. The three worker latency profiles are described in the following sections:

Default worker latency profile

:   With the `Default` profile, each kubelet reports its node status to the Kubelet Controller Manager Operator (kube controller) every 10 seconds. The Kubelet Controller Manager Operator checks the kubelet for a status every 5 seconds.

    The Kubernetes Controller Manager Operator waits 40 seconds for a status update before considering that node unhealthy. It marks the node with the `node.kubernetes.io/not-ready` or `node.kubernetes.io/unreachable` taint and evicts the pods on that node. If a pod on that node has the `NoExecute` toleration, the pod gets evicted in 300 seconds. If the pod has the `tolerationSeconds` parameter, the eviction waits for the period specified by that parameter.

    +----------------------------+------------------------------------------+--------------------------------+-----------+
    | Profile                    | Component                                | Parameter                      | Value     |
    +============================+==========================================+================================+===========+
    | Default                    | kubelet                                  | `node-status-update-frequency` | 10s       |
    +----------------------------+------------------------------------------+--------------------------------+-----------+
    | Kubelet Controller Manager | `node-monitor-grace-period`              | 40s                            |           |
    +----------------------------+------------------------------------------+--------------------------------+-----------+
    | Kubernetes API Server      | `default-not-ready-toleration-seconds`   | 300s                           |           |
    +----------------------------+------------------------------------------+--------------------------------+-----------+
    | Kubernetes API Server      | `default-unreachable-toleration-seconds` | 300s                           |           |
    +----------------------------+------------------------------------------+--------------------------------+-----------+

    : **Table 1**

Medium worker latency profile

:   Use the `MediumUpdateAverageReaction` profile if the network latency is slightly higher than usual.

    The `MediumUpdateAverageReaction` profile reduces the frequency of kubelet updates to 20 seconds and changes the period that the Kubernetes Controller Manager Operator waits for those updates to 2 minutes. The pod eviction period for a pod on that node is reduced to 60 seconds. If the pod has the `tolerationSeconds` parameter, the eviction waits for the period specified by that parameter.

    The Kubernetes Controller Manager Operator waits for 2 minutes to consider a node unhealthy. In another minute, the eviction process starts.

    +-----------------------------+------------------------------------------+--------------------------------+-----------+
    | Profile                     | Component                                | Parameter                      | Value     |
    +=============================+==========================================+================================+===========+
    | MediumUpdateAverageReaction | kubelet                                  | `node-status-update-frequency` | 20s       |
    +-----------------------------+------------------------------------------+--------------------------------+-----------+
    | Kubelet Controller Manager  | `node-monitor-grace-period`              | 2m                             |           |
    +-----------------------------+------------------------------------------+--------------------------------+-----------+
    | Kubernetes API Server       | `default-not-ready-toleration-seconds`   | 60s                            |           |
    +-----------------------------+------------------------------------------+--------------------------------+-----------+
    | Kubernetes API Server       | `default-unreachable-toleration-seconds` | 60s                            |           |
    +-----------------------------+------------------------------------------+--------------------------------+-----------+

    : **Table 2**

Low worker latency profile

:   Use the `LowUpdateSlowReaction` profile if the network latency is extremely high.

    The `LowUpdateSlowReaction` profile reduces the frequency of kubelet updates to 1 minute and changes the period that the Kubernetes Controller Manager Operator waits for those updates to 5 minutes. The pod eviction period for a pod on that node is reduced to 60 seconds. If the pod has the `tolerationSeconds` parameter, the eviction waits for the period specified by that parameter.

    The Kubernetes Controller Manager Operator waits for 5 minutes to consider a node unhealthy. In another minute, the eviction process starts.

    +----------------------------+------------------------------------------+--------------------------------+-----------+
    | Profile                    | Component                                | Parameter                      | Value     |
    +============================+==========================================+================================+===========+
    | LowUpdateSlowReaction      | kubelet                                  | `node-status-update-frequency` | 1m        |
    +----------------------------+------------------------------------------+--------------------------------+-----------+
    | Kubelet Controller Manager | `node-monitor-grace-period`              | 5m                             |           |
    +----------------------------+------------------------------------------+--------------------------------+-----------+
    | Kubernetes API Server      | `default-not-ready-toleration-seconds`   | 60s                            |           |
    +----------------------------+------------------------------------------+--------------------------------+-----------+
    | Kubernetes API Server      | `default-unreachable-toleration-seconds` | 60s                            |           |
    +----------------------------+------------------------------------------+--------------------------------+-----------+

    : **Table 3**

## Using worker latency profiles {#nodes-cluster-worker-latency-profiles-using_scaling-worker-latency-profiles}

To implement a worker latency profile to deal with network latency, edit the `node.config` object to add the name of the profile. You can change the profile at any time as latency increases or decreases.

You must move one worker latency profile at a time. For example, you cannot move directly from the `Default` profile to the `LowUpdateSlowReaction` worker latency profile. You must move from the `default` worker latency profile to the `MediumUpdateAverageReaction` profile first, then to `LowUpdateSlowReaction`. Similarly, when returning to the default profile, you must move from the low profile to the medium profile first, then to the default.

!!! note
    You can also configure worker latency profiles upon installing an OpenShift Container Platform cluster.

**Procedure**

To move from the default worker latency profile:

1.  Move to the medium worker latency profile:

    1.  Edit the `node.config` object:

        ``` terminal
        $ oc edit nodes.config/cluster
        ```

    2.  Add `spec.workerLatencyProfile: MediumUpdateAverageReaction`:

        **Example `node.config` object**

        ``` yaml
        apiVersion: config.openshift.io/v1
        kind: Node
        metadata:
          annotations:
            include.release.openshift.io/ibm-cloud-managed: "true"
            include.release.openshift.io/self-managed-high-availability: "true"
            include.release.openshift.io/single-node-developer: "true"
            release.openshift.io/create-only: "true"
          creationTimestamp: "2022-07-08T16:02:51Z"
          generation: 1
          name: cluster
          ownerReferences:
          - apiVersion: config.openshift.io/v1
            kind: ClusterVersion
            name: version
            uid: 36282574-bf9f-409e-a6cd-3032939293eb
          resourceVersion: "1865"
          uid: 0c0f7a4c-4307-4187-b591-6155695ac85b
        spec:
          workerLatencyProfile: MediumUpdateAverageReaction 

         ...
        ```

        -   Specifies the medium worker latency policy.

        Scheduling on each worker node is disabled as the change is being applied.

        When all nodes return to the `Ready` condition, you can use the following command to look in the Kubernetes Controller Manager to ensure it was applied:

        ``` terminal
        $ oc get KubeControllerManager -o yaml | grep -i workerlatency -A 5 -B 5
        ```

        **Example output**

        ``` terminal
         ...
            - lastTransitionTime: "2022-07-11T19:47:10Z"
              reason: ProfileUpdated
              status: "False"
              type: WorkerLatencyProfileProgressing
            - lastTransitionTime: "2022-07-11T19:47:10Z" 
              message: all static pod revision(s) have updated latency profile
              reason: ProfileUpdated
              status: "True"
              type: WorkerLatencyProfileComplete
            - lastTransitionTime: "2022-07-11T19:20:11Z"
              reason: AsExpected
              status: "False"
              type: WorkerLatencyProfileDegraded
            - lastTransitionTime: "2022-07-11T19:20:36Z"
              status: "False"
         ...
        ```

        -   Specifies that the profile is applied and active.

2.  Optional: Move to the low worker latency profile:

    1.  Edit the `node.config` object:

        ``` terminal
        $ oc edit nodes.config/cluster
        ```

    2.  Change the `spec.workerLatencyProfile` value to `LowUpdateSlowReaction`:

        **Example `node.config` object**

        ``` yaml
        apiVersion: config.openshift.io/v1
        kind: Node
        metadata:
          annotations:
            include.release.openshift.io/ibm-cloud-managed: "true"
            include.release.openshift.io/self-managed-high-availability: "true"
            include.release.openshift.io/single-node-developer: "true"
            release.openshift.io/create-only: "true"
          creationTimestamp: "2022-07-08T16:02:51Z"
          generation: 1
          name: cluster
          ownerReferences:
          - apiVersion: config.openshift.io/v1
            kind: ClusterVersion
            name: version
            uid: 36282574-bf9f-409e-a6cd-3032939293eb
          resourceVersion: "1865"
          uid: 0c0f7a4c-4307-4187-b591-6155695ac85b
        spec:
          workerLatencyProfile: LowUpdateSlowReaction 

         ...
        ```

        -   Specifies to use the low worker latency policy.

        Scheduling on each worker node is disabled as the change is being applied.

To change the low profile to medium or change the medium to low, edit the `node.config` object and set the `spec.workerLatencyProfile` parameter to the appropriate value.
