class www::voting ($git_root, $web_root_dir) {
  package { 'PyYAML':
    ensure => present,
  }

  file { '/home/voting':
    ensure => directory,
    owner => 'voting',
    group => 'users',
    mode => '711',
    require => User['voting'],
  }

  file { '/home/voting/public_html':
    ensure => directory,
    owner => 'voting',
    group => 'users',
    mode => '711',
    require => [User['voting'], File['/home/voting']],
  }

  user { 'voting':
    ensure => present,
    comment => 'Owner of voting record files',
    shell => '/sbin/nologin',
    gid => 'users',
    home => '/home/voting',
  }

  vcsrepo { "/home/voting/public_html/voting":
    ensure => present,
    provider => git,
    source => "${git_root}/voting.git",
    revision => "origin/master",
    force => true,
    require => [Package['PyYAML'], User['voting']],
    owner => 'voting',
    group => 'users',
  }

  file { '/home/voting/public_html/voting/votes':
    ensure => directory,
    owner => 'voting',
    group => 'users',
    mode => '700', # Prohibit people from seeing who voted.
    require => Vcsrepo['/home/voting/public_html/voting'],
  }
}
