//
//  CardioFieldsView.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI

struct CardioFieldsView: View {
    @Binding var distance: String
    @Binding var duration: String
    
    var body: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Distance")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)
                
                HStack {
                    TextField("5.0", text: $distance)
                        .keyboardType(.decimalPad)
                        .font(.body)
                        .padding()
                        .background(Color.backgroundTertiary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    Text("km")
                        .font(.body)
                        .foregroundColor(.textSecondary)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Duration")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)
                
                HStack {
                    TextField("00", text: .constant(""))
                        .keyboardType(.numberPad)
                        .font(.body)
                        .padding()
                        .background(Color.backgroundTertiary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    Text("Hour")
                        .font(.body)
                        .foregroundColor(.textSecondary)
                    
                    TextField("30", text: $duration)
                        .keyboardType(.numberPad)
                        .font(.body)
                        .padding()
                        .background(Color.backgroundTertiary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    Text("Min")
                        .font(.body)
                        .foregroundColor(.textSecondary)
                }
            }
        }
    }
}