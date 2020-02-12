
# Information

## Configuration Scripts

As part of the pipeline there are a number of scripts we run to harden the image

### SELinux Script

The SELinux script is used to install the additional tool required: to manage SELinux, set SELinux to enforcing mode, to configure Docker to label containers, and install the SELinux policy packages so that containers when labelled have some rules on the system support container workloads.

The script does the following:

1. Performs a yum update to install any missing security update deltas
2. Installs some SELinux policy and management tooling
3. Downloads and installs the following
   1. SELInux troubleshooting tools
   2. compatible container-selinux policy package
4. Configures SELinux to be set to enforcing
5. Updates the Docker daemon config file so docker can label containers

Some of the packages we install are outside of the AWS Amazon Linux 2 repos. We are also limited to a slightly old version of container-selinux package, because the dependencies for the more recent version are not currently supported on AL2

### CIS -LEVEL1

This script is used to apply the Kubernetes CIS-Level1 hardening

## SELinux Management

If you suspect the container you have launched is being affected by SELinux, there are some tools you can use to inspect and parse the logs. The output from the logs can be used custom SELinux modules that can be loaded into kernel.

Additionally, if the workload requires a considerable amount of system access, it is possible to launch the container in with a less restrictive policy applied. However this should be considered a last resort, and used only for complex applications.

### Logs

**/var/logs/audit/audit.log**

This contains the SELINUX denied messages for all processes that fail to pass SELINUX MAC lists.

To confirm if the process in your container has failed because of a deny you can run the following command

```bash
sudo cat /var/log/audit/audit.log | grep denied
```

If this highlights too many false positives, then try to `grep` for the process spawned by your application

```bash
sudo cat /var/log/audit/audit.log | grep certwatch
```

In this example, **certwatch** (`comm="certwatch"`) was denied write access (`{ write }`) to a directory labeled with the `var_t` type

```
type=AVC msg=audit(1226270358.848:238): avc:  denied  { write } for  pid=13349 comm="certwatch" name="cache" dev=dm-0 ino=218171 scontext=system_u:system_r:certwatch_t:s0 tcontext=system_u:object_r:var_t:s0 tclass=dir
```

### Audit2Allow

With a denial logged, such as the `certwatch` denial above, you can run  `audit2allow -w -a` command to produce a human-readable description of why access was denied. The `-a` option causes all audit logs to be read. The `-w` option produces the human-readable description. The `audit2allow` utility accesses `/var/log/audit/audit.log`, and as such, must be run as the Linux **root** user

```bash
sudo audit2allow -w -a
type=AVC msg=audit(1226270358.848:238): avc:  denied  { write } for  pid=13349 comm="certwatch" name="cache" dev=dm-0 ino=218171 scontext=system_u:system_r:certwatch_t:s0 tcontext=system_u:object_r:var_t:s0 tclass=dir
	Was caused by:
		Missing type enforcement (TE) allow rule.

	You can use audit2allow to generate a loadable module to allow this access.
```

You will probably find that just running `audit2allow -w -a` will produce multiple denials for multiple processes. Your goal should be create custom policy for a **single** process.

To do this, we can use the `grep` command (as used above) to narrow down the input for `audit2allow`. The following example demonstrates using `grep` to only send denials related to `certwatch` through `audit2allow`: 		

```bash
sudo grep certwatch /var/log/audit/audit.log | audit2allow -a -w
```

#### Custom policy

Now we have narrowed down the denied messages, we can create a custom SELINUX policy that can be loaded into kernel.

Following the same syntax above we can use `audit2allow -M` to produce the policy based on the messages in the audit log. The `-M` option creates a Type Enforcement file (`.te`) with the name specified with `-M`, in your current working directory: 				

```bash
sudo grep certwatch /var/log/audit/audit.log | audit2allow -M mycertwatch-policy
******************** IMPORTANT ***********************
To make this policy package active, execute:

# semodule -i mycertwatch2.pp
```

`audit2allow` also compiles the Type Enforcement rule into a policy package (`.pp`).

To install the module, execute:
```bash
sudo semodule -i mycertwatch-policy.pp
``` 
running command as the Linux root user.

### SELinux Permissive Mode

As you try to understand all the SELINUX requirements your application has, it can be useful to run SELINUX in Permissive mode to get further insight into the denials being triggered.

Permissive mode logs denied messages in the `audit.log` file, but does not stop processes from running.

To confirm if your are running in Permissive or Enforcing mode there are a number of commands you can run.

1. `sestatus` displays configuration information for SElinux

```bash
$ sestatus
SELinux status:                 enabled
SELinuxfs mount:                /sys/fs/selinux
SELinux root directory:         /etc/selinux
Loaded policy name:             targeted
Current mode:                   enforcing
Mode from config file:          enforcing
Policy MLS status:              enabled
Policy deny_unknown status:     allowed
Max kernel policy version:      31
```

2. `getenforce` displays the current mode SELinux is running

   ```bash
   $ getenforce
   Enforcing
   ```

The simplest way to set the current mode to permissive is to use the `setenforce 0` command, where `0` sets selinux to permissive. This needs to be run as the Linux root user

```bash
$ sudo setenforce 0
```

confirm the change.

```bash
$ getenforce
Permissive
```

Before launching the container clear the `audit.log` file so that the denied messages captured are for your application only

```bash
sudo > /var/log/audit/audit.log
```

Now that you are running in permissive mode you can launch your container or process, and capture all the requirement and when you run:

```bash
sudo grep denied /var/log/audit/audit.log | audit2allow -a -w
```

the messages you see will be more relevant.