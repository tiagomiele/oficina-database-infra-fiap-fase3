# ADR 0006 — Backup, retenção e proteção contra exclusão

- Status: Aceito
- Data: 2026-08-10

## Contexto

O banco precisa demonstrar prática correta de backup e recuperação. Homologação pode ser
descartável, mas o perfil versionado de produção deve preservar dados e impedir exclusão
acidental. O Learner Lab requer um override explícito quando a demonstração precisar ser
destruída no mesmo dia.

## Decisão

| Item | Homolog | Produção | Racional |
|---|---|---|---|
| `backup_retention_period` | 7 dias | 14 dias | backup automático dentro do tamanho do banco não gera custo adicional relevante |
| `backup_window` | 03:00-04:00 UTC | igual | janela fora do horário de uso |
| `maintenance_window` | dom 04:00-05:00 UTC | igual | imediatamente após o backup |
| `delete_automated_backups` | `true` | `true` | não deixa backup órfão após o destroy |
| `copy_tags_to_snapshot` | `true` | `true` | rastreabilidade de custo por projeto |
| `skip_final_snapshot` | `true` | `false` | produção exige snapshot final antes da exclusão |
| `deletion_protection` | `false` | `true` | produção bloqueia exclusão acidental |
| `storage_encrypted` | `true` | `true` | criptografia em repouso é obrigatória, mesmo no laboratório |
| `rds.force_ssl` | `1` | `1` | criptografia em trânsito obrigatória |
| retenção de log no CloudWatch | 7 dias | 14 dias | o padrão do RDS seria retenção infinita |

`final_snapshot_identifier` é obrigatório quando `skip_final_snapshot = false`, validado
por `precondition`. `environments/production.tfvars.example` define
`deletion_protection = true`, `skip_final_snapshot = false` e `multi_az = true`. A
configuração central sincroniza esses valores no workspace de produção.

## Consequências

- recuperação point-in-time existe dentro da janela de retenção enquanto a instância
  vive;
- homologação pode ser destruída sem snapshot residual;
- produção preserva snapshot final e exige uma mudança deliberada antes do destroy;
- ligar `deletion_protection` exige um apply para desligá-la antes do destroy, e isso
  está documentado em [`../troubleshooting.md`](../troubleshooting.md);
- não existe cópia entre regiões no perfil atual; isso exigiria política adicional fora do Learner Lab.

## Alternativas descartadas

- **Usar o perfil de homologação em produção**: reduziria disponibilidade e permitiria
  perda acidental de dados.
- **Produção descartável como padrão**: atende ao custo do Learner Lab, mas não ao requisito
  de alta disponibilidade; ficou disponível somente por override explícito.
- **Retenção de 35 dias**: sem ganho didático e com mais armazenamento cobrado.
- **AWS Backup**: outro serviço, outra permissão IAM, nenhum benefício aqui.
