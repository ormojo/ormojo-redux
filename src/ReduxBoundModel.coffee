import { BoundModel, applyModelPropsToInstanceClass, RxUtil } from 'ormojo'
import ReduxInstance from './ReduxInstance'
import cuid from 'cuid'
import { makeSelectorObservable, shallowDiff } from './Util'

mapWithSideEffects = RxUtil.mapWithSideEffects

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
		@resetAction = "RESET_#{@name}_ReduxBoundModel"
		@updateAction = "UPDATE_#{@name}_ReduxBoundModel"
		@deleteAction = "DELETE_#{@name}_ReduxBoundModel"
		@equalityTest = @spec.equalityTest or ( (a,b) -> not shallowDiff(a,b) )

	# Internal version of put that doesn't do a defensive copy.
	# Only use this if you're sure you're not going to accidentally mutate the DataValues later,
	# which would break Redux's contract.
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

	getSelector: ->
		if @selector then return @selector
		return (@selector = makeSelectorObservable (=> @state), @backend.store)

	# Implement the ormojo.Store interface.
	getById: (id) -> @state.byId[id]
	forEach: (func) -> func(v, k) for k,v of @state.byId; undefined

	# Implement the ormojo.Reducible interface.
	reduce: (action) ->
		myActionType = switch action.type
			when 'CREATE' then @createAction
			when 'UPDATE' then @updateAction
			when 'DELETE' then @deleteAction
			when 'RESET' then @resetAction
			else throw new Error('expected CRUD action')

		# Dispatch a synchronous action to the Redux store
		@backend.store.dispatch({
			type: myActionType
			payload: action.payload
		})

		# Tag us as the Store in future actions on this pipeline
		{
			type: action.type
			payload: action.payload
			meta: Object.assign({}, action.meta, { store: @ })
		}

	connectAfter: (observable) ->
		# XXX: Merge in a Subject here so we can inject RESET events downstream.
		# We should emit a RESET event when something like a time-travel happens
		# so that derived data can be rebuilt.
		mapWithSideEffects(observable, @reduce, @)

	getReducer: ->
		{ createAction, updateAction, deleteAction, equalityTest } = @
		(state = initialState, action) =>
			# XXX: detect RESET here?
			# Would be an impure behavior, but without it we can't support
			# time travel.
			ns = switch action.type
				when createAction
					nextById = Object.assign({}, state.byId)
					nextIds = state.ids.slice()
					for entity in action.payload
						nextIds.push(entity.id)
						nextById[entity.id] = entity
					{ ids: nextIds, byId: nextById }

				when updateAction
					nextById = Object.assign({}, state.byId)
					nextIds = state.ids.slice()
					for entity in action.payload
						if entity.id of nextById
							if not equalityTest(nextById[entity.id], entity)
								console.log("diffing #{entity.id}", nextById[entity.id], entity)
								nextById[entity.id] = Object.assign({}, nextById[entity.id], entity)
						else
							console.log("adding #{entity.id}")
							nextById[entity.id] = entity
							nextIds.push(entity.id)
					{ ids: nextIds, byId: nextById }

				when deleteAction
					nextById = Object.assign({}, state.byId)
					for id in action.payload
						delete nextById[id]
					nextIds = state.ids.filter( (x) -> not (x in action.payload) )
					{ ids: nextIds, byId: nextById }

				else
					state

			return (@state = ns)
