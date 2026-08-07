# AWS Academy

## Estratégia

- reutilizar a `LabRole`;
- validar credenciais temporárias antes de plan/apply;
- manter state no HCP Terraform;
- usar versão fixa suportada do PostgreSQL;
- evitar data sources que exijam permissões bloqueadas;
- destruir os recursos após a coleta das evidências.

## Ambientes

| Branch | Estado lógico |
|---|---|
| `homolog` | banco de homologação |
| `main` | banco de produção |

A disponibilidade dos recursos depende da sessão ativa do Learner Lab.
