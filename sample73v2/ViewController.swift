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
    
    var latitude:[Double] = [35.6835,35.6772,35.6847,35.6779]  //緯度
    var longitude:[Double] = [139.7708,139.7669,139.7656,139.7634] //経度
    var texts:[String] = ["1","2","3","4"]
    var markers: [GMSMarker] = []
    var zoom: Float = 13.0 //縮尺
    var flagA: Int = -1
    var flagB: Int = -1
    var flagC: Int = -1
    var flagD: Int = -1
    var clusterManager: GMUClusterManager!
    //write 7/7
    var marker: GMSMarker?
    var infoViewController: InfoViewController?
    
    //write 7/6
    var routeList: [[Double]] = []
    var accidentList: [[Double]] = []
    
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
            //item.text = texts[i]
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
    
    
    private func plotAll(x: Double, y: Double, z: String)  -> [GMSMarker]{
        
        let marker1 = GMSMarker()
        //latitude
        //longitude
        
        marker1.position = CLLocationCoordinate2D(latitude: x, longitude: y)
        marker1.title = z
        marker1.tracksInfoWindowChanges = true
        marker1.appearAnimation = GMSMarkerAnimation.pop
        mapView.selectedMarker = marker1
        marker1.map = self.mapView
        
        markers = [marker1]
        /*
         for i in 0..<latitude.count {
         let position = CLLocationCoordinate2D(latitude: latitude[i], longitude: longitude[i])
         let item = POIItem(position: position)
         item.text = texts[i]
         
         //let algorithm = GMUNonHierarchicalDistanceBasedAlgorithm()
         //let renderer = GMUDefaultClusterRenderer()
         //clusterManager = GMUClusterManager(map: mapView)
         
         }
         */
        return markers
    }
    
    private func plotData1() {
        let marker = GMSMarker()
        marker.position = CLLocationCoordinate2DMake(35.672494, 139.6605)
        marker.title = "右折時 歩行者に注意"
        marker.snippet = "Tokyo"
        marker.map = mapView
        mapView.selectedMarker = marker
        return
    }
    private func plotData2() {
        let marker = GMSMarker()
        marker.position = CLLocationCoordinate2DMake(35.6980, 139.6545)
        marker.title = "左折時 巻き込みに注意"
        marker.snippet = "Tokyo"
        marker.map = mapView
        mapView.selectedMarker = marker
        return
    }
    private func plotData3() {
        let marker = GMSMarker()
        marker.position = CLLocationCoordinate2DMake(35.68336,139.65679)
        marker.title = "直進時　追突注意"
        marker.snippet = "Tokyo"
        marker.map = mapView
        mapView.selectedMarker = marker
        return
    }
    
    
    private func showRoute(start: CLLocationCoordinate2D, end: CLLocationCoordinate2D) {
        routeList.removeAll()
        Task {
            
            do {
                // APIで経路情報を取得
                let direction = try await apiClient.fetchRoute(start: "\(start.latitude),\(start.longitude)",
                                                               end: "\(end.latitude),\(end.longitude)")
                guard let route = direction.routes.first, let leg = route.legs.first else { return }
                // UI処理はMainThreadにて
                //print("-------------------")
                
                
                for connection in leg.steps {
                    routeList.append([connection.startLocation.lat, connection.startLocation.lng])
                }
                //print("1")
                //print(routeList)
                
                
                DispatchQueue.main.async { [self] in
                    // legのstepsに曲がる交差点間の経路配列が入っている
                    leg.steps.forEach {
                        // 経路を結ぶ線を描く
                        let path = GMSMutablePath()
                        path.add(CLLocationCoordinate2D(latitude: $0.startLocation.lat,
                                                        longitude: $0.startLocation.lng))
                        
                        //routeList.append([$0.startLocation.lat, $0.startLocation.lng])
                        //print($0.startLocation.lat, $0.startLocation.lng)
                        //print("¥¥¥¥¥¥¥")
                        //print(routeList)
                        //print("¥¥¥¥¥¥¥")
                        path.add(CLLocationCoordinate2D(latitude: $0.endLocation.lat,
                                                        longitude: $0.endLocation.lng))
                        let polyline = GMSPolyline(path: path)
                        polyline.strokeWidth = 3
                        polyline.strokeColor = .blue
                        polyline.map = self.mapView
                        
                        self.updateCameraZoom(startLat: leg.startLocation.lat, startLng: leg.startLocation.lng, endLat: leg.endLocation.lat, endLng: leg.endLocation.lng)
                        
                    }
                }
                //print("-------------------@")
                //print("2")
                //print(routeList)
            } catch let error {
                print(error)
            }
            //print("3")
            //print(routeList)
        }
        
        //print("¥¥¥¥¥¥")
        //print(routeList)
    }
    /*
     private func execute() {
     //print("-----")
     //print(routeList)
     //print(routeList.count)
     for i in 0 ... (routeList.count - 2) {
     theta = calc_angle_3point(x0:routeList[i+1][0], y0:routeList[i+1][1], x1:routeList[i][0], y1:routeList[i][1], x2:routeList[i+2][0], y2:routeList[i+2][1])
     }
     }
     
     */
    /*
     private func calc_angle_3point(x0:Double, y0:Double, x1:Double, y1:Double, x2:Double, y2:Double) -> (theta:Double) {
     calc0 = calc_xy(phi_deg: x0, lambda_deg: y0)
     calc1 = calc_xy(phi_deg: x1, lambda_deg: y1)
     calc2 = calc_xy(phi_deg: x2, lambda_deg: y2)
     
     }
     
     private func calc_xy_v2(phi_deg:Double, lambda_deg:Double) -> (x:Double, y:Double) {
     let urlString = "https://vldb.gsi.go.jp/sokuchi/surveycalc/surveycalc/bl2xy.pl?outputType=json&refFrame=1&zone=9&latitude="+phi_deg.+"&longitude="+lambda_deg
     
     guard let url = URLComponents(string: urlString) else {return}
     
     let task = URLSession.shared.dataTask(with: url.url!) {(data, response, error) in
     if (error != nil) {
     print(error!.localizedDescription)
     }
     guard let _data = data else {return}
     
     let users = try! JSONDecoder().decode(<#T##T#>, from: <#T##Foundation.Data#>)
     }
     }
     
     */
    /*
     private func calc_xy(phi_deg:Double, lambda_deg:Double) -> (x:Double, y:Double) {
     var phi0_deg: Double = 36
     var lambda0_deg: Double = 139+50/60
     
     var phi_rad: Double = CGFloat.deg2rad(phi_deg)
     var lambda_rad: Double = CGFloat.deg2rad(lambda_deg)
     var phi0_rad: Double = CGFloat.deg2rad(phi0_deg)
     var lambda0_rad: Double = CGFloat.deg2rad(lambda0_deg)
     
     //補助関数
     private func A_array(n:Float) -> (Array<Any>) {
     let A0:Float = 1 + pow(n, 2) / 4 + pow(n, 4) / 64
     let A1:Float = -(3/2)*(n-pow(n,3)/8-pow(n,5)/64)
     let A2:Float = (15/16)*(pow(n, 2)-pow(n, 4)/4)
     let A3:Float = -(35/48)*(pow(n,3)-(5/16)*pow(n,5))
     let A4:Float = (315/512)*pow(n,4)
     let A5:Float = -(693/1280)*pow(n,5)
     
     return Array([A0,A1,A2,A3,A4,A5])
     }
     
     private func alpha_array(n:Float) -> (Array<Any>) {
     let a0:Float = Float.nan
     let a1:Float = (1/2)*2-(2/3)*pow(n,2) + (5/16)*pow(n, 3) + (41/180)*pow(n, 4) - (127/288)*pow(n, 5)
     let a2:Float = (13/48)*pow(n,2)-(3/5)*pow(n, 3)+(557/1440)*pow(n,4)+(281/630)*pow(n,5)
     let a3:Float = (61/240)*pow(n,3)-(103/140)*pow(n,4)+(15061/26880)*pow(n,5)
     let a4:Float = (49561/161280)*pow(n,4)-(179/168)*pow(n,5)
     let a5:Float = (34729/80640)*pow(n, 5)
     
     return Array([a0, a1, a2, a3, a4, a5])
     }
     
     let m0:Float = 0.9999
     let a: Float = 6378137
     let F: Float = 298.257222101
     
     var n: Float = 1/(2*F - 1)
     var A_array = A_array(n: n)
     var alpha_array = alpha_array(n: n)
     
     
     var A_ = ((m0*a)/(1+n))*A_array[0] as! Float
     //var S_ = ((m0*a)/(1+n))*(A_array[0]*phi0_rad + )
     
     var lambda_c = cos(lambda_rad-lambda0_rad)
     var lambda_s = sin(lambda_rad-lambda0_rad)
     
     var t = sinh(atanh(sin(phi_rad))-((2*sqrt(n))/(1+n))*atanh(((2*sqrt(n))/(1+n))*sin(phi_rad)))
     var t_ = sqrt(1+t*t)
     
     var xi2 = atan(t/lambda_c)
     var eta2 = atanh(lambda_s/t_)
     
     x = A_ * (xi2 + )
     }
     */
    
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
    var text: String = ""
    
    init(position: CLLocationCoordinate2D) {
        self.position = position
    }
}

