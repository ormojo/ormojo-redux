ormojo = require 'ormojo'
{ ReduxBackend, ReduxCollector } = require '../..'
{ createStore, applyMiddleware } = require 'redux'
ReduxDebug = require 'redux-debug'
ReduxFreeze = require 'redux-freeze'
{ mountRootComponent } = require 'redux-components'

makeCorpus = ->
	logger = if 'trace' in process.argv then console.log.bind(console) else ->

	reduxBackend = new ReduxBackend

	corpus = new ormojo.Corpus({
		log: {
			trace: logger
			debug: logger
			info: logger
			warn: logger
			error: logger
			fatal: logger
		}
		backends: {
			'redux': reduxBackend
		}
	})

	Widget = corpus.createModel({
		name: 'Widget'
		fields: {
			id: { type: ormojo.STRING }
			name: { type: ormojo.STRING }
			flatDefault: { type: ormojo.STRING, defaultValue: 'unnamed' }
			functionalDefault: { type: ormojo.INTEGER, defaultValue: -> 1 + 1 }
			getter: {
				type: ormojo.STRING
				defaultValue: ''
				get: (k) -> @getDataValue(k) + ' getter'
			}
			setter: {
				type: ormojo.STRING
				defaultValue: ''
				set: (k, v) -> @setDataValue(k, v + ' setter')
			}
			getterAndSetter: {
				type: ormojo.STRING
				defaultValue: ''
				get: (k) -> @getDataValue(k) + ' getter'
				set: (k, v) -> @setDataValue(k, v + ' setter')
			}
		}
	}).forBackend('redux')

	component = reduxBackend.getReduxComponent()
	store = applyMiddleware(ReduxDebug(console.log), ReduxFreeze)(createStore)( (x) -> x )
	mountRootComponent(store, component)

	widgetCollector = new ReduxCollector({component: Widget.getReduxComponent(), hydrator: Widget.hydrator })

	{ corpus, Widget, store, widgetCollector }

module.exports = makeCorpus
