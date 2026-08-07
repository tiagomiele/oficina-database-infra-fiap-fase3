variable "aws_region" {
  description = "Região AWS usada pelo Learner Lab."
  type        = string
  default     = "us-west-2"
}

variable "project_name" {
  description = "Prefixo dos recursos."
  type        = string
  default     = "oficina"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,20}$", var.project_name))
    error_message = "project_name deve usar letras minúsculas, números ou hífen."
  }
}

variable "environment" {
  description = "Ambiente lógico associado à branch e ao workspace HCP Terraform."
  type        = string
  default     = "homolog"

  validation {
    condition     = contains(["homolog", "production"], var.environment)
    error_message = "environment deve ser homolog ou production."
  }
}

variable "vpc_id" {
  description = "ID da VPC criada pelo repositório Kubernetes."
  type        = string

  validation {
    condition     = can(regex("^vpc-[0-9a-f]+$", var.vpc_id))
    error_message = "vpc_id deve ser um ID de VPC válido."
  }
}

variable "private_subnet_ids" {
  description = "Subnets privadas, em ao menos duas zonas, criadas pelo repositório Kubernetes."
  type        = list(string)

  validation {
    condition = (
      length(var.private_subnet_ids) >= 2 &&
      length(distinct(var.private_subnet_ids)) == length(var.private_subnet_ids) &&
      alltrue([for id in var.private_subnet_ids : can(regex("^subnet-[0-9a-f]+$", id))])
    )
    error_message = "Informe ao menos duas subnets privadas válidas e distintas."
  }
}

variable "allowed_security_group_ids" {
  description = "Security groups autorizados a acessar o PostgreSQL, inicialmente o SG do EKS."
  type        = set(string)

  validation {
    condition = (
      length(var.allowed_security_group_ids) >= 1 &&
      alltrue([for id in var.allowed_security_group_ids : can(regex("^sg-[0-9a-f]+$", id))])
    )
    error_message = "Informe ao menos um security group válido."
  }
}

variable "db_name" {
  description = "Nome do banco inicial."
  type        = string
  default     = "oficina"

  validation {
    condition     = can(regex("^[A-Za-z][A-Za-z0-9_]{0,62}$", var.db_name))
    error_message = "db_name deve começar com letra e conter somente letras, números ou underscore."
  }
}

variable "db_username" {
  description = "Usuário master do PostgreSQL."
  type        = string
  default     = "oficina_admin"

  validation {
    condition     = can(regex("^[A-Za-z][A-Za-z0-9_]{0,62}$", var.db_username))
    error_message = "db_username deve começar com letra e conter somente letras, números ou underscore."
  }
}

variable "db_password" {
  description = "Senha master fornecida como variável sensível no HCP Terraform."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.db_password) >= 16
    error_message = "db_password deve possuir ao menos 16 caracteres."
  }
}

variable "db_engine_version" {
  description = "Versão principal do PostgreSQL aceita no AWS Academy."
  type        = string
  default     = "16"
}

variable "db_instance_class" {
  description = "Classe da instância RDS."
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Armazenamento inicial em GiB."
  type        = number
  default     = 20

  validation {
    condition     = var.db_allocated_storage >= 20
    error_message = "db_allocated_storage deve ser pelo menos 20 GiB para gp3."
  }
}

variable "db_max_allocated_storage" {
  description = "Limite do autoscaling de armazenamento em GiB."
  type        = number
  default     = 40
}

variable "multi_az" {
  description = "Ativa réplica Multi-AZ. Mantida false no Learner Lab para reduzir consumo."
  type        = bool
  default     = false
}

variable "backup_retention_days" {
  description = "Retenção de backups automáticos."
  type        = number
  default     = 7

  validation {
    condition     = var.backup_retention_days >= 1 && var.backup_retention_days <= 35
    error_message = "backup_retention_days deve estar entre 1 e 35."
  }
}

variable "deletion_protection" {
  description = "Proteção contra exclusão. Deve permanecer false durante as sessões descartáveis do Academy."
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Permite destroy sem snapshot final no ambiente acadêmico."
  type        = bool
  default     = true
}

variable "final_snapshot_identifier" {
  description = "Nome do snapshot final quando skip_final_snapshot for false."
  type        = string
  default     = null
  nullable    = true
}
