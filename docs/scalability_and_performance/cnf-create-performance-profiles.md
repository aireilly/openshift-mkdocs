# Creating a performance profile

Learn about the Performance Profile Creator (PPC) and how you can use it to create a performance profile.

## About the Performance Profile Creator {#cnf-about-the-profile-creator-tool_cnf-create-performance-profiles}

The Performance Profile Creator (PPC) is a command-line tool, delivered with the Node Tuning Operator, used to create the performance profile. The tool consumes `must-gather` data from the cluster and several user-supplied profile arguments. The PPC generates a performance profile that is appropriate for your hardware and topology.

The tool is run by one of the following methods:

-   Invoking `podman`

-   Calling a wrapper script

### Gathering data about your cluster using `must-gather` {#gathering-data-about-your-cluster-using-must-gather_cnf-create-performance-profiles}

The Performance Profile Creator (PPC) tool requires `must-gather` data. As a cluster administrator, run `must-gather` to capture information about your cluster.

!!! note
    In earlier versions of OpenShift Container Platform, the Performance Addon Operator provided automatic, low latency performance tuning for applications. In OpenShift Container Platform 4.11, these functions are part of the Node Tuning Operator. However, you must still use the `performance-addon-operator-must-gather` image when running the `must-gather` command.

**Prerequisites**

-   Access to the cluster as a user with the `cluster-admin` role.

-   Access to the Performance Addon Operator `must gather` image.

-   The OpenShift CLI (`oc`) installed.

**Procedure**

1.  Navigate to the directory where you want to store the `must-gather` data.

2.  Run `must-gather` on your cluster:

    ``` terminal
    $ oc adm must-gather --image=<PAO_must_gather_image> --dest-dir=<dir>
    ```

    !!! note
        `must-gather` must be run with the `performance-addon-operator-must-gather` image. The output can optionally be compressed. Compressed output is required if you are running the Performance Profile Creator wrapper script.

    **Example**

    ``` terminal
    $ oc adm must-gather --image=registry.redhat.io/openshift4/performance-addon-operator-must-gather-rhel8:v4.11 --dest-dir=<path_to_must-gather>/must-gather
    ```

3.  Create a compressed file from the `must-gather` directory:

    ``` terminal
    $ tar cvaf must-gather.tar.gz must-gather/
    ```

### Running the Performance Profile Creator using podman {#running-the-performance-profile-profile-cluster-using-podman_cnf-create-performance-profiles}

As a cluster administrator, you can run `podman` and the Performance Profile Creator to create a performance profile.

**Prerequisites**

-   Access to the cluster as a user with the `cluster-admin` role.

-   A cluster installed on bare-metal hardware.

-   A node with `podman` and OpenShift CLI (`oc`) installed.

-   Access to the Node Tuning Operator image.

**Procedure**

1.  Check the machine config pool:

    ``` terminal
    $ oc get mcp
    ```

    **Example output**

    ``` terminal
    NAME         CONFIG                                                 UPDATED   UPDATING   DEGRADED   MACHINECOUNT   READYMACHINECOUNT   UPDATEDMACHINECOUNT   DEGRADEDMACHINECOUNT   AGE
    master       rendered-master-acd1358917e9f98cbdb599aea622d78b       True      False      False      3              3                   3                     0                      22h
    worker-cnf   rendered-worker-cnf-1d871ac76e1951d32b2fe92369879826   False     True       False      2              1                   1                     0                      22h
    ```

2.  Use Podman to authenticate to `registry.redhat.io`:

    ``` terminal
    $ podman login registry.redhat.io
    ```

    ``` bash
    Username: myrhusername
    Password: ************
    ```

