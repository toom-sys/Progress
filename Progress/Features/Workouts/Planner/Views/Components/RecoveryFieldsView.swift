//
//  RecoveryFieldsView.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI

struct RecoveryFieldsView: View {
    @Binding var recoveryType: RecoveryType
    @Binding var duration: String
    
    var body: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Category")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)
                
                Menu {
                    ForEach(RecoveryType.allCases, id: \.self) { type in
                        Button(type.displayName) {
                            recoveryType = type
                        }
                    }
                } label: {
                    HStack {
                        Text(recoveryType.displayName)
                            .font(.body)
                            .foregroundColor(.textPrimary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.down")
                            .foregroundColor(.textSecondary)
                    }
                    .padding()
                    .background(Color.backgroundTertiary)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
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