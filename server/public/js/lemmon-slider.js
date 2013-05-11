
/*
 * Lemmon Slider - jQuery Plugin
 * Simple and lightweight slider/carousel supporting variable elements/images widths.
 *
 * Examples and documentation at: http://jquery.lemmonjuice.com/plugins/slider-variable-widths.php
 *
 * Copyright (c) 2011 Jakub Pel叩k <jpelak@gmail.com>
 *
 * Version: 0.2 (9/6/2011)
 * Requires: jQuery v1.4+
 *
 * Dual licensed under the MIT and GPL licenses:
 *   http://www.opensource.org/licenses/mit-license.php
 *   http://www.gnu.org/licenses/gpl.html
 */
(function( $ ){

    var _css = {};

    var methods = {
	//
	// Initialzie plugin
	//
	init : function( options ){
	    
	    options = $.extend( {}, $.fn.lemmonSlider.defaults, options );
	    
	    return this.each(function(){
		
		var $slider = $( this ),
		    data = $slider.data( 'slider' );
		
		if ( ! data ){
		    
		    var $sliderContainer = $slider.find( options.slider ),
			$sliderControls = $slider.find( options.controls ),
			$items = $sliderContainer.find( options.items ),
			originalWidth =
                            $sliderContainer.outerWidth(true) -
                            $sliderContainer.innerWidth();
                    
		    $items.each(function(){
                        originalWidth += $( this ).outerWidth(true);
                    });
		    $sliderContainer.width( originalWidth );
                    
                    console.log(originalWidth);
                    console.log($slider.width());

                    // not necessary to scroll
                    if (originalWidth <= $slider.width()) {
                        $sliderControls.hide();
                        return;
                    }
		    
		    // left & right padding
		    $sliderContainer.css({
                        'padding-left': $slider.width(),
                        'padding-right': $slider.width()
                    });

		    // infinite carousel
		    if ( options.infinite ){

			originalWidth = originalWidth * 3;
			$sliderContainer.width( originalWidth );
			
			$items.clone().addClass( '-after' ).insertAfter( $items.filter(':last') );
			$items.filter( ':first' ).before( $items.clone().addClass('-before') );

			$items = $sliderContainer.find( options.items );
                    }
                    
		    $slider.items = $items;
		    $slider.options = options;
		    
		    // first item
		    //$items.filter( ':first' ).addClass( 'active' );

                    slideToFirst( $slider, false );

		    // attach events
		    $slider.bind( 'nextSlide', function( e, t ){

                        var baseLine = getBaseLine($slider);
			var x = baseLine;
			var slideIndex = 0;

			$items.each(function( i ){

                            var itemPos = getItemPos( $slider, $( this ) );
                            
			    if ( x == baseLine && itemPos > baseLine + 1){
				x = itemPos;
				slideIndex = i;
			    }
			});

			if ( x > baseLine ){
			    slideTo( $slider, x, slideIndex, 'fast' );
			} else if ( options.loop ){
			    // return to first
                            slideToFirst( $slider, 'slow' );
			}

		    });
		    $slider.bind( 'prevSlide', function( e, t ){

                        var baseLine = getBaseLine($slider);
			var x = baseLine;
			var slideIndex = 0;

			$items.each(function( i ){

                            var itemPos = getItemPos( $slider, $( this ) );
                            
			    if ( itemPos < baseLine ){
				x = itemPos;
				slideIndex = i;
			    }
			});

			if ( x < baseLine ){
			    slideTo( $slider, x, slideIndex, 'fast' );
			} else if ( options.loop ){
			    // return to last
                            slideToLast( $slider, 'slow' );
			}

		    });
		    $slider.bind( 'nextPage', function( e, t ){

			var scroll = $slider.scrollLeft();
			var w = $slider.width();
			var x = 0;
			var slide = 0;

			$items.each(function( i ){
			    if ( $( this ).position().left < w ){
				x = $( this ).position().left;
				slide = i;
			    }
			});

			if ( x > 0 && scroll + w < originalWidth ){
			    slideTo( $slider, scroll+x, slide, 'slow' );
			} else if ( options.loop ){
			    // return to first
                            slideToFirst( $slider, 'slow' );
			}

		    });
		    $slider.bind( 'prevPage', function( e, t ){

			var scroll = $slider.scrollLeft();
			var w = $slider.width();
			var x = 0;

			$items.each(function( i ){
			    if ( $( this ).position().left < 1 - w ){
				x = $( this ).next().position().left;
				slide = i;
			    }
			});

			if ( scroll ){
			    if ( x == 0 ){
				//$slider.animate({ 'scrollLeft' : 0 }, 'slow' );
				slideTo( $slider, 0, 0, 'slow' );
			    } else {
				//$slider.animate({ 'scrollLeft' : scroll + x }, 'slow' );
				slideTo( $slider, scroll+x, slide, 'slow' );
			    }
			} else if ( options.loop ) {
			    // return to last
                            slideToLast( $slider, 'slow' );
			}

		    });
		    $slider.bind( 'slideTo', function( e, i, t ){

			slideTo( $slider, getItemPos( $slider, $items.filter( ':eq(' + i +')' ) ), i, t );

		    });

		    // controls
		    $sliderControls.find( '.next-slide' ).click(function(){
			$slider.trigger( 'nextSlide' );
			return false;
		    });
		    $sliderControls.find( '.prev-slide' ).click(function(){
			$slider.trigger( 'prevSlide' );
			return false;
		    });
		    $sliderControls.find( '.next-page' ).click(function(){
			$slider.trigger( 'nextPage' );
			return false;
		    });
		    $sliderControls.find( '.prev-page' ).click(function(){
			$slider.trigger( 'prevPage' );
			return false;
		    });

		    //if ( typeof $slider.options.create == 'function' ) $slider.options.create();
		    
		    $slider.data( 'slider', {
			'target'  : $slider,
			'options' : options
		    });

		}

	    });
	    
	},
	//
	// Destroy plugin
	//
	destroy : function(){
	    
	    return this.each(function(){
		
		var $slider = $( this ),
		    $sliderControls = $slider.find( options.controls ),
		    data = $slider.data( 'slider' );
		
		$slider.unbind( 'nextSlide' );
		$slider.unbind( 'prevSlide' );
		$slider.unbind( 'nextPage' );
		$slider.unbind( 'prevPage' );
		$slider.unbind( 'slideTo' );
		
		$sliderControls.find( '.next-slide' ).unbind( 'click' );
		$sliderControls.find( '.prev-slide' ).unbind( 'click' );
		$sliderControls.find( '.next-page' ).unbind( 'click' );
		$sliderControls.find( '.next-page' ).unbind( 'click' );
		
		$slider.removeData( 'slider' );
		
	    });
	    
	}
	//
	//
	//
    };
    //
    // Private functions
    //
    function slideToFirst( $slider, t ) {

        var first = $slider.items.filter( ':not(.-before):first' );
	slideTo( $slider, getItemPos( $slider, first ), 0, t );
    }
    function slideToLast( $slider, t ) {

        var items = $slider.items.filter( ':not(.-after)' );
        var last = items.filter( ':last' );
	slideTo( $slider, getItemPos( $slider, last ), items.length-1, t );
    }

    function slideTo( $slider, x, i, t ){
	
        x = getScrollLeft( $slider, x );

	$slider.items.filter( ':eq(' + i + ')' ).addClass( 'active' ).siblings( '.active' ).removeClass( 'active' );
	
	if ( typeof t == 'undefined' ){
	    t = 'fast';
	}
	if ( t ){
	    $slider.animate({ 'scrollLeft' : x }, t, function(){
		checkInfinite( $slider );
	    });
	} else {
	    var time = 0;
	    $slider.scrollLeft( x );
	    checkInfinite( $slider );
	}
	
	//if ( typeof $slider.options.slide == 'function' ) $slider.options.slide( e, i, time );
	
    }
    function checkInfinite( $slider ){

	var $active = $slider.items.filter( '.active' );
	if ( $active.hasClass( '-before' ) ){

	    var i = $active.prevAll().size();
	    $active.removeClass( 'active' );
	    $active = $slider.items.filter( ':not(.-before):eq(' + i + ')' ).addClass( 'active' );
            setFocus( $slider, $active );

	} else if ( $active.hasClass( '-after' ) ){

	    var i = $active.prevAll( '.-after' ).size();
	    $active.removeClass( 'active' );
	    $active = $slider.items.filter( ':not(.-before):eq(' + i + ')' ).addClass( 'active' );
            setFocus( $slider, $active );
	}
	
    }
    function setFocus( $slider, focal ) {

        $slider.scrollLeft( getScrollLeft( $slider, getItemPos( $slider, focal ) ) );
    };
    function getScrollLeft( $slider, focalPos ) {

        if ( $slider.options.focusCenter ) {
            focalPos -= $slider.width() / 2;
        }
        return focalPos;
    }
    function getBaseLine( $slider ) {

        var baseLine = $slider.scrollLeft();
        if ( $slider.options.focusCenter ) {
            baseLine += $slider.width() / 2;
        }
        return baseLine;
    }
    function getItemPos( $slider, item ) {

        var itemPos = $slider.scrollLeft() + item.position().left;
        if ( $slider.options.focusCenter ) {
            itemPos += item.width() / 2;
        }
        return itemPos;
    }
    
    
    //
    // Debug
    //
    function debug( text ){
	$( '#debug span' ).text( text );
    }
    //
    //
    //
    $.fn.lemmonSlider = function( method ){  

	if ( methods[method] ) {
	    return methods[ method ].apply( this, Array.prototype.slice.call( arguments, 1 ));
	} else if ( typeof method === 'object' || !method ){
	    return methods.init.apply( this, arguments );
	} else {
	    $.error( 'Method ' +  method + ' does not exist on jQuery.lemmonSlider' );
	}

    };
    //
    //
    //
    $.fn.lemmonSlider.defaults = {
	
	'items'       : '> *',
	'loop'        : true,
	'slideToLast' : false,
	'slider'      : '> *:first',
        'controls'    : '> .controls',
	// since 0.2
	'infinite'    : false,
        'focusCenter' : false
	
    }

})( jQuery );
