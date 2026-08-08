import Foundation

/// A named benchmark workout with a ready-to-run timer preset.
struct BenchmarkWOD: Identifiable, Hashable {
    enum Category: String, CaseIterable {
        case girls = "The Girls"
        case heroes = "Hero WODs"
    }

    var id: String { name }
    var name: String
    var category: Category
    var block: WorkoutBlock
    var movements: String

    var schemeText: String {
        "\(block.typeTitle) \(block.summary)"
    }

    func plan(countdown: TimeInterval) -> WorkoutPlan {
        let type: WorkoutType
        switch block {
        case .emom: type = .emom
        case .amrap: type = .amrap
        case .forTime: type = .forTime
        case .tabata: type = .tabata
        case .rest: type = .forTime
        }
        return WorkoutPlan(
            type: type,
            blocks: [MixBlock(block: block, note: movements)],
            countdown: countdown,
            customName: name
        )
    }
}

enum BenchmarkLibrary {

    private static func forTime(_ minutes: Double) -> WorkoutBlock {
        .forTime(ForTimeConfig(isCapEnabled: true, timeCap: minutes * 60))
    }

    private static func amrap(_ minutes: Double) -> WorkoutBlock {
        .amrap(AmrapConfig(duration: minutes * 60))
    }

    static let all: [BenchmarkWOD] = [
        // MARK: The Girls
        .init(name: "Fran", category: .girls, block: forTime(10),
              movements: "21-15-9\nThrusters 95/65 lb\nPull-ups"),
        .init(name: "Grace", category: .girls, block: forTime(8),
              movements: "30 clean & jerks 135/95 lb"),
        .init(name: "Isabel", category: .girls, block: forTime(8),
              movements: "30 snatches 135/95 lb"),
        .init(name: "Diane", category: .girls, block: forTime(10),
              movements: "21-15-9\nDeadlifts 225/155 lb\nHandstand push-ups"),
        .init(name: "Elizabeth", category: .girls, block: forTime(12),
              movements: "21-15-9\nCleans 135/95 lb\nRing dips"),
        .init(name: "Helen", category: .girls, block: forTime(15),
              movements: "3 rounds:\n400 m run\n21 KB swings 53/35 lb\n12 pull-ups"),
        .init(name: "Jackie", category: .girls, block: forTime(15),
              movements: "1000 m row\n50 thrusters 45 lb\n30 pull-ups"),
        .init(name: "Karen", category: .girls, block: forTime(12),
              movements: "150 wall-ball shots 20/14 lb"),
        .init(name: "Angie", category: .girls, block: forTime(25),
              movements: "100 pull-ups\n100 push-ups\n100 sit-ups\n100 air squats"),
        .init(name: "Barbara", category: .girls, block: forTime(40),
              movements: "5 rounds (rest 3:00 between):\n20 pull-ups\n30 push-ups\n40 sit-ups\n50 air squats"),
        .init(name: "Chelsea", category: .girls,
              block: .emom(EmomConfig(rounds: 30, interval: 60)),
              movements: "Each minute:\n5 pull-ups\n10 push-ups\n15 air squats"),
        .init(name: "Cindy", category: .girls, block: amrap(20),
              movements: "5 pull-ups\n10 push-ups\n15 air squats"),
        .init(name: "Mary", category: .girls, block: amrap(20),
              movements: "5 handstand push-ups\n10 alternating pistols\n15 pull-ups"),
        .init(name: "Annie", category: .girls, block: forTime(12),
              movements: "50-40-30-20-10\nDouble-unders\nSit-ups"),
        .init(name: "Nancy", category: .girls, block: forTime(20),
              movements: "5 rounds:\n400 m run\n15 overhead squats 95/65 lb"),
        .init(name: "Kelly", category: .girls, block: forTime(30),
              movements: "5 rounds:\n400 m run\n30 box jumps 24/20 in\n30 wall-ball shots 20/14 lb"),
        .init(name: "Eva", category: .girls, block: forTime(45),
              movements: "5 rounds:\n800 m run\n30 KB swings 70/53 lb\n30 pull-ups"),
        .init(name: "Linda", category: .girls, block: forTime(30),
              movements: "10-9-8-7-6-5-4-3-2-1\nDeadlift 1.5× BW\nBench press 1× BW\nClean 0.75× BW"),
        .init(name: "Nicole", category: .girls, block: amrap(20),
              movements: "400 m run\nMax-rep pull-ups\n(score = total pull-ups)"),
        .init(name: "Amanda", category: .girls, block: forTime(12),
              movements: "9-7-5\nMuscle-ups\nSquat snatches 135/95 lb"),

        // MARK: Hero WODs
        .init(name: "Murph", category: .heroes, block: forTime(60),
              movements: "1 mile run\n100 pull-ups\n200 push-ups\n300 air squats\n1 mile run\n(20/14 lb vest)"),
        .init(name: "DT", category: .heroes, block: forTime(20),
              movements: "5 rounds:\n12 deadlifts 155/105 lb\n9 hang power cleans\n6 push jerks"),
        .init(name: "JT", category: .heroes, block: forTime(20),
              movements: "21-15-9\nHandstand push-ups\nRing dips\nPush-ups"),
        .init(name: "Randy", category: .heroes, block: forTime(12),
              movements: "75 power snatches 75/55 lb"),
        .init(name: "Griff", category: .heroes, block: forTime(20),
              movements: "800 m run\n400 m run backwards\n800 m run\n400 m run backwards")
    ]
}
