
class www::httpd {
  $anonpw = extlookup("ldap_anon_user_pw")

  # trac config is in ssl.conf, so we need that
  require sr-site::trac

  package { [ "httpd", "mod_ssl" ]:
    ensure => latest,
  }

  # Ensure /var/www belongs to wwwcontent, allowing vcsrepos to be cloned
  # into it.
  file { '/var/www':
    ensure => directory,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '755',
  }

  # Load some configuration for httpd.conf
  $www_canonical_hostname = extlookup('www_canonical_hostname')
  $www_base_hostname = extlookup('www_base_hostname')
  file { "httpd.conf":
    path => "/etc/httpd/conf/httpd.conf",
    owner => root,
    group => root,
    mode => "0600",
    content => template('www/httpd.conf.erb'),
    require => Package[ "httpd" ],
  }

  file { "ssl.conf":
    path => "/etc/httpd/conf.d/ssl.conf",
    owner => root,
    group => root,
    mode => "0600",
    content => template('www/ssl.conf.erb'),
    require => Package[ "mod_ssl" ],
    notify => Service['httpd'],
  }

  file { "server.crt":
    path => "/etc/pki/tls/certs/server.crt",
    owner => root,
    group => root,
    mode => "0400",
    source => "/srv/secrets/https/server.crt",
    require => Package[ "mod_ssl" ],
  }

  file { "server.key":
    path => "/etc/pki/tls/private/server.key",
    owner => root,
    group => root,
    mode => "0400",
    source => "/srv/secrets/https/server.key",
    require => Package[ "mod_ssl" ],
  }

  if $devmode == "0" {
    file { "cert_chain":
      path => "/etc/pki/tls/certs/gd_bundle.crt",
      owner => 'root',
      group => 'root',
      mode => '0400',
      source => '/srv/secrets/https/gd_bundle.crt',
      require => Package[ "mod_ssl" ],
    }
  }

  service { "httpd":
    enable => true,
    ensure => running,
    subscribe => [ Package[ "httpd" ],
                   Package[ "mod_ssl" ],
                   File[ "httpd.conf" ],
                   File[ "ssl.conf" ],
                   File[ "server.key"] ],
  }
}
