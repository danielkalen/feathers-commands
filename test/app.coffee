feathers = require '@feathersjs/feathers'
express = require '@feathersjs/express'
app = express(feathers())

createService = (name)->
	app.use name, 
		get: (_id, {query})-> Promise.resolve(query)

# createCommand = ()->
# 	app.service('myservice')
# 		.command 'sayHello', 

module.exports = {app, createService}