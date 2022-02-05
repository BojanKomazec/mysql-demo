#!/bin/sh

echo $(date)
echo Running MySQL Shell client...

# mysqlsh --version
mysqlsh --host=$MYSQL_DB_HOST --port=$MYSQL_DB_PORT --user=root --password=root --sql --file=./in/$SQL_FILE > ./out/$SQL_FILE.out

#
# If using Alpine as base image:
#
# It is possible to install mysql-client package which brings mysql client. It uses a slightly different arguments than mysqlsh.
#
# To test if mysql is installed:
# mysql --version
#
# To connect to MySQL (IP address is obtained from $ docker container inspect wp-admin-mysql)
# mysql --host=172.17.0.2 --user=root --password=root --database=avast_wordpress --tee ./wp-admin-diff-report-queries.out < ./all_post_types_report.sql
#
# When running the above command, mysql threw this error:
# ERROR 1045 (28000): Plugin caching_sha2_password could not be loaded: Error loading shared library /usr/lib/mariadb/plugin/caching_sha2_password.so: No such file or directory
#
# Running mysql docker image with --default-authentication-plugin=mysql_native_password didn't help.
# Until the solution is found we need to use Ubuntu as a base image for running mysql shell.

echo $(date)
echo MySQL Shell client exited.