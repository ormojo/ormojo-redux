import { BoundInstance, Util } from 'ormojo'

# Like `ormojo.BoundInstance`, except it does not mutate its dataValues, which means it is
# safe to set dataValues as a pointer into a Redux store.
export default class ReduxInstance extends BoundInstance
	constructor: (boundModel, @dataValues = {}) ->
		super

	getDataValue: (key) ->
		if @_nextDataValues and (key of @_nextDataValues) then @_nextDataValues[key] else @dataValues[key]

	setDataValue: (key, value) ->
		originalValue = @dataValues[key]
		# If value is different or not comparable...
		if (not Util.isPrimitive(value)) or (value isnt originalValue)
			# Create diff cache if needed...
			if not @_nextDataValues then @_nextDataValues = Object.create(null)
			# Add key to diff cache
			@_nextDataValues[key] = value
		undefined

	changed: (key) ->
		if key isnt undefined
			if @_nextDataValues and (key of @_nextDataValues) then true else false
		else
			if not @_nextDataValues then return false
			changes = (key for key of @dataValues when (key of @_nextDataValues))
			if changes.length > 0 then changes else false

	_clearChanges: ->
		delete @isNewRecord
		delete @_nextDataValues

	_mergeDataValues: (dvs) ->
		throw new Error('ReduxInstance does not support mutative merging of data values.')

	_getDataValues: ->
		if @_nextDataValues
			Object.assign({}, @dataValues, @_nextDataValues)
		else
			@dataValues
