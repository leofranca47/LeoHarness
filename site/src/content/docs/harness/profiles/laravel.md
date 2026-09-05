---
title: "Profile: Laravel"
---
Adiciona guidance específico de Laravel. **Carregue junto com `@harness/profiles/php.md` e `@harness/profiles/generic.md`.**

## ⚠️ Aviso importante

**Este profile NÃO força uma arquitetura.** O Laravel é flexível. Cada projeto tem seu próprio padrão.

Antes de seguir qualquer recomendação deste profile:
1. **Verifique** o que o projeto já faz
2. **Siga** o padrão encontrado
3. **Só então** adapte para o que está aqui

Exemplos comuns de variações legítimas:

```
Projeto A: Controller → Service → Repository → Model
Projeto B: Controller → Action → Domain
Projeto C: Controller → UseCase → Eloquent direto
Projeto D: Livewire component direto no Model
```

**Todos são Laravel válido.** Siga o que existe.

## Quando carregar este profile

- Projeto tem `composer.json` com `laravel/framework`
- Pode ser Laravel tradicional, Livewire, Inertia, API-only, etc.
- Verifique: `php artisan --version`

## Detecções iniciais

```bash
# Versão do Laravel
php artisan --version

# Versão do PHP requerida
composer.json → "require": { "php": "^8.2" }

# Stack adicional
composer.json → "require" → laravel/sanctum, laravel/jetstream, inertiajs/inertia-laravel, livewire/livewire

# Banco
.env → DB_CONNECTION
config/database.php → connections

# Cache/queue
config/queue.php, config/cache.php
```

## Compatibilidade Laravel ↔ PHP

| Laravel | PHP mínimo | Notas |
|---|---|---|
| 11.x | 8.2 | Mais recente |
| 10.x | 8.1 | LTS, ainda muito usado |
| 9.x | 8.0 | LTS |
| 8.x | 7.3 | EOL — cuidado |
| < 8 | - | EOL |

**Se Laravel 9, NÃO use features do PHP 8.2.**
**Se Laravel 11, pode usar PHP 8.2+.**

## Estrutura típica (referência, não dogma)

```
app/
├── Console/
│   └── Commands/
├── Exceptions/
│   └── Handler.php
├── Http/
│   ├── Controllers/
│   │   ├── Controller.php (base)
│   │   ├── Auth/
│   │   └── Api/
│   ├── Middleware/
│   ├── Requests/ (Form Requests)
│   └── Resources/ (API Resources)
├── Jobs/
├── Listeners/
├── Mail/
├── Models/
├── Notifications/
├── Policies/
├── Providers/
├── Rules/
└── Services/  ← se o projeto usar

bootstrap/
config/
database/
├── factories/
├── migrations/
└── seeders/

public/
resources/
routes/
├── api.php
├── channels.php
├── console.php
└── web.php

storage/
tests/
├── Feature/
└── Unit/
```

**Projetos divergem.** Veja o que está no projeto antes de assumir.

## Padrões por componente

### Controllers

**Padrão Laravel moderno:** Single Action Controllers (apenas `__invoke`).

```php
class StoreUserController extends Controller
{
    public function __invoke(StoreUserRequest $request): UserResource
    {
        $user = $this->service->create($request->validated());
        return new UserResource($user);
    }
}
```

**Mas:** muitos projetos usam `UserController@store`. **Siga o que existe.**

### Validação

**Padrão moderno:** Form Request classes (`App\Http\Requests`).

```php
class StoreUserRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'name' => ['required', 'string'],
            'email' => ['required', 'email', 'unique:users'],
        ];
    }
}
```

**Mas:** projetos menores validam inline. **Siga o projeto.**

### Models (Eloquent)

- Não abuse de `Model::all()` ou queries sem escopo
- Use **scopes** para queries reutilizáveis
- Use **accessors/mutators** para transformações
- Use **casts** para tipos (não para lógica)
- **Evite** models gordos (regras de negócio devem sair do model)

### Migrations

- **Sempre** com `down()` reversível (ou `php artisan migrate:rollback` fica órfão)
- Use tipos do Schema Builder
- Nomeie com timestamp: `2024_01_15_120000_create_xxx_table.php`
- Cuidado com `change()` em colunas (requer `doctrine/dbal` em Laravel <10)
- Em Laravel 10+: nativo para alterações

### Jobs (Filas)

```php
class ProcessPodcast implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public function __construct(public Podcast $podcast) {}

    public function handle(AudioProcessor $processor): void
    {
        // ...
    }
}
```

**Padrões:**
- Filas pesadas: usar Redis ou SQS
- Filas com dependências pesadas: queue `specific-name`
- Falhas: configurar `$tries`, `$backoff`, `failed()` method

### Events e Listeners

- Events: dados + contexto (DTO ou Model)
- Listeners: side effects (log, email, broadcast, etc.)
- Descubra o que o projeto usa: `app/Providers/EventServiceProvider.php` ou auto-discovery (Laravel 11+)

### API Resources

```php
class UserResource extends JsonResource
{
    public function toArray($request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'email' => $this->when($request->user()->isAdmin(), $this->email),
            'created_at' => $this->created_at->toISOString(),
        ];
    }
}
```

**Use para formatar saída de API.** Não use para JSON manual em controllers.

### Cache

- Driver em `config/cache.php` / `.env` (`CACHE_DRIVER`)
- Redis é comum em produção
- Use `Cache::remember()` para queries caras
- Tags (`Cache::tags()`) para invalidação granular (apenas Redis/memcached)
- Em Laravel 11+: `Cache::flexible()` para TTLs elásticos