3.  Optional: Display help for the PPC tool:

    ``` terminal
    $ podman run --rm --entrypoint performance-profile-creator registry.redhat.io/openshift4/ose-cluster-node-tuning-operator:v4.11 -h
    ```

    **Example output**

    ``` terminal
    A tool that automates creation of Performance Profiles

    Usage:
      performance-profile-creator [flags]

    Flags:
          --disable-ht                        Disable Hyperthreading
      -h, --help                              help for performance-profile-creator
          --info string                       Show cluster information; requires --must-gather-dir-path, ignore the other arguments. [Valid values: log, json] (default "log")
          --mcp-name string                   MCP name corresponding to the target machines (required)
          --must-gather-dir-path string       Must gather directory path (default "must-gather")
          --offlined-cpu-count int            Number of offlined CPUs
          --power-consumption-mode string     The power consumption mode.  [Valid values: default, low-latency, ultra-low-latency] (default "default")
          --profile-name string               Name of the performance profile to be created (default "performance")
          --reserved-cpu-count int            Number of reserved CPUs (required)
          --rt-kernel                         Enable Real Time Kernel (required)
          --split-reserved-cpus-across-numa   Split the Reserved CPUs across NUMA nodes
          --topology-manager-policy string    Kubelet Topology Manager Policy of the performance profile to be created. [Valid values: single-numa-node, best-effort, restricted] (default "restricted")
          --user-level-networking             Run with User level Networking(DPDK) enabled
    ```

4.  Run the Performance Profile Creator tool in discovery mode:

    !!! note
        Discovery mode inspects your cluster using the output from `must-gather`. The output produced includes information on:
        
        -   The NUMA cell partitioning with the allocated CPU ids
        
        -   Whether hyperthreading is enabled
        
        Using this information you can set appropriate values for some of the arguments supplied to the Performance Profile Creator tool.

    ``` terminal
    $ podman run --entrypoint performance-profile-creator -v <path_to_must-gather>/must-gather:/must-gather:z registry.redhat.io/openshift4/ose-cluster-node-tuning-operator:v4.11 --info log --must-gather-dir-path /must-gather
    ```

    !!! note
        This command uses the performance profile creator as a new entry point to `podman`. It maps the `must-gather` data for the host into the container image and invokes the required user-supplied profile arguments to produce the `my-performance-profile.yaml` file.
        
        The `-v` option can be the path to either:
        
        -   The `must-gather` output directory
        
        -   An existing directory containing the `must-gather` decompressed tarball
        
        The `info` option requires a value which specifies the output format. Possible values are log and JSON. The JSON format is reserved for debugging.

5.  Run `podman`:

    ``` terminal
    $ podman run --entrypoint performance-profile-creator -v /must-gather:/must-gather:z registry.redhat.io/openshift4/ose-cluster-node-tuning-operator:vBranch Build --mcp-name=worker-cnf --reserved-cpu-count=4 --rt-kernel=true --split-reserved-cpus-across-numa=false --must-gather-dir-path /must-gather --power-consumption-mode=ultra-low-latency --offlined-cpu-count=6 > my-performance-profile.yaml
    ```

    !!! note
        The Performance Profile Creator arguments are shown in the Performance Profile Creator arguments table. The following arguments are required:
        
        -   `reserved-cpu-count`
        
        -   `mcp-name`
        
        -   `rt-kernel`
        
        The `mcp-name` argument in this example is set to `worker-cnf` based on the output of the command `oc get mcp`. For single-node OpenShift use `--mcp-name=master`.

6.  Review the created YAML file:

    ``` terminal
    $ cat my-performance-profile.yaml
    ```

    **Example output**

    ``` yaml
    apiVersion: performance.openshift.io/v2
    kind: PerformanceProfile
    metadata:
      name: performance
    spec:
      cpu:
        isolated: 2-39,48-79
        offlined: 42-47
        reserved: 0-1,40-41
      machineConfigPoolSelector:
        machineconfiguration.openshift.io/role: worker-cnf
      nodeSelector:
        node-role.kubernetes.io/worker-cnf: ""
      numa:
        topologyPolicy: restricted
      realTimeKernel:
        enabled: true
      workloadHints:
        highPowerConsumption: true
        realTime: true
    ```

7.  Apply the generated profile:

    ``` terminal
    $ oc apply -f my-performance-profile.yaml
    ```

#### How to run `podman` to create a performance profile {#how-to-run-podman-to-create-a-profile_cnf-create-performance-profiles}

The following example illustrates how to run `podman` to create a performance profile with 20 reserved CPUs that are to be split across the NUMA nodes.

Node hardware configuration:

-   80 CPUs

-   Hyperthreading enabled

-   Two NUMA nodes

-   Even numbered CPUs run on NUMA node 0 and odd numbered CPUs run on NUMA node 1

Run `podman` to create the performance profile:

