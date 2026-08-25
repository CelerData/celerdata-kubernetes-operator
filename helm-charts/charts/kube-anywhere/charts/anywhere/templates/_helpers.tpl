{{- define "anywhere.name" -}}
{{- .Chart.Name -}}
{{- end }}

{{/*
The ServiceAccount the pod runs as; defaults to the chart name like every other resource.
*/}}
{{- define "anywhere.serviceAccountName" -}}
{{- default (include "anywhere.name" .) .Values.serviceAccount.name -}}
{{- end }}

{{/*
The image tag defaults to the chart appVersion.
*/}}
{{- define "anywhere.imageTag" -}}
{{- default .Chart.AppVersion .Values.image.tag -}}
{{- end }}

{{/*
The Secret holding the Admin Console accounts (key = username, value =
password): the user-provided one, or the chart-rendered "<name>-admin".
*/}}
{{- define "anywhere.adminSecretName" -}}
{{- default (printf "%s-admin" (include "anywhere.name" .)) .Values.admin.existingSecret -}}
{{- end }}

{{/*
The data PVC the StatefulSet mounts: the user-provided existingClaim, or the
chart-rendered one (templates/pvc.yaml), named data-<name>-0.
*/}}
{{- define "anywhere.dataPVCName" -}}
{{- default (printf "data-%s-0" (include "anywhere.name" .)) .Values.persistence.existingClaim -}}
{{- end }}

{{/*
The namespaces anywhere serves, deduplicated, as a JSON array (use with
fromJsonArray). Empty means all namespaces (cluster-scoped RBAC, pairing a
global-mode operator).
*/}}
{{- define "anywhere.watchNamespaces" -}}
{{- $namespaces := list -}}
{{- range .Values.watchNamespaces -}}
{{- if and . (not (has . $namespaces)) -}}
{{- $namespaces = append $namespaces . -}}
{{- end -}}
{{- end -}}
{{- toJson $namespaces -}}
{{- end }}
