/// Escape the four characters that change meaning inside HTML.
func escapeHTML(_ s: String) -> String {
    var out = ""
    out.reserveCapacity(s.count)
    for character in s {
        switch character {
        case "&": out += "&amp;"
        case "<": out += "&lt;"
        case ">": out += "&gt;"
        case "\"": out += "&quot;"
        default: out.append(character)
        }
    }
    return out
}
