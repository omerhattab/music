//
//  ViewController.swift
//  Music
//
//  Created by btk-mac on 13.05.2022.
//

import UIKit

enum BrowswSectionType{
    case newRelease(viewModels:[NewReleasesCellViewModel])
    case featuredPlaylists(viewModels:[NewReleasesCellViewModel])
    case recommendedTracks(viewModels:[NewReleasesCellViewModel])
}

class HomeViewController: UIViewController {

    private var collectionView: UICollectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewCompositionalLayout{ (sectionIndex, _) -> NSCollectionLayoutSection? in
            return HomeViewController.createSectionLayout(section: sectionIndex)
        }
   )
    
    private let spinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView()
        spinner.tintColor = .label
        spinner.hidesWhenStopped = true
        return spinner
    }()
    
    private var sections = [BrowswSectionType]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Home"
        
        view.backgroundColor = .systemBackground
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "gear"), style: .done, target: self, action: #selector(didTapSettings))
        configureCollectionView()
        view.addSubview(spinner)
        fetchData()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionView.frame = view.bounds
    }
    
    private func configureCollectionView(){
        view.addSubview(collectionView)
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        collectionView.register(NewReleaseCollectionViewCell.self, forCellWithReuseIdentifier: NewReleaseCollectionViewCell.identifier)
        collectionView.register(FeaturedPlaylistCollectionViewCell.self, forCellWithReuseIdentifier: FeaturedPlaylistCollectionViewCell.identifier)
        collectionView.register(RecommendedTrackCollectionViewCell.self, forCellWithReuseIdentifier: RecommendedTrackCollectionViewCell.identifier)
        collectionView.dataSource = self
        collectionView.delegate = self
    }
    
    private func fetchData(){
        let group = DispatchGroup()
        group.enter()
        group.enter()
        group.enter()
        
        var newRelease: NewReleaseResponse?
        var featuredPlaylist : FeaturedPlaylistsResponse?
        var recommendedGenres: RecommendationsResponse?
        // New Releases
        APICaller.shared.getNewsReleases { (result) in
            defer{
                group.leave()
            }
            
            switch result{
            case .success(let model):
                newRelease = model
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
        
        // Featured Playlist
        APICaller.shared.getFeaturedPlayLists { (result) in
            defer{
                group.leave()
            }
            
            switch result{
            case .success(let model):
                featuredPlaylist = model
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
        
        // Recommended
        APICaller.shared.gerRecommendedGenres{ (result) in
            switch result{
            case .success(let model):
                let genres = model.genres
                var seeds = Set<String>()
                while seeds.count < 5 {
                    if let random = genres.randomElement(){
                        seeds.insert(random)
                    }
                }
                
                APICaller.shared.getRecommendations(genres: seeds) { recommendedResult in
                    switch recommendedResult{
                    case .success(let model):
                        recommendedGenres = model
                    case .failure(let error):
                        print(error.localizedDescription)
                    }
                }
                
            case .failure(let error): break
            }
        }
        
        group.notify(queue: .main) {
            guard let newAlbums = newRelease?.albums.items,
                  let playlists = featuredPlaylist?.playlists.items,
                  let tracks = recommendedGenres?.tracks else {
                return
            }
            
            self.configureModels(newAlbums: newRelease, playlist: playlists, tracks: tracks)
        }
        
    }
    
    private func configureModels(newAlbums: [Album], playlist: [Playlist], tracks: [AudioTrack]){
        // Configure Models
        sections.append(.newRelease(viewModels: newAlbums.compactMap({
            return NewReleasesCellViewModel(name: $0.name, artworkURL: URL(string: $0.images.first?.url ?? ""), numberOfTrack: $0.total_tracks, artistName: $0.artists.first?.name ?? "-")
        })))
        sections.append(.featuredPlaylists(viewModels: []))
        sections.append(.recommendedTracks(viewModels: []))
    }
    
    @objc func didTapSettings(){
        let vc = SettingsViewController()
        vc.title = "Settings"
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
        
    }


}

extension HomeViewController: UICollectionViewDelegate, UICollectionViewDataSource{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let type = sections[section]
        switch type {
        case .newRelease(let viewModels):
            return viewModels.count
        case .featuredPlaylists(let viewModels):
            return viewModels.count
        case .recommendedTracks(let viewModels):
            return viewModels.count
        }
        return 20
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return sections.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        if indexPath.section == 0{
            cell.backgroundColor = .systemGreen
        }
        else if indexPath.section == 1{
            cell.backgroundColor = .systemPink
        }
        else if indexPath.section == 2{
            cell.backgroundColor = .systemBlue
        }
        return cell
    }
    
    static func createSectionLayout(section: Int) -> NSCollectionLayoutSection{
        switch section {
        case 0:
            //Item
            let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0)))
            item.contentInsets = NSDirectionalEdgeInsets(top: 2, leading: 2, bottom: 2, trailing: 2)

            //Vertical Group in Horizantal
            let verticalGroup = NSCollectionLayoutGroup.vertical(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(390)), subitem: item, count: 3)
            
            let horizontalGroup = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.9), heightDimension: .absolute(390)), subitem: verticalGroup, count: 1)
                    
            //Sectioon
            let section = NSCollectionLayoutSection(group: horizontalGroup)
            section.orthogonalScrollingBehavior = .groupPaging
            return section
        case 1:
            //Item
            let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .absolute(200), heightDimension: .absolute(200)))
            item.contentInsets = NSDirectionalEdgeInsets(top: 2, leading: 2, bottom: 2, trailing: 2)
            
            
            let verticalGroup = NSCollectionLayoutGroup.vertical(layoutSize: NSCollectionLayoutSize(widthDimension: .absolute(200), heightDimension: .absolute(400)), subitem: item, count: 2)
            
            let horizontalGroup = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .absolute(200), heightDimension: .absolute(400)), subitem: verticalGroup, count: 1)
                    
            //Sectioon
            let section = NSCollectionLayoutSection(group: horizontalGroup)
            section.orthogonalScrollingBehavior = .continuous
            return section
        case 2:
            //Item
            let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0)))
            item.contentInsets = NSDirectionalEdgeInsets(top: 2, leading: 2, bottom: 2, trailing: 2)

            //Vertical Group
            let group = NSCollectionLayoutGroup.vertical(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(80)), subitem: item, count: 1)
                    
            //Sectioon
            let section = NSCollectionLayoutSection(group: group)
            return section
        default:
            //Item
            let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0)))
            item.contentInsets = NSDirectionalEdgeInsets(top: 2, leading: 2, bottom: 2, trailing: 2)

            //Group
            let group = NSCollectionLayoutGroup.vertical(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(390)), subitem: item, count: 1)
                    
            //Sectioon
            let section = NSCollectionLayoutSection(group: group)
            return section
        }
    }
    
    
}

