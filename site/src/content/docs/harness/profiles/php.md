---
title: "Profile: PHP"
---
Adiciona guidance específico de PHP ao profile genérico. **Carregue junto com `@harness/profiles/generic.md`.**

## Quando carregar este profile

- Projeto tem `composer.json`
- Não tem framework PHP específico (Laravel, Symfony, etc.) — para esses, use profiles dedicados
- Ou projeto é um framework/GLI próprio

## Detecções iniciais

Antes de tudo, verifique:

```bash
# Versão do PHP requerida
composer.json → "require": { "php": "^8.1" }

# Versão instalada
php --version

# Extensões usadas
composer.json → "require": { "ext-*": "*" }

# Versão do Composer
composer --version
```

## Versões suportadas

| Versão | Status |
|---|---|
| 8.4 | Última estável (use freely) |
| 8.3 | Estável |
| 8.2 | Estável |
| 8.1 | Em manutenção — evite features novas |
| 8.0 | EOL — cuidado |
| 7.4 e anteriores | EOL — não use features modernas |

**Se o projeto declara PHP 8.1, NÃO use:**
- Readonly classes (8.2)
- `true`, `false`, `null` como tipos independentes (8.2)
- Enumerações avançadas com métodos complexos (8.1 OK, mas cautela)
- Fibers (8.1 OK; se <8.1, nem pense)
- `array_is_list` (8.1+)
- `Readonly` em propriedades (8.1+; só promoção em 8.0)

