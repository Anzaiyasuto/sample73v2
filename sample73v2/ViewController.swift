//
//  ViewController.swift
//  sample73v2
//
//  Created by AnzaiYasuto al18011 on 2022/07/03.
//

import UIKit
import GoogleMaps
import Direction
import GooglePlaces
import GoogleMapsUtils

class ViewController: UIViewController, GMUClusterManagerDelegate, GMUClusterRendererDelegate{
    
    var latitude: [Double] = [35.6835,35.6772,35.6847,35.6779]  //緯度
    var longitude: [Double] = [139.7708,139.7669,139.7656,139.7634] //経度
    var zoom: Float = 8.0 //縮尺
    
    var clusterManager: GMUClusterManager!
    
    
    /*----*/
    override func loadView() {
        super.loadView()
        let camera = GMSCameraPosition.camera(withLatitude: latitude[0],
                                              longitude: longitude[0],
                                              zoom: zoom)
        let mapView = GMSMapView.map(withFrame: view.frame,
                                     camera: camera)
        view = mapView
        
        //クラスタの画像について
        let iconGenerator: GMUDefaultClusterIconGenerator!
        iconGenerator = GMUDefaultClusterIconGenerator()
        let algorithm = GMUNonHierarchicalDistanceBasedAlgorithm()
        let renderer = GMUDefaultClusterRenderer(mapView: mapView, clusterIconGenerator: iconGenerator)
        renderer.delegate = self
        clusterManager = GMUClusterManager(map: mapView, algorithm: algorithm, renderer: renderer)
        clusterManager.cluster()
        clusterManager.setDelegate(self, mapDelegate: self)
        refresh()
        
    }
    
    func refresh(){
        //クラスター全削除
        self.clusterManager.clearItems()
        
        for i in 0..<latitude.count{
            let position = CLLocationCoordinate2DMake(latitude[i], longitude[i])
            let item = POIItem(position: position)
            self.clusterManager.add(item)
        }
    }
    /*---*/
    
    private lazy var mapView: GMSMapView = {
        let camera = GMSCameraPosition.camera(
            withLatitude: 36.0,
            longitude: 140.0,
            zoom: 8.0)
        let view = GMSMapView.map(withFrame: view.frame, camera: camera)
        view.isMyLocationEnabled = true
        view.settings.myLocationButton = true
        view.delegate = self
        return view
    }()
    
    // 現在地の座標を格納する変数
    private var current: CLLocationCoordinate2D?
    private var apiClient: APIClient = APIClient()
    // Locationの取得に必要なManager
    private lazy var locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        // ViewControllerでCLLocationManagerDelegateのメソッドを利用できるように
        manager.delegate = self
        return manager
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(mapView)
        
        //単体マーカー

        
        // Locationを取得開始する
        locationManager.startUpdatingLocation()
    }
    
    
    private func plotData() {
        let marker = GMSMarker()
        marker.position = CLLocationCoordinate2DMake(35.68154, 139.752498)
        marker.title = "the imperial palace"
        marker.snippet = "Tokyo"
        marker.map = mapView
        return
    }
    
    private func showRoute(start: CLLocationCoordinate2D, end: CLLocationCoordinate2D) {
        Task {
            do {
                // APIで経路情報を取得
                let direction = try await apiClient.fetchRoute(start: "\(start.latitude),\(start.longitude)",
                                                               end: "\(end.latitude),\(end.longitude)")
                guard let route = direction.routes.first, let leg = route.legs.first else { return }
                // UI処理はMainThreadにて
                print("-------------------")
                
                
                DispatchQueue.main.async { [self] in
                    // legのstepsに曲がる交差点間の経路配列が入っている
                    leg.steps.forEach {
                        // 経路を結ぶ線を描く
                        let path = GMSMutablePath()
                        path.add(CLLocationCoordinate2D(latitude: $0.startLocation.lat,
                                                        longitude: $0.startLocation.lng))
                        print($0.startLocation.lat, $0.startLocation.lng)
                        path.add(CLLocationCoordinate2D(latitude: $0.endLocation.lat,
                                                        longitude: $0.endLocation.lng))
                        let polyline = GMSPolyline(path: path)
                        polyline.strokeWidth = 3
                        polyline.strokeColor = .blue
                        polyline.map = self.mapView
                        
                        self.updateCameraZoom(startLat: leg.startLocation.lat, startLng: leg.startLocation.lng, endLat: leg.endLocation.lat, endLng: leg.endLocation.lng)
                        
                    }
                }
                print("-------------------")
            } catch let error {
                print(error)
            }
        }
    }
    
    private func updateCameraZoom(startLat: Double, startLng: Double, endLat: Double, endLng: Double) {
        let startCoordinate = CLLocationCoordinate2D(latitude: startLat, longitude: startLng)
        let endCoordinate = CLLocationCoordinate2D(latitude: endLat, longitude: endLng)
        let bounds = GMSCoordinateBounds(coordinate: startCoordinate, coordinate: endCoordinate)
        let cameraUpdate  = GMSCameraUpdate.fit(bounds, withPadding: 16.0)
        mapView.moveCamera(cameraUpdate)
    }
    
    
}

