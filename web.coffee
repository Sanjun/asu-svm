express = require 'express.io'
app = express().http().io()

app.configure ->
	app.use express.static 'public'

app.get '/*', (req,res)-> res.redirect '/'

app.io.route 'test', (req)-> req.io.respond req.data
	
app.listen 3000, -> console.log 'listening...'