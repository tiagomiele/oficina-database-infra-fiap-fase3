# Observabilidade do banco

## O que é exportado

O RDS publica os logs do PostgreSQL no CloudWatch Logs conforme
`enabled_cloudwatch_logs_exports`:

| Valor | Log group | Uso |
|---|---|---|
| `postgresql` | `/aws/rds/instance/<identificador>/postgresql` | conexões, desconexões, consultas lentas, erros e DDL |
| `upgrade` | `/aws/rds/instance/<identificador>/upgrade` | histórico de upgrade da engine |

Homologação exporta apenas `postgresql`. Produção exporta `postgresql` e `upgrade`.
Para desligar totalmente, use `enabled_cloudwatch_logs_exports = []`.

Quando `manage_cloudwatch_log_groups` é `true`, o Terraform cria os log groups antes da
instância só para aplicar `cloudwatch_logs_retention_days`. Sem isso, o RDS cria os log
groups com retenção *Never expire*, que acumula custo indefinidamente.

## Parâmetros de log e por quê

| Parâmetro | Valor padrão | Intenção |
|---|---|---|
| `log_connections` | `1` | comprovar que o backend no EKS e a Lambda de login realmente conectaram no RDS privado |
| `log_disconnections` | `1` | fechar o par conexão/desconexão e evidenciar pool de conexões |
| `log_min_duration_statement` | `1000` ms | registrar somente consulta lenta, sustentando a revisão de índices |
| `log_statement` | `ddl` | registrar mudança de estrutura, nunca o SQL de leitura ou escrita de dados |
| `log_lock_waits` | `1` | expor contenção, relevante no `SELECT ... FOR UPDATE` do numerador da OS |
| `log_parameter_max_length` | `0` | truncar todo parâmetro de bind |
| `log_parameter_max_length_on_error` | `0` | truncar parâmetro também em erro |
| `rds.force_ssl` | `1` | recusar conexão sem TLS |

## Dados pessoais fora do log

A tabela `clientes` guarda nome, documento, e-mail e telefone. Três decisões impedem
que esses valores cheguem ao CloudWatch:

1. `log_statement = "ddl"` — nenhum `INSERT`, `UPDATE` ou `SELECT` de dados é registrado
   integralmente;
2. `log_parameter_max_length = 0` e `log_parameter_max_length_on_error = 0` — o CPF
   enviado no login aparece como parâmetro truncado, não como valor;
3. o log de consulta lenta registra o texto parametrizado da instrução, sem os valores.

Elevar `log_statement` para `mod` ou `all` passa a gravar dados pessoais no CloudWatch.
Só faça isso em investigação pontual, com o banco sem dados reais, e reverta em seguida.

## Performance Insights

Desabilitado por padrão (`performance_insights_enabled = false`). Motivos:

- as evidências exigidas pela fase são obtidas via logs do PostgreSQL e métricas
  padrão do CloudWatch;
- no AWS Academy o orçamento é limitado e o recurso ficaria ligado à revelia;
- `db.t3.micro` já é a menor classe possível, então o ganho de diagnóstico é pequeno.

Para habilitar temporariamente:

```hcl
performance_insights_enabled          = true
performance_insights_retention_period = 7 # único valor da camada gratuita
```

Retenção acima de 7 dias é cobrada. A variável valida 7, 731 ou múltiplos de 31 até 713.

## Enhanced Monitoring

`monitoring_interval` fica em `0`. O Enhanced Monitoring exige uma role IAM com a
política `AmazonRDSEnhancedMonitoringRole`, e este repositório não cria recursos IAM
(restrição do AWS Academy). Se uma role adequada já existir na conta, informe
`monitoring_role_arn` e um `monitoring_interval` maior que zero; a `precondition` do
`aws_db_instance` recusa intervalo maior que zero sem role.

## Validação dos logs

Após o apply, com credenciais válidas do Learner Lab:

```bash
IDENTIFIER=$(terraform output -raw database_identifier)

# 1. Exportação habilitada na instância
aws rds describe-db-instances \
  --db-instance-identifier "$IDENTIFIER" \
  --query 'DBInstances[0].EnabledCloudwatchLogsExports'

# 2. Log group existe e tem retenção definida
aws logs describe-log-groups \
  --log-group-name-prefix "/aws/rds/instance/$IDENTIFIER" \
  --query 'logGroups[].[logGroupName,retentionInDays]' --output table

# 3. Eventos de conexão gravados após o backend subir
aws logs filter-log-events \
  --log-group-name "/aws/rds/instance/$IDENTIFIER/postgresql" \
  --filter-pattern "connection authorized" --max-items 20 \
  --query 'events[].message'

# 4. Consultas lentas, quando houver
aws logs filter-log-events \
  --log-group-name "/aws/rds/instance/$IDENTIFIER/postgresql" \
  --filter-pattern "duration:" --max-items 20 --query 'events[].message'
```

Confirme na saída que nenhuma mensagem contém CPF, e-mail ou telefone. Se contiver,
`log_statement` foi elevado indevidamente.

Métricas padrão do CloudWatch, sem custo adicional e sem Performance Insights:
`CPUUtilization`, `FreeStorageSpace`, `DatabaseConnections`, `FreeableMemory`,
`ReadLatency`, `WriteLatency`, `ReadIOPS` e `WriteIOPS`.

## Telemetria agregada no New Relic

Com `rds_newrelic_telemetry_enabled = true`, o Terraform cria uma Lambda Python agendada
a cada cinco minutos. Ela lê as métricas padrão do namespace `AWS/RDS` e publica um evento
customizado `OficinaRdsSample` na Event API do New Relic. A configuração central grava
`newrelic_account_id` e a `newrelic_license_key` sensível no workspace HCP do banco; nenhuma
chave é armazenada no repositório.

O evento contém somente:

- ambiente e identificador da instância;
- CPU, conexões, armazenamento livre, memória livre, latências e IOPS;
- contagens de linhas com severidade `ERROR`, `FATAL` ou `PANIC`;
- contagem de linhas de consultas lentas na janela de cinco minutos.

A Lambda nunca encaminha mensagem bruta, SQL, parâmetro de bind, CPF, e-mail ou credencial.
O código está em `lambda/rds_newrelic_telemetry.py`; o agendamento e as preconditions estão
em `telemetry.tf`. A página e os alertas que consultam `OficinaRdsSample` são gerenciados
pelo workspace `oficina-newrelic-<ambiente>` do repositório Kubernetes.

Validação após apply:

```sql
SELECT latest(cpuUtilizationPercent), latest(databaseConnections),
       latest(freeStorageBytes), latest(postgresErrorCount)
FROM OficinaRdsSample
WHERE environment = '<ambiente>'
FACET databaseIdentifier
SINCE 30 minutes ago
```

A ausência de eventos dispara a condição `telemetria RDS ausente`. CPU, conexões,
armazenamento livre e erros PostgreSQL possuem condições específicas por ambiente.
