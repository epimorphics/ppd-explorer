var Ppd = function() {
  var init = function() {
    initControls();
    bindEvents();
  };

  var initControls = function() {
    console.log( "Setting datepicker on " + $(".date-picker").length);
    $(".date-picker").datepicker( {
      dateFormat: "d MM yy",
      changeMonth: true,
      changeYear: true,
      onChangeMonthYear: onChangeMonthYear
    } );
  };

  var bindEvents = function() {

  };

  var onChangeMonthYear = function( year, month, dp ) {
    var control_name = $(this).attr( "name" );
    var defaultDate = defaultDayOfMonth( year, month, control_name );
    $(this).datepicker( "setDate", defaultDate );
  };

  var defaultDays = {
    min_date: {
      1: 1, 2: 1, 3: 1, 4:  1,  5: 1,  6: 1,
      7: 1, 8: 1, 9: 1, 10: 1, 11: 1, 12: 1
    },
    max_date: {
      1: 31, 2: 28, 3: 31, 4:  30,  5: 31,  6: 30,
      7: 31, 8: 31, 9: 30, 10: 31, 11: 30, 12: 31
    }
  };

  var defaultDayOfMonth = function( year, month, name ) {
    return new Date( year, month - 1, defaultDays[name][month] );
  };

  return {
    init: init
  };
}();

