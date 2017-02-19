import { HydratingCollector } from 'ormojo'

export default class ReduxCollector extends HydratingCollector
	constructor: ({@component})->
		super

	set: (id, val) ->
		# Val is a ReduxBoundInstance here...
		@byId[id] = val
		@component.update(val._getDataValues())

	remove: (id) ->
		delete @byId[id]
		@component.delete([id])
