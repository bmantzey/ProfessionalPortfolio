//
//  PDFDocumentView.swift
//  ProfessionalPortfolio
//
//  Created by Brandon Mantzey on 10/28/25.
//

import SwiftUI

struct PDFDocumentView: View {
    let pdfURL: URL
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading PDF...")
            } else {
                PDFKitRepresentable(url: pdfURL)
            }
        }
        .onAppear {
            // Small delay to show loading state briefly
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isLoading = false
            }
        }
    }
}

#Preview {
    PDFDocumentView(pdfURL: URL(string: "https://bmantzey-portfolio.web.app/documents/resume.pdf")!)
}
