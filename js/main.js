    jQuery(document).ready(function(){
      // Adds easing scrolling to # targets
      jQuery('a[href*=#]:not([href=#])').click(function() {
          if (location.pathname.replace(/^\//,'') == this.pathname.replace(/^\//,'') 
              || location.hostname == this.hostname) {

            var target = jQuery(this.hash);
            target = target.length ? target : jQuery('[name=' + this.hash.slice(1) +']');
            if (target.length) {
              jQuery('html,body').animate({
                scrollTop: target.offset().top-100
              }, 300);
              return false;
            }
          }
      });
      resizeHomeHeader();
      jQuery(window).resize(function() {
        resizeHomeHeader();
      });
    });

    function resizeHomeHeader(){

      if(jQuery(window).width() >=980){
        // Its a desktop device
        if(jQuery(window).height() <750){
          // Resize only if height less than 750px (700px header + 50px navigation)
          var header_height = jQuery(window).height() - (50+30); // 50px navigation + 30px padding in content

          jQuery(".home-header .content").css({
            'min-height': header_height + 'px',
            'height': header_height + 'px',
            'background-size': 'auto '+header_height + 'px'
          });

          // Setting headline text height as 130px
          jQuery(".home-header .content .headline-text").css({
            'height': 130 + 'px',
            'background-size': 'auto 130px',
            'margin-top': '30px'
          });

          if(header_height>450){
            jQuery(".home-header .content .info").css({
              'margin-top': '30px',
              'display' : 'block'
            });
          } else {
            jQuery(".home-header .content .info").hide();
          }

          console.log(header_height);
        }
      } else {
        // Its a mobile or tablet. Reverting to original css.
        jQuery(".home-header .content").css({
          'height': 'auto',
          'min-height': 'inherit'
        });
      }
    }

      // Re-display top navigation if it gets hidden.
      jQuery(window).resize(function() {
        if(jQuery(window).width() >=980){
          jQuery("#navigation").show();
        } else {
          jQuery("#navigation").hide();
        }
      });

      // Top navigation show dropdown on hover
      jQuery(".top-nav ul li" ).hover(
        function() {
          jQuery( this ).find('ul').show();
        }, function() {
          jQuery( this ).find('ul').hide();
        }
      );

      jQuery("#page_sticky_nav").stickOnScroll({
            topOffset: 0,
            setParentOnStick:   true,
            setWidthOnStick:    true
        });



