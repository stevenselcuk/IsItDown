//
//  FontHelper.swift
//  YouBar
//
//  Created by Steven J. Selcuk on 16.08.2022.
//

import SwiftUI

extension View {
    func fontBold(color: Color = .black, size: CGFloat) -> some View {
        font(.custom("Circe-Bold", size: size))
    }

    func fontRegular(color: Color = .black, size: CGFloat) -> some View {
        font(.custom("Circe", size: size))
    }

    func fontLight(color: Color = .black, size: CGFloat) -> some View {
        font(.custom("Circe-Light", size: size))
    }
    
    func fontMonoMedium(color: Color = .black, size: CGFloat) -> some View {
        font(.custom("Cartograph Mono CF Medium", size: size))
    }
}
