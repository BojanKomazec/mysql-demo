This repository contains tools and commands for running and querying MySQL database which contains Northwind DB data.

Northwind DB is downloaded from Google Code page: https://code.google.com/archive/p/northwindextended/downloads
Download url: https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/northwindextended/Northwind.MySQL5.sql

The original file is BOM-formated. If it's passed to mysqlsh for execution, mysqlsh returns an error "ERROR: 1064 (42000) at line 1: You have an error in your SQL syntax;". To prevent this error, BOM was removed from it before this file was added to this repository:

```
$ sudo xxd -l 32 ./shared/in/Northwind.MySQL5.sql
00000000: efbb bf23 202d 2d2d 2d2d 2d2d 2d2d 2d2d  ...# -----------
00000010: 2d2d 2d2d 2d2d 2d2d 2d2d 2d2d 2d2d 2d2d  ----------------

$ sudo sed -i '1s/^\xef\xbb\xbf//' ./shared/in/Northwind.MySQL5.sql

$ sudo xxd -l 32 ./shared/in/Northwind.MySQL5.sql
00000000: 2320 2d2d 2d2d 2d2d 2d2d 2d2d 2d2d 2d2d  # --------------
00000010: 2d2d 2d2d 2d2d 2d2d 2d2d 2d2d 2d2d 2d2d  ----------------
```

As the name says, this sql file is adjusted for MySQL version 5 but `select version();` for our DB returns `8.0.27`.
From https://www.tutorialspoint.com/can-we-use-rank-as-column-name-with-mysql8:
> The rank is a MySQL reserved word defined in MySQL version 8.0.2

To make this sql file compatible with our DB I had to put backticks around `RANK` word which is meant to be used as alias name here.
I added to this repo the original `Northwind.MySQL5.sql` file and also its modified version, which I renamed to `Northwind.MySQL8-0-27.sql` to reflect the fact that it is compatible with this version of MySQL DB.

In order to make deployment easier, DB and its client are run in their own Docker containers.

Before running the DB container we need to create a Docker volume to persists DB data and config between sessions:
```
$ docker volume create mysql-demo-volume
```

To run MySQL DB in a Docker container:
```
$ docker run \
--name mysql-demo \
--rm \
-p 3307:3306 \
-e MYSQL_ROOT_PASSWORD=root \
-v mysql-demo-volume:/var/lib/mysql \
-d \
mysql:latest
```

Default port that MySQL is listening is `3306` so this port is usually open for Docker container. If another container with port `3306` is already running, docker run will fail with following error:
```
docker: Error response from daemon: driver failed programming external connectivity on endpoint mysql-demo (eb...c5): Bind for 0.0.0.0:3306 failed: port is already allocated.
```
To resolve this error, choose some other port on host machine that container's port `3306` should be mapped to e.g. `3307`. If we're connecting to the database from another Docker container the exposed/forwarded port isn't used, so we should still use `3306` from there. We'll only use `3307` when connecting to it from outside of Docker.

`sql_mode` in MySQL config can be set to custom value in order to suppress errors like "invalid default value" when setting `'0000-00-00 00:00:00'` as default value for column with `datetime` type. By default `NO_ZERO_IN_DATE,NO_ZERO_DATE` are included in `sql_mode` value in `my.cnf` but if we want to exlude them we can do it by passing additional argument to the above docker run command: `--sql-mode="ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION"`

Instead of Docker volume, it is possible to share a local directory with Docker container in which case we can pass to `docker run`:
```
-v $(pwd)/mysql_demo_data:/var/lib/mysql
```
Note that `mysql_demo_data` will be created by Docker, it does not need to be created manually upfront.

To stop MySQL docker container:
```
$ docker container stop mysql-demo
```

After running MySQL DB for the first, time, it contains only `sys` schema (database). To access tables in MySQL Db we can use UI tool MySQL Workbench or thin clients like mysql (old client) or mysqlsh (MySQL Shell which is new, recommended client).

If MySQL shell is installed on local machine, we can run it to connect to DB running in Docker container and get the interactive shell in which we can type in SQL commands.

To run the shell and connect to DB:
```
$ mysqlsh --host=127.0.0.1 --port=3307 --user=root --password=root --sql
```

Some SQL commands we can execute:
```
MySQL  127.0.0.1:3307 ssl  SQL > show databases;
MySQL  127.0.0.1:3307 ssl  sys  SQL > use sys;
MySQL  127.0.0.1:3307 ssl  sys  SQL > use mysql;
MySQL  127.0.0.1:3307 ssl  mysql  SQL > show tables;
MySQL  127.0.0.1:3307 ssl  mysql  SQL > select host, user from user;
MySQL  127.0.0.1:3307 ssl  mysql  SQL > select host, user from mysql.user;
```

We can also pass SQL command (or multiple commands, separated by semicolon `;`) to mysqlsh to execute and quit:
```
$ mysqlsh --host=172.17.0.3 --port=3306 --user=root --password=root --sql --execute='select "Hello, world" as ""'
$ mysqlsh --host=172.17.0.3 --port=3306 --user=root --password=root --sql --execute='show databases;'
$ mysqlsh --host=172.17.0.3 --port=3306 --user=root --password=root --sql --execute='use sys; show tables;'
$ mysqlsh --host=172.17.0.3 --port=3306 --user=root --password=root --sql --execute='use mysql;show tables;'
$ mysqlsh --host=172.17.0.3 --port=3306 --user=root --password=root --sql --execute='select User from mysql.user;'
```

It is possible to put all SQL commands into a file and pass that file to mysqlsh to execute it. The output can be streamed into a specified text file:

```
$ mysqlsh --host=172.17.0.3 --port=3306 --user=root --password=root --sql --file=blank-db-queries.sql > blank-db-queries.out
```

To re-create Northwind database we can run `Northwind.MySQL8-0-27.sql` either from mysqlsh running directly on the host or in a Docker container. As we want to make deployment as easy as possible (so you don't need to install mysqlsh on the machine) I prepared a Dockefile for creating an image which contans mysqlsh. To build it (`bojankomazec/mysqlsh:latest`):
```
$ make build
```

To execute `Northwind.MySQL8-0-27.sql` by mysqlsh which runs in Docker container place this sql file in `./shared/in/` directory and then run the following command:
```
$ make run MYSQL_DB_HOST=172.17.0.3 MYSQL_DB_PORT=3306 SQL_FILE=Northwind.MySQL8-0-27.sql
```

Upon running this command this SQL query output file should be created: `./shared/out/Northwind.MySQL8-0-27.sql.out`.