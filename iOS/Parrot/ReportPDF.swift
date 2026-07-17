import UIKit

// Renders a clean one-or-more page US Letter PDF an SLP can skim in seconds.

enum ReportPDF {
    static let pageSize = CGSize(width: 612, height: 792)
    static let margin: CGFloat = 54

    static func generate(kidName: String, summary: ReportSummary) -> URL? {
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [
            kCGPDFContextTitle as String: "Parrot Practice Log for \(kidName)",
            kCGPDFContextCreator as String: "Parrot - Speech Practice Log"
        ]
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: pageSize), format: format)

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none

        let safeName = kidName.replacingOccurrences(of: "/", with: "-")
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("Parrot Report \(safeName).pdf")

        do {
            try renderer.writePDF(to: url) { pdfContext in
                var cursor = Cursor(context: pdfContext, pageSize: pageSize, margin: margin)
                cursor.beginPage()

                // Header
                cursor.draw("Parrot Practice Log", font: .systemFont(ofSize: 26, weight: .heavy), color: .black, spacingAfter: 6)
                cursor.draw("\(kidName)  |  \(dateFormatter.string(from: summary.start)) to \(dateFormatter.string(from: summary.end))",
                            font: .systemFont(ofSize: 12, weight: .medium), color: .darkGray, spacingAfter: 18)

                // Totals
                cursor.draw("Summary", font: .systemFont(ofSize: 15, weight: .bold), color: .black, spacingAfter: 8)
                let sessionsLine = "Sessions: \(summary.sessionCount)    Words practiced: \(summary.attemptCount)    Practice time: \(summary.totalMinutes) min    Overall accuracy: \(summary.overallAccuracy.percentText)"
                cursor.draw(sessionsLine, font: .systemFont(ofSize: 12), color: .black, spacingAfter: 18)

                // Per sound
                if !summary.soundStats.isEmpty {
                    cursor.draw("Accuracy by Sound", font: .systemFont(ofSize: 15, weight: .bold), color: .black, spacingAfter: 8)
                    for stat in summary.soundStats {
                        cursor.drawBarRow(label: stat.sound,
                                          detail: "\(stat.attempts) attempts",
                                          fraction: stat.accuracy,
                                          valueText: stat.accuracy.percentText)
                    }
                    cursor.space(12)
                }

                // Per position
                if !summary.positionStats.isEmpty {
                    cursor.draw("Accuracy by Position", font: .systemFont(ofSize: 15, weight: .bold), color: .black, spacingAfter: 8)
                    for stat in summary.positionStats {
                        cursor.drawBarRow(label: stat.position.label,
                                          detail: "\(stat.attempts) attempts",
                                          fraction: stat.accuracy,
                                          valueText: stat.accuracy.percentText)
                    }
                    cursor.space(12)
                }

                // Notes
                if !summary.notes.isEmpty {
                    cursor.draw("Session Notes", font: .systemFont(ofSize: 15, weight: .bold), color: .black, spacingAfter: 8)
                    for note in summary.notes {
                        cursor.draw(dateFormatter.string(from: note.date),
                                    font: .systemFont(ofSize: 10, weight: .semibold), color: .darkGray, spacingAfter: 2)
                        cursor.draw(note.text, font: .systemFont(ofSize: 11), color: .black, spacingAfter: 10)
                    }
                }

                cursor.space(16)
                cursor.draw("Logged at home with Parrot. This log supports professional guidance and is not a clinical assessment.",
                            font: .systemFont(ofSize: 9), color: .gray, spacingAfter: 0)
            }
            return url
        } catch {
            return nil
        }
    }
}

// MARK: - Simple paginating cursor

private struct Cursor {
    let context: UIGraphicsPDFRendererContext
    let pageSize: CGSize
    let margin: CGFloat
    var y: CGFloat = 0

    var contentWidth: CGFloat { pageSize.width - margin * 2 }

    init(context: UIGraphicsPDFRendererContext, pageSize: CGSize, margin: CGFloat) {
        self.context = context
        self.pageSize = pageSize
        self.margin = margin
    }

    mutating func beginPage() {
        context.beginPage()
        y = margin
    }

    mutating func ensureRoom(_ height: CGFloat) {
        if y + height > pageSize.height - margin {
            beginPage()
        }
    }

    mutating func space(_ amount: CGFloat) {
        y += amount
    }

    mutating func draw(_ text: String, font: UIFont, color: UIColor, spacingAfter: CGFloat) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byWordWrapping
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraph
        ]
        let attributed = NSAttributedString(string: text, attributes: attributes)
        let bounds = attributed.boundingRect(
            with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
        ensureRoom(bounds.height + spacingAfter)
        attributed.draw(in: CGRect(x: margin, y: y, width: contentWidth, height: ceil(bounds.height)))
        y += ceil(bounds.height) + spacingAfter
    }

    mutating func drawBarRow(label: String, detail: String, fraction: Double, valueText: String) {
        let rowHeight: CGFloat = 22
        ensureRoom(rowHeight + 6)

        let labelFont = UIFont.systemFont(ofSize: 12, weight: .bold)
        let detailFont = UIFont.systemFont(ofSize: 10)

        (label as NSString).draw(
            at: CGPoint(x: margin, y: y + 3),
            withAttributes: [.font: labelFont, .foregroundColor: UIColor.black]
        )
        (detail as NSString).draw(
            at: CGPoint(x: margin + 64, y: y + 5),
            withAttributes: [.font: detailFont, .foregroundColor: UIColor.darkGray]
        )

        let barX = margin + 170
        let barWidth = contentWidth - 170 - 48
        let barRect = CGRect(x: barX, y: y + 5, width: barWidth, height: 10)
        let cg = context.cgContext
        cg.setFillColor(UIColor(white: 0.9, alpha: 1).cgColor)
        cg.fill(barRect)
        let filled = CGRect(x: barX, y: y + 5, width: barWidth * CGFloat(min(max(fraction, 0), 1)), height: 10)
        let fillColor = fraction >= Mastery.threshold
            ? UIColor(red: 0.22, green: 0.65, blue: 0.42, alpha: 1)
            : UIColor(red: 0.22, green: 0.62, blue: 0.86, alpha: 1)
        cg.setFillColor(fillColor.cgColor)
        cg.fill(filled)

        (valueText as NSString).draw(
            at: CGPoint(x: barX + barWidth + 8, y: y + 3),
            withAttributes: [.font: labelFont, .foregroundColor: UIColor.black]
        )
        y += rowHeight
    }
}
