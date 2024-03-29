
class sr-site::openldap {
  class { 'ldap':
    server => 'true',
    client => 'true',
    localloginok => 'true',
  }

  ldap::define::domain { 'studentrobotics.org':
    ensure => 'present',
    basedn => 'o=sr',
    rootdn => 'cn=Manager', # basedn is jammed on the front of this.
    rootpw => extlookup("ldap_manager_pw"),
  }

  ldap::client::config { 'studentrobotics.org':
    ensure => 'present',
    servers => ['localhost'],
    ssl => 'false',
    base_dn => 'o=sr',
  }

  Ldapres {
    binddn => 'cn=Manager,o=sr',
    bindpw => extlookup("ldap_manager_pw"),
    ldapserverhost => 'localhost',
    ldapserverport => '389',
    require => Class['ldap'],
  }

  # Ensure that test-date from the openldap module's base ldif is removed.
  ldapres { "ou=people,o=sr":
    ensure => absent,
    objectclass => 'organizationalUnit',
    # I hope what this means is "require uid=test is absent first".
    # Because it's fully the wrong order otherwise.
    require => Ldapres['uid=test,ou=people,o=sr'],
  }

  ldapres { "uid=test,ou=people,o=sr":
    ensure => absent,
    objectclass => 'inetOrgPerson',
  }

  # Organizational unit for storing LDAP groups
  ldapres { "ou=groups,o=sr":
    ensure => present,
    objectclass => 'organizationalUnit',
  }

  # Organizational unit for storing LDAP users
  ldapres { "ou=users,o=sr":
    ensure => present,
    objectclass => 'organizationalUnit',
  }

  # SR anonymous user. This is probably a misnomer: "anon" has always been able
  # to access almost all data, everywhere. It's used by things like nscd and
  # apache to bind to ldap and find out various things such as group membership.
  # Essentially it's a catch-all privileged account, but crucially that can't
  # write to anything.
  ldapres { "uid=anon,ou=users,o=sr":
    ensure => present,
    objectclass => ["inetOrgPerson", "uidObject", "posixAccount"],
    uid => "anon",
    cn => "Anon user",
    sn => "Anon user",
    uidnumber => '2043',
    gidnumber => '1999',
    homedirectory => '/home/anon',
    userpassword => extlookup("ldap_anon_user_ssha_pw"),
  }

  file { '/etc/ldap.secret':
    ensure => present,
    content => extlookup('ldap_manager_pw'),
    owner => "root",
    group => "root",
    mode => "0600",
  }

  # Put some data in variables for blowing into pam_ldap.conf via a template.
  # These could be used to configure the rest of this class, but that would
  # probably be pointless.
  $serverhostname = 'localhost'
  $basedn = 'o=sr'
  $anonbinddn = 'uid=anon,ou=users,o=sr'
  $anonbindpw = extlookup("ldap_anon_user_pw")
  $managerdn = 'cn=Manager,o=sr'
  $logingroupname = 'shell-users'
  $groupdn = 'ou=groups,o=sr'
  $passwddn = 'ou=users,o=sr'
  $logingroupdn = "cn=${logingroupname},${groupdn}"
  $logingroupattr = 'memberUid'

  # Configure the LDAP PAM module. This tells pam all about how we want logins
  # to the machine to occur, how to bind to the ldap server, how to lookup
  # groups and so forth. It also informs the NSS server about similar facts.
  file { '/etc/pam_ldap.conf':
    ensure => present,
    content => template('sr-site/pam_ldap.conf.erb'),
    owner => "root",
    group => "root",
    mode => "0600",
    require => File['/etc/ldap.secret'],
  }

  # Make nss_ldap.conf point at pam_ldap.conf. They both contain the same
  # data in the same format, nothing is achieved by duplicating them.
  file { '/etc/nss_ldap.conf':
    ensure => link,
    target => '/etc/pam_ldap.conf',
    owner => "root",
    group => "root",
    mode => "0600",
    notify => Service["nscd"],
    require => File['/etc/pam_ldap.conf'],
  }

  # Ensure that the login group exists in ldap. No configuration of its member
  # attributes, that counts as data.
  ldapres { "$logingroupdn":
    ensure => present,
    cn => $logingroupname,
    objectclass => "posixGroup",
    gidnumber => 3046,
    notify => Exec['ldap-groups-flushed'],
    require => Ldapres["$groupdn"],
  }

  # Add srusers group. I have no idea what its purpose is, but that's what
  # everyones primary unix group is.
  ldapres { "cn=srusers,$groupdn":
    ensure => present,
    cn => 'srusers',
    objectclass => "posixGroup",
    gidnumber => 1999,
    notify => Exec['ldap-groups-flushed'],
    require => Ldapres["$groupdn"],
  }

  ldapres { "cn=mentors,$groupdn":
    ensure => present,
    cn => 'mentors',
    objectclass => "posixGroup",
    gidnumber => 2001,
    # Don't enable memberuid, or puppet will try to manage it. Without memberuid
    # all puppet will do is ensure that cn=mentors exists, without attempting
    # to configure who's a member
    # memberuid => blah
    notify => Exec['ldap-groups-flushed'],
    require => Ldapres["$groupdn"],
  }

  # A command to flush ldap groups. The idea here is that we flush/restart nscd
  # after any modifications have been made to ldap group records. That way, any
  # cached data is cleared. Plus, resources that depend on an ldap group
  # existing can now depend on this happening.
  exec { 'ldap-groups-flushed':
    command => '/sbin/nscd -i group',
    require => Class['ldap'],
    refreshonly => true,
  }

  file { "${ldap::params::lp_tmp_dir}/acl.d/studentrobotics.org-myeyes.conf":
    ensure => present,
    owner => 'ldap',
    group => 'ldap',
    mode => '440',
    source => 'puppet:///modules/sr-site/ldap_acl.conf',
    notify => Class['ldap::server::rebuild'],
  }

  exec { 'pop_ldap':
    command => "ldapadd -D cn=Manager,o=sr -y /etc/ldap.secret -x -h localhost -f /srv/secrets/ldap/ldap_backup; if test $? != 0; then exit 1; fi; touch /usr/local/var/sr/ldap_installed",
    provider => 'shell',
    creates => '/usr/local/var/sr/ldap_installed',

    # Synchronise against all relevant ldap groups and users being added,
    require => [Exec['ldap-groups-flushed'], File['/etc/ldap.secret']],
  }
}
