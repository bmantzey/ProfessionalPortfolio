//
//  PDFKitRepresentable.swift
//  ProfessionalPortfolio
//
//  Created by Brandon Mantzey on 10/28/25.
//

import SwiftUI
import PDFKit

struct PDFKitRepresentable: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        
        // Configure basic display settings
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.autoScales = false // We'll handle scaling manually
        pdfView.maxScaleFactor = 4.0
        pdfView.minScaleFactor = 0.25
        
        // Set up coordinator to handle document loading
        context.coordinator.setupPDFView(pdfView, with: url)
        
        return pdfView
    }
    
    func updateUIView(_ pdfView: PDFView, context: Context) {
        // Only reload if URL changed
        if pdfView.document?.documentURL != url {
            context.coordinator.setupPDFView(pdfView, with: url)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject {
        private var pdfView: PDFView?
        private var hasSetInitialScale = false
        
        func setupPDFView(_ pdfView: PDFView, with url: URL) {
            self.pdfView = pdfView
            self.hasSetInitialScale = false
            
            // Add observer for when document loads
            NotificationCenter.default.removeObserver(self)
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(documentDidLoad),
                name: .PDFViewDocumentChanged,
                object: pdfView
            )
            
            // Load the document
            DispatchQueue.global(qos: .userInitiated).async {
                if let document = PDFDocument(url: url) {
                    DispatchQueue.main.async {
                        pdfView.document = document
                    }
                }
            }
        }
        
        @objc private func documentDidLoad(_ notification: Notification) {
            guard let pdfView = notification.object as? PDFView,
                  let document = pdfView.document,
                  document.pageCount > 0,
                  !hasSetInitialScale else { return }
            
            // Wait a bit longer for view to be fully laid out
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                self?.setFitToWidthScale(pdfView)
            }
        }
        
        private func setFitToWidthScale(_ pdfView: PDFView) {
            guard !hasSetInitialScale,
                  pdfView.bounds.width > 0,
                  pdfView.bounds.height > 0 else {
                
                // If not ready yet, try again after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                    self?.setFitToWidthScale(pdfView)
                }
                return
            }
            
            // Use PDFView's built-in scale calculation but ensure it fits width
            let fitWidthScale = pdfView.scaleFactorForSizeToFit
            
            if fitWidthScale > 0 {
                // Set scale factors
                pdfView.minScaleFactor = fitWidthScale * 0.5 // Allow zoom out
                pdfView.maxScaleFactor = fitWidthScale * 4.0 // Allow zoom in
                pdfView.scaleFactor = fitWidthScale
                
                hasSetInitialScale = true
                print("✅ PDF scaled using built-in method: \(fitWidthScale)")
            } else {
                // Fallback to manual calculation if built-in method fails
                setManualFitScale(pdfView)
            }
        }
        
        private func setManualFitScale(_ pdfView: PDFView) {
            guard let document = pdfView.document,
                  let firstPage = document.page(at: 0) else { return }
            
            let pageRect = firstPage.bounds(for: .mediaBox)
            let pdfViewSize = pdfView.bounds.size
            
            // Calculate scale factors for both width and height
            let scaleToFitWidth = pdfViewSize.width / pageRect.width
            let scaleToFitHeight = pdfViewSize.height / pageRect.height
            
            // Use the smaller scale to ensure the entire page fits
            let scaleToFit = min(scaleToFitWidth, scaleToFitHeight)
            
            // Add some padding (reduce scale by 5% to ensure margins)
            let paddedScale = scaleToFit * 0.95
            
            // Set the scale factors
            pdfView.minScaleFactor = max(0.1, paddedScale * 0.5) // Allow zoom out to 50% of fit
            pdfView.maxScaleFactor = paddedScale * 4.0 // Allow zoom in to 4x
            pdfView.scaleFactor = paddedScale
            
            hasSetInitialScale = true
            print("✅ PDF scaled manually: \(paddedScale) (view: \(pdfViewSize), page: \(pageRect.size))")
        }
        
        deinit {
            NotificationCenter.default.removeObserver(self)
        }
    }
}

#Preview {
    PDFKitRepresentable(url: URL(string: "https://bmantzey-portfolio.web.app/documents/resume.pdf")!)
}
