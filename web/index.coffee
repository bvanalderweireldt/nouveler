###
Global Variable, i know it s bad
###
selectedDate = new Date()
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
	replaceSVGIntoInlineSVG()
	delay( 1000, loadFirst )
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
delay = (ms, func) -> 
	setTimeout( func, ms )

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
Function used for the first load, need a static departure value
###
loadFirst = () ->
	loadDataAfterOrBefore(-1)

###
Fade data + date, then inject new date / hot / data into the document
###
processData = (data) ->
	fadeClass = '.fade'
	$(fadeClass).fadeOut(jQueryFadeSpeed, -> #We need to fadeOut an always display element if we want the call back to be efficient
		$('.all').fadeOut(jQueryFadeSpeed)
		processDate ( data.date )
		processTrending( data.hot )
		processAll ( data.data )
		$(fadeClass).fadeIn(jQueryFadeSpeed)
		$('.data ul li').click ->
			openSource($(this))
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
	if json[0]
		returnList = '<ul>'
		for row in json
			returnList = returnList + '<li link=\'' + row.link + '\'>' + row.title + '</li>'
		return returnList + '</ul>'	
	else
		return '<p>Their is no availaible data back at that time</p>'

###
Replace all SVG images with inline SVG
###
replaceSVGIntoInlineSVG = () ->
	targetClass = 'img.inlineSvg'
	$(targetClass).each( () ->
		img = $(this)
		imgID = img.attr('id')
		imgClass = img.attr('class')
		imgURL = img.attr('src')
	
		$.get(imgURL, (data) ->
			#Get the SVG tag, ignore the rest
			svg = $(data).find('svg')

			#Add replaced image's ID to the new SVG
			if typeof imgID isnt 'undefined' then svg = svg.attr('id', imgID)
			
			#Add replaced image's classes to the new SVG
			if typeof imgClass isnt 'undefined' then svg = svg.attr('class', imgClass+' replaced-svg')
			

			#Remove any invalid XML tags as per http://validator.w3.org
			svg = svg.removeAttr('xmlns:a')

			#Replace image with new SVG
			img.replaceWith(svg)
		, 'xml')
	)

###
Open a new tab with the given link
###
openSource = (element) ->
	if element.attr('link') and element.attr('link') isnt 'undefined'
		window.open(element.attr('link'))
	else
		old = element.html()
		element.attr('link', element.html())
		element.html('Unfortunately their is no recorded source for that !')
		element.addClass('error')
		delay(3000, switchBackAllErrorElement)

###
Switch back error element
###
switchBackAllErrorElement = () ->
	$('.data ul li.error').each( () ->
		$(this).html($(this).attr('link'))
		$(this).removeClass('error')
	)
