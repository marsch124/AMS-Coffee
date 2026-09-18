import Foundation

/// One clear next move, in plain words, from the brew you just rated.
/// Deliberately pure so every branch can be unit-tested.
struct Advice: Equatable {
    var headline: String
    var detail: String
}

extension BrewMethod {
    /// Where this method usually wants to land. Used only to suggest, never
    /// to scold — a green brew outside the window is still a green brew.
    var idealRatio: ClosedRange<Double> {
        switch self {
        case .espresso:    return 1.8...2.4
        case .v60:         return 15...17
        case .filter:      return 15...17
        case .aeropress:   return 13...16
        case .frenchPress: return 15...17
        case .moka:        return 7...10
        // Cold brew runs anywhere from a thick concentrate to drink-as-it-is;
        // the starter (1 : 12.5) has to sit inside this, or the coach would
        // argue with the app's own default recipe.
        case .coldBrew:    return 8...15
        }
    }

    var idealSeconds: ClosedRange<Double> {
        switch self {
        case .espresso:    return 25...32
        case .v60:         return 150...210
        case .filter:      return 240...360
        case .aeropress:   return 90...180
        case .frenchPress: return 210...270
        case .moka:        return 180...300
        case .coldBrew:    return 12 * 3600...18 * 3600
        }
    }

    /// The knob you reach for first on this method.
    var slowerWord: String {
        switch self {
        case .frenchPress, .coldBrew, .aeropress: return "steep it longer"
        default:                                  return "grind finer"
        }
    }

    var fasterWord: String {
        switch self {
        case .frenchPress, .coldBrew, .aeropress: return "steep it shorter"
        default:                                  return "grind coarser"
        }
    }
}

enum Coach {

    static func advise(for shot: Shot) -> Advice {
        if shot.light == .green { return keepIt(shot) }
        return shot.method == .espresso ? espresso(shot) : brewed(shot)
    }

    // MARK: Green

    private static func keepIt(_ shot: Shot) -> Advice {
        let recipe: String
        switch shot.method {
        case .espresso:
            recipe = "Grind \(trim(shot.grind)), \(trim(shot.doseGrams)) g in, "
                + "\(trim(shot.yieldGrams)) g out, \(trim(shot.seconds)) s."
        case .coldBrew:
            recipe = "Grind \(trim(shot.grind)), \(trim(shot.doseGrams)) g in, "
                + "\(trim(shot.waterGrams)) g water, \(trim(shot.steepHours)) h."
        case .frenchPress, .aeropress:
            recipe = "Grind \(trim(shot.grind)), \(trim(shot.doseGrams)) g in, "
                + "\(trim(shot.waterGrams)) g water, \(trim(shot.steepMinutes)) min."
        default:
            recipe = "Grind \(trim(shot.grind)), \(trim(shot.doseGrams)) g in, "
                + "\(trim(shot.waterGrams)) g water, \(shot.timeText)."
        }
        return Advice(headline: "Keep it exactly here",
                      detail: "\(recipe) Saved as this bag's \(shot.method.title.lowercased()) recipe.")
    }

    // MARK: Espresso

    private static func espresso(_ shot: Shot) -> Advice {
        let sour = shot.sourBitter < -0.15
        let bitter = shot.sourBitter > 0.15
        let thin = shot.thinSyrupy < -0.2
        let fast = shot.seconds < 22
        let slow = shot.seconds > 35
        let ratio = shot.ratio ?? 2

        if sour && fast {
            return Advice(headline: "Grind finer",
                          detail: "About 2 clicks. It ran through in \(trim(shot.seconds)) s — too quick to taste sweet.")
        }
        if bitter && slow {
            return Advice(headline: "Grind coarser",
                          detail: "About 2 clicks. \(trim(shot.seconds)) s is choking it and pulling out the harsh bits.")
        }
        if sour && ratio < 1.7 {
            return Advice(headline: "Let it run longer",
                          detail: "Aim for about \(trim(shot.doseGrams * 2)) g out. A short shot tastes sour before it tastes sweet.")
        }
        if bitter && ratio > 2.6 {
            return Advice(headline: "Stop it earlier",
                          detail: "Aim for about \(trim(shot.doseGrams * 2)) g out. Past 1 : 2.6 you are mostly rinsing the puck.")
        }
        if thin && ratio > 2.4 {
            return Advice(headline: "Less water",
                          detail: "Thin and long. Try \(trim(shot.doseGrams * 2)) g out and a click finer.")
        }
        if sour {
            return Advice(headline: "A touch finer, a touch hotter",
                          detail: "Try grind \(trim(shot.grind - 1)) and \(trim(min(96, shot.tempC + 1)))°C.")
        }
        if bitter {
            return Advice(headline: "A touch coarser, a touch cooler",
                          detail: "Try grind \(trim(shot.grind + 1)) and \(trim(max(88, shot.tempC - 1)))°C.")
        }
        if fast {
            return Advice(headline: "Finer",
                          detail: "\(trim(shot.seconds)) s is fast for espresso. Two clicks finer and taste again.")
        }
        if slow {
            return Advice(headline: "Coarser",
                          detail: "\(trim(shot.seconds)) s is slow. Two clicks coarser and taste again.")
        }
        return oneThing()
    }

