# Sysdig Shield Onboarding

1. Edit base-values.yaml
2. Run pre-install-validation.sh
3. helm upgrade --install --atomic --create-namespace -n <namespace-name> -f base-values.yaml -f cluster-specific-values.yaml shield shield-0.10.0.tgz
4. run post-install-validation.sh


