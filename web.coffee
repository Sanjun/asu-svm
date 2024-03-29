express = require 'express.io'
mongoose = require 'mongoose'
app = express().http().io()

mongoose.connect 'mongodb://localhost/svm'

schema =
	users: new mongoose.Schema
		user: 
			type: String
			default: Date.now
		pass: String
		name: String
		id: String
		type: Number
	homePages: new mongoose.Schema
		tab: String
		content: String
	news: new mongoose.Schema
		title: String
		author: String
		image: String
		content: String
		date: 
			type: String
			default: Date.now
	posts: new mongoose.Schema
		title: String
		content: String
		user: String
		date:
			type: String
			default: Date.now
	likes: new mongoose.Schema
		postId: String
		liker: String
	comments: new mongoose.Schema
		postId: String
		user: String
		comment: String
		date:
			type: String
			default: Date.now
			
schema.users.index {user: 1}, {unique: 1}
schema.users.index {name: 1}
schema.users.index {id: 1}, {unique: 1}
schema.news.index {title: 1}
schema.news.index {author: 1}
schema.posts.index {user: 1}
schema.posts.index {title: 1}
schema.likes.index {postId: 1,liker: 1}, {unique: 1}
schema.likes.index {postId: 1}
schema.comments.index {postId: 1}

Model = 
		users: mongoose.model "users", schema.users
		homePages: mongoose.model "homePages", schema.homePages
		news: mongoose.model "news", schema.news
		posts: mongoose.model "posts", schema.posts
		likes: mongoose.model 'likes', schema.likes
		comments: mongoose.model 'comments', schema.comments
app.configure ->
	app.use express.static 'public'

app.get '/*', (req,res)-> res.redirect '/'

app.io.route 'test', (req)-> req.io.respond req.data
	
app.listen 3000, -> console.log 'listening...'

app.io.route 'create', (req)->
	data = req.data
	model = data.model
	doc = data.doc
	
	newDoc = new Model[model](doc).save (e,m)-> 
		setTimeout (-> req.io.respond m), 500
		
app.io.route 'read', (req)->
	data = req.data
	model = data.model
	query = data.query
	limit = data.limit
	skip = data.skip
	select = data.select
	sort = data.sort
	
	Model[model].find(query).select(select).sort(sort).skip(skip).limit(limit).exec (e,m)->
		setTimeout (-> req.io.respond m), 500

app.io.route 'search', (req)->
	data = req.data
	model = data.model
	fields = data.fields
	keyword = data.keyword[0]
	select = data.select
	sort = data.sort
	skip = data.skip
	limit = data.limit
	
	query = []
	
	for f in fields
		tempObject = {}
		tempObject[f] = 
			$regex: keyword
			$options: 'i'
		
		query.push tempObject
		
	Model[model].find({$or:query}).select(select).sort(sort).skip(skip).limit(limit).exec (e,m)->
		setTimeout (-> req.io.respond m), 500
		
app.io.route 'update', (req)-> 
	data = req.data
	model = data.model
	query = data.query
	newDoc = {$set: data.doc}
	
	Model[model].update query, newDoc, {upsert:1}, (e,m)-> setTimeout (-> req.io.respond m), 500
	
app.io.route 'alert_all', (req)->
	dta = req.data
	data = dta.data
	type = dta.type
	
	console.log data
	req.io.broadcast type, data
	
app.io.route 'count', (req)->
	data = req.data
	model = data.model
	query = data.query
	
	Model[model].count query, (e,m)-> req.io.respond m