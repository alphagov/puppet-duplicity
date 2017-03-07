define duplicity::job(
  $spoolfile,
  $ensure = 'present',
  $directory = undef,
  $target = undef,
  $bucket = undef,
  $dest_id = undef,
  $dest_key = undef,
  $folder = undef,
  $cloud = undef,
  $user = 'root',
  $ssh_id = undef,
  $pubkey_id = undef,
  $full_if_older_than = undef,
  $pre_command = undef,
  $post_command = undef,
  $remove_all_but_n_full = undef,
  $archive_directory = '~/.cache/duplicity/',
  $s3_use_multiprocessing = undef,
  $s3_multipart_chunk_size = undef,
) {

  include duplicity::params
  include duplicity::packages

  if ($target and ($cloud or $bucket or $folder)) {
    fail('The target parameter and the combination of the cloud, bucket and folder parameters are mutually exclusive. Please use the target parameter, the others are deprecated.')
  }

  $_target = $target ? {
    undef => $duplicity::params::target,
    default => $target
  }

  if (!$_target) {
    # target takes precedence over cloud parameters
    $_bucket = $bucket ? {
      undef => $duplicity::params::bucket,
      default => $bucket
    }

    $_folder = $folder ? {
      undef => $duplicity::params::folder,
      default => $folder
    }

    $_cloud = $cloud ? {
      undef => $duplicity::params::cloud,
      default => $cloud
    }
  }

  $_dest_id = $dest_id ? {
    undef => $duplicity::params::dest_id,
    default => $dest_id
  }

  $_dest_key = $dest_key ? {
    undef => $duplicity::params::dest_key,
    default => $dest_key
  }

  $_ssh_id = $ssh_id ? {
    undef => $duplicity::params::ssh_id,
    default => $ssh_id
  }

  $_pubkey_id = $pubkey_id ? {
    undef => $duplicity::params::pubkey_id,
    default => $pubkey_id
  }

  $_full_if_older_than = $full_if_older_than ? {
    undef => $duplicity::params::full_if_older_than,
    default => $full_if_older_than
  }

  $_pre_command = $pre_command ? {
    undef => '',
    default => "${pre_command} && "
  }

  $_post_command = $post_command ? {
    undef => '',
    default => $post_command,
  }

  $_remove_all_but_n_full = $remove_all_but_n_full ? {
    undef   => $duplicity::params::remove_all_but_n_full,
    default => $remove_all_but_n_full,
  }

  $_ssh_options = $_ssh_id ? {
    undef => ' ',
    default => " --ssh-options -oIdentityFile='${_ssh_id}' "
  }

  $_s3_use_multiprocessing = $s3_use_multiprocessing ? {
    undef => '',
    false => '',
    true  => '--s3-use-multiprocessing ',
  }

  $_s3_multipart_chunk_size = $s3_multipart_chunk_size ? {
    undef => '',
    default => "--s3-multipart-chunk-size=${s3_multipart_chunk_size} ",
  }

  # convert the old cloud, bucket and target parameters into the new target parameter
  if (! $_target) {

    warning('The cloud, bucket and folder parameters are deprecated. Please change your manifests to use the more general target parameter.')

    $_url = $_cloud ? {
      'cf' => "cf+http://${_bucket}",
      's3' => "s3+http://${_bucket}/${_folder}/${name}/",
      'file' => "file://${_bucket}"
    }
  } else {
    $_url = $_target
  }

  case $ensure {
    'present' : {

      if !$directory {
        fail('directory parameter has to be passed if ensure != absent')
      }

      if !$_url {
        fail('You need to define a target URL!')
      }

    }

    'absent' : {
    }
    default : {
      fail('ensure parameter must be absent or present')
    }
  }

  $_scheme = regsubst($_url, '^([^:]*):.*$', '\1')

  $_environment = $_scheme ? {
    'cf+http' => ["CLOUDFILES_USERNAME='${_dest_id}'", "CLOUDFILES_APIKEY='${_dest_key}'"],
    /s3|s3\+http/ => ["AWS_ACCESS_KEY_ID='${_dest_id}'", "AWS_SECRET_ACCESS_KEY='${_dest_key}'"],
    default => [],
  }

  if is_array($directory) {
    $_directories = $directory
  } else {
    $_directories = [$directory]
  }

  if ! $_pubkey_id {
    $_encryption = '--no-encryption'
  } else {
    if is_array($_pubkey_id) {
      $_pubkeys = $_pubkey_id
    } else {
      $_pubkeys = [$_pubkey_id]
    }
    $_encryption = inline_template('--gpg-options \'--trust-model=always\' <% @_pubkeys.each do |key| %>--encrypt-key \'<%= key %>\' <% end %>')
    $_keystr = join([ "'", join($_pubkeys, "' '"), "'" ], '')
    $_numkeys = size($_pubkeys)
    exec { "duplicity-pgp-${title}":
      command => "gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys ${_keystr}",
      path    => '/usr/bin:/usr/sbin:/bin',
      user    => $user,
      unless  => "test $(gpg --with-colons --list-keys ${_keystr} | grep '^pub:' | wc -l) -eq ${_numkeys}"
    }
  }

  $_remove_all_but_n_full_command = $_remove_all_but_n_full ? {
    undef => '',
    default => " && duplicity remove-all-but-n-full ${_remove_all_but_n_full} --verbosity warning --s3-use-new-style ${_s3_use_multiprocessing}${_s3_multipart_chunk_size}${_encryption}${_ssh_options}--force --archive-dir ${archive_directory} ${_url}"
  }

  file { $spoolfile:
    ensure  => $ensure,
    content => template('duplicity/file-backup.sh.erb'),
    owner   => $user,
    mode    => '0700',
  }

}
