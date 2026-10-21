# Usage:
#   make deploy              → full stack (same as make deploy-all)
#   make deploy infra        → postgres, redis, rabbitmq, nginx (--no-deps), host nginx
#   make deploy frontend|backend|cms|all
# Also: make deploy-infra, make deploy-frontend, …

.PHONY: deploy deploy-all deploy-infra deploy-frontend deploy-backend deploy-cms
.PHONY: infra frontend backend cms all

DEPLOY_SH := sh scripts/deploy.sh

# Stub goals so `make deploy <name>` does not fail with "No rule to make target"
infra frontend backend cms all:
	@:

deploy:
	@case "$(word 2,$(MAKECMDGOALS))" in \
	  infra)    $(DEPLOY_SH) infra ;; \
	  frontend) $(DEPLOY_SH) frontend ;; \
	  backend)  $(DEPLOY_SH) backend ;; \
	  cms)      $(DEPLOY_SH) cms ;; \
	  all)      $(DEPLOY_SH) all ;; \
	  '')       $(DEPLOY_SH) all ;; \
	  *)        echo "unknown deploy target: $(word 2,$(MAKECMDGOALS))" >&2; \
	            echo "usage: make deploy [infra|frontend|backend|cms|all]" >&2; exit 1 ;; \
	esac

deploy-all:
	$(DEPLOY_SH) all

deploy-infra:
	$(DEPLOY_SH) infra

deploy-frontend:
	$(DEPLOY_SH) frontend

deploy-backend:
	$(DEPLOY_SH) backend

deploy-cms:
	$(DEPLOY_SH) cms
