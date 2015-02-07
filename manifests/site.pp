#

    if versioncmp($::puppetversion,'3.6.1') >= 0 {
    $allow_virtual_packages = hiera('allow_virtual_packages',false)
        Package {
            allow_virtual => $allow_virtual_packages,
        }
}

class start () {

    node 'centos-postgress.loc' {
        notify {"hello world": }
    }


    node 'default' {
        $machinegroup = $hostname ? {
            /mgmt/     => 'grp-mgmt',
            /zabbix/   => 'grp-zabbix',
            /balancer/ => 'grp-balancer',
            /tomcat/   => 'grp-tomcat',
            /jenkins/  => 'grp-jenkins',
            /mysql/    => 'grp-mysql',
            default    => '',
            }
    

    include puppettest
    include puppettest2
    }
}
