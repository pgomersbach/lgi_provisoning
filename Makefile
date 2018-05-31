PACKER := $(shell packer --version 2>/dev/null)
TERRAFORM := $(shell terraform --version 2>/dev/null)

check:
ifdef PACKER
	@echo "Found packer version $(PACKER)"
else
	@echo "Packer Not found in path"
	@exit 1
endif
ifdef TERRAFORM
	@echo "Found terraform version $(TERRAFORM)"
else
	@echo "Terraform Not found in path"
	@exit 1
endif
ifndef AWS_ACCESS_KEY_ID
	@echo "AWS_ACCESS_KEY_ID not defined"
	@exit 1
endif
ifndef AWS_SECRET_ACCESS_KEY
	@echo "AWS_SECRET_ACCESS_KEY not defined"
	@exit 1
endif
	@packer validate packer.json
	@ansible-playbook -i 'localhost,' ansible-playbook.yml --syntax-check
	@TF_VAR_access_key="${AWS_ACCESS_KEY_ID}"  TF_VAR_secret_key="${AWS_SECRET_ACCESS_KEY}" terraform validate

ami:
	@packer validate packer.json
	packer build packer.json

tf_plan:
	@TF_VAR_access_key="${AWS_ACCESS_KEY_ID}"  TF_VAR_secret_key="${AWS_SECRET_ACCESS_KEY}" terraform validate
	@TF_VAR_access_key="${AWS_ACCESS_KEY_ID}"  TF_VAR_secret_key="${AWS_SECRET_ACCESS_KEY}" terraform plan

tf_apply:
	@TF_VAR_access_key="${AWS_ACCESS_KEY_ID}"  TF_VAR_secret_key="${AWS_SECRET_ACCESS_KEY}" terraform validate
	@TF_VAR_access_key="${AWS_ACCESS_KEY_ID}"  TF_VAR_secret_key="${AWS_SECRET_ACCESS_KEY}" terraform apply

tf_destroy:
        @TF_VAR_access_key="${AWS_ACCESS_KEY_ID}"  TF_VAR_secret_key="${AWS_SECRET_ACCESS_KEY}" terraform destroy

