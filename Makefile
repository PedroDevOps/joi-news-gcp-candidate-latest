BUILD_DIR=build
APPS=front-end quotes newsfeed
LIBS=common-utils
STATIC_BASE=front-end/public
STATIC_PATHS=css
STATIC_ARCHIVE=$(BUILD_DIR)/static.tgz
INSTALL_TARGETS=$(addsuffix .install, $(LIBS))
APP_JARS=$(addprefix $(BUILD_DIR)/, $(addsuffix .jar, $(APPS)))
DOCKER_TARGETS=$(addsuffix .docker, $(APPS))
DOCKER_PUSH_TARGETS=$(addsuffix .push, $(APPS))
_DOCKER_PUSH_TARGETS=$(addprefix _, $(DOCKER_PUSH_TARGETS))
GCR_URL=gcr.io

default: deploy_interview

_all: $(BUILD_DIR) $(APP_JARS) $(STATIC_ARCHIVE)

_libs: $(addprefix _, $(INSTALL_TARGETS))

static: $(STATIC_ARCHIVE)

_%.install:
	cd $* && lein install

_test: $(addprefix _, $(addsuffix .test, $(LIBS) $(APPS)))

test:
	dojo "make _test"

_%.test:
	cd $* && lein midje

login-gcloud:
	echo "Logging into GCP using interviewee credentials."
	gcloud auth activate-service-account --key-file=infra/.interviewee-creds.json

_apps:
	$(MAKE) _libs _all

apps:
	dojo "make _apps"

clean:
	rm -rf $(BUILD_DIR) $(addsuffix /target, $(APPS)) $(addsuffix /target, $(LIBS))

$(APP_JARS): | $(BUILD_DIR)
	cd $(notdir $(@:.jar=)) && lein uberjar && cp target/uberjar/*-standalone.jar ../$@

$(STATIC_ARCHIVE): | $(BUILD_DIR)
	tar -c -C $(STATIC_BASE) -z -f $(STATIC_ARCHIVE) $(STATIC_PATHS)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

%.docker:
	$(eval IMAGE_NAME = $(subst -,_,$*))
	cp $(BUILD_DIR)/$*.jar docker/$*
	cd docker/$* && docker buildx build --platform linux/amd64 -t $(IMAGE_NAME) .

%.push:
	# gcloud auth activate-service-account --key-file infra/.interviewee-creds.json
	$$(gcloud auth configure-docker gcr.io --quiet)
	$(eval IMAGE_NAME = $(subst -,_,$*))
	docker tag $(IMAGE_NAME) $(GCR_URL)/$$(cat .projectid.txt)/$(IMAGE_NAME)
	docker push $(GCR_URL)/$$(cat .projectid.txt)/$(IMAGE_NAME)

docker: $(DOCKER_TARGETS)

_push: $(_DOCKER_PUSH_TARGETS)
push: $(DOCKER_PUSH_TARGETS)

_%.infra:
	@if [ ! -f .projectid.txt ]; then >&2 echo "No .projectid.txt found, ask your interviewer for a GCP projectId that you can put into this file" && exit 127; fi
	@if [ ! -f infra/.interviewee-creds.json ]; then >&2 echo "No infra/.interviewee-creds.json found" && exit 127; fi

	echo "Project id is $$(cat .projectid.txt)"
	export TF_VAR_project="$$(cat .projectid.txt)" \
		&& cd infra/$* \
		&& rm -rf .terraform \
		&& terraform init -backend-config="bucket=$${TF_VAR_project}-infra-backend" \
		&& terraform apply -auto-approve

%.infra:
	dojo "make _$*.infra"

_%.deinfra:
	export TF_VAR_project="$$(cat .projectid.txt)" \
		&& cd infra/$* \
		&& rm -rf .terraform \
		&& terraform init -backend-config="bucket=$${TF_VAR_project}-infra-backend" \
		&& terraform destroy -auto-approve

%.deinfra:
	dojo "make _$*.deinfra"

_deploy_site:
	gcloud auth activate-service-account --key-file infra/.interviewee-creds.json
	mkdir -p build/static
	cd build/static && \
		tar xf ../static.tgz && \
		gsutil rsync -R . gs://$(shell cat .projectid.txt)-infra-static-pages/

deploy_site:
	dojo "make _deploy_site"

news.infra:

deploy_interview:
	$(MAKE) base.infra
	$(MAKE) apps
	$(MAKE) docker # builds all images
	$(MAKE) push
	$(MAKE) news.infra
	$(MAKE) deploy_site

destroy_interview:
	$(MAKE) news.deinfra
	$(MAKE) base.deinfra
