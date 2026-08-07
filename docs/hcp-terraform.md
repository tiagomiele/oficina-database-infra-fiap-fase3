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

Marque `private_subnet_ids` e `allowed_security_group_ids` como HCL. Marque `db_password` como sensível.

Os valores de rede vêm dos outputs do repositório `oficina-kubernetes-infra-fiap-fase3`:

- `vpc_id`;
- `private_subnet_ids`;
- `eks_cluster_security_group_id`.

## Integração com GitHub Actions

Em cada GitHub Environment (`homolog` e `production`), configure:

- secret `TF_API_TOKEN`;
- variable `TF_CLOUD_ORGANIZATION`;
- variable `TF_WORKSPACE_HOMOLOG`;
- variable `TF_WORKSPACE_PRODUCTION`.

O workflow **Terraform plan** é manual. Ele seleciona o workspace pelo ambiente e envia o plan para execução remota no HCP Terraform.

## Ordem segura

1. mantenha a sessão AWS Academy ativa;
2. renove as três credenciais AWS no workspace;
3. copie os outputs da infraestrutura Kubernetes;
4. execute **Actions → Terraform plan → Run workflow**;
5. revise recursos, alterações e outputs;
6. somente depois de aprovação explícita, confirme o apply no HCP Terraform;
7. colete evidências antes de encerrar o laboratório;
8. execute destroy quando os recursos não forem mais necessários.

Nenhum workflow deste repositório executa apply automático.