    // MARK: Everything poured or steeped

    private static func brewed(_ shot: Shot) -> Advice {
        let method = shot.method
        let sour = shot.sourBitter < -0.15
        let bitter = shot.sourBitter > 0.15
        let thin = shot.thinSyrupy < -0.2
        let strong = shot.thinSyrupy > 0.3
        let ratio = shot.ratio ?? method.idealRatio.lowerBound
        let time = shot.totalSeconds
        let quick = time > 0 && time < method.idealSeconds.lowerBound
        let draggy = time > method.idealSeconds.upperBound

        // Taste leads. Time only explains why.
        if bitter {
            let why = draggy ? " It also took \(shot.timeText), which is long for \(method.title.lowercased())." : ""
            return Advice(headline: method.fasterWord.capitalizedFirst,
                          detail: "Bitter means it gave up too much.\(why) Change only this and taste again.")
        }
        if sour {
            let why = quick ? " It was through in \(shot.timeText), which is quick for \(method.title.lowercased())." : ""
            return Advice(headline: method.slowerWord.capitalizedFirst,
                          detail: "Sour means it did not give up enough yet.\(why) Change only this and taste again.")
        }
        if thin && ratio > method.idealRatio.upperBound {
            let target = shot.doseGrams * method.idealRatio.upperBound
            return Advice(headline: "Less water",
                          detail: "1 : \(String(format: "%.0f", ratio)) is a lot of water for \(method.title.lowercased()). "
                              + "Try about \(trim(target.rounded())) g on \(trim(shot.doseGrams)) g of coffee.")
        }
        if thin {
            let target = shot.doseGrams + 2
            return Advice(headline: "More coffee",
                          detail: "Thin but not over-watered. Try \(trim(target)) g of coffee with the same water.")
        }
        if strong && ratio < method.idealRatio.lowerBound {
            let target = shot.doseGrams * method.idealRatio.lowerBound
            return Advice(headline: "More water",
                          detail: "Try about \(trim(target.rounded())) g of water on \(trim(shot.doseGrams)) g of coffee.")
        }
        if draggy {
            return Advice(headline: method.fasterWord.capitalizedFirst,
                          detail: "\(shot.timeText) is slow for \(method.title.lowercased()) — usually \(window(method)). "
                              + "Nothing tasted wrong, so change this one thing only if you want it brighter.")
        }
        if quick {
            return Advice(headline: method.slowerWord.capitalizedFirst,
                          detail: "\(shot.timeText) is quick for \(method.title.lowercased()) — usually \(window(method)).")
        }
        return oneThing()
    }

    private static func oneThing() -> Advice {
        Advice(headline: "Change one thing only",
               detail: "Nothing is obviously off. Nudge the grind by one click and see which way it moves.")
    }

    private static func window(_ method: BrewMethod) -> String {
        let r = method.idealSeconds
        if r.lowerBound >= 3600 {
            return "\(trim(r.lowerBound / 3600))–\(trim(r.upperBound / 3600)) h"
        }
        if r.lowerBound >= 120 {
            return "\(trim(r.lowerBound / 60))–\(trim(r.upperBound / 60)) min"
        }
        return "\(trim(r.lowerBound))–\(trim(r.upperBound)) s"
    }

    static func trim(_ v: Double) -> String {
        v == v.rounded() ? String(Int(v)) : String(format: "%.1f", v)
    }
}

extension String {
    var capitalizedFirst: String {
        guard let f = first else { return self }
        return f.uppercased() + dropFirst()
    }
}
