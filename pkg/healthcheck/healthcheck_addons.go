package healthcheck

import (
	"context"
	"fmt"

	l5dcharts "github.com/linkerd/linkerd2/pkg/charts/linkerd2"
	"github.com/linkerd/linkerd2/pkg/k8s"
	"sigs.k8s.io/yaml"
)

var (
	// LinkerdAddOnChecks adds checks to validate the add-on components
	LinkerdAddOnChecks CategoryID = "linkerd-addons"

	// AddOnCategories is the list of add-on category checks
	AddOnCategories = []CategoryID{LinkerdAddOnChecks}
)

func (hc *HealthChecker) addOnCategories() []category {
	return []category{
		{
			id: LinkerdAddOnChecks,
			checkers: []checker{
				{
					description: "linkerd add-on configmap exists",
					warning:     true,
					check: func(context.Context) error {
						return hc.checkIfAddOnsConfigMapExists()
					},
				},
			},
		},
	}
}

func (hc *HealthChecker) checkIfAddOnsConfigMapExists() error {

	// Check if linkerd-config-addons ConfigMap present, If no skip the next checks
	// If present update the add-on values for the next category to directly use
	cm, err := hc.checkForAddOnCM()
	if err != nil {
		return &SkipError{err.Error()}
	}

	// linkerd-config-addons cm is present,now update hc to include those add-ons
	// so that further add-on specific checks can be ran
	var values l5dcharts.Values
	err = yaml.Unmarshal([]byte(cm), &values)
	if err != nil {
		return &SkipError{fmt.Sprintf("could not unmarshal %s config-map: %s", k8s.AddOnsConfigMapName, err)}
	}

	addOns, err := l5dcharts.ParseAddOnValues(&values)
	if err != nil {
		return &SkipError{fmt.Sprintf("could not read %s config-map: %s", k8s.AddOnsConfigMapName, err)}
	}

	hc.addOns = make(map[string]l5dcharts.AddOn)

	for _, addOn := range addOns {
		hc.addOns[addOn.Name()] = addOn
	}

	return nil
}

func (hc *HealthChecker) checkForAddOnCM() (string, error) {
	cm, err := k8s.GetAddOnsConfigMap(hc.kubeAPI, hc.ControlPlaneNamespace)
	if err != nil {
		return "", err
	}

	return cm["values"], nil
}
