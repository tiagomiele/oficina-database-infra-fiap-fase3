# ADR 0004 — Restrições impostas pelo AWS Academy

- Status: Aceito
- Data: 2026-08-10

## Contexto

O ambiente é o AWS Academy Learner Lab: credenciais temporárias que expiram com a
sessão, papel `LabRole` pré-existente, proibição prática de criar ou alterar recursos
IAM, crédito limitado e conjunto reduzido de serviços e regiões.

## Decisão

Tratar as restrições como requisito de projeto, não como problema temporário:

- nenhum recurso `aws_iam_*` neste repositório;
- nenhuma dependência de role criada por nós, inclusive para Enhanced Monitoring;
- evitar `data source` que exija permissão bloqueada; a rede entra por variável, a
  partir dos outputs do repositório de Kubernetes;
- state remoto no HCP Terraform, para sobreviver ao fim da sessão do laboratório;
- credencial validada com `aws sts get-caller-identity` antes de qualquer comando
  Terraform nos workflows, com falha explícita em credencial ausente ou expirada;
- versão principal do PostgreSQL fixada e suportada;
- `deletion_protection` e snapshot final desligados enquanto o ambiente é descartável,
  para que o `destroy` de fim de sessão não falhe.

## Consequências

- `ExpiredToken` é a falha operacional mais comum e tem procedimento próprio em
  [`../troubleshooting.md`](../troubleshooting.md);
- as três credenciais (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`,
  `AWS_SESSION_TOKEN`) precisam ser renovadas a cada sessão por uma execução do script
  central, que atualiza o Variable Set HCP e os GitHub Environments;
- os recursos têm vida curta: cada validação recria o banco a partir do zero e as
  migrations do Flyway rodam de novo;
- o endpoint do banco muda a cada recriação, então nenhum endpoint pode ser tratado como
  estável ou publicado como ativo.

## Alternativas descartadas

- **OIDC entre GitHub Actions e AWS**: exigiria criar provider e role IAM.
- **Usuário IAM de longa duração**: proibido e inseguro no contexto do laboratório.
- **State local versionado**: perderia o state entre sessões e exporia dado sensível.