``` terminal
$ podman run --entrypoint performance-profile-creator -v /must-gather:/must-gather:z registry.redhat.io/openshift4/ose-cluster-node-tuning-operator:v4.11 --mcp-name=worker-cnf --reserved-cpu-count=20 --rt-kernel=true --split-reserved-cpus-across-numa=true --must-gather-dir-path /must-gather > my-performance-profile.yaml
```

The created profile is described in the following YAML:

``` yaml
  apiVersion: performance.openshift.io/v2
  kind: PerformanceProfile
  metadata:
    name: performance
  spec:
    cpu:
      isolated: 10-39,50-79
      reserved: 0-9,40-49
    nodeSelector:
      node-role.kubernetes.io/worker-cnf: ""
    numa:
      topologyPolicy: restricted
    realTimeKernel:
      enabled: true
```

!!! note
    In this case, 10 CPUs are reserved on NUMA node 0 and 10 are reserved on NUMA node 1.

### Running the Performance Profile Creator wrapper script {#running-the-performance-profile-creator-wrapper-script_cnf-create-performance-profiles}

The performance profile wrapper script simplifies the running of the Performance Profile Creator (PPC) tool. It hides the complexities associated with running `podman` and specifying the mapping directories and it enables the creation of the performance profile.

**Prerequisites**

-   Access to the Node Tuning Operator image.

-   Access to the `must-gather` tarball.

**Procedure**

1.  Create a file on your local machine named, for example, `run-perf-profile-creator.sh`:

    ``` terminal
    $ vi run-perf-profile-creator.sh
    ```

2.  Paste the following code into the file:

    ``` bash
    #!/bin/bash

    readonly CONTAINER_RUNTIME=${CONTAINER_RUNTIME:-podman}
    readonly CURRENT_SCRIPT=$(basename "$0")
    readonly CMD="${CONTAINER_RUNTIME} run --entrypoint performance-profile-creator"
    readonly IMG_EXISTS_CMD="${CONTAINER_RUNTIME} image exists"
    readonly IMG_PULL_CMD="${CONTAINER_RUNTIME} image pull"
    readonly MUST_GATHER_VOL="/must-gather"

    NTO_IMG="registry.redhat.io/openshift4/ose-cluster-node-tuning-operator:v4.11"
    MG_TARBALL=""
    DATA_DIR=""

    usage() {
      print "Wrapper usage:"
      print "  ${CURRENT_SCRIPT} [-h] [-p image][-t path] -- [performance-profile-creator flags]"
      print ""
      print "Options:"
      print "   -h                 help for ${CURRENT_SCRIPT}"
      print "   -p                 Node Tuning Operator image"
      print "   -t                 path to a must-gather tarball"

      ${IMG_EXISTS_CMD} "${NTO_IMG}" && ${CMD} "${NTO_IMG}" -h
    }

    function cleanup {
      [ -d "${DATA_DIR}" ] && rm -rf "${DATA_DIR}"
    }
    trap cleanup EXIT

    exit_error() {
      print "error: $*"
      usage
      exit 1
    }

    print() {
      echo  "$*" >&2
    }

    check_requirements() {
      ${IMG_EXISTS_CMD} "${NTO_IMG}" || ${IMG_PULL_CMD} "${NTO_IMG}" || \
          exit_error "Node Tuning Operator image not found"

      [ -n "${MG_TARBALL}" ] || exit_error "Must-gather tarball file path is mandatory"
      [ -f "${MG_TARBALL}" ] || exit_error "Must-gather tarball file not found"

      DATA_DIR=$(mktemp -d -t "${CURRENT_SCRIPT}XXXX") || exit_error "Cannot create the data directory"
      tar -zxf "${MG_TARBALL}" --directory "${DATA_DIR}" || exit_error "Cannot decompress the must-gather tarball"
      chmod a+rx "${DATA_DIR}"

      return 0
    }

    main() {
      while getopts ':hp:t:' OPT; do
        case "${OPT}" in
          h)
            usage
            exit 0
            ;;
          p)
            NTO_IMG="${OPTARG}"
            ;;
          t)
            MG_TARBALL="${OPTARG}"
            ;;
          ?)
            exit_error "invalid argument: ${OPTARG}"
            ;;
        esac
      done
      shift $((OPTIND - 1))

      check_requirements || exit 1

      ${CMD} -v "${DATA_DIR}:${MUST_GATHER_VOL}:z" "${NTO_IMG}" "$@" --must-gather-dir-path "${MUST_GATHER_VOL}"
      echo "" 1>&2
    }

    main "$@"
    ```

