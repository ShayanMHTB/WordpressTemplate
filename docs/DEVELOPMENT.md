# DEVELOPMENT

## Development Philosophy

This WordPress template embraces modern development practices, clean code principles, and developer productivity. The workflow is designed for mid/senior developers who value control, consistency, and quality over quick fixes.

## Coding Standards

### PHP Standards

- **PSR-12**: Extended coding style guide
- **PSR-4**: Autoloading standard
- **PHP 8.0+**: Modern PHP features and syntax
- **Strong typing**: Type declarations where appropriate
- **Error handling**: Comprehensive exception handling

```php
<?php
declare(strict_types=1);

namespace YourNamespace\WordPress;

class ExampleClass
{
    public function processData(array $data): ?string
    {
        try {
            return $this->validateAndProcess($data);
        } catch (Exception $e) {
            error_log("Processing error: " . $e->getMessage());
            return null;
        }
    }
}
```

### WordPress Conventions

- **WordPress Coding Standards**: Following WordPress PHP standards where beneficial
- **Custom conventions**: Enhanced standards for better maintainability
- **Hook naming**: Consistent, descriptive hook names
- **Function prefixing**: Unique prefixes to avoid conflicts

## Project Structure Convention

### Theme Development

```
wp-content/themes/custom-theme/
├── assets/
│   ├── css/
│   ├── js/
│   ├── images/
│   └── fonts/
├── includes/
│   ├── classes/
│   ├── functions/
│   └── hooks/
├── templates/
│   ├── parts/
│   └── pages/
├── style.css
├── functions.php
└── index.php
```

### Plugin Development

```
wp-content/plugins/custom-plugin/
├── src/
│   ├── Admin/
│   ├── Frontend/
│   └── Core/
├── assets/
├── languages/
├── tests/
├── composer.json
└── custom-plugin.php
```

## Development Workflow

### Local Development Setup

```bash
# Start development environment
docker-compose up -d

# Access WordPress container for CLI operations
docker-compose exec wordpress bash

# Install WordPress via WP-CLI
wp core install --url=http://localhost:8080 --title="Dev Site" --admin_user=admin --admin_password=password --admin_email=dev@example.com

# Enable debug mode for development
wp config set WP_DEBUG true --raw
wp config set WP_DEBUG_LOG true --raw
```

### Git Workflow

```bash
# Feature branch workflow
git checkout -b feature/new-functionality
git add .
git commit -m "feat: implement new functionality"
git push origin feature/new-functionality

# Code review and merge
git checkout main
git merge feature/new-functionality
git push origin main
```

### Database Management

```bash
# Export database for version control
wp db export database/wordpress-backup.sql

# Import database changes
wp db import database/wordpress-backup.sql

# Search and replace URLs for environment changes
wp search-replace 'oldurl.com' 'newurl.com'
```

## Custom Conventions

### Naming Conventions

- **Functions**: `snake_case` with unique prefix
- **Classes**: `PascalCase` with namespace
- **Variables**: `camelCase` for complex, `snake_case` for simple
- **Constants**: `UPPER_SNAKE_CASE`
- **Files**: `kebab-case.php`

```php
// Function naming
function custom_theme_setup(): void {}
function ct_get_post_meta(int $post_id): array {}

// Class naming
class ThemeCustomizer extends WP_Customize_Control {}
class PostTypeManager implements PostTypeInterface {}

// Variable naming
$post_data = get_post($post_id);
$userPreferences = get_user_meta($user_id);
```

### File Organization

- **One class per file**: Single responsibility principle
- **Logical grouping**: Related functionality together
- **Clear hierarchy**: Intuitive directory structure
- **Autoloading**: PSR-4 compliant autoloading

### Code Documentation

```php
/**
 * Processes user data with validation and sanitization
 *
 * @param array $user_data Raw user input data
 * @param array $rules Validation rules to apply
 * @return array|WP_Error Processed data or error object
 * @throws InvalidArgumentException When rules are malformed
 * @since 1.0.0
 */
function process_user_data(array $user_data, array $rules): array|WP_Error
{
    // Implementation
}
```

## Testing Strategy

### Unit Testing