extension ViewController: CLLocationManagerDelegate {
    // 現在地が更新された時にはしる処理
    
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        current = locations.first?.coordinate
        //print("--------------")
        //print(locations.first?.coordinate.latitude, locations.first?.coordinate.longitude)
        //35.672494, 139.6605
        //35.6980, 139.6545
        
        // 2点の経緯・緯度を設定
        //大原交差点
        var latA: Double =  35.672494
        var lngA: Double =  139.6605
        guard let latB = locations.first?.coordinate.latitude else {return}
        guard let lngB  =   locations.first?.coordinate.longitude else {return}
        
        let now_location:CLLocation = CLLocation(latitude: latB, longitude: lngB)
        let next_location: CLLocation = CLLocation(latitude: latA, longitude: lngA)
        let distanceA = next_location.distance(from: now_location)//meter
        print(distanceA)
        
        
        
        if distanceA < 500 {
            
            if flagA < 0 {
                //通知処理
                let content = UNMutableNotificationContent()
                content.title = "右折"
                content.body = "歩行者と車に気をつけてください"
                content.sound = UNNotificationSound.default
                
                // 直ぐに通知を表示
                let request = UNNotificationRequest(identifier: "immediately", content: content, trigger: nil)
                UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
                print("通知しました")
                flagA = 100
            }
        }
        
        
        //梅里交差点
        var latC: Double =  35.6980
        var lngC: Double =  139.6545
        //guard let latB = locations.first?.coordinate.latitude else {return}
        //guard let lngB  =   locations.first?.coordinate.longitude else {return}
        
