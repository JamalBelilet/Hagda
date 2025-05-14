//
//  HagdaTests.swift
//  HagdaTests
//
//  Created by Djamaleddine Belilet on 13/05/2025.
//

import Testing
import SwiftUI
@testable import Hagda

struct ModelTests {
    @Test func sourceTypeHasCorrectIcons() {
        #expect(SourceType.article.icon == "doc.text")
        #expect(SourceType.reddit.icon == "bubble.left.fill")
        #expect(SourceType.bluesky.icon == "cloud.fill")
        #expect(SourceType.mastodon.icon == "message.fill")
        #expect(SourceType.podcast.icon == "headphones")
    }
    
    @Test func appModelOrganizesSources() {
        let model = AppModel()
        let categories = model.categories
        
        #expect(!categories.isEmpty)
        #expect(categories["Top Tech Articles"] != nil)
        #expect(categories["Popular Subreddits"] != nil)
    }
    
    @Test func sourcesHaveRequiredProperties() {
        let sources = Source.sampleSources
        #expect(!sources.isEmpty)
        
        for source in sources {
            #expect(!source.name.isEmpty)
            #expect(!source.description.isEmpty)
        }
    }
}

struct ViewTests {
    @Test func libraryViewCategoriesTitleMatch() async {
        let model = AppModel()
        let categoryKeys = model.categories.keys.sorted()
        
        for key in categoryKeys {
            #expect(!key.isEmpty)
        }
    }
}
