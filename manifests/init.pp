# Class: apache
#
# This class installs Apache
#
# Parameters:
#
# Actions:
#   - Install Apache
#   - Manage Apache service
#
# Requires:
#
# Sample Usage:
#
class apache (
  $default_mods = true,
  $service_enable = true,
  $serveradmin  = 'root@localhost',
  $sendfile     = false,
  $listen_port = 80
) {
  include apache::params

  package { 'httpd':
    ensure => installed,
    name   => $apache::params::apache_name,
  }

  # true/false is sufficient for both ensure and enable
  validate_bool($service_enable)

  service { 'httpd':
    ensure    => $service_enable,
    name      => $apache::params::apache_name,
    enable    => $service_enable,
    subscribe => Package['httpd'],
  }

  file { 'httpd_vdir':
    ensure  => directory,
    path    => $apache::params::vdir,
    recurse => true,
    purge   => true,
    notify  => Service['httpd'],
    require => Package['httpd'],
  }

  if $apache::params::conf_dir and $apache::params::conf_file {
    # Template uses:
    # - $apache::params::user
    # - $apache::params::group
    # - $apache::params::conf_dir
    # - $serveradmin
    file { "${apache::params::conf_dir}/${apache::params::conf_file}":
      ensure  => present,
      content => template("apache/${apache::params::conf_file}.erb"),
      notify  => Service['httpd'],
      require => Package['httpd'],
    }
    
    # Debian has more than one file to template.
    if  $::osfamily == 'debian' {
      file { "${apache::params::conf_dir}/${apache::params::portsconf_file}":
        ensure  => present,
        content => template("apache/${apache::params::portsconf_file}.erb"),
        notify  => Service['httpd'],
        require => Package['httpd'],
      }
    }
    
    # Don't include default mods on debian.
    if $default_mods == true and  $::osfamily != 'debian'{
      include apache::mod::default
    }
  }
  
  
  
  
  
  if $apache::params::mod_dir {
    file { $apache::params::mod_dir:
      ensure  => directory,
      require => Package['httpd'],
    } -> A2mod <| |>
    resources { 'a2mod':
      purge => true,
    }
  }
}
