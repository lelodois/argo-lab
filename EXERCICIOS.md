# Laboratório Argo CD — roteiro de treino

Pré: `make status` verde. UI: https://localhost:8443 (admin / senha em CREDENCIAIS.txt).
App: http://localhost:8090 · Watch do canário: `make watch`

## 1. Deploy feliz (o fluxo do dia a dia)
    make deploy TAG=v2
    make watch          # veja o canary: 50% → pause 20s → 100%
    curl localhost:8090 # "billing-lab v2"
Observe na UI: OutOfSync → PreSync Job → Progressing → Healthy.
**Aprendizado**: o deploy foi um COMMIT (confira `git log`). O Argo fez o resto.

## 2. O SEU incidente: Progressing eterno
Edite manifests/rollout.yaml: SLOW_START_S: "600". Commit+push (ou make deploy).
O pod novo nunca passa no readiness → Rollout fica Progressing → um
`argocd app wait --health --timeout 60` estoura (é o wait-app-stage!).
Debug: kubectl -n cora describe pod <novo> (probe falhando).
Conserto: `make conserta` (git revert = rollback GitOps).

## 3. Degraded
    make quebra-health     # HEALTHY=false
Rollout aplica, pods sobem, probe reprova → Health: Degraded na UI.
    make conserta

## 4. Wave presa (incidente 17/07 do engineering-metrics)
    make quebra-imagem     # tag inexistente
ImagePullBackOff → canário nunca fica pronto → deploy congela.
Note: os pods VELHOS continuam servindo (curl ainda responde!) — é por
isso que o incidente foi silencioso em prod.
    make conserta

## 5. Migration que trava o deploy
    make quebra-migration
O PreSync Job falha → o Argo NEM APLICA o Rollout (sync para na wave).
`argocd app get billing-lab` mostra o sync Failed no hook.
    make conserta

## 6. Drift e selfHeal (a alma do GitOps)
    kubectl -n cora scale rollout billing-lab --replicas=5
Espere ~1min: o Argo volta pra 2 sozinho (selfHeal desfaz mudança manual).
Confira em Events na UI.

## 7. Rollback por histórico
    argocd app history billing-lab
    argocd app rollback billing-lab <ID>   # nota: desliga o auto-sync!
    argocd app set billing-lab --sync-policy automated --self-heal --auto-prune  # religa

## Cheat sheet
    argocd app get|diff|sync|wait|history|rollback billing-lab
    kubectl argo rollouts get rollout billing-lab -n cora --watch
    kubectl argo rollouts promote billing-lab -n cora     # pula a pausa do canary
