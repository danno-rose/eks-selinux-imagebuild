control 'SELinux Enforcing' do
  title 'SElinux should running in enforcing mode'
  describe command('getenforce') do
    its('stdout') { should include "Enforcing" }
  end
end

control 'SELinux Config' do
  title 'SElinux Config should be set to enforcing'
  describe file('/etc/selinux/config') do
    its('content') { should include 'SELINUX=enforcing' }
  end
end

control 'Docker SELinux' do
  title 'Docker set to lable containers'  
  describe file('/etc/docker/daemon.json') do
      its('content') { should include '"selinux-enabled": true' }
    end
  end

control 'Selinux Modules' do
  title 'Required SELINUX modules should be installed'
  describe command('sudo semodule -l | grep cluster-autoscaler') do
    its('stdout') { should include "cluster-autoscaler" }
  end

  describe command('sudo semodule -l | grep container') do
    its('stdout') { should include "container" }
  end
end

control 'seccomp' do
  title 'Checking Seccomp Enabled in Kernel'
  describe command('grep CONFIG_SECCOMP= /boot/config-$(uname -r)') do
    its('stdout') { should include 'CONFIG_SECCOMP=y' }
  end
end