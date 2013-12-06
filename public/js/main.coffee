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
	.controller('loadingCtrl', ['$location',($location)->
		$location.path '/guest'
	])
	.controller('mainCtrl', ['$location','$scope',($location,$scope)->
		
	])
	
angular.bootstrap document, ['svm']