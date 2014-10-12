
angular.module('starter.filters', [])

.filter('temperature', function() {
    return function(value) {
        if(!value)
            return '';
        if (value != undefined) 
            return Number((value).toFixed(1))+ ' °C';
    };
})
.filter('voc', function() {
    return function(value) {
        if(!value)
            return '';
        if (value != undefined) 
            return Number((value).toFixed(0))+ ' ppm';
    };
})
.filter('humidity', function() {
    return function(value) {
        if (value)
            return Number((value).toFixed(0)) + ' %';
        return '0 %'
    };
})
.filter('rain', function() {
    return function(value) {
        if(value)
            return Number((value).toFixed(1)) + ' mm';
        return '0 mm';
    };
})
.filter('windspeed', function() {
    return function(value) {
        if (value)
            return Number(value/3.6).toFixed(1) + ' m/s';
        return '0 m/s'
    };
})
.filter('pressure', function() {
    return function(value) {
        if (value)
            return Number((value).toFixed(1)) + ' hPa';
    };
})
