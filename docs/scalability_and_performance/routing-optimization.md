# Optimizing routing

The OpenShift Container Platform HAProxy router scales to optimize performance.

## Baseline Ingress Controller (router) performance {#baseline-router-performance_routing-optimization}

The OpenShift Container Platform Ingress Controller, or router, is the Ingress point for all external traffic destined for OpenShift Container Platform services.

When evaluating a single HAProxy router performance in terms of HTTP requests handled per second, the performance varies depending on many factors. In particular:

-   HTTP keep-alive/close mode

-   Route type

-   TLS session resumption client support

-   Number of concurrent connections per target route

-   Number of target routes

-   Back end server page size

-   Underlying infrastructure (network/SDN solution, CPU, and so on)

While performance in your specific environment will vary, Red Hat lab tests on a public cloud instance of size 4 vCPU/16GB RAM. A single HAProxy router handling 100 routes terminated by backends serving 1kB static pages is able to handle the following number of transactions per second.

In HTTP keep-alive mode scenarios:

+----------------------+-------------------------+-----------------------+
| **Encryption**       | **LoadBalancerService** | **HostNetwork**       |
+======================+=========================+=======================+
| none                 | 21515                   | 29622                 |
+----------------------+-------------------------+-----------------------+
| edge                 | 16743                   | 22913                 |
+----------------------+-------------------------+-----------------------+
| passthrough          | 36786                   | 53295                 |
+----------------------+-------------------------+-----------------------+
| re-encrypt           | 21583                   | 25198                 |
+----------------------+-------------------------+-----------------------+

: **Table 1**

In HTTP close (no keep-alive) scenarios:

+----------------------+-------------------------+-----------------------+
| **Encryption**       | **LoadBalancerService** | **HostNetwork**       |
+======================+=========================+=======================+
| none                 | 5719                    | 8273                  |
+----------------------+-------------------------+-----------------------+
| edge                 | 2729                    | 4069                  |
+----------------------+-------------------------+-----------------------+
| passthrough          | 4121                    | 5344                  |
+----------------------+-------------------------+-----------------------+
| re-encrypt           | 2320                    | 2941                  |
+----------------------+-------------------------+-----------------------+

: **Table 2**

Default Ingress Controller configuration with `ROUTER_THREADS=4` was used and two different endpoint publishing strategies (LoadBalancerService/HostNetwork) were tested. TLS session resumption was used for encrypted routes. With HTTP keep-alive, a single HAProxy router is capable of saturating 1 Gbit NIC at page sizes as small as 8 kB.

When running on bare metal with modern processors, you can expect roughly twice the performance of the public cloud instance above. This overhead is introduced by the virtualization layer in place on public clouds and holds mostly true for private cloud-based virtualization as well. The following table is a guide to how many applications to use behind the router:

+----------------------------+-----------------------------------------------+
| **Number of applications** | **Application type**                          |
+============================+===============================================+
| 5-10                       | static file/web server or caching proxy       |
+----------------------------+-----------------------------------------------+
| 100-1000                   | applications generating dynamic content       |
+----------------------------+-----------------------------------------------+

: **Table 3**

In general, HAProxy can support routes for 5 to 1000 applications, depending on the technology in use. Ingress Controller performance might be limited by the capabilities and performance of the applications behind it, such as language or static versus dynamic content.

Ingress, or router, sharding should be used to serve more routes towards applications and help horizontally scale the routing tier.

