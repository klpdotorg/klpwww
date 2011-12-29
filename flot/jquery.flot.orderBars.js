/* 
 * Flot plugin to order bars side by side.
 *
 * This plugin is an alpha version.
 *
 * To activate the plugin you must specify the parameter "order" for the specific serie :
 *
 *  $.plot($("#placeholder"), [{ data: [ ... ], bars :{ order = null or integer }])
 *
 * If 2 series have the same order param, they are ordered by the position in the array;
 *
 * The plugin adjust the point by adding a value depanding of the barwidth
 * Exemple for 3 series (barwidth : 0.1) :
 *
 *          first bar décalage : -0.15
 *          second bar décalage : -0.05
 *          third bar décalage : 0.05
 *
 */

(function($){
    function init(plot){
        /**
         * @param series All the series
         */
        function findOthersBarsToReOrders(series){
            var retSeries = new Array();

            for(var i = 0; i < series.length; i++){
                if(series[i].bars.order != null && series[i].bars.show){
                    retSeries.push(series[i]);
                }
            }

            return retSeries.sort(sortByOrder);
        }
        
        function sortByOrder(serie1,serie2){
            var x = serie1.bars.order;
            var y = serie2.bars.order;
            return ((x < y) ? -1 : ((x > y) ? 1 : 0));
        }

        function sumWidth(series,start,end){
            var totalWidth = 0;

            for(var i = start; i <= end; i++){
                totalWidth += series[i].bars.barWidth;
            }

            return totalWidth;
        }

        function findPosition(serie,allseries){
            var pos = 0
            for (var i = 0; i < allseries.length; ++i) {
                if (serie == allseries[i]){
                    pos = i;
                    break;
                }


            }

            return pos+1;
        }

        /*
         * This method add shift to x values
         */
        function reOrderBars(plot, serie, datapoints){
            var dx = 0;

            if(serie.bars == null || !serie.bars.show || serie.bars.order == null)
                return null;

            var orderedBarSeries = findOthersBarsToReOrders(plot.getData());
            var nbOfBarsToOrder = orderedBarSeries.length;
            var borderWidth = serie.bars.lineWidth ? serie.bars.lineWidth  : 2;
            var barWidth = serie.bars.barWidth + borderWidth;
 
            var position = findPosition(serie,orderedBarSeries);

            if(nbOfBarsToOrder < 2){
                return null;
            }else if (position <= Math.ceil(nbOfBarsToOrder / 2)){
                dx = -1*(sumWidth(orderedBarSeries,position-1,Math.floor(nbOfBarsToOrder / 2)-1));

                if(nbOfBarsToOrder%2 != 0)
                    dx -= (orderedBarSeries[Math.ceil(nbOfBarsToOrder / 2)].bars.barWidth)/2;
            }else{
                dx = sumWidth(orderedBarSeries,Math.ceil(nbOfBarsToOrder / 2),position-2);

                if(nbOfBarsToOrder%2 != 0)
                    dx += (orderedBarSeries[Math.ceil(nbOfBarsToOrder / 2)].bars.barWidth)/2;
            }


            var ps = datapoints.pointsize;
            var points = datapoints.points;
            var j = 0;

            for(var i = 0; i < points.length; i += ps){
                points[i] += dx;
                //Adding the new x value in the serie to be abble to display the right tooltip value,
                //using the index 3 to not overide the third index.
                serie.data[j][3] = points[i];
                j++;
            }


           datapoints.points = points;

           return points;
        }

         plot.hooks.processDatapoints.push(reOrderBars);

    }

    var options = {
        series : {
            bars: {order: null} // or number/string
        }
    };

    $.plot.plugins.push({
        init: init,
        options: options,
        name: "orderBars",
        version: "0.1"
    });

})(jQuery)

