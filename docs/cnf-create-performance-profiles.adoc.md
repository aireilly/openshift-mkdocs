# Creating a performance profile

Learn about the Performance Profile Creator (PPC) and how you can use it to create a performance profile.

## About the Performance Profile Creator

The Performance Profile Creator (PPC) is a command-line tool, delivered with the Node Tuning Operator, used to create the performance profile. The tool consumes `must-gather` data from the cluster and several user-supplied profile arguments. The PPC generates a performance profile that is appropriate for your hardware and topology.

The tool is run by one of the following methods:

-   Invoking `podman`

-   Calling a wrapper script

### Gathering data about your cluster using `must-gather`

The Performance Profile Creator (PPC) tool requires `must-gather` data. As a cluster administrator, run `must-gather` to capture information about your cluster.

!!! note
    In earlier versions of {product-title}, the Performance Addon Operator provided automatic, low latency performance tuning for applications. In {product-title} 4.11, these functions are part of the Node Tuning Operator. However, you must still use the performance-addon-operator-must-gather image when running the must-gather command.

In earlier versions of {product-title}, the Performance Addon Operator provided automatic, low latency performance tuning for applications. In {product-title} 4.11, these functions are part of the Node Tuning Operator. However, you must still use the `performance-addon-operator-must-gather` image when running the `must-gather` command.

-   Access to the cluster as a user with the `cluster-admin` role.

-   Access to the Performance Addon Operator `must gather` image.

-   The OpenShift CLI (`oc`) installed.

1.  Navigate to the directory where you want to store the `must-gather` data.

2.  Run `must-gather` on your cluster:

    ``` terminal
    $ oc adm must-gather --image=<PAO_must_gather_image> --dest-dir=<dir>
    ```

    !!! note
        must-gather must be run with the performance-addon-operator-must-gather image. The output can optionally be compressed. Compressed output is required if you are running the Performance Profile Creator wrapper script.
    `must-gather` must be run with the `performance-addon-operator-must-gather` image. The output can optionally be compressed. Compressed output is required if you are running the Performance Profile Creator wrapper script.

    **Example**

    ``` terminal
    $ oc adm must-gather --image=registry.redhat.io/openshift4/performance-addon-operator-must-gather-rhel8:v{product-version} --dest-dir=<path_to_must-gather>/must-gather
    ```

3.  Create a compressed file from the `must-gather` directory:

    ``` terminal
    $ tar cvaf must-gather.tar.gz must-gather/
    ```

### Running the Performance Profile Creator using podman

As a cluster administrator, you can run `podman` and the Performance Profile Creator to create a performance profile.

-   Access to the cluster as a user with the `cluster-admin` role.

-   A cluster installed on bare-metal hardware.

-   A node with `podman` and OpenShift CLI (`oc`) installed.

-   Access to the Node Tuning Operator image.

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
    $ podman run --rm --entrypoint performance-profile-creator registry.redhat.io/openshift4/ose-cluster-node-tuning-operator:v{product-version} -h
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
        Discovery mode inspects your cluster using the output from must-gather. The output produced includes information on:The NUMA cell partitioning with the allocated CPU idsWhether hyperthreading is enabledUsing this information you can set appropriate values for some of the arguments supplied to the Performance Profile Creator tool.
    Discovery mode inspects your cluster using the output from `must-gather`. The output produced includes information on:

    -   The NUMA cell partitioning with the allocated CPU ids

    -   Whether hyperthreading is enabled

    Using this information you can set appropriate values for some of the arguments supplied to the Performance Profile Creator tool.

    ``` terminal
    $ podman run --entrypoint performance-profile-creator -v <path_to_must-gather>/must-gather:/must-gather:z registry.redhat.io/openshift4/ose-cluster-node-tuning-operator:v{product-version} --info log --must-gather-dir-path /must-gather
    ```

    !!! note
        This command uses the performance profile creator as a new entry point to podman. It maps the must-gather data for the host into the container image and invokes the required user-supplied profile arguments to produce the my-performance-profile.yaml file.The -v option can be the path to either:The must-gather output directoryAn existing directory containing the must-gather decompressed tarballThe info option requires a value which specifies the output format. Possible values are log and JSON. The JSON format is reserved for debugging.
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
        The Performance Profile Creator arguments are shown in the Performance Profile Creator arguments table. The following arguments are required:reserved-cpu-countmcp-namert-kernelThe mcp-name argument in this example is set to worker-cnf based on the output of the command oc get mcp. For single-node OpenShift use --mcp-name=master.
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

