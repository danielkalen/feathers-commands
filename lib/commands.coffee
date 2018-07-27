extend = require 'smart-extend'
errors = require '@feathersjs/errors'
{runHooks} = require './hooks'


attachCommandMethods = (app, service, basePath, hookGroups)->
	service.__commands = {}

	service.command = (commandPath, handler)->
		commandPath = normalizePath(commandPath)
		methodName = commandPath.split('/')[0]
		methodFn = (handler or service[methodName]).bind(service)
		service.__commands[methodName] = methodFn
		
		app.route("/#{basePath}/#{commandPath}").post (req, res, next)->
			params = extend {req, query:req.query, data:req.body}, req.feathers, req.params
		
			Promise.resolve()
				.then ()-> service.run methodName, req.body, params
				.then (result)-> res.json(result)
				.catch next

		return service

	
	service.run = (methodName, data, params)->
		methodName = normalizePath(methodName)
		methodFn = service.__commands[methodName]
		
		if typeof methodFn isnt 'function'
			throw new errors.MethodNotAllowed "Command #{methodName} is not supported by this endpoint."

		params ||= {}
		params.query ?= {}
		context = {app, service, params, data, method:methodName, path:basePath, type:'before'}
		returnContext = arguments[arguments.length-1] is 0

		Promise.resolve()
			.then ()-> runHooks(service, 'before', context)
			.then ()->
				return context if context.result?
				Promise.resolve(methodFn(context.data, context.params, context))
					.then (result)-> context.result = result
					.then ()-> return context

			.then (context)-> extend.clone context, {type:'after'}
			.then (context)-> runHooks(service, 'after', context)
			.then (context)-> if returnContext then context else context.result
			.catch (err)->
				throw err if not hookGroups.error.length
				context.error = err
				Promise.resolve()
					.then ()-> runHooks(service, 'error', context)
					.then ()-> return context
			
			.then runFinallyHooks(context), runFinallyHooks(context, true)

	runFinallyHooks = (context, isErrorHandler)-> (result)->
		Promise.resolve()
			.then ()-> runHooks(service, 'finally', context)
			.then ()->
				if isErrorHandler
					throw result
				else
					return result



normalizePath = (path)->
	path = path.slice(1) if path[0] is '/'
	return path



module.exports = {attachCommandMethods}