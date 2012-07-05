# Class: neo4j
#
# For installing neo4j server.
#
class neo4j (
  $release             = 'neo4j-community-1.7.2',
  $mirror_url          = 'http://dist.neo4j.org/',
  $bind_address        = '127.0.0.1',
  $allow_store_upgrade = false,
  $enable_service      = true)
{
  $download_file = "${release}-unix.tar.gz"
  $download_url = "${mirror_url}${download_file}"

  # Create group, user, and home folder
  group { neo4j: ensure => present }
  user { neo4j:
    ensure     => present,
    managehome => false,
    home       => '/usr/share/neo4j',
    gid        => 'neo4j',
    require    => Group['neo4j'],
    comment    => 'Neo4j Graph Database'
  }
  file { '/etc/neo4j':
    ensure  => directory,
    owner   => 'neo4j',
	group   => 'neo4j',
    mode    => 0775,
    require => [ Group['neo4j'] ]
  }
  file { '/var/run/neo4j':
    ensure  => directory,
    owner   => 'neo4j',
	group   => 'neo4j',
    mode    => 0775,
    require => [ Group['neo4j'], User['neo4j'] ]
  }
  file { '/var/log/neo4j':
    ensure  => directory,
    owner   => 'neo4j',
	group   => 'neo4j',
    mode    => 0775,
    require => [ Group['neo4j'], User['neo4j'] ]
  }
  file { '/var/lib/neo4j':   # DB data directory
    ensure  => directory,
    owner   => 'neo4j',
	group   => 'neo4j',
    mode    => 0770,
    require => [ Group['neo4j'], User['neo4j'] ]
  }

  exec { 'neo4j-download':
    command   => "curl -v --progress-bar -o '/var/tmp/${download_file}' '$download_url'",
    creates   => "/var/tmp/${release}-unix.tar.gz",
    path      => ["/bin", "/usr/bin"],
    logoutput => true,
    user      => 'neo4j',
	group     => 'neo4j',
    require   => [ Group['neo4j'], User['neo4j'], Package['curl'] ],
    unless    => '/usr/bin/test -d /usr/share/neo4j'
  }

  exec { 'neo4j-extract':
    command   => "tar -xzf /var/tmp/${download_file} -C /var/tmp",
    creates   => "/var/tmp/${release}",
    path      => ["/bin", "/usr/bin"],
	logoutput => true,
    user      => 'neo4j',
	group     => 'neo4j',
    require   => [ Group['neo4j'], User['neo4j'], Exec['neo4j-download'] ],
    unless    => '/usr/bin/test -d /usr/share/neo4j'
  }
  exec { move_neo4j:
    command   => "mv -v '/var/tmp/${release}' /usr/share/neo4j",
    creates   => '/usr/share/neo4j',
    logoutput => true,
    path      => ["/bin", "/usr/bin"],
    require   => Exec['neo4j-extract']
  }
  file { '/usr/share/neo4j':
    ensure  => directory,
    mode    => 0775,
    require => Exec['move_neo4j'],
  }
  file { '/usr/bin/neo4j':
    ensure  => '/usr/share/neo4j/bin/neo4j',
    require => Exec['move_neo4j']
  }
  file { '/usr/bin/neo4j-shell':
    ensure  => '/usr/share/neo4j/bin/neo4j-shell',
    require => Exec['move_neo4j']
  }

  file { '/etc/neo4j/neo4j-server.properties':
    content => template('neo4j/neo4j-server.properties.erb'),
    owner   => 'neo4j',
    group   => 'neo4j',
    mode    => 0440,
    require => File['/etc/neo4j'],
    notify  => Service['neo4j-service']
  }
  file { '/etc/neo4j/neo4j-wrapper.conf':
    content => template('neo4j/neo4j-wrapper.conf.erb'),
    require => Exec['move_neo4j']
  }
  file { '/etc/neo4j/neo4j.properties':
    content => template('neo4j/neo4j.properties.erb'),
    owner   => 'neo4j',
	group   => 'neo4j',
    mode    => 0664,
    require => File['/etc/neo4j']
  }
  file { '/etc/neo4j/logging.properties':
    content => template('neo4j/logging.properties.erb'),
    owner   => 'neo4j',
	group   => 'neo4j',
    mode    => 0664,
    require => File['/etc/neo4j']
  }
  file { '/etc/init.d/neo4j-service':
    content => template('neo4j/neo4j-service.sh.erb'),
    owner   => 'root',
	group   => 'root',
    mode    => 0755,
    require => Package['lsof'],
    notify  => Service['neo4j-service']
  }

  # Linux specific notes
  # Note: Although the limit has been raised, neo4j may still complain (it's neo4j's bug):
  #   WARNING: Detected a limit of 1024 for maximum open files, while a minimum value of 40000 is recommended.
  # This is NORMAL.
  # To check yourself, "sudo su neo4j" then "ulimit -n", you'll see 40000
  exec { neo4j_security_limits:
    command   => 'sed -i -e \'$a neo4j    soft    nofile    40000\' -e \'$a neo4j    hard    nofile    40000\' /etc/security/limits.conf',
    logoutput => true,
    unless    => 'grep "neo4j" /etc/security/limits.conf',
    path      => ['/bin', '/usr/bin']
  }
  exec { neo4j_pam_limits:
    command   => 'sed -i -e \'s/# session    required   pam_limits.so/session    required   pam_limits.so/\' /etc/pam.d/su',
    logoutput => true,
    onlyif    => 'grep "# session    required   pam_limits.so" /etc/pam.d/su',
    path      => ['/bin', '/usr/bin']
  }

  service { neo4j-service:
    enable     => $enable_service,
    ensure     => running,
    hasrestart => true,
    hasstatus  => true,
    status     => '/usr/sbin/service neo4j-service status | grep "is running"',
    require    => [ Exec['neo4j_pam_limits'],
	  File['/usr/share/neo4j', '/etc/neo4j/neo4j-server.properties',
	       '/etc/neo4j/neo4j-wrapper.conf', '/etc/neo4j/neo4j.properties',
           '/etc/neo4j/logging.properties', '/etc/init.d/neo4j-service'] ],
  }

}
