import { createClass } from 'redux-components'
import { shallowDiff } from './Util'

# The redux-component that will be mounted to the store
export default OrmojoStore = createClass {
	displayName: 'OrmojoStore'

	verbs: ['CREATE', 'UPDATE', 'DELETE']

	componentWillMount: ->
		if not @equalityTest then @equalityTest = ( (a, b) -> not shallowDiff(a, b) )

	getReducer: -> (state = {}, action) ->
		{ equalityTest } = @

		switch action.type
			when @CREATE
				nextState = Object.assign({}, state)
				(nextState[entity.id] = entity) for entity in action.payload when entity?
				nextState

			when @UPDATE
				nextState = state
				for entity in action.payload when entity?
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
				for id in action.payload when id?
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

	selectors: {
		byId: (state) -> state
	}

	getById: (id) -> @state[id]
}
