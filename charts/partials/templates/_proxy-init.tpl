{{- define "partials.proxy-init" -}}
args:
- --incoming-proxy-port
- {{.global.Proxy.Ports.Inbound | quote}}
- --outgoing-proxy-port
- {{.global.Proxy.Ports.Outbound | quote}}
- --proxy-uid
- {{.global.Proxy.UID | quote}}
- --inbound-ports-to-ignore
- {{.global.Proxy.Ports.Control}},{{.global.Proxy.Ports.Admin}}{{ternary (printf ",%s" .global.ProxyInit.IgnoreInboundPorts) "" (not (empty .global.ProxyInit.IgnoreInboundPorts)) }}
{{- if hasPrefix "linkerd-" .global.Proxy.Component }}
- --outbound-ports-to-ignore
- {{ternary (printf "443,%s" .global.ProxyInit.IgnoreOutboundPorts) (quote "443") (not (empty .global.ProxyInit.IgnoreOutboundPorts)) }}
{{- else if .global.ProxyInit.IgnoreOutboundPorts }}
- --outbound-ports-to-ignore
- {{.global.ProxyInit.IgnoreOutboundPorts | quote}}
{{- end }}
image: {{.global.ProxyInit.Image.Name}}:{{.global.ProxyInit.Image.Version}}
imagePullPolicy: {{.global.ProxyInit.Image.PullPolicy}}
name: linkerd-init
{{ include "partials.resources" .global.ProxyInit.Resources }}
securityContext:
  allowPrivilegeEscalation: false
  capabilities:
    add:
    - NET_ADMIN
    - NET_RAW
    {{- if .global.ProxyInit.Capabilities -}}
    {{- if .global.ProxyInit.Capabilities.Add }}
    {{- toYaml .global.ProxyInit.Capabilities.Add | trim | nindent 4 }}
    {{- end }}
    {{- if .global.ProxyInit.Capabilities.Drop -}}
    {{- include "partials.proxy-init.capabilities.drop" .global.ProxyInit | nindent 4 -}}
    {{- end }}
    {{- end }}
  privileged: false
  readOnlyRootFilesystem: true
  runAsNonRoot: false
  runAsUser: 0
terminationMessagePolicy: FallbackToLogsOnError
{{- if .global.ProxyInit.SAMountPath }}
volumeMounts:
- mountPath: {{.global.ProxyInit.SAMountPath.MountPath}}
  name: {{.global.ProxyInit.SAMountPath.Name}}
  readOnly: {{.global.ProxyInit.SAMountPath.ReadOnly}}
{{- end -}}
{{- end -}}
