# Arquitetura do banco gerenciado

## Escopo

Este repositório provisionará o RDS PostgreSQL em subnets privadas da VPC criada pelo repositório Kubernetes.

## Componentes

- DB subnet group em duas zonas de disponibilidade;
- security group restrito ao EKS e à Lambda;
- RDS PostgreSQL 16;
- armazenamento com autoscaling limitado;
- backup, janela de manutenção e parâmetros;
- outputs não sensíveis para integração.

## Estados

Homologação e produção utilizarão workspaces/estados HCP Terraform independentes.

## Segurança

- banco sem acesso público;
- senha fornecida como variável sensível;
- tráfego liberado somente para origens autorizadas;
- outputs não exibem senha;
- destroy e snapshots seguirão a estratégia do ambiente acadêmico.
