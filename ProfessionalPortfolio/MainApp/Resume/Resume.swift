//
//  Resume.swift
//  ProfessionalPortfolio
//
//  Created by Brandon Mantzey on 10/26/25.
//
// Note: To update the PDF:
// 1. Navigate to the Firebase Hosting public folder at ~/FirebaseHosting/public. The file is hosted in the documents folder.
// 2. Put the new file in place:
//    - English: "resume_en.pdf"
//    - Japanese: "resume_ja.pdf"
// 3. Deploy to Firebase: `firebase deploy --only hosting`
// The app will automatically load the correct PDF based on device language without code changes.
//

import SwiftUI
import PDFKit

struct Resume: View {
    @Environment(\.theme) var theme
    
    private var resumeURL: URL {
        // Get the current language code
        let languageCode = Locale.current.language.languageCode?.identifier ?? "en"
        
        return URL(string: "https://bmantzey-portfolio.web.app/documents/resume_" + languageCode + ".pdf")!
    }
    
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
