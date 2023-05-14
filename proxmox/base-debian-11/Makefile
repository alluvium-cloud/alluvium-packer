.PHONY: apply applydiff all

all: build

build:
	packer build -force -on-error=ask -var-file base.auto.pkrvars.hcl .

