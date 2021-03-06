VAGRANT_DEFAULT_PROVIDER=virtualbox
export ANSIBLE_SSH_ARGS='-o ControlMaster=no'
default: all


.PHONY: help
help:
	@Echo "General tasks:"
	@echo "make  (all)   -builds dev target nolio windows virtual machines"
	@echo "               all: clean setup install deploy "
	@echo "make test    -test dev target nolio windows virtual machines "
	@echo "-------------------------------------------------------------"
	@echo "make clean   -Cleanup vm's and  ansible roles"
	@echo "make setup   -Setup ansible roles and python packages "
	@echo "make install -Install the virtual machines only"
	@echo "make build   -Build the application game of life"
	@echo "make deploy  -Deploy the application game of life to target"

.PHONY: setup
setup:
	@echo Installing galaxy roles
	chmod 644 ansible.ini
	ansible-playbook -vv -i ansible.ini -l local install.yml
	@echo Installing python extensions
	pip install --upgrade -r requirements.txt


.PHONY: install
install: setup
	@Echo Install Ansible galaxy roles and dependant python packages.
	@Echo Bring up 2 virtual machines:** 'dev' the CI server, and 'target' the Tomcat server
	vagrant up --no-provision
	@Echo **Run the provisioner**
	ansible-playbook -l dev:target provision.yml
	@Echo **Install Docker on target too**
	ansible-playbook -l target playbook.yml
	@Echo **Bring up the windows 7 VM, and provision it:**
# Bring nolio down, with 8G windows box will be  set otherwise in guruMeditation mode if memory runs out ..
	vagrant halt nolio
	vagrant up --no-provision windows
	ansible-playbook -l windows provision.yml

.PHONY: build
build:
	@Echo Triggers build jobs Jenkins on [dev].
	ansible-playbook -vv -i ansible.ini -l dev build.yml

.PHONY: clean
clean: destroy
	rm -rf roles/bbaassssiiee.commoncentos/
	rm -rf roles/bbaassssiiee.artifactory/
	rm -rf roles/bbaassssiiee.sonar/
	rm -rf roles/ansible-ant/
	rm -rf roles/ansible-eclipse/
	rm -rf roles/ansible-maven/
	rm -rf roles/ansible-oasis-maven/
	rm -rf roles/geerlingguy.java/
	rm -rf roles/hudecof.tomcat/
	rm -rf roles/hullufred.nexus/
	rm -rf roles/pcextreme.mariadb/
	rm -rf roles/briancoca.oracle_java7

.PHONY: destroy
destroy:
	@Echo Destroys virtual images
	vagrant destroy -f dev
	vagrant destroy -f nolio
	vagrant destroy -f target
	vagrant destroy -f windows
	
	

.PHONY: deploy
deploy:
	ansible-playbook -vv -i ansible.ini -l target deploy.yml



.PHONY: smoketest
smoketest:
	ansible-playbook -vv -i ansible.ini -l dev:target smoketest.yml
.PHONY: webtest
webtest:
	ansible-playbook -vv -i ansible.ini -l target webtest.yml
.PHONY: test
test: smoketest webtest


.PHONY: all
all: clean setup install deploy



dev.box:
	vagrant halt dev
	vagrant package --base dev --output boxes/dev.box

boxes/target.box:
	vagrant halt target
	vagrant package --base target --output boxes/target.box
boxes/test.box:
	vagrant halt test
	vagrant package --base test --output boxes/test.box
boxes/windows.box:
	vagrant halt windows
	vagrant package --base windows --output boxes/windows.box

.PHONY: boxes
boxes: boxes/dev.box boxes/target.box boxes/test.box boxes/windows.box

import:
	vagrant box add -f -name dockpack/centos6 boxes/target.box
	vagrant box add -f -name ubuntu14 boxes/test.box
	vagrant box add -f -name chef/centos-6.6 boxes/dev.box



