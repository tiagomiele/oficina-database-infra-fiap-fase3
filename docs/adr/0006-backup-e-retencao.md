# ADR 0006 — Backup, retenção e proteção contra exclusão

- Status: Aceito
- Data: 2026-08-10

## Contexto

O banco precisa demonstrar prática correta de backup e recuperação, mas vive em um
laboratório descartável em que o `destroy` de fim de sessão precisa funcionar sempre e
não pode deixar custo residual.

## Decisão

| Item | Homolog | Produção | Racional |
|---|---|---|---|
| `backup_retention_period` | 7 dias | 14 dias | backup automático dentro do tamanho do banco não gera custo adicional relevante |
| `backup_window` | 03:00-04:00 UTC | igual | janela fora do horário de uso |
| `maintenance_window` | dom 04:00-05:00 UTC | igual | imediatamente após o backup |
| `delete_automated_backups` | `true` | `true` | não deixa backup órfão após o destroy |
| `copy_tags_to_snapshot` | `true` | `true` | rastreabilidade de custo por projeto |
| `skip_final_snapshot` | `true` | `true` | snapshot final sobreviveria ao destroy e seria cobrado |
| `deletion_protection` | `false` | `false` | proteção ligada impede o destroy de fim de sessão |
| `storage_encrypted` | `true` | `true` | criptografia em repouso é obrigatória, mesmo no laboratório |
| `rds.force_ssl` | `1` | `1` | criptografia em trânsito obrigatória |
| retenção de log no CloudWatch | 7 dias | 14 dias | o padrão do RDS seria retenção infinita |

A semântica é preservada no código, não removida: `final_snapshot_identifier` continua
obrigatório quando `skip_final_snapshot = false`, validado por `precondition`, e os
valores recomendados para uma conta AWS real estão comentados em
`environments/production.tfvars.example` (`deletion_protection = true`,
`skip_final_snapshot = false`, `multi_az = true`).

## Consequências

- recuperação point-in-time existe dentro da janela de retenção enquanto a instância
  vive;
- ao encerrar a validação, nada permanece cobrado: nem snapshot, nem backup automático,
  nem log group sem expiração;
- ligar `deletion_protection` exige um apply para desligá-la antes do destroy, e isso
  está documentado em [`../troubleshooting.md`](../troubleshooting.md);
- não existe cópia de backup entre regiões: o dado é acadêmico e descartável.

## Alternativas descartadas

- **`deletion_protection = true` como padrão**: quebraria o destroy de fim de sessão do
  Learner Lab e deixaria a instância ligada consumindo crédito.
- **Snapshot final obrigatório**: custo residual após o fim do laboratório.
- **Retenção de 35 dias**: sem ganho didático e com mais armazenamento cobrado.
- **AWS Backup**: outro serviço, outra permissão IAM, nenhum benefício aqui.
