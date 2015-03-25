# == Define: docker::service
#
# Define to manage docker group users
#
# === Parameters
# [*create_user*]
#   Boolean to cotrol whether the user should be created
#
define docker::system_user (
  $create_user = true) {

  include docker::params

  if $create_user {
    ensure_resource('user', $name, {'ensure' => 'present' })
    User[$name] -> Exec["docker-system-user-${name}"]
  }

  $add_to_group = $::osfamily ? {
    'Darwin' => "/usr/sbin/dseditgroup -o edit -a ${name} -t user ${docker::params::docker_group}",
    default  => "/usr/sbin/usermod -aG ${docker::params::docker_group} ${name}",
  }
  $check_in_group = $::osfamily ? {
    'Darwin' => "/usr/bin/dsmemberutil checkmembership -U ${name} -G ${docker::params::docker_group} | grep -q 'user is a member'",
    default  => "/bin/cat /etc/group | grep '^${docker::params::docker_group}:' | grep -qw ${name}",
  }

  exec { "docker-system-user-${name}":
    command => $add_to_group,
    unless  => $check_in_group,
  }
}