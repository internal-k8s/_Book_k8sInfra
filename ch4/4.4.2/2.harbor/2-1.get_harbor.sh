#!/usr/bin/env bash
HARBOR_FILE_DIR=/opt/harbor
HARBOR_DATA_DIR=/data/harbor
echo "Remove existing configuration files"
rm -f 2-3.prepare 2-4.install.sh commom.sh LICENSE

echo "Create Harbor data directory($HARBOR_DATA_DIR)"
mkdir -p $HARBOR_DATA_DIR

echo "Download harbor-online-installer-v.2.10.0..."
curl -LO https://github.com/goharbor/harbor/releases/download/v2.10.0/harbor-online-installer-v2.10.0.tgz
tar -xvf harbor-online-installer-v2.10.0.tgz
mv harbor/* .

echo "Remove garbage files"
rm -f harbor-online-installer-v2.10.0.tgz
rm -rf harbor

echo "Add sequence number: "
echo "prepare    >>> 2-3.prepare"
echo "install.sh >>> 2-4.install.sh"
mv prepare 2-3.prepare
mv install.sh 2-4.install.sh

# modify 2-3.prepare.sh
sed -i '3 i\\HARBOR_BUNDLE_DIR=/opt/harbor' 2-3.prepare

# modify 2-4.install.sh
sed -i '/prepare $prepare_para/d' 2-4.install.sh
sed -i 's,$DOCKER_COMPOSE,$DOCKER_COMPOSE -f /opt/harbor/docker-compose.yml,' 2-4.install.sh
sed -i 's/up -d/-p harbor up -d/' 2-4.install.sh

# create systemd startup service for Harbor
cat <<EOF > /usr/lib/systemd/system/harbor.service
[Unit]
Description=Harbor startup service
Requires=docker.service
ConditionPathExists=$HARBOR_FILE_DIR/docker-compose.yml
After=network.target systemd-networkd-wait-online.service systemd-resolved.service syslog.service docker.service
Wants=network.target systemd-networkd-wait-online.service systemd-resolved.service syslog.service docker.service

[Service]
Type=simple
ExecStart=/usr/bin/docker compose -f $HARBOR_FILE_DIR/docker-compose.yml up
ExecStop=/usr/bin/docker compose -f $HARBOR_FILE_DIR/docker-compose.yml down

[Install]
WantedBy=multi-user.target
EOF

# reload and enable systemd service
systemctl daemon-reload
systemctl enable harbor
