import { Backend } from 'ormojo'
import ReduxBoundModel from './ReduxBoundModel'
import { combineReducers } from 'redux'

export default class ReduxBackend extends Backend
	constructor: ->
		super
		@boundModels = {}

	bindModel: (model, bindingOptions) ->
		m = new ReduxBoundModel(model, @, bindingOptions)
		if @boundModels[m.name] then throw new Error("duplicate bound model named #{m.name}")
		@boundModels[m.name] = m
		m

	getReducer: ->
		structure = {}
		structure[k] = v.getReducer() for k,v of @boundModels
		combineReducers(structure)

	setStore: (@store) ->

	dispatch: -> @store.dispatch.apply(@store, arguments)
