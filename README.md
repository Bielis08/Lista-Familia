# Lista Familia

Lista de la compra para la familia Montero Román. Permite la sincronización de la lista entre toda la familia.

## Features

- Añadir productos a la lista de la compra
- Marcar productos como comprados
- Editar nombre y cantidad de productos
- Eliminar productos individuales o todos los marcados
- Control de cantidades (incrementar / decrementar)
- Sincronización en tiempo real con Supabase para toda la familia

## Getting Started

### Prerequisites

- Flutter SDK (3.x+)
- Dart SDK
- A Supabase account

### Installation

1. Clone the repository:

```bash
git clone https://github.com/Bielis08/Lista-Familia.git
cd Lista-Familia
```

2. Install dependencies:

```bash
flutter pub get
```

3. Configure Supabase:

Open `lib/main.dart` and update the Supabase URL and publishable key with your own project credentials.

4. Run the app:

```bash
flutter run
```

## Supabase Setup

This app uses Supabase as its backend. The `products` table should have the following columns:

| Column       | Type    | Notes                    |
|-------------|---------|--------------------------|
| id          | text    | Primary key              |
| name        | text    | Product name             |
| is_checked  | boolean | Default: false           |
| quantity    | integer | Default: 1               |
| created_by  | text    | User who added the item  |
| created_at  | text    | ISO 8601 timestamp       |

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Author

**Biel Montero Román** — [bielmonteroroman08@gmail.com](mailto:bielmonteroroman08@gmail.com)