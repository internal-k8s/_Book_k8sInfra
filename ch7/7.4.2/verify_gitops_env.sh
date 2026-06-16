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

# 7.4.2 깃 원격 저장소 인증 여부 확인
if ! git -C ~/gitops ls-remote --exit-code origin &>/dev/null; then
  echo "Cannot access remote origin. Please check your credentials."
  exit 1
fi

echo "GitOps environment is ready."
