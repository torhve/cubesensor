angular.module('starter.directives', [])

// Based on http://www.ng-newsletter.com/posts/d3-on-angular.html

.directive('linechart', function() {
    return {
      restrict: 'EA',
      scope: {
        data: '=', // bi-driectional data-binding
        xdata: '=',
      },
      link: function(scope, element, attrs) {
          var margin = parseInt(attrs.margin) || 20,
              height = parseInt(attrs.height) || 90,
              padding = parseInt(attrs.padding) || 5,
              interpolation = attrs.interpolation || 'basis',
              graphtype = attrs.type,
              color0 = attrs.color0 || 'steelblue',
              color1 = attrs.color1 || '#b5152b';

          var svg = d3.select(element[0])
            .append("svg")
            .style('width', '100%')
            .style('height', height+"px");

          // Browser onresize event
          window.onresize = function() {
            scope.$apply();
          };

          // watch for data changes and re-render
          scope.$watch('data', function(newVals, oldVals) {
              return scope.render(newVals, scope.xdata);
          }, true);

          // Watch for resize event
          scope.$watch(function() {
            return angular.element(window)[0].innerWidth;
          }, function() {
            scope.render(scope.data, scope.xdata);
          });

          scope.render = function(data, xdata) {
            // remove all previous items before render
            svg.selectAll('*').remove();

            // If we don't pass any data, return out of the element
            if (!data) return;
            if (!xdata) return;
            var graphheight = height-margin;
            var width = d3.select(element[0]).node().offsetWidth - margin;
            var x = d3.time.scale().domain(d3.extent(xdata)).range([0, width]);
            var y = d3.scale.linear().domain(d3.extent(data)).range([graphheight, 0]);

            /*
            if (graphtype === 'maybe') {
                // Temperature line coloring
                // Thanks to http://bl.ocks.org/mbostock/3970883
                d3.select("#temperature-gradient")
                    .attr("gradientUnits", "userSpaceOnUse")
                    .attr("x1", 0).attr("y1", y(-1))
                    .attr("x2", 0).attr("y2", y(1))
                  .selectAll("stop")
                    .data([
                            {offset: "0%", color: color0},
                            {offset: "50%", color: color0},
                            {offset: "50%", color: color1},
                            {offset: "100%", color: color1}
                            ])
                  .enter().append("stop")
                    .attr("offset", function(d) { return d.offset; })
                    .attr("stop-color", function(d) { return d.color; });
            }
            */
            var xAxis = d3.svg.axis()
                .scale(x)
                .orient("bottom");

            // Draw icons
            var hoursAxis = d3.svg.axis()
              .scale(x)
              .orient('bottom')
              .ticks(d3.time.hour, 3)
              .tickPadding(6)
              .tickSize(8)
              .tickFormat(function(d) {
                var hours = d.getHours();
                if (hours === 6) {
                    // Ion icon sun
                    return '';
                }
                else if (hours === 18) {
                    // Ion icon moon
                    return '';
                }
                else {
                    return null;
                }
            })
            var iconheight = graphheight-30;
            var hoursg = svg.append('g')
                .classed('axis', true)
                .classed('hours', true)
                .classed('labeled', true)
                .attr("transform", "translate(0,"+iconheight+")")
                .call(hoursAxis)

            var daysTickmarksAxis = d3.svg.axis()
                .scale(x)
                .orient('bottom')
                .ticks(d3.time.day, 1)
                .tickFormat('') // we want blank labels on the tickmarks
                .tickSize(30)
                .tickPadding(6)

            svg.append('g')
               .classed('axis', true)
               .classed('days', true)
               .attr("transform", "translate(0.5,"+graphheight+")")
               .call(daysTickmarksAxis)

            // X Axis legend
            svg.append("g")
                .attr("class", "x axis")
                .attr("transform", "translate(0," +graphheight + ")")
                .call(xAxis);

            // X Axis grid
            var xrule = svg.selectAll("line.x")
                .data(x.ticks(10))
                .enter().append("g")
                .attr("class", "x axis")
              .append("svg:line")
                .attr("class", "yLine")
                .attr("x1", x)
                .attr("x2", x)
                .attr("y1", 0)
                .attr("y2", graphheight)
                .style('stroke', function(d, i) { 
                    if(d.getHours() == 0) {
                        return 'gray';
                    }
                    return '#ededed';
                })
                .attr("stroke-opacity", function(d, i) {
                    if(d.getHours() == 0) {
                        return '1';
                    }
                    return '0';
                })
                .style("shape-rendering", "crispEdges") ;
/*
            var xAxis = d3.svg.axis().scale(x).tickSize(-height).tickSubdivide(true);
            // Add the x-axis.
            svg.append("svg:g")
                  .attr("class", "x axis")
                  .attr("transform", "translate(0," + height + ")")
                  .call(xAxis);
*/

            var yAxisLeft = d3.svg.axis().scale(y).ticks(4).orient("left");
            // Add the y-axis to the left
            svg.append("svg:g")
                  .attr("class", "y axis")
                  .attr("transform", "translate(30,0)")
                  .call(yAxisLeft);

            var line = d3.svg.line()
                .x(function(d,i) { return x(xdata[i]); })
                .y(function(d) { return y(d); })
                .interpolate(interpolation)

            var path = svg.append("path")
                .attr("d", line(data))
                .data([data])
                    .attr("transform", "translate(" + 30 + ")"); // animate a slide to the left back to x(0) pixels to reveal the new value
            if(graphtype === 'maybe') {
                path.style("stroke", "url('#temperature-gradient')")
            }else{
                path.style("stroke", color1);
            }
          }
      }
    }
});
