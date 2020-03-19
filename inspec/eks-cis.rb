#TODO: Remove test values

## Worknode Configurations
control '4.1.1 kublet' do
    title 'Ensure that the kubelet service file permissions are set to 644 or more restrictive'
    paths = [
        "/etc/systemd/system/kubelet.service.d/10-eksclt.al2.conf",
        "/etc/systemd/system/kubelet.service.d/10-kubeadm.conf",
        "/home/drosea/.bashrc" #TODO: remove
    ]
    paths.each do |item|
        if file(item).exist?
            describe file(item) do
                it { should_not be_more_permissive_than('0644') }
            end
        end
    end
end

control '4.1.2 kublet' do
    title 'Ensure that the kubelet service file ownership is set to root:root'
    paths = [
        "/etc/systemd/system/kubelet.service.d/10-eksclt.al2.conf",
        "/etc/systemd/system/kubelet.service.d/10-kubeadm.conf",
        "/home/drosea/.bashrc" #TODO: remove
    ]
    paths.each do |item|
        if file(item).exist?
            describe command("stat -c %U:%G #{item}") do
                its('stdout') { should include "root:root" }
            end
        end
    end
end

control '4.1.5 kublet conf' do
    title 'Ensure that the kubelet.conf file permissions are set to 644 or more restrictive'
    paths = [
        "/etc/kubernetes/kubelet.conf",
        "/etc/kubernetes/kubelet/kubelet-config.json",
        "/home/drosea/.bashrc" #TODO: remove
    ]
    paths.each do |item|
        if file(item).exist?
            describe file(item) do
                it { should_not be_more_permissive_than('0644') }
            end
        end
    end
end

control '4.1.6 kublet conf' do
    title 'Ensure that the kubelet.conf file ownership is set to root:root'
    paths = [
        "/etc/kubernetes/kubelet.conf",
        "/etc/kubernetes/kubelet/kubelet-config.json",
        "/home/drosea/.bashrc" #TODO: remove
    ]
    paths.each do |item|
        if file(item).exist?
            describe command("stat -c %U:%G #{item}") do
                its('stdout') { should include "root:root" }
            end
        end
    end
end

control '4.1.9 kublet conf' do
    title 'Ensure that the kubelet configuration file has permissions set to 644 or more restrictive'
    paths = [
        "/etc/eksctl/kubelet.yaml"
    ]
    paths.each do |item|
        if file(item).exist?
            describe file(item) do
                it { should_not be_more_permissive_than('0644') }
            end
        end
    end
end

control '4.1.10 kublet conf' do
    title 'Ensure that the kubelet configuration file ownership is set to root:root'
    paths = [
        "/etc/eksctl/kubelet.yaml"
    ]
    paths.each do |item|
        if file(item).exist?
            describe command("stat -c %U:%G #{item}") do
                its('stdout') { should include "root:root" }
            end
        end
    end
end

### Kublet Recommendations
control '4.2.1 kublet yaml' do
    title 'Ensure that the anonymous-auth argument is set to false'
    kfile = file("/etc/eksctl/kubelet.yaml")
        describe command("cat #{kfile} | grep anonymous -A 1 | grep enabled ") do
            its('stdout') { should include "false" }
        end
end

control '4.2.2 kublet yaml' do
    title 'Ensure that the --authorization-mode argument is not set to AlwaysAllow'
    kfile = file("/etc/eksctl/kubelet.yaml")
        describe command("cat #{kfile} | grep authorization -A 1 | grep mode") do
            its('stdout') { should include "Webhook" }
        end
end

control '4.2.3 kublet yaml' do
    title 'Ensure that the --client-ca-file argument is set as appropriate'
    kfile = file("/etc/eksctl/kubelet.yaml")
        describe command("cat #{kfile} | grep x509 -A1 | grep clientCAFile") do
            its('stdout') { should include "ca.crt" }
        end
end

control '4.2.8 kublet yaml' do
    title 'Ensure that the --hostname-override argument is not set'
    kfile = file("/etc/eksctl/kubelet.yaml")
        describe command("cat #{kfile}") do
            its('stdout') { should_not include "hostname" }
        end
end

control '4.2.11 kublet yaml' do
    title 'Ensure that the --rotate-certificates argument is not set to false'
    kfile = file("/etc/eksctl/kubelet.yaml")
        describe command("cat #{kfile} | grep RotateKubeletServerCertificate") do
            its('stdout') { should_not include "false" }
        end
end

control '4.2.12 kublet yaml' do
    title 'Ensure that the RotateKubeletServerCertificate argument is set to true'
    kfile = file("/etc/eksctl/kubelet.yaml")
        describe command("cat #{kfile} | grep RotateKubeletServerCertificate") do
            its('stdout') { should include "true" }
        end
end