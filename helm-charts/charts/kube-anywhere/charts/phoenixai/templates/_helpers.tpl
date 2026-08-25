{{/*
Common labels
*/}}
{{- define "phoenixaicluster.labels" -}}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
initpassword secret name
*/}}

{{- define "phoenixaicluster.initpassword.secret.name" -}}
{{ default (print (include "phoenixaicluster.name" .) "-credential") .Values.initPassword.passwordSecret }}
{{- end }}

{{/*
phoenixaicluster
*/}}

{{- define "phoenixaicluster.name" -}}
{{ default (default .Chart.Name .Values.nameOverride) .Values.phoenixAICluster.name }}
{{- end }}

{{- define "phoenixaicluster.namespace" -}}
{{ default .Release.Namespace .Values.phoenixAICluster.namespace }}
{{- end }}

{{- define "phoenixaicluster.fe.name" -}}
{{- print (include "phoenixaicluster.name" .) "-fe" }}
{{- end }}

{{- define "phoenixaicluster.cn.name" -}}
{{- print (include "phoenixaicluster.name" .) "-cn" }}
{{- end }}

{{- define "phoenixaicluster.fe.configmap.name" -}}
{{- print (include "phoenixaicluster.fe.name" .) "-cm" }}
{{- end }}

{{- define "phoenixaicluster.cn.configmap.name" -}}
{{- print (include "phoenixaicluster.cn.name" .) "-cm" }}
{{- end }}

{{- define "phoenixaicluster.fe.config" -}}
fe.conf: |
{{- if and .Values.phoenixAIFeSpec.configyaml (kindIs "map" .Values.phoenixAIFeSpec.configyaml) }}
  {{- range $key, $value := .Values.phoenixAIFeSpec.configyaml }}
    {{ $key }} = {{ $value }}
  {{- end }}
{{- else if .Values.phoenixAIFeSpec.configyaml }}
  {{ fail "configyaml must be a map" }}
{{- else }}
  {{- .Values.phoenixAIFeSpec.config | nindent 2 }}
{{- end }}
{{- end }}

{{- define "phoenixaicluster.cn.config" -}}
cn.conf: |
{{- if and .Values.phoenixAICnSpec.configyaml (kindIs "map" .Values.phoenixAICnSpec.configyaml) }}
  {{- range $key, $value := .Values.phoenixAICnSpec.configyaml }}
    {{ $key }} = {{ $value }}
  {{- end }}
{{- else if .Values.phoenixAICnSpec.configyaml }}
  {{ fail "configyaml must be a map" }}
{{- else }}
  {{- .Values.phoenixAICnSpec.config | nindent 2 }}
{{- end }}
{{- end }}

{{- define "phoenixaicluster.fe.meta.suffix" -}}
{{- print "-meta" }}
{{- end }}

{{- define "phoenixaicluster.fe.meta.path" -}}
{{- if .Values.phoenixAIFeSpec.storageSpec.storageMountPath }}
{{- print .Values.phoenixAIFeSpec.storageSpec.storageMountPath }}
{{- else }}
{{- print "/opt/starrocks/fe/meta" }}
{{- end }}
{{- end }}

{{- define "phoenixaicluster.fe.log.suffix" -}}
{{- print "-log" }}
{{- end }}

{{- define "phoenixaicluster.fe.log.path" -}}
{{- if .Values.phoenixAIFeSpec.storageSpec.logMountPath }}
{{- print .Values.phoenixAIFeSpec.storageSpec.logMountPath }}
{{- else }}
{{- print "/opt/starrocks/fe/log" }}
{{- end }}
{{- end }}

{{- define "phoenixaicluster.cn.data.suffix" -}}
{{- print "-data" }}
{{- end }}

{{- define "phoenixaicluster.cn.data.path" -}}
{{- if .Values.phoenixAICnSpec.storageSpec.storageMountPath }}
{{- print .Values.phoenixAICnSpec.storageSpec.storageMountPath }}
{{- else }}
{{- print "/opt/starrocks/cn/storage" }}
{{- end }}
{{- end }}

