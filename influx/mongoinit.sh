#!/usr/bin/env bash
#
# Copyright © 2020.  SmartHub Inc. All rights reserved.
# This product is protected by copyright and intellectual 
# property laws in the United States and other countries
# as well as by international treaties.
#


set -x
source /opt/smarthub/utils/catalogsvc.sh

INFER_TEMPLATES_DIR="/opt/smarthub/templates/config"
NODE_PROPERTIES_TEMPLATE_FILE="${INFER_TEMPLATES_DIR}/node.properties"
CONSUL_CLIENT_CONFIG_TEMPLATE="${INFER_TEMPLATES_DIR}/client.json"
APP_CONFIG_DIR=${APP_CONFIG_DIR:-/opt/smarthub/iotc/conf}
NODE_PROPERTIES_FILE="${APP_CONFIG_DIR}/node.properties"
CONSUL_CLIENT_CONFIG="${APP_CONFIG_DIR}/consul.json"

# Consul keys
INFER_ENC_KEY_NAME='encrypt.key'
MONGODB_ADMIN_PASSWORD_KEY_NAME='mongo.db.admin.password'
MONGODB_IOTC_USER_KEY_NAME='mongo.db.username'
MONGODB_IOTC_PASSWORD_KEY_NAME='mongo.db.password'
MONGO_CS_URLS_KEY_NAME='mongo.cs.urls'
MONGO_DB_URLS_KEY_NAME='mongo.db.urls'

# Env to file mappings
MONGODB_ROOT_PASSWORD_FILE=/opt/smarthub/iotc/conf/rootpass

CERT_GEN_UTILITY=/opt/smarthub/utils/sh_generate_certs.py
CONSUL_MANAGER=/opt/smarthub/utils/consul_manager.py
ENCDEC_UTILTY=/opt/smarthub/utils/shencdec.py

MONGODB_CERTS=${MONGODB_CERTS:-"/certificates"}


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

ip_addr=$(ip addr show eth0 | grep -Po 'inet \K[\d.]+')

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

# generate self-signed certificates for mongodb
if [ ! -f "${MONGODB_CERTS}/keyfile.pem" ]; then

    echo "Creating the certificates for MongoDb"
    mkdir -p "${MONGODB_CERTS}"
    python3 $CERT_GEN_UTILITY ssl \
        --cert-store "filesystem://${MONGODB_CERTS}" \
        --cert-store "consul:///iotc/sites/default/instances/default/nodes/${MONGODB_ADVERTISED_HOSTNAME}/certstore" \
        --fqdn "${MONGODB_ADVERTISED_HOSTNAME}" \
        --ipaddr "${ip_addr}" \
        --issuer-store "consul:///iotc/sites/default/instances/default/certstore" \
        --issuer-name "SmartHub INFER IoT Center Root CA" \
        --component "mongodb"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to generate certificates for MongoDB"
        exit 1
    fi

    cat "${MONGODB_CERTS}/server.crt" "${MONGODB_CERTS}/server.pem" >> "${MONGODB_CERTS}/keyfile.pem"
    chmod 660 "${MONGODB_CERTS}/keyfile.pem" "${MONGODB_CERTS}/server.pem"
    chmod 770 ${MONGODB_CERTS}
fi 
INFER_ENC_KEY=$(python3 $CONSUL_MANAGER kv get --token "$CONFIG_CLIENT_TOKEN" --key "$INFER_ENC_KEY_NAME")
MONGODB_ROOT_PASSWORD=$(python3 $CONSUL_MANAGER kv get --token "$CONFIG_CLIENT_TOKEN" --key "$MONGODB_ADMIN_PASSWORD_KEY_NAME")
MONGODB_ROOT_PASSWORD=$(python3 $ENCDEC_UTILTY decode --key "$INFER_ENC_KEY" --encoded-text  $MONGODB_ROOT_PASSWORD)
MONGODB_IOTC_USER=$(python3 $CONSUL_MANAGER kv get --token "$CONFIG_CLIENT_TOKEN" --key "$MONGODB_IOTC_USER_KEY_NAME")
MONGODB_IOTC_PASSWORD=$(python3 $CONSUL_MANAGER kv get --token "$CONFIG_CLIENT_TOKEN" --key "$MONGODB_IOTC_PASSWORD_KEY_NAME")
MONGODB_IOTC_PASSWORD=$(python3 $ENCDEC_UTILTY decode --key "$INFER_ENC_KEY" --encoded-text  $MONGODB_IOTC_PASSWORD)

[ ! -f "$MONGODB_ROOT_PASSWORD_FILE" ] && \
     echo $MONGODB_ROOT_PASSWORD | tee "$MONGODB_ROOT_PASSWORD_FILE"

if [ "$MONGODB_SHARDING_MODE" == "configsvr" ]; then 
    MONGO_CS_URLS=$(python3 $CONSUL_MANAGER kv get --token "$CONFIG_CLIENT_TOKEN" --key "$MONGO_CS_URLS_KEY_NAME")
    if [[ "$MONGO_CS_URLS" =~ "$MONGODB_ADVERTISED_HOSTNAME" ]]; then
        echo "Already exists in $MONGO_CS_URLS_KEY_NAME"
    else
        if  [[ -z "$MONGO_CS_URLS" ]] || [[ "$MONGO_CS_URLS" =~ "dummy.mongodb.com" ]]; then
            MONGO_CS_URLS="$MONGODB_ADVERTISED_HOSTNAME"
        else 
            MONGO_CS_URLS=$(printf "%s,%s" $MONGO_CS_URLS $MONGODB_ADVERTISED_HOSTNAME)
        fi
        $(python3 $CONSUL_MANAGER kv put --token "$CONFIG_CLIENT_TOKEN" --kv-pair "$MONGO_CS_URLS_KEY_NAME=$MONGO_CS_URLS" )
    fi
elif [ "$MONGODB_SHARDING_MODE" == "mongos" ]; then
    MONGO_DB_URLS=$(python3 $CONSUL_MANAGER kv get --token "$CONFIG_CLIENT_TOKEN" --key "$MONGO_DB_URLS_KEY_NAME")

    if [[ "$MONGO_DB_URLS" =~ "$MONGODB_ADVERTISED_HOSTNAME" ]]; then
        echo "Already exists in $MONGO_DB_URLS_KEY_NAME"
    else        
        if  [[ -z "$MONGO_DB_URLS" ]] || [[ "$MONGO_DB_URLS" =~ "dummy.mongodb.com" ]]; then
            MONGO_DB_URLS="$MONGODB_ADVERTISED_HOSTNAME"
        else 
            MONGO_DB_URLS=$(printf "%s,%s" $MONGO_DB_URLS )
        fi        
        $(python3 $CONSUL_MANAGER kv put --token "$CONFIG_CLIENT_TOKEN" --kv-pair "$MONGO_DB_URLS_KEY_NAME=$MONGO_DB_URLS" )
    fi
fi

echo "Put some delay for sync and shutdown initiation"
sleep 30s

consul leave --token $CONFIG_CLIENT_TOKEN

