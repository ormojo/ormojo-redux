import { BoundModel, applyModelPropsToInstanceClass } from 'ormojo'
import ReduxInstance from './ReduxInstance'
import cuid from 'cuid'

initialState = {
	byId: {}
	ids: []
}

export default class ReduxBoundModel extends BoundModel
	constructor: (model, backend, bindingOptions) ->
		super

	initialize: ->
		@instanceClass = applyModelPropsToInstanceClass(@, (class BoundReduxInstance extends ReduxInstance))
		@createAction = "CREATE_#{@name}_ReduxBoundModel"
		@updateAction = "UPDATE_#{@name}_ReduxBoundModel"
		@deleteAction = "DELETE_#{@name}_ReduxBoundModel"

	_put: (dataValues, shouldCreate = true) ->
		if shouldCreate
			if not dataValues.id then dataValues.id = cuid()
			if dataValues.id of @getState().byId then return @corpus.Promise.reject(new Error('duplicate'))
			@backend.dispatch( { type: @createAction, payload: [ dataValues ] } )
			# Resolve with the next redux store object.
			@corpus.Promise.resolve(@getState().byId[dataValues.id])
		else
			if not dataValues.id then throw new Error('missing id field')
			@backend.dispatch( { type: @updateAction, payload: [ dataValues ]})
			# Resolve with the next redux store object.
			@corpus.Promise.resolve(@getState().byId[dataValues.id])

	put: (dataValues, shouldCreate = true) ->
		@_put(Object.assign({}, dataValues), shouldCreate)

	save: (instance) ->
		(if instance.isNewRecord
			@_put(instance._getDataValues(), true)
		else
			@_put(instance._getDataValues(), false)
		).then (nextDataValues) ->
			instance._setDataValues(nextDataValues)
			instance._clearChanges()
			instance

	destroyById: (id) ->
		if id of @getState().byId
			@backend.dispatch( { type: @deleteAction, payload: [ id ] })
			@corpus.Promise.resolve(true)
		else
			@corpus.Promise.resolve(false)

	_findById: (id) ->
		if (data = @getState().byId[id]) is undefined
			@corpus.Promise.resolve()
		else
			@corpus.Promise.resolve(@createInstance(data))

	_findByIds: (ids) ->
		rst = ids.map( (id) => if not (data = @getState().byId[id]) then undefined else @createInstance(data) )
		@corpus.Promise.resolve(rst)

	findById: (id) ->
		if Array.isArray(id) then @_findByIds(id) else @_findById(id)

	getState: -> @state or initialState

	getReducer: ->
		(state = initialState, action) =>
			ns = switch action.type
				when @createAction
					nextById = Object.assign({}, state.byId)
					nextIds = state.ids.slice()
					for entity in action.payload
						nextIds.push(entity.id)
						nextById[entity.id] = entity
					{ ids: nextIds, byId: nextById }

				when @updateAction
					nextById = Object.assign({}, state.byId)
					for entity in action.payload
						nextById[entity.id] = entity
					{ ids: state.ids, byId: nextById }

				when @deleteAction
					nextById = Object.assign({}, state.byId)
					delete nextById[id] for id in action.payload
					nextIds = state.ids.filter( (x) -> not (x in action.payload) )
					{ ids: nextIds, byId: nextById }

				else
					state

			return (@state = ns)
