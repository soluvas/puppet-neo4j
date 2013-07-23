# Class: neo4j
#
# For installing neo4j server.
#
class neo4j (
  $release             = 'neo4j-community-1.8.2',
  $mirror_url          = 'http://dist.neo4j.org/',
  $bind_address        = '127.0.0.1',
  $allow_store_upgrade = false,
  $enable_service      = true)
{
  package { neo4j:
    ensure => present,
  }
  service { neo4j-service:
    enable     => $enable_service,
    ensure     => running,
    require    => Package['neo4j'],
  }

}