**Para descobrir o que está disponível:**
- [php.net/manual/migration8X.php](https://www.php.net/manual/)
- `composer.json` do projeto tem a verdade

## PSR (PHP-FIG)

Siga as PSRs que o projeto declara. Padrões comuns:

| PSR | Tópico |
|---|---|
| PSR-1 | Basic coding standard |
| PSR-3 | Logger interface |
| PSR-4 | Autoloading (Composer usa) |
| PSR-7 | HTTP message interfaces |
| PSR-11 | Container interface |
| PSR-12 | Extended coding style |
| PSR-15 | HTTP handlers |
| PSR-16 | Simple cache |
| PSR-17 | HTTP factories |
| PSR-18 | HTTP client |

**PSR-12 é o padrão de estilo mais comum.**

## Composer

### Comandos comuns

```bash
composer install         # instala deps do composer.lock
composer update          # atualiza deps (cuidado em prod)
composer require pacote  # adiciona pacote
composer remove pacote   # remove
composer dump-autoload   # regenera autoload
composer script:name     # roda script definido em composer.json
```

### Antes de sugerir comando

```bash
cat composer.json | jq '.scripts'
```

**Só execute o que existir.**

### Autoloading

- PSR-4: padrão (Composer autoload)
- Confirme mapeamento em `composer.json` → `autoload`
- Respeite namespaces do projeto

## Convenções de código

### Tipagem

- **Strict types:** declare se o projeto usa (`declare(strict_types=1);`)
- **Type hints:** em parâmetros e retorno
- **Union types** (8.0+): use quando apropriado
- **Intersection types** (8.1+): use com cautela
- **`mixed`** (8.0+): evite quando puder ser mais específico
- **`never`** (8.1+): para funções que sempre lançam/saem

### Nomenclatura

| Elemento | Convenção |
|---|---|
| Classes | PascalCase |
| Interfaces | PascalCase, geralmente sufixo `Interface` (ou sem, segue projeto) |
| Traits | PascalCase, sufixo `Trait` |
| Métodos | camelCase |
| Propriedades | camelCase (ou snake_case em código legado) |
| Constantes | UPPER_SNAKE |
| Namespaces | PascalCase, plural para agrupamentos |
| Arquivos | PascalCase, um por classe (PSR-4) |

### Estrutura de classe

```php
<?php

declare(strict_types=1);

namespace App\Services;

use App\Contracts\OrderRepositoryInterface;
use App\Exceptions\OrderNotFound;

final class OrderService
{
    public function __construct(
        private readonly OrderRepositoryInterface $repository,
    ) {}

    public function find(int $id): Order
    {
        // ...
    }
}
```

**Siga a estrutura que o projeto usa.** Nem todo projeto usa `readonly` ou `final`.

## Tratamento de erros

### Exceções

- Exceções específicas (não genéricas)
- Exceções próprias do projeto (`App\Exceptions\X`)
- Construtor com mensagem clara
- Implemente interfaces úteis (`ContextAware`, `Renderable` se Laravel)

### Tipos de erro comuns

| Tipo | Como tratar |
|---|---|
| Validação | Exceção ou retorno tipado (siga o projeto) |
| Não encontrado | Exceção `NotFound` ou retornar null (siga o projeto) |
| Erro externo (API, DB) | Exceção + log |
| Erro inesperado | Exceção + log + (talvez) bubble up |

## Testes

### Frameworks comuns

| Framework | Quando |
|---|---|
| PHPUnit | Mais comum |
| Pest | Laravel moderno, popular em novos projetos |

### Antes de escrever teste

```bash
# Descobrir framework
cat composer.json | jq '.require["phpunit/phpunit"], .require["pestphp/pest"]'
```

### Comandos comuns

```bash
vendor/bin/phpunit              # PHPUnit direto
vendor/bin/pest                 # Pest direto
composer test                   # se houver script
```

### Convenção

- Testes em `tests/`
- Mapeamento PSR-4: `Tests\` namespace
- Unit: `tests/Unit/`
- Integration/Feature: `tests/Feature/`
- Fixtures em `tests/Fixtures/`

## Análise estática

| Ferramenta | Comando comum |
|---|---|
| PHPStan | `vendor/bin/phpstan analyse` |
| Psalm | `vendor/bin/psalm` |
| PHPCS | `vendor/bin/phpcs` |

**Só rode se existir no projeto.** Não adicione sem pedido.

## Formatação

| Ferramenta | Comando comum |
|---|---|
| PHP-CS-Fixer | `vendor/bin/php-cs-fixer fix` |
| Pint (Laravel) | `vendor/bin/pint` |
| PHPBF | `vendor/bin/bf` |

**Só rode se existir.** Deixe a ferramenta decidir.

## Segurança

- **SQL injection:** use prepared statements (PDO com placeholders, ou query builder)
- **XSS:** `htmlspecialchars()` em saída, ou templating engine
- **CSRF:** tokens em forms (frameworks geralmente já fazem)
- **Session fixation:** regenerar ID após login
- **Passwords:** `password_hash` / `password_verify` (bcrypt/argon2id)
- **File upload:** validar MIME real (não só extensão), limitar tamanho, não servir diretamente
- **Deserialization:** cuidado com `unserialize` em dados externos
- **Command injection:** nunca passe input externo para `exec`/`system`/`passthru` sem sanitizar

## Performance

- **OPcache:** garantido em prod, irrelevante em dev
- **Autoloader otimizado em prod:** `composer dump-autoload --optimize --no-dev`
- **Cache de config/routes:** próprio do framework
- **N+1 queries:** cuidado com loops que disparam queries
- **Conexões de DB:** persistent connection em long-running (workers), normal em FPM

## Debug

- `var_dump` / `print_r` / `dd`: **NUNCA** em código versionado
- Xdebug: útil em dev, desligado em prod
- Telescope (Laravel): registra queries, jobs, requests
- Logs: use Monolog (PSR-3)

## PHP idiomático

### Use

- `?? ` (null coalescing)
- `?->` (null safe operator, 8.0+)
- Match (8.0+) em vez de switch quando simples
- Named arguments (8.0+) quando melhora legibilidade
- Enums (8.1+) em vez de constantes mágicas
- Readonly properties (8.1+)
- Constructor property promotion (8.0+)
- First-class callable syntax (8.1+): `strlen(...)`

### Evite

- `@` para silenciar erros (em vez disso, trate)
- `extract()` (injection risk)
- `eval()` (NUNCA)
- `goto` (raramente apropriado)
- `$$var` (variable variables, confuso)
- Magic methods demais (`__get`, `__set`泛滥)

## Quando o profile não basta

Se o projeto é **Laravel**, **Symfony**, **Slim**, **CodeIgniter** ou outro framework:
- **PARE** de tratar como PHP genérico
- Carregue o profile dedicado (ex: `@harness/profiles/laravel.md`)
- O framework tem suas próprias convenções e este profile não as conhece

Se o projeto é WordPress, Drupal, Magento: são mundos à parte. Siga a documentação específica deles.

## Resumo

- **Compatibilidade PHP** é inegociável — verifique versão
- **Composer** é o gerenciador padrão
- **PSR-12** é o estilo mais comum (mas o projeto pode divergir)
- **Siga convenções do projeto**, não as deste profile
- **Testes, lint, análise estática** — só se o projeto já os usa