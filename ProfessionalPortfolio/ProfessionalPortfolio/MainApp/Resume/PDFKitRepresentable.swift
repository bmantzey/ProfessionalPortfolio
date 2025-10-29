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
        pdfView.autoScales = false // Don't auto scale to avoid jumping
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.maxScaleFactor = 4.0  // Allow zooming up to 4x
        pdfView.scaleFactor = 1.0
        pdfView.minScaleFactor = 0.1
        let fitWidthScale = pdfView.scaleFactorForSizeToFit
        if fitWidthScale > 0 {
            pdfView.minScaleFactor = fitWidthScale
            pdfView.scaleFactor = fitWidthScale
        }
        
        return pdfView
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        if let document = PDFDocument(url: url) {
            pdfView.document = document
            
            // Set the minimum scale factor to fit width after document is loaded
            DispatchQueue.main.async {
                let fitWidthScale = pdfView.scaleFactorForSizeToFit
                if fitWidthScale > 0 {
                    pdfView.minScaleFactor = fitWidthScale
                    pdfView.scaleFactor = fitWidthScale
                }
            }
        }
    }
}

#Preview {
    PDFView()
}
