extend = require 'smart-extend'
errors = require '@feathersjs/errors'
{processHooks} = require('@feathersjs/commons').hooks

registerCommandsApi = (app)->
	app.mixins.push (service, basePath)->
		hookGroups = patchHookProps(service)
		patchHooksMethod(service)
		attachCommandMethods(app, service, basePath, hookGroups)


patchHookProps = (service)->
	before = service.__hooks.before.all = []
	after = service.__hooks.after.all = []
	final = service.__hooks.finally.all = []
	error = service.__hooks.error.all = []
	last = [after, final]

	return {before, after, final, last, error}


patchHooksMethod = (service)->
	orig = service.hooks
	
	service.hooks = (newHooks)->
		for group,value of newHooks
			if typeof value is 'function'
				service.__hooks[group].all.push(value)
			else if value.all
				service.__hooks[group].all.push([].concat(value.all)...)

		orig.call(service, newHooks)



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
		context = {app, service, params, method:methodName, type:'before'}
		returnContext = arguments[arguments.length-1] is 0

		Promise.resolve()
			.then ()-> runHooks(service, hookGroups.before, context)
			.then ()->
				return context if context.result?
				Promise.resolve(methodFn(data, context.params, context))
					.then (result)-> context.result = result
					.then ()-> return context

			.then (context)-> extend.clone context, {type:'after'}
			.then (context)-> runHooks(service, hookGroups.after, context)
			.then (context)-> if returnContext then context else context.result
			.catch (err)->
				throw err if not hookGroups.error.length
				context.error = err
				Promise.resolve()
					.then ()-> runHooks(service, hookGroups.error, context)
					.then ()-> return context
			
			.then runFinallyHooks(context), runFinallyHooks(context)

	runFinallyHooks = (context)-> (result)->
		Promise.resolve()
			.then ()-> runHooks(service, hookGroups.final, context)
			.then ()-> return result



runHooks = (service, hooks, context)->
	if hooks.length
		processHooks.call(service, hooks, context)
	else
		return context

normalizePath = (path)->
	path = path.slice(1) if path[0] is '/'
	return path





module.exports = registerCommandsApi