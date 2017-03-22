# Define how Apache should be installed and configured

class { 'nubis_apache':
  update_script_source   => 'puppet:///nubis/files/update-site.sh',
  update_script_interval => {
    minute => [ fqdn_rand(30), ( fqdn_rand(30) + 30 ) % 60],
  },
}

apache::vhost { $project_name:
    serveradmin        => 'webops@mozilla.com',
    port               => 80,
    default_vhost      => true,
    docroot            => '/var/www/html',
    directoryindex     => 'index.htm',
    docroot_owner      => 'root',
    docroot_group      => 'root',
    block              => ['scm'],
    setenvif           => [
      'X-Forwarded-Proto https HTTPS=on',
      'Remote_Addr 127\.0\.0\.1 internal',
      'Remote_Addr ^10\. internal',
    ],
    access_log_env_var => '!internal',
    access_log_format  => '%a %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-agent}i\"',
    custom_fragment    => "
# Clustered without coordination
FileETag None
",
    headers            => [
      "set X-Nubis-Version ${project_version}",
      "set X-Nubis-Project ${project_name}",
      "set X-Nubis-Build   ${packer_build_name}",
    ],
    rewrites           => [
      {
        comment      => 'HTTPS redirect',
        rewrite_cond => ['%{HTTP:X-Forwarded-Proto} =http'],
        rewrite_rule => ['. https://%{HTTP:Host}%{REQUEST_URI} [L,R=permanent]'],
      }
    ]
}
