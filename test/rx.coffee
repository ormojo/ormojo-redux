{ expect } = require 'chai'
{ RxUtil, Observable } = require 'ormojo'
makeCorpus = require './helpers/makeCorpus'

expectTests = (tests) ->
	i = 0
	{
		next: (x) -> expect(tests[i++](x)).to.equal(true)
		error: (x) -> throw x
		complete: -> expect(i).to.equal(seq.length)
	}

describe 'rx', ->
	it 'CRUD actions affect Redux store', ->
		{corpus, ReducibleWidget: Widget} = makeCorpus()

		inj = new RxUtil.Subject
		Widget.connectAfter(inj)
		sel = Widget.getSelector()

		inj.next({ type: 'CREATE', payload:[ { id: 1, name: 'document number one' } ] } )
		expect(sel().byId['1'].name).to.equal('document number one')
		inj.next({ type: 'UPDATE', payload:[ { id: 1, name: 'updated'}]})
		expect(sel().byId['1'].name).to.equal('updated')
		inj.next({ type: 'DELETE', payload:[1]})
		expect(sel().byId['1']).to.be.not.ok

	it 'should make selectors into Observables', ->
		{corpus, ReducibleWidget: Widget} = makeCorpus()

		inj = new RxUtil.Subject
		Widget.connectAfter(inj)
		sel = Widget.getSelector()
		Observable.from(sel).subscribe(
			expectTests([
				(x) -> x.ids.length is 0 # initial state
				(x) -> x.byId['1'].name is 'first' # after CREATE
			])
		)
		inj.next({ type: 'CREATE', payload:[ { id: 1, name: 'first' } ] } )