### Redis

- Conexões em `config/database.php` → `redis`
- Use para: cache, queue, session, rate limiting, broadcasting
- **Sentinela:** se múltiplos workers/ambientes, garanta mesma config de Redis

### Filas (Queues)

- Conexão em `config/queue.php` / `.env` (`QUEUE_CONNECTION`)
- Conexões comuns: `sync`, `database`, `redis`, `sqs`, `beanstalkd`
- Workers: `php artisan queue:work` (use `--tries`, `--backoff`, `--max-time`)
- **Em produção:** use supervisor/systemd para gerenciar workers
- **Falha:** jobs que falham vão para `failed_jobs` table (rode `queue:failed-table`)

## Comandos artisan comuns

**Só execute os que existem/precisar.** Não invente.

```bash
# Mais comuns
php artisan migrate
php artisan migrate:rollback
php artisan migrate:fresh --seed     # CUIDADO em prod
php artisan db:seed
php artisan queue:work
php artisan queue:listen
php artisan queue:failed
php artisan cache:clear
php artisan config:clear
php artisan route:clear
php artisan view:clear
php artisan optimize
php artisan optimize:clear
php artisan test
php artisan make:controller X
php artisan make:model X
php artisan make:migration create_x_table
php artisan make:job X
php artisan make:request StoreXRequest
php artisan make:resource XResource
php artisan make:policy XPolicy

# Úteis para debug
php artisan route:list
php artisan config:show
php artisan tinker
php artisan about              # Laravel 9+
```

## Testes

### Framework

- Laravel usa **PHPUnit** ou **Pest**
- Feature tests: `tests/Feature/` (testam rotas/integração)
- Unit tests: `tests/Unit/` (testam unidades isoladas)

### Comandos

```bash
php artisan test               # roda todos
php artisan test --filter=TestName
php artisan test tests/Feature/UserTest.php
./vendor/bin/pest              # se Pest
./vendor/bin/phpunit           # se PHPUnit
```

### Helpers úteis

- `$this->get('/url')`, `$this->post(...)`, etc.
- `$this->actingAs($user)` — autenticar
- `$this->assertDatabaseHas(...)` — verificar DB
- `RefreshDatabase` trait — reset DB entre testes
- `factory()` ou `Model::factory()` — criar fixtures

### Boas práticas

- 1 teste por comportamento
- Nomes descritivos: `test_user_can_register_with_valid_data`
- Use factories, não crie usuários manualmente repetidamente
- Mock external services (Http::fake(), Mail::fake(), Event::fake())

## Middleware

- Custom em `app/Http/Middleware/`
- Registrado em `app/Http/Kernel.php` (Laravel 10-) ou `bootstrap/app.php` (Laravel 11+)
- Use para: auth, throttle, CORS, logging, request modification

## Autorização

- Gates: closures simples em `AuthServiceProvider` (geralmente em `bootstrap/app.php` em L11)
- Policies: classes para autorização de models (`App\Policies\XPolicy`)
- Use `$user->can('action', $model)` ou `$this->authorize('action', $model)`

## Autenticação

- **Laravel UI / Breeze / Jetstream / Fortify**: escolha do projeto, siga
- **Sanctum**: tokens para SPA e API
- **Passport**: OAuth2 (raro, pesado)
- **Bcrypt:** `Hash::make()`, `Hash::check()` (nunca `md5`, `sha1`)

## Service Container & DI

- Laravel resolve dependências automaticamente via constructor
- Service Provider registra bindings customizados
- **Não** use `app()->make()` em código de feature se puder injetar

## Banco de dados

- **Eloquent:** ORM padrão
- **Query Builder:** para queries complexas, mais performático
- **Transações:** `DB::transaction(...)` ou manual
- **N+1:** cuidado, use eager loading (`with()`) ou `load()`

## Segurança

Laravel já trata muito, mas:

- **CSRF:** web routes já têm. Não desabilite.
- **SQL injection:** Eloquent + query builder usam prepared statements. Use-os.
- **XSS:** Blade escapa por default. Use `{!! !!}` só com dados confiáveis.
- **Mass assignment:** use `$fillable` ou `$guarded`
- **Rate limiting:** use `throttle` middleware
- **Validação:** nunca confie em input

## Erros comuns em projetos Laravel

1. **Queries em loop** (N+1) — sempre eager load
2. **`dd()` em produção** — use logs
3. **Validação no controller** — use Form Request
4. **Service com 500 linhas** — divida
5. **Model sem `$fillable`** — mass assignment vulnerability
6. **Migration sem `down()`** — rollback impossível
7. **Job sem `tries`** — falha silenciosa
8. **Cache sem invalidar** — dados velhos
9. **Env em produção errado** — `APP_DEBUG=true` é fatal
10. **Não rodar `optimize` em prod** — performance ruim

## Performance

- `php artisan optimize` em prod (config + route + view cache)
- OPcache habilitado
- Queue para tasks demoradas (não em request)
- Cache para queries caras
- Eager loading para evitar N+1
- Indexes em colunas usadas em WHERE/ORDER BY

## Quando parar de seguir este profile

- Projeto não é Laravel mas usa Illuminate components → trate como PHP genérico
- Laravel misturado com framework próprio → siga o framework próprio
- Livewire / Inertia / Filament: têm suas próprias convenções, siga docs deles

## Resumo

- **Laravel é flexível.** Não force arquitetura.
- **Compatibilidade Laravel ↔ PHP** é inegociável
- **Padrões do projeto > padrões deste profile**
- **Use o que já existe.** Não invente.