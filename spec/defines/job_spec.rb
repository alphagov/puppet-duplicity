require 'spec_helper'

describe 'duplicity::job' do

  fqdn = 'somehost.domaindomain.org'

  let(:facts) {
    {
      :fqdn => fqdn
    }
  }

  let(:title) { 'some_backup_name' }

  let(:spoolfile) { "/var/spool/duplicity/#{title}.sh" }

  let(:params) {
    {
      :bucket    => 'somebucket',
      :directory => '/etc/',
      :dest_id   => 'some_id',
      :dest_key  => 'some_key',
      :spoolfile => spoolfile,
    }
  }

  it 'should be owned by root and only accessable by root and only root' do
    should contain_file(spoolfile) \
      .with_owner('root') \
      .with_mode('0700')
  end

  context "non-root user" do
    let(:params) {
      {
        :user      => 'devops',
        :directory => '/etc',
        :spoolfile => spoolfile,
      }
    }

    it 'should be owned and only acessible by specified user' do
      should contain_file(spoolfile) \
        .with_owner('devops') \
        .with_mode('0700')
    end
  end

  context "multiple directories" do
    let(:params) {
      {
        :bucket    => 'somebucket',
        :directory => ['/etc/', '/var/'],
        :dest_id   => 'some_id',
        :dest_key  => 'some_key',
        :cloud     => 'cf',
        :spoolfile => spoolfile,
      }
    }

    it "adds a spoolfile which contains the backup directories" do
      should contain_file(spoolfile) \
        .with_content(/duplicity .* --include '\/etc\/' --include '\/var\/' /)
    end
  end

  context "cloud files environment" do

    let(:params) {
      {
        :bucket    => 'somebucket',
        :directory => '/etc/',
        :dest_id   => 'some_id',
        :dest_key  => 'some_key',
        :cloud     => 'cf',
        :spoolfile => spoolfile,
      }
    }

    it "adds a spoolfile which contains the generated backup script" do
      should contain_file(spoolfile) \
        .with_content(/CLOUDFILES_USERNAME='some_id'/)\
        .with_content(/CLOUDFILES_APIKEY='some_key'/)\
        .with_content(/duplicity --verbosity warning --no-print-statistics --full-if-older-than 30D --s3-use-new-style --no-encryption --include '\/etc\/' --exclude '\*\*' --archive-dir ~\/.cache\/duplicity\/ \/ 'cf\+http:\/\/somebucket'/)
    end
  end

  context "without encryption" do

    let(:params) {
      {
        :bucket       => 'somebucket',
        :directory    => '/etc/',
        :dest_id  => 'some_id',
        :dest_key => 'some_key',
        :spoolfile => spoolfile,
      }
    }

    it "adds spoolfile which contains the generated backup script" do
      should contain_file(spoolfile) \
        .with_content(/AWS_ACCESS_KEY_ID='some_id'/)\
        .with_content(/AWS_SECRET_ACCESS_KEY='some_key'/)\
        .with_content(/duplicity --verbosity warning --no-print-statistics --full-if-older-than 30D --s3-use-new-style --no-encryption --include '\/etc\/' --exclude '\*\*' --archive-dir ~\/.cache\/duplicity\/ \/ 's3\+http:\/\/somebucket\/#{fqdn}\/some_backup_name\/'/)
    end


    it "should make a full backup every X days" do

    end
  end

  context "with a defined archive_directory" do
    let(:params) {
      {
        :bucket       => 'somebucket',
        :directory    => '/etc/',
        :dest_id  => 'some_id',
        :dest_key => 'some_key',
        :spoolfile => spoolfile,
        :archive_directory => '/root/giraffe/neckbeard/',
      }
    }

    it "adds a spoolfile which contains --archive-dir" do
      should contain_file(spoolfile) \
        .with_content(/^duplicity --verbosity warning --no-print-statistics --full-if-older-than 30D --s3-use-new-style --no-encryption --include '\/etc\/' --exclude '\*\*' --archive-dir \/root\/giraffe\/neckbeard\/ \/ 's3\+http:\/\/somebucket\/#{fqdn}\/some_backup_name\/'$/)
    end
  end

  context "with s3_use_multiprocessing set to true" do
    let(:params) {
      {
        :bucket       => 'somebucket',
        :directory    => '/etc/',
        :dest_id  => 'some_id',
        :dest_key => 'some_key',
        :spoolfile => spoolfile,
        :s3_use_multiprocessing => true,
      }
    }

    it "adds a spoolfile which contains --s3-use-multiprocessing" do
      should contain_file(spoolfile) \
        .with_content(/^duplicity --verbosity warning --no-print-statistics --full-if-older-than 30D --s3-use-new-style --s3-use-multiprocessing --no-encryption --include '\/etc\/' --exclude '\*\*' --archive-dir ~\/.cache\/duplicity\/ \/ 's3\+http:\/\/somebucket\/#{fqdn}\/some_backup_name\/'$/)
    end
  end

  context "with s3_use_multiprocessing set to false" do
    let(:params) {
      {
        :bucket       => 'somebucket',
        :directory    => '/etc/',
        :dest_id  => 'some_id',
        :dest_key => 'some_key',
        :spoolfile => spoolfile,
        :s3_use_multiprocessing => false,
      }
    }

    it "adds a spoolfile which does not contain --s3-use-multiprocessing" do
      should contain_file(spoolfile) \
        .with_content(/^duplicity --verbosity warning --no-print-statistics --full-if-older-than 30D --s3-use-new-style --no-encryption --include '\/etc\/' --exclude '\*\*' --archive-dir ~\/.cache\/duplicity\/ \/ 's3\+http:\/\/somebucket\/#{fqdn}\/some_backup_name\/'$/)
    end
  end

  context "with s3_multipart_chunk_size set to 100" do
    let(:params) {
      {
        :bucket       => 'somebucket',
        :directory    => '/etc/',
        :dest_id  => 'some_id',
        :dest_key => 'some_key',
        :spoolfile => spoolfile,
        :s3_multipart_chunk_size => 100,
      }
    }

    it "adds a spoolfile which contains --s3-multipart-chunk-size=100" do
      should contain_file(spoolfile) \
        .with_content(/^duplicity --verbosity warning --no-print-statistics --full-if-older-than 30D --s3-use-new-style --s3-multipart-chunk-size=100 --no-encryption --include '\/etc\/' --exclude '\*\*' --archive-dir ~\/.cache\/duplicity\/ \/ 's3\+http:\/\/somebucket\/#{fqdn}\/some_backup_name\/'$/)
    end
  end

  context "with s3_multipart_max_procs set to 4" do
    let(:params) {
      {
        :bucket       => 'somebucket',
        :directory    => '/etc/',
        :dest_id  => 'some_id',
        :dest_key => 'some_key',
        :spoolfile => spoolfile,
        :s3_multipart_max_procs => 4,
      }
    }

    it "adds a spoolfile which contains --s3-multipart-max-procs=4" do
      should contain_file(spoolfile) \
        .with_content(/^duplicity --verbosity warning --no-print-statistics --full-if-older-than 30D --s3-use-new-style --s3-multipart-max-procs=4 --no-encryption --include '\/etc\/' --exclude '\*\*' --archive-dir ~\/.cache\/duplicity\/ \/ 's3\+http:\/\/somebucket\/#{fqdn}\/some_backup_name\/'$/)
    end
  end

  context "with defined force full-backup" do

    let(:params) {
      {
        :bucket             => 'somebucket',
        :directory          => '/etc/',
        :dest_id            => 'some_id',
        :dest_key           => 'some_key',
        :full_if_older_than => '5D',
        :spoolfile => spoolfile,
      }
    }

    it "should do a full backup after the specified time" do
      should contain_file(spoolfile) \
        .with_content(/--full-if-older-than 5D/)
    end
  end

  context "with defined remove-all-but-n-full" do

    let(:params) {
      {
        :bucket                => 'somebucket',
        :directory             => '/etc/',
        :dest_id               => 'some_id',
        :dest_key              => 'some_key',
        :remove_all_but_n_full => '2',
        :spoolfile             => spoolfile,
      }
    }

    it "should be able to handle a specified remove-all-but-n-full time" do
      should contain_file(spoolfile) \
        .with_content(%r{^duplicity .* --archive-dir ~/.cache/duplicity/ .*&& duplicity remove-all-but-n-full 2 .* --archive-dir ~/.cache/duplicity/ .*})
    end
  end

  context "with defined remove-all-but-n-full and archive-dir" do
    let(:params) {
      {
        :bucket            => 'somebucket',
        :directory         => '/etc/',
        :dest_id           => 'some_id',
        :dest_key          => 'some_key',
        :remove_all_but_n_full => '7',
        :spoolfile         => spoolfile,
        :archive_directory => '/root/giraffe/neckbeard/',
      }
    }

    it "should reference the same --archive-dir in both commands" do
      should contain_file(spoolfile) \
        .with_content(%r{duplicity .* --archive-dir /root/giraffe/neckbeard/ .*&& duplicity remove-all-but-n-full 7 .* --archive-dir /root/giraffe/neckbeard/ .*})
    end
  end

  context "with defined remove-all-but-n-full and s3_use_multiprocessing set to true" do
    let(:params) {
      {
        :bucket            => 'somebucket',
        :directory         => '/etc/',
        :dest_id           => 'some_id',
        :dest_key          => 'some_key',
        :remove_all_but_n_full => '7',
        :spoolfile         => spoolfile,
        :s3_use_multiprocessing => true,
      }
    }

    it "should enable s3_use_multiprocessing in both commands" do
      should contain_file(spoolfile) \
        .with_content(%r{duplicity .* --s3-use-multiprocessing .*&& duplicity remove-all-but-n-full 7 .* --s3-use-multiprocessing .*})
    end
  end

  context "with defined remove-all-but-n-full and s3_multipart_chunk_size set to 250" do
    let(:params) {
      {
        :bucket            => 'somebucket',
        :directory         => '/etc/',
        :dest_id           => 'some_id',
        :dest_key          => 'some_key',
        :remove_all_but_n_full => '7',
        :spoolfile         => spoolfile,
        :s3_multipart_chunk_size => 250,
      }
    }

    it "should set s3_multipart_chunk_size to 250 in both files" do
      should contain_file(spoolfile) \
        .with_content(%r{duplicity .* --s3-multipart-chunk-size=250 .*&& duplicity remove-all-but-n-full 7 .* --s3-multipart-chunk-size=250 .*})
    end
  end

  context "with defined remove-all-but-n-full and s3_multipart_max_procs set to 4" do
    let(:params) {
      {
        :bucket            => 'somebucket',
        :directory         => '/etc/',
        :dest_id           => 'some_id',
        :dest_key          => 'some_key',
        :remove_all_but_n_full => '7',
        :spoolfile         => spoolfile,
        :s3_multipart_max_procs => 4,
      }
    }

    it "should set s3_multipart_max_procs to 4 in both files" do
      should contain_file(spoolfile) \
        .with_content(%r{duplicity .* --s3-multipart-max-procs=4 .*&& duplicity remove-all-but-n-full 7 .* --s3-multipart-max-procs=4 .*})
    end
  end

  context 'duplicity with pubkey encryption' do

    some_pubkey_id = '15ABDA79'
    fqdn = 'somehost.domaindomain.org'

    let(:params) {
      {
        :bucket       => 'somebucket',
        :directory    => '/etc/',
        :dest_id  => 'some_id',
        :dest_key => 'some_key',
        :pubkey_id   => some_pubkey_id,
        :spoolfile => spoolfile,
      }
    }

    it "should use pubkey encryption if keyid is provided" do
      should contain_file(spoolfile) \
        .with_content(/--gpg-options '--trust-model=always' --encrypt-key '#{some_pubkey_id}'/)
    end

    it "should download and import the specified pubkey" do
      should contain_exec("duplicity-pgp-#{title}") \
        .with_command("gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys '#{some_pubkey_id}'") \
        .with_path("/usr/bin:/usr/sbin:/bin") \
        .with_unless(/gpg .* --list-keys '#{some_pubkey_id}'/)
    end
  end

  context 'duplicity with multiple pubkeys for encryption' do
    first_key       = '15ABDA79'
    second_key      = 'DEADBEEF'

    let(:params) {
      {
        :bucket       => 'somebucket',
        :directory    => '/etc/',
        :dest_id  => 'some_id',
        :dest_key => 'some_key',
        :pubkey_id   => [first_key, second_key],
        :spoolfile => spoolfile,
      }
    }

    it "should use pubkey encryption for both keys" do
      should contain_file(spoolfile) \
        .with_content(/--gpg-options '--trust-model=always' --encrypt-key '#{first_key}' --encrypt-key '#{second_key}'/)
    end

    it "should download and import the specified pubkey" do
      should contain_exec("duplicity-pgp-#{title}") \
        .with_command("gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys '#{first_key}' '#{second_key}'") \
        .with_path("/usr/bin:/usr/sbin:/bin") \
        .with_unless(/gpg .* --list-keys '#{first_key}' '#{second_key}'/)
    end
  end

  context 'with default bucket and bucket as param' do
    let(:params) {
      {
        :directory    => '/etc/',
        :bucket       => 'from_param',
        :spoolfile => spoolfile,
      }
    }

    let (:pre_condition) {
      "class { 'duplicity::params' :
        bucket => 'default',
        dest_id => 'some_id',
        dest_key => 'some_key'
      }"
    }

    it "should override default bucket with param" do
      should contain_file(spoolfile) \
        .with_content(/from_param/)
    end
  end

  context 'duplicity defaults' do
    let(:params) {
      {
        :directory    => '/etc/',
        :spoolfile => spoolfile,
      }
    }

    let (:pre_condition) {
      "class { 'duplicity::params' :
        bucket => 'another_bucket',
        dest_id => 'some_id',
        dest_key => 'some_key'
      }"
    }

    it "contains package" do
      should contain_package('duplicity')
      should contain_package('gnupg')
    end

    it "should be able to set a global cloud key pair config" do
      should contain_file(spoolfile) \
        .with_content(/AWS_ACCESS_KEY_ID='some_id'/)\
        .with_content(/AWS_SECRET_ACCESS_KEY='some_key'/)\
        .with_content(/another_bucket/)

    end

    it "should be able to set a global pubkey id" do
    end
  end

  context "with pre_command" do

    let(:params) {
      {
        :bucket       => 'somebucket',
        :directory    => '/root/mysqldump',
        :dest_id      => 'some_id',
        :dest_key     => 'some_key',
        :pre_command  => 'mysqldump database',
        :spoolfile => spoolfile,
      }
    }

    it "should prepend pre_command to cronjob" do
      should contain_file(spoolfile) \
        .with_content(/^mysqldump database && /)
    end
  end

  context "with post_command" do

    let(:params) {
      {
        :bucket       => 'somebucket',
        :directory    => '/root/mysqldump',
        :dest_id      => 'some_id',
        :dest_key     => 'some_key',
        :pre_command  => 'mysqldump database',
        :post_command => 'echo Hello World',
        :spoolfile    => spoolfile,
      }
    }

    it "should append post_command to cronjob" do
      should contain_file(spoolfile) \
        .with_content(/^duplicity .+\necho Hello World\n\Z/)
    end
  end

  context 'with ensure => absent' do

    let(:params) {
      {
        :ensure       => 'absent',
        :spoolfile => spoolfile,
      }
    }

    it 'should remove the job file' do
      should contain_file(spoolfile) \
        .with_ensure('absent')
    end

  end

  context 'cloud and target are incompatible' do

    let(:params) {
      {
        :target       => 'ssh://someserver//some/dir',
        :bucket       => 'somebucket',
        :directory    => '/root/mysqldump',
        :dest_id      => 'some_id',
        :dest_key     => 'some_key',
        :spoolfile => spoolfile,
      }
    }

    it 'should fail with an error' do
      expect {
        should contain_file(spoolfile)
      }.to raise_error(Puppet::Error)
    end
  end

  context 'ssh target' do

    let(:params) {
      {
        :target                => 'ssh://someserver//some/dir',
        :ssh_id                => '/etc/duplicity/id_rsa',
        :cloud                 => false,
        :bucket                => false,
        :directory             => '/root/mysqldump',
        :remove_all_but_n_full => '1Y',
        :spoolfile => spoolfile,
      }
    }

    it 'should contain target url and ssh-id in spoolfile' do
      should contain_file(spoolfile) \
      .with_content(/ssh:\/\/someserver\/\/some\/dir/)
      .with_content(/^duplicity .* --ssh-options -oIdentityFile=\'\/etc\/duplicity\/id_rsa\'/)
      .with_content(/&& duplicity remove-all-but-n-full .* --ssh-options -oIdentityFile=\'\/etc\/duplicity\/id_rsa\'/)
    end
  end
end
