import { BoundModel, applyModelPropsToInstanceClass, RxUtil, Store, Query, Hydrator } from 'ormojo'
import ReduxInstance from './ReduxInstance'
import cuid from 'cuid'
import { makeSelectorObservable, shallowDiff } from './Util'
import { createClass } from 'redux-components'

# The redux-component that will be mounted to the store
OrmojoReduxStoreComponent = createClass {
	displayName: 'OrmojoReduxStoreComponent'

	verbs: ['CREATE', 'UPDATE', 'DELETE']

	getReducer: -> (state = {}, action) ->
		{ equalityTest } = @

		switch action.type
			when @CREATE
				nextState = Object.assign({}, state)
				(nextState[entity.id] = entity) for entity in action.payload
				nextState

			when @UPDATE
				nextState = state
				for entity in action.payload
					if entity.id of nextState
						if not equalityTest(nextState[entity.id], entity)
							if nextState is state then nextState = Object.assign({}, state)
							nextState[entity.id] = Object.assign({}, nextState[entity.id], entity)
					else
						if nextState is state then nextState = Object.assign({}, state)
						nextState[entity.id] = entity
				nextState

			when @DELETE
				nextState = state
				for id in action.payload
					if id of nextState
						 if nextState is state then nextState = Object.assign({}, state)
						 delete nextState[id]
				nextState

			else
				state

	actionDispatchers: {
		create: (entities) -> { type: @CREATE, payload: entities }
		update: (partialEntities) -> { type: @UPDATE, payload: partialEntities }
		delete: (ids) -> { type: @DELETE, payload: ids }
	}

	getById: (id) -> @state[id]
}

class ReduxStore extends Store
	constructor: ({equalityTest}) ->
		super
		@component = new OrmojoReduxStoreComponent
		@component.equalityTest = equalityTest

	crupsert: (data, isCreate) ->
		@corpus.Promise.resolve().then =>
			for datum in data
				if (not datum?) then throw new Error("invalid create format")
				if not datum.id then datum.id = cuid()
				if isCreate and @component.state[datum.id]? then throw new Error("duplicate id")
				datum
			if isCreate then @component.create(data) else @component.update(data)
			# Return the now-updated states
			stateNow = @component.state
			(stateNow[datum.id] for datum in data)

	read: (query) ->
		@corpus.Promise.resolve().then =>
			if not query?.ids? then throw new Error("invalid query format")
			stateNow = @component.state # synchronously safe
			stateNow[id] for id in query.ids

	create: (data) ->
		@crupsert(data, true)

	update: (data) ->
		@corpus.Promise.resolve().then =>
			stateNow = @component.state
			for datum in data
				if not datum?.id? then throw new Error("invalid update format")
				if not stateNow[datum.id]? then throw new Error("update of nonexistent object")
			@component.update(data)
			stateNow = @component.state
			(stateNow[datum.id] for datum in data)

	upsert: (data) ->
		@crupsert(data, false)

	delete: (data) ->
		@corpus.Promise.resolve().then =>
			stateNow = @component.state
			results = for datum in data
				if not datum? then throw new Error("invalid delete format")
				if stateNow[datum]? then true else false
			@component.delete(data)
			results

class ReduxQuery extends Query
	constructor: (id) ->
		if Array.isArray(id) then @ids = id else @ids = [id]

export default class ReduxBoundModel extends BoundModel
	constructor: (model, backend, bindingOptions) ->
		super
		equalityTest = @spec.equalityTest or ( (a,b) -> not shallowDiff(a,b) )
		@store = new ReduxStore({@corpus, equalityTest})
		@hydrator = new Hydrator({boundModel: @})

	initialize: ->
		@instanceClass = applyModelPropsToInstanceClass(@, (class BoundReduxInstance extends ReduxInstance))

	findById: (id) ->
		@store.read(new ReduxQuery(id))
		.then (readData) =>
			hydrated = (@hydrator.didRead(null, datum) for datum in readData)
			if Array.isArray(id) then hydrated else hydrated[0]

	getReduxComponent: -> @store.component
