#FILES PATH
TMPDIR = "/tmp"
CUR_DIR = $(shell echo "${PWD}")
DOCKER_FILE_DIR := "dockerfiles"
YELLOW = '\033[1;33m' 
RED = '\033[0;31m'
GREEN = '\033[0;32m' 
BLUE = '\033[0;34m'

#GET ADD VERSION
FILE := version.txt
VARIABLE := $(shell cat ${FILE})
DEFVERSION:= 1.0.0
VERSION := $(if $(VARIABLE),$(VARIABLE),$(DEFVERSION))
SCRIPT_VERSION:= "./version.sh"
SCRIPT_GDD := "./gdd.sh"
SCRIPT_NGINX := "./nginxgenerator.sh"
SCRIPT_PM2 := "./pm2creator.sh"
SCRIPT_GIT := "./gitrepo.sh"
SCRIPT_DJ_SETTINGS := ./djsettings.sh
SCRIPT_DJ_URLS := "./djurls.sh"
SCRIPT_DJ_INSTALLED_APPS := ./djapp.sh
ARGUMENT:= feature #can use major/feature/bug
NEWVERSION:=$(shell $(SCRIPT_VERSION) $(VERSION) $(ARGUMENT))
MESSAGE := app created, DEFAULT message
REMOTE_USER := root

#DEVELOP OR PRODUCT
DEV_MODE ?= 1
ifeq ($(DEV_MODE),1)
APP_NAME := djappcontrol
START_APP_NAME := devcontrol
REMOTE_HOST := jsonsmile.com## OR other IP hostname ....
DOCKERFILE := "${DOCKER_FILE_DIR}/dev.Dockerfile"
COMPOSEFILE := "${DOCKER_FILE_DIR}/dev.docker-compose.yml"
DOCKER_APP_ENV := "${DOCKER_FILE_DIR}/.env.dev"
DOCKER_CONTEXT := jsm_adalbert
CONTEXT_DESCRIPTION := develop
CONTEXT_HOST := host=ssh://adalbert@jsonsmile.com
FINAL_PORT := 8008
PORT_APP := 127.0.0.1:$(FINAL_PORT):8000
PORT_NGINX := 127.0.0.1:8888:80 
PORT_REDIS := 127.0.0.1:7379:6379
PORT_PSQ := 127.0.0.1:6543:5432
PORT_MEMCACHE := 127.0.0.1:22322:11211
DOMAIN := $(REMOTE_HOST)
else
APP_NAME := ipinfo
START_APP_NAME := control
REMOTE_HOST := jsonsmile.com
DOCKERFILE := "${DOCKER_FILE_DIR}/prod.Dockerfile"
COMPOSEFILE := "${DOCKER_FILE_DIR}/prod.docker-compose.yml"
DOCKER_APP_ENV := "${DOCKER_FILE_DIR}/.env.prod"
DOCKER_CONTEXT := jsm_root
CONTEXT_DESCRIPTION := production
CONTEXT_HOST := host=ssh://root@jsonsmile.com
FINAL_PORT := 4004
PORT_APP := 127.0.0.1:$(FINAL_PORT):8000
PORT_NGINX := 127.0.0.1:4444:80 
PORT_REDIS := 127.0.0.1:6379:6379
PORT_PSQ := 127.0.0.1:5432:5432
PORT_MEMCACHE := 127.0.0.1:21212:11211
DOMAIN := $(REMOTE_HOST)
endif

IMAGE_NAME := ${APP_NAME}
VENV := venv_$(APP_NAME)
GITSSH := git@github.com:bartaadalbert/$(APP_NAME).git
BRANCH := main
NGINX_CONF := $(APP_NAME).$(DOMAIN).conf
SUBDOMAIN := $(APP_NAME).$(DOMAIN)
SSH_SERVER := $(REMOTE_USER)@$(REMOTE_HOST)
PROXY_PASS := http:\/\/127.0.0.1:$(FINAL_PORT)
PM2_CONFIG := $(APP_NAME).config.js
APP_START := $(APP_NAME)/$(START_APP_NAME)

