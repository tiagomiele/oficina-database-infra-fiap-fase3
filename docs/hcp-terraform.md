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

A proteção **Required reviewers** deve existir somente no GitHub Environment `production`. Os environments `homolog`, `homolog-plan` e `production-plan` não possuem aprovação manual.

O workflow **Terraform plan** executa automaticamente em Pull Requests que alteram a infraestrutura e também pode ser iniciado manualmente. Ele seleciona o workspace pelo ambiente e envia o plan para execução remota no HCP Terraform, sem apply.

Merges em `homolog` iniciam automaticamente plan e apply, sem aprovação manual. Merges em `main` usam uma única aprovação no environment `production`. Em ambos os casos, o apply só prossegue quando `ENABLE_TERRAFORM_APPLY=true`. O HCP Terraform mantém Auto apply desativado.

O `workflow_dispatch` serve somente para repetir o apply durante bootstrap ou recuperação. Para homologação, selecione a branch `homolog`; para produção, selecione `main`. O workflow recusa outras branches. Destroy é executado manualmente pela CLI, com confirmação interativa.

O deploy roda o plan autoritativo antes do apply e imprime os outputs ao final. Racional no [ADR 0008](adr/0008-cicd-com-gate-de-apply.md).

## Ordem segura

1. mantenha a sessão AWS Academy ativa e execute o script central;
2. aplique o Kubernetes e reexecute o script para sincronizar os outputs;
3. revise o plan do Pull Request;
4. faça merge em `homolog` para plan e apply automáticos;
5. reexecute o script central para propagar a URL JDBC;
6. colete as evidências de [`evidence-checklist.md`](evidence-checklist.md) antes de encerrar o laboratório;
7. execute destroy manualmente via Terraform CLI quando necessário.

Pull Requests nunca executam apply. Merges em `homolog` iniciam o fluxo automático de homologação; merges em `main` aguardam uma única aprovação do environment `production`.
