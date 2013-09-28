/*
Global Variable, i know it s bad
*/


(function() {
  var constructList, delay, isBusy, jQueryFadeSpeed, load, loadData, loadDataAfterOrBefore, loadFirst, months, openSource, processAll, processData, processDate, processTrending, replaceSVGIntoInlineSVG, selectedDate, setLoaderRotate, switchBackAllErrorElement;

  selectedDate = new Date();

  isBusy = null;

  jQueryFadeSpeed = 'slow';

  months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];

  /*
  Bootstrap of App
  */


  $(document).ready(function() {
    return load();
  });

  /*
  Load data for today
  Activate animation
  */


  load = function() {
    replaceSVGIntoInlineSVG();
    delay(1000, loadFirst);
    $('.leftArrow').click(function() {
      return loadDataAfterOrBefore(-1);
    });
    $('.rightArrow').click(function() {
      return loadDataAfterOrBefore(1);
    });
    return $('.find').click(function() {
      if (!isBusy) {
        return $('.all').fadeToggle();
      }
    });
  };

  /*
  Activate or desactivate
  */


  setLoaderRotate = function(status) {
    var clockClass, rotateClass;
    rotateClass = 'rotate';
    clockClass = '.clock';
    if (status) {
      return $(clockClass).addClass(rotateClass);
    } else {
      return $(clockClass).removeClass(rotateClass);
    }
  };

  /*
  Delay Function
  */


  delay = function(ms, func) {
    return setTimeout(func, ms);
  };

  loadData = function(date) {
    setLoaderRotate(true);
    $('.all').fadeOut();
    isBusy = 1;
    return $.getJSON('/cgi-bin/nouveler-cgi.perl', {
      format: 'json',
      date: date
    }).done(function(data) {
      processData(JSON.parse(JSON.stringify(data)));
      isBusy = 0;
      return setLoaderRotate(false);
    });
  };

  /*
  Load data for the day (-/+) difference pass as argument
  */


  loadDataAfterOrBefore = function(day) {
    var intDate;
    if (!isBusy) {
      intDate = selectedDate.getDate() + day;
      selectedDate.setDate(intDate);
      return loadData(selectedDate.getTime() / 1000);
    }
  };

  /*
  Function used for the first load, need a static departure value
  */


  loadFirst = function() {
    return loadDataAfterOrBefore(-1);
  };

  /*
  Fade data + date, then inject new date / hot / data into the document
  */


  processData = function(data) {
    var fadeClass;
    fadeClass = '.fade';
    return $(fadeClass).fadeOut(jQueryFadeSpeed, function() {
      $('.all').fadeOut(jQueryFadeSpeed);
      processDate(data.date);
      processTrending(data.hot);
      processAll(data.data);
      $(fadeClass).fadeIn(jQueryFadeSpeed);
      return $('.data ul li').click(function() {
        return openSource($(this));
      });
    });
  };

  /*
  Create a new date from a given timestamp, then inject date,month,year into the document
  */


  processDate = function(timestamp) {
    var date;
    date = new Date(timestamp * 1000);
    selectedDate = date;
    $('.day').html(date.getDate());
    $('.month').html(months[date.getMonth()]);
    return $('.year').html(date.getFullYear());
  };

  /*
  Build a ul/li list from json object then inject it into trending
  */


  processTrending = function(trending) {
    var text;
    text = constructList(trending);
    return $('.trending').html(text);
  };

  /*
  Get a ul/li list from json object then inject it into all
  */


  processAll = function(all) {
    var text;
    text = constructList(all);
    return $('.all').html(text);
  };

  /*
  Build a ul/li list from a json object
  */


  constructList = function(json) {
    var returnList, row, _i, _len;
    if (json[0]) {
      returnList = '<ul>';
      for (_i = 0, _len = json.length; _i < _len; _i++) {
        row = json[_i];
        returnList = returnList + '<li link=\'' + row.link + '\'>' + row.title + '</li>';
      }
      return returnList + '</ul>';
    } else {
      return '<p>Their is no availaible data back at that time</p>';
    }
  };

  /*
  Replace all SVG images with inline SVG
  */


  replaceSVGIntoInlineSVG = function() {
    var targetClass;
    targetClass = 'img.inlineSvg';
    return $(targetClass).each(function() {
      var img, imgClass, imgID, imgURL;
      img = $(this);
      imgID = img.attr('id');
      imgClass = img.attr('class');
      imgURL = img.attr('src');
      return $.get(imgURL, function(data) {
        var svg;
        svg = $(data).find('svg');
        if (typeof imgID !== 'undefined') {
          svg = svg.attr('id', imgID);
        }
        if (typeof imgClass !== 'undefined') {
          svg = svg.attr('class', imgClass + ' replaced-svg');
        }
        svg = svg.removeAttr('xmlns:a');
        return img.replaceWith(svg);
      }, 'xml');
    });
  };

  /*
  Open a new tab with the given link
  */


  openSource = function(element) {
    var old;
    if (element.attr('link') && element.attr('link') !== 'undefined') {
      return window.open(element.attr('link'));
    } else {
      old = element.html();
      element.attr('link', element.html());
      element.html('Unfortunately their is no recorded source for that !');
      element.addClass('error');
      return delay(3000, switchBackAllErrorElement);
    }
  };

  /*
  Switch back error element
  */


  switchBackAllErrorElement = function() {
    return $('.data ul li.error').each(function() {
      $(this).html($(this).attr('link'));
      return $(this).removeClass('error');
    });
  };

}).call(this);
