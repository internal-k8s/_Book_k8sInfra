#!/usr/bin/env bash
TEMPLATE=harbor.yml.tmpl
echo "modify configuration template..."
sed -i 's/hostname: reg.mydomain.com/hostname: 192.168.1.10/' \
       $TEMPLATE
sed -i 's/port: 443/port: 8443/' \
       $TEMPLATE
sed -i 's/certificate: \/your\/certificate\/path/certificate: \/harbor-data\/server.crt/' \
       $TEMPLATE
sed -i 's/private_key: \/your\/private\/key\/path/private_key: \/harbor-data\/server.key/' \
       $TEMPLATE
sed -i 's/harbor_admin_password: Harbor12345/harbor_admin_password: admin/' \
       $TEMPLATE
sed -i 's/data_volume: \/data/data_volume: \/harbor-data/' \
       $TEMPLATE
echo "generate configuration YAML"
mv $TEMPLATE harbor.yml
