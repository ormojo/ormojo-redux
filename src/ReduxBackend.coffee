import { Backend } from 'ormojo'
import ReduxBoundModel from './ReduxBoundModel'
import { createComponent } from 'redux-components'

export default class ReduxBackend extends Backend
	constructor: ->
		super
		@boundModels = {}

	bindModel: (model, bindingOptions) ->
		m = new ReduxBoundModel(model, @, bindingOptions)
		if @boundModels[m.name] then throw new Error("duplicate bound model named #{m.name}")
		@boundModels[m.name] = m
		m

	getReduxComponent: ->
		if @_reduxComponent then return @_reduxComponent

		structure = {}
		structure[k] = v.getReduxComponent() for k,v of @boundModels

		@_reduxComponent = createComponent(structure)
