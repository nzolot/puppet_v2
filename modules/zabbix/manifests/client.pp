#Zabbix agent class
class zabbix::client ()

{
  $zabbix_server_name = hiera('zabbix_server_name')
  $zabbix_front_user  = hiera('zabbix_front_user')
  $zabbix_front_pass  = hiera('zabbix_front_pass')
  $zabmon_user        = hiera('zabmon_user')
  $zabmon_pass        = hiera('zabmon_pass')


    include zabbix::hosts

#Service
    service{'zabbix-agent':
        ensure  => 'running',
        enable => true,
        require => [Package['zabbix-agent'], File ['zabbix_agentd.conf']]
    }

#Packages
    package {'zabbix-agent':
        ensure => 'installed',
    }
    package {'wget':
        ensure => 'installed',
    }
    package {'jq':
        ensure => 'installed',
    }

#Configs
    file {'zabbix_agentd.conf':
        path    => '/etc/zabbix/zabbix_agentd.conf',
        ensure  => file,
        require => Package['zabbix-agent'],
        content => template("zabbix/configs/zabbix_agentd.conf.erb"),
        notify  => Service[zabbix-agent],
    }

    file {'zab.my.cnf':
        path => '/etc/zabbix/.my.cnf',
        ensure => file,
        require => Package['zabbix-agent'],
        content => template("zabbix/configs/my.cnf.erb"),
        owner => zabbix,
        mode => 600,
    }


    file { 'zabbix_agentd.d':
        path    => '/etc/zabbix/zabbix_agentd.d',
        ensure  => directory,
        force   => true,
        recurse => true,
        purge   => true,
        source  => "puppet:///modules/zabbix/zabbix_agentd.d",
        require => Package['zabbix-agent'],
        notify  => Service[zabbix-agent]
    }



#Scripts
    exec {'run_zabbix_register.sh':
        command => "/bin/bash /etc/zabbix/zabbix_register.sh $zabbix_front_user $zabbix_front_pass",
        require => [File['zabbix_register.sh']]
    }
    exec {'run_zabbix_enable.sh':
        command => "/bin/bash /etc/init.d/zabbix_enable.sh",
        require => [File[zabbix_enable]]
    }
    exec {"link_zabbix_disable":
        command => "/bin/ln -s /etc/init.d/zabbix_disable.sh /etc/rc0.d/K00zabbix_disable",
        creates => "/etc/rc0.d/K00zabbix_disable",
        require => [File[zabbix_disable]],
    }
    exec {"link_zabbix_enable":
            command => "/bin/ln -s /etc/init.d/zabbix_enable.sh /etc/rc3.d/S99zabbix_enable",
            creates => "/etc/rc3.d/S99zabbix_enable",
            require => [File[zabbix_enable]],
    }

    file {'zabbix_register.sh':
        path => '/etc/zabbix/zabbix_register.sh',
        ensure => file,
        require => Service[zabbix-agent],
        content => template("zabbix/scripts/zabbix_register.sh.erb"),
        owner => root,
        mode => 755
    }
        file {'zabbix_disable':
        path => '/etc/init.d/zabbix_disable.sh',
        ensure => file,
        content => template("zabbix/scripts/zabbix_disable.sh.erb"),
        owner => root,
        mode => 755
    }
        file {'zabbix_enable':
        path => '/etc/init.d/zabbix_enable.sh',
        ensure => file,
        content => template("zabbix/scripts/zabbix_enable.sh.erb"),
        owner => root,
        mode => 755
    }
    

}