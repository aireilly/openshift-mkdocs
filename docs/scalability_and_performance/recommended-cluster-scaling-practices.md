# Recommended cluster scaling practices

!!! important
    The guidance in this section is only relevant for installations with cloud provider integration.
    
    These guidelines apply to OpenShift Container Platform with software-defined networking (SDN), not Open Virtual Network (OVN).

Apply the following best practices to scale the number of worker machines in your OpenShift Container Platform cluster. You scale the worker machines by increasing or decreasing the number of replicas that are defined in the worker machine set.

## Recommended practices for scaling the cluster {#recommended-scale-practices_cluster-scaling}

When scaling up the cluster to higher node counts:

-   Spread nodes across all of the available zones for higher availability.

-   Scale up by no more than 25 to 50 machines at once.

-   Consider creating new compute machine sets in each available zone with alternative instance types of similar size to help mitigate any periodic provider capacity constraints. For example, on AWS, use m5.large and m5d.large.

!!! note
    Cloud providers might implement a quota for API services. Therefore, gradually scale the cluster.

The controller might not be able to create the machines if the replicas in the compute machine sets are set to higher numbers all at one time. The number of requests the cloud platform, which OpenShift Container Platform is deployed on top of, is able to handle impacts the process. The controller will start to query more while trying to create, check, and update the machines with the status. The cloud platform on which OpenShift Container Platform is deployed has API request limits and excessive queries might lead to machine creation failures due to cloud platform limitations.

Enable machine health checks when scaling to large node counts. In case of failures, the health checks monitor the condition and automatically repair unhealthy machines.

!!! note
    When scaling large and dense clusters to lower node counts, it might take large amounts of time as the process involves draining or evicting the objects running on the nodes being terminated in parallel. Also, the client might start to throttle the requests if there are too many objects to evict. The default client QPS and burst rates are currently set to `5` and `10` respectively and they cannot be modified in OpenShift Container Platform.

## Modifying a compute machine set {#machineset-modifying_cluster-scaling}

To make changes to a compute machine set, edit the `MachineSet` YAML. Then, remove all machines associated with the compute machine set by deleting each machine or scaling down the compute machine set to `0` replicas. Then, scale the replicas back to the desired number. Changes you make to a compute machine set do not affect existing machines.

If you need to scale a compute machine set without making other changes, you do not need to delete the machines.

!!! note
    By default, the OpenShift Container Platform router pods are deployed on workers. Because the router is required to access some cluster resources, including the web console, do not scale the compute machine set to `0` unless you first relocate the router pods.

**Prerequisites**

-   Install an OpenShift Container Platform cluster and the `oc` command line.

-   Log in to `oc` as a user with `cluster-admin` permission.

**Procedure**

1.  Edit the compute machine set by running the following command:

    ``` terminal
    $ oc edit machineset <machineset> -n openshift-machine-api
    ```

2.  Scale down the compute machine set to `0` by running one of the following commands:

    ``` terminal
    $ oc scale --replicas=0 machineset <machineset> -n openshift-machine-api
    ```

    Or:

    ``` terminal
    $ oc edit machineset <machineset> -n openshift-machine-api
    ```

    !!! tip
        You can alternatively apply the following YAML to scale the compute machine set:
        
        ``` yaml
        apiVersion: machine.openshift.io/v1beta1
        kind: MachineSet
        metadata:
          name: <machineset>
          namespace: openshift-machine-api
        spec:
          replicas: 0
        ```

    Wait for the machines to be removed.

3.  Scale up the compute machine set as needed by running one of the following commands:

    ``` terminal
    $ oc scale --replicas=2 machineset <machineset> -n openshift-machine-api
    ```

    Or:

    ``` terminal
    $ oc edit machineset <machineset> -n openshift-machine-api
    ```

    !!! tip
        You can alternatively apply the following YAML to scale the compute machine set:
        
        ``` yaml
        apiVersion: machine.openshift.io/v1beta1
        kind: MachineSet
        metadata:
          name: <machineset>
          namespace: openshift-machine-api
        spec:
          replicas: 2
        ```

    Wait for the machines to start. The new machines contain changes you made to the compute machine set.

## About machine health checks {#machine-health-checks-about_cluster-scaling}

Machine health checks automatically repair unhealthy machines in a particular machine pool.

To monitor machine health, create a resource to define the configuration for a controller. Set a condition to check, such as staying in the `NotReady` status for five minutes or displaying a permanent condition in the node-problem-detector, and a label for the set of machines to monitor.

!!! note
    You cannot apply a machine health check to a machine with the master role.

The controller that observes a `MachineHealthCheck` resource checks for the defined condition. If a machine fails the health check, the machine is automatically deleted and one is created to take its place. When a machine is deleted, you see a `machine deleted` event.

To limit disruptive impact of the machine deletion, the controller drains and deletes only one node at a time. If there are more unhealthy machines than the `maxUnhealthy` threshold allows for in the targeted pool of machines, remediation stops and therefore enables manual intervention.

!!! note
    Consider the timeouts carefully, accounting for workloads and requirements.
    
    -   Long timeouts can result in long periods of downtime for the workload on the unhealthy machine.
    
    -   Too short timeouts can result in a remediation loop. For example, the timeout for checking the `NotReady` status must be long enough to allow the machine to complete the startup process.

