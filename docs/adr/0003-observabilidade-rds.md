# ADR 0003 — Observabilidade RDS por CloudWatch e eventos sanitizados no New Relic

- Status: Aceito
- Data: 2026-08-10

## Contexto

A validação final precisa comprovar que o backend no EKS e a Lambda de autenticação
alcançaram um banco privado, e precisa sustentar a revisão de índices com dado real de
duração de consulta. O banco guarda dados pessoais de clientes (nome, documento,
e-mail, telefone), então log verboso é um risco, não uma vantagem. O orçamento do
Learner Lab é limitado e a ingestão do CloudWatch é cobrada por volume.

## Decisão

Exportar o log `postgresql` para o CloudWatch Logs, de forma configurável, com o
conjunto mínimo de parâmetros que sustenta a evidência:

- `log_connections` e `log_disconnections` ativos — é a evidência de conectividade;
- `log_min_duration_statement = 1000` ms — somente consulta lenta;
- `log_statement = "ddl"` — nunca o SQL de dados;
- `log_parameter_max_length = 0` e `log_parameter_max_length_on_error = 0` — nenhum
  parâmetro de bind, portanto nenhum CPF no log;
- `log_lock_waits` ativo — expõe contenção no `SELECT ... FOR UPDATE` do numerador da OS;
- log group criado pelo Terraform apenas para aplicar retenção.

Performance Insights e Enhanced Monitoring permanecem desligados por padrão, com
variáveis validadas para quem precisar ligar.

Uma Lambda Python agendada a cada cinco minutos consulta métricas padrão de `AWS/RDS` e
conta somente linhas de erro e consulta lenta no CloudWatch Logs. Ela publica o evento
`OficinaRdsSample` no New Relic sem credencial do banco, SQL, parâmetros ou mensagem bruta.
A Event API usa uma License key sensível mantida no HCP Terraform.

## Consequências

- a evidência de observabilidade é reprodutível por CLI, sem console e sem recurso pago
  (ver [`../observability.md`](../observability.md));
- a análise de índices depende de `EXPLAIN` manual, já que não há Performance Insights;
- o log não serve para auditoria de dados: quem alterou o quê é responsabilidade do log
  da aplicação, correlacionado por `correlation_id`;
- elevar `log_statement` passa a gravar dado pessoal e é tratado como exceção
  documentada, não como configuração normal;
- dashboard e alertas recebem CPU, conexões, armazenamento, memória, latências, IOPS e
  contagens agregadas, sem permitir consulta aos dados funcionais do PostgreSQL.

## Alternativas descartadas

- **`log_statement = "all"`**: gravaria dado pessoal no CloudWatch e multiplicaria custo
  de ingestão.
- **Performance Insights ligado por padrão**: custo e cota sem necessidade em
  `db.t3.micro`.
- **Enhanced Monitoring**: exige role IAM dedicada, proibido no AWS Academy.
- **pgaudit**: extensão adicional, mais volume de log e nenhuma exigência da fase que a
  justifique.
- **Agente externo apontando diretamente para o banco**: acrescentaria credencial e
  acesso à rede privada. O coletor adotado lê somente APIs CloudWatch com a `LabRole`.
- **Encaminhar logs brutos ao New Relic**: aumentaria custo e risco de vazamento de SQL ou
  dados pessoais; somente contagens sanitizadas são publicadas.
