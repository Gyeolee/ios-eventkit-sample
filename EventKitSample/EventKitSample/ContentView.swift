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
            Button("Request Authorization", action: checkAuthorizationStatus)
            
            Button("Save Event", action: saveCalendarEvent)
            
            Button("Remove Event", action: removeCalendarEvent)
        }
        .padding()
        .onAppear {
            eventStore.calendars(for: .event).forEach {
                print($0)
            }
        }
    }
}

extension ContentView {
    private func checkAuthorizationStatus() {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .notDetermined:    // 접근 허가 요구하지 않은 경우
            print("notDetermined")
            requestAuthorizationAccess()
            
        case .restricted:       // 디바이스 설정에서 접근을 제한하는 경우
            print("restricted")
            
        case .denied:           // 접근 거부한 경우
            print("denied")
            
        case .fullAccess:       // (authorized) iOS 17부터
            print("fullAccess")
            authorizationStatus = true
            
        case .writeOnly:        // (authorized) iOS 17부터
            print("writeOnly")
            requestAuthorizationAccess()
            
        @unknown default:
            print(#fileID, #function, #line, "unknown")
        }
    }
    
    private func requestAuthorizationAccess() {
        Task {
            authorizationStatus = try await eventStore.requestFullAccessToEvents()
        }
    }
    
    private func saveCalendarEvent() {
        guard authorizationStatus else {
            checkAuthorizationStatus()
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
    
    private func removeCalendarEvent() {
        guard authorizationStatus else {
            checkAuthorizationStatus()
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

#Preview {
    ContentView()
}
