# ADR 0008 — CI/CD automático por merge com gate de produção

- Status: Aceito
- Data: 2026-08-10

## Contexto

A fase exige um pipeline de validação e um caminho de deploy controlado por ambiente. O
risco no AWS Academy é o oposto do usual: não é deploy lento, é recurso criado sem
intenção consumindo crédito, ou pipeline que falha de forma confusa porque a credencial
temporária expirou.

## Decisão

Três workflows, com responsabilidades separadas:

1. **CI** (`ci.yml`), em todo push e em Pull Requests para `homolog`/`main`: validação
   estática e sem nuvem — documentação obrigatória, `terraform fmt`,
   `terraform init -backend=false`, `terraform validate`, verificação dos nomes de
   variável nos `*.tfvars.example`, coerência entre o diagrama ER e a documentação,
   TFLint, Trivy e Gitleaks. Nunca usa credencial AWS.
2. **Terraform plan** (`terraform-plan.yml`), automático nos Pull Requests que alteram
   a infraestrutura e manual para recuperação. Usa environments sem reviewers e nunca
   executa apply.
3. **Terraform deploy** (`terraform-apply.yml`), iniciado por push em `homolog` ou
   `main`: resolve o workspace, exige `ENABLE_TERRAFORM_APPLY=true`, valida a sessão AWS,
   executa o plan autoritativo e então apply. Homologação não possui gate humano;
   produção concentra uma única aprovação no GitHub Environment `production`.

O `workflow_dispatch` permanece somente para repetir o apply durante bootstrap ou
recuperação, a partir da branch correspondente. Destroy é manual via Terraform CLI e
não faz parte do GitHub Actions. O Auto apply do workspace HCP permanece desligado.

## Consequências

- o merge em `homolog` inicia a entrega automaticamente, sem aprovações repetidas;
- o merge em `main` registra uma única aprovação antes do deploy de produção;
- credencial ausente ou expirada falha no primeiro passo, com mensagem explícita, em vez
  de quebrar no meio do Terraform;
- o CI é totalmente gratuito e roda sem segredo da AWS, então funciona mesmo com o
  laboratório desligado;
- destroy exige execução operacional manual e confirmação interativa do Terraform.

## Alternativas descartadas

- **Apply somente manual**: não atende ao requisito de pipeline iniciado pelo merge.
- **Gate em homologação**: repete uma decisão já representada pelo merge protegido e torna
  o bootstrap desnecessariamente lento.
- **Destroy no GitHub Actions**: não é requisito da fase e amplia o risco operacional.
- **Plan usando credencial AWS do runner**: a sessão expira; o plan remoto usa as variáveis
  temporárias já sincronizadas no workspace HCP.
