#!/bin/bash
set -e

# Set correct ownership and permissions for certificates in /etc/wazuh-dashboard/certs/
echo "Setting up certificate permissions..."
mkdir -p /etc/wazuh-dashboard/certs
cp /certs/root-ca.pem /etc/wazuh-dashboard/certs/root-ca.pem
cp /certs/dashboard.pem /etc/wazuh-dashboard/certs/dashboard.pem
cp /certs/dashboard-key.pem /etc/wazuh-dashboard/certs/dashboard-key.pem
chown -R wazuh-dashboard:wazuh-dashboard /etc/wazuh-dashboard/certs
chmod 640 /etc/wazuh-dashboard/certs/*
chmod 750 /etc/wazuh-dashboard/certs/

# Wait for wazuh-indexer to be reachable before starting the dashboard.
# The indexer runs security-init which takes ~20 s; depends_on only waits
# for the container to exist, not for the service inside to be ready.
echo "Waiting for wazuh-indexer to be ready..."
until curl -sk --max-time 5 \
    --cacert /etc/wazuh-dashboard/certs/root-ca.pem \
    https://wazuh-indexer:9200 >/dev/null 2>&1; do
    echo "  wazuh-indexer not ready yet, retrying in 5 s..."
    sleep 5
done
echo "wazuh-indexer is ready."

# Start wazuh-dashboard service
echo "Starting wazuh-dashboard..."
sudo -u wazuh-dashboard /usr/share/wazuh-dashboard/bin/opensearch-dashboards \
    -c /etc/wazuh-dashboard/opensearch_dashboards.yml
