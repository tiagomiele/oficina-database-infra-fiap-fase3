# Validação do Terraform do banco

## Validação estática

```bash
terraform fmt -check -recursive
terraform init -backend=false -input=false
terraform validate
```

Quando disponível:

```bash
tflint --recursive
```

O CI também executa Trivy para configurações críticas e Gitleaks.

## Plan remoto

O plan real depende de:

- credenciais temporárias válidas do AWS Academy;
- workspace HCP Terraform configurado;
- outputs reais da VPC, subnets privadas e security group do EKS;
- senha do banco cadastrada como variável sensível.

Execute o workflow manual `Terraform plan` e confirme:

- uma instância RDS PostgreSQL privada;
- armazenamento criptografado;
- DB subnet group com ao menos duas subnets;
- entrada na porta 5432 somente para security groups autorizados;
- ausência de senha nos outputs;
- nenhum recurso IAM criado.

O apply não faz parte da validação estática e exige aprovação separada.