{{- define "phoenixaicluster.cn.log.suffix" -}}
{{- print "-log" }}
{{- end }}

{{- define "phoenixaicluster.cn.log.path" -}}
{{- if .Values.phoenixAICnSpec.storageSpec.logMountPath }}
{{- print .Values.phoenixAICnSpec.storageSpec.logMountPath }}
{{- else }}
{{- print "/opt/starrocks/cn/log" }}
{{- end }}
{{- end }}

{{- define "phoenixaicluster.cn.spill.suffix" -}}
{{- print "-spill" }}
{{- end }}

{{- define "phoenixaicluster.cn.spill.path" -}}
{{- if .Values.phoenixAICnSpec.storageSpec.spillMountPath }}
{{- print .Values.phoenixAICnSpec.storageSpec.spillMountPath }}
{{- else }}
{{- print "/opt/starrocks/cn/spill" }}
{{- end }}
{{- end }}

{{- define "phoenixaicluster.entrypoint.script.name" -}}
{{- print "entrypoint.sh" }}
{{- end }}

{{- define "phoenixaicluster.entrypoint.mount.path" -}}
{{- print "/etc/phoenixai" }}
{{- end }}

{{- define "phoenixaicluster.fe.entrypoint.script.configmap.name" -}}
{{- print (include "phoenixaicluster.name" .) "-fe-entrypoint-script" }}
{{- end }}

{{- define "phoenixaicluster.cn.entrypoint.script.configmap.name" -}}
{{- print (include "phoenixaicluster.name" .) "-cn-entrypoint-script" }}
{{- end }}

{{/*
Define a function to handle resource limits for fe
*/}}
{{- define "phoenixaicluster.fe.resources" -}}
requests:
  {{- toYaml .Values.phoenixAIFeSpec.resources.requests | nindent 2 }}
limits:
{{- range $key, $value := .Values.phoenixAIFeSpec.resources.limits }}
  {{- if ne (toString $value) "unlimited" }}
  {{ $key }}: {{ $value }}
  {{- end }}
{{- end }}
{{- end -}}

{{/*
Define a function to handle resource limits for cn
*/}}
{{- define "phoenixaicluster.cn.resources" -}}
requests:
  {{- toYaml .Values.phoenixAICnSpec.resources.requests | nindent 2 }}
limits:
{{- range $key, $value := .Values.phoenixAICnSpec.resources.limits }}
  {{- if ne (toString $value) "unlimited" }}
  {{ $key }}: {{ $value }}
  {{- end }}
{{- end }}
{{- end -}}

{{/*
phoenixaicluster.fe.config.hash is used to calculate the hash value of the fe.conf, and due to the length limit, only
the first 8 digits are taken, which will be used as the annotations for pods.
*/}}
{{- define "phoenixaicluster.fe.config.hash" }}
  {{- if and .Values.phoenixAIFeSpec.configyaml (kindIs "map" .Values.phoenixAIFeSpec.configyaml) }}
    {{- $hash := toJson .Values.phoenixAIFeSpec.configyaml | sha256sum | trunc 8 }}
    {{- printf "%s" $hash }}
  {{- else if .Values.phoenixAIFeSpec.configyaml }}
    {{ fail "configyaml must be a map" }}
  {{- else if .Values.phoenixAIFeSpec.config }}
    {{- $hash := toJson .Values.phoenixAIFeSpec.config | sha256sum | trunc 8 }}
    {{- printf "%s" $hash }}
  {{- else }}
    {{- printf "no-config" }}
  {{- end }}
{{- end }}


