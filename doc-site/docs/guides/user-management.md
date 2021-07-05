---
title: Managing Users
sidebar_label: Managing Users
sidebar_position: 3
---


## Granting User Access to team members

You may want to give members of your team access to the infrastructure.
Individual roles and permissions are defined in `environments/<env>/user_access.tf`, these will define the amount of access a user in that role has to both AWS and Kubernetes.

 1. Add users in `environments/shared/main.tf` and specify the role they should have in each environment, then run:
```
make apply-shared-env
```

 2. To do the assignment of users to roles in each environment, you must run this for each:
```
ENVIRONENT=<env> make apply-env
```
This should detect that there was a new user created, and put them into the necessary group.

 3. To create dev environment for developers, run:
```
scripts/create-dev-env.sh
```
This should detect new users under developer group, and create dev database for each.

 4. To create initial temporary password for users, you may run:
```
script/create-temporary-passwords.sh
```
You will get a list with username, termporary password and roles that the user is assigned to. Then, you can pass to the corresponding users.

 5. New users can check and setup local configurations for resoruce access by running:
```
script/setup-local-config.sh <user name> <role> <environment (stage/prod)>
```

 6. New users can check and setup local configurations for resoruce access by running:
```
script/setup-local-config.sh <user name> <role> <environment (stage/prod)>
```
