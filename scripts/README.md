# Configuration Scripts

As part of the pipeline there are a number of scripts we run to harden the image

## SELinux Script

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

## CIS -LEVEL1

This script is used to apply the Kubernetes CIS-Level1 hardening