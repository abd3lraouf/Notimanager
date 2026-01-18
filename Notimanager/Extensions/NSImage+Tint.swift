//
//  NSImage+Tint.swift
//  Notimanager
//
//  Created on 2026-01-17.
//

import AppKit

extension NSImage {
    /// Returns a new image tinted with the specified color.
    /// This is useful for menu bar icons where we want to force a specific color
    /// instead of relying on the system's automatic template rendering.
    ///
    /// - Parameter color: The color to tint the image with.
    /// - Returns: A new NSImage with the color applied, or the original image if copying fails.
    func tinted(color: NSColor) -> NSImage {
        guard let tintedImage = self.copy() as? NSImage else { return self }
        
        tintedImage.lockFocus()
        color.set()
        
        // Draw the color over the image bounds using Source Atop compositing
        // This keeps the alpha channel but replaces the color
        let imageRect = NSRect(origin: .zero, size: self.size)
        imageRect.fill(using: .sourceAtop)
        
        tintedImage.unlockFocus()
        
        // Important: Turn off template so the color renders as-is
        tintedImage.isTemplate = false 
        return tintedImage
    }
}
