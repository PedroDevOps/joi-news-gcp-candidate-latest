# Development and operations tools manual setup

You need all the tools below installed locally:

### Prerequisites to build the Java applications

 * make
 * Java
 * [Leiningen](http://leiningen.org/) (can be installed using `brew install leiningen`)

### Prerequisites for running infrastructure code

 * make
 * docker daemon
 * terraform
 * ssh-keygen
 * gcloud cli

# Infrastructure setup

This is a multi-step guide to setup some base infrastructure, and then, on top of it, the test environment for the newsfeed application.

## Base infrastructure setup

With an assumption that we have a new, empty GCP account, we need to provision some base infrastructure just one time.
These steps will provision:
 * terraform backend in GCS bucket
 * a minimal VPC with 1 subnet
 * GCR repositories for docker images

## Build the application artifacts

If you haven't built the jars and static resources yet, you should do so now:
```sh
make _apps
```

## Build docker images

Artifacts from previous stage will be packaged into docker images, then pushed to ECR.

Each application has its own image. Individual image can be built with:
```sh
make <app-name>.docker
# for example:
make front-end.docker
```

But you can build all images at once with
```sh
make docker
```

## Push docker images

Before applications can be deployed on GCP, the docker images have to be pushed:
```sh
make _push
```

## Provision services

Then, we can provision the backend and front-end services:
```sh
make _news.infra
```

Terraform will print the output with URL of the front_end server, e.g.
```
Outputs:

frontend_url = http://34.244.219.156:8080
```

## Delete services

To delete the deployment provisioned by terraform, run following commands:
```sh
make _news.deinfra
```