class POIItem: NSObject, GMUClusterItem {
    var position: CLLocationCoordinate2D
    
    init(position: CLLocationCoordinate2D) {
        self.position = position
    }
}

extension ViewController: CLLocationManagerDelegate {
    // 現在地が更新された時にはしる処理
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        current = locations.first?.coordinate
        //print("--------------")
        //print(locations.first?.coordinate.latitude)
        //print(locations.first?.coordinate.longitude)
        //print("--------------")
    }
}

extension ViewController: GMSMapViewDelegate {
    // マップを長押しするとはしる処理
    func mapView(_ mapView: GMSMapView, didLongPressAt coordinate: CLLocationCoordinate2D) {
        // 長押しした地点の座標
        print(coordinate)
        // マーカーが既にあれば取り除く
        mapView.clear()
        // マーカーを立てる
        let marker = GMSMarker(position: coordinate)
        marker.icon = GMSMarker.markerImage(with: .green)
        marker.map = mapView
        
        if let current = current {
            // 現在地とマーカー地点の経路を表示
            showRoute(start: current, end: coordinate)
            // ついでに、現在とマーカーを表示するようにカメラを移動
            let bounds = GMSCoordinateBounds(coordinate: current, coordinate: coordinate)
            let update = GMSCameraUpdate.fit(bounds)
            mapView.moveCamera(update)
        }
        plotData()
    }
}

final class APIClient {
    
    struct Direction: Codable {
        let routes: [Route]
    }
    
    struct Route: Codable {
        let legs: [Leg]
    }
    
    struct Leg: Codable {
        let startLocation: LocationPoint
        let endLocation: LocationPoint
        let steps: [Step]
        
        enum CodingKeys: String, CodingKey {
            case startLocation = "start_location"
            case endLocation = "end_location"
            case steps
        }
    }
    
    struct Step: Codable {
        let startLocation: LocationPoint
        let endLocation: LocationPoint
        
        enum CodingKeys: String, CodingKey {
            case startLocation = "start_location"
            case endLocation = "end_location"
        }
    }
    
    struct LocationPoint: Codable {
        let lat: Double
        let lng: Double
    }
    
    func fetchRoute(start: String, end: String) async throws -> Direction {
        // urlをセット
        var urlComponents = URLComponents(url: URL(string: "https://maps.googleapis.com/maps/api/directions/json")!, resolvingAgainstBaseURL: false)!
        // urlにつけるqueryをセット
        urlComponents.queryItems = [URLQueryItem(name: "key", value: "AIzaSyAHqB7OlRuY2tCOsZ9o8SvJBCFD1sr1hL0"),
                                    URLQueryItem(name: "origin", value: start),
                                    URLQueryItem(name: "destination", value: end)]
        // httpMethodにGETをセット
        var urlRequest = URLRequest(url: urlComponents.url!)
        urlRequest.httpMethod = "GET"
        // APIコール
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        // 結果を判定
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NSError(domain: "", code: 0, userInfo: nil)
        }
        // DirectionというEntityに変換（JsonのDecode）をして返す
        return try JSONDecoder().decode(Direction.self, from: data)
    }
}
