#Zabbix server config class
class zabbix::server ()
{
#Define empty vars
    $zabbix_server_name     = hiera('zabbix_server_name', 'zabbix')
    $zabbix_mysql_host      = hiera('zabbix_mysql_host', 'localhost')      #Define mysql host of Zabbix server DB
    $zabbix_mysql_name      = hiera('zabbix_mysql_name', 'zabbix')      #Define mysql DB name
    $zabbix_mysql_user      = hiera('zabbix_mysql_user', 'zabbix')      #Define user for zabbix
    $zabbix_mysql_pass      = hiera('zabbix_mysql_pass', 'zabbix')      #Define password for user above (cannot be blank!)
    $zabbix_mysql_root_user = hiera('zabbix_mysql_root_user', 'root') #Define root mysql user
    $zabbix_mysql_root_pass = hiera('zabbix_mysql_root_pass', '') #Define root mysql password (cannot be blank!)
    $zabbix_mysql_base      = hiera('zabbix_mysql_base', 'zabbix')      #Define database for zabbix
    $zabbix_front_user      = hiera('zabbix_front_user', 'zabbix')      #Define Username for frontend user
    $zabbix_front_pass      = hiera('zabbix_front_pass', 'zabbix')      #Define Password for frontend user
    $zabbix_import_dir      = hiera('zabbix_import_dir', '/etc/zabbix')      #Define where configuration files are


#Services

    service{'zabbix-server':
        ensure  => 'running',
        enable => true,
        notify => Service["httpd"],
        require => [Service["mysqld"], Package['zabbix-server-mysql', "zabbix-web-mysql"]]
    }
    
    service {"httpd":
        name => 'httpd',
        ensure => 'running',
        enable => true,
        require => Package['httpd']
    }
    
    service {"mysqld":
        name => 'mysqld',
        ensure  => 'running',
        enable => true,
        require => Package['mysql-server']
    }
    
    service {"zabbix-java-gateway":
        name   => 'zabbix-java-gateway',
        ensure => 'running',
        enable => 'true',
        require => [Package['zabbix-java-gateway'], File['zabbix_java_gateway.conf']]
    }

#Packages
        
    package {'httpd':
        ensure => 'installed'
    }

    package {'zabbix-server-mysql':
        ensure => 'installed',
        require => Package['php','mysql-server']
    }

    package {'zabbix-java-gateway':
        ensure => 'installed',
        require => Package['zabbix-server-mysql']
    }
    
    package {'zabbix-web-mysql':
        ensure => 'installed',
        require => Package['httpd']
    }

    package {'mysql-server':
        ensure => 'installed'
    }

    package {'php':
        ensure => 'installed'
    }
    
    package {'mysql':
        ensure => 'installed'
    }


#Configs

    file { 'zabbix_server.conf':
        path    => '/etc/zabbix/zabbix_server.conf',
        ensure  => file,
        require => Package['zabbix-server-mysql'],
        content => template("zabbix/configs/zabbix_server.conf.erb"),
        notify  => Service['zabbix-server']
    }
      
    file { 'httpd_zabbix.conf':
        path    => '/etc/httpd/conf.d/zabbix.conf',
        ensure  => file,
        require => Package['zabbix-server-mysql'],
        content => template("zabbix/configs/httpd_zabbix.conf.erb"),
        notify  => Service['zabbix-server']
    }

    file { 'zabbix.conf.php':
        path    => '/etc/zabbix/web/zabbix.conf.php',
        ensure  => file,
        require => Package['zabbix-web-mysql', 'zabbix-server-mysql'],
        content => template("zabbix/configs/zabbix.conf.php.erb"),
        notify  => Service['zabbix-server']
     }
    
    file { 'zabbix_import':
        path    => '/etc/zabbix/zabbix_import',
        ensure  => directory,
        force   => true,
        recurse => true,
        purge   => true,
        source  => "puppet:///modules/zabbix/zabbix_import/${zabbix_import_dir}"
    }
    file { 'zabbix_java_gateway.conf':
        path    => '/etc/zabbix/zabbix_java_gateway.conf',
        ensure  => file,
        require => Package ['zabbix-java-gateway'],
        content => template("zabbix/configs/zabbix_java_gateway.conf.erb"),
        notify  => Service ['zabbix-java-gateway']
    }


#Scripts
    exec { "run_zabbix_db_check.sh":
        command => "/bin/bash /etc/zabbix/zabbix_db_check.sh $zabbix_mysql_root_user $zabbix_mysql_root_pass $zabbix_mysql_user $zabbix_mysql_pass",
        require => [File['zabbix_db_check.sh'],Service['mysqld']]
    }
    
    file { 'zabbix_db_check.sh':
        path    => '/etc/zabbix/zabbix_db_check.sh',
        ensure  => file,
        require => Service['mysqld'],
        content => template("zabbix/scripts/zabbix_db_check.sh"),
        mode => 777,
        owner => root,
        group => root
#	notify  => Service[zabbix-server]
    }

        exec { "run_zabbix_config_update.sh":
        command => "/etc/zabbix/zabbix_config_update.sh",
        require => [File['zabbix_config_update.sh'],Service['zabbix-server']]
    }

    file { 'zabbix_config_update.sh':
	path    => '/etc/zabbix/zabbix_config_update.sh',
	ensure  => file,
	require => [Package['zabbix-server-mysql'], File['zabbix_import']],
	content => template("zabbix/scripts/zabbix_config_update.sh.erb"),
	mode    => 777,
	owner   => root,
	group   => root
    }
}
