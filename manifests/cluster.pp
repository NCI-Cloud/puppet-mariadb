# Class: mariadb::cluster
#
# manages the installation of the mariadb server.  manages the package, service,
# my.cnf
#
# Parameters:
#   [*wsrep_sst_password*]
#     Password for the replication user.
#   [*cluster_servers*]
#     Array of hosts in the galera cluster. Can be specified as names
#     or IP addresses.
#   [*cluster_iface*]
#     The host interface that the cluster will communicate with.
#   [*wsrep_sst_user*]
#     The replication user name.
#   [*wsrep_cluster_name*]
#     The unique name for the cluster.
#   [*status_user*]
#     The cluster status user name.
#   [*wsrep_sst_method*]
#     The method to use for replication.
#   [*wsrep_slave_threads*]
#     Number of threads to use for replication.
#   [*package_ensure*]
#     Ensure value for the server packages. Set to `present` or a version number.
#   [*galera_ensure*]
#     The galera package ensure value.
#   [*status_password*]
#     The password for the status user.
#   [*config_hash*]
#     hash of config parameters that need to be set.
#   [*enabled*]
#     If true, enable the service to start on boot.
#   [*single_cluster_peer*]
#     If true, configure each node to sync with only one other node. Sets
#     `wsrep_cluster_address = 'gcomm://192.168.0.1'`. If false,
#     sets `wsrep_cluster_address = 'gcomm://192.168.0.1,192.168.0.2,192.168.0.3'`,
#     etc. based on number of nodes and the IP/hostname as set in 
#     `cluster_servers`.
#   [*manage_status*]
#     If true, manage the status user and status script.
#   [*manage_repo*]
#     If true, manage the yum or apt repo.
#   [*build_stage*]
#     Where in the cluster build process the node is. Accepted values are
#     'bootstrap', which must be used on a single node in order to bootstrap the
#     cluster on that node, 'peer', which should be used on the remaining nodes
#     in order to join them to the bootstrap node, and 'standalone', which
#     configures the node without any clustering support.
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
class mariadb::cluster (
  $wsrep_sst_password,
  $cluster_servers,
  $cluster_iface           = 'eth0',
  $wsrep_sst_user          = 'root',
  $wsrep_cluster_name      = 'my_wsrep_cluster',
  $status_user             = 'clusterstatus',
  $wsrep_sst_method        = 'mysqldump',
  $wsrep_slave_threads     = $mariadb::params::slave_threads,
  $package_ensure          = $mariadb::params::cluster_package_ensure,
  $galera_ensure           = $mariadb::params::cluster_package_ensure,
  $debiansysmaint_password = undef,
  $status_password         = undef,
  $config_hash             = {},
  $enabled                 = true,
  $single_cluster_peer     = true,
  $manage_status           = true,
  $manage_repo             = true,
  $build_stage             = 'standalone',
) inherits mariadb::params {


  class { 'mariadb::cluster::base':
    wsrep_sst_password      => $wsrep_sst_password,
    wsrep_sst_user          => $wsrep_sst_user,
    package_ensure          => $package_ensure,
    package_names           => $::mariadb::cluster_package_names,
    debiansysmaint_password => $debiansysmaint_password,
    manage_repo             => $manage_repo,
    repo_version            => $repo_version,
    manage_status           => $manage_status,
    status_user             => $status_user,
    status_password         => $status_password,
    config_hash             => $config_hash,
    enabled                 => $enabled,
  }

  $galera_options = {
    wsrep_sst_password  => $wsrep_sst_password,
    wsrep_sst_user      => $wsrep_sst_user,
    wsrep_sst_method    => $wsrep_sst_method,
    wsrep_cluster_name  => $wsrep_cluster_name,
    wsrep_slave_threads => $wsrep_slave_threads,
    galera_name         => $::mariadb::galera_name,
    galera_ensure       => $galera_ensure,
    cluster_iface       => $cluster_iface,
    repo_version        => $repo_version,
  }

  case $build_stage {
    'bootstrap': {
      class { 'mariadb::cluster::galera':
        cluster_peer => '',
        *            => $galera_options,
      }
    }

    'peer': {
      # Find the next server in the list as a peer to sync with
      if $single_cluster_peer == true {
        $cluster_peer = inline_template(@(TMPL/L))
          <% (0..@cluster_servers.length).each do |i|; if @cluster_servers[i] \
          == @ipaddress_cluster_iface; if (i+1) == @cluster_servers.length %><%= \
          @cluster_servers[0] %><% else %><%= @cluster_servers[i+1] %><% \
          end; end; end %>
          |-TMPL
      } else {
        $cluster_peer = join($cluster_servers,',')
      }

      class { 'mariadb::cluster::galera':
        cluster_peer => $cluster_peer,
        *            => $galera_options,
      }
    }

    'standalone', default: {
      notice('Standalone mariadb server')
    }
  }

  if $wsrep_sst_method == 'mariabackup' {
    ensure_packages([$::mariadb::backup_package_name])
  }

}
