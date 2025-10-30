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
        ZStack {
            PDFKitRepresentable(url: pdfURL)
                .opacity(isLoading ? 0 : 1)
            
            if isLoading {
                ProgressView("Loading PDF...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground))
            }
        }
        .onAppear {
            // Give enough time for PDF to load and scale properly
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    PDFDocumentView(pdfURL: URL(string: "https://bmantzey-portfolio.web.app/documents/resume.pdf")!)
}
