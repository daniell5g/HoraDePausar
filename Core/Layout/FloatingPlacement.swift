import CoreGraphics
import Foundation

/// Where the reminder card's window goes. The window is larger than the card it shows:
/// `inset` is the transparent room kept around the card for its shadow.
public enum FloatingPlacement {
    /// Window origin (AppKit coordinates, bottom-left) that pins the card to the top-right corner of
    /// `visible`, `margin` points from both edges, and never lets the card leave `visible`.
    public static func topRight(window size: CGSize, inset: CGFloat, margin: CGFloat, in visible: CGRect) -> CGPoint {
        let card = CGSize(width: size.width - 2 * inset, height: size.height - 2 * inset)
        var cardX = visible.maxX - margin - card.width
        var cardY = visible.maxY - margin - card.height
        cardX = max(cardX, visible.minX + margin)
        cardY = max(cardY, visible.minY + margin)
        return CGPoint(x: cardX - inset, y: cardY - inset)
    }

    /// The card's own rectangle for a window placed at `origin`.
    public static func cardFrame(window size: CGSize, inset: CGFloat, origin: CGPoint) -> CGRect {
        CGRect(x: origin.x + inset, y: origin.y + inset,
               width: size.width - 2 * inset, height: size.height - 2 * inset)
    }
}
