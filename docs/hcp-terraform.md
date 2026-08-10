# HCP Terraform e execução do banco

## Workspaces

Crie dois workspaces com execução remota e **Auto apply desativado**:

| Workspace sugerido | Branch | Variável `environment` |
|---|---|---|
| `oficina-database-homolog` | `homolog` | `homolog` |
| `oficina-database-production` | `main` | `production` |

Cada workspace mantém seu próprio state. Não reutilize o state combinado da Fase 2.

## Variáveis do HCP Terraform

Cadastre como variáveis de ambiente sensíveis e renove a cada sessão do Learner Lab:

```text
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
AWS_SESSION_TOKEN
```

Cadastre como variáveis Terraform:

```text
aws_region = "us-west-2"
environment = "homolog" ou "production"
vpc_id = "vpc-..."
private_subnet_ids = ["subnet-...", "subnet-..."]
allowed_security_group_ids = ["sg-..."]
db_password = "valor-seguro"
```

As variáveis de observabilidade e custo são opcionais e têm padrão seguro. Cadastre-as
somente para divergir do padrão; os valores por ambiente estão em
[`../environments`](../environments).

```text
enabled_cloudwatch_logs_exports = ["postgresql"]
cloudwatch_logs_retention_days  = 7
performance_insights_enabled    = false
```

Marque `private_subnet_ids` e `allowed_security_group_ids` como HCL. Marque `db_password` como sensível.

Os valores de rede vêm dos outputs do repositório `oficina-kubernetes-infra-fiap-fase3`:

- `vpc_id`;
- `private_subnet_ids`;
- `eks_cluster_security_group_id`.

## Integração com GitHub Actions

Em cada GitHub Environment (`homolog` e `production`), configure:

- secret `TF_API_TOKEN`;
- secrets `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` e `AWS_SESSION_TOKEN`, renovados a cada sessão do Learner Lab;
- variable `TF_CLOUD_ORGANIZATION`;
- variable `TF_WORKSPACE_HOMOLOG`;
- variable `TF_WORKSPACE_PRODUCTION`;
- variable `ENABLE_TERRAFORM_APPLY`, que só vale `true` na janela em que o apply é autorizado;
- variable opcional `AWS_REGION` (padrão `us-west-2`);
- proteção **Required reviewers** no ambiente, que é o gate humano do apply.

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

1. mantenha a sessão AWS Academy ativa;
2. renove as três credenciais AWS no workspace;
3. copie os outputs da infraestrutura Kubernetes;
4. execute **Actions → Terraform plan → Run workflow**, selecionando `homolog`, ou use a CLI no primeiro bootstrap;
5. revise recursos, alterações e outputs;
6. ligue `ENABLE_TERRAFORM_APPLY` e execute **Terraform apply** com a confirmação
   textual, aprovando o ambiente; ou confirme o apply diretamente no HCP Terraform;
7. colete as evidências de [`evidence-checklist.md`](evidence-checklist.md) antes de
   encerrar o laboratório;
8. execute o destroy pelo mesmo workflow e desligue `ENABLE_TERRAFORM_APPLY`.

Nenhum workflow deste repositório executa apply automático.