3.  Add execute permissions for everyone on this script:

    ``` terminal
    $ chmod a+x run-perf-profile-creator.sh
    ```

4.  Optional: Display the `run-perf-profile-creator.sh` command usage:

    ``` terminal
    $ ./run-perf-profile-creator.sh -h
    ```

    **Expected output**

    ``` terminal
    Wrapper usage:
      run-perf-profile-creator.sh [-h] [-p image][-t path] -- [performance-profile-creator flags]

    Options:
       -h                 help for run-perf-profile-creator.sh
       -p                 Node Tuning Operator image 
       -t                 path to a must-gather tarball 
    A tool that automates creation of Performance Profiles

    Usage:
      performance-profile-creator [flags]

    Flags:
          --disable-ht                        Disable Hyperthreading
      -h, --help                              help for performance-profile-creator
          --info string                       Show cluster information; requires --must-gather-dir-path, ignore the other arguments. [Valid values: log, json] (default "log")
          --mcp-name string                   MCP name corresponding to the target machines (required)
          --must-gather-dir-path string       Must gather directory path (default "must-gather")
          --offlined-cpu-count int            Number of offlined CPUs
          --power-consumption-mode string     The power consumption mode.  [Valid values: default, low-latency, ultra-low-latency] (default "default")
          --profile-name string               Name of the performance profile to be created (default "performance")
          --reserved-cpu-count int            Number of reserved CPUs (required)
          --rt-kernel                         Enable Real Time Kernel (required)
          --split-reserved-cpus-across-numa   Split the Reserved CPUs across NUMA nodes
          --topology-manager-policy string    Kubelet Topology Manager Policy of the performance profile to be created. [Valid values: single-numa-node, best-effort, restricted] (default "restricted")
          --user-level-networking             Run with User level Networking(DPDK) enabled
    ```

    !!! note
        There two types of arguments:
        
        -   Wrapper arguments namely `-h`, `-p` and `-t`
        
        -   PPC arguments

    -   Optional: Specify the Node Tuning Operator image. If not set, the default upstream image is used: `registry.redhat.io/openshift4/ose-cluster-node-tuning-operator:v4.11`.

    -   `-t` is a required wrapper script argument and specifies the path to a `must-gather` tarball.

5.  Run the performance profile creator tool in discovery mode:

    !!! note
        Discovery mode inspects your cluster using the output from `must-gather`. The output produced includes information on:
        
        -   The NUMA cell partitioning with the allocated CPU IDs
        
        -   Whether hyperthreading is enabled
        
        Using this information you can set appropriate values for some of the arguments supplied to the Performance Profile Creator tool.

    ``` terminal
    $ ./run-perf-profile-creator.sh -t /must-gather/must-gather.tar.gz -- --info=log
    ```

    !!! note
        The `info` option requires a value which specifies the output format. Possible values are log and JSON. The JSON format is reserved for debugging.

6.  Check the machine config pool:

    ``` terminal
    $ oc get mcp
    ```

    **Example output**

    ``` terminal
    NAME         CONFIG                                                 UPDATED   UPDATING   DEGRADED   MACHINECOUNT   READYMACHINECOUNT   UPDATEDMACHINECOUNT   DEGRADEDMACHINECOUNT   AGE
    master       rendered-master-acd1358917e9f98cbdb599aea622d78b       True      False      False      3              3                   3                     0                      22h
    worker-cnf   rendered-worker-cnf-1d871ac76e1951d32b2fe92369879826   False     True       False      2              1                   1                     0                      22h
    ```

7.  Create a performance profile:

    ``` terminal
    $ ./run-perf-profile-creator.sh -t /must-gather/must-gather.tar.gz -- --mcp-name=worker-cnf --reserved-cpu-count=2 --rt-kernel=true > my-performance-profile.yaml
    ```

    !!! note
        The Performance Profile Creator arguments are shown in the Performance Profile Creator arguments table. The following arguments are required:
        
        -   `reserved-cpu-count`
        
        -   `mcp-name`
        
        -   `rt-kernel`
        
        The `mcp-name` argument in this example is set to `worker-cnf` based on the output of the command `oc get mcp`. For single-node OpenShift use `--mcp-name=master`.

