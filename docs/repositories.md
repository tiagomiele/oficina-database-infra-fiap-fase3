# Repositórios relacionados

- [Aplicação principal e migrations](https://github.com/tiagomiele/oficina-backend-fiap-fase3)
- [Autenticação serverless](https://github.com/tiagomiele/oficina-auth-serverless-fiap-fase3)
- [Infraestrutura Kubernetes e rede](https://github.com/tiagomiele/oficina-kubernetes-infra-fiap-fase3)

A integração usa outputs não sensíveis e regras de rede explícitas. Credenciais são fornecidas por ambientes seguros.

| Direção | Valores |
|---|---|
| Kubernetes → banco | `vpc_id`, `private_subnet_ids`, `eks_cluster_security_group_id` |
| banco → aplicação e Lambda | `database_endpoint`, `database_port`, `database_name`, `jdbc_url` |

As migrations Flyway (`V1`, `V2`, `V3`, `V4`) vivem no repositório da aplicação e são a fonte
do modelo descrito em [`data-model.md`](data-model.md). Índices adicionais recomendados
por [`index-review.md`](index-review.md) também precisam de migration lá, nunca aqui.
