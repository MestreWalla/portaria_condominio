# Estrutura MVC do Projeto

Este projeto segue o padrão MVC (Model-View-Controller) com a seguinte organização:

```
/lib
  /models         # Modelos de dados e regras de negócio
  /views         # Interfaces de usuário (páginas e widgets)
  /controllers   # Lógica de controle e gerenciamento de estado
  /core          # Utilitários, temas e configurações
  /services      # Serviços externos e integrações
```

## Responsabilidades

- **Models**: Classes de dados e regras de negócio
- **Views**: Interfaces de usuário e widgets
- **Controllers**: Gerenciamento de estado e lógica de controle
- **Core**: Configurações, temas e utilitários compartilhados
- **Services**: Integrações com serviços externos (Firebase, APIs, etc)
