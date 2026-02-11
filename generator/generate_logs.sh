#!/usr/bin/env sh
set -eu

LOG_FILE="/logs/app.log"
mkdir -p /logs
touch "$LOG_FILE"

# seed lines so Kibana has data immediately
echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) INFO  service=api   env=dev request_id=seed001 message=\"startup complete\"" >> "$LOG_FILE"
echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) INFO  service=nginx env=dev request_id=seed002 message=\"GET /health 200\"" >> "$LOG_FILE"

i=1000
while true; do
  ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  # simple random pick (works in busybox/alpine)
  r=$((i % 10))

  if [ "$r" -le 5 ]; then
    level="INFO"
  elif [ "$r" -le 7 ]; then
    level="WARN"
  else
    level="ERROR"
  fi

  if [ $((i % 2)) -eq 0 ]; then
    service="api"
    msg="GET /api 200"
  else
    service="nginx"
    msg="GET /api 502 upstream_error"
  fi

  # make ERROR messages look like real incidents
  if [ "$level" = "ERROR" ] && [ "$service" = "api" ]; then
    msg="DB connection timeout"
  fi

  request_id="rt$i"

  echo "$ts $level  service=$service env=dev request_id=$request_id message=\"$msg\"" >> "$LOG_FILE"

  # every 15 lines: simulate an incident burst
  if [ $((i % 15)) -eq 0 ]; then
    echo "$ts ERROR service=api env=dev request_id=burst$i message=\"panic: failed to load config\"" >> "$LOG_FILE"
    echo "$ts ERROR service=nginx env=dev request_id=burst$((i+1)) message=\"GET /api 504 gateway_timeout\"" >> "$LOG_FILE"
  fi

  i=$((i+1))
  sleep 2
done
