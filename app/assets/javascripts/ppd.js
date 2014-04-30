var Ppd = function() {
  /** Module variables */
  var _spinner;

  /** Module initialisation */
  var init = function() {
    initControls();
    bindEvents();
  };

  var initControls = function() {
    $(".date-picker").datepicker( {
      dateFormat: "d MM yy",
      changeMonth: true,
      changeYear: true,
      onChangeMonthYear: onChangeMonthYear,
      minDate: new Date( 1995, 0, 1 ),
      maxDate: new Date()
    } );

    $(".js.hidden").removeClass("hidden");

    // ajax spinner
    if (!_spinner) {
      _spinner = new Spinner( {
        color:'#ACCD40',
        lines: 12,
        radius: 20,
        length: 10,
        width: 4
      } );
    }
    else {
      _spinner.stop();
    }
  };

  var bindEvents = function() {
    $("form").on( "submit", onSubmitForm );
    $(".container").on( "click", ".action-bookmark", onBookmark );
    $(".container").on( "click", ".action-help" , onHelp );

    $(document).on( "ajaxSend", onAjaxSend )
               .on( "ajaxComplete", onAjaxComplete );
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
    else {
      _spinner.spin( $(".container")[0] );
    }
  }

  var validateForm = function() {
    $(".has-error").removeClass("has-error");
    $(".validation-warning").addClass("hidden");

    return validateAmount( "[name=min_price]") &&
           validateAmount( "[name=max_price]");
  };

  /** User wants to save the current location as a bookmark */
  var onBookmark = function( e ) {
    e.preventDefault();
    var elem = $(e.currentTarget);

    var baseURL = "";

    if (elem.data( "url")) {
      baseURL = window.location.host + elem.data( "url");
    }
    else if ($("form.preview").length) {
      var query = currentInteractionState( "preview", {}, ["utf8", "authenticity_token"] );
      var queryString = _.keys(query)
                         .reduce( function(a,k) {
                            a.push(k+'='+encodeURIComponent(query[k]));
                            return a
                          },[])
                         .join('&');
      baseURL = sprintf( "%s?%s", window.location.href.replace( /\?[^\?]*/, "" ), queryString );
    }
    else {
      baseURL = window.location.href;
    }

    $("#bookmark-modal").modal( 'show' );
    _.defer( function() {
      $(".fb-share-button").data( "href", baseURL );
      $(".twitter-share-button").data( "url", baseURL );
      gapi.plusone.render("plus-one", {"data-href": baseURL} );

      $(".bookmark-url").val( baseURL ).select();
    } );
  };

  /** User wants to see the help page */
  var onHelp = function( e ) {
    e.preventDefault();
    $("#help-modal").modal("show");
  };



  /* Ajax event handling */
  var onAjaxSend = function( e ) {
    $("a.btn").addClass( "action-disabled" );
    _spinner.spin( $(".container")[0] );
  };

  var onAjaxComplete = function( e ) {
    $("a.btn").removeClass( "action-disabled" );
    _spinner.stop();
  };

  return {
    init: init
  };
}();


$(Ppd.init);
