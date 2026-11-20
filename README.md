# Waiting Room App — Workshop 5

Flutter waiting room app with SQLite as its local source of truth, optional
Supabase synchronization, and optional client geolocation. Adding and removing
clients updates the local queue immediately; pending changes are retried when
the app starts or a new client is added while Supabase is available.

## Run the app

Install the Flutter SDK, then run:

```sh
flutter pub get
flutter run
```

Without Supabase credentials, the app runs in local-only mode. To enable remote
sync, create a Supabase project, enable anonymous sign-in, run
[`supabase/schema.sql`](supabase/schema.sql), then pass the project URL and
publishable/anon key at launch:

```sh
flutter run --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLISHABLE_OR_ANON_KEY
```

The SQL migration adds `client_uuid` so this version can synchronize stable
offline-generated UUIDs while preserving an existing Workshop 4 `id` column.
Keep Supabase Row Level Security enabled and never put a `service_role` key in
the app.

## Location permissions

Android and iOS permission descriptions are included in the project. Location
is optional: if permission is denied, services are off, or the position cannot
be read, the client is still added and the UI displays “Location not captured”.

## Tests

The SQLite tests use an in-memory database. Run the suite with:

```sh
flutter test
```
