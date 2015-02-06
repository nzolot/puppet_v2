class tomcat::configs (
    )
{

  file { 'server.xml':
    path    => '/etc/tomcat7/server.xml',
    source  => 'puppet:///modules/tomcat/server.xml',
    owner => 'root', 
    group => 'root', 
    mode => 644,
    require => Package['tomcat7'],
    notify  => Service['tomcat7'],
  }

}

