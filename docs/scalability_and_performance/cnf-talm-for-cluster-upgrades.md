# Topology Aware Lifecycle Manager for cluster updates

You can use the Topology Aware Lifecycle Manager (TALM) to manage the software lifecycle of multiple single-node OpenShift clusters. TALM uses Red Hat Advanced Cluster Management (RHACM) policies to perform changes on the target clusters.

!!! important
    Topology Aware Lifecycle Manager is a Technology Preview feature only. Technology Preview features are not supported with Red Hat production service level agreements (SLAs) and might not be functionally complete. Red Hat does not recommend using them in production. These features provide early access to upcoming product features, enabling customers to test functionality and provide feedback during the development process.
    
    For more information about the support scope of Red Hat Technology Preview features, see <https://access.redhat.com/support/offerings/techpreview/>.

## About the Topology Aware Lifecycle Manager configuration {#cnf-about-topology-aware-lifecycle-manager-config_cnf-topology-aware-lifecycle-manager}

The Topology Aware Lifecycle Manager (TALM) manages the deployment of Red Hat Advanced Cluster Management (RHACM) policies for one or more OpenShift Container Platform clusters. Using TALM in a large network of clusters allows the phased rollout of policies to the clusters in limited batches. This helps to minimize possible service disruptions when updating. With TALM, you can control the following actions:

-   The timing of the update

-   The number of RHACM-managed clusters

-   The subset of managed clusters to apply the policies to

-   The update order of the clusters

-   The set of policies remediated to the cluster

-   The order of policies remediated to the cluster

TALM supports the orchestration of the OpenShift Container Platform y-stream and z-stream updates, and day-two operations on y-streams and z-streams.

## About managed policies used with Topology Aware Lifecycle Manager {#cnf-about-topology-aware-lifecycle-manager-about-policies_cnf-topology-aware-lifecycle-manager}

The Topology Aware Lifecycle Manager (TALM) uses RHACM policies for cluster updates.

TALM can be used to manage the rollout of any policy CR where the `remediationAction` field is set to `inform`. Supported use cases include the following:

-   Manual user creation of policy CRs

-   Automatically generated policies from the `PolicyGenTemplate` custom resource definition (CRD)

For policies that update an Operator subscription with manual approval, TALM provides additional functionality that approves the installation of the updated Operator.

