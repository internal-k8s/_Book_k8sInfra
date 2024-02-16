#!/usr/bin/env bash
ZULU_SITE=https://cdn.azul.com/zulu/bin
ZULU_NAME=zulu21.32.17-ca-jdk21.0.2-linux_x64

curl -O $ZULU_SITE/$ZULU_NAME.tar.gz
tar -xvf $ZULU_NAME.tar.gz
mv $ZULU_NAME /opt
ln -s /opt/$ZULU_NAME/bin/java /usr/bin/java
rm -f $ZULU_NAME.tar.gz

echo "export JAVA_HOME=/opt/$ZULU_NAME" >> ~/.bashrc