#### How to run `podman` to create a performance profile

The following example illustrates how to run `podman` to create a performance profile with 20 reserved CPUs that are to be split across the NUMA nodes.

Node hardware configuration:

-   80 CPUs

-   Hyperthreading enabled

-   Two NUMA nodes

-   Even numbered CPUs run on NUMA node 0 and odd numbered CPUs run on NUMA node 1

Run `podman` to create the performance profile:

``` terminal
$ podman run --entrypoint performance-profile-creator -v /must-gather:/must-gather:z registry.redhat.io/openshift4/ose-cluster-node-tuning-operator:v{product-version} --mcp-name=worker-cnf --reserved-cpu-count=20 --rt-kernel=true --split-reserved-cpus-across-numa=true --must-gather-dir-path /must-gather > my-performance-profile.yaml
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

!!! warning
    In this case, 10 CPUs are reserved on NUMA node 0 and 10 are reserved on NUMA node 1.

In this case, 10 CPUs are reserved on NUMA node 0 and 10 are reserved on NUMA node 1.

### Running the Performance Profile Creator wrapper script

The performance profile wrapper script simplifies the running of the Performance Profile Creator (PPC) tool. It hides the complexities associated with running `podman` and specifying the mapping directories and it enables the creation of the performance profile.

-   Access to the Node Tuning Operator image.

-   Access to the `must-gather` tarball.

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

    NTO_IMG="registry.redhat.io/openshift4/ose-cluster-node-tuning-operator:v{product-version}"
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
        There two types of arguments:Wrapper arguments namely -h, -p and -tPPC arguments
    There two types of arguments:

    -   Wrapper arguments namely `-h`, `-p` and `-t`

    -   PPC arguments

    -   Optional: Specify the Node Tuning Operator image. If not set, the default upstream image is used: `registry.redhat.io/openshift4/ose-cluster-node-tuning-operator:v{product-version}`.

    -   `-t` is a required wrapper script argument and specifies the path to a `must-gather` tarball.

5.  Run the performance profile creator tool in discovery mode:

    !!! note
        Discovery mode inspects your cluster using the output from must-gather. The output produced includes information on:The NUMA cell partitioning with the allocated CPU IDsWhether hyperthreading is enabledUsing this information you can set appropriate values for some of the arguments supplied to the Performance Profile Creator tool.
    Discovery mode inspects your cluster using the output from `must-gather`. The output produced includes information on:

    -   The NUMA cell partitioning with the allocated CPU IDs

    -   Whether hyperthreading is enabled

    Using this information you can set appropriate values for some of the arguments supplied to the Performance Profile Creator tool.

    ``` terminal
    $ ./run-perf-profile-creator.sh -t /must-gather/must-gather.tar.gz -- --info=log
    ```

    !!! note
        The info option requires a value which specifies the output format. Possible values are log and JSON. The JSON format is reserved for debugging.
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
        The Performance Profile Creator arguments are shown in the Performance Profile Creator arguments table. The following arguments are required:reserved-cpu-countmcp-namert-kernelThe mcp-name argument in this example is set to worker-cnf based on the output of the command oc get mcp. For single-node OpenShift use --mcp-name=master.
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
    Install the Node Tuning Operator before applying the profile.

    ``` terminal
    $ oc apply -f my-performance-profile.yaml
    ```

### Performance Profile Creator arguments

<table><caption>Performance Profile Creator arguments</caption><colgroup><col style="width: 30%" /><col style="width: 70%" /></colgroup><thead><tr class="header"><th style="text-align: left;">Argument</th><th style="text-align: left;">Description</th></tr></thead><tbody><tr class="odd"><td style="text-align: left;"><p><code>disable-ht</code></p></td><td style="text-align: left;"><p>Disable hyperthreading.</p><p>Possible values: <code>true</code> or <code>false</code>.</p><p>Default: <code>false</code>.</p><div class="warning">!!! warning
    If this argument is set to true you should not disable hyperthreading in the BIOS. Disabling hyperthreading is accomplished with a kernel command line argument.<p>If this argument is set to <code>true</code> you should not disable hyperthreading in the BIOS. Disabling hyperthreading is accomplished with a kernel command line argument.</p></div></td></tr><tr class="even"><td style="text-align: left;"><p><code>info</code></p></td><td style="text-align: left;"><p>This captures cluster information and is used in discovery mode only. Discovery mode also requires the <code>must-gather-dir-path</code> argument. If any other arguments are set they are ignored.</p><p>Possible values:</p><ul><li><p><code>log</code></p></li><li><p><code>JSON</code></p><div class="note">!!! note
    These options define the output format with the JSON format being reserved for debugging.<p>These options define the output format with the JSON format being reserved for debugging.</p></div></li></ul><p>Default: <code>log</code>.</p></td></tr><tr class="odd"><td style="text-align: left;"><p><code>mcp-name</code></p></td><td style="text-align: left;"><p>MCP name for example <code>worker-cnf</code> corresponding to the target machines. This parameter is required.</p></td></tr><tr class="even"><td style="text-align: left;"><p><code>must-gather-dir-path</code></p></td><td style="text-align: left;"><p>Must gather directory path. This parameter is required.</p><p>When the user runs the tool with the wrapper script <code>must-gather</code> is supplied by the script itself and the user must not specify it.</p></td></tr><tr class="odd"><td style="text-align: left;"><p><code>offlined-cpu-count</code></p></td><td style="text-align: left;"><p>Number of offlined CPUs.</p><div class="note">!!! note
    This must be a natural number greater than 0. If not enough logical processors are offlined then error messages are logged. The messages are:<p>This must be a natural number greater than 0. If not enough logical processors are offlined then error messages are logged. The messages are:</p><pre class="terminal"><code>Error: failed to compute the reserved and isolated CPUs: please ensure that reserved-cpu-count plus offlined-cpu-count should be in the range [0,1]</code></pre><pre class="terminal"><code>Error: failed to compute the reserved and isolated CPUs: please specify the offlined CPU count in the range [0,1]</code></pre></div></td></tr><tr class="even"><td style="text-align: left;"><p><code>power-consumption-mode</code></p></td><td style="text-align: left;"><p>The power consumption mode.</p><p>Possible values:</p><ul><li><p><code>default</code>: CPU partitioning with enabled power management and basic low-latency.</p></li><li><p><code>low-latency</code>: Enhanced measures to improve latency figures.</p></li><li><p><code>ultra-low-latency</code>: Priority given to optimal latency, at the expense of power management.</p></li></ul><p>Default: <code>default</code>.</p></td></tr><tr class="odd"><td style="text-align: left;"><p><code>profile-name</code></p></td><td style="text-align: left;"><p>Name of the performance profile to create. Default: <code>performance</code>.</p></td></tr><tr class="even"><td style="text-align: left;"><p><code>reserved-cpu-count</code></p></td><td style="text-align: left;"><p>Number of reserved CPUs. This parameter is required.</p><div class="note">!!! note
    This must be a natural number. A value of 0 is not allowed.<p>This must be a natural number. A value of 0 is not allowed.</p></div></td></tr><tr class="odd"><td style="text-align: left;"><p><code>rt-kernel</code></p></td><td style="text-align: left;"><p>Enable real-time kernel. This parameter is required.</p><p>Possible values: <code>true</code> or <code>false</code>.</p></td></tr><tr class="even"><td style="text-align: left;"><p><code>split-reserved-cpus-across-numa</code></p></td><td style="text-align: left;"><p>Split the reserved CPUs across NUMA nodes.</p><p>Possible values: <code>true</code> or <code>false</code>.</p><p>Default: <code>false</code>.</p></td></tr><tr class="odd"><td style="text-align: left;"><p><code>topology-manager-policy</code></p></td><td style="text-align: left;"><p>Kubelet Topology Manager policy of the performance profile to be created.</p><p>Possible values:</p><ul><li><p><code>single-numa-node</code></p></li><li><p><code>best-effort</code></p></li><li><p><code>restricted</code></p></li></ul><p>Default: <code>restricted</code>.</p></td></tr><tr class="even"><td style="text-align: left;"><p><code>user-level-networking</code></p></td><td style="text-align: left;"><p>Run with user level networking (DPDK) enabled.</p><p>Possible values: <code>true</code> or <code>false</code>.</p><p>Default: <code>false</code>.</p></td></tr></tbody></table>

Performance Profile Creator arguments

## Reference performance profiles

### A performance profile template for clusters that use OVS-DPDK on OpenStack

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

To learn how to create and use performance profiles, see the "Creating a performance profile" page in the "Scalability and performance" section of the {product-title} documentation.

## Additional resources

-   For more information about the `must-gather` tool, see [Gathering data about your cluster](../support/gathering-cluster-data.xml#nodes-nodes-managing).
