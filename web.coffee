express = require 'express.io'
app = express().http().io()

app.configure ->
	app.use express.static 'public'

app.get '/*', (req,res)-> res.redirect '/'
	
app.listen 3000, -> console.log 'listening...'