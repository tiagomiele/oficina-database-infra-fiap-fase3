# Validação do Terraform do banco

## Validação estática (sem nuvem e sem custo)

```bash
terraform fmt -check -recursive
terraform init -backend=false -input=false
terraform validate
tflint --recursive
python3 scripts/validate_docs.py
```

`terraform init -backend=false` é obrigatório para validar offline: o bloco `cloud {}`
exigiria credencial do HCP Terraform em um init normal.

O CI executa os mesmos comandos e ainda:

- verifica que todo nome atribuído nos `environments/*.tfvars.example` corresponde a uma
  variável declarada;
- falha se algum recurso `aws_iam_*` for declarado;
- roda Checkov, Trivy (configuração) e Gitleaks (segredos).

## Verificações do Checkov ignoradas de propósito

Todas decorrem de decisões registradas em ADR, não de descuido:

| Check | Motivo | Referência |
|---|---|---|
| `CKV_AWS_158` log group com KMS | chave KMS gerenciada exigiria política IAM e custo | [ADR 0004](adr/0004-limitacoes-aws-academy.md) |
| `CKV_AWS_338` retenção de log de 1 ano | ingestão e retenção cobradas; 7 a 14 dias bastam para a evidência | [ADR 0007](adr/0007-controle-de-custo.md) |
| `CKV_AWS_293` deletion protection | impediria o destroy de fim de sessão do Learner Lab | [ADR 0006](adr/0006-backup-e-retencao.md) |
| `CKV_AWS_157` Multi-AZ | dobra o custo de instância | [ADR 0007](adr/0007-controle-de-custo.md) |
| `CKV_AWS_353` Performance Insights | recurso pago fora da retenção de 7 dias | [ADR 0003](adr/0003-observabilidade-rds.md) |
| `CKV_AWS_161` autenticação IAM no banco | exigiria criar recurso IAM | [ADR 0004](adr/0004-limitacoes-aws-academy.md) |
| `CKV_AWS_118` Enhanced Monitoring | exigiria role IAM dedicada | [ADR 0003](adr/0003-observabilidade-rds.md) |

Reproduza localmente:

```bash
pip install checkov==3.3.9
checkov -d . --compact --quiet --framework terraform \
  --skip-check CKV_AWS_158,CKV_AWS_338,CKV_AWS_293,CKV_AWS_157,CKV_AWS_353,CKV_AWS_161,CKV_AWS_118
```

Nenhum passo do CI usa credencial AWS, então ele passa com o Learner Lab desligado.

## Validação de credencial

Antes de qualquer comando que fale com a AWS:

```bash
aws sts get-caller-identity
```

Falha aqui significa credencial ausente ou expirada; ver
[`troubleshooting.md`](troubleshooting.md). Os workflows **Terraform plan** e
**Terraform apply** executam essa verificação como primeiro passo e falham com mensagem
explícita.

## Plan remoto

O plan real depende de:

- credenciais temporárias válidas do AWS Academy;
- workspace HCP Terraform configurado;
- outputs reais da VPC, subnets privadas e security group do EKS;
- senha do banco cadastrada como variável sensível.

Execute o workflow manual **Terraform plan** e confirme no log:

- uma instância RDS PostgreSQL privada;
- armazenamento criptografado;
- DB subnet group com ao menos duas subnets;
- entrada na porta 5432 somente para os security groups autorizados;
- `aws_cloudwatch_log_group` com `retention_in_days` definido;
- `performance_insights_enabled = false` e `monitoring_interval = 0`;
- ausência de senha nos outputs;
- nenhum recurso IAM criado.

## Apply e evidências

O apply exige gate explícito, ver [`hcp-terraform.md`](hcp-terraform.md). Depois dele,
siga [`evidence-checklist.md`](evidence-checklist.md) e a validação de logs em
[`observability.md`](observability.md), e execute o destroy ao final.