8.  Review the created YAML file:

    ``` terminal
    $ cat my-performance-profile.yaml
    ```

    **Example output**

    ``` terminal
    apiVersion: performance.openshift.io/v2
    kind: PerformanceProfile
    metadata:
      name: performance
    spec:
      cpu:
        isolated: 1-39,41-79
        reserved: 0,40
      nodeSelector:
        node-role.kubernetes.io/worker-cnf: ""
      numa:
        topologyPolicy: restricted
      realTimeKernel:
        enabled: false
    ```

9.  Apply the generated profile:

    !!! note
        Install the Node Tuning Operator before applying the profile.

    ``` terminal
    $ oc apply -f my-performance-profile.yaml
    ```

### Performance Profile Creator arguments {#performance-profile-creator-arguments_cnf-create-performance-profiles}

+-----------------------------------+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| Argument                          | Description                                                                                                                                                                              |
+===================================+==========================================================================================================================================================================================+
| `disable-ht`                      | Disable hyperthreading.                                                                                                                                                                  |
|                                   |                                                                                                                                                                                          |
|                                   | Possible values: `true` or `false`.                                                                                                                                                      |
|                                   |                                                                                                                                                                                          |
|                                   | Default: `false`.                                                                                                                                                                        |
|                                   |                                                                                                                                                                                          |
|                                   | !!! warning                                                                                                                                                                              |
|                                   |     If this argument is set to `true` you should not disable hyperthreading in the BIOS. Disabling hyperthreading is accomplished with a kernel command line argument.                   |
+-----------------------------------+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| `info`                            | This captures cluster information and is used in discovery mode only. Discovery mode also requires the `must-gather-dir-path` argument. If any other arguments are set they are ignored. |
|                                   |                                                                                                                                                                                          |
|                                   | Possible values:                                                                                                                                                                         |
|                                   |                                                                                                                                                                                          |
|                                   | -   `log`                                                                                                                                                                                |
|                                   |                                                                                                                                                                                          |
|                                   | -   `JSON`                                                                                                                                                                               |
|                                   |                                                                                                                                                                                          |
|                                   |     !!! note                                                                                                                                                                             |
|                                   |         These options define the output format with the JSON format being reserved for debugging.                                                                                        |
|                                   |                                                                                                                                                                                          |
|                                   | Default: `log`.                                                                                                                                                                          |
+-----------------------------------+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| `mcp-name`                        | MCP name for example `worker-cnf` corresponding to the target machines. This parameter is required.                                                                                      |
+-----------------------------------+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| `must-gather-dir-path`            | Must gather directory path. This parameter is required.                                                                                                                                  |
|                                   |                                                                                                                                                                                          |
|                                   | When the user runs the tool with the wrapper script `must-gather` is supplied by the script itself and the user must not specify it.                                                     |
+-----------------------------------+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| `offlined-cpu-count`              | Number of offlined CPUs.                                                                                                                                                                 |
|                                   |                                                                                                                                                                                          |
|                                   | !!! note                                                                                                                                                                                 |
|                                   |     This must be a natural number greater than 0. If not enough logical processors are offlined then error messages are logged. The messages are:                                        |
|                                   |                                                                                                                                                                                          |
|                                   |     ``` terminal                                                                                                                                                                         |
|                                   |     Error: failed to compute the reserved and isolated CPUs: please ensure that reserved-cpu-count plus offlined-cpu-count should be in the range [0,1]                                  |
|                                   |     ```                                                                                                                                                                                  |
|                                   |                                                                                                                                                                                          |
|                                   |     ``` terminal                                                                                                                                                                         |
|                                   |     Error: failed to compute the reserved and isolated CPUs: please specify the offlined CPU count in the range [0,1]                                                                    |
|                                   |     ```                                                                                                                                                                                  |
+-----------------------------------+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| `power-consumption-mode`          | The power consumption mode.                                                                                                                                                              |
|                                   |                                                                                                                                                                                          |
|                                   | Possible values:                                                                                                                                                                         |
|                                   |                                                                                                                                                                                          |
|                                   | -   `default`: CPU partitioning with enabled power management and basic low-latency.                                                                                                     |
|                                   |                                                                                                                                                                                          |
|                                   | -   `low-latency`: Enhanced measures to improve latency figures.                                                                                                                         |
|                                   |                                                                                                                                                                                          |
|                                   | -   `ultra-low-latency`: Priority given to optimal latency, at the expense of power management.                                                                                          |
|                                   |                                                                                                                                                                                          |
|                                   | Default: `default`.                                                                                                                                                                      |
+-----------------------------------+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| `profile-name`                    | Name of the performance profile to create. Default: `performance`.                                                                                                                       |
+-----------------------------------+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| `reserved-cpu-count`              | Number of reserved CPUs. This parameter is required.                                                                                                                                     |
|                                   |                                                                                                                                                                                          |
|                                   | !!! note                                                                                                                                                                                 |
|                                   |     This must be a natural number. A value of 0 is not allowed.                                                                                                                          |
+-----------------------------------+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| `rt-kernel`                       | Enable real-time kernel. This parameter is required.                                                                                                                                     |
|                                   |                                                                                                                                                                                          |
|                                   | Possible values: `true` or `false`.                                                                                                                                                      |
+-----------------------------------+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| `split-reserved-cpus-across-numa` | Split the reserved CPUs across NUMA nodes.                                                                                                                                               |
|                                   |                                                                                                                                                                                          |
|                                   | Possible values: `true` or `false`.                                                                                                                                                      |
|                                   |                                                                                                                                                                                          |
|                                   | Default: `false`.                                                                                                                                                                        |
+-----------------------------------+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| `topology-manager-policy`         | Kubelet Topology Manager policy of the performance profile to be created.                                                                                                                |
|                                   |                                                                                                                                                                                          |
|                                   | Possible values:                                                                                                                                                                         |
|                                   |                                                                                                                                                                                          |
|                                   | -   `single-numa-node`                                                                                                                                                                   |
|                                   |                                                                                                                                                                                          |
|                                   | -   `best-effort`                                                                                                                                                                        |
|                                   |                                                                                                                                                                                          |
|                                   | -   `restricted`                                                                                                                                                                         |
|                                   |                                                                                                                                                                                          |
|                                   | Default: `restricted`.                                                                                                                                                                   |
+-----------------------------------+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| `user-level-networking`           | Run with user level networking (DPDK) enabled.                                                                                                                                           |
|                                   |                                                                                                                                                                                          |
|                                   | Possible values: `true` or `false`.                                                                                                                                                      |
|                                   |                                                                                                                                                                                          |
|                                   | Default: `false`.                                                                                                                                                                        |
+-----------------------------------+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+

