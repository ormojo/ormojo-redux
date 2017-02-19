{ expect } = require 'chai'
{ RxUtil, Observable } = require 'ormojo'
makeCorpus = require './helpers/makeCorpus'

describe 'rx', ->
	it 'CRUD actions affect Redux store', ->
		{corpus, Widget, widgetCollector} = makeCorpus()

		inj = new RxUtil.Subject
		widgetCollector.connectAfter(inj)
		sel = Widget.getReduxComponent().byId

		inj.next({ type: 'CREATE', payload:[ { id: 1, name: 'document number one' } ] } )
		expect(sel()['1'].name).to.equal('document number one')
		inj.next({ type: 'UPDATE', payload:[ { id: 1, name: 'updated'}]})
		expect(sel()['1'].name).to.equal('updated')
		inj.next({ type: 'DELETE', payload:[ { id: 1 } ]})
		expect(sel()['1']).to.be.not.ok
