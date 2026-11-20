# Prompts AI - Workshop 4

Ce fichier conserve les prompts utilisés pour réaliser le TP Flutter
**Build a Real-Time Waiting Room with Flutter & Supabase**.

> Aucune clé Supabase ou donnée secrète ne doit être ajoutée dans ce fichier.

## 1. Copier le projet de départ

> Copier le contenu du dépôt `https://github.com/LindaWadaa/fluttertp3.git`
> directement dans `waiting_room_app4`, sans créer de dossier intermédiaire.

## 2. Comprendre et réaliser le TP

> Guide-moi pour travailler ce TP étape par étape. Examine le projet existant,
> explique les étapes manquantes, réalise les modifications nécessaires et
> vérifie le formatage, l'analyse et les tests.

## 3. Workshop 4 : Waiting Room temps réel

> Transformer l'application Flutter locale en système distribué avec Supabase.
> Utiliser `supabase_flutter`, remplacer l'état local par une base Supabase,
> synchroniser les clients en temps réel entre plusieurs appareils et utiliser
> CRUD, authentification et Row Level Security.

## 4. Configuration Supabase

> Configurer le projet Supabase, créer la table `clients` avec les colonnes
> `id`, `name` et `created_at`, activer Realtime pour `public.clients`, puis
> ajouter les policies RLS nécessaires à la lecture, l'insertion et la
> suppression.

## 5. Migration Flutter vers Supabase

> Ajouter `supabase_flutter` et `provider`, créer un modèle `Client` typé,
> implémenter `QueueProvider`, charger les clients depuis Supabase, ajouter et
> supprimer les clients dans la base, implémenter `nextClient` et écouter les
> changements Realtime.

## 6. Sécurité des clés

> Ne jamais écrire les clés Supabase dans le code versionné. Utiliser des
> variables `SUPABASE_URL` et `SUPABASE_ANON_KEY` transmises au lancement.
> Ne jamais utiliser ou partager la clé `service_role`.

## 7. Validation

> Exécuter le formatage, l'analyse statique et tous les tests Flutter. Vérifier
> ensuite le CRUD réel Supabase et tester la synchronisation entre deux
> appareils ou deux instances de l'application.

## État du projet

- Connexion Flutter-Supabase : réalisée.
- Modèle `Client` : réalisé.
- CRUD clients : réalisé.
- Boutons `Add`, `Remove` et `Next Client` : réalisés.
- Provider : réalisé.
- Realtime : configuré pour `public.clients`.
- RLS et policies : configurés.
- Tests Flutter : passés.
- Test temps réel sur deux appareils : à effectuer manuellement.

## Commande de lancement locale

Le fichier `run_supabase.ps1` contient les variables locales et est ignoré par
Git. Pour lancer l'application :

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\run_supabase.ps1
```
