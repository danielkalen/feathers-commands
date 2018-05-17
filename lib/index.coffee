extend = require 'smart-extend'
errors = require '@feathersjs/errors'
{patchHookProps, patchHooksMethod} = require './hooks'
{attachCommandMethods} = require './commands'


registerCommandsApi = (app)->
	app.mixins.push (service, basePath)->
		hookGroups = patchHookProps(service)
		patchHooksMethod(service)
		attachCommandMethods(app, service, basePath, hookGroups)




module.exports = registerCommandsApi