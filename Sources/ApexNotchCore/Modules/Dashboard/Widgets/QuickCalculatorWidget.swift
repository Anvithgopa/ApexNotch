import SwiftUI

public struct QuickCalculatorWidget: View {
    @NotchState private var input: String = ""
    @NotchState private var result: String = "Type an expression (e.g. 15% of 820 or 50 km to mi)"
    
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label("Quick Calc & Converter", systemImage: "function")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(NotchDesign.accentAmber)
                
                Spacer()
                
                if !input.isEmpty {
                    Button(action: {
                        let pb = NSPasteboard.general
                        pb.clearContents()
                        pb.setString(result, forType: .string)
                        AppState.shared.showToast("Copied result: \(result)")
                    }) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 10))
                            .foregroundColor(NotchDesign.accentAmber)
                    }
                    .buttonStyle(.plain)
                    .help("Copy result")
                }
            }
            
            HStack(spacing: 6) {
                TextField("e.g. (14 * 25) + 80, 50 c to f, 120 km to mi", text: $input)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11, design: .monospaced))
                    .padding(6)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(6)
                    .onChange(of: input) { _, val in
                        evaluate(val)
                    }
            }
            
            HStack {
                Text(result)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(input.isEmpty ? NotchDesign.textTertiary : NotchDesign.accentGreen)
                    .lineLimit(1)
                
                Spacer()
            }
            .padding(.top, 2)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(NotchDesign.surfaceElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(NotchDesign.borderSubtle, lineWidth: 1)
                )
        )
    }
    
    private func evaluate(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else {
            result = "Type an expression (e.g. 15% of 820 or 50 km to mi)"
            return
        }
        
        // 1. Percentage: "X% of Y"
        if trimmed.contains("% of ") {
            let parts = trimmed.components(separatedBy: "% of ")
            if parts.count == 2, let p = Double(parts[0]), let v = Double(parts[1]) {
                let res = (p / 100.0) * v
                result = "= \(formatNumber(res))"
                return
            }
        }
        
        // 2. Unit conversions
        if trimmed.contains(" to ") {
            let parts = trimmed.components(separatedBy: " to ")
            if parts.count == 2 {
                let left = parts[0].trimmingCharacters(in: .whitespaces)
                let targetUnit = parts[1].trimmingCharacters(in: .whitespaces)
                
                // Parse number and unit from left
                let scanner = Scanner(string: left)
                var val: Double = 0
                if scanner.scanDouble(&val) {
                    let sourceUnit = String(left[scanner.currentIndex...]).trimmingCharacters(in: .whitespaces)
                    if let converted = convertUnit(value: val, from: sourceUnit, to: targetUnit) {
                        result = "= \(formatNumber(converted)) \(targetUnit)"
                        return
                    }
                }
            }
        }
        
        // 3. Math Expression via NSExpression
        let mathClean = trimmed
            .replacingOccurrences(of: "x", with: "*")
            .replacingOccurrences(of: "×", with: "*")
            .replacingOccurrences(of: "÷", with: "/")
        
        let expr = NSExpression(format: mathClean)
        if let res = expr.expressionValue(with: nil, context: nil) as? NSNumber {
            result = "= \(formatNumber(res.doubleValue))"
        } else {
            result = "..."
        }
    }
    
    private func convertUnit(value: Double, from: String, to: String) -> Double? {
        let f = from.lowercased()
        let t = to.lowercased()
        
        // Length
        if (f == "km" || f == "kilometer" || f == "kilometers") && (t == "mi" || t == "mile" || t == "miles") {
            return value * 0.621371
        }
        if (f == "mi" || f == "mile" || f == "miles") && (t == "km" || t == "kilometer" || t == "kilometers") {
            return value * 1.60934
        }
        if (f == "m" || f == "meter") && (t == "ft" || t == "feet") {
            return value * 3.28084
        }
        if (f == "ft" || f == "feet") && (t == "m" || t == "meter") {
            return value / 3.28084
        }
        
        // Weight
        if (f == "kg" || f == "kilo") && (t == "lb" || t == "lbs" || t == "pound" || t == "pounds") {
            return value * 2.20462
        }
        if (f == "lb" || f == "lbs") && (t == "kg" || t == "kilo") {
            return value / 2.20462
        }
        
        // Temperature
        if (f == "c" || f == "celsius") && (t == "f" || t == "fahrenheit") {
            return (value * 9.0 / 5.0) + 32.0
        }
        if (f == "f" || f == "fahrenheit") && (t == "c" || t == "celsius") {
            return (value - 32.0) * 5.0 / 9.0
        }
        
        return nil
    }
    
    private func formatNumber(_ num: Double) -> String {
        if abs(num.rounded() - num) < 0.0001 {
            return String(format: "%.0f", num)
        } else {
            return String(format: "%.2f", num)
        }
    }
}
