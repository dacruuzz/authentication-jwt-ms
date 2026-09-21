terraform {
  cloud {
    organization = "dacruuzz-org"
    workspaces {
      name = "authentication-jwt-ms"
    }
  }
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0" # Utilizando a versão estável mais recente
    }
  }
}

variable "github_token" {
  description = "Personal Access Token do GitHub com permissão de administração no repositório"
  type        = string
  sensitive   = true
}

provider "github" {
  token = var.github_token
}

# Referência ao seu repositório existente no GitHub
# Substitua pelo nome exato do seu repositório atual
data "github_repository" "meu_projeto" {
  full_name = "dacruuzz/authentication-jwt-ms"
}

# Configuração unificada de proteção para as 2 branches desejadas
resource "github_branch_protection" "regras_ambientes" {
  for_each = toset(["master", "develop"])

  repository_id = data.github_repository.meu_projeto.node_id
  pattern       = each.value

  # 1. Require a pull request before merging
  required_pull_request_reviews {
    required_approving_review_count = 1
    dismiss_stale_reviews           = true
  }

  # 2 e 3. Require status checks to pass & Require branches to be up to date before merging
  required_status_checks {
    strict   = true
    contexts = [] # preencher com o nome do job (ex: "Build & Tests") quando o CI estiver rodando
  }

  # 4. Require conversation resolution before merging
  require_conversation_resolution = true

  # 5. Aplicar as regras até para admins (inclusive você)
  enforce_admins = true

  # 6. Bloquear force-push e deleção das branches protegidas
  allows_force_pushes = false
  allows_deletions    = false

  # 7. Exigir histórico linear (squash/rebase, sem merge commits)
  required_linear_history = true

  # 8. Exigir commits assinados (GPG/SSH)
  require_signed_commits = true
}
