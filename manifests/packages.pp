class duplicity::packages (
  $version = 'present',
  ) {
  # Install the packages
  package {[
            'python-paramiko',
            'python-gobject-2',
            'python-boto',
            'gnupg'
            ]:
          ensure => present
  }
  package {'duplicity':
    ensure => $version,
  }
}
