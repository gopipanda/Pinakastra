set -x
set -e

source /home/pinaka/all_in_one/vpinakastra/bin/activate
export ANSIBLE_PYTHON_INTERPRETER=/home/pinaka/all_in_one/vpinakastra/bin/python
echo "export ANSIBLE_PYTHON_INTERPRETER=/root/vpinakastra/bin/python" >> /etc/bashrc
cd /home/pinaka/all_in_one/vpinakastra/
kolla-ansible -i ./all-in-one bootstrap-servers
sudo sed -i.bak 's|^127\.0\.0\.1[[:space:]]*localhost[[:space:]]*|#127.0.0.1   localhost|' /etc/hosts
kolla-ansible -i ./all-in-one prechecks
kolla-ansible -i ./all-in-one deploy