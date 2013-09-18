###
Global Variable, i know it s bad
###
selectedDate = null
isBusy = null
jQueryFadeSpeed = 'slow'

months = ["January","February","March","April","May","June","July","August","September","October","November","December"]##WHY JAVASCRIPT DATE DON"T HAVE ANY getMonh FOR MONTH NAME ?
###
Bootstrap of App
###
$( document ).ready -> 
	load()

###
Load data for today
Activate animation
###
load = () ->
	delay( 1000, loadData )
	$('.leftArrow').click ->
		loadDataAfterOrBefore(-1)
	$('.rightArrow').click ->
		loadDataAfterOrBefore(1)
	$('.find').click ->
		unless isBusy
			$('.all').fadeToggle()

###
Activate or desactivate 
###
setLoaderRotate = (status) ->
	rotateClass = 'rotate'
	clockClass = '.clock'
	if status
		$(clockClass).addClass(rotateClass)
	else
		$(clockClass).removeClass(rotateClass);

###
Delay Function
###
delay = (ms, func) -> setTimeout func, ms

loadData = (date) ->
	setLoaderRotate(true)
	$('.all').fadeOut()
	isBusy = 1
	$.getJSON( '/cgi-bin/nouveler-cgi.perl', { format : 'json', date : date })
		.done (data) ->
			processData ( JSON.parse ( JSON.stringify( data ) ) )
			isBusy = 0
			setLoaderRotate(false)

###
Load data for the day (-/+) difference pass as argument
###
loadDataAfterOrBefore = (day) ->
	unless isBusy
		intDate = selectedDate.getDate() + day
		selectedDate.setDate(intDate)
		loadData( selectedDate.getTime() / 1000 )

###
Fade data + date, then inject new date / hot / data into the document
###
processData = (data) ->
	fadeClass = '.fade'
	$(fadeClass).fadeOut(jQueryFadeSpeed, ->
		processDate ( data.date )
		processTrending( data.hot )
		processAll ( data.data )
		$(fadeClass).fadeIn(jQueryFadeSpeed)
	)

###
Create a new date from a given timestamp, then inject date,month,year into the document
###
processDate = (timestamp) ->
	date = new Date(timestamp*1000)
	selectedDate = date
	$('.day').html(date.getDate())
	$('.month').html(months[date.getMonth()])
	$('.year').html(date.getFullYear())

###
Build a ul/li list from json object then inject it into trending
###
processTrending = (trending) ->
	text = constructList( trending )
	$('.trending').html(text)

###
Get a ul/li list from json object then inject it into all
###
processAll = (all) ->
	text = constructList( all )
	$('.all').html(text)

###
Build a ul/li list from a json object
###
constructList = (json) ->
	if json
		returnList = '<ul>'
		for row in json
			returnList = returnList + '<li>' + row.title + '</li>'
		return returnList + '</ul>'	
	else
		return 'Their is no availaible data at that time'