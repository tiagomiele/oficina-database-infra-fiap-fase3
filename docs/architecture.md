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
- outputs não sensíveis para integração.

## Estados

Homologação e produção utilizam workspaces/estados HCP Terraform independentes. Os outputs `vpc_id`, `private_subnet_ids` e `eks_cluster_security_group_id` do repositório Kubernetes são cadastrados como variáveis nos workspaces do banco.

## Segurança

- banco sem acesso público;
- senha fornecida como variável sensível;
- tráfego liberado somente para origens autorizadas;
- outputs não exibem senha;
- destroy e snapshots seguirão a estratégia do ambiente acadêmico.
