
{{/*
Expand the name of the chart.
*/}}
{{- define "gatekeeper.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "gatekeeper.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "gatekeeper.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Adds additional pod labels to the common ones
*/}}
{{- define "gatekeeper.podLabels" -}}
{{- if .Values.podLabels }}
{{- toYaml .Values.podLabels | nindent 8 }}
{{- end }}
{{- end -}}

{{- define "system_default_registry" -}}
{{- if .Values.global.cattle.systemDefaultRegistry -}}
{{- printf "%s/" .Values.global.cattle.systemDefaultRegistry -}}
{{- else -}}
{{- "" -}}
{{- end -}}
{{- end -}}

{{/*
Windows cluster will add default taint for linux nodes,
add below linux tolerations to workloads could be scheduled to those linux nodes
*/}}
{{- define "linux-node-tolerations" -}}
- key: "cattle.io/os"
  value: "linux"
  effect: "NoSchedule"
  operator: "Equal"
{{- end -}}

{{- define "linux-node-selector" -}}
kubernetes.io/os: linux
{{- end -}}

{{/*
Output post install webhook probe container entry
*/}}
{{- define "gatekeeper.postInstallWebhookProbeContainer" -}}
- name: webhook-probe-post
  image: "{{ .Values.postInstall.probeWebhook.image.repository }}:{{ .Values.postInstall.probeWebhook.image.tag }}"
  imagePullPolicy: {{ .Values.postInstall.probeWebhook.image.pullPolicy }}
  command:
    - "curl"
  args:
    - "--retry"
    - "99999"
    - "--retry-max-time"
    - "{{ .Values.postInstall.probeWebhook.waitTimeout }}"
    - "--retry-delay"
    - "1"
    - "--max-time"
    - "{{ .Values.postInstall.probeWebhook.httpTimeout }}"
    {{- if .Values.postInstall.probeWebhook.insecureHTTPS }}
    - "--insecure"
    {{- else }}
    - "--cacert"
    - /certs/ca.crt
    {{- end }}
    - "-v"
    - "https://gatekeeper-webhook-service.{{ .Release.Namespace }}.svc/v1/admitlabel?timeout=2s"
  resources:
  {{- toYaml .Values.postInstall.resources | nindent 4 }}
  securityContext:
    {{- if .Values.enableRuntimeDefaultSeccompProfile }}
    seccompProfile:
      type: RuntimeDefault
    {{- end }}
  {{- toYaml .Values.postInstall.securityContext | nindent 4 }}
  volumeMounts:
  - mountPath: /certs
    name: cert
    readOnly: true
{{- end -}}

{{/*
Output post install webhook probe volume entry
*/}}
{{- define "gatekeeper.postInstallWebhookProbeVolume" -}}
- name: cert
  secret:
    secretName: {{ .Values.externalCertInjection.secretName }}
{{- end -}}
