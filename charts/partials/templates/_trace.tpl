{{ define "partials.linkerd.trace" -}}
{{ if .ControlPlaneTracing -}}
- -trace-collector=linkerd-collector.{{.global.Namespace}}.svc.{{.global.ClusterDomain}}:55678
{{ end -}}
{{- end }}
