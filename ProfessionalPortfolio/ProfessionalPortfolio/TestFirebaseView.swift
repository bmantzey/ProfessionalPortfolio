//
//  TestFirebaseView.swift
//  ProfessionalPortfolio
//
//  Created by Brandon Mantzey on 10/22/25.
//

import SwiftUI
import FirebaseAuth

struct TestFirebaseView: View {
    @State private var status = "Click to test Firebase..."
    private var email = "test2@test.com"
    private var password = "password123"

    var body: some View {
        Text(status)
            .padding()
        Button("Test Create User") {
            status = "Testing create user..."
            Auth.auth().createUser(withEmail: email, password: password) { result, error in
                if let error = error {
                    status = "Error: \(error.localizedDescription)"
                } else {
                    status = "Success! User created successfully!"
                }
            }
        }
        .padding()
        Button("Test Authenticate") {
            status = "Testing authenticate..."
            Auth.auth().signIn(withEmail: email, password: password) { result, error in
                if let error = error {
                    status = "Error: \(error.localizedDescription)"
                } else {
                    status = "Success! Authenticated successfully!"
                }
            }
        }
    }
}

#Preview {
    TestFirebaseView()
}
