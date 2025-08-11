//
//  ResistanceFieldsView.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI

struct ResistanceFieldsView: View {
    @Binding var weight: String
    @Binding var sets: String
    @Binding var reps: String
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Weight")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.textPrimary)
                    
                    HStack {
                        TextField("20.0", text: $weight)
                            .keyboardType(.decimalPad)
                            .font(.body)
                            .padding()
                            .background(Color.backgroundTertiary)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        
                        Text("kg")
                            .font(.body)
                            .foregroundColor(.textSecondary)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Sets")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.textPrimary)
                    
                    TextField("03", text: $sets)
                        .keyboardType(.numberPad)
                        .font(.body)
                        .padding()
                        .background(Color.backgroundTertiary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Reps")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.textPrimary)
                    
                    TextField("10", text: $reps)
                        .keyboardType(.numberPad)
                        .font(.body)
                        .padding()
                        .background(Color.backgroundTertiary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }
}