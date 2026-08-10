# ADR 0003 — Observabilidade por logs do PostgreSQL no CloudWatch

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

## Consequências

- a evidência de observabilidade é reprodutível por CLI, sem console e sem recurso pago
  (ver [`../observability.md`](../observability.md));
- a análise de índices depende de `EXPLAIN` manual, já que não há Performance Insights;
- o log não serve para auditoria de dados: quem alterou o quê é responsabilidade do log
  da aplicação, correlacionado por `correlation_id`;
- elevar `log_statement` passa a gravar dado pessoal e é tratado como exceção
  documentada, não como configuração normal.

## Alternativas descartadas

- **`log_statement = "all"`**: gravaria dado pessoal no CloudWatch e multiplicaria custo
  de ingestão.
- **Performance Insights ligado por padrão**: custo e cota sem necessidade em
  `db.t3.micro`.
- **Enhanced Monitoring**: exige role IAM dedicada, proibido no AWS Academy.
- **pgaudit**: extensão adicional, mais volume de log e nenhuma exigência da fase que a
  justifique.
- **Agente externo (por exemplo New Relic) apontando para o banco**: acrescentaria
  credencial e custo sem cobrir nada que os logs e as métricas padrão já cobrem.
