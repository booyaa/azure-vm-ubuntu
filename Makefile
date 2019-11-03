.PHONY: init
init:
	terraform init

.PHONY: plan
plan:
	terraform plan -var-file azure.tfvars -out out.plan

.PHONY: apply
apply:
	terraform apply "out.plan"


.PHONY: check
check:
	terraform validate
	terraform fmt