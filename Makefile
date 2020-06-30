
run:
	cd $(PROJECT_DIR) && AUTO_APPROVE="-auto-approve" make

summary:
	@echo "zero-aws-eks-stack:"
	@echo "- Repository URL: ${REPOSITORY}"
	@echo "- To see your kubernetes clusters, run: 'kubectl config get-contexts'"
	@echo "- To switch to a cluster, use the NAME from the previous command in 'kubectl config use-context NAME'"
	@echo "- To inspect the selected cluster, run 'kubectl get node,service,deployment,pods'"

