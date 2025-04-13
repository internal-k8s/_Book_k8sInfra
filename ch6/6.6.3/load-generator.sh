#!/usr/bin/env bash
echo "📊 프로파일 데이터를 생성합니다."
echo "사용자 ID 1000의 점수를 100점씩 집계하는 API를 호출합니다."
WRITE_RESPONSE=$(curl -X 'POST' -w '\n' \
  'http://192.168.1.13/api/v1/score/1000' \
  -H 'accept: */*' \
  -H 'Content-Type: application/json' \
  -d '{
  "score": 100
}' )
echo "HTTP 응답: $WRITE_RESPONSE "
SCORE=$(echo $WRITE_RESPONSE | jq -r '.score.score')
echo -e "사용자 ID 1000의 점수가 서버에 반영되었습니다.\n> 현재 점수: $SCORE"

echo "사용자 ID 1000의 점수를 읽어오는 API를 호출합니다."
READ_RESPONSE=$(curl -X 'GET' -w '\n' \
  'http://192.168.1.13/api/v1/score/1000' \
  -H 'accept: application/json')
echo "HTTP 응답: READ_RESPONSE"
SCORE=$(echo $READ_RESPONSE | jq -r '.score')
echo -e "사용자 ID 1000의 점수를 서버에서 읽어왔습니다.\n> 현재 점수: $SCORE"