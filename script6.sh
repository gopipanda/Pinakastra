set -x
set -e

GLOBALS_YML="/etc/kolla/globals.yml"

declare -A key_values=(
  ["kolla_internal_vip_address"]="$IP_ADDRESS"
  ["network_interface"]="$INTERFACE_01"
  ["neutron_external_interface"]="$INTERFACE_02"
  ["enable_openstack_core"]="yes"
  ["enable_skyline"]="yes"
  ["enable_haproxy"]="no"
  ["enable_cinder"]="yes"
  ["enable_cinder_backup"]="yes"
  ["enable_cloudkitty"]="yes"
  ["enable_horizon_neutron_vpnaas"]="{{ enable_neutron_vpnaas | bool }}"
  ["enable_horizon_sahara"]="{{ enable_sahara | bool }}"
  ["enable_horizon_trove"]="{{ enable_trove | bool }}"
  ["enable_horizon_zun"]="{{ enable_zun | bool }}"
  ["enable_kuryr"]="yes"
  ["enable_magnum"]="yes"
  ["enable_neutron_vpnaas"]="yes"
  ["enable_neutron_metering"]="yes"
  ["enable_sahara"]="yes"
  ["enable_trove"]="yes"
  ["enable_zun"]="yes"
  ["external_ceph_cephx_enabled"]="yes"
  ["ceph_glance_keyring"]="ceph.client.glance.keyring"
  ["ceph_glance_user"]="glance"
  ["ceph_glance_pool_name"]="images"
  ["ceph_cinder_keyring"]="ceph.client.cinder.keyring"
  ["ceph_cinder_user"]="cinder"
  ["ceph_cinder_pool_name"]="volumes"
  ["ceph_cinder_backup_keyring"]="ceph.client.cinder-backup.keyring"
  ["ceph_cinder_backup_user"]="cinder-backup"
  ["ceph_cinder_backup_pool_name"]="backups"
  ["ceph_nova_keyring"]="{{ ceph_cinder_keyring }}"
  ["ceph_nova_user"]="nova"
  ["ceph_nova_pool_name"]="vms"
  ["glance_backend_ceph"]="yes"
  ["glance_backend_file"]="yes"
  ["cinder_backend_ceph"]="yes"
  ["cinder_backup_driver"]="ceph"
  ["cinder_backup_share"]="localhost:/cephfs"
  ["designate_backend"]="bind9"
  ["designate_ns_record"]='["ns1.example.org"]'
  ["designate_coordination_backend"]="{{ 'redis' if enable_redis|bool else '' }}"
  ["nova_backend_ceph"]="yes"
  ["nova_console"]="novnc"
  ["enable_prometheus_ceph_mgr_exporter"]="yes"
)

cp $GLOBALS_YML $GLOBALS_YML.bak

for key in "${!key_values[@]}"; do
  value="${key_values[$key]}"
  sudo sed -i "/#${key}:/ s/#//" $GLOBALS_YML
  sudo sed -i "/${key}:/ s/: .*/: \"$value\"/" $GLOBALS_YML
done