{{/*
phoenixaicluster.cn.config.hash is used to calculate the hash value of the cn.conf, and due to the length limit, only
the first 8 digits are taken, which will be used as the annotations for pods.
*/}}
{{- define "phoenixaicluster.cn.config.hash" }}
  {{- if and .Values.phoenixAICnSpec.configyaml (kindIs "map" .Values.phoenixAICnSpec.configyaml) }}
    {{- $hash := toJson .Values.phoenixAICnSpec.configyaml | sha256sum | trunc 8 }}
    {{- printf "%s" $hash }}
  {{- else if .Values.phoenixAICnSpec.configyaml }}
    {{ fail "configyaml must be a map" }}
  {{- else if .Values.phoenixAICnSpec.config }}
    {{- $hash := toJson .Values.phoenixAICnSpec.config | sha256sum | trunc 8 }}
    {{- printf "%s" $hash }}
  {{- else }}
    {{- printf "no-config" }}
  {{- end }}
{{- end }}

{{- define "phoenixaicluster.fe.query.port" -}}
{{- $config := index .Values.phoenixAIFeSpec.config  -}}
{{- $configMap := dict -}}
{{- range $line := splitList "\n" $config -}}
{{- $pair := splitList "=" $line -}}
{{- if eq (len $pair) 2 -}}
{{- $_ := set $configMap (trim (index $pair 0)) (trim (index $pair 1)) -}}
{{- end -}}
{{- end -}}
{{- if (index $configMap "query_port") -}}
{{- print (index $configMap "query_port") }}
{{- end }}
{{- end }}

{{- define "phoenixaicluster.fe.entrypoint.script.hash" }}
  {{- if .Values.phoenixAIFeSpec.entrypoint }}
    {{- $hash := toJson .Values.phoenixAIFeSpec.entrypoint.script | sha256sum | trunc 8 }}
    {{- printf "%s" $hash }}
  {{- else }}
    {{- printf "no-config" }}
  {{- end }}
{{- end }}

{{- define "phoenixaicluster.cn.entrypoint.script.hash" }}
  {{- if .Values.phoenixAICnSpec.entrypoint }}
    {{- $hash := toJson .Values.phoenixAICnSpec.entrypoint.script | sha256sum | trunc 8 }}
    {{- printf "%s" $hash }}
  {{- else }}
    {{- printf "no-config" }}
  {{- end }}
{{- end }}

{{- define "phoenixaicluster.fe.http.port" -}}
{{- $config := index .Values.phoenixAIFeSpec.config  -}}
{{- $configMap := dict -}}
{{- range $line := splitList "\n" $config -}}
{{- $pair := splitList "=" $line -}}
{{- if eq (len $pair) 2 -}}
{{- $_ := set $configMap (trim (index $pair 0)) (trim (index $pair 1)) -}}
{{- end -}}
{{- end -}}
{{- if (index $configMap "http_port") -}}
{{- print (index $configMap "http_port") }}
{{- end }}
{{- end }}

{{- define "phoenixaicluster.cn.webserver.port" -}}
{{- include "phoenixaicluster.webserver.port" .Values.phoenixAICnSpec }}
{{- end }}

{{- define "phoenixaicluster.webserver.port" -}}
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

{{/*
Get the value of the schedulerName field in the phoenixAIFeSpec
*/}}
{{- define "phoenixaicluster.fe.schedulerName" -}}
{{- if .Values.phoenixAIFeSpec.schedulerName -}}
{{- .Values.phoenixAIFeSpec.schedulerName -}}
{{- else if .Values.phoenixAICluster.componentValues.schedulerName -}}
{{- .Values.phoenixAICluster.componentValues.schedulerName -}}
{{- end -}}
{{- end -}}

{{/*
Get the value of the schedulerName field in the phoenixAICnSpec
*/}}
{{- define "phoenixaicluster.cn.schedulerName" -}}
{{- if .Values.phoenixAICnSpec.schedulerName -}}
{{- .Values.phoenixAICnSpec.schedulerName -}}
{{- else if .Values.phoenixAICluster.componentValues.schedulerName -}}
{{- .Values.phoenixAICluster.componentValues.schedulerName -}}
{{- end -}}
{{- end -}}

