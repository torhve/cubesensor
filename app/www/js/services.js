angular.module('starter.services', [])

.factory('CubeService', ['$http', '$interval', function($http, $interval) {
  var current = {};
  // Cube ID
  var cubeId = 0;
  var refreshAll = function() {
    $http.jsonp('/api/'+cubeId+'/current?callback=JSON_CALLBACK').then(function(data) {
        data = data.data[0];
        angular.forEach(data, function(v, k) {
            current[k] = v;
        });
    }).then(function(){
        $http.jsonp("/api/"+cubeId+"/record/temp/max?start=today&callback=JSON_CALLBACK").then(function(data, status) {
            current.highTemp = data.data[0];
        })
    }).then(function(){
        $http.jsonp("/api/"+cubeId+"/record/temp/min?start=today&callback=JSON_CALLBACK").then(function(data, status) {
            current.lowTemp = data.data[0];
        })
    }).then(function(){
        $http.jsonp("/api/"+cubeId+"/record/light/max?start=today&callback=JSON_CALLBACK").then(function(data, status) {
            current.highLight = data.data[0];
        })
    }).then(function(){
        $http.jsonp("/api/"+cubeId+"/record/light/min?start=today&callback=JSON_CALLBACK").then(function(data, status) {
            current.lowLight = data.data[0];
        })
    }).then(function(){
        $http.jsonp("/api/"+cubeId+"/record/voc/max?start=today&callback=JSON_CALLBACK").then(function(data, status) {
            current.highVoc = data.data[0];
        })
    }).then(function(){
        $http.jsonp("/api/"+cubeId+"/record/voc/min?start=today&callback=JSON_CALLBACK").then(function(data, status) {
            current.lowVoc = data.data[0];
        })
    }).then(function(){
        $http.jsonp("/api/"+cubeId+"/record/humidity/max?start=today&callback=JSON_CALLBACK").then(function(data, status) {
            current.highHumidity = data.data[0];
        })
    }).then(function(){
        $http.jsonp("/api/"+cubeId+"/record/humidity/min?start=today&callback=JSON_CALLBACK").then(function(data, status) {
            current.lowHumidity = data.data[0];
        })
    }).then(function(){
        $http.jsonp("/api/"+cubeId+"/record/noisedba/max?start=today&callback=JSON_CALLBACK").then(function(data, status) {
            current.highNoise = data.data[0];
        })
    }).then(function(){
        $http.jsonp("/api/"+cubeId+"/record/noisedba/min?start=today&callback=JSON_CALLBACK").then(function(data, status) {
            current.lowNoise = data.data[0];
        })
    }).then(function(){
        $http.jsonp("/api/"+cubeId+'/hour?start=2day&callback=JSON_CALLBACK').then(function(data, status) {
          // The date format of SQL
          var parseDate = d3.time.format("%Y-%m-%d %H:%M:%S%Z").parse;
          var xdata = [];
          var tempdata = [];
          var vocdata = [];
          var humiditydata = [];
          var lightdata = [];
          var noisedata = [];
          angular.forEach(data.data, function(entry) {
              tempdata.push(entry.rtemp);
              vocdata.push(entry.voc);
              humiditydata.push(entry.humidity);
              lightdata.push(entry.light);
              noisedata.push(entry.noisedba);
              // Add d3 js date for each datum. Tell it that the date is UTC
              xdata.push(parseDate(entry.time+"+0000"));
          });
          current.tempdata = tempdata;
          current.vocdata = vocdata;
          current.humiditydata = humiditydata;
          current.lightdata = lightdata;
          current.noisedata = noisedata;
          current.txdata = xdata;
        })
    })
    /*
    .then(function() {
      // Trigger refresh complete on the pull to refresh action
      $scope.$broadcast('scroll.refreshComplete');
    })*/
    }
    // Refresh every min
    $interval(refreshAll, 60*1000);

  return {
    id: function()  {
        return id;
    },
    setId: function(id) {
        cubeId = id;
    },
    current: function() {
        return current;
    },
    refresh: function() {
        return refreshAll();
    }
  }
}]);
