# Análise do Projeto (lms_admin)

## Visão Geral
- Projeto Flutter (web/desktop/mobile) com gerenciamento de estado via `flutter_riverpod`.
- Integrações principais com Firebase: `cloud_firestore`, `firebase_auth`, `firebase_storage`, e `firebase_ui_firestore`.
- Inicialização do Firebase em `lib/main.dart` usando `DefaultFirebaseOptions.currentPlatform` de `lib/firebase_options.dart`.
- Uso pontual de HTTP para verificação de licença em `lib/services/api_service.dart`.

## Existe backend?
- Não há backend próprio (server-side) no repositório.
- O app funciona como um cliente que consome serviços gerenciados:
  - Backend-as-a-Service: Firebase (Auth, Firestore, Storage).
  - Endpoint externo público para verificação de compra: `https://mrb-lab.com/wp-json/envato/v1/verify-purchase/{code}` em `APIService.verifyPurchaseCode()`.
- Não foram encontrados diretórios/arquivos típicos de backend como `server/`, `functions/` (Cloud Functions) ou APIs customizadas no repo.

## Padrão de Projeto / Arquitetura
- Camadas lógicas organizadas por domínios e serviços, com forte uso de Riverpod:
  - Estados e provedores distribuídos em `lib/tabs/**` e `lib/providers/**` (ex.: `app_setting_providers.dart`).
  - Serviços: `lib/services/` contém `FirebaseService`, `AuthService`, `APIService` (separação de integrações).
  - Modelos: `lib/models/**` com métodos estáticos para mapear Firestore (ex.: `Category.getMap`, `Course.fromFirestore`).
- Padrão predominante: "Feature-first" + Services + Models, com gerenciamento de estado por Riverpod. Não há um Clean Architecture formal completo, mas há separação razoável entre UI, estado e acesso a dados.
- Roteamento e tema centralizados em `lib/app.dart`, app iniciado em `lib/main.dart`.

## Integrações e Serviços
- `lib/services/firebase_service.dart`: CRUD avançado em coleções do Firestore, batch writes e queries com ordenação/filtros.
- `lib/services/auth_service.dart`: login por email/senha, logout, reautenticação e troca de senha com `EmailAuthProvider`.
- `lib/services/api_service.dart`: chamada HTTP pública (sem autenticação) para validação de licença (Envato/WP-JSON).

## Fluxo de Autenticação
- Inicialização: `Firebase.initializeApp(...)` em `lib/main.dart`.
- Login: `AuthService.loginWithEmailPassword(email, password)` em `lib/services/auth_service.dart`.
- Verificação de papéis: `AuthService.checkUserRole(uid)` lê `users/{uid}.role` no Firestore e mapeia para `UserRoles`.
- Logout: `AuthService.adminLogout()`.

## Persistência de Dados
- Principalmente Firestore:
  - Coleções: `users`, `courses`, `sections` (subcoleção), `lessons` (subcoleção), `categories`, `reviews`, `purchases`, `notifications`, `settings`, estatísticas (`user_stats`, `purchase_stats`).
  - Operações com `SetOptions(merge: true)` para upserts.
  - Contagens com `AggregateQuerySnapshot` (`count()`).
- Uploads de mídia em `Firebase Storage`: `FirebaseService.uploadImageToFirebaseHosting()` com `contentType: image/png`.

## Segurança – Achados
- Chaves web do Firebase estão em `lib/firebase_options.dart` (padrão para apps web). Observações:
  - Em apps web, a exposição das chaves é esperada, mas exige regras de segurança rigorosas no Firestore/Storage.
- Regras de segurança do Firestore/Storage não estão no repo (não avaliadas). Como o app executa operações administrativas (ex.: atualizar papéis de usuários, featured, ordenações), regras precisam restringir por papel/claim.
- `APIService.verifyPurchaseCode()` usa endpoint público sem autenticação, sujeito a:
  - MITM se não for HTTPS (o endpoint usa HTTPS – ok).
  - Rate limiting e validação do lado cliente inexistentes; resultado pode ser manipulado se backend confiar apenas no cliente.
- Upload de imagens: força `image/png`, mas não há validação de tamanho/tipo antes do upload além do mime metadata.
- Operações administrativas (ex.: `updateAuthorAccess`, `updateAppSettings`) são executadas direto do cliente.
  - Sem funções Cloud Functions ou backend intermediário, as regras do Firestore devem ser a única barreira.
- Dependências desatualizadas: `flutter pub get` mostrou várias libs com major updates disponíveis. Não é falha imediata, mas pode haver patches de segurança em versões novas.

## Segurança – Recomendações
1. Regras do Firestore/Storage
   - Exigir autenticação para todas as coleções sensíveis.
   - Restringir gravações administrativas a usuários com custom claims (`admin`, `author`). Evitar depender apenas de arrays de papéis no documento.
   - Validar schema básico nas regras (tipos, ranges, campos imutáveis como `created_at`, `author.id` etc.).
2. Custom Claims e Fluxo de Papéis
   - Gerenciar papéis via Custom Claims no Firebase Auth (setados via Cloud Functions ou backend), não apenas via `users/{uid}.role`.
   - Nas regras, checar `request.auth.token.admin == true` para operações administrativas.
3. Cloud Functions (opcional, recomendado)
   - Mover operações críticas para funções server-side (ex.: alterar papel de usuário, gerar estatísticas, verificação de licença) para reduzir superfície de ataque.
   - Implementar verificação de licença no servidor, com cache e rate limiting.
4. Uploads e Storage
   - Validar extensão/tamanho antes do upload no cliente; no servidor, se possível, reprocessar (ex.: imagens) e aplicar AV scanning para arquivos.
   - Regras do Storage limitando caminhos por papel/owner.
5. Proteções no Frontend Web
   - Revisar `web/index.html` e `web/manifest.json` para adicionar:
     - Content-Security-Policy (CSP) estrita (scripts do próprio domínio e dos SDKs necessários do Firebase).
     - `X-Content-Type-Options: nosniff`, `Referrer-Policy`, `Permissions-Policy` via cabeçalhos no host.
   - Remover logs sensíveis e mensagens de erro detalhadas em produção.
6. Gestão de Dependências
   - Executar `flutter pub outdated` e planejar upgrades de segurança (major updates testados em branch separada).
7. Telemetria e Auditoria
   - Registrar ações administrativas (quem alterou papéis, quem editou settings) – salvar logs em coleção de auditoria e/ou usar Analytics/Crashlytics.

## Itens Específicos (citações)
- Inicialização do Firebase: `lib/main.dart` linhas 8–12.
- Opções do Firebase (web): `lib/firebase_options.dart`.
- Autenticação: `lib/services/auth_service.dart`.
- Acesso a dados e operações administrativas: `lib/services/firebase_service.dart` (ex.: `updateAuthorAccess`, `updateAppSettings`, queries e batch updates).
- HTTP externo (licença): `lib/services/api_service.dart`.
- Estrutura e tema: `lib/app.dart`.

## Próximos Passos Sugeridos
- Definir e anexar regras do Firestore/Storage ao projeto; incluir `firestore.rules`/`storage.rules` no repo para versionamento.
- Introduzir Custom Claims e/ou Cloud Functions para operações administrativas.
- Adicionar CSP e cabeçalhos de segurança na configuração do host (Nginx/serviço de hospedagem).
- Criar testes básicos de integração para operações críticas (login, mudança de senha, CRUD principal).
- Planejar atualização de dependências com foco em correções de segurança.
