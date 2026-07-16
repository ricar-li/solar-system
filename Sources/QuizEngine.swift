import Foundation

/// 猜猜看：用趣闻/数据出题，三选一行星（排除太阳更偏「行星」知识时可含太阳）。
struct QuizQuestion: Identifiable, Equatable {
    let id: UUID
    let prompt: String
    let choices: [Planet]
    let answerID: String
}

enum QuizEngine {
    /// 生成一题；`avoidID` 避免连续两题同一答案。
    static func makeQuestion(avoidID: String? = nil) -> QuizQuestion {
        let pool = SolarData.all
        var answer = pool.randomElement()!
        var guardCount = 0
        while answer.id == avoidID, pool.count > 1, guardCount < 8 {
            answer = pool.randomElement()!
            guardCount += 1
        }

        let promptKinds: [() -> String] = [
            { "「\(answer.funFacts.randomElement() ?? answer.blurb)」说的是哪一颗？" },
            { "哪一颗的简介是：\(answer.blurb)" },
            { "直径「\(answer.diameter)」更接近哪一颗？" },
            { "「\(answer.orderText)」是哪一颗？" },
            { "温度大约「\(answer.temperature)」的是？" }
        ]
        let prompt = promptKinds.randomElement()!()

        var choices = [answer]
        let others = pool.filter { $0.id != answer.id }.shuffled()
        for p in others where choices.count < 3 {
            choices.append(p)
        }
        choices.shuffle()

        return QuizQuestion(id: UUID(), prompt: prompt, choices: choices, answerID: answer.id)
    }
}