For more information about managed policies, see [Policy Overview](https://access.redhat.com/documentation/en-us/red_hat_advanced_cluster_management_for_kubernetes/2.4/html-single/governance/index#policy-overview) in the RHACM documentation.

For more information about the `PolicyGenTemplate` CRD, see the "About the PolicyGenTemplate" section in "Deploying distributed units at scale in a disconnected environment".

## Installing the Topology Aware Lifecycle Manager by using the web console {#installing-topology-aware-lifecycle-manager-using-web-console_cnf-topology-aware-lifecycle-manager}

You can use the OpenShift Container Platform web console to install the Topology Aware Lifecycle Manager.

**Prerequisites**

-   Install the latest version of the RHACM Operator.

-   Set up a hub cluster with disconnected regitry.

-   Log in as a user with `cluster-admin` privileges.

**Procedure**

1.  In the OpenShift Container Platform web console, navigate to **Operators** → **OperatorHub**.

2.  Search for the **Topology Aware Lifecycle Manager** from the list of available Operators, and then click **Install**.

3.  Keep the default selection of **Installation mode** \["All namespaces on the cluster (default)"\] and **Installed Namespace** ("openshift-operators") to ensure that the Operator is installed properly.

4.  Click **Install**.

**Verification**

To confirm that the installation is successful:

1.  Navigate to the **Operators** → **Installed Operators** page.

2.  Check that the Operator is installed in the `All Namespaces` namespace and its status is `Succeeded`.

If the Operator is not installed successfully:

1.  Navigate to the **Operators** → **Installed Operators** page and inspect the `Status` column for any errors or failures.

2.  Navigate to the **Workloads** → **Pods** page and check the logs in any containers in the `cluster-group-upgrades-controller-manager` pod that are reporting issues.

## Installing the Topology Aware Lifecycle Manager by using the CLI {#installing-topology-aware-lifecycle-manager-using-cli_cnf-topology-aware-lifecycle-manager}

You can use the OpenShift CLI (`oc`) to install the Topology Aware Lifecycle Manager (TALM).

**Prerequisites**

-   Install the OpenShift CLI (`oc`).

-   Install the latest version of the RHACM Operator.

-   Set up a hub cluster with disconnected registry.

-   Log in as a user with `cluster-admin` privileges.

**Procedure**

1.  Create a `Subscription` CR:

    1.  Define the `Subscription` CR and save the YAML file, for example, `talm-subscription.yaml`:

        ``` yaml
        apiVersion: operators.coreos.com/v1alpha1
        kind: Subscription
        metadata:
          name: openshift-topology-aware-lifecycle-manager-subscription
          namespace: openshift-operators
        spec:
          channel: "stable"
          name: topology-aware-lifecycle-manager
          source: redhat-operators
          sourceNamespace: openshift-marketplace
        ```

    2.  Create the `Subscription` CR by running the following command:

        ``` terminal
        $ oc create -f talm-subscription.yaml
        ```

<!-- -->

1.  Verify that the installation succeeded by inspecting the CSV resource:

    ``` terminal
    $ oc get csv -n openshift-operators
    ```

    **Example output**

    ``` terminal
    NAME                                                   DISPLAY                            VERSION               REPLACES                           PHASE
    topology-aware-lifecycle-manager.4.11.x   Topology Aware Lifecycle Manager   4.11.x                                      Succeeded
    ```

2.  Verify that the TALM is up and running:

    ``` terminal
    $ oc get deploy -n openshift-operators
    ```

    **Example output**

    ``` terminal
    NAMESPACE                                          NAME                                             READY   UP-TO-DATE   AVAILABLE   AGE
    openshift-operators                                cluster-group-upgrades-controller-manager        1/1     1            1           14s
    ```

## About the ClusterGroupUpgrade CR {#talo-about-cgu-crs_cnf-topology-aware-lifecycle-manager}

The Topology Aware Lifecycle Manager (TALM) builds the remediation plan from the `ClusterGroupUpgrade` CR for a group of clusters. You can define the following specifications in a `ClusterGroupUpgrade` CR:

-   Clusters in the group

-   Blocking `ClusterGroupUpgrade` CRs

-   Applicable list of managed policies

-   Number of concurrent updates

-   Applicable canary updates

-   Actions to perform before and after the update

-   Update timing

As TALM works through remediation of the policies to the specified clusters, the `ClusterGroupUpgrade` CR can have the following states:

-   `UpgradeNotStarted`

-   `UpgradeCannotStart`

-   `UpgradeNotComplete`

-   `UpgradeTimedOut`

-   `UpgradeCompleted`

-   `PrecachingRequired`

!!! note
    After TALM completes a cluster update, the cluster does not update again under the control of the same `ClusterGroupUpgrade` CR. You must create a new `ClusterGroupUpgrade` CR in the following cases:
    
    -   When you need to update the cluster again
    
    -   When the cluster changes to non-compliant with the `inform` policy after being updated

### The UpgradeNotStarted state {#upgrade_not_started}

The initial state of the `ClusterGroupUpgrade` CR is `UpgradeNotStarted`.

TALM builds a remediation plan based on the following fields:

-   The `clusterSelector` field specifies the labels of the clusters that you want to update.

-   The `clusters` field specifies a list of clusters to update.

-   The `canaries` field specifies the clusters for canary updates.

-   The `maxConcurrency` field specifies the number of clusters to update in a batch.

You can use the `clusters` and the `clusterSelector` fields together to create a combined list of clusters.

The remediation plan starts with the clusters listed in the `canaries` field. Each canary cluster forms a single-cluster batch.

!!! note
    Any failures during the update of a canary cluster stops the update process.

The `ClusterGroupUpgrade` CR transitions to the `UpgradeNotCompleted` state after the remediation plan is successfully created and after the `enable` field is set to `true`. At this point, TALM starts to update the non-compliant clusters with the specified managed policies.

!!! note
    You can only make changes to the `spec` fields if the `ClusterGroupUpgrade` CR is either in the `UpgradeNotStarted` or the `UpgradeCannotStart` state.

**Sample `ClusterGroupUpgrade` CR in the `UpgradeNotStarted` state**

``` yaml
apiVersion: ran.openshift.io/v1alpha1
kind: ClusterGroupUpgrade
metadata:
  name: cgu-upgrade-complete
  namespace: default
spec:
  clusters: 
  - spoke1
  enable: false
  managedPolicies: 
  - policy1-common-cluster-version-policy
  - policy2-common-nto-sub-policy
  remediationStrategy: 
    canaries: 
      - spoke1
    maxConcurrency: 1 
    timeout: 240
status: 
  conditions:
  - message: The ClusterGroupUpgrade CR is not enabled
    reason: UpgradeNotStarted
    status: "False"
    type: Ready
  copiedPolicies:
  - cgu-upgrade-complete-policy1-common-cluster-version-policy
  - cgu-upgrade-complete-policy2-common-nto-sub-policy
  managedPoliciesForUpgrade:
  - name: policy1-common-cluster-version-policy
    namespace: default
  - name: policy2-common-nto-sub-policy
    namespace: default
  placementBindings:
  - cgu-upgrade-complete-policy1-common-cluster-version-policy
  - cgu-upgrade-complete-policy2-common-nto-sub-policy
  placementRules:
  - cgu-upgrade-complete-policy1-common-cluster-version-policy
  - cgu-upgrade-complete-policy2-common-nto-sub-policy
  remediationPlan:
  - - spoke1
```

-   Defines the list of clusters to update.

-   Lists the user-defined set of policies to remediate.

-   Defines the specifics of the cluster updates.

-   Defines the clusters for canary updates.

-   Defines the maximum number of concurrent updates in a batch. The number of remediation batches is the number of canary clusters, plus the number of clusters, except the canary clusters, divided by the `maxConcurrency` value. The clusters that are already compliant with all the managed policies are excluded from the remediation plan.

-   Displays information about the status of the updates.

### The UpgradeCannotStart state {#upgrade_cannot_start}

In the `UpgradeCannotStart` state, the update cannot start because of the following reasons:

-   Blocking CRs are missing from the system

-   Blocking CRs have not yet finished

### The UpgradeNotCompleted state {#upgrade_not_completed}

In the `UpgradeNotCompleted` state, TALM enforces the policies following the remediation plan defined in the `UpgradeNotStarted` state.

Enforcing the policies for subsequent batches starts immediately after all the clusters of the current batch are compliant with all the managed policies. If the batch times out, TALM moves on to the next batch. The timeout value of a batch is the `spec.timeout` field divided by the number of batches in the remediation plan.

!!! note
    The managed policies apply in the order that they are listed in the `managedPolicies` field in the `ClusterGroupUpgrade` CR. One managed policy is applied to the specified clusters at a time. After the specified clusters comply with the current policy, the next managed policy is applied to the next non-compliant cluster.

**Sample `ClusterGroupUpgrade` CR in the `UpgradeNotCompleted` state**

``` yaml
apiVersion: ran.openshift.io/v1alpha1
kind: ClusterGroupUpgrade
metadata:
  name: cgu-upgrade-complete
  namespace: default
spec:
  clusters:
  - spoke1
  enable: true 
  managedPolicies:
  - policy1-common-cluster-version-policy
  - policy2-common-nto-sub-policy
  remediationStrategy:
    maxConcurrency: 1
    timeout: 240
status: 
  conditions:
  - message: The ClusterGroupUpgrade CR has upgrade policies that are still non compliant
    reason: UpgradeNotCompleted
    status: "False"
    type: Ready
  copiedPolicies:
  - cgu-upgrade-complete-policy1-common-cluster-version-policy
  - cgu-upgrade-complete-policy2-common-nto-sub-policy
  managedPoliciesForUpgrade:
  - name: policy1-common-cluster-version-policy
    namespace: default
  - name: policy2-common-nto-sub-policy
    namespace: default
  placementBindings:
  - cgu-upgrade-complete-policy1-common-cluster-version-policy
  - cgu-upgrade-complete-policy2-common-nto-sub-policy
  placementRules:
  - cgu-upgrade-complete-policy1-common-cluster-version-policy
  - cgu-upgrade-complete-policy2-common-nto-sub-policy
  remediationPlan:
  - - spoke1
  status:
    currentBatch: 1
    remediationPlanForBatch: 
      spoke1: 0
```

-   The update starts when the value of the `spec.enable` field is `true`.

-   The `status` fields change accordingly when the update begins.

-   Lists the clusters in the batch and the index of the policy that is being currently applied to each cluster. The index of the policies starts with `0` and the index follows the order of the `status.managedPoliciesForUpgrade` list.

### The UpgradeTimedOut state {#upgrade_timed_out}

In the `UpgradeTimedOut` state, TALM checks every hour if all the policies for the `ClusterGroupUpgrade` CR are compliant. The checks continue until the `ClusterGroupUpgrade` CR is deleted or the updates are completed. The periodic checks allow the updates to complete if they get prolonged due to network, CPU, or other issues.

TALM transitions to the `UpgradeTimedOut` state in two cases:

-   When the current batch contains canary updates and the cluster in the batch does not comply with all the managed policies within the batch timeout.

-   When the clusters do not comply with the managed policies within the `timeout` value specified in the `remediationStrategy` field.

If the policies are compliant, TALM transitions to the `UpgradeCompleted` state.

### The UpgradeCompleted state {#upgrade_completed}

In the `UpgradeCompleted` state, the cluster updates are complete.

**Sample `ClusterGroupUpgrade` CR in the `UpgradeCompleted` state**

``` yaml
apiVersion: ran.openshift.io/v1alpha1
kind: ClusterGroupUpgrade
metadata:
  name: cgu-upgrade-complete
  namespace: default
spec:
  actions:
    afterCompletion:
      deleteObjects: true 
  clusters:
  - spoke1
  enable: true
  managedPolicies:
  - policy1-common-cluster-version-policy
  - policy2-common-nto-sub-policy
  remediationStrategy:
    maxConcurrency: 1
    timeout: 240
status: 
  conditions:
  - message: The ClusterGroupUpgrade CR has all clusters compliant with all the managed policies
    reason: UpgradeCompleted
    status: "True"
    type: Ready
  managedPoliciesForUpgrade:
  - name: policy1-common-cluster-version-policy
    namespace: default
  - name: policy2-common-nto-sub-policy
    namespace: default
  remediationPlan:
  - - spoke1
  status:
    remediationPlanForBatch:
      spoke1: -2 
```

-   The value of `spec.action.afterCompletion.deleteObjects` field is `true` by default. After the update is completed, TALM deletes the underlying RHACM objects that were created during the update. This option is to prevent the RHACM hub from continuously checking for compliance after a successful update.

-   The `status` fields show that the updates completed successfully.

-   Displays that all the policies are applied to the cluster.

In the `PrecachingRequired` state, the clusters need to have images pre-cached before the update can start. For more information about pre-caching, see the "Using the container image pre-cache feature" section.

### Blocking ClusterGroupUpgrade CRs {#cnf-about-topology-aware-lifecycle-manager-blocking-crs_cnf-topology-aware-lifecycle-manager}

You can create multiple `ClusterGroupUpgrade` CRs and control their order of application.

For example, if you create `ClusterGroupUpgrade` CR C that blocks the start of `ClusterGroupUpgrade` CR A, then `ClusterGroupUpgrade` CR A cannot start until the status of `ClusterGroupUpgrade` CR C becomes `UpgradeComplete`.

One `ClusterGroupUpgrade` CR can have multiple blocking CRs. In this case, all the blocking CRs must complete before the upgrade for the current CR can start.

**Prerequisites**

-   Install the Topology Aware Lifecycle Manager (TALM).

-   Provision one or more managed clusters.

-   Log in as a user with `cluster-admin` privileges.

-   Create RHACM policies in the hub cluster.

**Procedure**

1.  Save the content of the `ClusterGroupUpgrade` CRs in the `cgu-a.yaml`, `cgu-b.yaml`, and `cgu-c.yaml` files.

    ``` yaml
    apiVersion: ran.openshift.io/v1alpha1
    kind: ClusterGroupUpgrade
    metadata:
      name: cgu-a
      namespace: default
    spec:
      blockingCRs: 
      - name: cgu-c
        namespace: default
      clusters:
      - spoke1
      - spoke2
      - spoke3
      enable: false
      managedPolicies:
      - policy1-common-cluster-version-policy
      - policy2-common-pao-sub-policy
      - policy3-common-ptp-sub-policy
      remediationStrategy:
        canaries:
        - spoke1
        maxConcurrency: 2
        timeout: 240
    status:
      conditions:
      - message: The ClusterGroupUpgrade CR is not enabled
        reason: UpgradeNotStarted
        status: "False"
        type: Ready
      copiedPolicies:
      - cgu-a-policy1-common-cluster-version-policy
      - cgu-a-policy2-common-pao-sub-policy
      - cgu-a-policy3-common-ptp-sub-policy
      managedPoliciesForUpgrade:
      - name: policy1-common-cluster-version-policy
        namespace: default
      - name: policy2-common-pao-sub-policy
        namespace: default
      - name: policy3-common-ptp-sub-policy
        namespace: default
      placementBindings:
      - cgu-a-policy1-common-cluster-version-policy
      - cgu-a-policy2-common-pao-sub-policy
      - cgu-a-policy3-common-ptp-sub-policy
      placementRules:
      - cgu-a-policy1-common-cluster-version-policy
      - cgu-a-policy2-common-pao-sub-policy
      - cgu-a-policy3-common-ptp-sub-policy
      remediationPlan:
      - - spoke1
      - - spoke2
    ```

    -   Defines the blocking CRs. The `cgu-a` update cannot start until `cgu-c` is complete.

    ``` yaml
    apiVersion: ran.openshift.io/v1alpha1
    kind: ClusterGroupUpgrade
    metadata:
      name: cgu-b
      namespace: default
    spec:
      blockingCRs: 
      - name: cgu-a
        namespace: default
      clusters:
      - spoke4
      - spoke5
      enable: false
      managedPolicies:
      - policy1-common-cluster-version-policy
      - policy2-common-pao-sub-policy
      - policy3-common-ptp-sub-policy
      - policy4-common-sriov-sub-policy
      remediationStrategy:
        maxConcurrency: 1
        timeout: 240
    status:
      conditions:
      - message: The ClusterGroupUpgrade CR is not enabled
        reason: UpgradeNotStarted
        status: "False"
        type: Ready
      copiedPolicies:
      - cgu-b-policy1-common-cluster-version-policy
      - cgu-b-policy2-common-pao-sub-policy
      - cgu-b-policy3-common-ptp-sub-policy
      - cgu-b-policy4-common-sriov-sub-policy
      managedPoliciesForUpgrade:
      - name: policy1-common-cluster-version-policy
        namespace: default
      - name: policy2-common-pao-sub-policy
        namespace: default
      - name: policy3-common-ptp-sub-policy
        namespace: default
      - name: policy4-common-sriov-sub-policy
        namespace: default
      placementBindings:
      - cgu-b-policy1-common-cluster-version-policy
      - cgu-b-policy2-common-pao-sub-policy
      - cgu-b-policy3-common-ptp-sub-policy
      - cgu-b-policy4-common-sriov-sub-policy
      placementRules:
      - cgu-b-policy1-common-cluster-version-policy
      - cgu-b-policy2-common-pao-sub-policy
      - cgu-b-policy3-common-ptp-sub-policy
      - cgu-b-policy4-common-sriov-sub-policy
      remediationPlan:
      - - spoke4
      - - spoke5
      status: {}
    ```

    -   The `cgu-b` update cannot start until `cgu-a` is complete.

    ``` yaml
    apiVersion: ran.openshift.io/v1alpha1
    kind: ClusterGroupUpgrade
    metadata:
      name: cgu-c
      namespace: default
    spec: 
      clusters:
      - spoke6
      enable: false
      managedPolicies:
      - policy1-common-cluster-version-policy
      - policy2-common-pao-sub-policy
      - policy3-common-ptp-sub-policy
      - policy4-common-sriov-sub-policy
      remediationStrategy:
        maxConcurrency: 1
        timeout: 240
    status:
      conditions:
      - message: The ClusterGroupUpgrade CR is not enabled
        reason: UpgradeNotStarted
        status: "False"
        type: Ready
      copiedPolicies:
      - cgu-c-policy1-common-cluster-version-policy
      - cgu-c-policy4-common-sriov-sub-policy
      managedPoliciesCompliantBeforeUpgrade:
      - policy2-common-pao-sub-policy
      - policy3-common-ptp-sub-policy
      managedPoliciesForUpgrade:
      - name: policy1-common-cluster-version-policy
        namespace: default
      - name: policy4-common-sriov-sub-policy
        namespace: default
      placementBindings:
      - cgu-c-policy1-common-cluster-version-policy
      - cgu-c-policy4-common-sriov-sub-policy
      placementRules:
      - cgu-c-policy1-common-cluster-version-policy
      - cgu-c-policy4-common-sriov-sub-policy
      remediationPlan:
      - - spoke6
      status: {}
    ```

    -   The `cgu-c` update does not have any blocking CRs. TALM starts the `cgu-c` update when the `enable` field is set to `true`.

2.  Create the `ClusterGroupUpgrade` CRs by running the following command for each relevant CR:

    ``` terminal
    $ oc apply -f <name>.yaml
    ```

3.  Start the update process by running the following command for each relevant CR:

    ``` terminal
    $ oc --namespace=default patch clustergroupupgrade.ran.openshift.io/<name> \
    --type merge -p '{"spec":{"enable":true}}'
    ```

    The following examples show `ClusterGroupUpgrade` CRs where the `enable` field is set to `true`:

    **Example for `cgu-a` with blocking CRs**

    ``` yaml
    apiVersion: ran.openshift.io/v1alpha1
    kind: ClusterGroupUpgrade
    metadata:
      name: cgu-a
      namespace: default
    spec:
      blockingCRs:
      - name: cgu-c
        namespace: default
      clusters:
      - spoke1
      - spoke2
      - spoke3
      enable: true
      managedPolicies:
      - policy1-common-cluster-version-policy
      - policy2-common-pao-sub-policy
      - policy3-common-ptp-sub-policy
      remediationStrategy:
        canaries:
        - spoke1
        maxConcurrency: 2
        timeout: 240
    status:
      conditions:
      - message: 'The ClusterGroupUpgrade CR is blocked by other CRs that have not yet
          completed: [cgu-c]' 
        reason: UpgradeCannotStart
        status: "False"
        type: Ready
      copiedPolicies:
      - cgu-a-policy1-common-cluster-version-policy
      - cgu-a-policy2-common-pao-sub-policy
      - cgu-a-policy3-common-ptp-sub-policy
      managedPoliciesForUpgrade:
      - name: policy1-common-cluster-version-policy
        namespace: default
      - name: policy2-common-pao-sub-policy
        namespace: default
      - name: policy3-common-ptp-sub-policy
        namespace: default
      placementBindings:
      - cgu-a-policy1-common-cluster-version-policy
      - cgu-a-policy2-common-pao-sub-policy
      - cgu-a-policy3-common-ptp-sub-policy
      placementRules:
      - cgu-a-policy1-common-cluster-version-policy
      - cgu-a-policy2-common-pao-sub-policy
      - cgu-a-policy3-common-ptp-sub-policy
      remediationPlan:
      - - spoke1
      - - spoke2
      status: {}
    ```

    -   Shows the list of blocking CRs.

    **Example for `cgu-b` with blocking CRs**

    ``` yaml
    apiVersion: ran.openshift.io/v1alpha1
    kind: ClusterGroupUpgrade
    metadata:
      name: cgu-b
      namespace: default
    spec:
      blockingCRs:
      - name: cgu-a
        namespace: default
      clusters:
      - spoke4
      - spoke5
      enable: true
      managedPolicies:
      - policy1-common-cluster-version-policy
      - policy2-common-pao-sub-policy
      - policy3-common-ptp-sub-policy
      - policy4-common-sriov-sub-policy
      remediationStrategy:
        maxConcurrency: 1
        timeout: 240
    status:
      conditions:
      - message: 'The ClusterGroupUpgrade CR is blocked by other CRs that have not yet
          completed: [cgu-a]' 
        reason: UpgradeCannotStart
        status: "False"
        type: Ready
      copiedPolicies:
      - cgu-b-policy1-common-cluster-version-policy
      - cgu-b-policy2-common-pao-sub-policy
      - cgu-b-policy3-common-ptp-sub-policy
      - cgu-b-policy4-common-sriov-sub-policy
      managedPoliciesForUpgrade:
      - name: policy1-common-cluster-version-policy
        namespace: default
      - name: policy2-common-pao-sub-policy
        namespace: default
      - name: policy3-common-ptp-sub-policy
        namespace: default
      - name: policy4-common-sriov-sub-policy
        namespace: default
      placementBindings:
      - cgu-b-policy1-common-cluster-version-policy
      - cgu-b-policy2-common-pao-sub-policy
      - cgu-b-policy3-common-ptp-sub-policy
      - cgu-b-policy4-common-sriov-sub-policy
      placementRules:
      - cgu-b-policy1-common-cluster-version-policy
      - cgu-b-policy2-common-pao-sub-policy
      - cgu-b-policy3-common-ptp-sub-policy
      - cgu-b-policy4-common-sriov-sub-policy
      remediationPlan:
      - - spoke4
      - - spoke5
      status: {}
    ```

    -   Shows the list of blocking CRs.

    **Example for `cgu-c` with blocking CRs**

    ``` yaml
    apiVersion: ran.openshift.io/v1alpha1
    kind: ClusterGroupUpgrade
    metadata:
      name: cgu-c
      namespace: default
    spec:
      clusters:
      - spoke6
      enable: true
      managedPolicies:
      - policy1-common-cluster-version-policy
      - policy2-common-pao-sub-policy
      - policy3-common-ptp-sub-policy
      - policy4-common-sriov-sub-policy
      remediationStrategy:
        maxConcurrency: 1
        timeout: 240
    status:
      conditions:
      - message: The ClusterGroupUpgrade CR has upgrade policies that are still non compliant 
        reason: UpgradeNotCompleted
        status: "False"
        type: Ready
      copiedPolicies:
      - cgu-c-policy1-common-cluster-version-policy
      - cgu-c-policy4-common-sriov-sub-policy
      managedPoliciesCompliantBeforeUpgrade:
      - policy2-common-pao-sub-policy
      - policy3-common-ptp-sub-policy
      managedPoliciesForUpgrade:
      - name: policy1-common-cluster-version-policy
        namespace: default
      - name: policy4-common-sriov-sub-policy
        namespace: default
      placementBindings:
      - cgu-c-policy1-common-cluster-version-policy
      - cgu-c-policy4-common-sriov-sub-policy
      placementRules:
      - cgu-c-policy1-common-cluster-version-policy
      - cgu-c-policy4-common-sriov-sub-policy
      remediationPlan:
      - - spoke6
      status:
        currentBatch: 1
        remediationPlanForBatch:
          spoke6: 0
    ```

    -   The `cgu-c` update does not have any blocking CRs.

## Update policies on managed clusters {#talo-policies-concept_cnf-topology-aware-lifecycle-manager}

The Topology Aware Lifecycle Manager (TALM) remediates a set of `inform` policies for the clusters specified in the `ClusterGroupUpgrade` CR. TALM remediates `inform` policies by making `enforce` copies of the managed RHACM policies. Each copied policy has its own corresponding RHACM placement rule and RHACM placement binding.

One by one, TALM adds each cluster from the current batch to the placement rule that corresponds with the applicable managed policy. If a cluster is already compliant with a policy, TALM skips applying that policy on the compliant cluster. TALM then moves on to applying the next policy to the non-compliant cluster. After TALM completes the updates in a batch, all clusters are removed from the placement rules associated with the copied policies. Then, the update of the next batch starts.

If a spoke cluster does not report any compliant state to RHACM, the managed policies on the hub cluster can be missing status information that TALM needs. TALM handles these cases in the following ways:

-   If a policy’s `status.compliant` field is missing, TALM ignores the policy and adds a log entry. Then, TALM continues looking at the policy’s `status.status` field.

-   If a policy’s `status.status` is missing, TALM produces an error.

-   If a cluster’s compliance status is missing in the policy’s `status.status` field, TALM considers that cluster to be non-compliant with that policy.

For more information about RHACM policies, see [Policy overview](https://access.redhat.com/documentation/en-us/red_hat_advanced_cluster_management_for_kubernetes/2.4/html-single/governance/index#policy-overview).

**Additional resources**

For more information about `PolicyGenTemplate` CRD, see [About the PolicyGenTemplate](../ztp-deploying-disconnected/#ztp-the-policygentemplate_ztp-deploying-disconnected).

### Applying update policies to managed clusters {#talo-apply-policies_cnf-topology-aware-lifecycle-manager}

You can update your managed clusters by applying your policies.

**Prerequisites**

-   Install the Topology Aware Lifecycle Manager (TALM).

-   Provision one or more managed clusters.

-   Log in as a user with `cluster-admin` privileges.

-   Create RHACM policies in the hub cluster.

**Procedure**

1.  Save the contents of the `ClusterGroupUpgrade` CR in the `cgu-1.yaml` file.

    ``` yaml
    apiVersion: ran.openshift.io/v1alpha1
    kind: ClusterGroupUpgrade
    metadata:
      name: cgu-1
      namespace: default
    spec:
      managedPolicies: 
        - policy1-common-cluster-version-policy
        - policy2-common-nto-sub-policy
        - policy3-common-ptp-sub-policy
        - policy4-common-sriov-sub-policy
      enable: false
      clusters: 
      - spoke1
      - spoke2
      - spoke5
      - spoke6
      remediationStrategy:
        maxConcurrency: 2 
        timeout: 240 
    ```

    -   The name of the policies to apply.

    -   The list of clusters to update.

    -   The `maxConcurrency` field signifies the number of clusters updated at the same time.

    -   The update timeout in minutes.

2.  Create the `ClusterGroupUpgrade` CR by running the following command:

    ``` terminal
    $ oc create -f cgu-1.yaml
    ```

    1.  Check if the `ClusterGroupUpgrade` CR was created in the hub cluster by running the following command:

        ``` terminal
        $ oc get cgu --all-namespaces
        ```

        **Example output**

        ``` terminal
        NAMESPACE   NAME      AGE
        default     cgu-1     8m55s
        ```

    2.  Check the status of the update by running the following command:

        ``` terminal
        $ oc get cgu -n default cgu-1 -ojsonpath='{.status}' | jq
        ```

        **Example output**

        ``` json
        {
          "computedMaxConcurrency": 2,
          "conditions": [
            {
              "lastTransitionTime": "2022-02-25T15:34:07Z",
              "message": "The ClusterGroupUpgrade CR is not enabled", 
              "reason": "UpgradeNotStarted",
              "status": "False",
              "type": "Ready"
            }
          ],
          "copiedPolicies": [
            "cgu-policy1-common-cluster-version-policy",
            "cgu-policy2-common-nto-sub-policy",
            "cgu-policy3-common-ptp-sub-policy",
            "cgu-policy4-common-sriov-sub-policy"
          ],
          "managedPoliciesContent": {
            "policy1-common-cluster-version-policy": "null",
            "policy2-common-nto-sub-policy": "[{\"kind\":\"Subscription\",\"name\":\"node-tuning-operator\",\"namespace\":\"openshift-cluster-node-tuning-operator\"}]",
            "policy3-common-ptp-sub-policy": "[{\"kind\":\"Subscription\",\"name\":\"ptp-operator-subscription\",\"namespace\":\"openshift-ptp\"}]",
            "policy4-common-sriov-sub-policy": "[{\"kind\":\"Subscription\",\"name\":\"sriov-network-operator-subscription\",\"namespace\":\"openshift-sriov-network-operator\"}]"
          },
          "managedPoliciesForUpgrade": [
            {
              "name": "policy1-common-cluster-version-policy",
              "namespace": "default"
            },
            {
              "name": "policy2-common-nto-sub-policy",
              "namespace": "default"
            },
            {
              "name": "policy3-common-ptp-sub-policy",
              "namespace": "default"
            },
            {
              "name": "policy4-common-sriov-sub-policy",
              "namespace": "default"
            }
          ],
          "managedPoliciesNs": {
            "policy1-common-cluster-version-policy": "default",
            "policy2-common-nto-sub-policy": "default",
            "policy3-common-ptp-sub-policy": "default",
            "policy4-common-sriov-sub-policy": "default"
          },
          "placementBindings": [
            "cgu-policy1-common-cluster-version-policy",
            "cgu-policy2-common-nto-sub-policy",
            "cgu-policy3-common-ptp-sub-policy",
            "cgu-policy4-common-sriov-sub-policy"
          ],
          "placementRules": [
            "cgu-policy1-common-cluster-version-policy",
            "cgu-policy2-common-nto-sub-policy",
            "cgu-policy3-common-ptp-sub-policy",
            "cgu-policy4-common-sriov-sub-policy"
          ],
          "precaching": {
            "spec": {}
          },
          "remediationPlan": [
            [
              "spoke1",
              "spoke2"
            ],
            [
              "spoke5",
              "spoke6"
            ]
          ],
          "status": {}
        }
        ```

        -   The `spec.enable` field in the `ClusterGroupUpgrade` CR is set to `false`.

    3.  Check the status of the policies by running the following command:

        ``` terminal
        $ oc get policies -A
        ```

        **Example output**

        ``` terminal
        NAMESPACE   NAME                                                 REMEDIATION ACTION   COMPLIANCE STATE   AGE
        default     cgu-policy1-common-cluster-version-policy            enforce                                 17m 
        default     cgu-policy2-common-nto-sub-policy                    enforce                                 17m
        default     cgu-policy3-common-ptp-sub-policy                    enforce                                 17m
        default     cgu-policy4-common-sriov-sub-policy                  enforce                                 17m
        default     policy1-common-cluster-version-policy                inform               NonCompliant       15h
        default     policy2-common-nto-sub-policy                        inform               NonCompliant       15h
        default     policy3-common-ptp-sub-policy                        inform               NonCompliant       18m
        default     policy4-common-sriov-sub-policy                      inform               NonCompliant       18m
        ```

        -   The `spec.remediationAction` field of policies currently applied on the clusters is set to `enforce`. The managed policies in `inform` mode from the `ClusterGroupUpgrade` CR remain in `inform` mode during the update.

3.  Change the value of the `spec.enable` field to `true` by running the following command:

    ``` terminal
    $ oc --namespace=default patch clustergroupupgrade.ran.openshift.io/cgu-1 \
    --patch '{"spec":{"enable":true}}' --type=merge
    ```

<!-- -->

1.  Check the status of the update again by running the following command:

    ``` terminal
    $ oc get cgu -n default cgu-1 -ojsonpath='{.status}' | jq
    ```

    **Example output**

    ``` json
    {
      "computedMaxConcurrency": 2,
      "conditions": [ 
        {
          "lastTransitionTime": "2022-02-25T15:34:07Z",
          "message": "The ClusterGroupUpgrade CR has upgrade policies that are still non compliant",
          "reason": "UpgradeNotCompleted",
          "status": "False",
          "type": "Ready"
        }
      ],
      "copiedPolicies": [
        "cgu-policy1-common-cluster-version-policy",
        "cgu-policy2-common-nto-sub-policy",
        "cgu-policy3-common-ptp-sub-policy",
        "cgu-policy4-common-sriov-sub-policy"
      ],
      "managedPoliciesContent": {
        "policy1-common-cluster-version-policy": "null",
        "policy2-common-nto-sub-policy": "[{\"kind\":\"Subscription\",\"name\":\"node-tuning-operator\",\"namespace\":\"openshift-cluster-node-tuning-operator\"}]",
        "policy3-common-ptp-sub-policy": "[{\"kind\":\"Subscription\",\"name\":\"ptp-operator-subscription\",\"namespace\":\"openshift-ptp\"}]",
        "policy4-common-sriov-sub-policy": "[{\"kind\":\"Subscription\",\"name\":\"sriov-network-operator-subscription\",\"namespace\":\"openshift-sriov-network-operator\"}]"
      },
      "managedPoliciesForUpgrade": [
        {
          "name": "policy1-common-cluster-version-policy",
          "namespace": "default"
        },
        {
          "name": "policy2-common-nto-sub-policy",
          "namespace": "default"
        },
        {
          "name": "policy3-common-ptp-sub-policy",
          "namespace": "default"
        },
        {
          "name": "policy4-common-sriov-sub-policy",
          "namespace": "default"
        }
      ],
      "managedPoliciesNs": {
        "policy1-common-cluster-version-policy": "default",
        "policy2-common-nto-sub-policy": "default",
        "policy3-common-ptp-sub-policy": "default",
        "policy4-common-sriov-sub-policy": "default"
      },
      "placementBindings": [
        "cgu-policy1-common-cluster-version-policy",
        "cgu-policy2-common-nto-sub-policy",
        "cgu-policy3-common-ptp-sub-policy",
        "cgu-policy4-common-sriov-sub-policy"
      ],
      "placementRules": [
        "cgu-policy1-common-cluster-version-policy",
        "cgu-policy2-common-nto-sub-policy",
        "cgu-policy3-common-ptp-sub-policy",
        "cgu-policy4-common-sriov-sub-policy"
      ],
      "precaching": {
        "spec": {}
      },
      "remediationPlan": [
        [
          "spoke1",
          "spoke2"
        ],
        [
          "spoke5",
          "spoke6"
        ]
      ],
      "status": {
        "currentBatch": 1,
        "currentBatchStartedAt": "2022-02-25T15:54:16Z",
        "remediationPlanForBatch": {
          "spoke1": 0,
          "spoke2": 1
        },
        "startedAt": "2022-02-25T15:54:16Z"
      }
    }
    ```

    -   Reflects the update progress of the current batch. Run this command again to receive updated information about the progress.

2.  If the policies include Operator subscriptions, you can check the installation progress directly on the single-node cluster.

    1.  Export the `KUBECONFIG` file of the single-node cluster you want to check the installation progress for by running the following command:

        ``` terminal
        $ export KUBECONFIG=<cluster_kubeconfig_absolute_path>
        ```

    2.  Check all the subscriptions present on the single-node cluster and look for the one in the policy you are trying to install through the `ClusterGroupUpgrade` CR by running the following command:

        ``` terminal
        $ oc get subs -A | grep -i <subscription_name>
        ```

        **Example output for `cluster-logging` policy**

        ``` terminal
        NAMESPACE                              NAME                         PACKAGE                      SOURCE             CHANNEL
        openshift-logging                      cluster-logging              cluster-logging              redhat-operators   stable
        ```

3.  If one of the managed policies includes a `ClusterVersion` CR, check the status of platform updates in the current batch by running the following command against the spoke cluster:

    ``` terminal
    $ oc get clusterversion
    ```

    **Example output**

    ``` terminal
    NAME      VERSION   AVAILABLE   PROGRESSING   SINCE   STATUS
    version   4.9.5     True        True          43s     Working towards 4.9.7: 71 of 735 done (9% complete)
    ```

4.  Check the Operator subscription by running the following command:

    ``` terminal
    $ oc get subs -n <operator-namespace> <operator-subscription> -ojsonpath="{.status}"
    ```

5.  Check the install plans present on the single-node cluster that is associated with the desired subscription by running the following command:

    ``` terminal
    $ oc get installplan -n <subscription_namespace>
    ```

    **Example output for `cluster-logging` Operator**

    ``` terminal
    NAMESPACE                              NAME            CSV                                 APPROVAL   APPROVED
    openshift-logging                      install-6khtw   cluster-logging.5.3.3-4             Manual     true 
    ```

    -   The install plans have their `Approval` field set to `Manual` and their `Approved` field changes from `true` to `false` after TALM approves the install plan.

6.  Check if the cluster service version for the Operator of the policy that the `ClusterGroupUpgrade` is installing reached the `Succeeded` phase by running the following command:

    ``` terminal
    $ oc get csv -n <operator_namespace>
    ```

    **Example output for OpenShift Logging Operator**

    ``` terminal
    NAME                    DISPLAY                     VERSION   REPLACES   PHASE
    cluster-logging.5.4.2   Red Hat OpenShift Logging   5.4.2                Succeeded
    ```

## Creating a backup of cluster resources before upgrade {#talo-backup-feature-concept_cnf-topology-aware-lifecycle-manager}

For single-node OpenShift, the Topology Aware Lifecycle Manager (TALM) can create a backup of a deployment before an upgrade. If the upgrade fails, you can recover the previous version and restore a cluster to a working state without requiring a reprovision of applications.

The container image backup starts when the `backup` field is set to `true` in the `ClusterGroupUpgrade` CR.

The backup process can be in the following statuses:

`BackupStatePreparingToStart`

:   The first reconciliation pass is in progress. The TALM deletes any spoke backup namespace and hub view resources that have been created in a failed upgrade attempt.

`BackupStateStarting`

:   The backup prerequisites and backup job are being created.

`BackupStateActive`

:   The backup is in progress.

`BackupStateSucceeded`

:   The backup has succeeded.

`BackupStateTimeout`

:   Artifact backup has been partially done.

`BackupStateError`

:   The backup has ended with a non-zero exit code.

!!! note
    If the backup fails and enters the `BackupStateTimeout` or `BackupStateError` state, the cluster upgrade does not proceed.

### Creating a ClusterGroupUpgrade CR with backup {#talo-backup-start_and_update_cnf-topology-aware-lifecycle-manager}

For single-node OpenShift, you can create a backup of a deployment before an upgrade. If the upgrade fails you can use the `upgrade-recovery.sh` script generated by Topology Aware Lifecycle Manager (TALM) to return the system to its preupgrade state. The backup consists of the following items:

Cluster backup

:   A snapshot of `etcd` and static pod manifests.

Content backup

:   Backups of folders, for example, `/etc`, `/usr/local`, `/var/lib/kubelet`.

Changed files backup

:   Any files managed by `machine-config` that have been changed.

Deployment

:   A pinned `ostree` deployment.

Images (Optional)

:   Any container images that are in use.

**Prerequisites**

-   Install the Topology Aware Lifecycle Manager (TALM).

-   Provision one or more managed clusters.

-   Log in as a user with `cluster-admin` privileges.

-   Install Red Hat Advanced Cluster Management (RHACM).

!!! note
    It is highly recommended that you create a recovery partition. The following is an example `SiteConfig` custom resource (CR) for a recovery partition of 50 GB:
    
    ``` yaml
    nodes:
        - hostName: "snonode.sno-worker-0.e2e.bos.redhat.com"
        role: "master"
        rootDeviceHints:
            hctl: "0:2:0:0"
            deviceName: /dev/sda
    ........
    ........
        #Disk /dev/sda: 893.3 GiB, 959119884288 bytes, 1873281024 sectors
        diskPartition:
            - device: /dev/sda
            partitions:
            - mount_point: /var/recovery
                size: 51200
                start: 800000
    ```

**Procedure**

1.  Save the contents of the `ClusterGroupUpgrade` CR with the `backup` field set to `true` in the `clustergroupupgrades-group-du.yaml` file:

    ``` yaml
    apiVersion: ran.openshift.io/v1alpha1
    kind: ClusterGroupUpgrade
    metadata:
      name: du-upgrade-4918
      namespace: ztp-group-du-sno
    spec:
      preCaching: true
      backup: true
      clusters:
      - cnfdb1
      - cnfdb2
      enable: false
      managedPolicies:
      - du-upgrade-platform-upgrade
      remediationStrategy:
        maxConcurrency: 2
        timeout: 240
    ```

2.  To start the update, apply the `ClusterGroupUpgrade` CR by running the following command:

    ``` terminal
    $ oc apply -f clustergroupupgrades-group-du.yaml
    ```

-   Check the status of the upgrade in the hub cluster by running the following command:

    ``` terminal
    $ oc get cgu -n ztp-group-du-sno du-upgrade-4918 -o jsonpath='{.status}'
    ```

    **Example output**

    ``` json
    {
        "backup": {
            "clusters": [
                "cnfdb2",
                "cnfdb1"
        ],
        "status": {
            "cnfdb1": "Succeeded",
            "cnfdb2": "Succeeded"
        }
    },
    "computedMaxConcurrency": 1,
    "conditions": [
        {
            "lastTransitionTime": "2022-04-05T10:37:19Z",
            "message": "Backup is completed",
            "reason": "BackupCompleted",
            "status": "True",
            "type": "BackupDone"
        }
    ],
    "precaching": {
        "spec": {}
    },
    "status": {}
    ```

### Recovering a cluster after a failed upgrade {#talo-backup-recovery_cnf-topology-aware-lifecycle-manager}

If an upgrade of a cluster fails, you can manually log in to the cluster and use the backup to return the cluster to its preupgrade state. There are two stages:

Rollback

:   If the attempted upgrade included a change to the platform OS deployment, you must roll back to the previous version before running the recovery script.

Recovery

:   The recovery shuts down containers and uses files from the backup partition to relaunch containers and restore clusters.

**Prerequisites**

-   Install the Topology Aware Lifecycle Manager (TALM).

-   Provision one or more managed clusters.

-   Install Red Hat Advanced Cluster Management (RHACM).

-   Log in as a user with `cluster-admin` privileges.

-   Run an upgrade that is configured for backup.

**Procedure**

1.  Delete the previously created `ClusterGroupUpgrade` custom resource (CR) by running the following command:

    ``` terminal
    $ oc delete cgu/du-upgrade-4918 -n ztp-group-du-sno
    ```

2.  Log in to the cluster that you want to recover.

3.  Check the status of the platform OS deployment by running the following command:

    ``` terminal
    $ oc ostree admin status
    ```

    **Example outputs**

    ``` terminal
    [root@lab-test-spoke2-node-0 core]# ostree admin status
    * rhcos c038a8f08458bbed83a77ece033ad3c55597e3f64edad66ea12fda18cbdceaf9.0
        Version: 49.84.202202230006-0
        Pinned: yes 
        origin refspec: c038a8f08458bbed83a77ece033ad3c55597e3f64edad66ea12fda18cbdceaf9
    ```

    -   The current deployment is pinned. A platform OS deployment rollback is not necessary.

    ``` terminal
    [root@lab-test-spoke2-node-0 core]# ostree admin status
    * rhcos f750ff26f2d5550930ccbe17af61af47daafc8018cd9944f2a3a6269af26b0fa.0
        Version: 410.84.202204050541-0
        origin refspec: f750ff26f2d5550930ccbe17af61af47daafc8018cd9944f2a3a6269af26b0fa
    rhcos ad8f159f9dc4ea7e773fd9604c9a16be0fe9b266ae800ac8470f63abc39b52ca.0 (rollback) 
        Version: 410.84.202203290245-0
        Pinned: yes 
        origin refspec: ad8f159f9dc4ea7e773fd9604c9a16be0fe9b266ae800ac8470f63abc39b52ca
    ```

    -   This platform OS deployment is marked for rollback.

    -   The previous deployment is pinned and can be rolled back.

4.  To trigger a rollback of the platform OS deployment, run the following command:

    ``` terminal
    $ rpm-ostree rollback -r
    ```

5.  The first phase of the recovery shuts down containers and restores files from the backup partition to the targeted directories. To begin the recovery, run the following command:

    ``` terminal
    $ /var/recovery/upgrade-recovery.sh
    ```

6.  When prompted, reboot the cluster by running the following command:

    ``` terminal
    $ systemctl reboot
    ```

7.  After the reboot, restart the recovery by running the following command:

    ``` terminal
    $ /var/recovery/upgrade-recovery.sh  --resume
    ```

!!! note
    If the recovery utility fails, you can retry with the `--restart` option:
    
    ``` terminal
    $ /var/recovery/upgrade-recovery.sh --restart
    ```

-   To check the status of the recovery run the following command:

    ``` terminal
    $ oc get clusterversion,nodes,clusteroperator
    ```

    **Example output**

    ``` terminal
    NAME                                         VERSION   AVAILABLE   PROGRESSING   SINCE   STATUS
    clusterversion.config.openshift.io/version   4.9.23    True        False         86d     Cluster version is 4.9.23 


    NAME                          STATUS   ROLES           AGE   VERSION
    node/lab-test-spoke1-node-0   Ready    master,worker   86d   v1.22.3+b93fd35 

    NAME                                                                           VERSION   AVAILABLE   PROGRESSING   DEGRADED   SINCE   MESSAGE
    clusteroperator.config.openshift.io/authentication                             4.9.23    True        False         False      2d7h    
    clusteroperator.config.openshift.io/baremetal                                  4.9.23    True        False         False      86d


    ..............
    ```

    -   The cluster version is available and has the correct version.

    -   The node status is `Ready`.

    -   The `ClusterOperator` object’s availability is `True`.

## Using the container image pre-cache feature {#talo-precache-feature-concept_cnf-topology-aware-lifecycle-manager}

Clusters might have limited bandwidth to access the container image registry, which can cause a timeout before the updates are completed.

!!! note
    The time of the update is not set by TALM. You can apply the `ClusterGroupUpgrade` CR at the beginning of the update by manual application or by external automation.

The container image pre-caching starts when the `preCaching` field is set to `true` in the `ClusterGroupUpgrade` CR. After a successful pre-caching process, you can start remediating policies. The remediation actions start when the `enable` field is set to `true`.

The pre-caching process can be in the following statuses:

`PrecacheNotStarted`

:   This is the initial state all clusters are automatically assigned to on the first reconciliation pass of the `ClusterGroupUpgrade` CR.

    In this state, TALM deletes any pre-caching namespace and hub view resources of spoke clusters that remain from previous incomplete updates. TALM then creates a new `ManagedClusterView` resource for the spoke pre-caching namespace to verify its deletion in the `PrecachePreparing` state.

`PrecachePreparing`

:   Cleaning up any remaining resources from previous incomplete updates is in progress.

`PrecacheStarting`

:   Pre-caching job prerequisites and the job are created.

`PrecacheActive`

:   The job is in "Active" state.

`PrecacheSucceeded`

:   The pre-cache job has succeeded.

`PrecacheTimeout`

:   The artifact pre-caching has been partially done.

`PrecacheUnrecoverableError`

:   The job ends with a non-zero exit code.

### Creating a ClusterGroupUpgrade CR with pre-caching {#talo-precache-start_and_update_cnf-topology-aware-lifecycle-manager}

The pre-cache feature allows the required container images to be present on the spoke cluster before the update starts.

**Prerequisites**

-   Install the Topology Aware Lifecycle Manager (TALM).

-   Provision one or more managed clusters.

-   Log in as a user with `cluster-admin` privileges.

**Procedure**

1.  Save the contents of the `ClusterGroupUpgrade` CR with the `preCaching` field set to `true` in the `clustergroupupgrades-group-du.yaml` file:

    ``` yaml
    apiVersion: ran.openshift.io/v1alpha1
    kind: ClusterGroupUpgrade
    metadata:
      name: du-upgrade-4918
      namespace: ztp-group-du-sno
    spec:
      preCaching: true 
      clusters:
      - cnfdb1
      - cnfdb2
      enable: false
      managedPolicies:
      - du-upgrade-platform-upgrade
      remediationStrategy:
        maxConcurrency: 2
        timeout: 240
    ```

    -   The `preCaching` field is set to `true`, which enables TALM to pull the container images before starting the update.

2.  When you want to start the update, apply the `ClusterGroupUpgrade` CR by running the following command:

    ``` terminal
    $ oc apply -f clustergroupupgrades-group-du.yaml
    ```

<!-- -->

1.  Check if the `ClusterGroupUpgrade` CR exists in the hub cluster by running the following command:

    ``` terminal
    $ oc get cgu -A
    ```

    **Example output**

    ``` terminal
    NAMESPACE          NAME              AGE
    ztp-group-du-sno   du-upgrade-4918   10s 
    ```

    -   The CR is created.

2.  Check the status of the pre-caching task by running the following command:

    ``` terminal
    $ oc get cgu -n ztp-group-du-sno du-upgrade-4918 -o jsonpath='{.status}'
    ```

    **Example output**

    ``` json
    {
      "conditions": [
        {
          "lastTransitionTime": "2022-01-27T19:07:24Z",
          "message": "Precaching is not completed (required)", 
          "reason": "PrecachingRequired",
          "status": "False",
          "type": "Ready"
        },
        {
          "lastTransitionTime": "2022-01-27T19:07:24Z",
          "message": "Precaching is required and not done",
          "reason": "PrecachingNotDone",
          "status": "False",
          "type": "PrecachingDone"
        },
        {
          "lastTransitionTime": "2022-01-27T19:07:34Z",
          "message": "Pre-caching spec is valid and consistent",
          "reason": "PrecacheSpecIsWellFormed",
          "status": "True",
          "type": "PrecacheSpecValid"
        }
      ],
      "precaching": {
        "clusters": [
          "cnfdb1" 
        ],
        "spec": {
          "platformImage": "image.example.io"},
        "status": {
          "cnfdb1": "Active"}
        }
    }
    ```

    -   Displays that the update is in progress.

    -   Displays the list of identified clusters.

3.  Check the status of the pre-caching job by running the following command on the spoke cluster:

    ``` terminal
    $ oc get jobs,pods -n openshift-talm-pre-cache
    ```

    **Example output**

    ``` terminal
    NAME                  COMPLETIONS   DURATION   AGE
    job.batch/pre-cache   0/1           3m10s      3m10s

    NAME                     READY   STATUS    RESTARTS   AGE
    pod/pre-cache--1-9bmlr   1/1     Running   0          3m10s
    ```

4.  Check the status of the `ClusterGroupUpgrade` CR by running the following command:

    ``` terminal
    $ oc get cgu -n ztp-group-du-sno du-upgrade-4918 -o jsonpath='{.status}'
    ```

    **Example output**

    ``` json
    "conditions": [
        {
          "lastTransitionTime": "2022-01-27T19:30:41Z",
          "message": "The ClusterGroupUpgrade CR has all clusters compliant with all the managed policies",
          "reason": "UpgradeCompleted",
          "status": "True",
          "type": "Ready"
        },
        {
          "lastTransitionTime": "2022-01-27T19:28:57Z",
          "message": "Precaching is completed",
          "reason": "PrecachingCompleted",
          "status": "True",
          "type": "PrecachingDone" 
        }
    ```

    -   The pre-cache tasks are done.

## Troubleshooting the Topology Aware Lifecycle Manager {#talo-troubleshooting_cnf-topology-aware-lifecycle-manager}

The Topology Aware Lifecycle Manager (TALM) is an OpenShift Container Platform Operator that remediates RHACM policies. When issues occur, use the `oc adm must-gather` command to gather details and logs and to take steps in debugging the issues.

For more information about related topics, see the following documentation:

-   [Red Hat Advanced Cluster Management for Kubernetes 2.4 Support Matrix](https://access.redhat.com/articles/6218901)

-   [Red Hat Advanced Cluster Management Troubleshooting](https://access.redhat.com/documentation/en-us/red_hat_advanced_cluster_management_for_kubernetes/2.0/html/troubleshooting/troubleshooting)

-   The "Troubleshooting Operator issues" section

### General troubleshooting {#talo-general-troubleshooting_cnf-topology-aware-lifecycle-manager}

You can determine the cause of the problem by reviewing the following questions:

-   Is the configuration that you are applying supported?

    -   Are the RHACM and the OpenShift Container Platform versions compatible?

    -   Are the TALM and RHACM versions compatible?

-   Which of the following components is causing the problem?

    -   [Managed policies](#talo-troubleshooting-managed-policies_cnf-topology-aware-lifecycle-manager)

    -   [Clusters](#talo-troubleshooting-clusters_cnf-topology-aware-lifecycle-manager)

    -   [Remediation Strategy](#talo-troubleshooting-remediation-strategy_cnf-topology-aware-lifecycle-manager)

    -   [Topology Aware Lifecycle Manager](#talo-troubleshooting-remediation-talo_cnf-topology-aware-lifecycle-manager)

To ensure that the `ClusterGroupUpgrade` configuration is functional, you can do the following:

1.  Create the `ClusterGroupUpgrade` CR with the `spec.enable` field set to `false`.

2.  Wait for the status to be updated and go through the troubleshooting questions.

3.  If everything looks as expected, set the `spec.enable` field to `true` in the `ClusterGroupUpgrade` CR.

!!! warning
    After you set the `spec.enable` field to `true` in the `ClusterUpgradeGroup` CR, the update procedure starts and you cannot edit the CR's `spec` fields anymore.

### Cannot modify the ClusterUpgradeGroup CR {#talo-troubleshooting-modify-cgu_cnf-topology-aware-lifecycle-manager}

Issue

:   You cannot edit the `ClusterUpgradeGroup` CR after enabling the update.

Resolution

:   Restart the procedure by performing the following steps:

    1.  Remove the old `ClusterGroupUpgrade` CR by running the following command:

        ``` terminal
        $ oc delete cgu -n <ClusterGroupUpgradeCR_namespace> <ClusterGroupUpgradeCR_name>
        ```

    2.  Check and fix the existing issues with the managed clusters and policies.

        1.  Ensure that all the clusters are managed clusters and available.

        2.  Ensure that all the policies exist and have the `spec.remediationAction` field set to `inform`.

    3.  Create a new `ClusterGroupUpgrade` CR with the correct configurations.

        ``` terminal
        $ oc apply -f <ClusterGroupUpgradeCR_YAML>
        ```

### Managed policies {#talo-troubleshooting-managed-policies_cnf-topology-aware-lifecycle-manager}

**Checking managed policies on the system**

Issue

:   You want to check if you have the correct managed policies on the system.

Resolution

:   Run the following command:

    ``` terminal
    $ oc get cgu lab-upgrade -ojsonpath='{.spec.managedPolicies}'
    ```

    **Example output**

    ``` json
    ["group-du-sno-validator-du-validator-policy", "policy2-common-nto-sub-policy", "policy3-common-ptp-sub-policy"]
    ```

**Checking remediationAction mode**

Issue

:   You want to check if the `remediationAction` field is set to `inform` in the `spec` of the managed policies.

Resolution

:   Run the following command:

    ``` terminal
    $ oc get policies --all-namespaces
    ```

    **Example output**

    ``` terminal
    NAMESPACE   NAME                                                 REMEDIATION ACTION   COMPLIANCE STATE   AGE
    default     policy1-common-cluster-version-policy                inform               NonCompliant       5d21h
    default     policy2-common-nto-sub-policy                        inform               Compliant          5d21h
    default     policy3-common-ptp-sub-policy                        inform               NonCompliant       5d21h
    default     policy4-common-sriov-sub-policy                      inform               NonCompliant       5d21h
    ```

**Checking policy compliance state**

Issue

:   You want to check the compliance state of policies.

Resolution

:   Run the following command:

    ``` terminal
    $ oc get policies --all-namespaces
    ```

    **Example output**

    ``` terminal
    NAMESPACE   NAME                                                 REMEDIATION ACTION   COMPLIANCE STATE   AGE
    default     policy1-common-cluster-version-policy                inform               NonCompliant       5d21h
    default     policy2-common-nto-sub-policy                        inform               Compliant          5d21h
    default     policy3-common-ptp-sub-policy                        inform               NonCompliant       5d21h
    default     policy4-common-sriov-sub-policy                      inform               NonCompliant       5d21h
    ```

### Clusters {#talo-troubleshooting-clusters_cnf-topology-aware-lifecycle-manager}

**Checking if managed clusters are present**

Issue

:   You want to check if the clusters in the `ClusterGroupUpgrade` CR are managed clusters.

Resolution

:   Run the following command:

    ``` terminal
    $ oc get managedclusters
    ```

    **Example output**

    ``` terminal
    NAME            HUB ACCEPTED   MANAGED CLUSTER URLS                    JOINED   AVAILABLE   AGE
    local-cluster   true           https://api.hub.example.com:6443        True     Unknown     13d
    spoke1          true           https://api.spoke1.example.com:6443     True     True        13d
    spoke3          true           https://api.spoke3.example.com:6443     True     True        27h
    ```

    1.  Alternatively, check the TALM manager logs:

        1.  Get the name of the TALM manager by running the following command:

            ``` terminal
            $ oc get pod -n openshift-operators
            ```

            **Example output**

            ``` terminal
            NAME                                                         READY   STATUS    RESTARTS   AGE
            cluster-group-upgrades-controller-manager-75bcc7484d-8k8xp   2/2     Running   0          45m
            ```

        2.  Check the TALM manager logs by running the following command:

            ``` terminal
            $ oc logs -n openshift-operators \
            cluster-group-upgrades-controller-manager-75bcc7484d-8k8xp -c manager
            ```

            **Example output**

            ``` terminal
            ERROR    controller-runtime.manager.controller.clustergroupupgrade   Reconciler error    {"reconciler group": "ran.openshift.io", "reconciler kind": "ClusterGroupUpgrade", "name": "lab-upgrade", "namespace": "default", "error": "Cluster spoke5555 is not a ManagedCluster"} 
            sigs.k8s.io/controller-runtime/pkg/internal/controller.(*Controller).processNextWorkItem
            ```

            -   The error message shows that the cluster is not a managed cluster.

**Checking if managed clusters are available**

Issue

:   You want to check if the managed clusters specified in the `ClusterGroupUpgrade` CR are available.

Resolution

:   Run the following command:

    ``` terminal
    $ oc get managedclusters
    ```

    **Example output**

    ``` terminal
    NAME            HUB ACCEPTED   MANAGED CLUSTER URLS                    JOINED   AVAILABLE   AGE
    local-cluster   true           https://api.hub.testlab.com:6443        True     Unknown     13d
    spoke1          true           https://api.spoke1.testlab.com:6443     True     True        13d 
    spoke3          true           https://api.spoke3.testlab.com:6443     True     True        27h 
    ```

    -   The value of the `AVAILABLE` field is `True` for the managed clusters.

**Checking clusterSelector**

Issue

:   You want to check if the `clusterSelector` field is specified in the `ClusterGroupUpgrade` CR in at least one of the managed clusters.

Resolution

:   Run the following command:

    ``` terminal
    $ oc get managedcluster --selector=upgrade=true 
    ```

    -   The label for the clusters you want to update is `upgrade:true`.

    **Example output**

    ``` terminal
    NAME            HUB ACCEPTED   MANAGED CLUSTER URLS                     JOINED    AVAILABLE   AGE
    spoke1          true           https://api.spoke1.testlab.com:6443      True     True        13d
    spoke3          true           https://api.spoke3.testlab.com:6443      True     True        27h
    ```

**Checking if canary clusters are present**

Issue

:   You want to check if the canary clusters are present in the list of clusters.

    **Example `ClusterGroupUpgrade` CR**

    ``` yaml
    spec:
        clusters:
        - spoke1
        - spoke3
        clusterSelector:
        - upgrade2=true
        remediationStrategy:
            canaries:
            - spoke3
            maxConcurrency: 2
            timeout: 240
    ```

Resolution

:   Run the following commands:

    ``` terminal
    $ oc get cgu lab-upgrade -ojsonpath='{.spec.clusters}'
    ```

    **Example output**

    ``` json
    ["spoke1", "spoke3"]
    ```

    1.  Check if the canary clusters are present in the list of clusters that match `clusterSelector` labels by running the following command:

        ``` terminal
        $ oc get managedcluster --selector=upgrade=true
        ```

        **Example output**

        ``` terminal
        NAME            HUB ACCEPTED   MANAGED CLUSTER URLS   JOINED    AVAILABLE   AGE
        spoke1          true           https://api.spoke1.testlab.com:6443   True     True        13d
        spoke3          true           https://api.spoke3.testlab.com:6443   True     True        27h
        ```

!!! note
    A cluster can be present in `spec.clusters` and also be matched by the `spec.clusterSelecter` label.

**Checking the pre-caching status on spoke clusters**

1.  Check the status of pre-caching by running the following command on the spoke cluster:

    ``` terminal
    $ oc get jobs,pods -n openshift-talo-pre-cache
    ```

### Remediation Strategy {#talo-troubleshooting-remediation-strategy_cnf-topology-aware-lifecycle-manager}

**Checking if remediationStrategy is present in the ClusterGroupUpgrade CR**

Issue

:   You want to check if the `remediationStrategy` is present in the `ClusterGroupUpgrade` CR.

Resolution

:   Run the following command:

    ``` terminal
    $ oc get cgu lab-upgrade -ojsonpath='{.spec.remediationStrategy}'
    ```

    **Example output**

    ``` json
    {"maxConcurrency":2, "timeout":240}
    ```

**Checking if maxConcurrency is specified in the ClusterGroupUpgrade CR**

Issue

:   You want to check if the `maxConcurrency` is specified in the `ClusterGroupUpgrade` CR.

Resolution

:   Run the following command:

    ``` terminal
    $ oc get cgu lab-upgrade -ojsonpath='{.spec.remediationStrategy.maxConcurrency}'
    ```

    **Example output**

    ``` terminal
    2
    ```

### Topology Aware Lifecycle Manager {#talo-troubleshooting-remediation-talo_cnf-topology-aware-lifecycle-manager}

**Checking condition message and status in the ClusterGroupUpgrade CR**

Issue

:   You want to check the value of the `status.conditions` field in the `ClusterGroupUpgrade` CR.

Resolution

:   Run the following command:

    ``` terminal
    $ oc get cgu lab-upgrade -ojsonpath='{.status.conditions}'
    ```

    **Example output**

    ``` json
    {"lastTransitionTime":"2022-02-17T22:25:28Z", "message":"The ClusterGroupUpgrade CR has managed policies that are missing:[policyThatDoesntExist]", "reason":"UpgradeCannotStart", "status":"False", "type":"Ready"}
    ```

**Checking corresponding copied policies**

Issue

:   You want to check if every policy from `status.managedPoliciesForUpgrade` has a corresponding policy in `status.copiedPolicies`.

Resolution

:   Run the following command:

    ``` terminal
    $ oc get cgu lab-upgrade -oyaml
    ```

    **Example output**

    ``` yaml
    status:
      …
      copiedPolicies:
      - lab-upgrade-policy3-common-ptp-sub-policy
      managedPoliciesForUpgrade:
      - name: policy3-common-ptp-sub-policy
        namespace: default
    ```

**Checking if status.remediationPlan was computed**

Issue

:   You want to check if `status.remediationPlan` is computed.

Resolution

:   Run the following command:

    ``` terminal
    $ oc get cgu lab-upgrade -ojsonpath='{.status.remediationPlan}'
    ```

    **Example output**

    ``` json
    [["spoke2", "spoke3"]]
    ```

**Errors in the TALM manager container**

Issue

:   You want to check the logs of the manager container of TALM.

Resolution

:   Run the following command:

    ``` terminal
    $ oc logs -n openshift-operators \
    cluster-group-upgrades-controller-manager-75bcc7484d-8k8xp -c manager
    ```

    **Example output**

    ``` terminal
    ERROR    controller-runtime.manager.controller.clustergroupupgrade   Reconciler error    {"reconciler group": "ran.openshift.io", "reconciler kind": "ClusterGroupUpgrade", "name": "lab-upgrade", "namespace": "default", "error": "Cluster spoke5555 is not a ManagedCluster"} 
    sigs.k8s.io/controller-runtime/pkg/internal/controller.(*Controller).processNextWorkItem
    ```

    -   Displays the error.

-   For information about troubleshooting, see [OpenShift Container Platform Troubleshooting Operator Issues](../support/troubleshooting/troubleshooting-operator-issues.xml).

-   For more information about using Topology Aware Lifecycle Manager in the ZTP workflow, see [Updating managed policies with Topology Aware Lifecycle Manager](../ztp-deploying-disconnected/#cnf-topology-aware-lifecycle-manager).
