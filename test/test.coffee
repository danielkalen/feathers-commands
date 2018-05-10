{test} = require 'ava'
{app, createService} = require './app'
feathersCommands = require '../'

test "registration", (t)->
	createService '1'
	t.is typeof app.service('1').command, 'undefined'
	t.is typeof app.service('1').run, 'undefined'

	feathersCommands(app)
	t.is typeof app.service('1').command, 'undefined'
	t.is typeof app.service('1').run, 'undefined'
	
	createService '2'
	t.is typeof app.service('2').command, 'function'
	t.is typeof app.service('2').run, 'function'


test "create commands", (t)->
	t.notThrows ()->
		app.service('2').command 'command1', (data, params)-> Promise.resolve([data, params])


test "run commands", (t)->
	Promise.resolve()
		.then ()-> app.service('2').run 'command1', 'abc123'
		.then (result)->
			t.is result[0], 'abc123'
			t.deepEqual result[1], {query:{}}
		
		.then ()-> app.service('2').run 'command1', 'def456', {blabla:1}
		.then (result)->
			t.is result[0], 'def456'
			t.deepEqual result[1], {query:{}, blabla:1}


test "command path params", (t)->
	request = require 'supertest'
	extend = require 'smart-extend'
	
	Promise.resolve()
		.then ()-> app.service('2').command 'command3/:name/:field?', (data, params)-> Promise.resolve extend.keys(['name','field']).clone(params)
		.then ()-> request(app).post('/2/command3')
		.then ({status})->
			t.is status, 404
		
		.then ()-> request(app).post('/2/command3/daniel')
		.then ({status, body})->
			t.is status, 200
			t.is body.name, 'daniel'
			t.is body.field, undefined
	
		.then ()-> request(app).post('/2/command3/daniel/king')
		.then ({status, body})->
			t.is status, 200
			t.is body.name, 'daniel'
			t.is body.field, 'king'
