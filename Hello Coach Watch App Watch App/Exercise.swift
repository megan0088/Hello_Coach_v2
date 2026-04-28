import Foundation

// MARK: - Muscle Group

enum MuscleGroup: String, CaseIterable, Codable, Hashable {
    case chest          = "Chest"
    case anteriorDelt   = "Anterior Delt"
    case lateralDelt    = "Lateral Delt"
    case posteriorDelt  = "Posterior Delt"
    case triceps        = "Triceps"
    case lats           = "Lats"
    case traps          = "Traps"
    case rhomboids      = "Rhomboids"
    case biceps         = "Biceps"
    case forearms       = "Forearms"
}

// MARK: - Exercise Category

enum ExerciseCategory: String, CaseIterable, Codable, Hashable {
    case push = "Push"
    case pull = "Pull"
}

// MARK: - Exercise

enum Exercise: String, CaseIterable, Identifiable, Codable, Hashable {

    // Push — Chest
    case benchPress               = "Bench Press"
    case inclineBenchPress        = "Incline Bench Press"
    case declineBenchPress        = "Decline Bench Press"
    case chestPressMachine        = "Chest Press Machine"
    case dumbbellFly              = "Dumbbell Fly"
    case cableFly                 = "Cable Fly"
    case pushUp                   = "Push Up"

    // Push — Shoulder
    case overheadPress            = "Overhead Press"
    case arnoldPress              = "Arnold Press"
    case dumbbellShoulderPress    = "Dumbbell Shoulder Press"
    case lateralRaise             = "Lateral Raise"
    case frontRaise               = "Front Raise"
    case machineShoulderPress     = "Machine Shoulder Press"

    // Push — Triceps
    case tricepPushdown           = "Tricep Pushdown"
    case overheadTricepExtension  = "Overhead Tricep Extension"
    case skullcrusher             = "Skullcrusher"
    case closeGripBenchPress      = "Close Grip Bench Press"
    case dips                     = "Dips"

    // Pull — Back
    case pullUp                   = "Pull Up"
    case latPulldown              = "Lat Pulldown"
    case seatedCableRow           = "Seated Cable Row"
    case barbellRow               = "Barbell Row"
    case dumbbellRow              = "Dumbbell Row"
    case tBarRow                  = "T-Bar Row"
    case machineRow               = "Machine Row"
    case straightArmPulldown      = "Straight Arm Pulldown"
    case deadlift                 = "Deadlift"

    // Pull — Rear Shoulder
    case facePull                 = "Face Pull"
    case reversePecDeck           = "Reverse Pec Deck"
    case rearDeltFly              = "Rear Delt Fly"

    // Pull — Biceps
    case barbellCurl              = "Barbell Curl"
    case dumbbellCurl             = "Dumbbell Curl"
    case hammerCurl               = "Hammer Curl"
    case preacherCurl             = "Preacher Curl"
    case cableCurl                = "Cable Curl"

    var id: String { rawValue }
    var displayName: String { rawValue }

    var category: ExerciseCategory {
        switch self {
        case .benchPress, .inclineBenchPress, .declineBenchPress, .chestPressMachine,
             .dumbbellFly, .cableFly, .pushUp,
             .overheadPress, .arnoldPress, .dumbbellShoulderPress,
             .lateralRaise, .frontRaise, .machineShoulderPress,
             .tricepPushdown, .overheadTricepExtension, .skullcrusher,
             .closeGripBenchPress, .dips:
            return .push
        case .pullUp, .latPulldown, .seatedCableRow, .barbellRow, .dumbbellRow,
             .tBarRow, .machineRow, .straightArmPulldown, .deadlift,
             .facePull, .reversePecDeck, .rearDeltFly,
             .barbellCurl, .dumbbellCurl, .hammerCurl, .preacherCurl, .cableCurl:
            return .pull
        }
    }

