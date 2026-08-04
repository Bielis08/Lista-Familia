# Configuración de Supabase (Gratis) para Lista Familiar

## 1. Crear cuenta en Supabase

1. Ve a [https://supabase.com](https://supabase.com)
2. Haz clic en **"Start your project"** (gratis)
3. Inicia sesión con tu cuenta de GitHub (o crea una)
4. Acepta los términos del free tier

## 2. Obtener las claves de la base de datos

1. Una vez creado el proyecto, ve al menú lateral y haz clic en **Settings** (⚙️)
2. Selecciona **API**
3. Copia estos dos valores:
   - **Project URL** → `https://xxxxx.supabase.co`
   - **anon public** → la clave que empieza con `eyJ...` (ahora llamada **publishableKey**)

## 3. Configurar las claves en la app

Las credenciales se pasan como variables de entorno al compilar:

```bash
flutter run --dart-define=SUPABASE_URL=YOUR_URL --dart-define=SUPABASE_KEY=YOUR_KEY
```

Para builds de release:

```bash
flutter build apk --dart-define=SUPABASE_URL=YOUR_URL --dart-define=SUPABASE_KEY=YOUR_KEY
```

Si no se pasan las variables, se usan los valores por defecto en `lib/main.dart`.

## 4. Crear la tabla `products`

### Opción A: Desde la interfaz de Supabase

1. En el menú lateral de Supabase, haz clic en **Table Editor**
2. Haz clic en **New table**
3. Configura:
   - **Table name**: `products`
   - **Row ID**: `id` (tipo: `text`, no UUID)
4. Agrega las siguientes columnas:

| Column Name   | Type      | Nullable | Default     |
|---------------|-----------|----------|-------------|
| id            | text      | No       | (primary key)|
| name          | text      | No       |             |
| is_checked    | boolean   | No       | false       |
| quantity      | integer   | No       | 1           |
| created_by    | text      | Yes      |             |
| created_at    | timestamp | Yes      | now()       |
| position      | integer   | No       | 0           |

5. Haz clic en **Save**

### Opción B: Desde SQL (recomendado, más fiable)

1. Ve a **Database** → **Query Editor** en el menú lateral
2. Pega y ejecuta este SQL:

```sql
create table products (
  id text primary key,
  name text not null,
  is_checked boolean not null default false,
  is_important boolean not null default false,
  quantity integer not null default 1,
  created_by text,
  created_at timestamp default now(),
  position integer not null default 0
);

alter publication supabase_realtime add table products;
```

3. Haz clic en **Run**

### Si la tabla ya existe: añadir columnas quantity, position e is_important

Si ya tienes la tabla `products` creada sin las columnas `quantity`, `position` o `is_important`, ejecuta este SQL en el **Query Editor**:

```sql
alter table products add column if not exists quantity integer not null default 1;
alter table products add column if not exists position integer not null default 0;
alter table products add column if not exists is_important boolean not null default false;
```

## 5. Habilitar Realtime (sincronización en tiempo real)

Si usaste la Opción A, habilita Realtime:
1. Ve a **Database** → **Replication** en el menú lateral
2. En la sección **Publications**, haz clic en **publication** (o crea una nueva)
3. Asegúrate de que la tabla `products` esté incluida
4. También puedes habilitar Realtime desde **Table Editor** → `products` → **Enable Realtime**

Si usaste la Opción B, la tabla ya está añadida a Realtime con el comando SQL.

## 6. Configurar Row Level Security (RLS)

Para que los 4 usuarios puedan leer y escribir:

1. Ve a **Authentication** → **Policies** (o en Table Editor → `products` → **Policies**)
2. Crea las siguientes políticas:

**Para SELECT (leer):**
- Policy name: `Allow read`
- Operation: `SELECT`
- Role: `anon`
- Expression: `true` (permite leer a todos)

**Para INSERT (escribir):**
- Policy name: `Allow insert`
- Operation: `INSERT`
- Role: `anon`
- Expression: `true`

**Para UPDATE (actualizar):**
- Policy name: `Allow update`
- Operation: `UPDATE`
- Role: `anon`
- Expression: `true`

**Para DELETE (eliminar):**
- Policy name: `Allow delete`
- Operation: `DELETE`
- Role: `anon`
- Expression: `true`

## 7. Ejecutar la app

```bash
flutter pub get
flutter run
```

## Solución de errores al añadir productos

Si al añadir un producto obtienes un error, las causas más comunes son:

### 1. La tabla `products` no existe
Asegúrate de haber creado la tabla en Supabase (paso 4). Verifícalo en **Table Editor** del menú lateral.

### 2. Las políticas RLS bloquean la inserción
Ve a **Table Editor** → `products` → **Policies** y comprueba que existen políticas para `INSERT`, `SELECT`, `UPDATE` y `DELETE` con Role `anon` y expresión `true`.

### 3. La columna `id` es de tipo UUID
Si la tabla se creó con el tipo `uuid` para `id` (por defecto en Supabase), los inserts con texto fallarán. Asegúrate de que `id` sea de tipo `text`.

### 4. Ver los errores en tiempo real
Abre las **DevTools** del navegador (F12) y mira la pestaña **Console** para ver el error exacto de Supabase. También puedes revisar los logs en **Supabase Dashboard** → **Logs**.

### 5. El método `single()` falla con 0 resultados
Si la tabla está vacía y el insert no devuelve la fila, `single()` lanza un error. La app ahora usa `maybeSingle()` para manejar esto, pero asegúrate de tener las políticas RLS correctas.

## Límites del Free Tier de Supabase

- **Base de datos**: 500 MB
- **Usuarios activos/mes**: 50,000
- **Almacenamiento de archivos**: 1 GB
- **Funciones**: 100,000 invocaciones/mes

Más que suficiente para una familia de 4 personas.

## Nota sobre seguridad

La clave `publishableKey` (antes llamada `anon`) es pública y segura de compartir en el cliente. No da acceso de administración. Para producción, considera agregar autenticación con Supabase Auth para que cada usuario tenga su propia identidad.