class duplicity::packages (
  $version = 'present',
  ) {

  # Install the packages
  ensure_packages([
    'python-paramiko',
    'python-gobject-2',
    'python-boto',
    'gnupg',
  ])

  package {'duplicity':
    ensure => $version,
  }
}
