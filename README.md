# Centralized Logging (ELK) — Real-Time “Ops” Incident Logging Stack

## Context
This project is my **centralized logging lab** using **Elasticsearch + Logstash + Kibana (ELK)** with a **real-time log generator**.

Real Ops goal: during an incident, I don’t want to SSH into 5 containers/servers hunting for one error line.  
I want **one place** to search logs fast, filter by service, and prove what happened.

---

## Problem
When logs are scattered everywhere, incidents turn into a mess:

- I’m jumping between servers/containers trying to find “the one log line”
- Logs rotate or disappear before I can investigate
- It’s hard to answer basic questions quickly:
  - When did errors start?
  - Which service is failing?
  - Is it one node or the whole system?
  - Are errors increasing or stable?

**Slow log search = slow recovery.**

---

## Solution
I built a centralized logging stack using **ELK** with **real-time log creation**:

- **Log Generator (Alpine container)** writes logs continuously into `logs/app.log`
- **Logstash** tails that log file and parses fields (`service`, `level`, `request_id`, `message`)
- **Elasticsearch** stores and indexes logs for fast search
- **Kibana** lets me filter/search logs during incidents (Discover + filters + time range)

With this setup I can:
- Search by `service`, `level`, `request_id`
- Zoom into the time range when errors started
- Prove incident investigation with screenshots and saved queries

---

## Architecture
![Architecture Diagram](screenshots/architecture.png)

**Flow:** Log Generator → Logstash (parse + ingest) → Elasticsearch (index + store) → Kibana (search + filters)

---

## What I did  + screenshots

### 1) Started the stack (Goal: bring ELK + generator up locally)
- I started everything using Docker Compose and verified containers were running.

**Screenshot — Compose up**
![Compose Up](screenshots/01-docker-compose-up.png)

---

### 2) Verified Elasticsearch health (Goal: confirm search backend is reachable + indices can exist)
- I checked Elasticsearch responds and can list indices.

**Screenshot — Elasticsearch health / indices**
![Elasticsearch Health](screenshots/02-elasticsearch-health.png)

---

### 3) Confirmed Logstash ingestion (Goal: ensure logs are being parsed + shipped to Elasticsearch)
- I confirmed Logstash is running and ingesting the generator log file.

**Screenshot — Logstash running / ingest proof**
![Logstash Ingest](screenshots/03-logstash-running.png)

---

### 4) Opened Kibana (Goal: confirm UI works for incident investigation)
- I opened Kibana UI and confirmed it loads.

**Screenshot — Kibana home**
![Kibana Home](screenshots/04-kibana-ui-home.png)

---

### 5) Created a Data View (Goal: make logs searchable in Discover)
- I created a Data View for `ops-logs-*` with `@timestamp` as the time field.

**Screenshot — Data view created**
![Data View](screenshots/05-data-view-created.png)

---

### 6) Investigated “incident logs” (Goal: filter errors fast during an incident)
- In Discover, I filtered for errors (`level: ERROR`) to simulate incident triage.

**Screenshot — Discover error filter**
![Discover Errors](screenshots/06-discover-errors-filter.png)

---

### 7) Narrowed to a specific service (Goal: identify which service is failing)
- I filtered further by service (`service: api`) to isolate the failing component.

**Screenshot — Service filter**
![Service Filter](screenshots/07-service-filter.png)

---

### 8) Watched live logs (Goal: verify new logs appear in real time)
- I confirmed logs keep streaming and new events appear continuously in Kibana.

**Screenshot — Live logs updating**
![Live Logs](screenshots/08-live-new-logs.png)

---

## Business Impact
- **Faster incident response:** one place to search instead of checking logs service-by-service
- **Better visibility:** filter by `ERROR`, `service`, and time range to find root cause quickly
- **Proof for stakeholders:** screenshots + saved queries show exactly what happened and when
- **Reusable lab:** runs locally and can be repeated anytime for demos or practice

---

## Troubleshooting

### Elasticsearch index health is `yellow`
That’s normal in **single-node** mode because replicas can’t be assigned.  
If you want it green, set replicas to `0` (see **Useful CLI → Elasticsearch**).

---

### Kibana loads but no logs show up
Most common causes:
- No index exists yet (`ops-logs-*`)
- Data View pattern/time field is wrong
- Discover time range is too narrow

Fix steps:
1) Confirm indices exist (see **Useful CLI → Elasticsearch**)
2) Confirm Logstash is ingesting (see **Useful CLI → Logstash**)
3) Confirm Data View:
   - pattern: `ops-logs-*`
   - time field: `@timestamp`
4) In Discover, try time range: **Last 15 minutes**

---

### Logstash keeps restarting
Most common cause: parsing mismatch (grok pattern doesn’t match log format).  
Check Logstash logs (see **Useful CLI → Logstash**) and adjust `pipeline/logstash.conf` pattern.

---

### No new logs appear (generator issue)
- Check generator container logs
- Confirm `logs/app.log` is growing

(Commands in **Useful CLI → Generator / File checks**)

---

### Ports already in use (9200 or 5601)
- Another container/app may already be bound to those ports.
- Stop conflicts or change ports in `docker-compose.yml`.

(Commands in **Useful CLI → Ports**)

---

## Useful CLI (setup + verification + troubleshooting)

### Setup / Run
```bash
# from repo root
mkdir -p centralized-logging-elk/{pipeline,generator,logs,screenshots}
cd centralized-logging-elk

# reset the log file (important so Logstash reads clean)
: > logs/app.log

# start
docker compose up -d

# check status
docker compose ps
````

### Elasticsearch (health + indices + common fixes)

```bash
# basic health check
curl -s http://localhost:9200 | head

# list indices
curl -s "http://localhost:9200/_cat/indices?v"

# (optional) make single-node indices green by removing replicas
curl -s -X PUT "http://localhost:9200/ops-logs-*/_settings" \
  -H 'Content-Type: application/json' \
  -d '{"index":{"number_of_replicas":0}}'
```

### Logstash (ingestion troubleshooting)

```bash
# follow logs
docker compose logs -f logstash

# last 200 lines (useful for errors)
docker compose logs logstash --tail=200

# quick check: do we see our index name?
curl -s "http://localhost:9200/_cat/indices?v" | grep ops-logs || true
```

### Kibana (quick checks)

```bash
# confirm Kibana is reachable
curl -I http://localhost:5601
```

### Generator / File checks (confirm logs are being written)

```bash
# generator logs
docker compose logs -f log-generator

# confirm file is growing
wc -l logs/app.log
tail -n 20 logs/app.log
tail -f logs/app.log
```

### Ports (find conflicts)

```bash
# show running containers
docker ps

# if you know the conflicting container
docker stop <container_id>
```

---

## Cleanup

```bash
docker compose down
```


