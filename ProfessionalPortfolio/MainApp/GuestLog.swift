//
//  GuestLog.swift
//  ProfessionalPortfolio
//
//  Created by Brandon Mantzey on 10/26/25.
//

import SwiftUI
import MapKit

// TODO: Figure out the best implementation of a map view.
/*
 Want to have a "Sign My Guest Log" link in a space somewhere on the screen that will:
 1. Display the pins for all users that have signed the guest log.
 2. Prompt for permission to use the user's location.
 3. Present a text box that prompts them to “Introduce yourself, give feedback, or say anything."
 4. Submit the GPS location and text feedback when submitted.
 5. Tapping on a pin will show the text feedback that was submitted by the user at that location.
 6. Have an AI summary of all user feedback displayed near where the button to sign the guest book is.
 */

struct GuestLog: View {
    var body: some View {
        Text("You are in the Guest Log View!")
    }
}

#Preview {
    GuestLog()
}
