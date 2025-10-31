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
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.autoScales = false
        pdfView.document = PDFDocument(url: url)
        
        context.coordinator.setup(pdfView: pdfView)
        return pdfView
    }
    
    func updateUIView(_ pdfView: PDFView, context: Context) {
        // Do nothing - handle everything through orientation notifications
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject {
        private weak var pdfView: PDFView?
        
        func setup(pdfView: PDFView) {
            self.pdfView = pdfView
            
            // Listen for orientation changes
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(orientationChanged),
                name: UIDevice.orientationDidChangeNotification,
                object: nil
            )
            
            // Initial setup
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.fitToWidth()
            }
        }
        
        @objc private func orientationChanged() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.fitToWidth()
            }
        }
        
        private func fitToWidth() {
            guard let pdfView = pdfView,
                  let document = pdfView.document,
                  let page = document.page(at: 0),
                  pdfView.bounds.width > 0 else { return }
            
            let scale = pdfView.bounds.width / page.bounds(for: .mediaBox).width
            
            pdfView.minScaleFactor = scale
            pdfView.maxScaleFactor = scale * 4
            pdfView.scaleFactor = scale
            pdfView.go(to: page)
            
            print("✅ PDF scaled: \(scale), bounds: \(pdfView.bounds.size)")
        }
        
        deinit {
            NotificationCenter.default.removeObserver(self)
        }
    }
}

#Preview {
    PDFKitRepresentable(url: URL(string: "https://bmantzey-portfolio.web.app/documents/resume.pdf")!)
}
