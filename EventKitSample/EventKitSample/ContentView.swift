//
//  ContentView.swift
//  EventKitSample
//
//  Created by Hangyeol on 10/19/23.
//

import SwiftUI
import EventKit

struct ContentView: View {
    @AppStorage("authorizationStatus") var authorizationStatus: Bool = false
    
    @State private var eventId: String? = nil
    
    private let eventStore: EKEventStore = .init()
    
    var body: some View {
        VStack(spacing: 20) {
            Button("Request Authorization") {
                switch EKEventStore.authorizationStatus(for: .event) {
                case .notDetermined:    // 접근 허가 요구하지 않은 경우
                    print("notDetermined")
                    Task {
                        authorizationStatus = try await eventStore.requestFullAccessToEvents()
                    }
                    
                case .restricted:       // 디바이스 설정에서 접근을 제한하는 경우
                    print("restricted")
                    
                case .denied:           // 접근 거부한 경우
                    print("denied")
                    
                case .fullAccess:       // (authorized) iOS 17부터
                    print("fullAccess")
                    authorizationStatus = true
                    
                case .writeOnly:        // (authorized) iOS 17부터
                    print("writeOnly")
                    Task {
                        authorizationStatus = try await eventStore.requestFullAccessToEvents()
                    }
                    
                @unknown default:
                    print(#fileID, #function, #line, "unknown")
                }
            }
            
            Button("Save Event") {
                guard authorizationStatus else {
                    return
                }
                
                let event = EKEvent(eventStore: eventStore)
                event.calendar = eventStore.calendars(for: .event).first(where: { $0.type == .local })
                event.title = "등록 함 해볼게!"
                event.startDate = Date()
                event.endDate = event.startDate.addingTimeInterval(3600)
                event.alarms = [EKAlarm(relativeOffset: 0)]
                
                do {
                    try eventStore.save(event, span: .thisEvent, commit: true)
                    eventId = event.eventIdentifier
                    print("이벤트 등록 완료 - eventIdentifier: \(event.eventIdentifier ?? "")")
                } catch {
                    print(#fileID, #function, #line, error.localizedDescription)
                }
            }
            
            Button("Remove Event") {
                guard authorizationStatus else {
                    return
                }
                
                guard let eventId,
                      let event = eventStore.event(withIdentifier: eventId) else {
                    return
                }
                
                do {
                    try eventStore.remove(event, span: .thisEvent)
                    print("이벤트 삭제 완료")
                } catch {
                    print(#fileID, #function, #line, error.localizedDescription)
                }
            }
        }
        .padding()
        .onAppear {
            eventStore.calendars(for: .event).forEach {
                print($0)
            }
        }
    }
}

#Preview {
    ContentView()
}
