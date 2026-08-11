# AWS Academy

## Estratégia

- usar as credenciais temporárias do Learner Lab sem criar recursos IAM;
- validar credenciais temporárias antes de plan/apply;
- manter state no HCP Terraform;
- usar versão fixa suportada do PostgreSQL;
- evitar data sources que exijam permissões bloqueadas;
- destruir os recursos após a coleta das evidências;
- manter Multi-AZ e proteção contra exclusão desativados no ambiente acadêmico descartável;
- manter Performance Insights e Enhanced Monitoring desligados por padrão;
- exigir armazenamento criptografado, backup e acesso privado mesmo no laboratório.

## Ambientes

| Branch | Estado lógico |
|---|---|
| `homolog` | banco de homologação |
| `main` | banco de produção |

A disponibilidade dos recursos depende da sessão ativa do Learner Lab.

## Limitações que moldaram o projeto

| Limitação | Efeito neste repositório |
|---|---|
| credencial temporária que expira com a sessão | validação obrigatória por `aws sts get-caller-identity` antes de plan e apply |
| sem permissão para criar IAM | sem Enhanced Monitoring; CI falha se algum `aws_iam_*` for declarado |
| crédito limitado | `db.t3.micro`, Multi-AZ e Performance Insights desligados, retenção curta de log |
| ambiente descartável | `deletion_protection = false` e `skip_final_snapshot = true`, para o destroy sempre funcionar |
| conjunto reduzido de serviços | observabilidade só com CloudWatch Logs e métricas padrão |
| state não pode viver no laboratório | state remoto no HCP Terraform |

A falha operacional mais comum é `ExpiredToken`; o procedimento está em
[`troubleshooting.md`](troubleshooting.md). O racional completo está no
[ADR 0004](adr/0004-limitacoes-aws-academy.md).
