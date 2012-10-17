class www::voting ($git_root, $web_root_dir) {
  package { 'PyYAML':
    ensure => present,
  }

  vcsrepo { "${web_root_dir}/voting":
    ensure => present,
    provider => git,
    source => "${git_root}/voting.git",
    revision => "master",
    force => true,
    require => Package['PyYAML'],
  }
}