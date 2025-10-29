# Kong Mesh Telemetry Integration with OpenTelemetry (OTEL) and New Relic

This guide provides detailed steps to configure **Kong Mesh (Kuma)** on **EKS** to send telemetry data — metrics, traces, and logs — to **New Relic** using the **OpenTelemetry Collector**.

---

## 0. Decide Your Ingestion Pattern
Use one in-cluster **OpenTelemetry Collector** as a single telemetry gateway that scrapes Prometheus metrics, receives traces, and exports them to New Relic via OTLP.

> Avoid running both the New Relic Prometheus agent and OTEL Collector simultaneously to prevent duplicate data.

---

## 1. Prerequisites & Secrets
1. Obtain your New Relic **license key**.
2. Create a Kubernetes secret to store the key:

```bash
kubectl -n observability create secret generic newrelic-license-key \
  --from-literal=license-key='<NR_LICENSE_KEY>'
```

3. Optionally, create the `observability` namespace:

```bash
kubectl create ns observability
```

---

## 2. Enable Kong/Kuma Metrics & Traces
Ensure that Prometheus metrics and OpenTelemetry tracing are enabled in **Kong/Kuma**.

### Metrics
Verify that metrics endpoints expose mesh, dataplane, and service labels.

### Traces
Enable Kong's OpenTelemetry plugin to export spans to the OTEL Collector.

**Sample plugin settings:**
```bash
otel_endpoint = "otel-collector.observability.svc.cluster.local:4317"
otel_service_name = "kong-proxy"
```

---

## 3. Deploy the OpenTelemetry Collector
Deploy the OTEL Collector as a centralized deployment using Helm.

### Example `values.yaml`:
```yaml
mode: deployment
replicaCount: 2
config:
  receivers:
    otlp:
      protocols:
        grpc:
        http:
    prometheus:
      config:
        scrape_configs:
          - job_name: otel-collector-self
            scrape_interval: 10s
            static_configs:
              - targets: ["${MY_POD_IP}:8888"]
          - job_name: "kuma-dataplanes"
            scrape_interval: 5s
            relabel_configs:
              - source_labels: [__meta_kuma_mesh]
                target_label: mesh
              - source_labels: [__meta_kuma_dataplane]
                target_label: dataplane
              - source_labels: [__meta_kuma_service]
                target_label: service
            kuma_sd_configs:
              - server: "http://mesh-nsk-control-plane.app09889.sve:5676"
  exporters:
    otlphttp/newrelic:
      endpoint: https://otlp.nr-data.net:4318
      headers:
        api-key: ${NEW_RELIC_LICENSE_KEY}
  service:
    pipelines:
      metrics:
        receivers: [prometheus, otlp]
        exporters: [otlphttp/newrelic]
      traces:
        receivers: [otlp]
        exporters: [otlphttp/newrelic]
```

**Install via Helm:**
```bash
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
helm upgrade --install otel-collector open-telemetry/opentelemetry-collector \
  -n observability -f values-otel.yaml
```

---

## 4. Point Kong and Applications to the Collector
Configure Kong and your applications to send telemetry data to the OTEL Collector endpoint.

**Example environment variables:**
```bash
OTEL_SERVICE_NAME=my-service
OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-collector.observability.svc:4317
```

---

## 5. Disable Other Prometheus Paths
If you previously installed the New Relic Prometheus agent, disable or uninstall it to prevent duplicate data ingestion.

---

## 6. Validate the Pipeline
1. **Check collector logs:**
   ```bash
   kubectl -n observability logs deploy/otel-collector | grep -i "Export"
   ```
2. **Verify metrics in New Relic:**
   ```sql
   SELECT rate(sum(kong_http_requests_total), 1 minute) FROM Metric TIMESERIES
   ```

---

## 7. Build New Relic Dashboards
Recreate Grafana panels in New Relic using **NRQL queries**.

Add template variables such as `{{instance}}` and `{{mesh}}` for filtering.

---

## 8. Service Maps in New Relic
Ensure distributed tracing is enabled in Kong and applications. Spans should include:
- `service.name`
- `peer.service`
- `http.method`, `http.target`, etc.

> New Relic automatically generates service maps from traces.

---

## 9. Productionization
- Implement **tail-based sampling** for production.
- Add `deployment.environment` tags for `dev`, `stage`, and `prod`.
- Set up **alerts** and **SLIs** for latency, throughput, and error rates.

---

## 10. Alternate Setup (NR Prometheus Agent)
If you keep the NR Prometheus agent, skip the Prometheus receiver in OTEL Collector and use it for traces and logs only.

---

## TL;DR
1. Enable Kong/Kuma metrics & tracing.
2. Deploy OTEL Collector with New Relic OTLP exporter.
3. Point Kong and apps to the Collector.
4. Validate metrics/traces/logs in New Relic.
5. Recreate dashboards and confirm service maps.
