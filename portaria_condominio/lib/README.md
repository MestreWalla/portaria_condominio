# 🏢 Portaria Condomínio - Sistema de Gestão

## 📱 Sobre o Projeto

Sistema de gestão para portaria de condomínio desenvolvido em Flutter, seguindo o padrão de arquitetura MVC (Model-View-Controller). O aplicativo oferece funcionalidades completas para gerenciamento de moradores, visitantes, prestadores de serviço e comunicações internas.

## 🏗️ Arquitetura do Projeto

O projeto está organizado seguindo o padrão MVC, com uma estrutura clara e modular:

```
/lib
  ├── /models        # Modelos de dados e regras de negócio
  │   ├── morador_model.dart
  │   ├── visita_model.dart
  │   ├── prestador_model.dart
  │   ├── message_model.dart
  │   └── ...
  │
  ├── /views         # Interfaces de usuário (páginas e widgets)
  │   ├── /home
  │   │   ├── home_view.dart
  │   │   ├── moradores_view.dart
  │   │   └── ...
  │   ├── /chat
  │   │   ├── chat_view.dart
  │   │   └── chat_list_view.dart
  │   └── ...
  │
  ├── /controllers   # Lógica de controle e gerenciamento de estado
  │   ├── morador_controller.dart
  │   ├── chat_controller.dart
  │   └── ...
  │
  ├── /core          # Utilitários, temas e configurações
  │   ├── /theme
  │   │   └── app_theme.dart
  │   └── /utils
  │       ├── preferences.dart
  │       └── page_transitions.dart
  │
  ├── /services      # Serviços externos e integrações
  │   ├── notification_service.dart
  │   └── photo_registration_service.dart
  │
  └── /routes        # Configuração de rotas da aplicação
      └── app_routes.dart
```

## 📚 Componentes Principais

### 📋 Models
Responsáveis pela representação dos dados e regras de negócio:
- `morador_model.dart`: Dados dos moradores
- `visita_model.dart`: Registro de visitantes
- `prestador_model.dart`: Dados de prestadores de serviço
- `message_model.dart`: Mensagens do chat

### 🖥️ Views
Interface do usuário organizada por funcionalidades:
- **Home**: Views principais do aplicativo
- **Chat**: Sistema de comunicação interna
- **QRCode**: Leitura e geração de QR Codes
- **Settings**: Configurações do aplicativo

### 🎮 Controllers
Gerenciamento de estado e lógica de negócio:
- `morador_controller.dart`: Gestão de moradores
- `chat_controller.dart`: Controle do sistema de chat
- `auth_controller.dart`: Autenticação de usuários

### ⚙️ Core
Componentes fundamentais do sistema:
- **Theme**: Temas e estilos do aplicativo
- **Utils**: Utilitários e helpers

### 🔌 Services
Integrações e serviços externos:
- Notificações push
- Upload de fotos
- Integração com Firebase

## 🔧 Tecnologias Utilizadas

- **Flutter**: Framework de desenvolvimento
- **Firebase**: Backend e autenticação
- **Cloud Firestore**: Banco de dados
- **Firebase Storage**: Armazenamento de mídia
- **Firebase Auth**: Autenticação de usuários

## 🚀 Funcionalidades Principais

1. **Gestão de Moradores**
   - Cadastro e atualização de dados
   - Controle de acesso
   - Perfil com foto

2. **Controle de Visitantes**
   - Registro de visitas
   - Histórico de acessos
   - QR Code para entrada

3. **Sistema de Chat**
   - Comunicação entre moradores
   - Notificações em tempo real
   - Histórico de mensagens

4. **Prestadores de Serviço**
   - Cadastro de prestadores
   - Controle de acesso
   - Histórico de serviços

5. **Notificações**
   - Avisos importantes
   - Comunicados gerais
   - Notificações push

## 📱 Interface do Usuário

O aplicativo segue as diretrizes de Material Design, oferecendo:
- Design responsivo
- Temas claro e escuro
- Suporte a múltiplos idiomas
- Animações suaves
- Interface intuitiva

## 🔐 Segurança

- Autenticação segura via Firebase
- Controle de permissões por perfil
- Criptografia de dados sensíveis
- Backup automático de dados

## 🌐 Internacionalização

Suporte aos idiomas:
- 🇧🇷 Português (BR)
- 🇺🇸 Inglês (EN)
- 🇸🇦 Árabe (AR)
- 🇨🇳 Chinês (ZH)

## 🎨 Temas do Aplicativo

O aplicativo oferece uma variedade de temas elegantes, organizados em quatro categorias principais. Cada tema está disponível em versões clara e escura para melhor experiência do usuário.

### 🎨 Paletas de Cores

