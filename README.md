# Sysdig Shield Onboarding

[Guided Install]
1. run ./install.sh

[Manual Install]
1. run ./helpers/pre-install-validation.sh
2. edit cluster-specific-values.yaml
3. helm upgrade --install --create-namespace -n <UPDATE-NAMESPACE-NAME> -f ./helpers/base-values.yaml -f cluster-specific-values.yaml shield shield-0.10.0.tgz
4. run ./helpers/post-install-validation.sh

