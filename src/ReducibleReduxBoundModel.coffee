import { Reducible } from 'ormojo'

export default class ReducibleReduxBoundModel extends Reducible
	constructor: (@boundModel) ->
		super()

	# Implement the ormojo.Store interface
	getById: (id) -> @boundModel.getById(id)
	forEach: (func) -> @boundModel.forEach(func)

	# Passthru some useful functions from the boundModel
	getSelector: -> @boundModel.getSelector()

	# Implement the ormojo.Reducible interface.
	reduce: (action) ->
		myActionType = switch action.type
			when 'CREATE' then @boundModel.createAction
			when 'UPDATE' then @boundModel.updateAction
			when 'DELETE' then @boundModel.deleteAction
			when 'RESET' then @boundModel.resetAction
			else null

		if not myActionType then return action

		# Dispatch a synchronous action to the Redux store
		@boundModel.backend.store.dispatch({
			type: myActionType
			payload: action.payload
		})

		# Tag us as the Store in future actions on this pipeline
		{
			type: action.type
			payload: action.payload
			meta: Object.assign({}, action.meta, { store: @ })
		}
