class www::piwik ( $git_root, $root_dir ) {
  package { ['php-gd']:
    ensure => present,
    notify => Service['httpd'],
  }

  vcsrepo { "${root_dir}":
    ensure => present,
    user => 'wwwcontent',
    provider => git,
    source => 'git://github.com/piwik/piwik.git',
    revision => '1.8.4',
    force => true,
    require => Package['php-gd', 'php-mysql'],
  }

  $piwik_user = extlookup('piwik_sql_user')
  $piwik_pw = extlookup('piwik_sql_pw')
  mysql::db { 'piwik':
    user => $piwik_user,
    password => $piwik_pw,
    host => 'localhost',
    grant => ['all'],
  }

  file { "${root_dir}/tmp":
    ensure => directory,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '2770',
    require => Vcsrepo["${root_dir}"],
  }

  file { "${root_dir}/tmp/templates_c":
    ensure => directory,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '2770',
    require => Vcsrepo["${root_dir}"],
  }

  file { "${root_dir}/tmp/cache":
    ensure => directory,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '2770',
    require => Vcsrepo["${root_dir}"],
  }

  file { "${root_dir}/tmp/assets":
    ensure => directory,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '2770',
    require => Vcsrepo["${root_dir}"],
  }

  file { "${root_dir}/tmp/tcpdf":
    ensure => directory,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '2770',
    require => Vcsrepo["${root_dir}"],
  }

  file { "${root_dir}/config":
    ensure => directory,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '2770',
    require => Vcsrepo["${root_dir}"],
  }

  file { "${root_dir}/tmp/sessions":
    ensure => directory,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '2770',
    require => Vcsrepo["${root_dir}"],
  }

  file { "${root_dir}/tmp/latest":
    ensure => directory,
    owner => 'wwwcontent',
    group => 'apache',
    mode => '2770',
    require => Vcsrepo["${root_dir}"],
  }
}
