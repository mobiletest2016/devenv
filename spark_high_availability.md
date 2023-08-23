From: https://gist.github.com/aseigneurin/3af6b228490a8deab519c6aea2c209bc


Docker compose file: [spark_high_availability.yml](spark_high_availability.yml)


# Spark - High availability

## Components in play

As a reminder, here are the components in play to run an application:

- The *cluster*:
  - **Spark Master**: coordinates the resources
  - **Spark Workers**: offer resources to run the applications
- The *application*:
  - **Driver**: the part of the application that coordinates the processing
  - **Executors**: the distributed part of the application that process the data

When the *driver* is run in *cluster mode*, it runs on a *worker*.

Notice that each component run its own JVM: the *workers* spawn separate JVMs to run the *driver* and the *executors*.

## Fault tolerance

With a Spark *standalone* cluster, here is what happens if the JVM running a component dies:

- *Master*: :x: can no longer run new applications and the UI becomes unavailable.
- *Worker*: :white_check_mark: not a problem, the cluster simply has less resources.
- *Driver*: :x: the application dies.
- *Executor*: :white_check_mark: not a problem, the partitions being processed are sent to another *executor*.

Notice that losing a JVM or losing the whole EC2 instance has the same effect.

Here is how to deal with these problems:

- *Master* -> setup a *standby master*.
- *Driver* -> run the application in *supervised mode*.


## Setting up a *standby master*

Since the Master is a *single point of failure*, Spark offers the ability to start another instance of a master which will be in standby until the active master disappears. When the standby master becomes the active master, the workers will reconnect to this master and existing applicatione will continue running without problem.

This functionality relies on ZooKeeper to perform master election.

### Starting the masters

First step is to get a ZooKeeper cluster up and running. You can then start the master with options to connect to ZooKeeper, e.g.:

```
SPARK_MASTER_OPTS="-Dspark.deploy.recoveryMode=ZOOKEEPER -Dspark.deploy.zookeeper.url=<zkhost>:2181"
```

You should see the following lines in the log:

```
2016-11-01 10:44:16 INFO ZooKeeperLeaderElectionAgent: Starting ZooKeeper LeaderElection agent
...
2016-11-01 10:44:57 INFO Master: I have been elected leader! New state: ALIVE
```

In the UI of this master, you should see:

```
Status: ALIVE
```

Now, if you start a master with the same ZooKeeper options on another node, you should only see a line indicating an election is being performed but this master should not become the leader:

```
2016-11-01 10:51:27 INFO ZooKeeperLeaderElectionAgent: Starting ZooKeeper LeaderElection agent
...
```

In the UI of this new master, you should see:

```
Status: STANDBY
```

### Starting the workers

When starting the worker, you now have to provide the reference to all the masters:

```
start-slave.sh spark://master1:7077,master2:7077
```

The workers will only be visible in the UI of the active master but they will have the ability to connect to the new master if the active one dies.

### Submitting applications

The same principle applies when submitting applications:

```
spark-submit --master spark://master1:7077,master2:7077 ...
```

### Master election

Now, if you kill the active master, you should see the following lines in the log of the previously standby master:

```
2016-11-01 11:27:39 INFO ZooKeeperLeaderElectionAgent: We have gained leadership
2016-11-01 11:27:39 INFO Master: I have been elected leader! New state: RECOVERING
...
2016-11-01 11:27:39 INFO Master: Worker has been re-registered: worker-20161101112104-127.0.0.1-57477
2016-11-01 16/11/01 11:27:39 INFO Master: Application has been re-registered: app-20161101112623-0000
2016-11-01 16/11/01 11:27:39 INFO Master: Recovery complete - resuming operations!
```

Here is what this indicates:

- The standby master became the active master.
- The worker reconnected to the new master.
- The running application reconnected to the new master.

In the log of the workers, you should see the following:

```
2016-11-01 11:26:55 ERROR Worker: Connection to master failed! Waiting for master to reconnect...
...
2016-11-01 11:27:39 INFO Worker: Master has changed, new master is at spark://127.0.0.1:9099
```

And in the log of the driver of the running application, you should see:

```
2016-11-01 11:26:55 WARN StandaloneSchedulerBackend: Disconnected from Spark cluster! Waiting for reconnection...
2016-11-01 11:26:55 WARN StandaloneAppClient$ClientEndpoint: Connection to 127.0.0.1:7077 failed; waiting for master to reconnect...
2016-11-01 11:27:39 INFO StandaloneAppClient$ClientEndpoint: Master has changed, new master is at spark://127.0.0.1:9099
```

## Running the application in *supervised mode*

The *supervised mode* allows the driver to be restarted on a different node if it dies. Enabling this functionality simply requires adding the `--supervise` flag when running `spark-submit`:

`spark-submit --supervise ...`

Notice that restarting the application is the easy part: you need to be aware of potential side effects of re-running the application. Let's say you need to update the balance of an account by $100. If you simply increment the current balance, re-running this operation will end up increasing the balance by $200.

A best practice is to make the whole application **idempotent**. Idempotence means that re-running the application doesn't change the values that have already been written.This means you need a way to determine if each operation has already been processed. Another way to achieve idempotence is to use [event sourcing](http://martinfowler.com/eaaDev/EventSourcing.html).
