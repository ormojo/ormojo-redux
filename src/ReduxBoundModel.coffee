import { BoundModel, applyModelPropsToInstanceClass, RxUtil, Store, Query, Hydrator, ResultSet } from 'ormojo'
import ReduxInstance from './ReduxInstance'
import cuid from 'cuid'
import { makeSelectorObservable, shallowDiff } from './Util'
import OrmojoStore from './OrmojoStore'

class ReduxResultSet extends ResultSet
	constructor: (@results) ->

class ReduxStore extends Store
	constructor: ({equalityTest}) ->
		super
		@component = new OrmojoStore
		@component.equalityTest = equalityTest

	crupsert: (data, isCreate) ->
		@corpus.Promise.resolve().then =>
			for datum in data when datum?
				if not datum.id then datum.id = cuid()
				if isCreate and @component.state[datum.id]? then throw new Error("duplicate id")
				datum
			if isCreate then @component.create(data) else @component.update(data)
			# Return the now-updated states
			stateNow = @component.state
			for datum in data
				if datum? then stateNow[datum.id] else undefined

	read: (query) ->
		@corpus.Promise.resolve().then =>
			if not query?.ids? then throw new Error("invalid query format")
			stateNow = @component.state # synchronously safe
			new ReduxResultSet( ( (if id? then stateNow[id]) for id in query.ids) )

	create: (data) ->
		@crupsert(data, true)

	update: (data) ->
		@corpus.Promise.resolve().then =>
			stateNow = @component.state
			for datum in data when datum?
				if not datum?.id? then throw new Error("invalid update format")
				if not stateNow[datum.id]? then throw new Error("update of nonexistent object")
			@component.update(data)
			stateNow = @component.state
			for datum in data
				if datum? then stateNow[datum.id] else undefined

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
	constructor: ->
		super

export default class ReduxBoundModel extends BoundModel
	constructor: (model, backend, bindingOptions) ->
		super
		equalityTest = @spec.equalityTest or ( (a,b) -> not shallowDiff(a,b) )
		@store = new ReduxStore({@corpus, equalityTest})
		@hydrator = new Hydrator({boundModel: @})

	initialize: ->
		@instanceClass = applyModelPropsToInstanceClass(@, (class BoundReduxInstance extends ReduxInstance))

	getReduxComponent: -> @store.component
