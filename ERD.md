# Hello Coach — Entity Relationship Diagram

```mermaid
erDiagram

    %% ═══════════════════════════════════════════════
    %%   SWIFTDATA MODELS  (@Model — stored in SQLite)
    %% ═══════════════════════════════════════════════

    WorkoutSession {
        UUID    id              PK
        String  typeRawValue
        Date    startTime
        Date    endTime         "nullable"
    }

    ExerciseEntry {
        UUID    id              PK
        String  exerciseRawValue
    }

    RepSet {
        UUID    id              PK
        Int     reps
        Double  weightKg
        Date    timestamp
    }

    %% ═══════════════════════════════════════════════
    %%   VALUE TYPES  (enum — resolved at runtime)
    %% ═══════════════════════════════════════════════

    ExerciseCategory {
        String  rawValue        "push | pull"
    }

    Exercise {
        String  rawValue
        String  category        "push | pull"
        String  subgroup        "Chest | Shoulder | Triceps | Back | Rear Shoulder | Biceps"
    }

    MuscleGroup {
        String  rawValue        "Chest | Anterior Delt | Lateral Delt | Posterior Delt | Triceps | Lats | Traps | Rhomboids | Biceps | Forearms"
    }

    %% ═══════════════════════════════════════════════
    %%   RELATIONSHIPS
    %% ═══════════════════════════════════════════════

    WorkoutSession  ||--o{ ExerciseEntry   : "has entries  (cascade delete)"
    ExerciseEntry   ||--o{ RepSet          : "has sets     (cascade delete)"

    WorkoutSession  }o--||  ExerciseCategory : "typeRawValue"
    ExerciseEntry   }o--||  Exercise         : "exerciseRawValue"
    Exercise        }o--o{  MuscleGroup      : "primaryMuscles / secondaryMuscles"
```

---

## Computed Properties

> Derived at runtime — not stored in the database.

| Entity | Property | Formula |
|:---|:---|:---|
| `WorkoutSession` | `type` | `ExerciseCategory(rawValue: typeRawValue)` |
| `WorkoutSession` | `totalReps` | `sum(entries.totalReps)` |
| `WorkoutSession` | `totalVolume` | `sum(entries.totalVolume)` |
| `WorkoutSession` | `totalSets` | `sum(entries.setCount)` |
| `WorkoutSession` | `duration` | `endTime − startTime` |
| `WorkoutSession` | `formattedDuration` | `"m:ss"` |
| `WorkoutSession` | `exerciseSummary` | `entries[].displayName joined` |
| `ExerciseEntry` | `exercise` | `Exercise(rawValue: exerciseRawValue)` |
| `ExerciseEntry` | `totalReps` | `sum(sets.reps)` |
| `ExerciseEntry` | `totalVolume` | `sum(sets.volume)` |
| `ExerciseEntry` | `setCount` | `sets.count` |
| `ExerciseEntry` | `bestSet` | `sets.max(by: volume)` |
| `RepSet` | `volume` | `reps × weightKg` |

---

## Delete Cascade

```
WorkoutSession  →  ExerciseEntry  →  RepSet
   (deleted)           (deleted)      (deleted)
```

Menghapus satu `WorkoutSession` secara otomatis menghapus semua `ExerciseEntry` dan `RepSet` miliknya.

---

## Storage

| Kelas | Tipe | Lokasi |
|:---|:---|:---|
| `WorkoutSession` | `@Model` | SQLite via `ModelContainer` |
| `ExerciseEntry` | `@Model` | SQLite via `ModelContainer` |
| `RepSet` | `@Model` | SQLite via `ModelContainer` |
| `ExerciseCategory` | `enum String` | In-memory (rawValue di model) |
| `Exercise` | `enum String` | In-memory (rawValue di model) |
| `MuscleGroup` | `enum String` | In-memory (computed property) |
