
# git_root: The root URL to access the SR git repositories
class sr-site( $git_root ) {

  # Default PATH
  Exec {
    path => [ "/usr/bin" ],
  }

  # Installed flags for various flavours of data
  file { '/usr/local/var':
    ensure => directory,
    owner => 'root',
    group => 'root',
    mode => '755',
  }

  file { '/usr/local/var/sr':
    ensure => directory,
    owner => 'root',
    group => 'root',
    mode => '700',
    require => File['/usr/local/var'],
  }

  # Anonymous git access
  include gitdaemon

  # The bee
  include bee

  include sr-site::firewall
  include sr-site::mysql
  include sr-site::openldap
  include sr-site::trac
  include sr-site::subversion
  include sr-site::login
  include sr-site::gerrit

  class { 'sr-site::git':
    git_root => $git_root,
  }

  # Web stuff
  class { "www":
    git_root => $git_root,
  }

  class { "backup":
    git_root => $git_root,
  }

  class { "pipebot":
    git_root => $git_root,
  }
}
