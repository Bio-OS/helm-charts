{{/* vim: set filetype=mustache: */}}

{{/*
Expand the name of the chart.
*/}}
{{- define "common.names.name" -}}
{{- .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "common.labels.standard" -}}
app.kubernetes.io/name: {{ include "common.names.name" . }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
{{- if .Values.labels }}
{{toYaml .Values.labels }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
cromwell resource name
*/}}
{{- define "common.names.cromwell" -}}
{{- if contains .Chart.Name .Release.Name -}}
{{- printf "%s" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
cromwell labels
*/}}
{{- define "common.labels.cromwell" -}}
{{- include "common.labels.standard" . }}
app.kubernetes.io/component: cromwell
{{- if .Values.labels }}
{{toYaml .Values.labels }}
{{- end }}
{{- end -}}

{{/*
cromwell matchLabels
*/}}
{{- define "common.labels.matchLabels.cromwell" -}}
app.kubernetes.io/name: {{ include "common.names.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: cromwell
{{- end -}}

{{/*
cromwell pod labels
*/}}
{{- define "common.podLabels.cromwell" -}}
{{- if .Values.podLabels }}
{{toYaml .Values.podLabels }}
{{- end }}
{{- if .Values.podLabels }}
{{toYaml .Values.podLabels }}
{{- end }}
{{- end -}}

{{/*
cromwell pod annotations
*/}}
{{- define "common.podAnnotations.cromwell" -}}
{{- if .Values.podAnnotations }}
{{toYaml .Values.podAnnotations }}
{{- end }}
{{- if .Values.podAnnotations }}
{{toYaml .Values.podAnnotations }}
{{- end }}
{{- end -}}

{{/*
Return the cromwell image name
*/}}
{{- define "common.images.cromwell" -}}
  {{- $repositoryName := .Values.platformConfig.registryRepository -}}
  {{- $imageName := .Values.image.name -}}
  {{- $tag := .Values.image.tag | toString -}}
  {{- if .Values.platformConfig.registryDomain -}}
    {{- $registryName := .Values.platformConfig.registryDomain -}}
    {{- printf "%s/%s/%s:%s" $registryName $repositoryName $imageName $tag -}}
  {{- else -}}
    {{- printf "%s/%s:%s" $repositoryName $imageName $tag -}}
  {{- end -}}
{{- end -}}

{{/*
cromwell config
*/}}
{{- define "cromwell.config" -}}
include required(classpath("application"))
webservice {
  port = {{ .Values.service.httpPort }}
}
workflow-options {
  workflow-log-dir = {{ .Values.basePath }}{{ .Values.log.path }}
  workflow-log-temporary = false
}
call-caching {
  enabled = true
  invalidate-bad-cache-results = true
}
{{- if .Values.db.local.enabled }}
database {
  profile = "slick.jdbc.HsqldbProfile$"
  db {
    driver = "org.hsqldb.jdbcDriver"
    url = """
    jdbc:hsqldb:file:{{ .Values.basePath }}{{ .Values.db.local.path }};
    shutdown=false;
    hsqldb.default_table_type=cached;hsqldb.tx=mvcc;
    hsqldb.result_max_memory_rows=10000;
    hsqldb.large_data=true;
    hsqldb.applog=1;
    hsqldb.lob_compressed=true;
    hsqldb.script_format=3
    """
    connectionTimeout = 120000
    numThreads = 1
  }
}
{{- else if .Values.db.mysql.enabled }}
database {
  profile = "slick.jdbc.MySQLProfile$"
  db {
    driver = "com.mysql.cj.jdbc.Driver"
    url = "jdbc:mysql://{{ .Values.db.mysql.host }}:{{ .Values.db.mysql.port }}/{{ .Values.db.mysql.name }}?rewriteBatchedStatements=true&useSSL=false"
    port = {{ .Values.db.mysql.port }}
    user = {{ .Values.db.mysql.username | quote }}
    password = {{ .Values.db.mysql.password | quote }}
    connectionTimeout = 5000
  }
}
{{- end }}
backend {
  default = "Local"
  providers {
    Local {
      config {
        root = "{{ .Values.basePath }}{{ .Values.executionPath }}"
        filesystem {
          local {
      localization: [
      	"hard-link", "soft-link", "copy"
      ]

      caching {
        duplication-strategy: [
          "hard-link", "soft-link", "copy"
        ]
        hashing-strategy: "md5"
        check-sibling-md5: false
      }
    }
  }
}
    }
  }
}
{{- end -}}