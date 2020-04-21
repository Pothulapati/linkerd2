package linkerd2

import (
	"k8s.io/helm/pkg/chartutil"
	"sigs.k8s.io/yaml"
)

var (
	prometheusAddOn = "prometheus"
)

// prometheus is an add-on that installs prometheus
type Prometheus map[string]interface{}

// Name returns the name of the Prometheus add-on
func (p Prometheus) Name() string {
	return prometheusAddOn
}

// Values returns the configuration values that were assigned for this add-on
func (p Prometheus) Values() []byte {
	values, err := yaml.Marshal(p)
	if err != nil {
		return nil
	}
	return values
}

// Templates returns the template files specific to this add-on
func (p Prometheus) Templates() []*chartutil.BufferedFile {
	return []*chartutil.BufferedFile{
		{Name: chartutil.ChartfileName},
		{Name: "templates/prometheus-rbac.yaml"},
		{Name: "templates/prometheus.yaml"},
	}
}