```php
<?php
use PHPUnit\Framework\TestCase;

class PostProcessorTest extends TestCase
{
    public function test_validates_post_data(): void
    {
        $processor = new PostProcessor();
        $result = $processor->validate(['title' => 'Test Post']);

        $this->assertTrue($result);
    }
}
```

### Integration Testing

```bash
# WordPress integration tests
wp scaffold plugin-tests custom-plugin
cd /tmp/wordpress-tests-lib
phpunit
```

### Browser Testing

- **Cross-browser compatibility**: Chrome, Firefox, Safari, Edge
- **Responsive design**: Mobile, tablet, desktop viewports
- **Accessibility**: WCAG 2.1 AA compliance
- **Performance**: Core Web Vitals optimization

## Asset Management

### CSS Organization

```scss
// SCSS structure
assets/scss/
├── abstracts/
│   ├── _variables.scss
│   ├── _mixins.scss
│   └── _functions.scss
├── base/
│   ├── _reset.scss
│   └── _typography.scss
├── components/
│   ├── _buttons.scss
│   └── _cards.scss
├── layout/
│   ├── _header.scss
│   └── _footer.scss
└── style.scss
```

### JavaScript Organization

```javascript
// Modern ES6+ JavaScript
class ThemeApp {
  constructor() {
    this.init();
  }

  init() {
    document.addEventListener('DOMContentLoaded', () => {
      this.setupEventListeners();
    });
  }

  setupEventListeners() {
    // Event handling logic
  }
}

new ThemeApp();
```

### Build Process

```json
{
  "scripts": {
    "build": "webpack --mode=production",
    "dev": "webpack --mode=development --watch",
    "lint:css": "stylelint assets/scss/**/*.scss",
    "lint:js": "eslint assets/js/**/*.js"
  }
}
```

## Performance Optimization

### PHP Performance

- **Opcode caching**: OPcache enabled
- **Memory management**: Efficient memory usage
- **Database queries**: Optimized queries, minimal database calls
- **Caching**: Object caching with Redis

### Frontend Performance

- **Asset optimization**: Minification and compression
- **Image optimization**: WebP format, lazy loading
- **Critical CSS**: Above-fold CSS inlined
- **JavaScript optimization**: Code splitting, lazy loading

## Debugging and Profiling

### Debug Tools

```php
// Custom debug functions
function debug_log($message, $context = []): void {
    if (defined('WP_DEBUG') && WP_DEBUG) {
        error_log(print_r([
            'message' => $message,
            'context' => $context,
            'trace' => debug_backtrace(DEBUG_BACKTRACE_IGNORE_ARGS, 3)
        ], true));
    }
}

// Query debugging
function debug_queries(): void {
    if (defined('WP_DEBUG') && WP_DEBUG) {
        global $wpdb;
        echo '<pre>' . print_r($wpdb->queries, true) . '</pre>';
    }
}
```

### Profiling

- **Xdebug**: Step debugging and profiling
- **Query Monitor**: WordPress-specific profiling
- **New Relic**: Application performance monitoring
- **Blackfire**: PHP profiling and optimization

## Code Quality

### Code Review Checklist

- [ ] Follows coding standards
- [ ] Includes proper documentation
- [ ] Has appropriate error handling
- [ ] Includes security considerations
- [ ] Performance optimized
- [ ] Accessible markup
- [ ] Mobile responsive
- [ ] Cross-browser tested

### Automated Quality Checks

```bash
# PHP CodeSniffer
phpcs --standard=WordPress-Extra wp-content/themes/custom-theme/

# PHPStan static analysis
phpstan analyse wp-content/themes/custom-theme/

# ESLint for JavaScript
eslint assets/js/

# Stylelint for CSS
stylelint assets/scss/**/*.scss
```

## Deployment Preparation

### Pre-deployment Checklist

- [ ] Environment variables configured
- [ ] Debug mode disabled
- [ ] Assets compiled and optimized
- [ ] Database migrations applied
- [ ] Security scan passed
- [ ] Performance benchmarks met
- [ ] Backup procedures verified
- [ ] Documentation updated

### Build Process

```bash
# Production build
npm run build

# Optimize images
imagemin assets/images/* --out-dir=dist/images

# Generate version hash for cache busting
wp-cli cache flush
```

This development guide ensures consistent, high-quality code while maintaining the flexibility and control that experienced developers demand.
