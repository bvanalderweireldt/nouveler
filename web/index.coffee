selectedDate = null
isBusy = null


$( document ).ready -> 
	load()

load = () ->
	setLoaderRotate(true)
	delay( 1000, loadData )
	$('.leftArrow').click ->
		loadDataAfterOrBefore(-1)
	$('.rightArrow').click ->
		loadDataAfterOrBefore(1)
	$('.find').click ->
		showAllData()


setLoaderRotate = (status) ->
	rotateClass = 'rotate'
	clockClass = '.clock'
	if status
		$(clockClass).addClass(rotateClass)
	else
		$(clockClass).removeClass(rotateClass);

delay = (ms, func) -> setTimeout func, ms

loadData = (date) ->
	$('.all').fadeOut()
	isBusy = 1
	$.getJSON( '/cgi-bin/nouveler-cgi.perl', { format : 'json', date : date })
		.done (data) ->
			processData ( JSON.parse ( JSON.stringify( data ) ) )
			isBusy = 0
			setLoaderRotate(false)

loadDataAfterOrBefore = (day) ->
	unless isBusy
		intDate = selectedDate.getDate() + day
		selectedDate.setDate(intDate)
		loadData( selectedDate.getTime() / 1000 )

processData = (data) ->
	processDate ( data.date )
	processTrending( data.hot )
	processAll ( data.data )

months = ["January","February","March","April","May","June","July","August","September","October","November","December"]
processDate = (timestamp) ->
	date = new Date(timestamp*1000)
	selectedDate = date
	$('.day').html(date.getDate())
	$('.month').html(months[date.getMonth()])
	$('.year').html(date.getFullYear())

processTrending = (trending) ->
	text = constructList( trending )
	$('.trending').html(text)

processAll = (all) ->
	text = constructList( all )
	$('.all').html(text)

constructList = (json) ->
	returnList = '<ul>'
	for row in json
		returnList = returnList + '<li>' + row.title + '</li>'
	return returnList + '</ul>'
		
showAllData = () ->
	unless isBusy
		$('.all').fadeIn()