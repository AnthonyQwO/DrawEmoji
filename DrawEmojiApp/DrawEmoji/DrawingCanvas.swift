//
//  DrawingCanvas.swift
//  DrawEmoji
//
//  Created by Tang Anthony on 2025/5/15.
//
//
//import SwiftUI
//
//struct DrawingView: View {
//    @Binding var lines: [Line]
//    @GestureState private var gestureLine = Line()
//    @State private var latestLine = Line()
//    
//    var body: some View {
//        ZStack {
//            // 已完成線條
//            ForEach(lines) { line in
//                Path { path in
//                    guard let first = line.points.first else { return }
//                    path.move(to: first)
//                    for point in line.points.dropFirst() {
//                        path.addLine(to: point)
//                    }
//                }
//                .stroke(Color.black, lineWidth: 3)
//            }
//            
//            // 當前繪圖中線條（灰色）
//            Path { path in
//                guard let first = gestureLine.points.first else { return }
//                path.move(to: first)
//                for point in gestureLine.points.dropFirst() {
//                    path.addLine(to: point)
//                }
//            }
//            .stroke(Color.gray, lineWidth: 2)
//        }
//        .contentShape(Rectangle())
//        .gesture(
//            DragGesture(minimumDistance: 0.1)
//                .updating($gestureLine) { value, state, _ in
//                    state.points.append(value.location)
//                }
//                .onChanged { value in
//                    latestLine.points.append(value.location)
//                }
//                .onEnded { _ in
//                    lines.append(latestLine)
//                    latestLine = Line()
//                }
//        )
//    }
//}
//
//// MARK: - Drawing Data Model
//struct Line: Identifiable {
//    var id = UUID()
//    var points: [CGPoint] = []
//}
//
//#Preview {
//    ContentView()
//}
