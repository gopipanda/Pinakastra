set -x
set -e

source /home/pinaka/all_in_one/vpinakastra/bin/activate
export ANSIBLE_PYTHON_INTERPRETER=/root/vpinakastra/bin/python
kolla-ansible post-deploy
pip install python-openstackclient -c https://releases.openstack.org/constraints/upper/2023.1
/home/pinaka/all_in_one/vpinakastra/share/kolla-ansible/init-runonce