    var subgroup: String {
        switch self {
        case .benchPress, .inclineBenchPress, .declineBenchPress,
             .chestPressMachine, .dumbbellFly, .cableFly, .pushUp:
            return "Chest"
        case .overheadPress, .arnoldPress, .dumbbellShoulderPress,
             .lateralRaise, .frontRaise, .machineShoulderPress:
            return "Shoulder"
        case .tricepPushdown, .overheadTricepExtension, .skullcrusher,
             .closeGripBenchPress, .dips:
            return "Triceps"
        case .pullUp, .latPulldown, .seatedCableRow, .barbellRow,
             .dumbbellRow, .tBarRow, .machineRow, .straightArmPulldown, .deadlift:
            return "Back"
        case .facePull, .reversePecDeck, .rearDeltFly:
            return "Rear Shoulder"
        case .barbellCurl, .dumbbellCurl, .hammerCurl, .preacherCurl, .cableCurl:
            return "Biceps"
        }
    }

    var primaryMuscles: [MuscleGroup] {
        switch self {
        case .benchPress, .inclineBenchPress, .declineBenchPress,
             .chestPressMachine, .dumbbellFly, .cableFly, .pushUp:
            return [.chest]
        case .overheadPress, .arnoldPress, .dumbbellShoulderPress, .machineShoulderPress:
            return [.anteriorDelt, .lateralDelt]
        case .lateralRaise:
            return [.lateralDelt]
        case .frontRaise:
            return [.anteriorDelt]
        case .tricepPushdown, .overheadTricepExtension, .skullcrusher:
            return [.triceps]
        case .closeGripBenchPress:
            return [.triceps]
        case .dips:
            return [.triceps, .chest]
        case .pullUp, .latPulldown, .straightArmPulldown:
            return [.lats]
        case .seatedCableRow, .machineRow:
            return [.rhomboids, .traps]
        case .barbellRow, .dumbbellRow, .tBarRow:
            return [.lats, .rhomboids]
        case .deadlift:
            return [.lats, .traps]
        case .facePull, .reversePecDeck, .rearDeltFly:
            return [.posteriorDelt]
        case .barbellCurl, .dumbbellCurl, .preacherCurl, .cableCurl:
            return [.biceps]
        case .hammerCurl:
            return [.biceps, .forearms]
        }
    }

    var secondaryMuscles: [MuscleGroup] {
        switch self {
        case .benchPress, .inclineBenchPress, .chestPressMachine, .pushUp:
            return [.anteriorDelt, .triceps]
        case .declineBenchPress:
            return [.triceps]
        case .dumbbellFly, .cableFly:
            return [.anteriorDelt]
        case .overheadPress, .machineShoulderPress:
            return [.triceps, .traps]
        case .arnoldPress, .dumbbellShoulderPress:
            return [.triceps]
        case .lateralRaise:
            return [.anteriorDelt]
        case .frontRaise:
            return [.lateralDelt]
        case .closeGripBenchPress:
            return [.chest, .anteriorDelt]
        case .dips:
            return [.anteriorDelt]
        case .pullUp, .latPulldown:
            return [.biceps, .rhomboids, .posteriorDelt]
        case .seatedCableRow, .machineRow:
            return [.lats, .biceps]
        case .barbellRow, .tBarRow:
            return [.biceps, .traps]
        case .dumbbellRow:
            return [.biceps]
        case .straightArmPulldown:
            return [.triceps]
        case .deadlift:
            return [.rhomboids, .forearms]
        case .facePull:
            return [.rhomboids, .traps]
        case .reversePecDeck, .rearDeltFly:
            return [.rhomboids]
        case .barbellCurl, .dumbbellCurl, .preacherCurl, .cableCurl:
            return [.forearms]
        case .hammerCurl, .tricepPushdown, .overheadTricepExtension, .skullcrusher:
            return []
        }
    }

    static func exercises(for category: ExerciseCategory) -> [Exercise] {
        allCases.filter { $0.category == category }
    }

    static func grouped(for category: ExerciseCategory) -> [(subgroup: String, exercises: [Exercise])] {
        var result: [(String, [Exercise])] = []
        var seen: [String] = []
        for exercise in exercises(for: category) {
            if !seen.contains(exercise.subgroup) {
                seen.append(exercise.subgroup)
                result.append((exercise.subgroup, exercises(for: category).filter { $0.subgroup == exercise.subgroup }))
            }
        }
        return result
    }
}
