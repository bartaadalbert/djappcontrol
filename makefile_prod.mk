APP_NAME := ipinfo
APP_MODE := prod
START_APP_NAME := control
REMOTE_USER := root
REMOTE_HOST := jsonsmile.com
SSH_PORT := 22
TIMEOUT := 5
APP_DOCKERFILE := ${DOCKER_FILE_DIR}/prod.Dockerfile
NGINX_DOCKERFILE := ${DOCKER_FILE_DIR}/nginx/
NGINX_DOCKERFILE_NAME := ${DOCKER_FILE_DIR}/nginx/Dockerfile
APP_COMPOSEFILE := prod.docker-compose.yml
DOCKER_APP_ENV := ${DOCKER_FILE_DIR}/.env.prod
DOCKER_DB_ENV := ${DOCKER_FILE_DIR}/.env.prod.db
DOCKER_CONTEXT := jsm_root
CONTEXT_DESCRIPTION := production
CONTEXT_HOST := host=ssh://root@jsonsmile.com
FINAL_PORT := 4004
PORT_APP := 127.0.0.1:$(FINAL_PORT):8000
FINAL_PORT_STAGING := 8001
PORT_APP_STAGING := 127.0.0.1:$(FINAL_PORT_STAGING):$(FINAL_PORT_STAGING)
PORT_NGINX_FINAL := 4444
PORT_NGINX := 127.0.0.1:$(PORT_NGINX_FINAL):80
PORT_REDIS_FINAL := 6379
PORT_REDIS := 127.0.0.1:$(PORT_REDIS_FINAL):6379
PORT_PSQ_FINAL := 5432
PORT_PSQ := 127.0.0.1:$(PORT_PSQ_FINAL):5432
PORT_MEMCACHE := 127.0.0.1:21212:11211
DOMAIN := $(REMOTE_HOST)
SUBDOMAIN := $(APP_NAME).$(DOMAIN)
SUBDOMAIN_CSRF := "https:\/\/$(APP_NAME).$(DOMAIN)"
SUBDOMAIN_NAME := $(APP_NAME)
SOCKET_NAME := dockerProd-tunnel-socket
REGISTRY_PORT := 5000
SSH_KEY_NAME := DO_$(APP_NAME)_SSH_Key
SSH_KEY_COMMENT := admin@$(DOMAIN)
SSH_KEY_FILE := $(DEFF_MAKER)digitalocean/id_rsa
SSH_GIT_KEY_FILE := $(DEFF_MAKER)git/id_rsa
BRANCH := main
REPO_NAME := $(APP_NAME)
RSYNC_DESTINATION_DIR := /home/rsync_django/$(BRANCH)/$(REPO_NAME)
GUNICORN_COMMAND := "gunicorn --bind 0.0.0.0:8000 --workers 2 --threads 2 --worker-tmp-dir /dev/shm $(APP_NAME).wsgi:application"
GUNICORN_COMMAND_STAGING := "gunicorn --bind 0.0.0.0:$(FINAL_PORT_STAGING) --workers 2 --threads 2 --worker-tmp-dir /dev/shm $(APP_NAME).wsgi:application"