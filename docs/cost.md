# Controle de custo no AWS Academy

O crédito do Learner Lab é limitado e compartilhado com os outros repositórios da
solução. As decisões abaixo mantêm o banco no menor custo possível sem abrir mão de
criptografia, acesso privado e backup.

## Padrões econômicos

| Item | Padrão | Efeito no custo |
|---|---|---|
| `db_instance_class` | `db.t3.micro` | menor classe elegível ao free tier do RDS |
| `multi_az` | `false` em homolog; `true` em produção | Multi-AZ praticamente dobra o custo de instância |
| `db_allocated_storage` | 20 GiB | mínimo do `gp3` |
| `db_max_allocated_storage` | 40 GiB | teto do autoscaling, evita crescimento silencioso |
| `backup_retention_days` | 7 em homolog, 14 em produção | backup além do tamanho do banco é cobrado |
| `delete_automated_backups` | `true` | não deixa backup órfão após o destroy |
| `skip_final_snapshot` | `true` em homolog; `false` em produção | produção preserva snapshot final |
| `enabled_cloudwatch_logs_exports` | `["postgresql"]` | apenas o log necessário à evidência |
| `cloudwatch_logs_retention_days` | 7 em homolog, 14 em produção | sem isso a retenção seria infinita |
| `log_min_duration_statement_ms` | 1000 | limita volume de ingestão no CloudWatch |
| `log_statement` | `ddl` | evita ingestão de todo o SQL da aplicação |
| `performance_insights_enabled` | `false` | recurso pago fora da retenção de 7 dias |
| `monitoring_interval` | `0` | Enhanced Monitoring gera ingestão contínua no CloudWatch |

## Onde o custo escapa

1. **Log group sem retenção.** O RDS cria `/aws/rds/instance/.../postgresql` com
   *Never expire*. Por isso o Terraform gerencia o log group.
2. **Instância esquecida ligada.** O laboratório é encerrado, mas os recursos criados
   por Terraform continuam contabilizados enquanto a sessão vive. Rode `destroy` após
   coletar as evidências.
3. **Snapshot final.** Fica cobrado como armazenamento de backup depois do destroy.
4. **Storage autoscaling.** Só cresce; não reduz. O teto de 40 GiB é intencional.
5. **Multi-AZ ligado "só para testar".** Não é revertido automaticamente.

## Sequência de menor custo

1. crie os recursos apenas quando for coletar evidência;
2. execute o `plan` e revise antes do apply;
3. colete as evidências da lista em [`evidence-checklist.md`](evidence-checklist.md);
4. rode `destroy` no mesmo dia;
5. confirme que não sobrou snapshot manual nem log group retido.

## Produção mais conservadora que homologação

O perfil versionado de produção prioriza disponibilidade e recuperação: Multi-AZ,
`deletion_protection = true`, snapshot final e retenções maiores. Esse perfil tem custo
superior e não deve ser aplicado apenas para coletar evidência descartável no Learner Lab.
Quando a demonstração acadêmica exigir um ambiente lógico de produção que será destruído
no mesmo dia, execute a configuração central com
`-UseAwsAcademyDisposableProductionProfile`. O override define Multi-AZ e proteção como
`false` e ignora o snapshot final; a limitação deve constar na evidência e o workspace
deve voltar ao perfil endurecido antes da promoção final.
