angular.module('svm',[])
	.config(['$routeProvider','$locationProvider',($routeProvider,$locationProvider)->
		$routeProvider
			.when '/',
				templateUrl: 'view/loading.html'
				controller: 'loadingCtrl'	
			.when '/guest',
				templateUrl: 'view/guest.html'
				controller: 'mainCtrl'
				
		$locationProvider.html5Mode 1
	])
	.factory('socket', ['$rootScope',($rootScope)->
		socket = io.connect()
		
		emit: (event, data, callback)->
			socket.emit event, data, ->
				args = arguments
				$rootScope.$apply ->
					callback.apply socket, args
					
		on: (event, callback)->
			socket.on event, ->
				args = arguments
				$rootScope.$apply ->
					callback.apply socket, args
	])
	.controller('loadingCtrl', ['$location',($location)->
		$location.path '/guest'
	])
	.controller('mainCtrl', ['$location','$scope','socket',($location,$scope,socket)->
	
	])
	
angular.bootstrap document, ['svm']