import CoreLocation
import UIKit
import MapKit

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    let locationManager = CLLocationManager()
    let mapView = MKMapView()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupMapView()
        requestLocationPermission()
        setupAddPointButton()
        setupRouteButton()
        setupLongPressGesture()
        view.backgroundColor = .white
    }

    func setupMapView() {
        mapView.frame = view.bounds
        mapView.showsUserLocation = true
        mapView.delegate = self
        view.addSubview(mapView)

        // Инициализация CLLocationManager
        let locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()

        // Используйте местоположение пользователя, если доступно, иначе используйте начальное местоположение
        if let userLocation = locationManager.location?.coordinate {
            mapView.setCenter(userLocation, animated: true)

            // Опционально, установите регион с нужным масштабом
            let span = MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
            let region = MKCoordinateRegion(center: userLocation, span: span)
            mapView.setRegion(region, animated: true)
        } else {
            let initialLocation = CLLocationCoordinate2D(latitude: 60.035351, longitude: 30.228947)
            let span = MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
            let region = MKCoordinateRegion(center: initialLocation, span: span)
            mapView.setRegion(region, animated: true)
        }
    }

    func requestLocationPermission() {
        locationManager.startUpdatingLocation()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
    }

    func setupLongPressGesture() {
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        mapView.addGestureRecognizer(longPressGesture)
    }

    @objc func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            let touchPoint = gestureRecognizer.location(in: mapView)
            let coordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
            
            // Добавьте пин (маркер) на карту
            addPin(at: coordinate)
        }
    }

    
    
    func addCustomAnnotation(at coordinates: CLLocationCoordinate2D) {
        let customAnnotation = MKPointAnnotation()
        customAnnotation.coordinate = coordinates
        customAnnotation.title = "Новая точка"
        customAnnotation.subtitle = "Описание новой точки"
        mapView.addAnnotation(customAnnotation)
    }

    func setupAddPointButton() {
        let addButton = UIBarButtonItem(
            title: "Поставить метку",
            style: .plain,
            target: self,
            action:  #selector(addPointButtonTapped)
        )
        navigationItem.rightBarButtonItem = addButton
    }

    @objc func addPointButtonTapped() {
        showCoordinateInputDialog()
    }


    func addPin(at coordinate:CLLocationCoordinate2D){
        let pin = MKPointAnnotation()
        pin.coordinate = coordinate
        mapView.addAnnotation(pin)
    }
    
    func setupRouteButton(){
        let routeButton = UIBarButtonItem(
            title: "Задать маршрут", style: .plain, target: self, action: #selector(routeButtonTapped)
        )
        navigationItem.leftBarButtonItems = [routeButton]
    }
    
    @objc func routeButtonTapped(){
        if let userLocation = locationManager.location?.coordinate,
           let destinationCoordinate = mapView.annotations.first?.coordinate{
            let sourcePlacemark = MKPlacemark(coordinate: userLocation)
            let destinationPlacemark = MKPlacemark(coordinate: destinationCoordinate)
            
            let sourceMapItem = MKMapItem(placemark: sourcePlacemark)
            let destinationMapItem = MKMapItem(placemark: destinationPlacemark)
            
            let directionRequest = MKDirections.Request()
            directionRequest.source = sourceMapItem
            directionRequest.destination = destinationMapItem
            directionRequest.transportType = .automobile
            
            
            let direction = MKDirections(request: directionRequest)
            direction.calculate { (responce, error) in
                guard let responce = responce else {
                    if let error = error {
                        print("Ошибка при прокладывании маршрута: \(error.localizedDescription)")
                        
                        let alertController = UIAlertController(
                            title: "Ошибка",
                            message: "Не удалось проложить маршрут. \(error.localizedDescription)",
                            preferredStyle: .alert
                        )
                        
                        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                        alertController.addAction(okAction)
                        
                        self.present(alertController, animated: true, completion: nil)
                    }
                    return
                }
                
                
                let route = responce.routes[0]
                self.mapView.addOverlay(route.polyline, level: .aboveRoads)
                let rect = route.polyline.boundingMapRect
                self.mapView.setRegion(MKCoordinateRegion(rect), animated: true)
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = .blue
        renderer.lineWidth = 5.0
        return renderer
    }
    
    func showCoordinateInputDialog() {
        let alertController = UIAlertController(
            title: "Введите координаты",
            message: "Введите широту и долготу через запятую",
            preferredStyle: .alert
        )
        
        alertController.addTextField { textField in
            textField.placeholder = "Широта, Долгота"
            
        }
        
        let addAction = UIAlertAction(title: "Добавить", style: .default) { [weak self] _ in
            if let coordinatesText = alertController.textFields?.first?.text,
               let coordinates = self?.parseCoordinates(coordinatesText) {
                self?.addPin(at: coordinates)
            }
        }
        
        let cancelAction = UIAlertAction(title: "Отмена", style: .cancel, handler: nil)
        
        alertController.addAction(addAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
        
    }

    func parseCoordinates(_ text: String) -> CLLocationCoordinate2D? {
        let coordinatesComponents = text.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        
        guard coordinatesComponents.count == 2,
              let latitude = CLLocationDegrees(coordinatesComponents[0]),
              let longitude = CLLocationDegrees(coordinatesComponents[1]) else {
            return nil
            
        }
        
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
