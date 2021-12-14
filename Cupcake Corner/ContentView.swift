//
//  ContentView.swift
//  Cupcake Corner
//
//  Created by Connor A Lynch on 13/12/2021.
//

import SwiftUI
import AVKit

extension ContentView {
    class ViewModel: ObservableObject {
        
        @Published var audioPlayer: AVPlayer!
        
        @Published var results = [ResultViewModel]()
        
        @Published var searchText: String = ""
        
        @Published var searchArtist: String = ""
        
        var filteredItems: [ResultViewModel] {
            return searchText.isEmpty ? results :
            results.filter{ $0.trackName.lowercased().contains(searchText.lowercased())
                ||
                $0.collectionName.lowercased().contains(searchText.lowercased())
                ||
                $0.artistName.lowercased().contains(searchText.lowercased())
            }
        }
        
        private var artist: String {
            let lowercased = searchArtist.lowercased()
            return lowercased.replacingOccurrences(of: " ", with: "+")
        }
        
        func fetchData() async {
            
            guard let url = URL(string: "https://itunes.apple.com/search?term=\(artist)&entity=song") else { return }
            do {
                
                let (data, _) = try await URLSession.shared.data(from: url)
                
                if let decodedResponse = try? JSONDecoder().decode(Response.self, from: data) {
                    DispatchQueue.main.async {
                        self.results = decodedResponse.results.compactMap(ResultViewModel.init)
                    }
                }else{
                    print("DEBUG: didn't work")
                }
                
            }catch let error {
                print("DEBUG: \(error.localizedDescription)")
            }
        }
    }
}

struct ContentView: View {
    
    @StateObject var viewModel: ViewModel
    
    init(viewModel: ViewModel = .init()){
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        
        VStack {
            
            TextField("Artist", text: $viewModel.searchArtist)
            
            Button {
                Task {
                    await viewModel.fetchData()
                }
            } label: {
                Text("Fetch Data")
            }

            
            TextField("Song", text: $viewModel.searchText)
            
            List{
                ForEach(viewModel.filteredItems.isEmpty ? viewModel.results : viewModel.filteredItems) { track in
                    MusicCellView(viewModel: MusicCellView.ViewModel(track: track))
                }
            }
            .listStyle(.plain)
        }
        .task {
            await viewModel.fetchData()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

extension MusicCellView {
    class ViewModel: ObservableObject {
        
        @ObservedObject var contentViewModel = ContentView.ViewModel()
        
        @Published var songURL: String?
        @Published var track: ResultViewModel
        
        init(track: ResultViewModel){
            self.track = track
        }
        
        
        func setSongURL(_ url: String){
            self.songURL = url
            self.contentViewModel.audioPlayer = AVPlayer(url: URL(string: url)!)
        }
        
        func musicPlayer(){
            track.isPlaying ? contentViewModel.audioPlayer?.play() : contentViewModel.audioPlayer?.pause()
        }
    }
}

struct MusicCellView: View {
    
    @StateObject var viewModel: ViewModel
    
    init(viewModel: ViewModel = .init(track: ResultViewModel(result: Result(trackId: 0, trackName: "", artistName: "", collectionName: "", artworkUrl100: "", previewUrl: "")))){
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(viewModel.track.trackName)
                    .font(.headline)
                Text(viewModel.track.collectionName)
                        .font(.footnote)
                Text(viewModel.track.artistName)
                    .font(.footnote).bold()
            }
            Spacer()
            
            ZStack {
                
                AsyncImage(url: URL(string: viewModel.track.image)) { phase in
                    if let img = phase.image {
                        img.resizable().scaledToFill()
                    }else if phase.error != nil {
                        Text("There was an error loading the image.")
                    } else {
                        ProgressView()
                    }
                }
                .frame(width: 100, height: 100)
                .cornerRadius(5)
                
                if viewModel.track.isPlaying {
                    Image(systemName: "pause.circle")
                        .resizable()
                        .frame(width: 50, height: 50, alignment: .center)
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 0)
                }else{
                    Image(systemName: "play.circle")
                        .resizable()
                        .frame(width: 50, height: 50, alignment: .center)
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 0)
                }
                
                
            }
            .onTapGesture {
                if viewModel.track.previewURL == viewModel.songURL {
                    viewModel.track.isPlaying.toggle()
                }else{
                    viewModel.setSongURL(viewModel.track.previewURL)
                    viewModel.track.isPlaying = true
                }
                viewModel.musicPlayer()
            }
        }
    }
}
