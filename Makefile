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

.PHONY: destroy
destroy:
	terraform destroy -var-file azure.tfvars

PHONY: ssh
ssh: 
	ssh $(shell terraform output ssh_connect)
