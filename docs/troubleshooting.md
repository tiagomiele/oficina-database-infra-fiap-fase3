# Troubleshooting

## `ExpiredToken` / `ExpiredTokenException`

```text
Error: error configuring Terraform AWS Provider: ... ExpiredToken:
The security token included in the request is expired
```

Causa: as credenciais do AWS Academy Learner Lab expiram junto com a sessão do
laboratório (algumas horas) e não são renováveis por refresh.

Correção:

1. abra o Learner Lab e clique em **Start Lab** até o indicador ficar verde;
2. abra **AWS Details → AWS CLI** e copie os três valores atuais;
3. atualize no workspace HCP Terraform, como variáveis de ambiente sensíveis:
   `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN`;
4. atualize também os secrets do GitHub Environment usado pelos workflows;
5. rode novamente o workflow.

O `AWS_SESSION_TOKEN` é obrigatório. Credencial sem token de sessão falha com
`InvalidClientTokenId`.

Os workflows deste repositório validam a credencial com
`aws sts get-caller-identity` antes de qualquer comando Terraform e falham com mensagem
explícita quando a credencial está ausente ou expirada, em vez de quebrar no meio do
`plan`.

## `InvalidClientTokenId` ou `SignatureDoesNotMatch`

Os três valores foram copiados de sessões diferentes. Copie os três de uma vez, da
mesma sessão.

## `AccessDenied` em `iam:CreateRole`

Algum recurso passou a exigir role IAM. Este repositório não cria IAM: verifique se
`monitoring_interval` foi elevado sem `monitoring_role_arn`. Deixe
`monitoring_interval = 0`.

## `DBSubnetGroupDoesNotCoverEnoughAZs`

`private_subnet_ids` contém subnets de uma única AZ. Use ao menos duas subnets privadas
em zonas diferentes, vindas dos outputs do repositório de Kubernetes.

## `InvalidParameterCombination: Cannot find version 16 for postgres`

A versão foi retirada da região. Consulte as versões disponíveis e ajuste
`db_engine_version`:

```bash
aws rds describe-db-engine-versions --engine postgres \
  --query 'DBEngineVersions[].EngineVersion' --output text
```

## `InvalidParameterValue: DeletionProtection` no destroy

O `destroy` falha enquanto `deletion_protection = true`. Aplique
`deletion_protection = false`, faça o apply dessa mudança e só então rode o destroy.
Não altere o padrão do repositório para contornar isso.

## `final_snapshot_identifier é obrigatório`

Mensagem da `precondition` do `aws_db_instance`. Com `skip_final_snapshot = false` é
preciso informar `final_snapshot_identifier`.

## `Error acquiring the state lock` no HCP Terraform

Uma execução anterior ficou pendente no workspace. Abra o workspace, cancele ou
descarte a run pendente e repita. Não force unlock local: o state é remoto.

## Conexão do backend expira (timeout) no EKS

Ordem de verificação:

1. `allowed_security_group_ids` inclui o security group real dos nós do EKS;
2. o pod está na mesma VPC das subnets privadas do DB subnet group;
3. a string de conexão usa o output `database_endpoint`, porta 5432;
4. a conexão usa TLS (`sslmode=require`), obrigatório por `rds.force_ssl = 1`;
5. o log group `postgresql` mostra a tentativa de conexão. Se não mostra, o tráfego não
   chegou ao banco e o problema é de rede, não de credencial.

## Erro de Flyway na subida do backend

Migrations pertencem ao backend. Este repositório entrega o banco vazio com o database
inicial `oficina`. Verifique usuário, senha e nome do banco antes de suspeitar da
infraestrutura.