{{/*
Get the value of the serviceAccount field in the phoenixAIFeSpec
*/}}
{{- define "phoenixaicluster.fe.serviceAccount" -}}
{{- if .Values.phoenixAIFeSpec.serviceAccount -}}
{{- .Values.phoenixAIFeSpec.serviceAccount -}}
{{- else if .Values.phoenixAICluster.componentValues.serviceAccount -}}
{{- .Values.phoenixAICluster.componentValues.serviceAccount -}}
{{- end -}}
{{- end -}}

{{/*
Get the value of the serviceAccount field in the phoenixAICnSpec
*/}}
{{- define "phoenixaicluster.cn.serviceAccount" -}}
{{- if .Values.phoenixAICnSpec.serviceAccount -}}
{{- .Values.phoenixAICnSpec.serviceAccount -}}
{{- else if .Values.phoenixAICluster.componentValues.serviceAccount -}}
{{- .Values.phoenixAICluster.componentValues.serviceAccount -}}
{{- end -}}
{{- end -}}

{{/*
Get the value of the imagePullSecrets field in the phoenixAIFeSpec
*/}}
{{- define "phoenixaicluster.fe.imagePullSecrets" -}}
{{- if .Values.phoenixAIFeSpec.imagePullSecrets -}}
{{- toYaml .Values.phoenixAIFeSpec.imagePullSecrets -}}
{{- else if .Values.phoenixAICluster.componentValues.imagePullSecrets -}}
{{- toYaml .Values.phoenixAICluster.componentValues.imagePullSecrets -}}
{{- end -}}
{{- end -}}

{{/*
Get the value of the imagePullSecrets field in the phoenixAICnSpec
*/}}
{{- define "phoenixaicluster.cn.imagePullSecrets" -}}
{{- if .Values.phoenixAICnSpec.imagePullSecrets -}}
{{- toYaml .Values.phoenixAICnSpec.imagePullSecrets -}}
{{- else if .Values.phoenixAICluster.componentValues.imagePullSecrets -}}
{{- toYaml .Values.phoenixAICluster.componentValues.imagePullSecrets -}}
{{- end -}}
{{- end -}}

{{/*
Get the value of the tolerations field in the phoenixAIFeSpec
*/}}
{{- define "phoenixaicluster.fe.tolerations" -}}
{{- if .Values.phoenixAIFeSpec.tolerations -}}
{{- toYaml .Values.phoenixAIFeSpec.tolerations -}}
{{- else if .Values.phoenixAICluster.componentValues.tolerations -}}
{{- toYaml .Values.phoenixAICluster.componentValues.tolerations -}}
{{- end -}}
{{- end -}}

{{/*
Get the value of the tolerations field in the phoenixAICnSpec
*/}}
{{- define "phoenixaicluster.cn.tolerations" -}}
{{- if .Values.phoenixAICnSpec.tolerations -}}
{{- toYaml .Values.phoenixAICnSpec.tolerations -}}
{{- else if .Values.phoenixAICluster.componentValues.tolerations -}}
{{- toYaml .Values.phoenixAICluster.componentValues.tolerations -}}
{{- end -}}
{{- end -}}

{{/*
Get the value of the nodeSelector field in the phoenixAIFeSpec
*/}}
{{- define "phoenixaicluster.fe.nodeSelector" -}}
{{- if .Values.phoenixAIFeSpec.nodeSelector -}}
{{- toYaml .Values.phoenixAIFeSpec.nodeSelector -}}
{{- else if .Values.phoenixAICluster.componentValues.nodeSelector -}}
{{- toYaml .Values.phoenixAICluster.componentValues.nodeSelector -}}
{{- end -}}
{{- end -}}

{{/*
Get the value of the nodeSelector field in the phoenixAICnSpec
*/}}
{{- define "phoenixaicluster.cn.nodeSelector" -}}
{{- if .Values.phoenixAICnSpec.nodeSelector -}}
{{- toYaml .Values.phoenixAICnSpec.nodeSelector -}}
{{- else if .Values.phoenixAICluster.componentValues.nodeSelector -}}
{{- toYaml .Values.phoenixAICluster.componentValues.nodeSelector -}}
{{- end -}}
{{- end -}}

