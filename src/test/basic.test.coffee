{ expect } = require 'chai'
ormojo = require 'ormojo'
makeCorpus = require './helpers/makeCorpus'

describe 'basic tests: ', ->
	it 'should create, save, find by id', ->
		{corpus, Widget} = makeCorpus()
		awidget = Widget.create()
		awidget.name = 'whosit'

		testThing = null
		awidget.save().then (thing) ->
			console.log { thing }
			thing
		.then (thing) ->
			testThing = thing
			Widget.findById(thing.id)
		.then (anotherThing) ->
			expect(anotherThing.get()).to.deep.equal(testThing.get())

	it 'should create by specific id', ->
		{ Widget } = makeCorpus()
		awidget = Widget.create()
		awidget.name = '12345'
		awidget.id = 12345

		awidget.save()
		.then ->
			Widget.findById(12345)
		.then (rst) ->
			expect(rst.name).to.equal('12345')

	it 'shouldnt find documents that arent there', ->
		{ Widget } = makeCorpus()

		Widget.findById('nothere')
		.then (x) ->
			expect(x).to.equal(undefined)
			Widget.findById(['nothere', 'nowhere'])
		.then (xs) ->
			expect(xs.length).to.equal(2)
			expect(xs[0]).to.equal(undefined)
			expect(xs[1]).to.equal(undefined)

	it 'should save, delete, not find', ->
		{ Widget } = makeCorpus()
		id = null
		Widget.create({name: 'whatsit', qty: 1000000})
		.then (widg) ->
			id = widg.id
			widg.destroy()
		.then ->
			Widget.findById(id)
		.then (x) ->
			expect(x).to.equal(undefined)

	it 'should CRUD', ->
		{ Widget } = makeCorpus()
		id = null
		Widget.create({name: 'name1', qty: 1})
		.then (widg) ->
			expect(widg.name).to.equal('name1')
			Widget.findById(widg.id)
		.then (widg) ->
			expect(widg.name).to.equal('name1')
			widg.name = 'name2'
			expect(widg.name).to.equal('name2')
			widg.save()
		.then (widg) ->
			Widget.findById(widg.id)
		.then (widg) ->
			expect(widg.name).to.equal('name2')
			id = widg.id
			widg.destroy()
		.then ->
			Widget.findById(id)
		.then (x) ->
			expect(x).to.equal(undefined)
			expect(Widget.getReduxComponent().state).to.deep.equal({})

	it 'should diff', ->
		{ Widget } = makeCorpus()
		id = null
		Widget.create({name: 'name1', qty: 1})
		.then (widg) ->
			expect(widg.changed()).to.equal(false)
			widg.name = 'name2'
			expect(widg.changed()).to.deep.equal(['name'])
			widg.save()
		.then (widg) ->
			expect(widg.changed()).to.equal(false)
