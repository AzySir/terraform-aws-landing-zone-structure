ORG:=myorg

init: validate-aws clean
ifdef REGION
	terraform -chdir=domain/$(DOMAIN) init \
	-backend-config=bucket=$(ORG)-tf-state \
	-backend-config=key="$(DOMAIN)/$(REGION)/terraform.tfstate" \
	$(ARGS)
else
	terraform -chdir=domain/$(DOMAIN) init \
	-backend-config=bucket=$(ORG)-tf-state \
	-backend-config=key="$(DOMAIN)/terraform.tfstate" \
	$(ARGS)
endif


plan: validate-aws fmt
ifdef REGION
	terraform -chdir=domain/$(DOMAIN)/$(REGION) plan \
	$(ARGS)
else
	terraform -chdir=domain/$(DOMAIN) plan \
	$(ARGS)
endif

apply: validate-aws validate-region fmt
ifdef REGION
	terraform -chdir=domain/$(DOMAIN)/$(REGION) apply \
	-var-file=$(REGION).tfvars \
	$(ARGS)
else
	terraform -chdir=domain/$(DOMAIN) apply \
	$(ARGS)
endif

destroy: validate-aws  fmt
	terraform -chdir=domain/$(DOMAIN) destroy  \
	$(ARGS)

console: validate-aws fmt
	terraform -chdir=domain/$(DOMAIN) console 

clean:
ifdef REGION
	rm -rf domain/$(DOMAIN)/$(REGION)/.terraform*
else
	rm -rf domain/$(DOMAIN)/.terraform*
endif

fmt:
	terraform fmt -recursive

rm:
	terraform -chdir=domain/$(DOMAIN) state rm $(ARGS)

import:
	terraform -chdir=domain/$(DOMAIN) import $(ARGS)

list:
	terraform -chdir=domain/$(DOMAIN) state list

show:
	terraform -chdir=domain/$(DOMAIN) state show $(ARGS)
	

validate-env:
ifndef ENV
	$(error Please provide a Environment Name i.e make plan ENV="dev")
endif

validate-aws:
ifndef AWS_SECRET_ACCESS_KEY
	$(error Please authenticate to AWS i.e AWS_SECRET_ACCESS_KEY="<secret key here>")
endif
ifndef AWS_ACCESS_KEY_ID
	$(error Please authenticate to AWS i.e AWS_ACCESS_KEY_ID="<access key here>")
endif

validate-region:
ifndef REGION
	$(error Please ensure to have REGION included i.e make apply REGION=eu-west-2")
endif