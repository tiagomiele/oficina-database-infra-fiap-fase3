# Checklist de evidências

Use esta lista na validação final. Cada item indica o comando ou a tela e o artefato a
guardar. Nenhum item exige Performance Insights.

## 1. Validação estática (sem custo, sem nuvem)

| Evidência | Como obter | Artefato |
|---|---|---|
| CI verde no PR | GitHub Actions → workflow **CI** | print da execução |
| formatação | `terraform fmt -check -recursive` | saída sem diferenças |
| validate | `terraform init -backend=false -input=false && terraform validate` | `Success! The configuration is valid.` |
| lint | `tflint --recursive` | saída limpa |
| segurança de configuração | job Trivy no CI | print do job |
| ausência de segredos | job Gitleaks no CI | print do job |
| documentação e diagrama | job de validação de documentação no CI | print do job |

## 2. Credenciais e workspace

| Evidência | Como obter | Artefato |
|---|---|---|
| credencial temporária válida | `aws sts get-caller-identity` | JSON com `Arn` contendo `LabRole` ou `voclabs` |
| workspaces separados | HCP Terraform → lista de workspaces | print de `oficina-database-homolog` e `oficina-database-production` |
| variáveis sensíveis | HCP Terraform → workspace → Variables | print mostrando `db_password` e credenciais como sensitive |

## 3. Plan

| Evidência | Como obter | Artefato |
|---|---|---|
| plan de homologação | Actions → **Terraform plan** → `homolog` | log do plan |
| recursos previstos | leitura do plan | `aws_db_subnet_group`, `aws_security_group`, `aws_db_parameter_group`, `aws_cloudwatch_log_group`, `aws_db_instance` |
| nenhum recurso IAM | leitura do plan | ausência de `aws_iam_*` |

## 4. Apply e recursos criados

| Evidência | Como obter | Artefato |
|---|---|---|
| instância criada | `aws rds describe-db-instances --db-instance-identifier <id>` | JSON |
| banco privado | campo `PubliclyAccessible` | `false` |
| criptografia | campo `StorageEncrypted` | `true` |
| Multi-AZ desligado | campo `MultiAZ` | `false` |
| backup configurado | campos `BackupRetentionPeriod` e `PreferredBackupWindow` | `7` (ou `14`) e `03:00-04:00` |
| subnets privadas | campo `DBSubnetGroup.Subnets` | ao menos duas AZs |
| SSL obrigatório | `aws rds describe-db-parameters --db-parameter-group-name <pg> --query "Parameters[?ParameterName=='rds.force_ssl']"` | `1` |
| acesso restrito | `aws ec2 describe-security-groups --group-ids <sg>` | ingress 5432 somente por security group de origem |
| outputs sem senha | `terraform output` | ausência de `db_password` |

## 5. Observabilidade

| Evidência | Como obter | Artefato |
|---|---|---|
| exportação habilitada | `aws rds describe-db-instances ... --query 'DBInstances[0].EnabledCloudwatchLogsExports'` | `["postgresql"]` |
| log group com retenção | `aws logs describe-log-groups --log-group-name-prefix /aws/rds/instance/<id>` | nome e `retentionInDays` |
| conexão registrada | `aws logs filter-log-events ... --filter-pattern "connection authorized"` | mensagens de conexão do backend e da Lambda |
| consulta lenta registrada | `aws logs filter-log-events ... --filter-pattern "duration:"` | mensagens de consulta lenta, quando houver |
| sem dado pessoal no log | leitura das mensagens acima | confirmação de ausência de CPF, e-mail e telefone |
| métricas padrão | CloudWatch → RDS → instância | print de `CPUUtilization` e `DatabaseConnections` |
| Performance Insights desligado | `terraform output performance_insights_enabled` | `false` |

Os comandos completos estão em [`observability.md`](observability.md).

## 6. Integração ponta a ponta

| Evidência | Como obter | Artefato |
|---|---|---|
| backend conectado | log do pod no EKS mostrando Flyway aplicado | log |
| migrations aplicadas | `SELECT version, description, success FROM flyway_schema_history ORDER BY installed_rank;` | resultado com `V1`, `V2` e `V3` |
| modelo real | comparação do resultado de `\dt` com [`data-model.md`](data-model.md) | lista de 14 tabelas |
| índices reais | `SELECT indexname, tablename FROM pg_indexes WHERE schemaname = 'public' ORDER BY tablename;` | comparação com [`index-review.md`](index-review.md) |
| login por CPF | chamada à Lambda de autenticação | resposta com token |

## 7. Encerramento

| Evidência | Como obter | Artefato |
|---|---|---|
| destroy executado | run de destroy no HCP Terraform | log |
| sem instância remanescente | `aws rds describe-db-instances` | lista vazia do projeto |
| sem snapshot remanescente | `aws rds describe-db-snapshots --snapshot-type manual` | lista vazia do projeto |
| sem log group remanescente | `aws logs describe-log-groups --log-group-name-prefix /aws/rds/instance/oficina` | lista vazia |

Enquanto o apply não for executado com credenciais válidas, o banco **não** existe:
nenhum endpoint, URL JDBC ou instância deste repositório deve ser descrito como ativo
antes da validação final.
