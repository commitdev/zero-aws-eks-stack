---
title: Developer Experience with Telepresence
sidebar_label: Dev Experience - Telepresence
sidebar_position: 6
---

### Dev Environment
This project is set up with a local/cloud hybrid dev environment. This means you can do fast local development of a single service, even if that service depends on other resources in your cluster.
Make a change to your service, run it, and you can immediately see the new service in action in a real environment. You can also use any tools like your local IDE, debugger, etc. to test/debug/edit/run your service.

Usually when developing you would run the service locally with a local database and any other dependencies running either locally or in containers using `docker-compose`, `minikube`, etc.
Now your service will have access to any dependencies within a namespace running in the EKS cluster, with access to resources there.
[Telepresence](https://telepresence.io) is used to provide this functionality.

 Development workflow:

  1. Run `start-dev-env.sh` - You will be dropped into a shell that is the same as your local machine, but works as if it were running inside a pod in your k8s cluster
  2. Change code and run the server - As you run your local server, using local code, it will have access to remote dependencies, and will be sent traffic by the load balancer
  3. Test on your cloud environment with real dependencies - `https://<your name>-<backend-domain>`
  4. git commit & auto-deploy to Staging through the build pipeline