
run:
	cd $(PROJECT_DIR) && AUTO_APPROVE="-auto-approve" make

summary:
	@echo "zero-aws-eks-stack:"
	@echo "- Repository URL: ${REPOSITORY}"
	@echo "- To see your kubernetes clusters, run: 'kubectl config get-contexts'"
	@echo "- To switch to a cluster, use the following commands:"
	@echo $(shell echo ${ENVIRONMENT} | grep production > /dev/null && echo "- for production use: kubectl config use-context $(shell kubectl config get-contexts -o name | grep ${NAME}-production)")
	@echo $(shell echo ${ENVIRONMENT} | grep staging > /dev/null && echo "- for staging use: kubectl config use-context $(shell kubectl config get-contexts -o name | grep ${NAME}-staging)")
	@echo "- To inspect the selected cluster, run 'kubectl get node,service,deployment,pods'"
