//
//  ContentView.swift
//  CardSwipeExample
//
//  Created by MacBook Pro on 04/03/23.
//

import SwiftUI
import SwiftSoup


struct ContentView: View {
    
    @State var cards: [ExampleCardView]
    
    var body: some View {
        VStack {
            Text("🐦‍⬛ Twitter Swiper")
                .font(.title)
                .foregroundColor(.blue)
            
            // Cards
            CardSwiperView(cards: self.$cards , onCardSwiped: { swipeDirection, index in
                
                let tweetID = self.cards[index].tweetID
                
                switch swipeDirection {
                case .left:
                    print("")
                case .right:
                    print("Card with Tweet ID \(tweetID) swiped right direction ➡️")
                case .top:
                    print("")
                case .bottom:
                    print("")
                }

                //switch swipeDirection {
                //case .left:
                    //print("Card with Tweet ID \(tweetID) swiped left direction ⬅️")
                //case .right:
                    //print("Card with Tweet ID \(tweetID) swiped right direction ➡️")
                    //saveToFile(tweetID: tweetID)
                //case .top:
                    //print("Card with Tweet ID \(tweetID) swiped top direction ⬆️")
                //case .bottom:
                    //print("Card with Tweet ID \(tweetID) swiped bottom direction ⬇️")
                //}
            }, onCardDragged: { swipeDirection, index, offset in
                //print("Card dragged \(swipeDirection) direction at index \(index) with offset \(offset)")
            })
            .padding(.vertical, 20)
        }
        .onAppear {
            loadCards()
        }
    }
    
    private func saveToFile(tweetID: String) {
        let fileName = "SwipedCards.txt"
        let documentDirURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let fileURL = documentDirURL.appendingPathComponent(fileName)
        
        let writeString = "\(tweetID)\n"
        if FileManager.default.fileExists(atPath: fileURL.path) {
            // If the file exists, append to it
            if let fileHandle = try? FileHandle(forWritingTo: fileURL) {
                fileHandle.seekToEndOfFile()
                fileHandle.write(writeString.data(using: .utf8)!)
                fileHandle.closeFile()
            }
        } else {
            // If the file doesn't exist, create it and write
            try? writeString.write(to: fileURL, atomically: true, encoding: String.Encoding.utf8)
        }
    }
    
    private func loadCards() {
        var newCards: [ExampleCardView] = []
        var htmlString: String? = nil
        
        do {
            if let filepath = Bundle.main.path(forResource: "twitter-UserTweets-1708383865061", ofType: "html") {
                do {
                    htmlString = try String(contentsOfFile: filepath)
                    //print(htmlString ?? "Empty html")
                } catch {
                    // Handle error
                }
            } else {
            }
            
            do {
                let document: Document = try SwiftSoup.parse(htmlString ?? "empty")
                let rows: Elements = try document.select("tr") // Select all table rows
                
                for (index, row) in rows.array().enumerated() {
                    let tds: Elements = try row.select("td")
                    
                    // Safely check if the expected td elements exist
                    guard tds.size() > 3 else { continue } // Skip rows that don't have at least 4 td elements
                    
                    let tweetID = try tds.get(0).text() // Extract tweetID from the first td
                    let fullText = try tds.get(2).text() // Extract full_text from the third td
                    let mediaElement = try tds.get(3).select("img").first() // Attempt to select the first img within the fourth td
                    var mediaUrl = try mediaElement?.attr("src") // Extract the src attribute of the img tag
                    
                    if var url = mediaUrl, let range = url.range(of: "name=thumb") {
                        url.replaceSubrange(range, with: "name=orig")
                        mediaUrl = url // If you need to update the original optional variable
                    }
                    
                    // Debug print to console
                    print("Row \(index): Tweet ID: \(tweetID) Full Text: \(fullText), Media URL: \(mediaUrl ?? "No media")")
                    
                    // Initialize ExampleCardView with the extracted data
                    if let media = mediaUrl, !media.isEmpty {
                        newCards.append(ExampleCardView(index: index, tweetID: tweetID, fullText: fullText, mediaUrl: media))
                    } else {
                        // Handle cases where there is no media URL
                        newCards.append(ExampleCardView(index: index, tweetID: tweetID, fullText: fullText, mediaUrl: nil))
                    }
                }
                
            } catch Exception.Error(let type, let message) {
                print("Error of type \(type) with message: \(message)")
            } catch {
                print("An error occurred")
            }
            
            // Assigning the new array instance to the @State variable
            cards = newCards
        }
    }
    
    
    struct ExampleCardView: View {
        var index: Int
        var tweetID: String
        var fullText: String
        var mediaUrl: String?
        var tagId: UUID = UUID()
        
        var selectedColor: UIColor {
            let index = index
            let hexColors = ["#FF0000FF", "#0000FFFF", "#FFFF00FF"] // Define the hex colors array
            let selectedHex = hexColors[index % hexColors.count] // Dynamically select a hex color
            return UIColor(hex: selectedHex) ?? UIColor.clear // Convert to UIColor, defaulting to clear if nil
        }
        
        var body: some View {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                //.shadow(color: Color(selectedColor), radius: 5)
                .frame(width: 320, height: 420) // Specify the size
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color(selectedColor), lineWidth: 8) // Frame color and line width
                    )
                
                .overlay(
                    VStack(spacing: 10) {
                        Text(fullText)
                            .font(.body)
                            .lineLimit(nil) // Use nil for multi-line text
                            .minimumScaleFactor(0.5) // Adjusts font size down to 50% if needed
                        if let mediaUrl = mediaUrl {
                            AsyncImage(url: URL(string: mediaUrl)) { image in
                                image
                                    .resizable() // Make the image resizable
                                    .aspectRatio(contentMode: .fit)
                            } placeholder: {
                                Color.white
                            }
                            .aspectRatio(contentMode: .fit)
                        }
                    }
                        .padding()
                )
                //.shadow(color: Color(selectedColor), radius: 5)
        }
    }
    
    struct ContentView_Previews: PreviewProvider {
        static var previews: some View {
            ContentView(cards: [])
        }
    }
}
