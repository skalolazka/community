---
title: Global Load Balancer with serverless backends in multiple regions
description: ...
author: skalolazka,nplanner,gasparch
tags: Cloud Run, Serverless Connector
date_published: 2022-01-01
---

Natalia Strelkova | Community Editor | Google
<p style="background-color:#CAFACA;"><i>Contributed by Google employees.</i></p>

# Global Load Balancer with serverless backends in multiple regions

This tutorial describes ...

This document is for network administrators, security architects, app developers and cloud operations professionals.

## Architecture using Cloud Run 

The following diagram summarizes the architecture that you create in this tutorial.

![Architecture](./image1.png)

## Objectives

* 1
* 2
* 3

## Costs

This tutorial uses the following billable components of Google Cloud:

* [Cloud Run](https://cloud.google.com/run/pricing)
* [HTTP(S) Load Balancer with Serverless NEGs](https://cloud.google.com/vpc/network-pricing)
...

To generate a cost estimate based on your projected usage, use the [pricing calculator](https://cloud.google.com/products/calculator).

## Prerequisites

...
1. In the Google Cloud Console, on the project selector page, select or create a Google Cloud project. \
**Note**: If you don't plan to keep the resources that you create in this procedure, create a project instead of selecting an existing project. After you finish these steps, you can delete the project, removing all resources associated with the project.
2. [Go to project selector](https://console.cloud.google.com/projectselector2/home/dashboard)
3. Make sure that billing is enabled for your Cloud project. [Learn how to confirm that billing is enabled for your project](https://cloud.google.com/billing/docs/how-to/modify-project).
4. In the Cloud Console, [activate Cloud Shell](https://console.cloud.google.com/?cloudshell=true). \
At the bottom of the Cloud Console, a [Cloud Shell](https://cloud.google.com/shell/docs/features) session starts and displays a command-line prompt. Cloud Shell is a shell environment with the Cloud SDK already installed, including the [gcloud](https://cloud.google.com/sdk/gcloud) command-line tool, and with values already set for your current project. It can take a few seconds for the session to initialize.

This guide assumes that you are familiar with [Terraform](https://cloud.google.com/docs/terraform).

* See [Getting started with Terraform on Google Cloud](https://cloud.google.com/community/tutorials/getting-started-on-gcp-with-terraform) to set up your Terraform environment for Google Cloud.
* The code here has been tested using Terraform version 1.0.2.
* Ensure that you have a [service account](https://cloud.google.com/iam/docs/creating-managing-service-accounts) with sufficient permissions to deploy the resources used in this tutorial.

Enable the following APIs on <strong><code><em>your-gcp-service-project</em></code></strong>

    * API Gateway API
    * Service Control API
    * Service Management API
    * Cloud Run API
???

            gcloud services enable \
            apigateway.googleapis.com  \
            servicecontrol.googleapis.com \
            servicemanagement.googleapis.com \
            run.googleapis.com

## Quickstart

1. Open [Cloud Shell](https://console.cloud.google.com/cloudshell)

2. Clone this repository
```
git clone https://github.com/GoogleCloudPlatform/community.git
```
3. Go to the tutorial code directory:
```
cd community/tutorials/global-lb-with-cloud-run/code
```
4. <i>If you aren't using Cloud Shell</i>, this tutorial uses the default application credentials for Terraform authentication to Google Cloud. Run the following command first to obtain the default credentials for your project:
```
gcloud auth application-default login
```
5. (optional) Create a "terraform.tfvars" file with the variable values for your environment. Example content:
```
project_id = "your-gcp-project"
prefix = "test"
cloud_run_regions = ["europe-west3", "europe-west2"]
```
<i>Main variables used</i>:

- "project_id" - your-gcp-service-project where resources will be deployed
- "prefix" - prefix for resource names
- "cloud_run_regions" - list of regions to deploy Cloud Run to
- "source_ip_range_for_security_policy" - array of Cloud Armor security policy allowed IP ranges, default [] (otherwise, put your IP as an array here e.g. ["10.0.0.0"])

See the variables.tf and modules/serverless_endpoint/variables.tf files for others that have default values.

6. Run Terraform to deploy architecture:
```
terraform init
terraform plan
terraform apply
```
The resources are ready after a few minutes.

7. Check the output of ```terraform apply``` and get the IP address of the created load balancer.

## Destroying created resources
```
>> terraform destroy
```

## Additional reading
* [Additional examples in the terraform-google-examples repository](https://github.com/GoogleCloudPlatform/terraform-google-examples).
* [Learn more about load balancing on Google Cloud](https://cloud.google.com/compute/docs/load-balancing).
* Try out other Google Cloud features for yourself. Have a look at our [tutorials](https://cloud.google.com/docs/tutorials).