For more information on Ingress sharding, see [Configuring Ingress Controller sharding by using route labels](../networking/ingress-operator/#nw-ingress-sharding-route-labels_configuring-ingress) and [Configuring Ingress Controller sharding by using namespace labels](../networking/ingress-operator.xml#nw-ingress-sharding-namespace-labels_configuring-ingress).

## Ingress Controller (router) performance optimizations {#router-performance-optimizations_routing-optimization}

OpenShift Container Platform no longer supports modifying Ingress Controller deployments by setting environment variables such as `ROUTER_THREADS`, `ROUTER_DEFAULT_TUNNEL_TIMEOUT`, `ROUTER_DEFAULT_CLIENT_TIMEOUT`, `ROUTER_DEFAULT_SERVER_TIMEOUT`, and `RELOAD_INTERVAL`.

You can modify the Ingress Controller deployment, but if the Ingress Operator is enabled, the configuration is overwritten.

### Configuring Ingress Controller liveness, readiness, and startup probes {#ingress-liveness-readiness-startup-probes_routing-optimization}

Cluster administrators can configure the timeout values for the kubelet’s liveness, readiness, and startup probes for router deployments that are managed by the OpenShift Container Platform Ingress Controller (router). The liveness and readiness probes of the router use the default timeout value of 1 second, which is too short for the kubelet’s probes to succeed in some scenarios. Probe timeouts can cause unwanted router restarts that interrupt application connections. The ability to set larger timeout values can reduce the risk of unnecessary and unwanted restarts.

You can update the `timeoutSeconds` value on the `livenessProbe`, `readinessProbe`, and `startupProbe` parameters of the router container.

+------------------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| Parameter        | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
+==================+=================================================================================================================================================================================================================================================================================================================================================================================================================================================================+
| `livenessProbe`  | The `livenessProbe` reports to the kubelet whether a pod is dead and needs to be restarted.                                                                                                                                                                                                                                                                                                                                                                     |
+------------------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| `readinessProbe` | The `readinessProbe` reports whether a pod is healthy or unhealthy. When the readiness probe reports an unhealthy pod, then the kubelet marks the pod as not ready to accept traffic. Subsequently, the endpoints for that pod are marked as not ready, and this status propogates to the kube-proxy. On cloud platforms with a configured load balancer, the kube-proxy communicates to the cloud load-balancer not to send traffic to the node with that pod. |
+------------------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| `startupProbe`   | The `startupProbe` gives the router pod up to 2 minutes to initialize before the kubelet begins sending the router liveness and readiness probes. This initialization time can prevent routers with many routes or endpoints from prematurely restarting.                                                                                                                                                                                                       |
+------------------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+

: **Table 4**

!!! important
    The timeout configuration option is an advanced tuning technique that can be used to work around issues. However, these issues should eventually be diagnosed and possibly a support case or [Jira issue](https://issues.redhat.com/secure/CreateIssueDetails!init.jspa?pid=12332330&summary=Summary&issuetype=1&priority=10200&versions=12385624) opened for any issues that causes probes to time out.

The following example demonstrates how you can directly patch the default router deployment to set a 5-second timeout for the liveness and readiness probes:

``` terminal
$ oc -n openshift-ingress patch deploy/router-default --type=strategic --patch='{"spec":{"template":{"spec":{"containers":[{"name":"router","livenessProbe":{"timeoutSeconds":5},"readinessProbe":{"timeoutSeconds":5}}]}}}}'
```

**Verification**

``` terminal
$ oc -n openshift-ingress describe deploy/router-default | grep -e Liveness: -e Readiness:
    Liveness:   http-get http://:1936/healthz delay=0s timeout=5s period=10s #success=1 #failure=3
    Readiness:  http-get http://:1936/healthz/ready delay=0s timeout=5s period=10s #success=1 #failure=3
```

### Configuring HAProxy reload interval {#configuring-haproxy-interval_routing-optimization}

When you update a route or an endpoint associated with a route, OpenShift Container Platform router updates the configuration for HAProxy. Then, HAProxy reloads the updated configuration for those changes to take effect. When HAProxy reloads, it generates a new process that handles new connections using the updated configuration.

HAProxy keeps the old process running to handle existing connections until those connections are all closed. When old processes have long-lived connections, these processes can accumulate and consume resources.

The default minimum HAProxy reload interval is five seconds. You can configure an Ingress Controller using its `spec.tuningOptions.reloadInterval` field to set a longer minimum reload interval.

!!! warning
    Setting a large value for the minimum HAProxy reload interval can cause latency in observing updates to routes and their endpoints. To lessen the risk, avoid setting a value larger than the tolerable latency for updates.

**Procedure**

-   Change the minimum HAProxy reload interval of the default Ingress Controller to 15 seconds by running the following command:

    ``` terminal
    $ oc -n openshift-ingress-operator patch ingresscontrollers/default --type=merge --patch='{"spec":{"tuningOptions":{"reloadInterval":"15s"}}}'
    ```
