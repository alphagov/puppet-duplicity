class duplicity::packages {
  # Install the packages
  package {
    ['python-boto', 'gnupg']: ensure => present
  }

  package { 'duplicity':
    ensure => 0.6.24,
  }
}
