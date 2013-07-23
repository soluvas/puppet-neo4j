# Class: neo4j
#
# For installing neo4j server.
#
class neo4j (
  $release             = 'neo4j-community-1.8.2', # obsolete
  $mirror_url          = 'http://dist.neo4j.org/', # obsolete
  $bind_address        = '127.0.0.1',
  $allow_store_upgrade = false,
  $enable_service      = true)
{
  apt::source { neo4j:
    location    => 'http://debian.neo4j.org/repo',
    release     => 'stable/',
    repos       => '',
    key         => '2DC499C3',
    key_server  => 'keyserver.ubuntu.com',
    include_src => false,
  }
  package { neo4j:
    ensure  => present,
    require => Apt::Source['neo4j'],
  }
  service { neo4j-service:
    enable     => $enable_service,
    ensure     => running,
    require    => Package['neo4j'],
  }

}
