express = require 'express.io'
mongoose = require 'mongoose'
app = express().http().io()

mongoose.connect 'mongodb://localhost/svm'

schema =
	users: new mongoose.Schema
		user: String
		pass: String
		name: String
		id: String
		type: Number
	homePages: new mongoose.Schema
		tab: String
		content: String

schema.users.index {user: 1}, {unique: 1}
schema.users.index {name: 1}
schema.users.index {id: 1}, {unique: 1}

Model = 
		users: mongoose.model "users", schema.users
		homePages: mongoose.model "homePages", schema.homePages
		
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
	