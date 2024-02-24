#!/usr/bin/env bash
echo "modify configuration template..."
sed -i 's/hostname: reg.mydomain.com/hostname: 192.168.1.10/' harbor.yml.tmpl
sed -i 's/port: 443/port: 8443/' harbor.yml.tmpl
sed -i 's/certificate: \/your\/certificate\/path/certificate: \/harbor-data\/server.crt/' harbor.yml.tmpl
sed -i 's/private_key: \/your\/private\/key\/path/private_key: \/harbor-data\/server.key/' harbor.yml.tmpl
sed -i 's/harbor_admin_password: Harbor12345/harbor_admin_password: admin/' harbor.yml.tmpl
sed -i 's/data_volume: \/data/data_volume: \/harbor-data/' harbor.yml.tmpl
echo "generate configuration YAML"
mv harbor.yml.tmpl harbor.yml
