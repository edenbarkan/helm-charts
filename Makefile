.PHONY: help lint template-dev template-staging template-prod

help: ## Show available commands
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

lint: ## Lint Helm chart for all environments
	helm lint charts/generic-app -f apps/myapp/base/values.yaml -f apps/myapp/overlays/dev/values.yaml
	helm lint charts/generic-app -f apps/myapp/base/values.yaml -f apps/myapp/overlays/staging/values.yaml
	helm lint charts/generic-app -f apps/myapp/base/values.yaml -f apps/myapp/overlays/production/values.yaml
	@echo "All environments pass linting"

template-dev: ## Render dev Helm templates
	helm template myapp charts/generic-app -f apps/myapp/base/values.yaml -f apps/myapp/overlays/dev/values.yaml

template-staging: ## Render staging Helm templates
	helm template myapp charts/generic-app -f apps/myapp/base/values.yaml -f apps/myapp/overlays/staging/values.yaml

template-prod: ## Render production Helm templates
	helm template myapp charts/generic-app -f apps/myapp/base/values.yaml -f apps/myapp/overlays/production/values.yaml