: **Table 1: Performance Profile Creator arguments**

## Reference performance profiles {#cnf-create-performance-profiles-reference}

### A performance profile template for clusters that use OVS-DPDK on OpenStack {#installation-openstack-ovs-dpdk-performance-profile_cnf-create-performance-profiles}

To maximize machine performance in a cluster that uses Open vSwitch with the Data Plane Development Kit (OVS-DPDK) on Red Hat OpenStack Platform (RHOSP), you can use a performance profile.

You can use the following performance profile template to create a profile for your deployment.

**A performance profile template for clusters that use OVS-DPDK**

``` yaml
apiVersion: performance.openshift.io/v2
kind: PerformanceProfile
metadata:
  name: cnf-performanceprofile
spec:
  additionalKernelArgs:
    - nmi_watchdog=0
    - audit=0
    - mce=off
    - processor.max_cstate=1
    - idle=poll
    - intel_idle.max_cstate=0
    - default_hugepagesz=1GB
    - hugepagesz=1G
    - intel_iommu=on
  cpu:
    isolated: <CPU_ISOLATED>
    reserved: <CPU_RESERVED>
  hugepages:
    defaultHugepagesSize: 1G
    pages:
      - count: <HUGEPAGES_COUNT>
        node: 0
        size: 1G
  nodeSelector:
    node-role.kubernetes.io/worker: ''
  realTimeKernel:
    enabled: false
    globallyDisableIrqLoadBalancing: true
```

Insert values that are appropriate for your configuration for the `CPU_ISOLATED`, `CPU_RESERVED`, and `HUGEPAGES_COUNT` keys.

To learn how to create and use performance profiles, see the "Creating a performance profile" page in the "Scalability and performance" section of the OpenShift Container Platform documentation.

## Additional resources {#cnf-create-performance-profiles-additional-resources}

-   For more information about the `must-gather` tool, see [Gathering data about your cluster](../support/gathering-cluster-data/#nodes-nodes-managing).
