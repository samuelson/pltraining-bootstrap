class bootstrap::profile::guacamole {

  include docker
  docker::run {'ciab-guacd':
    image => 'glyptodon/guacd'
  }
  docker::run {'ciab-guacamole':
    image            => 'glyptodon/guacamole',
    links            => ['ciab-guacd:guacd'],
    ports            => ['8080'],
    env              => [
      "MYSQL_HOSTNAME=${::fqdn}",
      'MYSQL_DATABASE=guacamole_db',
      'MYSQL_USER=guacamole_user',
      'MYSQL_PASSWORD=some_password',
    ],
    extra_parameters => [
      "--add-host ${::fqdn}:${::networking['ip']}",
    ],
    require => [Mysql::Db['guacamole_db'],Docker::Run['ciab-guacd']],
  }

  file { '/usr/src/guacamole':
    ensure => directory,
  }
  file { '/usr/src/guacamole/initdb.sql':
    ensure => file,
    source  => 'puppet:///modules/bootstrap/initdb.sql',
  }

  $override_options = {
    'mysqld' => {
      'bind-address' => '0.0.0.0',
    }
  }
  class {'::mysql::server':
    override_options => $override_options,
  }
  mysql::db {'guacamole_db':
    user     => 'guacamole_user',
    password => 'some_password',
    host     => '%',
    grant    => ['SELECT','INSERT','UPDATE','DELETE'],
    sql      => '/usr/src/guacamole/initdb.sql',
    require  => File['/usr/src/guacamole/initdb.sql'],
  }
  firewall { '010 allow mysql':
    proto  => 'tcp',
    action => 'accept',
    dport   => '3306',
  }
    
}