        let now_locationB:CLLocation = CLLocation(latitude: latB, longitude: lngB)
        let next_locationB: CLLocation = CLLocation(latitude: latC, longitude: lngC)
        let distanceC = next_locationB.distance(from: now_locationB)//meter
        print(distanceC)
        
        
        
        if distanceC < 500 {
            
            if flagB < 0 {
                //通知処理
                let content = UNMutableNotificationContent()
                content.title = "左折"
                content.body = "巻込み注意"
                content.sound = UNNotificationSound.default
                
                // 直ぐに通知を表示
                let request = UNNotificationRequest(identifier: "immediately", content: content, trigger: nil)
                UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
                print("通知しました")
                flagB = 100
            }
        }
        
        
        
        //方南町駅
        var lat_straight: Double =  35.68336
        var lng_straight: Double =  139.65679
        //guard let latB = locations.first?.coordinate.latitude else {return}
        //guard let lngB  =   locations.first?.coordinate.longitude else {return}
        
        //let now_locationB:CLLocation = CLLocation(latitude: latB, longitude: lngB)
        let next_location_straight: CLLocation = CLLocation(latitude: lat_straight, longitude: lng_straight)
        let distance_straight = next_location_straight.distance(from: now_locationB)//meter
        //print(distanceC)
        
        
        
