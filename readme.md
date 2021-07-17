

**consul**
mkdir -p $PWD/consul01/{data,conf,logs,ssl,extra,tmp,app}
mkdir -p $PWD/consul02/{data,conf,logs,ssl,extra,tmp,app}
mkdir -p $PWD/consul03/{data,conf,logs,ssl,extra,tmp,app}


**mongo-cs**
mkdir -p $PWD/mongocs01/{ssl,app,consul,data,init}
mkdir -p $PWD/mongocs02/{ssl,app,consul,data,init}

mongo-s
mkdir -p $PWD/mongos01/{ssl,app,consul,data,init}

**mongo-shard**
mkdir -p $PWD/mongoshard01/{ssl,app,consul,data,init}
mkdir -p $PWD/mongoshard02/{ssl,app,consul,data,init}

**INFLUXDB**

Starting influx cluster - begin with data nodes:

mkdir -p $PWD/influxdata01/{conf,data,init} && sudo chown -R 1001:1001 $PWD/influxdata01
mkdir -p $PWD/influxdata02/{conf,data,init} && sudo chown -R 1001:1001 $PWD/influxdata02

Staring the meta nodes post that

mkdir -p $PWD/influxmeta01/{conf,data,init} && sudo chown -R 1001:1001 $PWD/influxmeta01
mkdir -p $PWD/influxmeta02/{conf,data,init} && sudo chown -R 1001:1001 $PWD/influxmeta02
mkdir -p $PWD/influxmeta03/{conf,data,init} && sudo chown -R 1001:1001 $PWD/influxmeta03