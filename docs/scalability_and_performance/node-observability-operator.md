# Requesting CRI-O and Kubelet profiling data by using the Node Observability Operator

The Node Observability Operator collects and stores the CRI-O and Kubelet profiling data of worker nodes. You can query the profiling data to analyze the CRI-O and Kubelet performance trends and debug the performance-related issues.

!!! important
    The Node Observability Operator is a Technology Preview feature only. Technology Preview features are not supported with Red Hat production service level agreements (SLAs) and might not be functionally complete. Red Hat does not recommend using them in production. These features provide early access to upcoming product features, enabling customers to test functionality and provide feedback during the development process.
    
    For more information about the support scope of Red Hat Technology Preview features, see <https://access.redhat.com/support/offerings/techpreview/>.

## Workflow of the Node Observability Operator {#workflow-node-observability-operator_node-observability-operator}

The following workflow outlines on how to query the profiling data using the Node Observability Operator:

1.  Install the Node Observability Operator in the OpenShift Container Platform cluster.

2.  Create a NodeObservability custom resource to enable the CRI-O profiling on the worker nodes of your choice.

3.  Run the profiling query to generate the profiling data.

## Installing the Node Observability Operator {#install-node-observability-operator_node-observability-operator}

The Node Observability Operator is not installed in OpenShift Container Platform by default. You can install the Node Observability Operator by using the OpenShift Container Platform CLI or the web console.

### Installing the Node Observability Operator using the CLI {#install-node-observability-using-cli_node-observability-operator}

You can install the Node Observability Operator by using the OpenShift CLI (oc).

**Prerequisites**

-   You have installed the OpenShift CLI (oc).

-   You have access to the cluster with `cluster-admin` privileges.

**Procedure**

1.  Confirm that the Node Observability Operator is available by running the following command:

    ``` terminal
    $ oc get packagemanifests -n openshift-marketplace node-observability-operator
    ```

    **Example output**

    ``` terminal
    NAME                            CATALOG                AGE
    node-observability-operator     Red Hat Operators      9h
    ```

2.  Create the `node-observability-operator` namespace by running the following command:

    ``` terminal
    $ oc new-project node-observability-operator
    ```

3.  Create an `OperatorGroup` object YAML file:

    ``` yaml
    cat <<EOF | oc apply -f -
    apiVersion: operators.coreos.com/v1
    kind: OperatorGroup
    metadata:
      name: node-observability-operator
      namespace: node-observability-operator
    spec:
      targetNamespaces:
      - node-observability-operator
    EOF
    ```

4.  Create a `Subscription` object YAML file to subscribe a namespace to an Operator:

    ``` yaml
    cat <<EOF | oc apply -f -
    apiVersion: operators.coreos.com/v1alpha1
    kind: Subscription
    metadata:
      name: node-observability-operator
      namespace: node-observability-operator
    spec:
      channel: alpha
      name: node-observability-operator
      source: redhat-operators
      sourceNamespace: openshift-marketplace
    EOF
    ```

<!-- -->

1.  View the install plan name by running the following command:

    ``` terminal
    $ oc -n node-observability-operator get sub node-observability-operator -o yaml | yq '.status.installplan.name'
    ```

    **Example output**

    ``` terminal
    install-dt54w
    ```

2.  Verify the install plan status by running the following command:

    ``` terminal
    $ oc -n node-observability-operator get ip <install_plan_name> -o yaml | yq '.status.phase'
    ```

    `<install_plan_name>` is the install plan name that you obtained from the output of the previous command.

    **Example output**

    ``` terminal
    COMPLETE
    ```

3.  Verify that the Node Observability Operator is up and running:

    ``` terminal
    $ oc get deploy -n node-observability-operator
    ```

    **Example output**

    ``` terminal
    NAME                                            READY   UP-TO-DATE  AVAILABLE   AGE
    node-observability-operator-controller-manager  1/1     1           1           40h
    ```

### Installing the Node Observability Operator using the web console {#install-node-observability-using-web-console_node-observability-operator}

You can install the Node Observability Operator from the OpenShift Container Platform web console.

**Prerequisites**

-   You have access to the cluster with `cluster-admin` privileges.

-   You have access to the OpenShift Container Platform web console.

**Procedure**

1.  Log in to the OpenShift Container Platform web console.

2.  In the Administrator???s navigation panel, expand **Operators** ??? **OperatorHub**.

3.  In the **All items** field, enter **Node Observability Operator** and select the **Node Observability Operator** tile.

4.  Click **Install**.

5.  On the **Install Operator** page, configure the following settings:

    1.  In the **Update channel** area, click **alpha**.

    2.  In the **Installation mode** area, click **A specific namespace on the cluster**.

    3.  From the **Installed Namespace** list, select **node-observability-operator** from the list.

    4.  In the **Update approval** area, select **Automatic**.

    5.  Click **Install**.

<!-- -->

1.  In the Administrator???s navigation panel, expand **Operators** ??? **Installed Operators**.

2.  Verify that the Node Observability Operator is listed in the Operators list.

## Creating the Node Observability custom resource {#creating-node-observability-custom-resource_node-observability-operator}

