{{ define "partials.proxy" -}}
env:
- name: LINKERD2_PROXY_LOG
  value: {{.global.Proxy.LogLevel}}
- name: LINKERD2_PROXY_DESTINATION_SVC_ADDR
  value: {{ternary "localhost.:8086" (printf "linkerd-dst.%s.svc.%s:8086" .global.Namespace .global.ClusterDomain) (eq .global.Proxy.Component "linkerd-destination")}}
- name: LINKERD2_PROXY_CONTROL_LISTEN_ADDR
  value: 0.0.0.0:{{.global.Proxy.Ports.Control}}
- name: LINKERD2_PROXY_ADMIN_LISTEN_ADDR
  value: 0.0.0.0:{{.global.Proxy.Ports.Admin}}
- name: LINKERD2_PROXY_OUTBOUND_LISTEN_ADDR
  value: 127.0.0.1:{{.global.Proxy.Ports.Outbound}}
- name: LINKERD2_PROXY_INBOUND_LISTEN_ADDR
  value: 0.0.0.0:{{.global.Proxy.Ports.Inbound}}
- name: LINKERD2_PROXY_DESTINATION_GET_SUFFIXES
  {{- $internalProfileSuffix := printf "svc.%s." .global.ClusterDomain }}
  value: {{ternary "." $internalProfileSuffix .global.Proxy.EnableExternalProfiles}}
- name: LINKERD2_PROXY_DESTINATION_PROFILE_SUFFIXES
  {{- $internalProfileSuffix := printf "svc.%s." .global.ClusterDomain }}
  value: {{ternary "." $internalProfileSuffix .global.Proxy.EnableExternalProfiles}}
- name: LINKERD2_PROXY_INBOUND_ACCEPT_KEEPALIVE
  value: 10000ms
- name: LINKERD2_PROXY_OUTBOUND_CONNECT_KEEPALIVE
  value: 10000ms
- name: _pod_ns
  valueFrom:
    fieldRef:
      fieldPath: metadata.namespace
- name: LINKERD2_PROXY_DESTINATION_CONTEXT
  value: ns:$(_pod_ns)
{{ if eq .global.Proxy.Component "linkerd-prometheus" -}}
- name: LINKERD2_PROXY_OUTBOUND_ROUTER_CAPACITY
  value: "10000"
{{ end -}}
{{ if .global.Proxy.DisableIdentity -}}
- name: LINKERD2_PROXY_IDENTITY_DISABLED
  value: disabled
{{ else -}}
- name: LINKERD2_PROXY_IDENTITY_DIR
  value: /var/run/linkerd/identity/end-entity
- name: LINKERD2_PROXY_IDENTITY_TRUST_ANCHORS
  value: |
  {{- required "Please provide the identity trust anchors" .global.Identity.TrustAnchorsPEM | trim | nindent 4 }}
- name: LINKERD2_PROXY_IDENTITY_TOKEN_FILE
  value: /var/run/secrets/kubernetes.io/serviceaccount/token
- name: LINKERD2_PROXY_IDENTITY_SVC_ADDR
  {{- $identitySvcAddr := printf "linkerd-identity.%s.svc.%s:8080" .global.Namespace .global.ClusterDomain }}
  value: {{ternary "localhost.:8080" $identitySvcAddr (eq .global.Proxy.Component "linkerd-identity")}}
- name: _pod_sa
  valueFrom:
    fieldRef:
      fieldPath: spec.serviceAccountName
- name: _l5d_ns
  value: {{.global.Namespace}}
- name: _l5d_trustdomain
  value: {{.global.Identity.TrustDomain}}
- name: LINKERD2_PROXY_IDENTITY_LOCAL_NAME
  value: $(_pod_sa).$(_pod_ns).serviceaccount.identity.$(_l5d_ns).$(_l5d_trustdomain)
- name: LINKERD2_PROXY_IDENTITY_SVC_NAME
  value: linkerd-identity.$(_l5d_ns).serviceaccount.identity.$(_l5d_ns).$(_l5d_trustdomain)
- name: LINKERD2_PROXY_DESTINATION_SVC_NAME
  value: linkerd-destination.$(_l5d_ns).serviceaccount.identity.$(_l5d_ns).$(_l5d_trustdomain)
{{ end -}}
{{ if .global.Proxy.DisableTap -}}
- name: LINKERD2_PROXY_TAP_DISABLED
  value: "true"
{{ else if not .global.Proxy.DisableIdentity -}}
- name: LINKERD2_PROXY_TAP_SVC_NAME
  value: linkerd-tap.$(_l5d_ns).serviceaccount.identity.$(_l5d_ns).$(_l5d_trustdomain)
{{ end -}}
{{ if .ControlPlaneTracing -}}
- name: LINKERD2_PROXY_TRACE_COLLECTOR_SVC_ADDR
  value: linkerd-collector.{{.global.Namespace}}.svc.{{.global.ClusterDomain}}:55678
- name: LINKERD2_PROXY_TRACE_COLLECTOR_SVC_NAME
  value: linkerd-collector.{{.global.Namespace}}.serviceaccount.identity.$(_l5d_ns).$(_l5d_trustdomain)
{{ else if .global.Proxy.Trace -}}
{{ if .global.Proxy.Trace.CollectorSvcAddr -}}
- name: LINKERD2_PROXY_TRACE_COLLECTOR_SVC_ADDR
  value: {{ .global.Proxy.Trace.CollectorSvcAddr }}
- name: LINKERD2_PROXY_TRACE_COLLECTOR_SVC_NAME
  value: {{ .global.Proxy.Trace.CollectorSvcAccount }}.serviceaccount.identity.$(_l5d_ns).$(_l5d_trustdomain)
{{ end -}}
{{ end -}}
image: {{.global.Proxy.Image.Name}}:{{.global.Proxy.Image.Version}}
imagePullPolicy: {{.global.Proxy.Image.PullPolicy}}
livenessProbe:
  httpGet:
    path: /metrics
    port: {{.global.Proxy.Ports.Admin}}
  initialDelaySeconds: 10
name: linkerd-proxy
ports:
- containerPort: {{.global.Proxy.Ports.Inbound}}
  name: linkerd-proxy
- containerPort: {{.global.Proxy.Ports.Admin}}
  name: linkerd-admin
readinessProbe:
  httpGet:
    path: /ready
    port: {{.global.Proxy.Ports.Admin}}
  initialDelaySeconds: 2
{{- if .global.Proxy.Resources }}
{{ include "partials.resources" .global.Proxy.Resources }}
{{- end }}
securityContext:
  allowPrivilegeEscalation: false
  {{- if .global.Proxy.Capabilities -}}
  {{- include "partials.proxy.capabilities" .global.Proxy | nindent 2 -}}
  {{- end }}
  readOnlyRootFilesystem: true
  runAsUser: {{.global.Proxy.UID}}
terminationMessagePolicy: FallbackToLogsOnError
{{- if or (not .global.Proxy.DisableIdentity) (.global.Proxy.SAMountPath) }}
volumeMounts:
{{- if not .global.Proxy.DisableIdentity }}
- mountPath: /var/run/linkerd/identity/end-entity
  name: linkerd-identity-end-entity
{{- end -}}
{{- if .global.Proxy.SAMountPath }}
- mountPath: {{.global.Proxy.SAMountPath.MountPath}}
  name: {{.global.Proxy.SAMountPath.Name}}
  readOnly: {{.global.Proxy.SAMountPath.ReadOnly}}
{{- end -}}
{{- end -}}
{{- end }}
