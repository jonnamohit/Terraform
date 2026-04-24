.PHONY: help init plan apply destroy rebuild clean validate fmt

ENVIRONMENT := dev
TF_PATH := env/$(ENVIRONMENT)

help:
	@echo "Terraform Pipeline Commands"
	@echo "============================"
	@echo "make init        - Initialize terraform"
	@echo "make plan        - Show what will be created/changed"
	@echo "make apply       - Apply terraform configuration"
	@echo "make destroy     - Destroy all infrastructure"
	@echo "make rebuild     - Destroy everything and rebuild fresh"
	@echo "make clean       - Clean terraform cache"
	@echo "make validate    - Validate terraform configuration"
	@echo "make fmt         - Format terraform files"
	@echo ""

init:
	@cd $(TF_PATH) && terraform init

plan:
	@cd $(TF_PATH) && terraform plan

apply:
	@cd $(TF_PATH) && terraform apply -auto-approve

destroy:
	@echo "⚠️  WARNING: This will destroy all infrastructure!"
	@read -p "Are you sure? (yes/no): " confirm; \
	if [ "$$confirm" = "yes" ]; then \
		cd $(TF_PATH) && terraform destroy -auto-approve; \
	else \
		echo "Cancelled."; \
	fi

rebuild: destroy clean init apply
	@echo "✅ Pipeline rebuilt successfully!"

clean:
	@cd $(TF_PATH) && rm -rf .terraform .terraform.lock.hcl

validate:
	@cd $(TF_PATH) && terraform validate

fmt:
	@cd $(TF_PATH) && terraform fmt -recursive ../../modules

output:
	@cd $(TF_PATH) && terraform output
