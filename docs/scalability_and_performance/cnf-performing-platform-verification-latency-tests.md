# Performing latency tests for platform verification

You can use the Cloud-native Network Functions (CNF) tests image to run latency tests on a CNF-enabled OpenShift Container Platform cluster, where all the components required for running CNF workloads are installed. Run the latency tests to validate node tuning for your workload.

The `cnf-tests` container image is available at `registry.redhat.io/openshift4/cnf-tests-rhel8:v4.11`.

!!! important
    The `cnf-tests` image also includes several tests that are not supported by Red Hat at this time. Only the latency tests are supported by Red Hat.

## Prerequisites for running latency tests {#cnf-latency-tests-prerequisites_cnf-latency-tests}

Your cluster must meet the following requirements before you can run the latency tests:

1.  You have configured a performance profile with the Node Tuning Operator.

2.  You have applied all the required CNF configurations in the cluster.

3.  You have a pre-existing `MachineConfigPool` CR applied in the cluster. The default worker pool is `worker-cnf`.

-   For more information about creating the cluster performance profile, see [Provisioning a worker with real-time capabilities](../cnf-low-latency-tuning/#node-tuning-operator-provisioning-worker-with-real-time-capabilities_cnf-master).

## About discovery mode for latency tests {#discovery-mode_cnf-latency-tests}

Use discovery mode to validate the functionality of a cluster without altering its configuration. Existing environment configurations are used for the tests. The tests can find the configuration items needed and use those items to execute the tests. If resources needed to run a specific test are not found, the test is skipped, providing an appropriate message to the user. After the tests are finished, no cleanup of the pre-configured configuration items is done, and the test environment can be immediately used for another test run.

!!! important
    When running the latency tests, **always** run the tests with `-e DISCOVERY_MODE=true` and `-ginkgo.focus` set to the appropriate latency test. If you do not run the latency tests in discovery mode, your existing live cluster performance profile configuration will be modified by the test run.

**Limiting the nodes used during tests**

The nodes on which the tests are executed can be limited by specifying a `NODES_SELECTOR` environment variable, for example, `-e NODES_SELECTOR=node-role.kubernetes.io/worker-cnf`. Any resources created by the test are limited to nodes with matching labels.

!!! note
    If you want to override the default worker pool, pass the `-e ROLE_WORKER_CNF=<custom_worker_pool>` variable to the command specifying an appropriate label.

## Measuring latency {#cnf-measuring-latency_cnf-latency-tests}

The `cnf-tests` image uses three tools to measure the latency of the system:

-   `hwlatdetect`

-   `cyclictest`

-   `oslat`

Each tool has a specific use. Use the tools in sequence to achieve reliable test results.

hwlatdetect

:   Measures the baseline that the bare-metal hardware can achieve. Before proceeding with the next latency test, ensure that the latency reported by `hwlatdetect` meets the required threshold because you cannot fix hardware latency spikes by operating system tuning.

cyclictest

:   Verifies the real-time kernel scheduler latency after `hwlatdetect` passes validation. The `cyclictest` tool schedules a repeated timer and measures the difference between the desired and the actual trigger times. The difference can uncover basic issues with the tuning caused by interrupts or process priorities. The tool must run on a real-time kernel.

oslat

:   Behaves similarly to a CPU-intensive DPDK application and measures all the interruptions and disruptions to the busy loop that simulates CPU heavy data processing.

The tests introduce the following environment variables:

+-------------------------------+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| Environment variables         | Description                                                                                                                                                                                                                                                                                                                                          |
+===============================+======================================================================================================================================================================================================================================================================================================================================================+
| `LATENCY_TEST_DELAY`          | Specifies the amount of time in seconds after which the test starts running. You can use the variable to allow the CPU manager reconcile loop to update the default CPU pool. The default value is 0.                                                                                                                                                |
+-------------------------------+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| `LATENCY_TEST_CPUS`           | Specifies the number of CPUs that the pod running the latency tests uses. If you do not set the variable, the default configuration includes all isolated CPUs.                                                                                                                                                                                      |
+-------------------------------+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| `LATENCY_TEST_RUNTIME`        | Specifies the amount of time in seconds that the latency test must run. The default value is 300 seconds.                                                                                                                                                                                                                                            |
+-------------------------------+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| `HWLATDETECT_MAXIMUM_LATENCY` | Specifies the maximum acceptable hardware latency in microseconds for the workload and operating system. If you do not set the value of `HWLATDETECT_MAXIMUM_LATENCY` or `MAXIMUM_LATENCY`, the tool compares the default expected threshold (20??s) and the actual maximum latency in the tool itself. Then, the test fails or succeeds accordingly. |
+-------------------------------+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| `CYCLICTEST_MAXIMUM_LATENCY`  | Specifies the maximum latency in microseconds that all threads expect before waking up during the `cyclictest` run. If you do not set the value of `CYCLICTEST_MAXIMUM_LATENCY` or `MAXIMUM_LATENCY`, the tool skips the comparison of the expected and the actual maximum latency.                                                                  |
+-------------------------------+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| `OSLAT_MAXIMUM_LATENCY`       | Specifies the maximum acceptable latency in microseconds for the `oslat` test results. If you do not set the value of `OSLAT_MAXIMUM_LATENCY` or `MAXIMUM_LATENCY`, the tool skips the comparison of the expected and the actual maximum latency.                                                                                                    |
+-------------------------------+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| `MAXIMUM_LATENCY`             | Unified variable that specifies the maximum acceptable latency in microseconds. Applicable for all available latency tools.                                                                                                                                                                                                                          |
+-------------------------------+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+

: **Table 1: Latency test environment variables**

!!! note
    Variables that are specific to a latency tool take precedence over unified variables. For example, if `OSLAT_MAXIMUM_LATENCY` is set to 30 microseconds and `MAXIMUM_LATENCY` is set to 10 microseconds, the `oslat` test will run with maximum acceptable latency of 30 microseconds.

## Running the latency tests {#cnf-performing-end-to-end-tests-running-the-tests_cnf-latency-tests}

Run the cluster latency tests to validate node tuning for your Cloud-native Network Functions (CNF) workload.

!!! important
    **Always** run the latency tests with `DISCOVERY_MODE=true` set. If you don't, the test suite will make changes to the running cluster configuration.
!!! note
    When executing `podman` commands as a non-root or non-privileged user, mounting paths can fail with `permission denied` errors. To make the `podman` command work, append `:Z` to the volumes creation; for example, `-v $(pwd)/:/kubeconfig:Z`. This allows `podman` to do the proper SELinux relabeling.

**Procedure**

1.  Open a shell prompt in the directory containing the `kubeconfig` file.

    You provide the test image with a `kubeconfig` file in current directory and its related `$KUBECONFIG` environment variable, mounted through a volume. This allows the running container to use the `kubeconfig` file from inside the container.

2.  Run the latency tests by entering the following command:

    ``` terminal
    $ podman run -v $(pwd)/:/kubeconfig:Z -e KUBECONFIG=/kubeconfig/kubeconfig \
    -e DISCOVERY_MODE=true registry.redhat.io/openshift4/cnf-tests-rhel8:v4.11 \
    /usr/bin/test-run.sh -ginkgo.focus="\[performance\]\ Latency\ Test"
    ```

3.  Optional: Append `-ginkgo.dryRun` to run the latency tests in dry-run mode. This is useful for checking what the tests run.

4.  Optional: Append `-ginkgo.v` to run the tests with increased verbosity.

5.  Optional: To run the latency tests against a specific performance profile, run the following command, substituting appropriate values:

    ``` terminal
    $ podman run -v $(pwd)/:/kubeconfig:Z -e KUBECONFIG=/kubeconfig/kubeconfig \
    -e LATENCY_TEST_RUN=true -e LATENCY_TEST_RUNTIME=600 -e OSLAT_MAXIMUM_LATENCY=20 \
    -e PERF_TEST_PROFILE=<performance_profile> registry.redhat.io/openshift4/cnf-tests-rhel8:v4.11 \
    /usr/bin/test-run.sh -ginkgo.focus="[performance]\ Latency\ Test"
    ```

    where:

    &lt;performance\_profile&gt;

    :   Is the name of the performance profile you want to run the latency tests against.

    !!! important
        For valid latency tests results, run the tests for at least 12 hours.

### Running hwlatdetect {#cnf-performing-end-to-end-tests-running-hwlatdetect_cnf-latency-tests}

The `hwlatdetect` tool is available in the `rt-kernel` package with a regular subscription of Red Hat Enterprise Linux (RHEL) 8.x.

!!! important
    **Always** run the latency tests with `DISCOVERY_MODE=true` set. If you don't, the test suite will make changes to the running cluster configuration.
!!! note
    When executing `podman` commands as a non-root or non-privileged user, mounting paths can fail with `permission denied` errors. To make the `podman` command work, append `:Z` to the volumes creation; for example, `-v $(pwd)/:/kubeconfig:Z`. This allows `podman` to do the proper SELinux relabeling.

**Prerequisites**

-   You have installed the real-time kernel in the cluster.

-   You have logged in to `registry.redhat.io` with your Customer Portal credentials.

**Procedure**

-   To run the `hwlatdetect` tests, run the following command, substituting variable values as appropriate:

    ``` terminal
    $ podman run -v $(pwd)/:/kubeconfig:Z -e KUBECONFIG=/kubeconfig/kubeconfig \
    -e LATENCY_TEST_RUN=true -e DISCOVERY_MODE=true -e ROLE_WORKER_CNF=worker-cnf \
    -e LATENCY_TEST_RUNTIME=600 -e MAXIMUM_LATENCY=20 \
    registry.redhat.io/openshift4/cnf-tests-rhel8:v4.11 \
    /usr/bin/test-run.sh -ginkgo.v -ginkgo.focus="hwlatdetect"
    ```

    The `hwlatdetect` test runs for 10 minutes (600 seconds). The test runs successfully when the maximum observed latency is lower than `MAXIMUM_LATENCY` (20 ??s).

    If the results exceed the latency threshold, the test fails.

    !!! important
        For valid results, the test should run for at least 12 hours.

    **Example failure output**

    ``` terminal
    running /usr/bin/cnftests -ginkgo.v -ginkgo.focus=hwlatdetect
    I0908 15:25:20.023712      27 request.go:601] Waited for 1.046586367s due to client-side throttling, not priority and fairness, request: GET:https://api.hlxcl6.lab.eng.tlv2.redhat.com:6443/apis/imageregistry.operator.openshift.io/v1?timeout=32s
    Running Suite: CNF Features e2e integration tests
    =================================================
    Random Seed: 1662650718
    Will run 1 of 194 specs

    [...]

    ??? Failure [283.574 seconds]
    [performance] Latency Test
    /remote-source/app/vendor/github.com/openshift/cluster-node-tuning-operator/test/e2e/performanceprofile/functests/4_latency/latency.go:62
      with the hwlatdetect image
      /remote-source/app/vendor/github.com/openshift/cluster-node-tuning-operator/test/e2e/performanceprofile/functests/4_latency/latency.go:228
        should succeed [It]
        /remote-source/app/vendor/github.com/openshift/cluster-node-tuning-operator/test/e2e/performanceprofile/functests/4_latency/latency.go:236

        Log file created at: 2022/09/08 15:25:27
        Running on machine: hwlatdetect-b6n4n
        Binary: Built with gc go1.17.12 for linux/amd64
        Log line format: [IWEF]mmdd hh:mm:ss.uuuuuu threadid file:line] msg
        I0908 15:25:27.160620       1 node.go:39] Environment information: /proc/cmdline: BOOT_IMAGE=(hd1,gpt3)/ostree/rhcos-c6491e1eedf6c1f12ef7b95e14ee720bf48359750ac900b7863c625769ef5fb9/vmlinuz-4.18.0-372.19.1.el8_6.x86_64 random.trust_cpu=on console=tty0 console=ttyS0,115200n8 ignition.platform.id=metal ostree=/ostree/boot.1/rhcos/c6491e1eedf6c1f12ef7b95e14ee720bf48359750ac900b7863c625769ef5fb9/0 ip=dhcp root=UUID=5f80c283-f6e6-4a27-9b47-a287157483b2 rw rootflags=prjquota boot=UUID=773bf59a-bafd-48fc-9a87-f62252d739d3 skew_tick=1 nohz=on rcu_nocbs=0-3 tuned.non_isolcpus=0000ffff,ffffffff,fffffff0 systemd.cpu_affinity=4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79 intel_iommu=on iommu=pt isolcpus=managed_irq,0-3 nohz_full=0-3 tsc=nowatchdog nosoftlockup nmi_watchdog=0 mce=off skew_tick=1 rcutree.kthread_prio=11 + +
        I0908 15:25:27.160830       1 node.go:46] Environment information: kernel version 4.18.0-372.19.1.el8_6.x86_64
        I0908 15:25:27.160857       1 main.go:50] running the hwlatdetect command with arguments [/usr/bin/hwlatdetect --threshold 1 --hardlimit 1 --duration 100 --window 10000000us --width 950000us]
        F0908 15:27:10.603523       1 main.go:53] failed to run hwlatdetect command; out: hwlatdetect:  test duration 100 seconds
           detector: tracer
           parameters:
                Latency threshold: 1us 
                Sample window:     10000000us
                Sample width:      950000us
             Non-sampling period:  9050000us
                Output File:       None

        Starting test
        test finished
        Max Latency: 326us 
        Samples recorded: 5
        Samples exceeding threshold: 5
        ts: 1662650739.017274507, inner:6, outer:6
        ts: 1662650749.257272414, inner:14, outer:326
        ts: 1662650779.977272835, inner:314, outer:12
        ts: 1662650800.457272384, inner:3, outer:9
        ts: 1662650810.697273520, inner:3, outer:2

    [...]

    JUnit report was created: /junit.xml/cnftests-junit.xml


    Summarizing 1 Failure:

    [Fail] [performance] Latency Test with the hwlatdetect image [It] should succeed
    /remote-source/app/vendor/github.com/openshift/cluster-node-tuning-operator/test/e2e/performanceprofile/functests/4_latency/latency.go:476

    Ran 1 of 194 Specs in 365.797 seconds
    FAIL! -- 0 Passed | 1 Failed | 0 Pending | 193 Skipped
    --- FAIL: TestTest (366.08s)
    FAIL
    ```

    -   You can configure the latency threshold by using the `MAXIMUM_LATENCY` or the `HWLATDETECT_MAXIMUM_LATENCY` environment variables.

    -   The maximum latency value measured during the test.

**Example hwlatdetect test results**

You can capture the following types of results:

-   Rough results that are gathered after each run to create a history of impact on any changes made throughout the test.

-   The combined set of the rough tests with the best results and configuration settings.

**Example of good results**

``` terminal
hwlatdetect: test duration 3600 seconds
detector: tracer
parameters:
Latency threshold: 10us
Sample window: 1000000us
Sample width: 950000us
Non-sampling period: 50000us
Output File: None

Starting test
test finished
Max Latency: Below threshold
Samples recorded: 0
```

The `hwlatdetect` tool only provides output if the sample exceeds the specified threshold.

**Example of bad results**

``` terminal
hwlatdetect: test duration 3600 seconds
detector: tracer
parameters:Latency threshold: 10usSample window: 1000000us
Sample width: 950000usNon-sampling period: 50000usOutput File: None

Starting tests:1610542421.275784439, inner:78, outer:81
ts: 1610542444.330561619, inner:27, outer:28
ts: 1610542445.332549975, inner:39, outer:38
ts: 1610542541.568546097, inner:47, outer:32
ts: 1610542590.681548531, inner:13, outer:17
ts: 1610543033.818801482, inner:29, outer:30
ts: 1610543080.938801990, inner:90, outer:76
ts: 1610543129.065549639, inner:28, outer:39
ts: 1610543474.859552115, inner:28, outer:35
ts: 1610543523.973856571, inner:52, outer:49
ts: 1610543572.089799738, inner:27, outer:30
ts: 1610543573.091550771, inner:34, outer:28
ts: 1610543574.093555202, inner:116, outer:63
```

The output of `hwlatdetect` shows that multiple samples exceed the threshold. However, the same output can indicate different results based on the following factors:

-   The duration of the test

-   The number of CPU cores

-   The host firmware settings

!!! warning
    Before proceeding with the next latency test, ensure that the latency reported by `hwlatdetect` meets the required threshold. Fixing latencies introduced by hardware might require you to contact the system vendor support.
    
    Not all latency spikes are hardware related. Ensure that you tune the host firmware to meet your workload requirements. For more information, see [Setting firmware parameters for system tuning](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux_for_real_time/9/html-single/optimizing_rhel_9_for_real_time_for_low_latency_operation/index#setting-bios-parameters-for-system-tuning_optimizing-RHEL9-for-real-time-for-low-latency-operation).

### Running cyclictest {#cnf-performing-end-to-end-tests-running-cyclictest_cnf-latency-tests}

The `cyclictest` tool measures the real-time kernel scheduler latency on the specified CPUs.

!!! important
    **Always** run the latency tests with `DISCOVERY_MODE=true` set. If you don't, the test suite will make changes to the running cluster configuration.
!!! note
    When executing `podman` commands as a non-root or non-privileged user, mounting paths can fail with `permission denied` errors. To make the `podman` command work, append `:Z` to the volumes creation; for example, `-v $(pwd)/:/kubeconfig:Z`. This allows `podman` to do the proper SELinux relabeling.

**Prerequisites**

-   You have logged in to `registry.redhat.io` with your Customer Portal credentials.

-   You have installed the real-time kernel in the cluster.

-   You have applied a cluster performance profile by using Node Tuning Operator.

**Procedure**

-   To perform the `cyclictest`, run the following command, substituting variable values as appropriate:

    ``` terminal
    $ podman run -v $(pwd)/:/kubeconfig:Z -e KUBECONFIG=/kubeconfig/kubeconfig \
    -e LATENCY_TEST_RUN=true -e DISCOVERY_MODE=true -e ROLE_WORKER_CNF=worker-cnf \
    -e LATENCY_TEST_CPUS=10 -e LATENCY_TEST_RUNTIME=600 -e MAXIMUM_LATENCY=20 \
    registry.redhat.io/openshift4/cnf-tests-rhel8:v4.11 \
    /usr/bin/test-run.sh -ginkgo.v -ginkgo.focus="cyclictest"
    ```

    The command runs the `cyclictest` tool for 10 minutes (600 seconds). The test runs successfully when the maximum observed latency is lower than `MAXIMUM_LATENCY` (in this example, 20 ??s). Latency spikes of 20 ??s and above are generally not acceptable for telco RAN workloads.

    If the results exceed the latency threshold, the test fails.

    !!! important
        For valid results, the test should run for at least 12 hours.

    **Example failure output**

    ``` terminal
    running /usr/bin/cnftests -ginkgo.v -ginkgo.focus=cyclictest
    I0908 13:01:59.193776      27 request.go:601] Waited for 1.046228824s due to client-side throttling, not priority and fairness, request: GET:https://api.compute-1.example.com:6443/apis/packages.operators.coreos.com/v1?timeout=32s
    Running Suite: CNF Features e2e integration tests
    =================================================
    Random Seed: 1662642118
    Will run 1 of 194 specs

    [...]

    Summarizing 1 Failure:

    [Fail] [performance] Latency Test with the cyclictest image [It] should succeed
    /remote-source/app/vendor/github.com/openshift/cluster-node-tuning-operator/test/e2e/performanceprofile/functests/4_latency/latency.go:220

    Ran 1 of 194 Specs in 161.151 seconds
    FAIL! -- 0 Passed | 1 Failed | 0 Pending | 193 Skipped
    --- FAIL: TestTest (161.48s)
    FAIL
    ```

**Example cyclictest results**

The same output can indicate different results for different workloads. For example, spikes up to 18??s are acceptable for 4G DU workloads, but not for 5G DU workloads.

**Example of good results**

``` terminal
running cmd: cyclictest -q -D 10m -p 1 -t 16 -a 2,4,6,8,10,12,14,16,54,56,58,60,62,64,66,68 -h 30 -i 1000 -m
# Histogram
000000 000000   000000  000000  000000  000000  000000  000000  000000  000000  000000  000000  000000  000000  000000  000000  000000
000001 000000   000000  000000  000000  000000  000000  000000  000000  000000  000000  000000  000000  000000  000000  000000  000000
000002 579506   535967  418614  573648  532870  529897  489306  558076  582350  585188  583793  223781  532480  569130  472250  576043
More histogram entries ...
# Total: 000600000 000600000 000600000 000599999 000599999 000599999 000599998 000599998 000599998 000599997 000599997 000599996 000599996 000599995 000599995 000599995
# Min Latencies: 00002 00002 00002 00002 00002 00002 00002 00002 00002 00002 00002 00002 00002 00002 00002 00002
# Avg Latencies: 00002 00002 00002 00002 00002 00002 00002 00002 00002 00002 00002 00002 00002 00002 00002 00002
# Max Latencies: 00005 00005 00004 00005 00004 00004 00005 00005 00006 00005 00004 00005 00004 00004 00005 00004
# Histogram Overflows: 00000 00000 00000 00000 00000 00000 00000 00000 00000 00000 00000 00000 00000 00000 00000 00000
# Histogram Overflow at cycle number:
# Thread 0:
# Thread 1:
# Thread 2:
# Thread 3:
# Thread 4:
# Thread 5:
# Thread 6:
# Thread 7:
# Thread 8:
# Thread 9:
# Thread 10:
# Thread 11:
# Thread 12:
# Thread 13:
# Thread 14:
# Thread 15:
```

**Example of bad results**

``` terminal
running cmd: cyclictest -q -D 10m -p 1 -t 16 -a 2,4,6,8,10,12,14,16,54,56,58,60,62,64,66,68 -h 30 -i 1000 -m
# Histogram
000000 000000   000000  000000  000000  000000  000000  000000  000000  000000  000000  000000  000000  000000  000000  000000  000000
000001 000000   000000  000000  000000  000000  000000  000000  000000  000000  000000  000000  000000  000000  000000  000000  000000
000002 564632   579686  354911  563036  492543  521983  515884  378266  592621  463547  482764  591976  590409  588145  589556  353518
More histogram entries ...
# Total: 000599999 000599999 000599999 000599997 000599997 000599998 000599998 000599997 000599997 000599996 000599995 000599996 000599995 000599995 000599995 000599993
# Min Latencies: 00002 00002 00002 00002 00002 00002 00002 00002 00002 00002 00002 00002 00002 00002 00002 00002
# Avg Latencies: 00002 00002 00002 00002 00002 00002 00002 00002 00002 00002 00002 00002 00002 00002 00002 00002
# Max Latencies: 00493 00387 00271 00619 00541 00513 00009 00389 00252 00215 00539 00498 00363 00204 00068 00520
# Histogram Overflows: 00001 00001 00001 00002 00002 00001 00000 00001 00001 00001 00002 00001 00001 00001 00001 00002
# Histogram Overflow at cycle number:
# Thread 0: 155922
# Thread 1: 110064
# Thread 2: 110064
# Thread 3: 110063 155921
# Thread 4: 110063 155921
# Thread 5: 155920
# Thread 6:
# Thread 7: 110062
# Thread 8: 110062
# Thread 9: 155919
# Thread 10: 110061 155919
# Thread 11: 155918
# Thread 12: 155918
# Thread 13: 110060
# Thread 14: 110060
# Thread 15: 110059 155917
```

### Running oslat {#cnf-performing-end-to-end-tests-running-oslat_cnf-latency-tests}

The `oslat` test simulates a CPU-intensive DPDK application and measures all the interruptions and disruptions to test how the cluster handles CPU heavy data processing.

!!! important
    **Always** run the latency tests with `DISCOVERY_MODE=true` set. If you don't, the test suite will make changes to the running cluster configuration.
!!! note
    When executing `podman` commands as a non-root or non-privileged user, mounting paths can fail with `permission denied` errors. To make the `podman` command work, append `:Z` to the volumes creation; for example, `-v $(pwd)/:/kubeconfig:Z`. This allows `podman` to do the proper SELinux relabeling.

**Prerequisites**

-   You have logged in to `registry.redhat.io` with your Customer Portal credentials.

-   You have applied a cluster performance profile by using the Node Tuning Operator.

**Procedure**

-   To perform the `oslat` test, run the following command, substituting variable values as appropriate:

    ``` terminal
    $ podman run -v $(pwd)/:/kubeconfig:Z -e KUBECONFIG=/kubeconfig/kubeconfig \
    -e LATENCY_TEST_RUN=true -e DISCOVERY_MODE=true -e ROLE_WORKER_CNF=worker-cnf \
    -e LATENCY_TEST_CPUS=7 -e LATENCY_TEST_RUNTIME=600 -e MAXIMUM_LATENCY=20 \
    registry.redhat.io/openshift4/cnf-tests-rhel8:v4.11 \
    /usr/bin/test-run.sh -ginkgo.v -ginkgo.focus="oslat"
    ```

    `LATENCY_TEST_CPUS` specifices the list of CPUs to test with the `oslat` command.

    The command runs the `oslat` tool for 10 minutes (600 seconds). The test runs successfully when the maximum observed latency is lower than `MAXIMUM_LATENCY` (20 ??s).

    If the results exceed the latency threshold, the test fails.

    !!! important
        For valid results, the test should run for at least 12 hours.

    **Example failure output**

    ``` terminal
    running /usr/bin/cnftests -ginkgo.v -ginkgo.focus=oslat
    I0908 12:51:55.999393      27 request.go:601] Waited for 1.044848101s due to client-side throttling, not priority and fairness, request: GET:https://compute-1.example.com:6443/apis/machineconfiguration.openshift.io/v1?timeout=32s
    Running Suite: CNF Features e2e integration tests
    =================================================
    Random Seed: 1662641514
    Will run 1 of 194 specs

    [...]

    ??? Failure [77.833 seconds]
    [performance] Latency Test
    /remote-source/app/vendor/github.com/openshift/cluster-node-tuning-operator/test/e2e/performanceprofile/functests/4_latency/latency.go:62
      with the oslat image
      /remote-source/app/vendor/github.com/openshift/cluster-node-tuning-operator/test/e2e/performanceprofile/functests/4_latency/latency.go:128
        should succeed [It]
        /remote-source/app/vendor/github.com/openshift/cluster-node-tuning-operator/test/e2e/performanceprofile/functests/4_latency/latency.go:153

        The current latency 304 is bigger than the expected one 1 : 

    [...]

    Summarizing 1 Failure:

    [Fail] [performance] Latency Test with the oslat image [It] should succeed
    /remote-source/app/vendor/github.com/openshift/cluster-node-tuning-operator/test/e2e/performanceprofile/functests/4_latency/latency.go:177

    Ran 1 of 194 Specs in 161.091 seconds
    FAIL! -- 0 Passed | 1 Failed | 0 Pending | 193 Skipped
    --- FAIL: TestTest (161.42s)
    FAIL
    ```

    -   In this example, the measured latency is outside the maximum allowed value.

## Generating a latency test failure report {#cnf-performing-end-to-end-tests-test-failure-report_cnf-latency-tests}

Use the following procedures to generate a JUnit latency test output and test failure report.

**Prerequisites**

-   You have installed the OpenShift CLI (`oc`).

-   You have logged in as a user with `cluster-admin` privileges.

**Procedure**

-   Create a test failure report with information about the cluster state and resources for troubleshooting by passing the `--report` parameter with the path to where the report is dumped:

    ``` terminal
    $ podman run -v $(pwd)/:/kubeconfig:Z -v $(pwd)/reportdest:<report_folder_path> \
    -e KUBECONFIG=/kubeconfig/kubeconfig  -e DISCOVERY_MODE=true \
    registry.redhat.io/openshift4/cnf-tests-rhel8:v4.11 \
    /usr/bin/test-run.sh --report <report_folder_path> \
    -ginkgo.focus="\[performance\]\ Latency\ Test"
    ```

    where:

    &lt;report\_folder\_path&gt;

    :   Is the path to the folder where the report is generated.

## Generating a JUnit latency test report {#cnf-performing-end-to-end-tests-junit-test-output_cnf-latency-tests}

Use the following procedures to generate a JUnit latency test output and test failure report.

**Prerequisites**

-   You have installed the OpenShift CLI (`oc`).

-   You have logged in as a user with `cluster-admin` privileges.

**Procedure**

-   Create a JUnit-compliant XML report by passing the `--junit` parameter together with the path to where the report is dumped:

    ``` terminal
    $ podman run -v $(pwd)/:/kubeconfig:Z -v $(pwd)/junitdest:<junit_folder_path> \
    -e KUBECONFIG=/kubeconfig/kubeconfig  -e DISCOVERY_MODE=true \
    registry.redhat.io/openshift4/cnf-tests-rhel8:v4.11 \
    /usr/bin/test-run.sh --junit <junit_folder_path> \
    -ginkgo.focus="\[performance\]\ Latency\ Test"
    ```

    where:

    &lt;junit\_folder\_path&gt;

    :   Is the path to the folder where the junit report is generated

## Running latency tests on a single-node OpenShift cluster {#cnf-performing-end-to-end-tests-running-in-single-node-cluster_cnf-latency-tests}

You can run latency tests on single-node OpenShift clusters.

!!! important
    **Always** run the latency tests with `DISCOVERY_MODE=true` set. If you don't, the test suite will make changes to the running cluster configuration.
!!! note
    When executing `podman` commands as a non-root or non-privileged user, mounting paths can fail with `permission denied` errors. To make the `podman` command work, append `:Z` to the volumes creation; for example, `-v $(pwd)/:/kubeconfig:Z`. This allows `podman` to do the proper SELinux relabeling.

**Prerequisites**

-   You have installed the OpenShift CLI (`oc`).

-   You have logged in as a user with `cluster-admin` privileges.

**Procedure**

-   To run the latency tests on a single-node OpenShift cluster, run the following command:

    ``` terminal
    $ podman run -v $(pwd)/:/kubeconfig:Z -e KUBECONFIG=/kubeconfig/kubeconfig \
    -e DISCOVERY_MODE=true -e ROLE_WORKER_CNF=master \
    registry.redhat.io/openshift4/cnf-tests-rhel8:v4.11 \
    /usr/bin/test-run.sh -ginkgo.focus="\[performance\]\ Latency\ Test"
    ```

    !!! note
        `ROLE_WORKER_CNF=master` is required because master is the only machine pool to which the node belongs. For more information about setting the required `MachineConfigPool` for the latency tests, see \"Prerequisites for running latency tests\".

    After running the test suite, all the dangling resources are cleaned up.

## Running latency tests in a disconnected cluster {#cnf-performing-end-to-end-tests-disconnected-mode_cnf-latency-tests}

The CNF tests image can run tests in a disconnected cluster that is not able to reach external registries. This requires two steps:

1.  Mirroring the `cnf-tests` image to the custom disconnected registry.

2.  Instructing the tests to consume the images from the custom disconnected registry.

**Mirroring the images to a custom registry accessible from the cluster**

A `mirror` executable is shipped in the image to provide the input required by `oc` to mirror the test image to a local registry.

1.  Run this command from an intermediate machine that has access to the cluster and [registry.redhat.io](https://catalog.redhat.com/software/containers/explore):

    ``` terminal
    $ podman run -v $(pwd)/:/kubeconfig:Z -e KUBECONFIG=/kubeconfig/kubeconfig \
    registry.redhat.io/openshift4/cnf-tests-rhel8:v4.11 \
    /usr/bin/mirror -registry <disconnected_registry> | oc image mirror -f -
    ```

    where:

    &lt;disconnected\_registry&gt;

    :   Is the disconnected mirror registry you have configured, for example, `my.local.registry:5000/`.

2.  When you have mirrored the `cnf-tests` image into the disconnected registry, you must override the original registry used to fetch the images when running the tests, for example:

    ``` terminal
    $ podman run -v $(pwd)/:/kubeconfig:Z -e KUBECONFIG=/kubeconfig/kubeconfig \
    -e DISCOVERY_MODE=true -e IMAGE_REGISTRY="<disconnected_registry>" \
    -e CNF_TESTS_IMAGE="cnf-tests-rhel8:v4.11" \
    /usr/bin/test-run.sh -ginkgo.focus="\[performance\]\ Latency\ Test"
    ```

**Configuring the tests to consume images from a custom registry**

You can run the latency tests using a custom test image and image registry using `CNF_TESTS_IMAGE` and `IMAGE_REGISTRY` variables.

-   To configure the latency tests to use a custom test image and image registry, run the following command:

    ``` terminal
    $ podman run -v $(pwd)/:/kubeconfig:Z -e KUBECONFIG=/kubeconfig/kubeconfig \
    -e IMAGE_REGISTRY="<custom_image_registry>" \
    -e CNF_TESTS_IMAGE="<custom_cnf-tests_image>" \
    registry.redhat.io/openshift4/cnf-tests-rhel8:v4.11 /usr/bin/test-run.sh
    ```

    where:

    &lt;custom\_image\_registry&gt;

    :   is the custom image registry, for example, `custom.registry:5000/`.

    &lt;custom\_cnf-tests\_image&gt;

    :   is the custom cnf-tests image, for example, `custom-cnf-tests-image:latest`.

**Mirroring images to the cluster internal registry**

OpenShift Container Platform provides a built-in container image registry, which runs as a standard workload on the cluster.

**Procedure**

1.  Gain external access to the registry by exposing it with a route:

    ``` terminal
    $ oc patch configs.imageregistry.operator.openshift.io/cluster --patch '{"spec":{"defaultRoute":true}}' --type=merge
    ```

2.  Fetch the registry endpoint by running the following command:

    ``` terminal
    $ REGISTRY=$(oc get route default-route -n openshift-image-registry --template='{{ .spec.host }}')
    ```

3.  Create a namespace for exposing the images:

    ``` terminal
    $ oc create ns cnftests
    ```

4.  Make the image stream available to all the namespaces used for tests. This is required to allow the tests namespaces to fetch the images from the `cnf-tests` image stream. Run the following commands:

    ``` terminal
    $ oc policy add-role-to-user system:image-puller system:serviceaccount:cnf-features-testing:default --namespace=cnftests
    ```

    ``` terminal
    $ oc policy add-role-to-user system:image-puller system:serviceaccount:performance-addon-operators-testing:default --namespace=cnftests
    ```

5.  Retrieve the docker secret name and auth token by running the following commands:

    ``` terminal
    $ SECRET=$(oc -n cnftests get secret | grep builder-docker | awk {'print $1'}
    ```

    ``` terminal
    $ TOKEN=$(oc -n cnftests get secret $SECRET -o jsonpath="{.data['\.dockercfg']}" | base64 --decode | jq '.["image-registry.openshift-image-registry.svc:5000"].auth')
    ```

6.  Create a `dockerauth.json` file, for example:

    ``` bash
    $ echo "{\"auths\": { \"$REGISTRY\": { \"auth\": $TOKEN } }}" > dockerauth.json
    ```

7.  Do the image mirroring:

    ``` terminal
    $ podman run -v $(pwd)/:/kubeconfig:Z -e KUBECONFIG=/kubeconfig/kubeconfig \
    registry.redhat.io/openshift4/cnf-tests-rhel8:4.11 \
    /usr/bin/mirror -registry $REGISTRY/cnftests |  oc image mirror --insecure=true \
    -a=$(pwd)/dockerauth.json -f -
    ```

8.  Run the tests:

    ``` terminal
    $ podman run -v $(pwd)/:/kubeconfig:Z -e KUBECONFIG=/kubeconfig/kubeconfig \
    -e DISCOVERY_MODE=true -e IMAGE_REGISTRY=image-registry.openshift-image-registry.svc:5000/cnftests \
    cnf-tests-local:latest /usr/bin/test-run.sh -ginkgo.focus="\[performance\]\ Latency\ Test"
    ```

**Mirroring a different set of test images**

You can optionally change the default upstream images that are mirrored for the latency tests.

**Procedure**

1.  The `mirror` command tries to mirror the upstream images by default. This can be overridden by passing a file with the following format to the image:

    ``` yaml
    [
        {
            "registry": "public.registry.io:5000",
            "image": "imageforcnftests:4.11"
        }
    ]
    ```

2.  Pass the file to the `mirror` command, for example saving it locally as `images.json`. With the following command, the local path is mounted in `/kubeconfig` inside the container and that can be passed to the mirror command.

    ``` terminal
    $ podman run -v $(pwd)/:/kubeconfig:Z -e KUBECONFIG=/kubeconfig/kubeconfig \
    registry.redhat.io/openshift4/cnf-tests-rhel8:v4.11 /usr/bin/mirror \
    --registry "my.local.registry:5000/" --images "/kubeconfig/images.json" \
    |  oc image mirror -f -
    ```

## Troubleshooting errors with the cnf-tests container {#cnf-performing-end-to-end-tests-troubleshooting_cnf-latency-tests}

To run latency tests, the cluster must be accessible from within the `cnf-tests` container.

**Prerequisites**

-   You have installed the OpenShift CLI (`oc`).

-   You have logged in as a user with `cluster-admin` privileges.

**Procedure**

-   Verify that the cluster is accessible from inside the `cnf-tests` container by running the following command:

    ``` terminal
    $ podman run -v $(pwd)/:/kubeconfig:Z -e KUBECONFIG=/kubeconfig/kubeconfig \
    registry.redhat.io/openshift4/cnf-tests-rhel8:v4.11 \
    oc get nodes
    ```

    If this command does not work, an error related to spanning across DNS, MTU size, or firewall access might be occurring.
