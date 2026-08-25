{{- define "phoenixaiwarehouse.name" -}}
{{ .Release.Name }}
{{- end }}

{{- define "phoenixaiwarehouse.namespace" -}}
{{ .Release.Namespace }}
{{- end }}

{{/*
phoenixaiwarehouse.prefix is the name prefix the operator gives every sub-resource of a warehouse
(StatefulSet, Services, ConfigMap, HPA), and the value it puts in their
app.phoenixai.ownerreference/name label. It must stay in sync with GetPrefixNameForWarehouse in
pkg/k8sutils/templates/object/meta.go.
*/}}
{{- define "phoenixaiwarehouse.prefix" -}}
{{- print (include "phoenixaiwarehouse.name" .) "-warehouse" }}
{{- end }}

{{- define "phoenixaiwarehouse.cn.name" -}}
{{- print (include "phoenixaiwarehouse.prefix" .) "-cn" }}
{{- end }}

{{- define "phoenixaiwarehouse.labels" -}}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "phoenixaiwarehouse.configmap.name" -}}
{{- print (include "phoenixaiwarehouse.name" .) "-cm" }}
{{- end }}

{{- define "phoenixaiwarehouse.config" -}}
cn.conf: |
{{- if .Values.spec.config }}
{{- .Values.spec.config | nindent 2 }}
{{- end }}
{{- end }}

{{/*
phoenixaiwarehouse.config.hash is used to calculate the hash value of the cn.conf, and due to the length limit, only
the first 8 digits are taken, which will be used as the annotations for pods.
*/}}
{{- define "phoenixaiwarehouse.config.hash" }}
  {{- if .Values.spec.config }}
    {{- $hash := toJson .Values.spec.config | sha256sum | trunc 8 }}
    {{- printf "%s" $hash }}
  {{- else }}
    {{- printf "no-config" }}
  {{- end }}
{{- end }}

{{- define "phoenixaiwarehouse.webserver.port" -}}
{{- include "phoenixaiwarehouse.get.webserver.port" .Values.spec }}
{{- end }}

{{- define "phoenixaiwarehouse.get.webserver.port" -}}
{{- $config := index .config  -}}
{{- $configMap := dict -}}
{{- range $line := splitList "\n" $config -}}
{{- $pair := splitList "=" $line -}}
{{- if eq (len $pair) 2 -}}
{{- $_ := set $configMap (trim (index $pair 0)) (trim (index $pair 1)) -}}
{{- end -}}
{{- end -}}
{{- if (index $configMap "webserver_port") -}}
{{- print (index $configMap "webserver_port") }}
{{- end }}
{{- end }}

{{- define "phoenixaicluster.cn.data.suffix" -}}
{{- print "-data" }}
{{- end }}

{{- define "phoenixaicluster.cn.data.path" -}}
{{- print "/opt/starrocks/cn/storage" }}
{{- end }}

{{- define "phoenixaicluster.cn.log.suffix" -}}
{{- print "-log" }}
{{- end }}

{{- define "phoenixaicluster.cn.log.path" -}}
{{- print "/opt/starrocks/cn/log" }}
{{- end }}
