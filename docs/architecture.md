# Arquitetura do banco gerenciado

## Escopo

Este repositório provisiona o RDS PostgreSQL em subnets privadas da VPC criada pelo repositório Kubernetes. A integração entre os states ocorre por inputs e outputs explícitos, sem compartilhar credenciais.

## Componentes

- DB subnet group em duas zonas de disponibilidade;
- security group restrito ao EKS e à Lambda;
- RDS PostgreSQL 16 privado e criptografado;
- armazenamento `gp3` com autoscaling limitado;
- backup, janela de manutenção e parâmetros de log;
- SSL obrigatório pelo parameter group;
- log groups do CloudWatch com retenção definida;
- Lambda EventBridge que publica métricas e contagens sanitizadas no New Relic;
- outputs não sensíveis para integração.

## Estados

Homologação e produção utilizam workspaces/estados HCP Terraform independentes. O script central lê `vpc_id`, `private_subnet_ids` e `eks_cluster_security_group_id` do state Kubernetes e sincroniza os workspaces do banco sem cópia manual.

## Segurança

- banco sem acesso público;
- senha fornecida como variável sensível;
- tráfego liberado somente para origens autorizadas;
- outputs não exibem senha;
- destroy e snapshots seguem a estratégia do ambiente acadêmico ([ADR 0006](adr/0006-backup-e-retencao.md));
- log conservador, sem parâmetros de bind e sem SQL de dados ([observabilidade](observability.md)).

## Observabilidade

Os logs do PostgreSQL vão para o CloudWatch Logs, com retenção curta e parâmetros
escolhidos para evidenciar conectividade e consulta lenta sem gravar dado pessoal. Uma
Lambda agendada consulta métricas padrão do RDS e somente contagens sanitizadas dos logs,
publicando `OficinaRdsSample` no New Relic. Performance Insights e Enhanced Monitoring
ficam desligados por padrão. Detalhes em [`observability.md`](observability.md) e no
[ADR 0003](adr/0003-observabilidade-rds.md).

## Decisões

O racional das escolhas está registrado nos [ADRs](adr/README.md): banco gerenciado,
modelagem relacional, observabilidade, restrições do AWS Academy, separação de
ambientes, backup e retenção, custo e gate de apply.
