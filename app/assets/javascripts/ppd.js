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
      onChangeMonthYear: onChangeMonthYear,
      minDate: new Date( 1995, 0, 1 ),
      maxDate: new Date()
    } );
  };

  var bindEvents = function() {
    $("form").on( "submit", onSubmitForm );
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

  var validateAmount = function( selector ) {
    var elem = $(selector);
    var amt = $.trim( elem.val() );

    if (amt) {
      if (!amt.match( /^((\d+)|(\d{1,3})(\,\d{3}|)*)(\.\d{2}|)$/ )) {
        elem.parents(".form-group")
            .addClass( "has-error" );
        elem.parents(".row")
            .first()
            .find(".validation-warning")
            .removeClass("hidden");
        return false;
      }
    }

    return true;
  };

  var onSubmitForm = function( e ) {
    if (!validateForm()) {
      e.preventDefault();
    }
  }

  var validateForm = function() {
    $(".has-error").removeClass("has-error");
    $(".validation-warning").addClass("hidden");

    return validateAmount( "[name=min_price]") &&
           validateAmount( "[name=max_price]");
  };

  return {
    init: init
  };
}();

