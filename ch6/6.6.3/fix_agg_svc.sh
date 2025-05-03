#!/usr/bin/env bash

echo "Clone from github, colosseum-agg codebase"
git clone https://github.com/k8s-edu/Bkv2_sub_colosseum
cd Bkv2_sub_colosseum/Bkv2_sub_colosseum-agg

echo "Finding slow warn log."
grep -r "This request was processed abnormally" -C 2
echo "Repair server logic: remove rootcause code Thread.Sleep..."
sed -i '/val miliseconds/,/logger.warn/c\        logger.info("This request was processed normally")' src/main/kotlin/book/k8sinfra/aggregateservice/controller/UserScoreController.kt

echo "final check before container build."
git diff

echo "build fix container image."
docker build -f ./Dockerfile.profile -t 192.168.1.10:8443/library/colosseum-agg:fix . --push

echo "re-deploy fix application."
kubectl set image deploy colosseum-agg -n colosseum colosseum-agg=192.168.1.10:8443/library/colosseum-agg:fix

cd -
