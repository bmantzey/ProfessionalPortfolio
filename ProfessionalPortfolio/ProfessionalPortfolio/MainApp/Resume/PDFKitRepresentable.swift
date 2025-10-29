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
    let pdfView = PDFView()

    func makeUIView(context: Context) -> some UIView {
        pdfView.document = PDFDocument(url: url)
        
        // Configure scaling behavior
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        
        // Set scale factors - minScaleFactor will be the "fit width" scale
        pdfView.minScaleFactor = pdfView.scaleFactorForSizeToFit
        pdfView.maxScaleFactor = 4.0  // Allow zooming up to 4x
        
        return pdfView
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        if let document = PDFDocument(url: url) {
            pdfView.document = document
            
            // Set the minimum scale factor to fit width after document is loaded
            DispatchQueue.main.async {
                pdfView.minScaleFactor = pdfView.scaleFactorForSizeToFit
                pdfView.scaleFactor = pdfView.scaleFactorForSizeToFit // Start at fit-width
            }
        }
    }
}

#Preview {
    PDFView()
}
