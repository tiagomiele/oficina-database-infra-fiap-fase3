# ADR 0008 — CI/CD com apply sempre bloqueado por gate

- Status: Aceito
- Data: 2026-08-10

## Contexto

A fase exige um pipeline de validação e um caminho de deploy controlado por ambiente. O
risco no AWS Academy é o oposto do usual: não é deploy lento, é recurso criado sem
intenção consumindo crédito, ou pipeline que falha de forma confusa porque a credencial
temporária expirou.

## Decisão

Três workflows, com responsabilidades separadas:

1. **CI** (`ci.yml`), em todo Pull Request e push para `homolog`/`main`: validação
   estática e sem nuvem — documentação obrigatória, `terraform fmt`,
   `terraform init -backend=false`, `terraform validate`, verificação dos nomes de
   variável nos `*.tfvars.example`, coerência entre o diagrama ER e a documentação,
   TFLint, Trivy e Gitleaks. Nunca usa credencial AWS.
2. **Terraform plan** (`terraform-plan.yml`), manual, por ambiente: valida a credencial
   temporária com `aws sts get-caller-identity` e executa `plan` remoto no workspace HCP
   do ambiente escolhido.
3. **Terraform apply** (`terraform-apply.yml`), manual, com três barreiras
   independentes: a variável de ambiente `ENABLE_TERRAFORM_APPLY` precisa valer `true`,
   o input `confirm` precisa ser exatamente `APPLY-<ambiente>`, e o job roda em um
   GitHub Environment protegido por *required reviewers*, o que exige aprovação humana
   antes de qualquer chamada à AWS.

Nenhum workflow é acionado por push para executar apply, e o Auto apply do workspace HCP
permanece desligado. O destroy segue o mesmo padrão de gate, com input próprio.

## Consequências

- é impossível criar recurso na AWS por merge;
- credencial ausente ou expirada falha no primeiro passo, com mensagem explícita, em vez
  de quebrar no meio do Terraform;
- o CI é totalmente gratuito e roda sem segredo da AWS, então funciona mesmo com o
  laboratório desligado;
- quem executa o apply precisa de permissão no GitHub Environment, e a execução fica
  registrada com o aprovador.

## Alternativas descartadas

- **Apply automático no merge para `main`**: incompatível com credencial temporária e com
  o controle de custo.
- **Gate único (apenas aprovação de ambiente)**: uma aprovação distraída bastaria; a
  confirmação textual força a leitura do ambiente-alvo.
- **`terraform plan` no CI de Pull Request**: exigiria credencial AWS válida em todo PR,
  que expira, tornando o CI vermelho sem relação com a mudança.
