{{- define "diploma-platform.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "diploma-platform.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{- define "diploma-platform.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" }}
{{- end }}

{{- define "diploma-platform.labels" -}}
helm.sh/chart: {{ include "diploma-platform.chart" . }}
{{ include "diploma-platform.selectorLabels" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "diploma-platform.selectorLabels" -}}
app.kubernetes.io/name: {{ include "diploma-platform.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "diploma-platform.image" -}}
{{- $reg := .Values.platform.imageRegistry -}}
{{- $repo := .repository -}}
{{- $tag := .tag | default "latest" -}}
{{- if $reg -}}
{{- printf "%s/%s:%s" $reg $repo $tag -}}
{{- else -}}
{{- printf "%s:%s" $repo $tag -}}
{{- end }}
{{- end }}

{{- define "diploma-platform.kafkaBrokers" -}}
kafka:9092
{{- end }}

{{- define "diploma-platform.minioEndpoint" -}}
minio:9000
{{- end }}

{{- define "diploma-platform.imagePullSecrets" -}}
{{- with .Values.platform.imagePullSecrets }}
imagePullSecrets:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end }}
