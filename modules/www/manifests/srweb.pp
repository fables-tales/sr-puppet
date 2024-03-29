
class www::srweb ( $git_root, $web_root_dir ) {
  package { [ "php", "php-Smarty", "memcached"]:
    ensure => latest,
    notify => Service[ "httpd" ],
  }

  service { 'memcached':
    enable => 'true',
    ensure => 'running',
    hasrestart => 'true',
    hasstatus => 'true',
  }

  file { "${web_root_dir}":
    ensure => directory,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '644',
    before => Vcsrepo[ "${web_root_dir}" ],
  }

  # Maintain a git clone of the website
  vcsrepo { "${web_root_dir}":
    ensure => present,
    user => 'wwwcontent',
    provider => git,
    source => "${git_root}/srweb.git",
    revision => "origin/master",
    force => true,
    require => Package[ "php" ],
  }

  # srweb needs this directory to belong to apache
  file { "${web_root_dir}/templates_compiled":
    ensure => directory,
    owner => "wwwcontent",
    group => "apache",
    mode => "u=rwx,g=rwxs,o=rx",
    recurse => false,
    require => Vcsrepo[ "${web_root_dir}" ],
  }

  $srweb_live_site = extlookup('srweb_live_site')
  file { "${web_root_dir}/local.config.inc.php":
    ensure => present,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '640',
    content => template('www/srweb_local.config.inc.php.erb'),
    require => Vcsrepo["${web_root_dir}"],
  }

  # Set the rewrite base
  exec { "rewritebase":
    command => "sed -i .htaccess -e 's#/~chris/srweb#/#'",
    onlyif => "grep '~chris' /var/www/html/.htaccess",
    cwd => "${web_root_dir}",
    subscribe => Vcsrepo[ "${web_root_dir}" ],
  }

  # Maintain existance and permissions on the 404log.
  file { "${web_root_dir}/404log":
    ensure => present,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '664',
  }

  # Configure php
  file { '/etc/php.ini':
    ensure => present,
    owner => 'root',
    group => 'root',
    mode => '644',
    source => 'puppet:///modules/www/php.ini',
  }

  # Create subscribed_people. No need for extended acls because we don't need
  # the group to be www-admin any more.
  file { "${web_root_dir}/subscribed_people.csv":
    ensure => present,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '660',
  }
}
