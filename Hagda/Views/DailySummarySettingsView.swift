import SwiftUI

/// A view for customizing the daily summary settings
struct DailySummarySettingsView: View {
    @Environment(AppModel.self) private var appModel
    
    // Create state variables bound to the app model settings
    @State private var showWeather: Bool
    @State private var includeTodayEvents: Bool
    @State private var summarizeSource: Bool
    @State private var summaryLength: DailySummarySettings.SummaryLength
    @State private var sortingOrder: DailySummarySettings.SummarySort
    
    init() {
        // Initialize state variables with default values that will be updated in onAppear
        _showWeather = State(initialValue: true)
        _includeTodayEvents = State(initialValue: true)
        _summarizeSource = State(initialValue: true)
        _summaryLength = State(initialValue: .medium)
        _sortingOrder = State(initialValue: .newest)
    }
    
    var body: some View {
        List {
            // Priority Sources Section
            Section {
                ForEach(appModel.feedSources) { source in
                    HStack {
                        Label {
                            Text(source.name)
                        } icon: {
                            Image(systemName: source.type.icon)
                                .foregroundStyle(priorityIconColor(for: source))
                        }
                        
                        Spacer()
                        
                        if appModel.isSourcePrioritized(source) {
                            Image(systemName: "star")
                                .foregroundStyle(.yellow)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation {
                            appModel.toggleSourcePrioritization(source)
                        }
                    }
                }
            } header: {
                Text("Priority Sources")
            } footer: {
                Text("Starred sources will be featured more prominently in your personalized brief.")
            }
            
            // Display Options Section
            Section {
                Toggle("Show Weather", isOn: $showWeather)
                    .onChange(of: showWeather) { _, newValue in
                        appModel.updateDailySummarySettings(showWeather: newValue)
                    }
                
                Toggle("Include Today's Events", isOn: $includeTodayEvents)
                    .onChange(of: includeTodayEvents) { _, newValue in
                        appModel.updateDailySummarySettings(includeTodayEvents: newValue)
                    }
                
                Toggle("Summarize Source Content", isOn: $summarizeSource)
                    .onChange(of: summarizeSource) { _, newValue in
                        appModel.updateDailySummarySettings(summarizeSource: newValue)
                    }
            } header: {
                Text("Display Options")
            }
            
            // Content Length Section
            Section {
                Picker("Summary Length", selection: $summaryLength) {
                    ForEach(DailySummarySettings.SummaryLength.allCases) { length in
                        Text(length.rawValue).tag(length)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: summaryLength) { _, newValue in
                    appModel.updateDailySummarySettings(summaryLength: newValue)
                }
            } header: {
                Text("Summary Length")
            } footer: {
                Text("Choose the level of detail for your personalized brief.")
            }
            
            // Sort Order Section
            Section {
                Picker("Sort Order", selection: $sortingOrder) {
                    ForEach(DailySummarySettings.SummarySort.allCases) { order in
                        Text(order.rawValue).tag(order)
                    }
                }
                #if os(iOS) || os(visionOS)
                .pickerStyle(.navigationLink)
                #else
                .pickerStyle(.menu)
                #endif
                .onChange(of: sortingOrder) { _, newValue in
                    appModel.updateDailySummarySettings(sortingOrder: newValue)
                }
                
                // Explanation text based on current selection
                if sortingOrder == .newest {
                    Text("Displays most recent content at the top.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if sortingOrder == .trending {
                    Text("Highlights trending content at the top.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if sortingOrder == .priority {
                    Text("Puts content from your starred sources at the top.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Content Sorting")
            }
        }
        #if os(iOS) || os(visionOS)
        .listStyle(.insetGrouped)
        #else
        .listStyle(.inset)
        #endif
        .onAppear {
            // Load current settings from app model
            showWeather = appModel.dailySummarySettings.showWeather
            includeTodayEvents = appModel.dailySummarySettings.includeTodayEvents
            summarizeSource = appModel.dailySummarySettings.summarizeSource
            summaryLength = appModel.dailySummarySettings.summaryLength
            sortingOrder = appModel.dailySummarySettings.sortingOrder
        }
    }
    
    /// Returns the appropriate color for source's priority icon
    private func priorityIconColor(for source: Source) -> Color {
        appModel.isSourcePrioritized(source) ? .yellow : .accentColor
    }
}

#Preview {
    NavigationStack {
        DailySummarySettingsView()
            .environment(AppModel())
    }
}