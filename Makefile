# Esteira local do laboratório Argo CD.
# `make deploy` = o que o CI da Cora faz: build → push → muda o desejo no git → Argo converge.
TAG ?= $(shell date +%H%M%S)
# REG_HOST: registry visto do SEU mac (docker push)
# REG_K8S:  o MESMO registry visto de DENTRO do cluster (nos manifests)
REG_HOST = localhost:5551
REG_K8S  = lab-registry:5551

build:
	docker build -t $(REG_HOST)/billing-lab:$(TAG) app/
	docker push $(REG_HOST)/billing-lab:$(TAG)

# GitOps de verdade: o deploy é um COMMIT (muda a tag no manifest) + push.
# O auto-sync do Argo percebe e converge — você não aplica nada no cluster.
deploy: build
	sed -i '' -E 's|(billing-lab:)[A-Za-z0-9._-]+|\1$(TAG)|' manifests/rollout.yaml
	sed -i '' -E 's|(value: ")[^"]*(" # app-version)|\1$(TAG)\2|' manifests/rollout.yaml
	git add -A && git commit -m "deploy: billing-lab $(TAG)" && git push
	@echo "→ commit no git feito; acompanhe: make watch"

watch:
	kubectl argo rollouts get rollout billing-lab -n cora --watch 2>/dev/null || \
	  kubectl -n cora get rollout billing-lab -w

status:
	argocd app get billing-lab

sync:
	argocd app sync billing-lab

# ── exercícios de incidente ──
quebra-imagem:   # tag inexistente → wave/rollout preso (ImagePullBackOff)
	sed -i '' -E 's|(billing-lab:)[A-Za-z0-9._-]+|\1nao-existe|' manifests/rollout.yaml
	git add -A && git commit -m "exercicio: imagem inexistente" && git push

quebra-health:   # HEALTHY=false → Degraded
	sed -i '' 's|value: "true"      # "false"|value: "false"      # "false"|' manifests/rollout.yaml
	git add -A && git commit -m "exercicio: health quebrado" && git push

quebra-migration: # migration falha → PreSync trava o deploy
	sed -i '' 's|value: "false"   # mude|value: "true"   # mude|' manifests/migration-job.yaml
	git add -A && git commit -m "exercicio: migration falha" && git push

conserta:        # git revert do último exercício (o rollback GitOps!)
	git revert --no-edit HEAD && git push