{{/*
Get the value of the affinity field in the phoenixAIFeSpec
*/}}
{{- define "phoenixaicluster.fe.affinity" -}}
{{- if .Values.phoenixAIFeSpec.affinity -}}
{{- toYaml .Values.phoenixAIFeSpec.affinity -}}
{{- else if .Values.phoenixAICluster.componentValues.affinity -}}
{{- toYaml .Values.phoenixAICluster.componentValues.affinity -}}
{{- end -}}
{{- end -}}

{{/*
Get the value of the affinity field in the phoenixAICnSpec
*/}}
{{- define "phoenixaicluster.cn.affinity" -}}
{{- if .Values.phoenixAICnSpec.affinity -}}
{{- toYaml .Values.phoenixAICnSpec.affinity -}}
{{- else if .Values.phoenixAICluster.componentValues.affinity -}}
{{- toYaml .Values.phoenixAICluster.componentValues.affinity -}}
{{- end -}}
{{- end -}}

{{/*
Get the value of the topologySpreadConstraints field in the phoenixAIFeSpec
*/}}
{{- define "phoenixaicluster.fe.topologySpreadConstraints" -}}
{{- if .Values.phoenixAIFeSpec.topologySpreadConstraints -}}
{{- toYaml .Values.phoenixAIFeSpec.topologySpreadConstraints -}}
{{- else if .Values.phoenixAICluster.componentValues.topologySpreadConstraints -}}
{{- toYaml .Values.phoenixAICluster.componentValues.topologySpreadConstraints -}}
{{- end -}}
{{- end -}}

{{/*
Get the value of the topologySpreadConstraints field in the phoenixAICnSpec
*/}}
{{- define "phoenixaicluster.cn.topologySpreadConstraints" -}}
{{- if .Values.phoenixAICnSpec.topologySpreadConstraints -}}
{{- toYaml .Values.phoenixAICnSpec.topologySpreadConstraints -}}
{{- else if .Values.phoenixAICluster.componentValues.topologySpreadConstraints -}}
{{- toYaml .Values.phoenixAICluster.componentValues.topologySpreadConstraints -}}
{{- end -}}
{{- end -}}

{{/*
Get the value of the runAsNonRoot field in the phoenixAIFeSpec
*/}}
{{- define "phoenixaicluster.fe.runAsNonRoot" -}}
{{- if .Values.phoenixAIFeSpec.runAsNonRoot -}}
{{- .Values.phoenixAIFeSpec.runAsNonRoot -}}
{{- else if .Values.phoenixAICluster.componentValues.runAsNonRoot -}}
{{- .Values.phoenixAICluster.componentValues.runAsNonRoot -}}
{{- else -}}
false
{{- end -}}
{{- end -}}

{{/*
Get the value of the runAsNonRoot field in the phoenixAICnSpec
*/}}
{{- define "phoenixaicluster.cn.runAsNonRoot" -}}
{{- if .Values.phoenixAICnSpec.runAsNonRoot -}}
{{- .Values.phoenixAICnSpec.runAsNonRoot -}}
{{- else if .Values.phoenixAICluster.componentValues.runAsNonRoot -}}
{{- .Values.phoenixAICluster.componentValues.runAsNonRoot -}}
{{- else -}}
false
{{- end -}}
{{- end -}}

{{/*
Get the value of hostAliases field in the phoenixAIFeSpec
*/}}
{{- define "phoenixaicluster.fe.hostAliases" -}}
{{- if .Values.phoenixAIFeSpec.hostAliases -}}
{{- toYaml .Values.phoenixAIFeSpec.hostAliases -}}
{{- else if .Values.phoenixAICluster.componentValues.hostAliases -}}
{{- toYaml .Values.phoenixAICluster.componentValues.hostAliases -}}
{{- end -}}
{{- end -}}

