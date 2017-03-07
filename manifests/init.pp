define duplicity(
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
  $weekday = undef,
  $hour = undef,
  $minute = undef,
  $full_if_older_than = undef,
  $pre_command = undef,
  $post_command = undef,
  $remove_all_but_n_full = undef,
  $archive_directory = undef,
  $s3_use_multiprocessing = undef,
  $s3_multipart_chunk_size = undef,
) {

  include duplicity::params
  include duplicity::packages

  $spoolfile = "${duplicity::params::job_spool}/${name}.sh"

  duplicity::job { $name :
    ensure                  => $ensure,
    spoolfile               => $spoolfile,
    directory               => $directory,
    target                  => $target,
    bucket                  => $bucket,
    dest_id                 => $dest_id,
    dest_key                => $dest_key,
    folder                  => $folder,
    cloud                   => $cloud,
    user                    => $user,
    ssh_id                  => $ssh_id,
    pubkey_id               => $pubkey_id,
    full_if_older_than      => $full_if_older_than,
    pre_command             => $pre_command,
    post_command            => $post_command,
    remove_all_but_n_full   => $remove_all_but_n_full,
    archive_directory       => $archive_directory,
    s3_use_multiprocessing  => $s3_use_multiprocessing,
    s3_multipart_chunk_size => $s3_multipart_chunk_size,
  }

  $_weekday = $weekday ? {
    undef   => $duplicity::params::weekday,
    default => $weekday
  }

  $_hour = $hour ? {
    undef   => $duplicity::params::hour,
    default => $hour
  }

  $_minute = $minute ? {
    undef   => $duplicity::params::minute,
    default => $minute
  }

  cron { $name :
    ensure  => $ensure,
    command => $spoolfile,
    user    => $user,
    minute  => $_minute,
    hour    => $_hour,
    weekday => $_weekday,
  }

  File[$spoolfile]->Cron[$name]
}
