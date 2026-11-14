# Estoque Fácil – PIM IV (ADS / UNIP)

Sistema de controle de estoque com **SQL Server + API RESTful ASP.NET Core 8 + site web + app Flutter**.

```
pim_estoque/
├── database/                 Scripts SQL Server (tabelas, procedures, trigger)
│   ├── EstoqueDB.sql         Cria o banco
│   └── 02_objetos.sql        Tabelas, índices, sp_CadastrarItem, sp_MovimentarEstoque, trigger de auditoria
├── api/Estoque.Api/          API ASP.NET Core (Controllers → Services → Repositories → EF Core)
│   └── wwwroot/              Site (painel web) servido pela própria API
├── app/                      App Flutter (Android, Web, Windows)
└── iniciar_api.ps1           Sobe a API + site
```

## Abrir com 1 clique

Atalhos na Área de Trabalho (cópias também na pasta do projeto):

| Atalho | O que faz |
|---|---|
| **Estoque Fácil - App** | Liga a API (se precisar) e abre o app Flutter em janela de aplicativo (http://localhost:5000/app/) |
| **Estoque Fácil - Site** | Liga a API (se precisar) e abre o painel web no navegador (http://localhost:5000) |
| **Estoque Fácil - Código** | Abre a pasta do projeto no VS Code |
| **Estoque Fácil - Desligar servidor** | Encerra a API |

Os atalhos chamam `launcher\bin\EstoqueFacil.exe` (fonte em `launcher\EstoqueLauncher`), que:
- abre na hora se a API já estiver ligada (< 1 s);
- senão mostra a tela “Carregando…” e liga a API por trás (~7 s);
- recompila a API sozinho quando o código C# muda.

Depois de mudar o código do app Flutter, rode `flutter build web --base-href /app/` dentro de `app/`
para o atalho pegar a versão nova.

## Pré-requisitos

- .NET 8 SDK
- SQL Server (Express ou LocalDB)
- Flutter 3.x (para o app)

## 1. API + site

Clique no atalho **Estoque Fácil - Site**, ou pelo terminal:

```powershell
cd api\Estoque.Api
dotnet run --urls "http://*:5000"
```

Na primeira execução a API cria o banco **EstoqueDB**, roda `database/02_objetos.sql` e cadastra o administrador padrão:

| E-mail | Senha | Perfil |
|---|---|---|
| admin@estoque.com | Admin@123 | Admin |

- Site: http://localhost:5000
- Swagger: http://localhost:5000/swagger

A string de conexão fica em `api/Estoque.Api/appsettings.json` (`ConnectionStrings:Estoque`).
Se usar LocalDB, troque o servidor por `(localdb)\MSSQLLocalDB`.

## 2. App Flutter

```powershell
cd app
flutter pub get
flutter run -d chrome           # no navegador
flutter run -d emulator-5554    # emulador Android (usa http://10.0.2.2:5000)
```

No **celular físico**, toque no ícone de rede na tela de login e informe o IP do PC
(ex.: `http://192.168.0.10:5000`). O PC e o celular precisam estar na mesma rede, e o
firewall do Windows deve liberar a porta 5000.

## Endpoints

| Método | Endpoint | Auth |
|---|---|---|
| POST | /api/auth/register | – |
| POST | /api/auth/login | – (5 tentativas/min) |
| GET | /api/auth/me | JWT |
| GET | /api/itens?busca=&pagina=&tamanho= | JWT |
| GET | /api/itens/{id} | JWT |
| POST | /api/itens | JWT |
| PUT | /api/itens/{id} | JWT |
| PATCH | /api/itens/{id}/quantidade | JWT |
| DELETE | /api/itens/{id} | JWT (Admin) |
| GET | /api/itens/{id}/movimentacoes | JWT |

## Regras de negócio

- A quantidade nunca fica negativa (validação no app, na API e na procedure `sp_MovimentarEstoque` com `UPDLOCK`).
- A quantidade só muda por movimentação (ENTRADA/SAIDA); a quantidade inicial do cadastro vira uma ENTRADA “Estoque inicial”.
- Exclusão lógica (`Ativo = 0`), com histórico preservado; somente Admin remove.
- E-mail e código do item são únicos.
- Toda alteração na tabela `Itens` é registrada em `AuditoriaItens` pela trigger.