To stop the check, remove the resource.

### Limitations when deploying machine health checks {#machine-health-checks-limitations_cluster-scaling}

There are limitations to consider before deploying a machine health check:

-   Only machines owned by a machine set are remediated by a machine health check.

-   Control plane machines are not currently supported and are not remediated if they are unhealthy.

-   If the node for a machine is removed from the cluster, a machine health check considers the machine to be unhealthy and remediates it immediately.

-   If the corresponding node for a machine does not join the cluster after the `nodeStartupTimeout`, the machine is remediated.

-   A machine is remediated immediately if the `Machine` resource phase is `Failed`.

## Sample MachineHealthCheck resource {#machine-health-checks-resource_cluster-scaling}

The `MachineHealthCheck` resource for all cloud-based installation types, and other than bare metal, resembles the following YAML file:

``` yaml
apiVersion: machine.openshift.io/v1beta1
kind: MachineHealthCheck
metadata:
  name: example 
  namespace: openshift-machine-api
spec:
  selector:
    matchLabels:
      machine.openshift.io/cluster-api-machine-role: <role> 
      machine.openshift.io/cluster-api-machine-type: <role> 
      machine.openshift.io/cluster-api-machineset: <cluster_name>-<label>-<zone> 
  unhealthyConditions:
  - type:    "Ready"
    timeout: "300s" 
    status: "False"
  - type:    "Ready"
    timeout: "300s" 
    status: "Unknown"
  maxUnhealthy: "40%" 
  nodeStartupTimeout: "10m" 
```

-   Specify the name of the machine health check to deploy.

-   Specify a label for the machine pool that you want to check.

-   Specify the machine set to track in `<cluster_name>-<label>-<zone>` format. For example, `prod-node-us-east-1a`.

-   Specify the timeout duration for a node condition. If a condition is met for the duration of the timeout, the machine will be remediated. Long timeouts can result in long periods of downtime for a workload on an unhealthy machine.

-   Specify the amount of machines allowed to be concurrently remediated in the targeted pool. This can be set as a percentage or an integer. If the number of unhealthy machines exceeds the limit set by `maxUnhealthy`, remediation is not performed.

-   Specify the timeout duration that a machine health check must wait for a node to join the cluster before a machine is determined to be unhealthy.

!!! note
    The `matchLabels` are examples only; you must map your machine groups based on your specific needs.

### Short-circuiting machine health check remediation {#machine-health-checks-short-circuiting_cluster-scaling}

Short circuiting ensures that machine health checks remediate machines only when the cluster is healthy. Short-circuiting is configured through the `maxUnhealthy` field in the `MachineHealthCheck` resource.

If the user defines a value for the `maxUnhealthy` field, before remediating any machines, the `MachineHealthCheck` compares the value of `maxUnhealthy` with the number of machines within its target pool that it has determined to be unhealthy. Remediation is not performed if the number of unhealthy machines exceeds the `maxUnhealthy` limit.

!!! important
    If `maxUnhealthy` is not set, the value defaults to `100%` and the machines are remediated regardless of the state of the cluster.

The appropriate `maxUnhealthy` value depends on the scale of the cluster you deploy and how many machines the `MachineHealthCheck` covers. For example, you can use the `maxUnhealthy` value to cover multiple compute machine sets across multiple availability zones so that if you lose an entire zone, your `maxUnhealthy` setting prevents further remediation within the cluster. In global Azure regions that do not have multiple availability zones, you can use availability sets to ensure high availability.

The `maxUnhealthy` field can be set as either an integer or percentage. There are different remediation implementations depending on the `maxUnhealthy` value.

#### Setting maxUnhealthy by using an absolute value {#_setting_maxunhealthy_by_using_an_absolute_value}

If `maxUnhealthy` is set to `2`:

-   Remediation will be performed if 2 or fewer nodes are unhealthy

-   Remediation will not be performed if 3 or more nodes are unhealthy

These values are independent of how many machines are being checked by the machine health check.

#### Setting maxUnhealthy by using percentages {#_setting_maxunhealthy_by_using_percentages}

If `maxUnhealthy` is set to `40%` and there are 25 machines being checked:

-   Remediation will be performed if 10 or fewer nodes are unhealthy

-   Remediation will not be performed if 11 or more nodes are unhealthy

If `maxUnhealthy` is set to `40%` and there are 6 machines being checked:

-   Remediation will be performed if 2 or fewer nodes are unhealthy

-   Remediation will not be performed if 3 or more nodes are unhealthy

!!! note
    The allowed number of machines is rounded down when the percentage of `maxUnhealthy` machines that are checked is not a whole number.

## Creating a MachineHealthCheck resource {#machine-health-checks-creating_cluster-scaling}

You can create a `MachineHealthCheck` resource for all `MachineSets` in your cluster. You should not create a `MachineHealthCheck` resource that targets control plane machines.

**Prerequisites**

-   Install the `oc` command line interface.

**Procedure**

1.  Create a `healthcheck.yml` file that contains the definition of your machine health check.

2.  Apply the `healthcheck.yml` file to your cluster:

    ``` terminal
    $ oc apply -f healthcheck.yml
    ```
