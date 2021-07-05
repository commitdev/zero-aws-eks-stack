---
title: Repository structure
sidebar_label: Repository Structure
sidebar_position: 3
---

The root folder is used for declaring parameters required by the templates, and [Zero][zero] will gather the required parameters and parse the templates as individual repositories for user to maintain.
```shell
/   # file in the root directory is for initializing the user's repo and declaring metadata
|-- Makefile                        #make command triggers the initialization of repository
|-- zero-module.yml                 #module declares required parameters and credentials
|
|   # files in templates become the repo for users
|   templates/
|   |   # this makefile is used both during init and
|   |   # on-going needs/utilities for user to maintain their infrastructure
|   |-- Makefile
|   |-- terraform/
|   |   |-- bootstrap/              #initial setup
|   |   |-- environments/           #infrastructure setup
|   |   |   |-- prod/
|   |   |   |-- stage/
|   |-- kubernetes
|   |   |-- terraform
|   |   |   |-- environments        #k8s-ultities
|   |   |   |   |-- prod/
|   |   |   |   |-- stage/
```