#### 🎯 Básico (Google Blue)
| Elemento | Modo Claro | Modo Escuro |
|----------|------------|-------------|
| Primária | <div style="background-color: #1A73E8; width: 100px; height: 20px; display: inline-block; border: 1px solid #000;"></div> | <div style="background-color: #1A73E8; width: 100px; height: 20px; display: inline-block; border: 1px solid #000; opacity: 0.8;"></div> |
| Variante Clara | <div style="background-color: #D2E3FC; width: 100px; height: 20px; display: inline-block; border: 1px solid #000;"></div> | <div style="background-color: #D2E3FC; width: 100px; height: 20px; display: inline-block; border: 1px solid #000; opacity: 0.8;"></div> |
| Variante Escura | <div style="background-color: #1557B0; width: 100px; height: 20px; display: inline-block; border: 1px solid #000;"></div> | <div style="background-color: #1557B0; width: 100px; height: 20px; display: inline-block; border: 1px solid #000; opacity: 0.8;"></div> |
| Superfície | <div style="background-color: #FFFFFF; width: 100px; height: 20px; display: inline-block; border: 1px solid #000;"></div> | <div style="background-color: #121212; width: 100px; height: 20px; display: inline-block; border: 1px solid #000;"></div> |
| Texto | <div style="background-color: #000000; width: 100px; height: 20px; display: inline-block; border: 1px solid #000;"></div> | <div style="background-color: #FFFFFF; width: 100px; height: 20px; display: inline-block; border: 1px solid #000;"></div> |

#### ❄️ Tons Frios

##### 🔷 Índigo
| Elemento | Modo Claro | Modo Escuro |
|----------|------------|-------------|
| Primária | <div style="background-color: #3F51B5; width: 100px; height: 20px; display: inline-block; border: 1px solid #000;"></div> | <div style="background-color: #3F51B5; width: 100px; height: 20px; display: inline-block; border: 1px solid #000; opacity: 0.8;"></div> |
| Variante Clara | <div style="background-color: #C5CAE9; width: 100px; height: 20px; display: inline-block; border: 1px solid #000;"></div> | <div style="background-color: #C5CAE9; width: 100px; height: 20px; display: inline-block; border: 1px solid #000; opacity: 0.8;"></div> |
| Variante Escura | <div style="background-color: #303F9F; width: 100px; height: 20px; display: inline-block; border: 1px solid #000;"></div> | <div style="background-color: #303F9F; width: 100px; height: 20px; display: inline-block; border: 1px solid #000; opacity: 0.8;"></div> |

##### 💜 Roxo
| Elemento | Modo Claro | Modo Escuro |
|----------|------------|-------------|
| Primária | <div style="background-color: #9C27B0; width: 100px; height: 20px; display: inline-block; border: 1px solid #000;"></div> | <div style="background-color: #9C27B0; width: 100px; height: 20px; display: inline-block; border: 1px solid #000; opacity: 0.8;"></div> |
| Variante Clara | <div style="background-color: #E1BEE7; width: 100px; height: 20px; display: inline-block; border: 1px solid #000;"></div> | <div style="background-color: #E1BEE7; width: 100px; height: 20px; display: inline-block; border: 1px solid #000; opacity: 0.8;"></div> |
| Variante Escura | <div style="background-color: #7B1FA2; width: 100px; height: 20px; display: inline-block; border: 1px solid #000;"></div> | <div style="background-color: #7B1FA2; width: 100px; height: 20px; display: inline-block; border: 1px solid #000; opacity: 0.8;"></div> |

##### 🌊 Azul
| Elemento | Modo Claro | Modo Escuro |
|----------|------------|-------------|
| Primária | <div style="background-color: #2196F3; width: 100px; height: 20px; display: inline-block; border: 1px solid #000;"></div> | <div style="background-color: #2196F3; width: 100px; height: 20px; display: inline-block; border: 1px solid #000; opacity: 0.8;"></div> |
| Variante Clara | <div style="background-color: #BBDEFB; width: 100px; height: 20px; display: inline-block; border: 1px solid #000;"></div> | <div style="background-color: #BBDEFB; width: 100px; height: 20px; display: inline-block; border: 1px solid #000; opacity: 0.8;"></div> |
| Variante Escura | <div style="background-color: #1976D2; width: 100px; height: 20px; display: inline-block; border: 1px solid #000;"></div> | <div style="background-color: #1976D2; width: 100px; height: 20px; display: inline-block; border: 1px solid #000; opacity: 0.8;"></div> |

#### 🌞 Tons Quentes

