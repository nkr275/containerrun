#!/bin/sh

# Copyright © 2018.  VMware Inc. All rights reserved. This product is protected by copyright
# and intellectual property laws in the United States and other countries as well as by international treaties.
# VMware products may be covered by one or more patents listed at http://www.vmware.com/go/patents.
set -x

source /etc/bootstrap/utils/catalogsvc.sh

CONSUL_DATA_DIR="/var/lib/consul"
INSTANCE_NAME="shkranthi-05"
CONFIG_SERVER="51.83.252.116"
CONFIG_CLIENT_TOKEN="b123bd0d-180b-933c-7af5-a50a281b535a"
INFER_TEMPLATES_DIR="/opt/smarthub/templates/config"
NODE_PROPERTIES_TEMPLATE_FILE="${INFER_TEMPLATES_DIR}/node.properties"
CONSUL_CLIENT_CONFIG_TEMPLATE="${INFER_TEMPLATES_DIR}/client.json"
APP_CONFIG_DIR=${APP_CONFIG_DIR:-/opt/smarthub/iotc/conf}
NODE_PROPERTIES_FILE="${APP_CONFIG_DIR}/node.properties"
CONSUL_CLIENT_CONFIG="${APP_CONFIG_DIR}/consul.json"
INFLUX_HOME=/etc/influxdb
INFLUX_META_CONF=$INFLUX_HOME/influxdb-meta.conf
CONSUL_MANAGER=/opt/smarthub/utils/consul_manager.py


# Get the consul config from the global catalog server
[ -z $INSTANCE_NAME ] && \
  echo "No instance name provided" && \
  exit 1

eval $(getDeployment "$INSTANCE_NAME")

[ -z $CONFIG_CLIENT_TOKEN ] && \
    echo "No consul client token" && \
    exit 1

# generate node.properties
mkdir -p "$(dirname $NODE_PROPERTIES_FILE)" && \
cp $NODE_PROPERTIES_TEMPLATE_FILE $NODE_PROPERTIES_FILE   

# add the consul kv access token
sed -i "/consul.host/s|=.*|=$CONFIG_SERVER|g" $NODE_PROPERTIES_FILE
sed -i "/consul.kv.access.token/s|=.*|=$CONFIG_CLIENT_TOKEN|g" $NODE_PROPERTIES_FILE
APP_ENCRYPT_KEY=$(python3 $CONSUL_MANAGER kv get --host=$CONFIG_SERVER --port=8500 --token=$CONFIG_CLIENT_TOKEN "--key=encrypt.key")
sed -i "/encrypt.key/s|=.*|=$APP_ENCRYPT_KEY|g" $NODE_PROPERTIES_FILE

# set stage to start a local consul client

cat $CONSUL_CLIENT_CONFIG_TEMPLATE | \
    jq --arg CONFIG_ENCRYPT_KEY "$CONFIG_ENCRYPT_KEY" '.encrypt = $CONFIG_ENCRYPT_KEY' | \
    jq --arg node "$MONGODB_ADVERTISED_HOSTNAME" '.node_name = $node' | \
    jq --arg CONSUL_DATA_DIR "$CONSUL_DATA_DIR" '.data_dir = $CONSUL_DATA_DIR' | \
    jq --arg CONFIG_SERVER "$CONFIG_SERVER" '.start_join += [$CONFIG_SERVER]' | \
    jq --arg CONFIG_MASTER_TOKEN "$CONFIG_MASTER_TOKEN" '.acl.tokens.master = $CONFIG_MASTER_TOKEN' | \
    jq --arg CONFIG_CLIENT_TOKEN "$CONFIG_CLIENT_TOKEN" '.acl.tokens.agent = $CONFIG_CLIENT_TOKEN' | \
    tee $CONSUL_CLIENT_CONFIG


consul agent -config-file $CONSUL_CLIENT_CONFIG &
# waiting for consul service to start
retry=10
while [ $retry -gt 0 ]
do
    sleep 10
    # check if consul is running
    response=$(consul members -token $CONFIG_CLIENT_TOKEN)
    [[ "$response" =~ .*"$ip_addr".* ]]  && break;

    retry=$((retry-1))
done

