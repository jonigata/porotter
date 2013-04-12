(function($){
    $.fn.extend({
        justModal: function(options){
            // setup options
            var defaults={
                top:100,
                overlay:0.5,
                closeButton:null
            };
            var o = $.extend(defaults,options);

            // add overlay
            var overlay = $("<div id='lean-overlay'></div>");
            $("body").append(overlay);

            // setup close function
            var modal = this;
            function close_modal() {
                overlay.fadeOut(200);
                modal.css({"display":"none"});
            };
            overlay.click(close_modal);
            $(o.closeButton).click(close_modal);
            this.close = close_modal;

            // show overlay
            overlay.css({
                "display":"block",
                opacity:0
            });
            overlay.fadeTo(200,o.overlay);

            // show modal entity
            modal.css({
                "display":"block",
                "position":"fixed",
                "opacity":0,
                "z-index":11000,
                "left":50+"%",
                "margin-left":-(modal.outerWidth()/2)+"px",
                "top":o.top+"px"
            });
            modal.fadeTo(200,1);
            modal.find('.first').focus();
            return this;
        }
    });
})(jQuery);
