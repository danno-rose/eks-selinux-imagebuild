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

control '4.1.10 kublet' do
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