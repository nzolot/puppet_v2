#This is script to check zabbix DB
#PARAMETERS: 1 - Mysql root user; 2 - mysql root password; 3 - mysql zabbix user; 4 - mysql zabbix password;

USER=$1
PASSWORD=$2
DEFAULT_USER=root
DEFAULT_PASSWORD=
ZABBIX_USER=$3
ZABBIX_PASSWORD=$4
DB=zabbix

UP=$(pgrep mysqld | wc -l);
if [ "$UP" -ne 0 ];
then
    echo "MySQL is up";
    CHECKPASS=`mysqlshow --user=$DEFAULT_USER --password=$DEFAULT_PASSWORD | grep -v Wildcard | grep -o Database`
    
    if [ "$CHECKPASS" == "Database" ]; then
    /usr/bin/mysqladmin --user=$DEFAULT_USER password $PASSWORD
    else
    CHECKPASS=`mysqlshow --user=$USER --password=$PASSWORD | grep -v Wildcard | grep -o Database`
	if [ "$CHECKPASS" == "Database" ]; then
        echo NEWPASSOK
	else
	exit 1
	fi
    fi
#IMPORT ZABBIX TABLE IF NEEDED

    CHECKDB=`mysqlshow --user=$USER --password=$PASSWORD $DB | grep -v Wildcard | grep -o $DB`
	if [ "$CHECKDB" == "$DB" ]; then
	echo "db found, exiting"
	touch /etc/zabbix/zabbix_db_check.done
	exit 0
	else
	/usr/bin/mysql --user=$USER --password=$PASSWORD -e "CREATE DATABASE zabbix CHARACTER SET UTF8;"
	/usr/bin/mysql --user=$USER --password=$PASSWORD -e "GRANT ALL PRIVILEGES on $DB.* to '$ZABBIX_USER'@'localhost' IDENTIFIED BY '$ZABBIX_PASSWORD';"
	/usr/bin/mysql --user=$USER --password=$PASSWORD -e "FLUSH PRIVILEGES;"
	/usr/bin/mysql --user=$ZABBIX_USER --password=$ZABBIX_PASSWORD $DB < /usr/share/doc/zabbix-server-mysql-*/create/schema.sql
	/usr/bin/mysql --user=$ZABBIX_USER --password=$ZABBIX_PASSWORD $DB < /usr/share/doc/zabbix-server-mysql-*/create/images.sql
	/usr/bin/mysql --user=$ZABBIX_USER --password=$ZABBIX_PASSWORD $DB < /usr/share/doc/zabbix-server-mysql-*/create/data.sql
#	/usr/bin/mysql --user=$USER --password=$PASSWORD $DB < /etc/zabbix/zabbix-default.sql
	exit 0
	fi

echo good!
    exit 0
else
    echo "MySQL is DOWN!!!!!!!!";
    exit 1
fi


exit 0
