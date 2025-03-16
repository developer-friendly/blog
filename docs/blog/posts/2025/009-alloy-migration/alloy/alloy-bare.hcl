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
}

loki.source.file "kubernetes_pods" {
	targets               = local.file_match.kubernetes_pods.targets
	forward_to            = [loki.process.kubernetes_pods.receiver]
	legacy_positions_file = "/run/promtail/positions.yaml"
}

loki.write "default" {
	endpoint {
		url = "http://loki-gateway/loki/api/v1/push"
	}
	external_labels = {}
}