{{/*
Get the value of hostAliases field in the phoenixAICnSpec
*/}}
{{- define "phoenixaicluster.cn.hostAliases" -}}
{{- if .Values.phoenixAICnSpec.hostAliases -}}
{{- toYaml .Values.phoenixAICnSpec.hostAliases -}}
{{- else if .Values.phoenixAICluster.componentValues.hostAliases -}}
{{- toYaml .Values.phoenixAICluster.componentValues.hostAliases -}}
{{- end -}}
{{- end -}}

{{/*
Get the value of tag field in the phoenixAIFeSpec
*/}}
{{- define "phoenixaicluster.fe.image.tag" -}}
{{- if and .Values.phoenixAIFeSpec.image.tag (ne (toString .Values.phoenixAIFeSpec.image.tag) "") -}}
{{- .Values.phoenixAIFeSpec.image.tag -}}
{{- else -}}
{{- .Values.phoenixAICluster.componentValues.image.tag -}}
{{- end -}}
{{- end -}}

{{/*
Get the value of tag field in the phoenixAICnSpec
*/}}
{{- define "phoenixaicluster.cn.image.tag" -}}
{{- if and .Values.phoenixAICnSpec.image.tag (ne (toString .Values.phoenixAICnSpec.image.tag) "") -}}
{{- .Values.phoenixAICnSpec.image.tag -}}
{{- else -}}
{{- .Values.phoenixAICluster.componentValues.image.tag -}}
{{- end -}}
{{- end -}}

{{/*
Get the value of podLabels field in the phoenixAIFeSpec
*/}}
{{- define "phoenixaicluster.fe.podLabels" -}}
{{- if .Values.phoenixAIFeSpec.podLabels -}}
{{- toYaml .Values.phoenixAIFeSpec.podLabels -}}
{{- else if .Values.phoenixAICluster.componentValues.podLabels -}}
{{- toYaml .Values.phoenixAICluster.componentValues.podLabels -}}
{{- end -}}
{{- end -}}

{{/*
Get the value of podLabels field in the phoenixAICnSpec
*/}}
{{- define "phoenixaicluster.cn.podLabels" -}}
{{- if .Values.phoenixAICnSpec.podLabels -}}
{{- toYaml .Values.phoenixAICnSpec.podLabels -}}
{{- else if .Values.phoenixAICluster.componentValues.podLabels -}}
{{- toYaml .Values.phoenixAICluster.componentValues.podLabels -}}
{{- end -}}
{{- end -}}

{{/*
Build the Datadog log annotation value for a given component.
Arguments (passed as a dict via "include"):
  .root = root context (has .Values)
  .component = "fe" or "cn"
  .multilinePattern = regex pattern string for multi_line rule
  .multilineName = name for the multi_line rule
Usage: include "phoenixaicluster.datadog.log.annotation" (dict "root" . "component" "fe" "multilinePattern" "..." "multilineName" "...")
*/}}
{{- define "phoenixaicluster.datadog.log.annotation" -}}
{{- $root := .root -}}
{{- $component := .component -}}
{{- $multilinePattern := .multilinePattern -}}
{{- $multilineName := .multilineName -}}
{{- $logConfig := $root.Values.datadog.log.logConfig -}}
{{- $base := dict "service" "phoenixai" "source" $component -}}
{{- if eq (kindOf $logConfig) "map" -}}
  {{- $base = merge $base $logConfig -}}
{{- else if eq (kindOf $logConfig) "string" -}}
  {{- if ne (trimAll " {}" $logConfig) "" -}}
    {{- $extra := fromJson $logConfig -}}
    {{- $base = merge $base $extra -}}
  {{- end -}}
{{- end -}}
{{- if $root.Values.datadog.log.enableMultilineLogParsing -}}
  {{- if not (hasKey $base "log_processing_rules") -}}
    {{- $rule := dict "name" $multilineName "pattern" $multilinePattern "type" "multi_line" -}}
    {{- $_ := set $base "log_processing_rules" (list $rule) -}}
  {{- end -}}
{{- end -}}
{{- list $base | toJson | squote -}}
{{- end -}}
