//
//  Resume.swift
//  ProfessionalPortfolio
//
//  Created by Brandon Mantzey on 10/26/25.
//
// Note: To update the PDF:
// 1. Navigate to the Firebase Hosting public folder at ~/FirebaseHosting/public. The file is hosted in the documents folder.
// 2. Put the new file in place. The name is "resume.pdf".
// 3. Deploy to Firebase: `firebase deploy --only hosting`
// The app will automatically load the updated PDF without code changes.
//

import SwiftUI
import PDFKit

struct Resume: View {
    @Environment(\.theme) var theme
    private let resumeURL = URL(string: "https://bmantzey-portfolio.web.app/documents/resume.pdf")!
    
    var body: some View {
        PDFDocumentView(pdfURL: resumeURL)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        theme.backgroundTertiary,
                        Color(.systemGray)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
    }
}

#Preview {
    Resume()
}
