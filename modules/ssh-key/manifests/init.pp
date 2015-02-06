#
class ssh-key
()
{
  file { 'if-do43-key-final.pem':
          path    => '/root/.ssh/if-do43-key-final.pem',
          ensure  => file,
          content => template ("ssh-key/if-do43-key-final.pem.erb"),
          mode => 700,
        }

file { 'config':
          path    => '/root/.ssh/config',
          ensure  => file,
          content => template ("ssh-key/config.erb"),
          mode => 700,
     }                                          
}