# return error if consul doesn't start
if [ $retry -eq 0 ]; then
    echo "Error: Consul restart timeout. Exiting..."
    exit 1
fi


# influx license-key 
sed -i "s/^\s*license-key = \".*\"/  license-key = \"e81fba29-027d-420c-a2d2-f326205b6a10\"/" $INFLUX_META_CONF

consul_token=`cat ${NODE_PROPERTIES_FILE} | grep "consul.kv.access.token" | cut -d'=' -f2`

# check if influxdb config file exists
if [ ! -f "$INFLUX_META_CONF" ]; then
    echo "Error: Unable to find influxdb config file - $INFLUX_META_CONF"
    exit 1;
fi

# add the docker interface ip in influxdb config to open it for iotc docker services
echo "Updating InfluxDB service config"
sed -i "s/^\s*# hostname = \".*\"/hostname = \"shconsulnode-01\"/" $INFLUX_META_CONF

# enable TLS and authentication for influxdb meta conf file
#sed -i "s/^\s*# https-enabled = .*/  https-enabled = true/" $INFLUX_META_CONF
#sed -i "s/^\s*# https-certificate = \".*\"/  https-certificate = \"\/etc\/influxdb\/certs\/server.crt\"/" $INFLUX_META_CONF
#sed -i "s/^\s*# https-private-key = \".*\"/  https-private-key = \"\/etc\/influxdb\/certs\/server.pem\"/" $INFLUX_META_CONF
#sed -i "s/^\s*# https-insecure-tls = .*/  https-insecure-tls = true/" $INFLUX_META_CONF
#sed -i "s/^\s*# data-use-tls = .*/  data-use-tls = true/" $INFLUX_META_CONF
#sed -i "s/^\s*# data-insecure-tls = .*/  data-insecure-tls = true/" $INFLUX_META_CONF
#sed -i "s/^\s*# min-version = .*/  min-version = \"tls1.2\"/" $INFLUX_META_CONF
#sed -i "s/^\s*# auth-enabled = .*/  auth-enabled = true/" $INFLUX_META_CONF
#sed -i "/^\s*license-path = .*/a [tls]\n\ \ min-version = \"tls1.2\"" $INFLUX_META_CONF
#sed -i "/^\s*min-version = .*/a \ \ ciphers = [\"TLS_RSA_WITH_AES_128_CBC_SHA256\", \"TLS_RSA_WITH_AES_128_GCM_SHA256\", \"TLS_RSA_WITH_AES_256_GCM_SHA384\", \"TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256\", \"TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256\", \"TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256\", \"TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256\", \"TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384\", \"TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384\"]" $INFLUX_META_CONF

ENCRYPT_KEY=$CONFIG_ENCRYPT_KEY
# It is new cluster;
if [ -z "$ENCRYPT_KEY" ]; then

   # generate InfluxDB shared secret key
   echo "Generating InfluxDB shared secret key"
   key=$(uuidgen)
   internal_key=$(uuidgen)
   echo $consul_token | python3 $BOOTSTRAP_UTILS/put_consul_key_value.py 'influx.shared.secret' $key
   echo $consul_token | python3 $BOOTSTRAP_UTILS/put_consul_key_value.py 'influx.internal.shared.secret' $internal_key

# Secondary node;
else

   # get InfluxDB shared secret key from consul
   echo "Getting InfluxDB shared secret key"
   key=$(echo $consul_token | python3 $BOOTSTRAP_UTILS/get_consul_key_value.py 'influx.shared.secret')
   [[ -z "$key" ]] && echo "Failed to get Influx secret key from consul" && exit 1
   internal_key=$(echo $consul_token | python3 $BOOTSTRAP_UTILS/get_consul_key_value.py 'influx.internal.shared.secret')
   [[ -z "$internal_key" ]] && echo "Failed to get Influx secret key from consul" && exit 1
fi

# set internal shared secret. This is required when we enable meta node authentication
sed -i "/^\[meta\]$/,/^\[/ s/^\s*# internal-shared-secret = .*/  internal-shared-secret = \"$internal_key\"/"  $INFLUX_META_CONF

# remove readable permissions for others
chown -R influxdb:influxdb /etc/influxdb
chmod 600 $INFLUX_META_CONF
