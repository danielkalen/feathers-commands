NATIVE_METHODS = require './nativeMethods'
{processHooks} = require('@feathersjs/commons').hooks

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
			else
				commandMethods = Object.keys(value).filter (method)->
					not NATIVE_METHODS.includes(method)

				for method in commandMethods
					hooks = value[method]
					service.__hooks[group][method] ?= []
					service.__hooks[group][method].push [].concat(hooks)...
					delete value[method]

		orig.call(service, newHooks)


extractHooks = (groups, {method})->
	output = []
	output.push(groups.all...) if groups.all.length
	output.push(groups[method]...) if groups[method]?.length
	return output


runHooks = (service, target, context)->
	{method} = context
	hooks = extractHooks service.__hooks[target], context
	
	if hooks.length
		processHooks.call(service, hooks, context)
	else
		return context


module.exports = {patchHookProps, patchHooksMethod, runHooks}
