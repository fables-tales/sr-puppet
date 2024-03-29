
class sr-site::fw_pre {

  firewall { "000 accept all icmp":
    proto  => "icmp",
    action => "accept",
  }

  firewall { "001 allow loopback":
    iniface => "lo",
    chain => "INPUT",
    action => "accept",
  }

  firewall { "000 INPUT allow related and established":
    state => ["RELATED", "ESTABLISHED"],
    action => "accept",
    proto => "all",
  }

  firewall { "002 ssh":
    proto  => "tcp",
    dport => 22,
    action => "accept",
  }

  firewall { "003 git":
    proto => "tcp",
    dport => 9418,
    action => "accept",
  }

  firewall { "004 http":
    proto => "tcp",
    dport => 80,
    action => "accept",
  }

  firewall { "005 https":
    proto => "tcp",
    dport => 443,
    action => "accept",
  }

  firewall { "006 gerrit-http":
    proto => "tcp",
    dport => "8081",
    action => "accept",
    source => "127.0.0.1", # Limit to only apache reverse-proxying.
  }

  firewall { "007 gerrit-sshd":
    proto => "tcp",
    dport => "29418",
    action => "accept",
  }
}
