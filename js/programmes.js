jQuery(document).ready(function(){
			resizeProgrammesHeader();
			jQuery(window).resize(function() {
				resizeProgrammesHeader();
			});
		});

		function resizeProgrammesHeader(){

			if(jQuery(window).width() >=980){
				// Its a desktop device

				if(jQuery(window).height() <725){
					var header_height = jQuery(window).height() - (125);
					jQuery(".programmes-header").css({
						'height': header_height + 'px',
					});
					jQuery(".programmes-header").addClass('desktop_smaller_height');
				} else {
					jQuery(".programmes-header").removeClass('desktop_smaller_height');
					jQuery(".programmes-header").css({
						'height': 600 + 'px',
					});
				}
			}
}

