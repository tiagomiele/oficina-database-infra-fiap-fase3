# AWS Academy

## Estratégia

- usar as credenciais temporárias do Learner Lab sem criar recursos IAM;
- validar credenciais temporárias antes de plan/apply;
- manter state no HCP Terraform;
- usar versão fixa suportada do PostgreSQL;
- evitar data sources que exijam permissões bloqueadas;
- destruir os recursos após a coleta das evidências;
- usar o override descartável somente na demonstração do Learner Lab; o perfil versionado de produção permanece Multi-AZ e protegido;
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
| crédito limitado | `db.t3.micro`, Performance Insights desligado e retenção curta; Multi-AZ pode ser removido apenas no override acadêmico |
| ambiente descartável | `-UseAwsAcademyDisposableProductionProfile` reduz a proteção do workspace de produção para permitir destroy |
| conjunto reduzido de serviços | observabilidade usa CloudWatch e uma Lambda com a `LabRole`, sem criar IAM |
| state não pode viver no laboratório | state remoto no HCP Terraform |

O override acadêmico não representa produção real e deve ser removido antes da promoção final. A falha operacional mais comum é `ExpiredToken`; o procedimento está em
[`troubleshooting.md`](troubleshooting.md). O racional completo está no
[ADR 0004](adr/0004-limitacoes-aws-academy.md).
