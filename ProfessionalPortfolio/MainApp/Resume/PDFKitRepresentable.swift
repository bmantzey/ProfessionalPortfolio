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
        pdfView.minScaleFactor = 0.25 // This will be updated dynamically
        
        // Set up coordinator to handle document loading and rotation
        context.coordinator.setupPDFView(pdfView, with: url)
        
        return pdfView
    }
    
    func updateUIView(_ pdfView: PDFView, context: Context) {
        // Only reload if URL changed
        if pdfView.document?.documentURL != url {
            context.coordinator.setupPDFView(pdfView, with: url)
        } else {
            // Check if view size changed (rotation) and adjust if needed
            context.coordinator.handleViewSizeChange(pdfView)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject {
        private var pdfView: PDFView?
        private var hasSetInitialScale = false
        private var lastViewSize: CGSize = .zero
        
        func setupPDFView(_ pdfView: PDFView, with url: URL) {
            self.pdfView = pdfView
            self.hasSetInitialScale = false
            self.lastViewSize = .zero
            
            // Add observer for when document loads
            NotificationCenter.default.removeObserver(self)
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(documentDidLoad),
                name: .PDFViewDocumentChanged,
                object: pdfView
            )
            
            // Add observer for device rotation
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(orientationDidChange),
                name: UIDevice.orientationDidChangeNotification,
                object: nil
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
            
            // Wait a bit for view to be fully laid out
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                self?.setFitToWidthScale(pdfView)
            }
        }
        
        @objc private func orientationDidChange() {
            guard let pdfView = self.pdfView else { return }
            
            // Handle rotation more quickly to catch the size change
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.handleViewSizeChange(pdfView)
            }
        }
        
        func handleViewSizeChange(_ pdfView: PDFView) {
            let currentSize = pdfView.bounds.size
            
            // Check if the view size has actually changed (indicating rotation or resize)
            if currentSize != lastViewSize && currentSize.width > 0 && currentSize.height > 0 {
                lastViewSize = currentSize
                
                // Scroll to top immediately, but give a tiny delay to ensure view is ready
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    if let document = pdfView.document, let firstPage = document.page(at: 0) {
                        pdfView.go(to: firstPage)
                    }
                }
                
                // Recalculate and set the fit-to-width scale
                setFitToWidthScale(pdfView, animated: true)
            }
        }
        
        private func setFitToWidthScale(_ pdfView: PDFView, animated: Bool = false) {
            guard pdfView.bounds.width > 0,
                  pdfView.bounds.height > 0,
                  let document = pdfView.document,
                  let firstPage = document.page(at: 0) else {
                
                // If not ready yet, try again after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                    self?.setFitToWidthScale(pdfView, animated: animated)
                }
                return
            }
            
            let pageRect = firstPage.bounds(for: .mediaBox)
            let pdfViewSize = pdfView.bounds.size
            
            // Calculate scale to fit width exactly (this becomes our minimum)
            let scaleToFitWidth = pdfViewSize.width / pageRect.width
            
            // Add small padding to ensure content doesn't touch edges
            let fitWidthScale = scaleToFitWidth * 0.95
            
            // Update scale factors
            let newMinScale = fitWidthScale
            let newMaxScale = fitWidthScale * 4.0
            
            pdfView.minScaleFactor = newMinScale
            pdfView.maxScaleFactor = newMaxScale
            
            // For initial load or significant changes, set to fit width
            // For rotations, animate to fit width
            if animated {
                UIView.animate(withDuration: 0.3, animations: {
                    pdfView.scaleFactor = fitWidthScale
                })
            } else {
                pdfView.scaleFactor = fitWidthScale
            }
            
            hasSetInitialScale = true
            lastViewSize = pdfViewSize
            
            print("✅ PDF scaled to fit width: \(fitWidthScale) (view: \(pdfViewSize), page: \(pageRect.size))")
        }
        
        deinit {
            NotificationCenter.default.removeObserver(self)
        }
    }
}

#Preview {
    PDFKitRepresentable(url: URL(string: "https://bmantzey-portfolio.web.app/documents/resume.pdf")!)
}
