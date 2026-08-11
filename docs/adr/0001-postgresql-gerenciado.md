# ADR 0001 — PostgreSQL gerenciado no Amazon RDS

- Status: Aceito
- Data: 2026-08-10

## Contexto

O domínio da oficina é transacional e fortemente relacional: cliente, veículo, ordem de
serviço, orçamento com versões, estoque com saldo e histórico, notas fiscais com chave
natural composta e conta corrente. As invariantes mais importantes — saldo de estoque
não negativo, uma única etapa de status aberta por ordem de serviço, unicidade do
documento do cliente — precisam valer inclusive sob concorrência, com duas aplicações
distintas escrevendo no mesmo dado (o backend no EKS e a Lambda de autenticação).

A infraestrutura roda no AWS Academy Learner Lab, com credenciais temporárias, sem
permissão para criar recursos IAM e com crédito limitado.

## Decisão

Usar **Amazon RDS PostgreSQL 16**, provisionado por Terraform, em subnets privadas.

Motivos:

- transações ACID e constraints declarativas (`CHECK`, `UNIQUE`, FK composta) movem as
  invariantes para o banco, não apenas para o código;
- índices únicos parciais resolvem duas exigências do domínio de forma direta: uma única
  etapa de status aberta por OS e unicidade do CPF normalizado apenas entre clientes
  ativos;
- coluna gerada `STORED` (`documento_normalizado`) dá unicidade independente de máscara
  sem duplicar regra na aplicação;
- serviço gerenciado elimina o esforço de patch, backup e recuperação, que não cabe no
  escopo da disciplina;
- PostgreSQL é suportado no Learner Lab na classe `db.t3.micro`, elegível ao free tier.

## Consequências

- o schema evolui por migrations Flyway versionadas no repositório do backend, nunca por
  alteração manual;
- este repositório entrega o serviço e a configuração, não o schema;
- a versão principal fica fixada (`db_engine_version = "16"`), com upgrade menor
  automático habilitado;
- a família do parameter group (`postgres16`) acompanha a versão principal: mudar de
  major exige alterar as duas coisas juntas.

## Alternativas descartadas

- **DynamoDB**: modelo de acesso do domínio é relacional e exige junção e agregação por
  período; emular FK e unicidade composta na aplicação aumentaria o risco de dado
  inconsistente.
- **Aurora Serverless v2**: custo mínimo por ACU acima do free tier e disponibilidade
  irregular no Learner Lab.
- **PostgreSQL em contêiner no EKS**: exigiria gerenciar volume, backup e alta
  disponibilidade manualmente, e o banco morreria junto com o cluster descartável.
- **MySQL**: sem índice único parcial nem coluna gerada com a mesma flexibilidade,
  justamente os recursos usados pelo modelo.