        if distance_straight < 500 {
            
            if flagC < 0 {
                //通知処理
                let content = UNMutableNotificationContent()
                content.title = "直進"
                content.body = "追突注意"
                content.sound = UNNotificationSound.default
                
                // 直ぐに通知を表示
                let request = UNNotificationRequest(identifier: "immediately", content: content, trigger: nil)
                UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
                print("通知しました")
                flagC = 100
            }
        }
        
        
        //豊洲駅
        var lat_toyosu: Double =  35.65457
        var lng_toyosu: Double =  139.79653
        //guard let latB = locations.first?.coordinate.latitude else {return}
        //guard let lngB  =   locations.first?.coordinate.longitude else {return}
        
        //let now_locationB:CLLocation = CLLocation(latitude: latB, longitude: lngB)
        let next_location_toyosu: CLLocation = CLLocation(latitude: lat_toyosu, longitude: lng_toyosu)
        let distance_toyosu = next_location_toyosu.distance(from: now_locationB)//meter
        //print(distanceC)
        
        
        
        if distance_straight < 100 {
            
            if flagD < 0 {
                //通知処理
                let content = UNMutableNotificationContent()
                content.title = "豊洲テスト"
                content.body = "目的地まで100m"
                content.sound = UNNotificationSound.default
                
                // 直ぐに通知を表示
                let request = UNNotificationRequest(identifier: "immediately", content: content, trigger: nil)
                UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
                print("通知しました")
                flagD = 100
            }
        }
        
        
        /*
         print("-------A")
         print(latA,lngA)
         print("---------")
         print("-------B")
         print(latB,lngB)
         print("---------")
         */
        // 経緯・緯度からCLLocationを作成
        /*
         CLLocation *A = [[CLLocation alloc] initWithLatitude:latA longitude:lngA];
         CLLocation *B = [[CLLocation alloc] initWithLatitude:latB longitude:lngB];
         */
        //　距離を取得
        //CLLocationDistance distance = [A distanceFromLocation:B];
        /*
         // お約束の開放
         [A release];
         [B release];
         
         // 距離をコンソールに表示
         NSLog(@"distance:%f", distance);
         */
        //print("--------------")
    }
}

extension Collection where Element == Float {
    func sum() -> Float {
        return reduce(0, +)
    }
}

/*
 extension CGFloat {
 static func deg2rad(_ deg:CGFloat) -> CGFloat {
 return CGFloat.pi /180.0 * deg
 }
 
 var deg2rad: CGFloat {
 return CGFloat.pi / 180.0 * self
 }
 }
 */
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [self] in
                // 0.5秒後に実行したい処理
                print("5")
                print(self.routeList)
                
                //execute()
            }
            // ついでに、現在とマーカーを表示するようにカメラを移動
            let bounds = GMSCoordinateBounds(coordinate: current, coordinate: coordinate)
            let update = GMSCameraUpdate.fit(bounds)
            mapView.moveCamera(update)
        }
        plotData3()
        plotData2()
        plotData1()
        //plotAll()
        //self.plotAll(x:35.672494, y:139.6605, z:"migi")
        //self.plotAll(x:35.6980, y:139.6545, z:"hidari")
    }
}


final class APIClient {
    
    struct Output: Codable {
        let publicX: Float
        let publicY: Float
        let gridConv: Float
        let scaleFactor: Float
    }
    
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
