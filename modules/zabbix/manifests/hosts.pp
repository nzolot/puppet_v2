#This class defines hosts, groups and templates;
class zabbix::hosts
()
{

    $templates     = hiera('zabbix_templates')
    $groups        = hiera('zabbix_groups')
    $interfaces    = hiera('zabbix_interfaces')

}