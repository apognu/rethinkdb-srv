# RethinkDB clustering with DNS SRV records

This Docker image is forked from the official [rethinkdb](https://hub.docker.com/_/rethinkdb/) and allows to set up clustering through DNS SRV records until RethinkDB supports it.

What is does is simple, it looks up **RDB_CLUSTER_SRV_ADDRESS** for all SRV records, blacklists the current host (through the **HOST** environment variable), and builds the run parameters accordingly.

For instance, with the following DNS SRV records set:

```
$ host -t SRV rethinkdb.service.consul 127.0.0.1
Using domain server:
Name: 127.0.0.1
Address: 127.0.0.1#53
Aliases:

rethinkdb.discovery.internal has SRV record 0 0 33333 slave-03.domain.tld.
rethinkdb.discovery.internal has SRV record 0 0 22222 slave-02.domain.tld.
rethinkdb.discovery.internal has SRV record 0 0 11111 slave-01.domain.tld.
```

And with this environment:

```
HOST=slave-03.domain.tld
RDB_CLUSTER_SRV_ADDRESS=rethinkdb.discovery.internal
```

The Docker image would be run with the following command:

```
$ --join slave-02.appscho.lab:22222 --join slave-03.appscho.lab:33333
```

## Settings

 * RDB_CLUSTER_RETRY_COUNT: how many times should we retry the DNS query if it fails
 * RDB_CLUSTER_RETRY_INTERVAL: how much time (in seconds) to wait between retries
