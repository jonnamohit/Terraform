{{- define "app-new.fullname" -}}
{{- printf "%s" .Release.Name }}
{{- end -}}

{{- define "app-new.labels" -}}
helm.sh/chart: {{ include "app-new.chart" . }}
app.kubernetes.io/name: {{ include "app-new.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- if .Values.appVersion }}
app.kubernetes.io/version: {{ .Values.appVersion | quote }}
{{- end }}
{{- end -}}

{{- define "app-new.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end -}}

{{- define "app-new.chart" -}}
{{ .Chart.Name }}-{{ .Chart.Version }}
{{- end -}}
