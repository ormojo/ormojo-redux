import { RxUtil, Observable } from 'ormojo'

export shallowDiff = (a, b) ->
	return true for i of a when not (i of b)
	return true for i of b when a[i] isnt b[i]
	false

export makeSelectorObservable = (selectorFn, store) ->
	RxUtil.defineObservableSymbol(selectorFn, ->
		new Observable (observer) ->
			# Store present state of selector
			prevState = undefined

			# Check if state changed; invoke observer if so.
			observeState = ->
				nextState = selectorFn(store.getState())
				return if nextState is prevState
				prevState = nextState
				observer.next(nextState) if observer.next

			# Observe initial state
			observeState()

			# Returns unsubscriber func
			store.subscribe(observeState)
	)

	selectorFn
