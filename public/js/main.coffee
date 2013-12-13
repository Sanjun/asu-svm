angular.module('svm',['ui.tinymce','ui.keypress'])
	.config(['$routeProvider','$locationProvider',($routeProvider,$locationProvider)->
		$routeProvider
			.when '/',
				templateUrl: 'view/loading.html'
				controller: 'loadingCtrl'	
			.when '/guest',
				templateUrl: 'view/guest.html'
				controller: 'mainCtrl'
			.when '/student',
				templateUrl: 'view/student.html'
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
	).directive('select2',->
		templateUrl: 'partials/select.html'
		restrict: 'E'
		transclude: 1
		replace: 1
		scope:
			options: '='
			model: '='
		link: (scope, el, attr)->
			scope.options.unshift "" #blank space

			el.bind 'change', ->
				scope.model = parseInt(this.value)
				scope.$apply()

			scope.$watch 'model', (v)->
				setTimeout (->
				  el.val(v)
				), 3000
				
	).directive('form2', ->
		templateUrl: 'partials/form2.html'
		restrict: 'E'
		scope:
			o: '='
			preview: '='
		replace: 1
		transclude: 1
	)
	.directive('showmore', ->
		templateUrl: 'partials/showmore.html'
		restrict: 'E'
		scope:
			form: '='
			fn: '='
		replace: 1
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
					when 1 #student
						$location.path '/student'
					when 4 #admin
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
		#re-check session
		if sessionStorage.type is undefined or sessionStorage.user is undefined or sessionStorage.pass is undefined
			$location.path "/guest"
			
		#modal
		$scope.modal = {}
		
		#load home pages
		socket.emit 'read', 
			model: 'homePages'
		,(res)->
			$scope.homePages = res or []
			
		#defaults
		$scope.type = 'guest'
		
		#user's info
		try
			$scope.user = sjcl.decrypt 'user', sessionStorage.user
			$scope.type = parseInt(sjcl.decrypt 'type', sessionStorage.type)
		catch e
			console.log e.toString()
			
		#utilities
		$scope.like = (o)->
			o.disableLike = 1
			socket.emit 'create', 
				model: "likes"
				doc:
					postId: o._id
					liker: $scope.user
			, (res)->
				o.disableLike = 0
				if res?.liker
					o.likeCount = o.likeCount or 0
					o.likeCount++
					o.liked = 1
					
		$scope.alertAll = (o)->
			type = o.type
			data = o.data
			
			socket.emit 'alert_all', {type,data}
		
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
				else if res?.hasOwnProperty(o.expect2) or res?[0]?.hasOwnProperty(o.expect2) or res is o.expect2
					o.statusClass = "label label-warning"
					o.status = o.success2
					o.callback2 res
				else
					o.status = o.failed
					o.statusClass = "label label-danger"
			
				$timeout (->
					o.showStatus = 0
					o.disabled = 0
				), 2000
		
		$scope.showMore = (form)->
			form.disableShowMore = 1
			form.data.skip = form.rData.length
			console.log form
			socket.emit form.event, form.data, (res)->
				form.callback res
				form.disableShowMore = 0
		
		$scope.setType = (n)->
			switch n
				when 1
					return "Student"
				when 2
					return "Teacher"
				when 3
					return "Alumni"
				when 4
					return "Admin"
					
		#search news
		$scope.frmSearchNews = 
			show: 1
			inputs: [
				label: "Search News:"
				model: 0
				type: "search"
			]
			button: "Search"
			fn: $scope.send
			event: "search"
			data:
				model: "news"
				fields: ["title","author"]
				keyword: [""]
				limit: 5
				sort: {_id: -1}
			dataType: "keyword"
			showMore: 1
			callback: (res)->
				$scope.frmSearchNews.rData = $scope.frmSearchNews.rData or []
				
				rs = res or []
				if rs.length is 0
					$scope.frmSearchNews.showMore = 0
					return
				if $scope.frmSearchNews.data.skip is 0
					$scope.frmSearchNews.rData = rs
					return
				for n in rs
					$scope.frmSearchNews.rData.push n
				return	
			message: "Searching, please wait.."
			success: "Done!"
			failed: "Failed search.."
			expect: "length" #array
		
		#load news
		socket.emit 'read',
			model: 'news'
			sort: {_id: -1}
			limit: 5
		,(res)->
			$scope.frmSearchNews.rData = res or []
		
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
			switch: sessionStorage.menu or "news"
			
		#menu watcher
		$scope.$watch 'navbar.switch', (v)-> 
			if v is undefined or v is "undefined"
				$scope.navbar.switch = "news"
				sessionStorage.menu = "news"
			else
				sessionStorage.menu = v
			
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
						when 1
							delete sessionStorage.menu
							$location.path "/student"
						when 4
							delete sessionStorage.menu
							$location.path "/admin"
							
			#Activate form
			$scope.frmActivate = 
				show: 1
				title: "ACTIVATE ACCOUNT"
				inputs: [
					label: "Full Name:"
					model: "name"
				,
					label: "Student/Teacher/Alumni ID No:"
					model: "id"
					type: "text"
				]
				button: "Activate"
				event: "read"
				data:
					model: "users"
					query:
						id: ""
						name: ""
					limit: 1
				dataType: "query"
				fn: $scope.send
				expect: "pass"
				expect2: "name"
				success2: "Account Found!"  
				message: "Checking account.."
				success: "Account found but ALREADY ACTIVATED.."
				failed: "Account NOT Found.."
				callback2: (res)->
					$scope.frmSaveAccount.data.query = {name: res[0].name}
					$scope.frmActivate.show = 0
					$scope.frmSaveAccount.show = 1
				callback: (res)->
					console.log "already activated"
					
			#save account
			$scope.frmSaveAccount = 
				fnClose: -> $scope.frmActivate.show = 1
				close: 1
				title: "Account Found"
				inputs: [
					label: 'Set Username:'
					model: "user"
					type: "text"
				,
					label: 'Set Password:'
					model: "pass"
					type: "password"
				,
					label: 'Retype Password:'
					model: "pass2"
					type: "password"
				]
				disabled: 1
				filter: ->
					console.log 'executing..'
					$scope.frmSaveAccount.disabled = 1
					$scope.frmSaveAccount.showStatus = 0
					
					user = $scope.frmSaveAccount.data.doc.user.length
					pass = $scope.frmSaveAccount.data.doc.pass
					pass2 = $scope.frmSaveAccount.data.doc.pass2
					passLen = pass.length
					pass2Len = pass2.length
					
					if user < 3 or user > 8 
						$scope.frmSaveAccount.statusClass = "label label-info"
						$scope.frmSaveAccount.status = "Username must be 3-8 characters only"
						$scope.frmSaveAccount.showStatus = 1
						return
						
					if passLen < 8 or passLen > 15 
						$scope.frmSaveAccount.statusClass = "label label-warning"
						$scope.frmSaveAccount.status = "Password must be 8-15 characters only"
						$scope.frmSaveAccount.showStatus = 1
						return
						
					if pass isnt pass2 
						$scope.frmSaveAccount.statusClass = "label label-danger"
						$scope.frmSaveAccount.status = "Passwords not matched!"
						$scope.frmSaveAccount.showStatus = 1
						return
						
					$scope.frmSaveAccount.disabled = 0
						
				button: "Save"
				fn: $scope.send
				event: "update"
				expect: 1
				success: "Account Saved!"
				failed: "Save failed.."
				callback: (res)->
					console.log res
				data:
					model: "users"
					query: {name: 0} #default query
					doc:
						user: ""
						pass: ""
						pass2: ""
				dataType: "doc"
				
			return #end of guest's script, prevent execute code below
		
		#=================NOT GUEST==================#
		#post page
		$scope.attachCommentForm = (o,i)->
			console.log o
			if o.frmComment then return
			o.frmComment = 
				textareas:[
					label: "Comment:"
					model: "comment"
				]
				button: "Post Comment"
				event: 'create'
				dataType: 'doc'
				data:
					model: 'comments'
					doc:
						user: $scope.user
						postId: o._id
						comment: ""
				callback:(res)->
					o.comments.push res
					o.commentCount++
					this.data.doc.comment = ""
				message: "Sending comment.."
				success: "Success.."
				failed: "Sending Failed.."
				expect: "comment"
				fn: $scope.send
				show: 1
				
		$scope.getComments = (o,i)->
			if o.comments then return
			o.comments = []
			socket.emit 'read',
				model: 'comments'
				query: 
					postId: o._id
				limit: 5
				sort: {_id: -1}
			,(res)->
				rs = res or []
				for n in rs
					o.comments.unshift n
		
		$scope.getCommentCount = (o, i)->
			if o.commentCount then return
			socket.emit 'count',
				model: 'comments'
				query:
					postId: o._id
			,(res)->
				o.commentCount = res
				
		$scope.getLikes = (o,i)-> 
			if o.likeCount then return
			socket.emit 'count', 
				model: 'likes'
				query:
					postId: o._id
			,(res)->
				o.likeCount = res
				
		$scope.isLiked = (o,i)->
			if o.liked then return
			socket.emit 'count', 
				model: 'likes'
				query:
					postId: o._id
					liker: $scope.user
				,(res)->
					if res is 1
						o.liked = 1
	
						
		$scope.postFunctions = [
			$scope.getLikes
		,
			$scope.isLiked
		,
			$scope.attachCommentForm
		, 
			$scope.getComments
		,
			$scope.getCommentCount
		]
		
		$scope.looper = (process, obj, i)->
		
			len = process.length
			
			x = 0
			$timeout (->
				process[x] obj, i
				x++
				if x < len
					$timeout arguments.callee, 100
			), 100
				
		$scope.previous = (o, m)->
			o.disablePrevious = 1
			socket.emit 'read',
				model: m
				query:
					postId: o._id
				sort: {_id: -1}
				skip: o.comments.length
				limit: 5
			,(res)->
				o.disablePrevious = 0
				rs = res or []
				
				for n in rs
					o.comments.unshift n
					
		#alerts to all users except guest
		socket.on 'post', (res)->
			$scope.frmSearchPosts.rData.unshift res
			$scope.refreshPosts()
		
		$scope.refreshPosts = ->
			for n, i in $scope.frmSearchPosts.rData
				$scope.looper $scope.postFunctions, n, i
				
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
		
		#create post form
		$scope.frmCreatePost = 
			close: 1
			title: "Create Post:"
			inputs: [
				label: "Title:"
				model: "title"
				type: "text"
			]
			tinymces: [
				label: "Content:"
				model: "content"
			]
			button: "Post"
			dataType: "doc"
			data:
				model: "posts"
				doc:
					user: $scope.user
					content: ""
					title: ""
					image: ""
			event: "create"
			message: "Posting, please wait..."
			success: "Success.."
			failed: "Post failed.."
			expect: "title"
			fn: $scope.send
			callback: (res)->
				$scope.frmSearchPosts.rData.unshift res
				$scope.alertAll({type:"post",data:res})
				$scope.frmCreatePost.show = 0
				$scope.refreshPosts()
		#search posts
		$scope.frmSearchPosts = 
			show: 1
			inputs: [
				label: "Search Posts:"
				model: 0
				type: "search"
			]
			button: "Search"
			fn: $scope.send
			event: "search"
			rData: []
			data:
				model: "posts"
				fields: ["title","user"]
				keyword: [""]
				limit: 5
				sort: {_id: -1}
			dataType: "keyword"
			showMore: 1
			callback: (res)->
				$scope.frmSearchPosts.rData = $scope.frmSearchPosts.rData or []
				
				rs = res or []
				if rs.length is 0
					$scope.frmSearchPosts.showMore = 0
					return
				if $scope.frmSearchPosts.data.skip is 0
					$scope.frmSearchPosts.rData = rs
					$scope.refreshPosts()
					
					return
				for n in rs
					$scope.frmSearchPosts.rData.push n
				$scope.refreshPosts()
				
				return	
			message: "Searching, please wait.."
			success: "Done!"
			failed: "Failed search.."
			expect: "length" #array
		
		
				
		#=================STUDENT PAGE===============#
		if $scope.type is 1
			console.log "student"
			#modify navbar for student
			$scope.navbar.brand = 'Welcome Student'
			$scope.navbar.menus.unshift
				label: "Post"
				fn: -> $scope.navbar.switch = "post"

			return #prevent execute below
		#=================ADMIN PAGE=================#
		if $scope.type is 4
			#modify navbar for admin
			$scope.navbar.menus.push 
				label: "Accounts"
				fn: -> $scope.navbar.switch = "accounts"
				
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
				
			#create news form
			$scope.frmCreateNews = 
				title: "Create News"
				inputs: [
					label: "Title:"
					model: "title"
					type: "text"
				,
					label: "Author:"
					model: "author"
					type: "text"
				,
					label: "Image Url:"
					model: "image"
					type: "text"
				]
				tinymces: [
					label: "Content:"
					model: "content"
				]
				close: 1
				event: "create"
				expect: "author"
				message: "Saving news.."
				success: "News saved successfully!"
				failed: "Failed.."
				dataType: "doc"
				data: 
					model: "news"
					doc:
						image: ""
						content: ""
						author: ""
						title: ""
				callback: (res)->
					console.log res
				button: "Save"
				fn: $scope.send
			
			#Register Account
			$scope.frmRegisterAccount = 
				formClass: "well well-sm"
				title: "Register Account"
				inputs: [
					label: "Student/Teacher/Alumni ID No:"
					type: "text"
					model: "id"
					placeholder: "ex. 2013-4048"
				,
					label: "Full Name:"
					type: "text"
					model: "name"
					placeholder: "ex. Juan A. Dela Cruz"
				]
				selects: [
					label: "Account Type:"
					model: "type"
					options: [
						value: 1
						option: "Student"
					,
						value: 2
						option: "Teacher"
					,
						value: 3
						option: "Alumni"
					,
						value: 4
						option: "Student"
					]
				]
				close: 1
				button: "Register"
				fn: $scope.send
				callback: (res)->
					console.log res
				expect: "name"
				message: "Registering, please wait.."
				success: "Successfully registered!"
				failed: "failed, please try again later.."
				event: "create"
				data:
					model: "users"
					doc:
						name: ""
						id: ""
				dataType: "doc"
				
			#search account
			$scope.frmSearchAccount = 
				title: "Search Account:"
				inputs: [
					label: "Name/ID/User:"
					type: "text"
					model: 0
				]
				dataType: "keyword"
				data: 
					model: "users"
					keyword: [""]
					fields: ["name","user","id"]
					limit: 5
				show: 1
				button: "Search"
				fn: $scope.send
				event: "search"
				expect: "length" #array
				message: "Searching, please wait.."
				success: "Done!"
				failed: "Failed search.."
				rData: []
				callback: (res)->
					rs = res or []
					if rs.length is 0
						$scope.frmSearchAccount.showMore = 0
						return
					if $scope.frmSearchAccount.data.skip is 0
						$scope.frmSearchAccount.rData = rs
						return
					for a in rs
						$scope.frmSearchAccount.rData.push a
					
			return #end of admin's script, prevent execute code below
	])
	
angular.bootstrap document, ['svm']