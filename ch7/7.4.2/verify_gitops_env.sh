#!/usr/bin/env bash

# 7.4.2 깃옵스 디렉터리 존재 여부 확인
if [ ! -d ~/gitops ]; then
  echo "~/gitops not found. Please complete Chapter 5 labs first."
  exit 1
fi

# 7.4.2 깃 원격 저장소 등록 여부 확인
if ! git -C ~/gitops remote get-url origin &>/dev/null; then
  echo "No remote origin found in ~/gitops."
  exit 1
fi

# 7.4.2 깃 자격증명 설정 및 파일 존재 여부 확인
if ! git config --global credential.helper | grep -q "store --file ~/.git-cred"; then
  echo "Git credential helper is not configured. Please complete Chapter 5 labs first."
  exit 1
fi

if [ ! -f ~/.git-cred ]; then
  echo "~/.git-cred not found. Please complete Chapter 5 labs first."
  exit 1
fi

echo "GitOps environment is ready."