define my_func
    $(eval $@_PROTOCOL = "https:"")
    $(eval $@_HOSTNAME = $(1))
    $(eval $@_PORT = $(2))
    echo "${$@_PROTOCOL}//${$@_HOSTNAME}:${$@_PORT}/"
endef


.PHONY: help

help: ## This help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help

# my-target:
#     @$(call my_func,"example.com",8000)

preconfig: ## Add all needed files
	
.gitignore: ## Create gitignore dinamic
	@cp gitignorestatic .gitignore

create_repo: ## Cretae github repository private whitout template
	$(shell $(SCRIPT_GIT) $(APP_NAME))
	@echo The repo was created with $(APP_NAME) name

delete_repo: ## DELETE teh repo in github with user and name setted before
	$(shell $(SCRIPT_GIT) $(APP_NAME) "DELETE")
	@echo The repo was deleted with $(APP_NAME) name

create_ssl: ## Create ssl with certbot for our nginx conf in our server
	@scp $(NGINX_CONF) $(SSH_SERVER)":/etc/nginx/sites-available/"
	@ssh $(SSH_SERVER) "apt install nginx"
	@ssh $(SSH_SERVER) "rm -f /etc/nginx/sites-enabled/$(NGINX_CONF)"
	@ssh $(SSH_SERVER) "ln -s /etc/nginx/sites-available/$(NGINX_CONF) /etc/nginx/sites-enabled/$(NGINX_CONF)"
	@ssh $(SSH_SERVER) "systemctl restart nginx"
	@ssh $(SSH_SERVER) "certbot --nginx -d $(SUBDOMAIN)"
	@ssh $(SSH_SERVER) "certbot renew --dry-run"

delete_ssl: ## This will delete our ssl configs with nginx config
	@ssh $(SSH_SERVER) "rm -f /etc/nginx/sites-available/$(NGINX_CONF)"
	@ssh $(SSH_SERVER) "rm -f /etc/nginx/sites-enabled/$(NGINX_CONF)"
	@ssh $(SSH_SERVER) "rm -f /etc/letsencrypt/live/$(SUBDOMAIN)"
	@ssh $(SSH_SERVER) "systemctl restart nginx"

create_nginx: ## Create an nginx config with proxypass and servername
	$(shell $(SCRIPT_NGINX) $(SUBDOMAIN) "$(PROXY_PASS)")
	@echo The nginx conf $(NGINX_CONF) was created successfully

delete_nginx: ## Delete nginx config with conf name
	@rm -f $(NGINX_CONF)
	@echo The nginx config $(NGINX_CONF) was deleted

create_subdomain: ## This will create a subdomain nam=app_name in our main domain
	$(shell $(SCRIPT_GDD) $(DOMAIN) $(APP_NAME))
	@echo "subdomain was created $(APP_NAME).$(REMOTE_HOST)"

delete_subdomain: ## Delete the subdomain with this app_name
	$(shell $(SCRIPT_GDD) $(DOMAIN) $(APP_NAME) "DELETE")
	@echo "subdomain was deleted $(APP_NAME) on $(DOMAIN)"

context: ##Get available docker context s
	@docker context ls

images: ## Get all docker images
	@docker images

ps: ## Get all runing docker containers
	@docker ps -a 

change_context: context ## Change the docker context to other server
	@docker context use $(DOCKER_CONTEXT)

create_context: ## Create new server docker context
	@docker context create $(DOCKER_CONTEXT) --description $(CONTEXT_DESCRIPTION) --docker $(CONTEXT_HOST)

delete_context: ## Delete the context
	@docker context rm $(DOCKER_CONTEXT)

add_installed_apps: ## Add in django settings installed apps new app
	$(shell $(SCRIPT_DJ_INSTALLED_APPS) $(APP_NAME) $(START_APP_NAME))
	@echo The app was added to installed app with name $(START_APP_NAME)

create_venv: ## Create venv with Django startproject, and delete venv if exist
	@rm -rf $(VENV)
	@python3 -m venv $(VENV)
	@source $(VENV)/bin/activate && python3 -m pip install --upgrade pip && pip install --upgrade -r requirements.txt
	@if [[ ! -d $(APP_NAME) ]]; then\
		cp gitignorestatic .gitignore;\
		echo "$(APP_NAME)/$(APP_NAME)/__pycache__" >> .gitignore;\
		echo "$(APP_NAME)/$(START_APP_NAME)/__pycache__" >> .gitignore;\
		echo "$(APP_NAME)/$(APP_NAME)/settings.py" >> .gitignore;\
		echo "$(APP_NAME)/.env*" >> .gitignore;\
		source $(VENV)/bin/activate && django-admin startproject $(APP_NAME) && cd $(APP_NAME) && python3 manage.py startapp $(START_APP_NAME);\
		echo "The app folder $(APP_NAME) created with startapp $(START_APP_NAME) successfully";\
	else\
		echo "The app folder $(APP_NAME) exist, nothing to do";\
	fi
	@sleep 5
	@if [[ -d $(APP_NAME)/$(START_APP_NAME) ]]; then\
		$(SCRIPT_DJ_SETTINGS) $(APP_NAME);\
		$(SCRIPT_DJ_URLS) $(APP_NAME) $(START_APP_NAME);\
		echo "The django settings was changed with $(APP_NAME)";\
		make add_installed_apps $(APP_NAME) $(START_APP_NAME);\
	fi
delete_app: ## THIS will remove our startproject with all data
	@rm -rf $(APP_NAME)
	@rm -rf $(VENV)
	@echo "the app $(APP_NAME) was deleted and also the venv $(VENV)"

git_init: ## ADD ssh pub key to git, this will be simple for the future using, and create an app in github
	@if [ -z $(APP_NAME) ]; then\
		echo "The app name not configured";\
		exit 1;\
	fi

	@if [ -z $(GITSSH) ]; then\
		echo "The git ssh repo not configured";\
		exit 1;\
	fi

	- @make create_repo
	@git init
	@git add .
	@git commit -m "$(VERSION)"
	@git remote add origin $(GITSSH)
	@git branch -M $(BRANCH)	
	@git push -u origin $(BRANCH)

git_push: ##Git add . and commit and push to branch, add tag
	@git add .
	@git commit -m "$(MESSAGE) with version $(VERSION)"
	@git push -u origin $(BRANCH)

save_version: check_version ## Save a new version with increment param ARGUMENT=[1.0.0:major/feature/bug]
	$(shell echo $(NEWVERSION) > $(FILE))
	@echo new version: $(NEWVERSION)

check_version: ## Get the actual version
	@echo current version: $(VERSION)

reset_version: clean_version ## This will generate new file with DEFVERSION or any VERSION
	$(shell echo $(DEFVERSION) > $(FILE))
	@echo reset version: $(DEFVERSION)

clean_version: ## This will delete our version file, will set version to DEFVERSION 1.0.0 or what you give
	$(shell rm $(FILE))
	@echo the version file was deleted from app directory

tag: ## This will tag our git vith the version 
	@git checkout integration
	@echo $(VERSION)
	@git tag $(VERSION)
	@git push --tags

create_pm2: ## Add pm2 config js to app folder
	@if [[ ! -d $(APP_NAME) ]]; then\
		echo "Cant add pm2 config if APP not created before";\
		exit 0;\
	fi
	$(shell $(SCRIPT_PM2) $(APP_NAME) "$(FINAL_PORT)")
	@cp $(CUR_DIR)/$(PM2_CONFIG) $(APP_NAME)
	@echo The config js was created and copied to APP folder

bash_executable: ## Make all .sh file executable for our app
	@sudo chmod u+x *.sh
	@echo the bash files was made executable

activate: ##Activate the venv
	source $(VENV)/bin/activate

check:
	$(echo -e "$(MESSAGE)")
	@git init
	

build: ## Build the docker image
	@echo $(CUR_DIR)
	@echo $(THIS_MAKEFILE)
	

