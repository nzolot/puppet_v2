#
class puppettest {

 $var1 = "sometext"
 $var2 = "text2some"
#  $var1 = hiera('var1')
#  $var2 = hiera('var2')
    
    notify {"Helloworld!\$var1 ${var1}, \$var2 ${var2}, \$operatingsystem ${operatingsystem} ${operatingsystemrelease} ${ipaddress} ${fqdn} ${ipaddress_eth0} ${clientcert} ${environment}":}
    
}
