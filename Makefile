.PHONY: deploy deploy-frontend deploy-backend deploy-infra deploy-cms deploy-all

deploy-all:
	sh scripts/deploy.sh all

deploy-infra:
	sh scripts/deploy.sh infra

deploy-frontend:
	sh scripts/deploy.sh frontend

deploy-backend:
	sh scripts/deploy.sh backend

deploy-cms:
	sh scripts/deploy.sh cms

deploy: deploy-all
