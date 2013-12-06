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
	.directive('navbar', ->
		templateUrl: 'partials/navbar.html'
		restrict: 'E'
		scope: 
			o: '='
		replace: 1
	)
	.directive('form2', ->
		templateUrl: 'partials/form2.html'
		restrict: 'E'
		scope:
			o: '='
		replace: 1
		transclude: 1
	)
	.controller('loadingCtrl', ['$location',($location)->
		$location.path '/guest'
	])
	.controller('mainCtrl', ['$location','$scope','socket',($location,$scope,socket)->
		#===============Global===================#
		$scope.defaultMenu = "news"
		
		#===============Guest====================#
		#Guest's navbar
		$scope.navbarGuest = 
			brand: "<strong>WELCOME GUEST!</strong>"
			menus: [
				label: "Home"
				fn: -> $scope.navbarGuest.switch = "home"
			,
				label: "News"
				fn: -> $scope.navbarGuest.switch = "news"
			,
				label: "Account"
				fn: -> $scope.navbarGuest.switch = "account"
			]
			switch: sessionStorage.menu or $scope.defaultMenu
			style: "maroon no-radius"
		
		#Login form
		$scope.frmLogin = 
			show: 1
			title: "LOGIN USER"
			inputs: [
				label: "Username:"
				model: "user"
				type: "text"
			,
				label: "Password:"
				model: "pass"
				type: "password"
			]
			button: "Login"
		
		#Activate form
		$scope.frmActivate = 
			show: 1
			title: "ACTIVATE ACCOUNT"
			inputs: [
				label: "Student/Teacher/Alumni ID No:"
				model: "id"
				type: "text"
			,
				label: "Full Name:"
				model: "name"
			]
			button: "Activate"
			
		#menu watcher
		$scope.$watch 'navbarGuest.switch', (v)-> sessionStorage.menu = v
	])
	
angular.bootstrap document, ['svm']