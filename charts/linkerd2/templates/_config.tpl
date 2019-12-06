{{- define "linkerd.configs.global" -}}
{
  "linkerdNamespace": "{{.global.Namespace}}",
  "cniEnabled": false,
  "version": "{{.global.LinkerdVersion}}",
  "identityContext":{
    "trustDomain": "{{.global.Identity.TrustDomain}}",
    "trustAnchorsPem": "{{required "Please provide the identity trust anchors" .global.Identity.TrustAnchorsPEM | trim | replace "\n" "\\n"}}",
    "issuanceLifeTime": "{{.global.Identity.Issuer.IssuanceLifeTime}}",
    "clockSkewAllowance": "{{.global.Identity.Issuer.ClockSkewAllowance}}",
    "scheme": "{{.global.Identity.Issuer.Scheme}}"
  },
  "autoInjectContext": null,
  "omitWebhookSideEffects": {{.OmitWebhookSideEffects}},
  "clusterDomain": "{{.global.ClusterDomain}}"
}
{{- end -}}

{{- define "linkerd.configs.proxy" -}}
{
  "proxyImage":{
    "imageName":"{{.global.Proxy.Image.Name}}",
    "pullPolicy":"{{.global.Proxy.Image.PullPolicy}}"
  },
  "proxyInitImage":{
    "imageName":"{{.global.ProxyInit.Image.Name}}",
    "pullPolicy":"{{.global.ProxyInit.Image.PullPolicy}}"
  },
  "controlPort":{
    "port": {{.global.Proxy.Ports.Control}}
  },
  "ignoreInboundPorts":[
    {{- $ports := splitList "," .global.ProxyInit.IgnoreInboundPorts -}}
    {{- if gt (len $ports) 1}}
    {{- $last := sub (len $ports) 1 -}}
    {{- range $i,$port := $ports -}}
    {"port":{{$port}}}{{ternary "," "" (ne $i $last)}}
    {{- end -}}
    {{- end -}}
  ],
  "ignoreOutboundPorts":[
    {{- $ports := splitList "," .global.ProxyInit.IgnoreOutboundPorts -}}
    {{- if gt (len $ports) 1}}
    {{- $last := sub (len $ports) 1 -}}
    {{- range $i,$port := $ports -}}
    {"port":{{$port}}}{{ternary "," "" (ne $i $last)}}
    {{- end -}}
    {{- end -}}
  ],
  "inboundPort":{
    "port": {{.global.Proxy.Ports.Inbound}}
  },
  "adminPort":{
    "port": {{.global.Proxy.Ports.Admin}}
  },
  "outboundPort":{
    "port": {{.global.Proxy.Ports.Outbound}}
  },
  "resource":{
    "requestCpu": "{{.global.Proxy.Resources.CPU.Request}}",
    "limitCpu": "{{.global.Proxy.Resources.CPU.Limit}}",
    "requestMemory": "{{.global.Proxy.Resources.Memory.Request}}",
    "limitMemory": "{{.global.Proxy.Resources.Memory.Limit}}"
  },
  "proxyUid": {{.global.Proxy.UID}},
  "logLevel":{
    "level": "{{.global.Proxy.LogLevel}}"
  },
  "disableExternalProfiles": {{not .global.Proxy.EnableExternalProfiles}},
  "proxyVersion": "{{.global.Proxy.Image.Version}}",
  "proxyInitImageVersion": "{{.global.ProxyInit.Image.Version}}"
}
{{- end -}}

{{- define "linkerd.configs.install" -}}
{
  "cliVersion":"{{ .global.LinkerdVersion }}",
  "flags":[]
}
{{- end -}}
