dnf install speedtest-cli
dnf install epel-release
dnf install epel-release
dnf install dbus-devel
dnf install glib2-devel
dnf install dbus-x11
dnf install python3-sqlalchemy
dnf upgrade
dnf install git python3-devel libffi-devel gcc openssl-devel python3-libselinux
python3 -m venv /root/vpinakastra
source /root/vpinakastra/bin/activate
pip install -U pip
pip install ansible-core==2.13.11
pip install git+https://opendev.org/openstack/kolla-ansible@stable/zed
mkdir -p /etc/kolla
echo $USER
chown $USER:$USER /etc/kolla
cp -r /root/vpinakastra/share/kolla-ansible/etc_examples/kolla/* /etc/kolla
cp /root/vpinakastra/share/kolla-ansible/ansible/inventory/all-in-one .
kolla-ansible install-deps
ansible-galaxy collection list
ansible-galaxy collection install ansible.posix
ansible-galaxy collection install community.general
ansible-galaxy collection install ansible.utils
ansible-galaxy collection install community.general
ansible-galaxy collection install community.mysql
ansible-galaxy collection list
kolla-ansible install-deps
kolla-genpwd

==================================================================================================================================
## HERE /etc/kolla/globals.yml FILE IS EDITED BASED ON THE DATA COLLECTED DURING THE INITIAL SETUP OF PINAKA-INSTALLER.EXE TOOL ##
==================================================================================================================================
dnf search release-ceph
dnf install --assumeyes centos-release-ceph-reef
dnf install --assumeyes cephadm
chmod +x cephadm
which cephadm
cephadm bootstrap --mon-ip <<<REPLACE MGMT-IP HERE>>> --allow-fqdn-hostname
cephadm shell -- ceph -s

=====================================================================================================================
## BELOW COMMAND SHOULD LOOK FOR ADDITIONAL HDD IN THE SERVER (APART FROM THE OS DISK) AND PREPARE IT AS CEPH OSD ##
=====================================================================================================================
ceph orch apply osd --all-available-devices
source /root/vpinakastra/bin/activate
pip install selinux
export ANSIBLE_PYTHON_INTERPRETER=/root/vpinakastra/bin/python
kolla-ansible -i ./all-in-one bootstrap-servers
export ANSIBLE_PYTHON_INTERPRETER=/root/vpinakastra/bin/python
kolla-ansible -i ./all-in-one prechecks
kolla-ansible -i ./all-in-one deploy 

======================================================================================
## Issue with ZUN containers during deploy step) ##
======================================================================================
mkdir -p /opt/cni/bin   
pip install python-openstackclient -c https://releases.openstack.org/constraints/upper/zed
kolla-ansible post-deploy
ceph osd pool create volumes
ceph osd pool create images
ceph osd pool create backups
ceph osd pool create vms
ceph config set global  mon_allow_pool_size_one true
ceph osd pool set .mgr size 1 --yes-i-really-mean-it
ceph osd pool set images size 1 --yes-i-really-mean-it
ceph osd pool set backups size 1 --yes-i-really-mean-it
ceph osd pool set volumes size 1 --yes-i-really-mean-it
ceph osd pool set vms size 1 --yes-i-really-mean-it
rbd pool init volumes
rbd pool init vms
rbd pool init images
rbd pool init backups
/root/vpinakastra/share/kolla-ansible/init-runonce

======================================================================================
### WE HAVE TO CREATE THE BELOW DIR STRUCTURE TO INTEGRATE OUR CEPH WITH OUR OPENSTACK
======================================================================================

[root@pinakastra-aio ~]# tree /etc/kolla/config/
/etc/kolla/config/
├── cinder
│   ├── ceph.client.cinder.keyring
│   ├── ceph.conf
│   ├── cinder-backup
│   │   ├── ceph.client.cinder-backup.keyring
│   │   ├── ceph.client.cinder.keyring
│   │   └── ceph.conf
│   └── cinder-volume
│       ├── ceph.client.cinder.keyring
│       └── ceph.conf
├── glance
│   ├── ceph.client.glance.keyring
│   └── ceph.conf
├── horizon
│   └── custom_local_settings
└── nova
    ├── ceph.client.cinder.keyring
    ├── ceph.conf
    └── nova-compute.conf

6 directories, 13 files
[root@pinakastra-aio ~]# 




mkdir -p /etc/kolla/config/cinder
mkdir -p /etc/kolla/config/glance
mkdir -p /etc/kolla/config/nova
mkdir -p /etc/kolla/config/horizon
mkdir -p /etc/kolla/config/cinder/cinder-volume
mkdir -p /etc/kolla/config/cinder/cinder-backup

======================================================================================
### COMMANDS TO CEPH  OPENSTACK INTEGRATION
======================================================================================
cephadm shell ceph auth get-or-create client.glance mon 'profile rbd' osd 'profile rbd pool=images' mgr 'profile rbd pool=images'
cephadm shell ceph auth get-or-create client.cinder mon 'profile rbd' osd 'profile rbd pool=volumes, profile rbd pool=vms, profile rbd-read-only pool=images' mgr 'profile rbd pool=volumes, profile rbd pool=vms'
cephadm shell ceph auth get-or-create client.cinder-backup mon 'profile rbd' osd 'profile rbd pool=backups' mgr 'profile rbd pool=backups'
cephadm shell ceph auth get-or-create client.glance | ssh pinakastra sudo tee /etc/ceph/ceph.client.glance.keyring
vi /etc/hosts
cephadm shell ceph auth get-or-create client.glance | ssh pinakastra-dell sudo tee /etc/ceph/ceph.client.glance.keyring
ssh pinakastra-dell sudo chown root:root /etc/ceph/ceph.client.glance.keyring
ls -ltr /etc/ceph/
cephadm shell ceph auth get-or-create client.cinder | ssh pinakastra-dell sudo tee /etc/ceph/ceph.client.cinder.keyring
ssh pinakastra-dell sudo chown root:root /etc/ceph/ceph.client.cinder.keyring
ls -ltr /etc/ceph/
cephadm shell ceph auth get-or-create client.cinder-backup | ssh pinakastra-dell sudo tee /etc/ceph/ceph.client.cinder-backup.keyring
ssh pinakastra-dell sudo chown root:root /etc/ceph/ceph.client.cinder-backup.keyring
cephadm shell ceph auth get-or-create client.cinder | ssh pinakastra-dell sudo tee /etc/ceph/ceph.client.cinder.keyring
cephadm shell ceph auth get-key client.cinder | ssh pinakastra-dell tee client.cinder.key
cp /etc/ceph/ceph.client.cinder.keyring /etc/kolla/config/cinder
cp /etc/ceph/ceph.conf /etc/kolla/config/cinder
cp /etc/ceph/ceph.client.cinder-backup.keyring /etc/kolla/config/cinder/cinder-backup/
cp /etc/ceph/ceph.client.cinder.keyring /etc/kolla/config/cinder/cinder-backup/
cp /etc/ceph/ceph.conf /etc/kolla/config/cinder/cinder-backup/
cp /etc/ceph/ceph.client.cinder.keyring /etc/kolla/config/cinder/cinder-volume/
cp /etc/ceph/ceph.conf /etc/kolla/config/cinder/cinder-volume/
cp /etc/ceph/ceph.client.glance.keyring /etc/kolla/config/glance/
cp /etc/ceph/ceph.conf /etc/kolla/config/glance/
cp /etc/ceph/ceph.client.cinder.keyring /etc/kolla/config/nova/
cp /etc/ceph/ceph.conf /etc/kolla/config/nova/
cat /etc/kolla/config/nova/nova-compute.conf


