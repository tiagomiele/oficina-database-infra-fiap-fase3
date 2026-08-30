# ADR 0007 — Controle de custo como padrão do repositório

- Status: Aceito
- Data: 2026-08-10

## Contexto

O crédito do Learner Lab é compartilhado por todos os repositórios da solução (EKS,
Lambda, banco). O padrão de qualquer variável precisa ser o mais barato aceitável, e
qualquer recurso caro precisa ser uma escolha explícita de quem executa.

## Decisão

Nenhum recurso de custo elevado é obrigatório. Os padrões econômicos e os pontos em que
o custo escapa estão consolidados em [`../cost.md`](../cost.md). Os principais:
`db.t3.micro`, `multi_az = false`, 20 GiB com teto de 40 GiB,
`performance_insights_enabled = false`, `monitoring_interval = 0`, exportação apenas do
log `postgresql`, retenção de log de 7 dias e `log_min_duration_statement` de 1000 ms.

O merge inicia o workflow de apply, mas nenhum recurso é criado sem
`ENABLE_TERRAFORM_APPLY=true` e aprovação do GitHub Environment. Configuração ausente
falha explicitamente.

## Consequências

- produção usa Multi-AZ e retenção maior por decisão arquitetural; o override acadêmico
  descartável precisa ser solicitado explicitamente;
- ligar Performance Insights ou Enhanced Monitoring continua sendo decisão consciente;
- as variáveis de recurso pago são validadas para evitar valor fora da camada gratuita
  por engano (por exemplo, retenção do Performance Insights);
- o teto de autoscaling de armazenamento pode exigir ajuste consciente se o volume
  crescer;
- a coleta de evidência é feita em uma janela curta, seguida de `destroy`.

## Alternativas descartadas

- **Deixar o padrão "produção real"** (Multi-AZ, Performance Insights, retenção longa):
  esgotaria o crédito e não é exigido pela fase.
- **Orçamento e alarme de billing**: exigiria permissão de billing indisponível no
  Learner Lab.
