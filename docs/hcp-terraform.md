# HCP Terraform e execução do banco

## Workspaces

Crie dois workspaces com execução remota e **Auto apply desativado**:

| Workspace sugerido | Branch | Variável `environment` |
|---|---|---|
| `oficina-database-homolog` | `homolog` | `homolog` |
| `oficina-database-production` | `main` | `production` |

Cada workspace mantém seu próprio state. Não reutilize o state combinado da Fase 2.

## Variáveis do HCP Terraform

Não copie credenciais, VPC, subnets, security group ou senha pelo formulário. Execute no repositório do backend:

```powershell
.\scripts\configure-environment.ps1 -Environment homolog
```

O script associa o Variable Set AWS compartilhado, mantém `environment`, reutiliza a senha local protegida e lê `vpc_id`, `private_subnet_ids` e `eks_cluster_security_group_id` diretamente dos outputs Kubernetes.

As variáveis de observabilidade e custo têm padrão econômico. Cadastre uma sobrescrita somente quando houver decisão arquitetural explícita; os valores por ambiente estão em [`../environments`](../environments).

```text
enabled_cloudwatch_logs_exports = ["postgresql"]
cloudwatch_logs_retention_days  = 7
performance_insights_enabled    = false
```

O script grava listas como HCL e `db_password` como sensível. Não reutilize IDs depois de reset do AWS Academy; reexecute o script após o novo apply do Kubernetes.

## Integração com GitHub Actions

O script central configura os GitHub Environments `homolog` e `production`, incluindo token HCP, credenciais AWS, nomes dos workspaces, região e `ENABLE_TERRAFORM_APPLY=true`.

A proteção **Required reviewers** continua manual por ser gate humano de governança.

O workflow **Terraform plan** é manual. Ele valida a credencial temporária com
`aws sts get-caller-identity`, seleciona o workspace pelo ambiente e envia o plan para
execução remota no HCP Terraform.

O workflow **Terraform apply** também é manual e executa `apply` ou `destroy` somente
quando as três barreiras passam:

1. `ENABLE_TERRAFORM_APPLY` vale `true` no ambiente escolhido;
2. o campo de confirmação recebe exatamente `APPLY-<ambiente>` ou `DESTROY-<ambiente>`;
3. o GitHub Environment aprova a execução (required reviewers).

Ele roda o plan antes da operação e imprime os outputs ao final. Racional no
[ADR 0008](adr/0008-cicd-com-gate-de-apply.md).

O `workflow_dispatch` só aparece no GitHub Actions depois que o arquivo do workflow existe na branch padrão `main`. No primeiro bootstrap, promova o workflow até `main` ou execute o plan pela CLI com `TF_CLOUD_ORGANIZATION` e `TF_WORKSPACE`; em ambos os casos, mantenha Auto apply desativado.

## Ordem segura

1. mantenha a sessão AWS Academy ativa e execute o script central;
2. aplique o Kubernetes somente após aprovação e reexecute o script para sincronizar os outputs;
3. execute **Actions → Terraform plan → Run workflow**, selecionando o ambiente, ou use a CLI no primeiro bootstrap;
4. revise recursos, alterações e outputs;
5. execute **Terraform apply** com a confirmação textual e aprovação do environment, ou confirme o apply diretamente no HCP Terraform;
6. reexecute o script central para propagar a URL JDBC;
7. colete as evidências de [`evidence-checklist.md`](evidence-checklist.md) antes de encerrar o laboratório;
8. execute o destroy pelo mesmo workflow quando necessário.

Nenhum workflow deste repositório executa apply automático.
