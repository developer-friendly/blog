##########################################################
#                        GENERAL
##########################################################

livedebugging {
	enabled = true
}

##########################################################
#                        LOGGING
##########################################################

discovery.kubernetes "kubernetes_pods" {
	role = "pod"
}

discovery.relabel "kubernetes_pods" {
	targets = discovery.kubernetes.kubernetes_pods.targets

	rule {
		source_labels = ["__meta_kubernetes_pod_controller_name"]
		regex         = "([0-9a-z-.]+?)(-[0-9a-f]{8,10})?"
		target_label  = "__tmp_controller_name"
	}

	rule {
		source_labels = ["__meta_kubernetes_pod_label_app_kubernetes_io_name", "__meta_kubernetes_pod_label_app", "__tmp_controller_name", "__meta_kubernetes_pod_name"]
		regex         = "^;*([^;]+)(;.*)?$"
		target_label  = "app"
	}

	rule {
		source_labels = ["__meta_kubernetes_pod_label_app_kubernetes_io_instance", "__meta_kubernetes_pod_label_instance"]
		regex         = "^;*([^;]+)(;.*)?$"
		target_label  = "instance"
	}

	rule {
		source_labels = ["__meta_kubernetes_pod_label_app_kubernetes_io_component", "__meta_kubernetes_pod_label_component"]
		regex         = "^;*([^;]+)(;.*)?$"
		target_label  = "component"
	}

	rule {
		source_labels = ["__meta_kubernetes_pod_node_name"]
		target_label  = "node_name"
	}

	rule {
		source_labels = ["__meta_kubernetes_namespace"]
		target_label  = "namespace"
	}

	rule {
		source_labels = ["namespace", "app"]
		separator     = "/"
		target_label  = "job"
	}

	rule {
		source_labels = ["__meta_kubernetes_pod_name"]
		target_label  = "pod"
	}

	rule {
		source_labels = ["__meta_kubernetes_pod_container_name"]
		target_label  = "container"
	}

	rule {
		source_labels = ["__meta_kubernetes_pod_uid", "__meta_kubernetes_pod_container_name"]
		separator     = "/"
		target_label  = "__path__"
		replacement   = "/var/log/pods/*$1/*.log"
	}

	rule {
		source_labels = ["__meta_kubernetes_pod_annotationpresent_kubernetes_io_config_hash", "__meta_kubernetes_pod_annotation_kubernetes_io_config_hash", "__meta_kubernetes_pod_container_name"]
		separator     = "/"
		regex         = "true/(.*)"
		target_label  = "__path__"
		replacement   = "/var/log/pods/*$1/*.log"
	}
}

local.file_match "kubernetes_pods" {
	path_targets = discovery.relabel.kubernetes_pods.output
}

loki.process "kubernetes_pods" {
	forward_to = [loki.write.default.receiver]

	stage.cri { }

	stage.decolorize { }

	stage.drop {
		expression = ".*(\\/health|\\/metrics|\\/ping).*"
	}
}

loki.source.file "kubernetes_pods" {
	targets               = local.file_match.kubernetes_pods.targets
	forward_to            = [loki.process.kubernetes_pods.receiver]
	legacy_positions_file = "/run/promtail/positions.yaml"
}

discovery.relabel "systemd_journal" {
	targets = []

	rule {
		source_labels = ["__journal__systemd_unit"]
		target_label  = "unit"
	}

	rule {
		source_labels = ["__journal__hostname"]
		target_label  = "hostname"
	}

	rule {
		source_labels = ["__journal__boot_id"]
		target_label  = "boot_id"
	}

	rule {
		source_labels = ["__journal__machine_id"]
		target_label  = "machine_id"
	}

	rule {
		source_labels = ["__journal__priority"]
		target_label  = "priority"
	}

	rule {
		source_labels = ["__journal__syslog_identifier"]
		target_label  = "syslog_identifier"
	}

	rule {
		source_labels = ["__journal__transport"]
		target_label  = "transport"
	}

	rule {
		source_labels = ["unit"]
		target_label  = "_stream"
		replacement   = "unit=\"$1\""
	}
}

loki.source.journal "systemd_journal" {
	path          = "/var/log/journal"
	relabel_rules = discovery.relabel.systemd_journal.rules
	forward_to    = [loki.write.default.receiver]
	labels        = {}
}

loki.source.kubernetes_events "cluster_events" {
	job_name   = "integrations/kubernetes/eventhandler"
	log_format = "logfmt"
	forward_to = [
		loki.process.cluster_events.receiver,
	]
}

loki.process "cluster_events" {
	forward_to = [loki.write.default.receiver]

	stage.regex {
		expression = ".*name=(?P<name>[^ ]+).*kind=(?P<kind>[^ ]+).*objectAPIversion=(?P<apiVersion>[^ ]+).*type=(?P<type>[^ ]+).*"
	}

	stage.labels {
		values = {
			kubernetes_cluster_events = "job",
			name                      = "name",
			kind                      = "kind",
			apiVersion                = "apiVersion",
			type                      = "type",
		}
	}
}

loki.write "default" {
	endpoint {
		url       = "http://vlogs-victorialogs.monitoring:9428/insert/loki/api/v1/push?_stream_fields=instance,job,host,app&disable_message_parsing=1"
		tenant_id = "0:0"
	}
	external_labels = {}
}

##########################################################
#                        TRACING
##########################################################

otelcol.receiver.otlp "default" {
	grpc {
		endpoint = "0.0.0.0:4317"
	}

	http {
		endpoint = "0.0.0.0:4318"
	}

	output {
		metrics = [otelcol.processor.batch.default.input]
		logs    = [otelcol.processor.batch.default.input]
		traces  = [otelcol.connector.servicegraph.default.input, otelcol.processor.batch.default.input]
	}
}

otelcol.connector.servicegraph "default" {
	dimensions = ["http.method"]

	debug_metrics { }

	output {
		metrics = [otelcol.exporter.prometheus.default.input]
	}
}

otelcol.processor.batch "default" {
	output {
		metrics = [otelcol.exporter.otlp.default.input]
		logs    = [otelcol.exporter.otlp.default.input]
		traces  = [otelcol.exporter.otlp.default.input]
	}
}

otelcol.exporter.otlp "default" {
	client {
		endpoint = "tempo.monitoring:4317"

		tls {
			insecure = true
		}
	}
}

otelcol.exporter.prometheus "default" {
	forward_to = [prometheus.remote_write.default.receiver]
}

##########################################################
#                        METRICS
##########################################################

discovery.kubernetes "services" {
  role = "service"
}

prometheus.scrape "services" {
  targets    = discovery.kubernetes.services.targets
  forward_to = [prometheus.remote_write.default.receiver]
}

prometheus.remote_write "default" {
	endpoint {
		url = "http://vmsingle-victoria-metrics-k8s-stack.monitoring:8429/api/v1/write"
	}
}
