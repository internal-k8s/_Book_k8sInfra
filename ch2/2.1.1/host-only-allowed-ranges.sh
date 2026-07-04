#!/usr/bin/env bash

# Linux 호스트 전용: VirtualBox 6.1+의 host-only 네트워크 대역 허용 목록.
# macOS/Windows는 이 파일 없이도 host-only 네트워크가 정상 동작하므로 불필요.
cat <<EOF > /etc/vbox/networks.conf
* 10.0.0.0/8 192.168.0.0/16
* 2001::/64
EOF