##### 🔥 Laranja
| Elemento | Modo Claro | Modo Escuro |
|----------|------------|-------------|
| Primária | <div style="background-color: #FF5722; width: 100px; height: 20px; display: inline-block; border: 1px solid #000;"></div> | <div style="background-color: #FF5722; width: 100px; height: 20px; display: inline-block; border: 1px solid #000; opacity: 0.8;"></div> |
| Variante Clara | <div style="background-color: #FFCCBC; width: 100px; height: 20px; display: inline-block; border: 1px solid #000;"></div> | <div style="background-color: #FFCCBC; width: 100px; height: 20px; display: inline-block; border: 1px solid #000; opacity: 0.8;"></div> |
| Variante Escura | <div style="background-color: #E64A19; width: 100px; height: 20px; display: inline-block; border: 1px solid #000;"></div> | <div style="background-color: #E64A19; width: 100px; height: 20px; display: inline-block; border: 1px solid #000; opacity: 0.8;"></div> |

##### ❤️ Vermelho
| Elemento | Modo Claro | Modo Escuro |
|----------|------------|-------------|
| Primária | <div style="background-color: #F44336; width: 100px; height: 20px; display: inline-block; border: 1px solid #000;"></div> | <div style="background-color: #F44336; width: 100px; height: 20px; display: inline-block; border: 1px solid #000; opacity: 0.8;"></div> |
| Variante Clara | <div style="background-color: #FFCDD2; width: 100px; height: 20px; display: inline-block; border: 1px solid #000;"></div> | <div style="background-color: #FFCDD2; width: 100px; height: 20px; display: inline-block; border: 1px solid #000; opacity: 0.8;"></div> |
| Variante Escura | <div style="background-color: #D32F2F; width: 100px; height: 20px; display: inline-block; border: 1px solid #000;"></div> | <div style="background-color: #D32F2F; width: 100px; height: 20px; display: inline-block; border: 1px solid #000; opacity: 0.8;"></div> |

#### 🌿 Natureza

##### 🌊 Teal
| Elemento | Modo Claro | Modo Escuro |
|----------|------------|-------------|
| Primária | <div style="background-color: #009688; width: 100px; height: 20px; display: inline-block; border: 1px solid #000;"></div> | <div style="background-color: #009688; width: 100px; height: 20px; display: inline-block; border: 1px solid #000; opacity: 0.8;"></div> |
| Variante Clara | <div style="background-color: #B2DFDB; width: 100px; height: 20px; display: inline-block; border: 1px solid #000;"></div> | <div style="background-color: #B2DFDB; width: 100px; height: 20px; display: inline-block; border: 1px solid #000; opacity: 0.8;"></div> |
| Variante Escura | <div style="background-color: #00796B; width: 100px; height: 20px; display: inline-block; border: 1px solid #000;"></div> | <div style="background-color: #00796B; width: 100px; height: 20px; display: inline-block; border: 1px solid #000; opacity: 0.8;"></div> |

##### 🌱 Verde
| Elemento | Modo Claro | Modo Escuro |
|----------|------------|-------------|
| Primária | <div style="background-color: #4CAF50; width: 100px; height: 20px; display: inline-block; border: 1px solid #000;"></div> | <div style="background-color: #4CAF50; width: 100px; height: 20px; display: inline-block; border: 1px solid #000; opacity: 0.8;"></div> |
| Variante Clara | <div style="background-color: #C8E6C9; width: 100px; height: 20px; display: inline-block; border: 1px solid #000;"></div> | <div style="background-color: #C8E6C9; width: 100px; height: 20px; display: inline-block; border: 1px solid #000; opacity: 0.8;"></div> |
| Variante Escura | <div style="background-color: #388E3C; width: 100px; height: 20px; display: inline-block; border: 1px solid #000;"></div> | <div style="background-color: #388E3C; width: 100px; height: 20px; display: inline-block; border: 1px solid #000; opacity: 0.8;"></div> |

### 🎭 Detalhes de Aplicação dos Temas

Cada tema é aplicado de forma consistente em toda a interface do aplicativo:

#### Elementos Primários
- Barra de navegação superior
- Botões de ação principal
- Links ativos
- Elementos de destaque

#### Elementos Secundários
- Botões secundários
- Ícones interativos
- Elementos de progresso
- Bordas ativas

#### Superfícies
- Fundo do aplicativo
- Cartões e painéis
- Modais e diálogos
- Menus suspensos

#### Texto e Ícones
- Textos principais e secundários
- Ícones e símbolos
- Rótulos e legendas
- Mensagens e notificações

Para alterar o tema, acesse as configurações do aplicativo e escolha a combinação que melhor se adequa às suas preferências. Cada tema foi cuidadosamente projetado para garantir contraste adequado e legibilidade em ambos os modos claro e escuro.
