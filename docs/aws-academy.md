# AWS Academy

## Estratégia

- usar as credenciais temporárias do Learner Lab sem criar recursos IAM;
- validar credenciais temporárias antes de plan/apply;
- manter state no HCP Terraform;
- usar versão fixa suportada do PostgreSQL;
- evitar data sources que exijam permissões bloqueadas;
- destruir os recursos após a coleta das evidências;
- manter Multi-AZ e proteção contra exclusão desativados no ambiente acadêmico descartável;
- exigir armazenamento criptografado, backup e acesso privado mesmo no laboratório.

## Ambientes

| Branch | Estado lógico |
|---|---|
| `homolog` | banco de homologação |
| `main` | banco de produção |

A disponibilidade dos recursos depende da sessão ativa do Learner Lab.
