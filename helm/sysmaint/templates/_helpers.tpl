# SYSMAINT Helm Chart Helpers
#
# SPDX-License-Identifier: MIT
# Copyright (c) 2025 Harery

{{/*
Expand the name of the chart.
*/}}
{{- define "sysmaint.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "sysmaint.fullname" -}}
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

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "sysmaint.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "sysmaint.labels" -}}
helm.sh/chart: {{ include "sysmaint.chart" . }}
{{ include "sysmaint.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "sysmaint.selectorLabels" -}}
app.kubernetes.io/name: {{ include "sysmaint.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: system-maintenance
app.kubernetes.io/part-of: sysmaint
{{- end }}

{{/*
Create the name of the service account
*/}}
{{- define "sysmaint.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "sysmaint.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Image tag
*/}}
{{- define "sysmaint.image" -}}
{{- $tag := .Values.image.tag | default .Chart.AppVersion }}
{{- printf "%s:%s" .Values.image.repository $tag }}
{{- end }}
