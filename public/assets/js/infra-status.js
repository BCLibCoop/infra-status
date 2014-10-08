// from http://stackoverflow.com/questions/4399005/implementing-jquerys-shake-effect-with-animate
// replacement for broken Effect.Shake from JQuery UI
jQuery.fn.shake = function (steps, duration, amount, vertical) {
    var s = steps || 3;
    var d = duration || 120;
    var a = amount || 3;
    var v = vertical || false;
    this.css('position', 'relative');
    var cur = parseInt(this.css(v ? "top" : "left"), 10);
    if (isNaN(cur))
        cur = 0;

    var ds = d / s;

    if (v) {
        for (i = 0; i < s; i++)
            this.animate({ "top": cur + a + "px" }, ds).animate({ "top": cur - a + "px" }, ds);
        this.animate({ "top": cur }, 20);
    }
    else {
        for (i = 0; i < s; i++)
            this.animate({ "left": cur + a }, ds).animate({ "left": cur - a + "px" }, ds);
        this.animate({ "left": cur }, 20);
    }

    return this;
}

jQuery(function($) {
    $('.has-tooltip').tooltip();

    $('a.notice-link').click(function() {
        if ($(this).hasClass('active')) {
            $('div.notice').show(400);
            $(this).removeClass('active');
            $('#notices-for').html('');

            return false;
        } else {
            var affected_notices = $("div.notice[data-services~='" + $(this).data('service') +"']");

            if (affected_notices.length > 0) {
                $("div.notice:not([data-services~='" + $(this).data('service') +"'])").hide(400);
                affected_notices.show(400);
                $('#notices-for').html('for ' + $(this).data('service-name'));
                $('a.notice-link.active').removeClass('active');
                $(this).addClass('active');
            } else {
                $(this).shake();
                return false;
            }
        }

        if (location.pathname.replace(/^\//,'') == this.pathname.replace(/^\//,'') && location.hostname == this.hostname) {
            var target = $(this.hash);
            target = target.length ? target : $('[name=' + this.hash.slice(1) +']');
            if (target.length) {
                $('html,body').animate({
                    scrollTop: target.offset().top
                }, 200);
                return false;
            }
        }
    });
});

InfraStatus = {};