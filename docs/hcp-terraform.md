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

O script grava listas como HCL e `db_password` como sensível. Depois do apply do Kubernetes, o próprio workflow Kubernetes atualiza automaticamente os IDs de rede usados pelo Database.

## Integração com GitHub Actions

O script central configura os GitHub Environments `homolog` e `production`, incluindo token HCP, credenciais AWS, nomes dos workspaces, região e `ENABLE_TERRAFORM_APPLY=true`. A sincronização com o Backend usa preferencialmente `SYNC_APP_CLIENT_ID`, contendo o Client ID da GitHub App, e `SYNC_APP_PRIVATE_KEY`, contendo a chave privada; ambos são configurados uma única vez no repositório Database. A App deve estar instalada somente no repositório Backend com permissão **Environments: read and write**. O secret `GITHUB_SYNC_TOKEN` é aceito apenas como alternativa temporária de recuperação.

A proteção **Required reviewers** deve existir somente no GitHub Environment `production`. Os environments `homolog`, `homolog-plan` e `production-plan` não possuem aprovação manual.

O workflow **Terraform plan** executa automaticamente somente em Pull Requests que alteram a infraestrutura. Ele seleciona o workspace pela branch base e envia o plan para execução remota no HCP Terraform, sem apply.

Merges em `homolog` apresentam três jobs sequenciais: validação da configuração e da sessão AWS → `plan → apply → sincronização JDBC` → resumo. Merges em `main` mantêm toda a execução em um único job e usam uma única aprovação no environment `production`. Após o apply, o workflow grava `db_url` como variável sensível no workspace Auth e atualiza `APP_DB_URL` e `DEPLOY_ENABLED` no Environment correspondente do Backend. Em ambos os casos, o apply só prossegue quando `ENABLE_TERRAFORM_APPLY=true`. O HCP Terraform mantém Auto apply desativado.

O `workflow_dispatch` do deploy serve somente para repetir o fluxo durante bootstrap ou recuperação. Para homologação, selecione a branch `homolog`; para produção, selecione `main`. O workflow recusa outras branches. Destroy é executado manualmente pela CLI, com confirmação interativa.

O deploy roda o plan autoritativo antes do apply, sincroniza os outputs e imprime o resumo no mesmo run. Racional no [ADR 0008](adr/0008-cicd-com-gate-de-apply.md).

## Ordem segura

1. mantenha a sessão AWS Academy ativa e execute o script central uma vez para renovar as credenciais temporárias;
2. aplique o Kubernetes; seu workflow sincroniza automaticamente os outputs de rede;
3. revise o plan automático do Pull Request do Database;
4. faça merge em `homolog`; um único run executa plan, apply e sincronização JDBC;
5. confirme no resumo que Auth e Backend receberam o JDBC;
6. colete as evidências de [`evidence-checklist.md`](evidence-checklist.md) antes de encerrar o laboratório;
7. execute destroy manualmente via Terraform CLI quando necessário.

Pull Requests nunca executam apply. Merges em `homolog` iniciam o fluxo automático de homologação; merges em `main` aguardam uma única aprovação do environment `production`.
