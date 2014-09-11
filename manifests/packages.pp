class duplicity::packages {
  # Install the packages
  package {
    ['duplicity',
     'python-boto',
     'gnupg',
     'python-paramiko',
     'python-gobject-2'
    ]:
      ensure => present
  }
}
