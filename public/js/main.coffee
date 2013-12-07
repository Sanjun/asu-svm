angular.module('svm',['ui.tinymce','ui.keypress'])
	.config(['$routeProvider','$locationProvider',($routeProvider,$locationProvider)->
		$routeProvider
			.when '/',
				templateUrl: 'view/loading.html'
				controller: 'loadingCtrl'	
			.when '/guest',
				templateUrl: 'view/guest.html'
				controller: 'mainCtrl'
			.when '/admin',
				templateUrl: 'view/admin.html'
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
			preview: '='
		replace: 1
		transclude: 1
	)
	.controller('loadingCtrl', ['$location','socket',($location,socket)->
		try
			socket.emit 'read', 
				model: 'users'
				query:
					user: sjcl.decrypt 'user', sessionStorage.user
					pass: sjcl.decrypt 'pass', sessionStorage.pass
				limit: 1
			,(res)->
				client = res[0]
				type = client.type
				
				switch type
					when 4
						$location.path '/admin'
					else
						menu = sessionStorage.menu
						sessionStorage.clear()
						sessionStorage.menu = menu
						$location.path '/guest'
		catch e
			menu = sessionStorage.menu
			sessionStorage.clear()
			sessionStorage.menu = menu
			$location.path '/guest'
	])
	.controller('mainCtrl', ['$location','$scope','socket','$timeout',($location,$scope,socket,$timeout)->
		#===============Global===================#
		#load home pages
		socket.emit 'read', 
			model: 'homePages'
		,(res)->
			$scope.homePages = res or []
			
		#defaults
		$scope.defaultMenu = "news"
		$scope.type = 'guest'
		
		#user's info
		try
			$scope.user = sjcl.decrypt 'user', sessionStorage.user
			$scope.type = parseInt(sjcl.decrypt 'type', sessionStorage.type)
		catch e
			console.log e.toString()
			
		#utilities
		$scope.send = (o)->
			o.disabled = 1
			o.statusClass = 'label label-info'
			o.status = o.message
			o.showStatus = 1
			
			socket.emit o.event, o.data, (res)->
				console.log res
				if res?.hasOwnProperty(o.expect) or res?[0]?.hasOwnProperty(o.expect) or res is o.expect
					o.statusClass = "label label-success"
					o.status = o.success
					o.callback res
				else
					o.status = o.failed
					o.statusClass = "label label-danger"
			
				$timeout (->
					o.showStatus = 0
					o.disabled = 0
				), 2000
				
		#initial navbar
		$scope.navbar = 
			menus: [
				label: "Home"
				fn: -> $scope.navbar.switch = "home"
			,
				label: "News"
				fn: -> $scope.navbar.switch = "news"
			]
			style: "maroon no-radius"
			switch: sessionStorage.menu or $scope.defaultMenu
		
		#menu watcher
		$scope.$watch 'navbar.switch', (v)-> sessionStorage.menu = v
			
		#===============Guest Page====================#
		if $scope.type is 'guest'
			#modify navbar for guest
			$scope.navbar.brand = "Welcome Guest!"
			$scope.navbar.menus.push
				label: "Account"
				fn: -> 
					$scope.navbar.switch = "account"
			
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
				fn: $scope.send
				dataType: "query"
				data: 
					model: "users"
					query:
						user: ""
						pass: ""
					limit: 1
				event: "read"
				message: "Checking Please Wait.."
				success: "Authenticated!"
				failed: "Wrong username or password.."
				expect: "user"
				callback: (res)->
					rs = res[0]
					user = rs.user
					pass = rs.pass
					type = rs.type
					
					sessionStorage.user = sjcl.encrypt 'user', user
					sessionStorage.pass = sjcl.encrypt 'pass', pass 
					sessionStorage.type = sjcl.encrypt 'type', type.toString()
					
					switch type
						when 4
							delete sessionStorage.menu
							$location.path "/admin"
							
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
				
				
			return #end of guest's script, prevent execute code below
		
		#=================NOT GUEST==================#
		#add user page and logout
		$scope.navbar.dropdowns = [
			label: $scope.user.toUpperCase()
			menus: [
				label: "Sign-Out"
				fn: ->
					sessionStorage.clear()
					$location.path '/guest'
			]
		]
		
		#=================ADMIN PAGE=================#
		if $scope.type is 4
			#modify navbar for admin
			$scope.navbar.switch = sessionStorage.menu or $scope.defaultMenu
			$scope.navbar.brand = "Welcome Admin"
			
			#new page form
			$scope.frmNewPage = 
				title: "Create Page"
				tinymces: [
					label: "Content:"
					model: "content"
				]
				inputs: [
					label: "Tab Name:"
					model: "tab"
				]
				show: 1
				event: "create"
				data: 
					model: "homePages"
					doc:
						content: ""
						tab: ""
				dataType: "doc"
				button: "Save"
				message: "Saving new page..."
				failed: "Saving failed.."
				success: "Page saved successfully!"
				fn: $scope.send
				expect: "content"
				callback: (res)->
					$scope.homePages.push res
			return #end of admin's script, prevent execute code below
	])
	
angular.bootstrap document, ['svm']