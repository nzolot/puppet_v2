# Manage tomcat webserver
class tomcat {

  include tomcat::configs

  package { 'tomcat7':
    ensure => latest,
    require => Package ['httpd', 'jdk'],
  }

  file { '/etc/profile.d/tomcat.sh':
    content => 'export CATALINA_HOME=/usr/share/tomcat7
    export PATH=${CATALINA_HOME}/bin:${PATH}',
  }

  service { 'tomcat7':
    ensure  => running,
    enable  => true,
    hasstatus => false,
    hasrestart => true,
    require => [Package['tomcat7'], File["server.xml"]],
  }

}