You must create and run the `NodeObservability` custom resource (CR) before you run the profiling query. When you run the `NodeObservability` CR, it creates the necessary machine config and machine config pool CRs to enable the CRI-O profiling on the worker nodes matching the `nodeSelector`.

!!! important
    The worker nodes matching the `nodeSelector` specified in `NodeObservability` CR are rebooted. It might take 10 or more minutes to complete.
!!! note
    Kubelet profiling is enabled by default.

The CRI-O unix socket of the node is mounted on the agent pod, which allows the agent to communicate with CRI-O to run the pprof request. Similarly, the `kubelet-serving-ca` certificate chain is mounted on the agent pod, which allows secure communication between the agent and node???s kubelet endpoint.

**Prerequisites** \* You have installed the Node Observability Operator. \* You have installed the OpenShift CLI (oc). \* You have access to the cluster with `cluster-admin` privileges.

**Procedure**

1.  Log in to the OpenShift Container Platform CLI by running the following command:

    ``` terminal
    $ oc login -u kubeadmin https://<HOSTNAME>:6443
    ```

2.  Switch back to the `node-observability-operator` namespace by running the following command:

    ``` terminal
    $ oc project node-observability-operator
    ```

3.  Create a CR file named `nodeobservability.yaml` that contains the following text:

    ``` yaml
        apiVersion: nodeobservability.olm.openshift.io/v1alpha2
        kind: NodeObservability
        metadata:
          name: cluster 
        spec:
          nodeSelector:
            kubernetes.io/hostname: <node_hostname> 
          type: crio-kubelet
    ```

    -   You must specify the name as `cluster` because there should be only one `NodeObservability` CR per cluster.

    -   Specify the nodes on which the Node Observability agent must be deployed.

4.  Run the `NodeObservability` CR:

    ``` terminal
    oc apply -f nodeobservability.yaml
    ```

    **Example output**

    ``` terminal
    nodeobservability.olm.openshift.io/cluster created
    ```

5.  Review the status of the `NodeObservability` CR by running the following command:

    ``` terminal
    $ oc get nob/cluster -o yaml | yq '.status.conditions'
    ```

    **Example output**

    ``` terminal
    conditions:
      conditions:
      - lastTransitionTime: "2022-07-05T07:33:54Z"
        message: 'DaemonSet node-observability-ds ready: true NodeObservabilityMachineConfig
          ready: true'
        reason: Ready
        status: "True"
        type: Ready
    ```

    `NodeObservability` CR run is completed when the reason is `Ready` and the status is `True`.

## Running the profiling query {#running-profiling-query_node-observability-operator}

To run the profiling query, you must create a `NodeObservabilityRun` resource. The profiling query is a blocking operation that fetches CRI-O and Kubelet profiling data for a duration of 30 seconds. After the profiling query is complete, you must retrieve the profiling data inside the container file system `/run/node-observability` directory. The lifetime of data is bound to the agent pod through the `emptyDir` volume, so you can access the profiling data while the agent pod is in the `running` status.

!!! important
    You can request only one profiling query at any point of time.

**Prerequisites** \* You have installed the Node Observability Operator. \* You have created the `NodeObservability` custom resource (CR). \* You have access to the cluster with `cluster-admin` privileges.

**Procedure**

1.  Create a `NodeObservabilityRun` resource file named `nodeobservabilityrun.yaml` that contains the following text:

    ``` yaml
    apiVersion: nodeobservability.olm.openshift.io/v1alpha2
    kind: NodeObservabilityRun
    metadata:
      name: nodeobservabilityrun
    spec:
      nodeObservabilityRef:
        name: cluster
    ```

2.  Trigger the profiling query by running the `NodeObservabilityRun` resource:

    ``` terminal
    $ oc apply -f nodeobservabilityrun.yaml
    ```

3.  Review the status of the `NodeObservabilityRun` by running the following command:

    ``` terminal
    $ oc get nodeobservabilityrun -o yaml  | yq '.status.conditions'
    ```

    **Example output**

    ``` terminal
    conditions:
    - lastTransitionTime: "2022-07-07T14:57:34Z"
      message: Ready to start profiling
      reason: Ready
      status: "True"
      type: Ready
    - lastTransitionTime: "2022-07-07T14:58:10Z"
      message: Profiling query done
      reason: Finished
      status: "True"
      type: Finished
    ```

    The profiling query is complete once the status is `True` and type is `Finished`.

4.  Retrieve the profiling data from the container???s `/run/node-observability` path by running the following bash script:

    ``` bash
    for a in $(oc get nodeobservabilityrun nodeobservabilityrun -o yaml | yq .status.agents[].name); do
      echo "agent ${a}"
      mkdir -p "/tmp/${a}"
      for p in $(oc exec "${a}" -c node-observability-agent -- bash -c "ls /run/node-observability/*.pprof"); do
        f="$(basename ${p})"
        echo "copying ${f} to /tmp/${a}/${f}"
        oc exec "${a}" -c node-observability-agent -- cat "${p}" > "/tmp/${a}/${f}"
      done
    done
    ```
