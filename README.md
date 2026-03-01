
# Centralized Logging (ELK) — Real-Time “Ops” Incident Logging Stack

## Context

In real operations work, logs are one of the first places I go during an incident. If an application is slow, failing, or returning errors, I need a fast way to see what is happening without jumping from one server or container to another.

For this project, I built a centralized logging lab using **Elasticsearch, Logstash, and Kibana (ELK)** with a **real-time log generator**. The idea was to simulate the kind of setup that helps during incidents: logs come in continuously, get parsed, stored, and become searchable in one place.

This project shows how I can move from scattered raw logs to a simple centralized logging workflow that supports faster troubleshooting.

---

## Problem

When logs are spread across different systems, incident investigation becomes slow and frustrating.

Some common problems are:

* I have to check multiple servers or containers one by one
* Important logs may rotate or disappear before I review them
* It becomes hard to quickly answer:

  * when the issue started
  * which service is affected
  * whether the problem is isolated or widespread
  * whether the error rate is increasing

In Ops work, if log investigation is slow, recovery is usually slow too.

---

## Solution

I built a centralized logging stack using **ELK** and a **real-time log generator**.

The setup works like this:

* A **log generator container** continuously writes logs
* **Logstash** reads and parses those logs into structured fields
* **Elasticsearch** stores and indexes the logs
* **Kibana** gives me a searchable interface for filtering and investigating events

With this setup, I can:

* search logs from one place
* filter by fields like `service`, `level`, and `request_id`
* narrow down events by time range
* quickly focus on error activity during an incident

---

## Architecture

![Architecture Diagram](screenshots/architecture.png)

The architecture shows a centralized logging flow where logs are created, collected, parsed by Logstash, indexed in Elasticsearch, and explored in Kibana for fast incident investigation.

---

## Workflow

### 1. Start the ELK stack and confirm containers are running

**Goal:** make sure the logging environment starts correctly and all main services are available.

At this stage, I bring up the stack and verify that the main containers are running properly. This confirms that the lab is ready before I start checking ingestion and search.

![Compose Up](screenshots/01-docker-compose-up.png)

**What the screenshot shows:** the Docker Compose stack is up and the ELK services are running.

---

### 2. Verify Elasticsearch is healthy

**Goal:** confirm that Elasticsearch is reachable and ready to store indexed log data.

Before using Kibana or checking parsed logs, I first make sure Elasticsearch is responding correctly. This is important because Elasticsearch is the storage and search engine behind the whole pipeline.

![Elasticsearch Health](screenshots/02-elasticsearch-health.png)

**What the screenshot shows:** Elasticsearch is up and responding, which means the backend log storage is available.

---

### 3. Confirm Logstash is processing logs

**Goal:** verify that Logstash is actively reading and forwarding logs into Elasticsearch.

This step confirms that ingestion is working. The logs are not just being generated—they are actually moving through the pipeline and being processed.

![Logstash Running](screenshots/03-logstash-running.png)

**What the screenshot shows:** Logstash is running and processing the incoming log stream.

---

### 4. Open Kibana successfully

**Goal:** verify that the visualization and search interface is available.

Once Elasticsearch and Logstash are working, I confirm Kibana is accessible. Kibana is the part I use during troubleshooting because it gives me one place to search and filter events.

![Kibana Home](screenshots/04-kibana-ui-home.png)

**What the screenshot shows:** Kibana is available and ready for log exploration.

---

### 5. Create the data view for indexed logs

**Goal:** make the indexed logs visible and searchable inside Kibana.

A data view connects Kibana to the stored log indices. Without it, logs may exist in Elasticsearch, but they are not easy to explore in Kibana Discover.

![Data View Created](screenshots/05-data-view-created.png)

**What the screenshot shows:** the `ops-logs` data view has been created successfully.

---

### 6. Filter logs to focus on errors

**Goal:** reduce noise and quickly isolate incident-related log events.

In a real incident, I usually do not want to read everything. I want to narrow the view fast. Filtering on `ERROR` lets me focus only on the logs that matter most for troubleshooting.

![Discover Errors](screenshots/06-discover-errors-filter.png)

**What the screenshot shows:** Kibana Discover is filtering logs to show only error-level events.

---

### 7. Narrow the incident to a specific service

**Goal:** identify whether one service is causing the issue.

After filtering for errors, I can go deeper by filtering on a service such as `api`. This helps separate one failing service from the rest of the environment.

![Service Filter](screenshots/07-service-filter.png)

**What the screenshot shows:** the logs are filtered further to focus on one service involved in the issue.

---

### 8. Confirm that new logs appear in real time

**Goal:** prove that the pipeline is continuously ingesting fresh events.

A useful logging setup must not only store old logs—it also needs to show new events as they happen. This helps me monitor ongoing incidents and validate whether a fix is working.

![Live Logs](screenshots/08-live-new-logs.png)

**What the screenshot shows:** new logs are continuously appearing in Kibana, proving live ingestion is working.

---

## Business Impact

This project improves incident response by giving me one place to search and analyze logs.

From an operations point of view, the impact is:

* faster investigation during failures
* less time wasted jumping between systems
* easier identification of affected services
* better visibility into when errors begin and how they change over time
* stronger proof during troubleshooting because incidents can be shown with filters and screenshots

In simple terms, centralized logging helps reduce investigation time and supports faster recovery.

---

## Troubleshooting

### Elasticsearch is up but index health is yellow

In a single-node setup, a `yellow` status is usually normal because replicas cannot be assigned. This does not always mean the environment is broken.

### Kibana opens but no logs appear

This usually means one of these is wrong:

* the logs are not being ingested into Elasticsearch
* the data view is not configured correctly
* the selected time range in Kibana is too narrow

### Logstash is not parsing data correctly

If parsing fails, logs may arrive unstructured or not appear the way I expect in Kibana. In this case, the pipeline configuration usually needs to be checked.

### No live logs are appearing

This can happen if the log generator is not writing correctly or if Logstash is no longer reading the log file.

### Ports are already in use

If Kibana or Elasticsearch does not start, another container or service may already be using the same port.

---

## Useful CLI

### General verification

```bash
docker compose ps
docker compose logs --tail=50
```

### Elasticsearch checks

```bash
curl -s http://localhost:9200
curl -s "http://localhost:9200/_cat/indices?v"
```

### Logstash troubleshooting

```bash
docker compose logs logstash --tail=200
docker compose logs -f logstash
```

### Generator troubleshooting

```bash
docker compose logs -f log-generator
wc -l logs/app.log
tail -n 20 logs/app.log
```

### Container / port checks

```bash
docker ps
docker stop <container_id>
```

### Optional Elasticsearch setting adjustment for single-node lab

```bash
curl -s -X PUT "http://localhost:9200/ops-logs-*/_settings" \
  -H 'Content-Type: application/json' \
  -d '{"index":{"number_of_replicas":0}}'
```

---

## Cleanup

```bash
docker compose down
```

